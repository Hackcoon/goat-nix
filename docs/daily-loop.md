# NixOS Daily Loop (cheat sheet)

Copy-paste order. Full explanations: `docs/github-workflow.md`.

```zsh
cden               # cd /etc/nixos

# 1. edit files...

# 2. track new files (flakes ignore untracked!)
nix-track

# 3. review
config-status
config-diff

# 4. validate
nix-test           # temp activate, safe first try
# nix-build-system # or: build only, no activate

# 5. save + publish (NO sudo for git)
config-savem "Imperative msg, e.g. Enable Blocky NSFW group"
git push

# 6. activate permanently (needs sudo, alias handles it)
nix-switch
```

Emergency: `nix-rollback`, history: `config-log`, generations: `nix-generations`.
