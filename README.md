# omarchy-tuner

Personalization layer on top of [Omarchy](https://omarchy.org/). Clone this after
a fresh Omarchy install, run `./install`, and the machine picks up the binds
and tools below.

Safe to re-run. `./install --check` reports drift without writing.

Today the main tool is **sessionizer**, a Primeagen-style project picker.
The command name stays `sessionizer`. It attaches or creates a tmux session.
Super+Alt+Return from the desktop launches that picker.

Ctrl+F inside tmux (or Super+Alt+Return from the desktop) lists the folders
in `~/Work`, plus `~/.config`. `[ + New ]` makes a new folder under `~/Work`
and attaches. Picking an existing row attaches:

| Window | Contents |
| --- | --- |
| `nvim` | `nvim .` in the project directory |
| `scratch` | Shell on the left, harness selector on the right |

The harness selector lists `grok`, `pi`, `omp`, then `shell`. Only installed
agents appear. Quitting an agent returns to the list so you can switch.

## Install (any Omarchy machine)

```bash
git clone <this-repo> ~/Work/omarchy-tuner
cd ~/Work/omarchy-tuner
./install
```

### What it edits

Marked blocks only (`# omarchy-tuner:begin` … `# omarchy-tuner:end`):

- `~/.bashrc` — Ctrl+F
- `~/.config/tmux/tmux.conf` — prefix+f popup; prefix+|/- splits, hjkl panes, X kill-window
- `~/.grok/config.toml` — `[ui] screen_mode = "minimal"` (only if grok is present)
- `~/.config/hypr/bindings.lua` — Super+Alt+Return (was: attach to a session named `Work`); Ctrl+1–0 / H / L workspaces; mouse:275 + horizontal flick between workspaces
- `~/.config/hypr/input.lua` — Caps Lock as Ctrl; natural scroll; touchpad disable-while-typing, two-finger right-click, no tap-click
- `~/.config/hypr/looknfeel.lua` — workspace slide animation (Omarchy default is off)
- `~/.config/omarchy/extensions/omarchy-menu.jsonc` — strips a leftover Sessionizer row if a previous install added one
- `~/.config/omarchy/shell.json` — leftover `omarchy-tuner.weather` → stock `omarchy.weather`

And it adds:

- `~/.local/bin/sessionizer` and `sessionizer-harness` (symlinks)
- `~/.config/nvim/lua/plugins/sessionizer.lua` (Ctrl+F in nvim)
- `~/.config/nvim/lua/plugins/sessionizer-neo-tree.lua` (wipe leftover `[No Name]` after Neo-tree opens a file)
- `~/.config/uwsm/env.d/20-ssh-agent` (`SSH_AUTH_SOCK` for the OpenSSH user agent)
- `~/.config/omarchy/hooks/post-update.d/omarchy-tuner.hook` (re-applies after `omarchy update`)

A previous `sessionizer` or `omarchy-tune` install is migrated: old marked
blocks and `sessionizer.hook` / `omarchy-tune.hook` are removed. Leftover
herdr marked blocks are stripped; herdr is not configured.

Nothing under `/usr/share/omarchy/` is touched.

## Install (macOS)

Do not run `./install`. That script is Omarchy-only.

```bash
# tmux ≥ 3.3, fzf ≥ 0.53
brew install tmux fzf
mkdir -p ~/.local/bin
ln -sfn ~/Work/omarchy-tuner/sessionizer/bin/sessionizer ~/.local/bin/sessionizer
ln -sfn ~/Work/omarchy-tuner/sessionizer/bin/sessionizer-harness ~/.local/bin/sessionizer-harness
```

Put `~/.local/bin` on `PATH`. Keep those command names; the symlink must point at the clone so `lib/` resolves.

### tmux

In `~/.config/tmux/tmux.conf` (or `~/.tmux.conf`):

```tmux
source-file ~/Work/omarchy-tuner/sessionizer/share/tmux.conf
source-file ~/Work/omarchy-tuner/share/tmux.binds.conf
```

The first file is Ctrl+F and prefix+`f` → sessionizer. Do not wrap that in `display-popup`. The second is prefix `C-a`, `|/‑` splits, hjkl panes, `X` kill-window — skip it if you only want the picker.

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

### Optional (outside tmux)

```zsh
# ~/.zshrc
bindkey -s '^F' '^Usessionizer\n'
```

```bash
ln -sfn ~/Work/omarchy-tuner/sessionizer/share/sessionizer.lua ~/.config/nvim/lua/plugins/sessionizer.lua
ln -sfn ~/Work/omarchy-tuner/sessionizer/share/neo-tree.lua ~/.config/nvim/lua/plugins/sessionizer-neo-tree.lua
```

No Super+Alt+Return equivalent. Existing sessions are not rebuilt.

## Usage

```
sessionizer              # fzf picker ([ + New ] makes a new ~/Work folder)
sessionizer ~/Work/foo   # jump straight there
sessionizer foo          # match a ~/Work child or existing session
sessionizer --create foo # mkdir ~/Work/foo and attach
```

Inside tmux the picker is a popup. Outside tmux, fzf runs in the current
terminal and then attaches.

## Config

Optional `~/.config/sessionizer/config`:

```bash
SESSIONIZER_ROOTS=("$HOME/Work")
SESSIONIZER_DEPTH=1
SESSIONIZER_EXTRAS=("$HOME/.config")   # listed as itself, not scanned
```

## Tests

```bash
./tests/run
```
