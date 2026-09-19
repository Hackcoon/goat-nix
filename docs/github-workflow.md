# GitHub Kickstart + NixOS Daily Workflow

Single guide for: (A) pushing any local folder to GitHub, (B) daily NixOS config edits now that `/etc/nixos` is on GitHub.

Rule #1: `gh` + `git push/pull` run WITHOUT sudo. Only `nixos-rebuild` needs sudo. Your files in `/etc/nixos` are owned by `fury`, so plain `git` works. `sudo git` breaks HTTPS auth (root can't see your token).

---

## 0. One-time setup (per machine)

```zsh
gh auth login
# Choose: GitHub.com -> HTTPS -> Yes (paste token when asked, NOT password)
# Login WITHOUT sudo. Verify:
gh auth status
gh auth setup-git
git config --global user.name "furynix"
git config --global user.email "235014707+Hackcoon@users.noreply.github.com"
git config --global init.defaultBranch main
```

HTTPS vs SSH: HTTPS works immediately with `gh`. Use SSH only if you already have keys on GitHub (`gh ssh-key add`). Switch later with `git remote set-url origin git@github.com:YOU/REPO.git`.

---

## A. New local folder -> new GitHub repo (any project)

```zsh
cd /path/to/project
git init -b main
cat > .gitignore <<'EOF'
result
result-*
*.bak*
*.tar.gz
node_modules/
dist/
build/
.env
EOF
git add -A
git status --short --branch
git commit -m "Initial commit"
gh repo create REPO-NAME --private --source=. --push
# e.g. gh repo create fury-nixOS --private --source=. --push
git push -u origin main
```

Make public later: GitHub repo page -> Settings -> General -> Danger Zone -> Change visibility. Or `gh repo edit REPO --visibility public`.

---

## B. Existing local git repo (like /etc/nixos was) -> GitHub

```zsh
cden  # cd /etc/nixos
git status --short --branch
git remote -v  # empty = no remote yet
gh repo create fury-nixOS --private --source=. --push
git push -u origin main
```

If remote already exists but wrong URL:
```zsh
git remote set-url origin https://github.com/YOU/fury-nixOS.git
git push -u origin main
```

---

## C. Daily NixOS edit loop (use your aliases)

```zsh
cden
# 1. edit files (configuration.nix, modules/...)
# 2. track NEW files first — flakes ignore untracked files!
nix-track        # = git -C /etc/nixos add -A
# 3. review
config-status    # changed + untracked
config-diff      # what changed
# 4. validate before activating
nix-test         # temp activate, no boot entry
# or: nix-build-system  (build only)
# 5. save + publish
config-savem "Short imperative msg, e.g. Add Blocky NSFW docs"
git push
# 6. activate permanently (only after test looks good)
nix-switch
```

Alias map: `config-diff` (diff), `config-status`, `config-log` (last 10), `config-save` (prompt for msg), `config-savem "msg"` (inline msg), `nix-track`, `nix-test`, `nix-switch`/`nix-rebuild`, `nix-generations`, `nix-rollback`.

---

## D. Before first public push (secrets + junk check)

```zsh
cden
# secrets — must return nothing sensitive:
grep -rniE "password|api[_-]?key|secret|token|BEGIN.*PRIVATE" --exclude-dir=.git --exclude=flake.lock . | head
# junk — result symlink, tarballs, .bak must NOT be tracked:
git ls-files | grep -E "^(result|.*\.bak|.*\.tar\.gz)$"
# fix if found:
git rm --cached result config-backup-*.tar.gz <any.bak-file>
echo -e "result\nresult-*\n*.bak*\n*.tar.gz" >> .gitignore
config-savem "Cleanup before public push"
```

Safe to publish: `hardware-configuration.nix` UUIDs (everyone publishes these), `flake.lock` (pin versions, good). Never publish: `/var/lib/searx/searx.env`, API keys in `settings`/`environment` (use sops-nix/agenix `environmentFiles` instead).

---

## E. Errors you already hit (fixes)

| Error | Cause | Fix |
|---|---|---|
| `Invalid username or token. Password auth not supported` | `sudo git push` (root has no token) or typed password not token | Push WITHOUT sudo: `git push`. If needed: `gh auth login` (no sudo) + `gh auth setup-git` |
| `src refspec master does not match any` | Local branch is `main`, you pushed `master` | `git branch -a` to check, then `git push -u origin main` |
| `Path X is not tracked by Git` on rebuild | New file not staged; flakes only see git-tracked files | `nix-track` before every rebuild |
| `Failed to start transient service unit` on `dry-activate` | Ran rebuild without sudo / non-interactive | Normal for dry-activate without sudo; use `nix-test` (with sudo) or `nixos-rebuild build` to validate |
| `field allowLists not found` (Blocky) | Stable Blocky 0.29 uses `whiteLists/blackLists`; new docs use `allowLists/denyLists` | Keep `whiteLists/blackLists` on 0.29. Only rename if you override to unstable 0.34 |

Change remote default branch: push `main`, then GitHub Settings -> General -> Default branch -> `main`, then `git push origin --delete master`.

---

## F. New machine / clone down

```zsh
gh repo clone YOU/fury-nixOS /etc/nixos   # or: git clone https://github.com/YOU/fury-nixOS.git
cd /etc/nixos
sudo nixos-rebuild switch --flake .#nixos
```

Never copy `/etc/secureboot` keys or `/var/lib/searx/searx.env` via git — move those manually with a USB stick.
