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
- `~/.config/herdr/config.toml` — Ctrl+F and prefix+f popup (only if herdr is present)
- `~/.config/hypr/bindings.lua` — Super+Alt+Return (was: attach to a session named `Work`); Ctrl+1–0 / H / L workspaces
- `~/.config/omarchy/extensions/omarchy-menu.jsonc` — Sessionizer menu row

And it adds:

- `~/.local/bin/sessionizer` and `sessionizer-harness` (symlinks)
- `~/.config/nvim/lua/plugins/sessionizer.lua` (Ctrl+F in nvim)
- `~/.config/omarchy/hooks/post-update.d/omarchy-tuner.hook` (re-applies after `omarchy update`)

A previous `sessionizer` or `omarchy-tune` install is migrated: old marked
blocks and `sessionizer.hook` / `omarchy-tune.hook` are removed.

Nothing under `/usr/share/omarchy/` is touched.

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
