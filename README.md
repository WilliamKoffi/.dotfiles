# dotfiles

GNU Stow packages. Target is `$HOME`.

## Install on a new machine

```bash
sudo apt install stow          # or pacman -S stow, dnf install stow
git clone <this-repo> ~/.dotfiles

# ~/.claude and ~/.claude/skills must exist as REAL directories first,
# or stow folds them into symlinks and captures everything Claude
# later writes there (sessions, projects, 187M of plugins).
mkdir -p ~/.claude/skills

stow -d ~/.dotfiles -t ~ claude
for s in ~/.dotfiles/ai/skills/*; do ln -sfn "$s" ~/.claude/skills/"$(basename "$s")"; done
```

Then, in Claude Code, reinstall the marketplace plugins that `settings.json`
declares — they are not vendored here:

```
/plugin install typescript-lsp@claude-plugins-official
/plugin install php-lsp@claude-plugins-official
/plugin install vercel@claude-plugins-official
```

Restart. `grain` loads as `grain@skills-dir`; check with `/grain:survey`.

## AI material: `ai/`

Not a stow package. Everything AI that is not a tool's own config lives here:

| Path | Carries |
|---|---|
| `ai/skills/<name>/` | The skills: one action word (`scaffold`, `preflight`, `diagnose`…) or `namespace:action` (`grain:survey`, `filament:split`) |
| `ai/decisions/` | Reusable conventions, by system (agents, language, stack, database, money, payments, testing…) and by language and framework (`php`, `php/laravel`, `ts/nuxt`) |

### Decisions: pull, don't fetch

`ai/decisions/` is the library a new project starts from, instead of going back to an old
project to copy what it decided. Each decision is one abstract statement (no project, no
local id), taken or skipped whole; variants conflict (`STK-001` pnpm ↔ `STK-002` bun).
Rules, format and register: `ai/decisions/README.md`.

In the new project, run `/scaffold [stack] [target]`. It asks which languages and
frameworks the project uses (the stack is chosen there, never stored as a decision), then
which decisions to take per system, and writes full copies into the project's
`docs/decisions/` plus a `decisions.lock` (stack, base commit, local number → id). The project then reads on its own; it never links back here.

Commit `~/.dotfiles` before scaffolding: the lock pins the base commit.

Skills are linked one by one into each agent's skill folder:

```bash
for s in ~/.dotfiles/ai/skills/*; do
  ln -sfn "$s" ~/.claude/skills/"$(basename "$s")"
  ln -sfn "$s" ~/.gemini/config/skills/"$(basename "$s")"
done
```

The `claude`, `gemini` and `qwen` stow packages stay at the root.

## What the `claude` package carries

| Path | Why |
|---|---|
| `.claude/CLAUDE.md` | Global pointer to the grain doctrine. No doctrine inline. |
| `.claude/settings.json` | Permissions, model, theme, effort, enabled-plugin list. |
| `.claude/skills/` | Empty; holds links into `ai/skills/` (grain included), not stowed files. |

Nothing else. Everything else under `~/.claude` is machine state Claude
regenerates: `plugins/` (187M, installer-managed), `projects/` (43M),
`file-history/`, `cache/`, `sessions/`, `history.jsonl`, and friends. All are
in `.gitignore`.

`~/.claude/.credentials.json` is **never** committed. If it ever appears in
`git status`, something is wrong with `.gitignore` — fix that before commiting.

## Undo

```bash
stow -D -d ~/.dotfiles -t ~ claude    # removes the symlinks, keeps the repo
```

The real files stay in `~/.dotfiles/claude/.claude/`. Copy them back manually
if you want them un-stowed rather than gone.

## Adding a package

One directory per package, mirroring `$HOME` inside it:

```
~/.dotfiles/nvim/.config/nvim/init.lua   →  stow nvim  →  ~/.config/nvim/init.lua
```

## Termux (Android)

```bash
curl -fsSL https://raw.githubusercontent.com/WilliamKoffi/.dotfiles/main/bootstrap-termux.sh | bash
```

Installs the CLI-only subset via `pkg` and stows `bash bat claude gemini git nvim qwen vim zsh scripts`.
Everything Wayland/X11 (`hyprland niri ironbar mako rofi rio swaylock waybar windsurf code zed`) and
everything systemd/chroot-based (`hooks/`) is skipped — see `bootstrap-termux.sh` for the reasoning.

## Wayland compositor: niri

The daily driver moved from Hyprland to niri. Packages:

```bash
stow niri ironbar swaylock scripts
```

| Package | Carries |
|---|---|
| `niri` | `~/.config/niri/config.kdl` (single file — niri KDL has no include mechanism), `~/.config/xdg-desktop-portal/niri-portals.conf` |
| `ironbar` | `~/.config/ironbar/{config.toml,style.css}` — replaces waybar; niri-native workspace/window modules |
| `swaylock` | `~/.config/swaylock/config` — replaces hyprlock |
| `scripts` | `~/.local/bin/cliphist-paste.lua` + `~/.local/lib/clipboard/*.lua` — the SUPER+V clipboard picker, retargeted from `hyprctl` to `niri msg` |

Install the runtime pieces with `nix profile install nixpkgs#{niri,ironbar,xwayland-satellite,swaybg,xdg-desktop-portal-gnome,fuzzel,playerctl}`.
Idle/lock (`swayidle`/`swaylock`) is spawned from within `niri/.config/niri/config.kdl`, not a separate service.

### Reverting to Hyprland

`hyprland/` and `waybar/` stay in this repo, untouched and unstowed, specifically so this is reversible:

```bash
nix profile install nixpkgs#hyprland
sudo apt install hypridle hyprlock xdg-desktop-portal-hyprland
stow -D niri ironbar swaylock
stow hyprland waybar
```
Then recreate `/usr/local/share/wayland-sessions/hyprland.desktop` (see `hyprland/.config/hypr/` history, or `git log` on this file).
