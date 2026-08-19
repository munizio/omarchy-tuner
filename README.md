# omarchy-tuner

Personalization layer on top of [Omarchy](https://omarchy.org/). Clone this after
a fresh Omarchy install, run `./install`, and the machine picks up the binds,
menu row, and tools below.

Safe to re-run. `./install --check` reports drift without writing.

Today the main tool is **sessionizer**, a Primeagen-style project picker.
The command name stays `sessionizer`. Inside tmux it attaches a tmux session;
inside herdr it focuses a herdr workspace. Super+Alt+Return stays tmux unless
you set `SESSIONIZER_BACKEND=herdr`.

Ctrl+F inside tmux or herdr (or Super+Alt+Return from the desktop) lists the
folders in `~/Work`, plus `~/.config`. Picking one attaches:

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
- `~/.config/herdr/config.toml` — Ctrl+F and prefix+f popup; prefix `ctrl+a`; prefix+j / prefix+k workspace next/prev (only if herdr is present)
- `~/.grok/config.toml` — `[ui] screen_mode = "minimal"` (only if grok is present)
- `~/.config/hypr/bindings.lua` — Super+Alt+Return (was: attach to a session named `Work`); Ctrl+1–0 / H / L workspaces
- `~/.config/hypr/input.lua` — mouse and touchpad natural scrolling
- `~/.config/omarchy/extensions/omarchy-menu.jsonc` — Sessionizer menu row

And it adds:

- `~/.local/bin/sessionizer` and `sessionizer-harness` (symlinks)
- `~/.config/nvim/lua/plugins/sessionizer.lua` (Ctrl+F in nvim)
- `~/.config/omarchy/hooks/post-update.d/omarchy-tuner.hook` (re-applies after `omarchy update`)

A previous `sessionizer` or `omarchy-tune` install is migrated: old marked
blocks and `sessionizer.hook` / `omarchy-tune.hook` are removed.

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

### herdr

Append `sessionizer/share/herdr.toml` to `~/.config/herdr/config.toml`, then `herdr server reload-config`.

`auto` backend: herdr only when already inside herdr; otherwise tmux.

### Optional (outside tmux / herdr)

```zsh
# ~/.zshrc
bindkey -s '^F' '^Usessionizer\n'
```

```bash
ln -sfn ~/Work/omarchy-tuner/sessionizer/share/sessionizer.lua ~/.config/nvim/lua/plugins/sessionizer.lua
```

No Super+Alt+Return equivalent. Existing sessions are not rebuilt.

## Usage

```
sessionizer              # fzf picker
sessionizer ~/Work/foo   # jump straight there
sessionizer foo          # match a ~/Work child or existing session
```

Inside tmux the picker is a popup. Inside herdr it is a herdr popup. Outside
both, fzf runs in the current terminal and then attaches.

## Config

Optional `~/.config/sessionizer/config`:

```bash
SESSIONIZER_ROOTS=("$HOME/Work")
SESSIONIZER_DEPTH=1
SESSIONIZER_EXTRAS=("$HOME/.config")   # listed as itself, not scanned
SESSIONIZER_BACKEND=auto               # auto | tmux | herdr
```

`auto` uses herdr only when already inside herdr (`HERDR_ENV=1`). Set
`SESSIONIZER_BACKEND=herdr` to make Super+Alt+Return attach herdr too.

## Tests

```bash
./tests/run
```
