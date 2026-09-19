# Local AI stack: Ollama (CUDA) + open-webui + Hermes Agent.
#
# NOTE — secrets: never put API keys in `settings` or `environment`;
# both are written into /nix/store, which is world-readable. Use
# `environmentFiles` pointed at a sops-nix/agenix secret (or, as a
# bare-minimum starting point, a manually created 0600 file owned by
# the hermes user).
{ config, pkgs, lib, ... }:

{
  # Ollama — always-on local LLM server at http://localhost:11434.
  # ollama-cuda offloads inference to the NVIDIA GPU; idle it consumes
  # nearly nothing.
  # Manual start only (gated 2026-09-11: ollama-cuda idles on the
  # NVIDIA GPU even with no model loaded). Start when needed with:
  #   sudo systemctl start ollama open-webui
  # Re-enable autostart by deleting the two wantedBy lines + rebuild.
  systemd.services.ollama.wantedBy = lib.mkForce [];
  systemd.services.open-webui.wantedBy = lib.mkForce [];

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  services.open-webui = {
    enable = true;
    port = 8080;
    # package = pkgs.open-webui;  # pin explicitly if needed
  };

  services.hermes-agent = {
    enable = true;

    settings.model = {
      # OpenRouter is Hermes' default provider — no base_url override
      # needed, just the model slug. MiniMax M3 (free): 1M context,
      # tuned for long-horizon agentic/coding work — genuinely free,
      # not a trial quota.
      default = "minimax/minimax-m3:free";
    };

    # OpenRouter key (see secrets NOTE above)
    environmentFiles = [ "/var/lib/hermes/env" ];

    # Deployment mode: by default this runs as a hardened systemd
    # service directly on the host, where the agent can only use
    # tools already on its Nix-provided PATH. To let it
    # self-install packages at runtime (apt/pip/npm), set
    # container.enable = true — runs it inside a persistent Ubuntu
    # container instead (needs Podman, enabled in
    # programs/virtualisation.nix).
    # container.enable = true;

    addToSystemPackages = true;
  };
}
