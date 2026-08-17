# omarchy-tuner — notes for coding agents

Post-[Omarchy](https://omarchy.org/) personalization. This repo is the source
of truth. `./install` symlinks binaries into `~/.local/bin` and wires user
config. Editing the repo is live after install.

`sessionizer/` is the Primeagen-style tmux picker. The command name stays
`sessionizer`. Do not rename the binaries, `~/.config/sessionizer/`, the menu
row key, or the Hyprland app-id.

No compiler, package, or extra runtime. Dependencies are bash, tmux ≥ 3.3
(for fzf `--tmux`), and fzf ≥ 0.53 (Omarchy already has these). herdr is
optional; python3 is required only for the herdr backend (the installer
already uses it).

## Layout

| Path | Role |
| --- | --- |
| `sessionizer/bin/sessionizer` | Picker + create/switch. Resolve this file with `sessionizer_realpath` before taking `..` for `SESSIONIZER_ROOT` — that is the `sessionizer/` package, not the repo root. Install is a symlink from `~/.local/bin/sessionizer`. |
| `sessionizer/bin/sessionizer-harness` | Right-pane agent loop. Same symlink/`sessionizer_realpath` rule. |
| `sessionizer/lib/sessionizer.bash` | Shared helpers. Sourced, never executed. |
| `sessionizer/share/tmux.conf` | `C-f` (root) and prefix+`f` → `run-shell -b sessionizer` |
| `sessionizer/share/herdr.toml` | herdr `ctrl+f` and prefix+`f` popup → `sessionizer` |
| `sessionizer/share/bashrc` | bash Ctrl+F fallback when not inside tmux or herdr |
| `sessionizer/share/sessionizer.lua` | nvim Ctrl+F fallback when not inside tmux or herdr |
| `sessionizer/tests/run` | Sessionizer tests. No bats. |
| `share/tmux.binds.conf` | prefix+`\|`/`-` splits, prefix+hjkl panes, prefix+X kill-window (overrides Omarchy defaults) |
| `share/bindings.lua` | Hyprland Super+Alt+Return and Ctrl+1–0 / H / L workspaces |
| `share/omarchy-menu.jsonc` | Omarchy menu row (template; installer merges) |
| `install` | Idempotent installer for the whole repo. `--check` is the drift test. |
| `tests/run` | Runs `sessionizer/tests/run`. |

## What to run after a change

```bash
./tests/run
./install --check          # after a first install; expect clean
```

New machine, or after changing `share/` / `sessionizer/share/` drop-ins that
install copies into marked blocks: `./install`. Safe to re-run. It reloads
tmux.conf if tmux is up, `herdr server reload-config` if herdr is up, and
`hyprctl reload` + `hyprctl configerrors` if Hyprland is up.

Do not edit `/usr/share/omarchy/`. User wiring is only under `~/.config/` and
`~/.local/bin/`, behind `# omarchy-tuner:begin` / `# omarchy-tuner:end` (Lua uses
`--`). `grep` for those Lua markers **must** be `grep -F -- "$begin"` —
`-- omarchy-tuner:begin` otherwise looks like a grep option.

`./install` migrates leftover `# sessionizer:begin` / `# omarchy-tune:begin`
blocks and `sessionizer.hook` / `omarchy-tune.hook`.

## Install surface

### Existing files edited (marked blocks only)

| File | What the block does |
| --- | --- |
| `~/.bashrc` | `source` of `sessionizer/share/bashrc` |
| `~/.config/tmux/tmux.conf` | `source-file` of `sessionizer/share/tmux.conf` and `share/tmux.binds.conf`. `omarchy refresh tmux` overwrites this file; the post-update hook re-adds the block. |
| `~/.config/herdr/config.toml` | `[[keys.command]]` popup binds for Ctrl+F and prefix+`f`. Only written if `herdr` is on PATH or the file already exists. |
| `~/.config/hypr/bindings.lua` | Unbind Super+Alt+Return (was `omarchy-launch-terminal-tmux` → single session named `Work`) and bind Sessionizer. Also Ctrl+1–0 / H / L workspace navigation. Super+number stays. |
| `~/.config/omarchy/extensions/omarchy-menu.jsonc` | Adds a `sessionizer` row if missing. Does **not** rewrite an existing row. |

### New files only

| Path | What |
| --- | --- |
| `~/.local/bin/sessionizer` | symlink → `sessionizer/bin/sessionizer` |
| `~/.local/bin/sessionizer-harness` | symlink → `sessionizer/bin/sessionizer-harness` |
| `~/.config/nvim/lua/plugins/sessionizer.lua` | symlink → `sessionizer/share/sessionizer.lua` |
| `~/.config/omarchy/hooks/post-update.d/omarchy-tuner.hook` | generated; `exec $ROOT/install` after `omarchy update` |

Never touch: `/usr/share/omarchy/**`, other hypr files, nvim `init.lua` /
`keymaps.lua` / existing plugins, `~/.config/omarchy/defaults/agent`,
`~/.config/omarchy/shell.json`, existing tmux sessions.

`install` refuses to overwrite a non-symlink at a symlink destination.

## Behavior

### Picker

```
sessionizer              # fzf picker
sessionizer <dir>        # attach/create for that path
sessionizer <name>       # exact dir under a root, exact session/workspace, or unique basename prefix
sessionizer --list       # label<TAB>target (existing sessions tagged [tmux] or [herdr], then dirs)
sessionizer --name <path>
sessionizer --no-sessions   # hide the [tmux] / [herdr] rows (combine with --list)
sessionizer-harness --list
```

Default roots: immediate children of `~/Work` (`SESSIONIZER_DEPTH=1`), including
hidden dirs. `tries` is one row, not its children. `~/.config` is also
one row (`SESSIONIZER_EXTRAS`); its children are not listed.

Session name = `basename` with a leading `.` stripped, then `.` and `:` → `_`
(`sessionizer_name`). So `~/.config` is the tmux session `config`. This repo
lists as `omarchy-tuner`.

Selecting an **existing** session or herdr workspace only attaches/switches.
Layout is created only for brand-new sessions/workspaces. To apply a layout
change, the user must kill that session (or close that herdr workspace) first.
A leftover session named `sessionizer` or `omarchy-tune` will not become
`omarchy-tuner` until it is killed and recreated.

Inside tmux the picker is `fzf --tmux=center,80%,70%`. **Never wrap
`sessionizer` in `tmux display-popup`** — that nests and fails silently.
Inside herdr the keybind opens a `type = "popup"` and fzf is inline
(`--height=100%`); do not also use `fzf --tmux` there (herdr can sit inside
tmux). Outside both, fzf is fullscreen in the current terminal, then attach.
Hyprland launches via `omarchy-launch-tui`; if sessionizer exits non-zero in
a non-tmux, non-herdr TTY it pauses so the window does not flash closed. fzf
cancel is exit 0.

Private tmux server for tests: `SESSIONIZER_TMUX_SOCKET=...`.
Private herdr session for tests: `SESSIONIZER_HERDR_SESSION=...`.

Optional `~/.config/sessionizer/config` (sourced if present):

```bash
SESSIONIZER_ROOTS=("$HOME/Work")
SESSIONIZER_DEPTH=1
SESSIONIZER_EXTRAS=("$HOME/.config")
SESSIONIZER_BACKEND=auto          # auto | tmux | herdr
# SESSIONIZER_HERDR_SESSION=      # named herdr session; unset = default
```

`SESSIONIZER_BACKEND` (`auto` if unset):

| Value | Behavior |
| --- | --- |
| `auto` | `HERDR_ENV=1` → herdr workspace. Otherwise tmux (including Super+Alt+Return). |
| `herdr` | Always herdr, including desktop launch. |
| `tmux` | Always tmux. |

On herdr, each project is a **workspace** labeled with `sessionizer_name`
inside one herdr session (the default, or `SESSIONIZER_HERDR_SESSION`).
That matches herdr's own model: tmux session → workspace, window → tab,
pane → pane. Do not create one herdr session per project.

`SESSIONIZER_ROOTS` and `SESSIONIZER_EXTRAS` are bash arrays. They are not
exported to child processes; tests that exec `sessionizer/bin/sessionizer`
must set them via that config file (and usually a fake `HOME`). An extra is
listed as itself (hidden names allowed). Unset extras default to `~/.config`;
set `SESSIONIZER_EXTRAS=()` to hide it.

### New session layout

1. Window `nvim` — `automatic-rename off`. Sends `nvim .` (or Omarchy's
   default *terminal* editor + ` .`). GUI editors fall back to nvim.
   Editor file: `~/.local/state/omarchy/defaults/editor`. Do not use `$EDITOR`
   — on Omarchy that is `omarchy-launch-editor --inline`.
2. Window `scratch` — `automatic-rename off`. `split-window -h`: left is the
   default shell, right is `sessionizer-harness`. Focus stays on `nvim`.

Omarchy tmux has `base-index 1` and global `automatic-rename on`; the
per-window off is required so names stay `nvim` / `scratch`.

The herdr layout is the same shape: tab `nvim` (`pane run` the editor), tab
`scratch` split right onto `sessionizer-harness`, then focus `nvim`.

### Harness pane

`sessionizer-harness` loops: fzf list → run agent → on exit, list again.
Escape on fzf re-prompts. `shell` is `exec $SHELL` and leaves the loop.

Roster, in order: `grok pi omp`, then `shell`. Only binaries on `PATH` are
shown; `shell` is always last. Launch flags must match `omarchy-agent --inline`:

| Agent | argv |
| --- | --- |
| grok | `grok --permission-mode bypassPermissions` |
| pi | `pi` |
| omp | `omp --auto-approve` |
| shell | `${SHELL:-bash}` |

Picking a harness does **not** write `~/.config/omarchy/defaults/agent`.

The harness picker is inline fzf in that pane (not `--tmux`). That pane is
the selector UI.

## Keys

| Surface | Binding | Notes |
| --- | --- |
| tmux (anywhere) | Ctrl+F | Root table. Works in shell, nvim, and agent TUIs. This is the one the user actually uses. |
| tmux | prefix+f (`C-a f`) | Same `run-shell -b sessionizer` |
| herdr (anywhere) | Ctrl+F | `[[keys.command]]` popup. Same picker; creates/focuses a workspace. |
| herdr | prefix+f (`C-a f`) | Same popup. |
| bash, not in tmux | Ctrl+F | Inserts `sessionizer` + newline. **Do not use `bind -x`** — fzf gets no TTY. |
| nvim, not in tmux | `<C-f>` | `sessionizer/share/sessionizer.lua` |
| Hyprland | Super+Alt+Return | `omarchy-launch-tui --app-id=org.omarchy.sessionizer sessionizer`. Previously the single `Work` session. |
| Hyprland | Ctrl+1–0 | Switch to workspace 1–10. Super+number is unchanged. |
| Hyprland | Ctrl+H / Ctrl+L | Previous / next workspace. |
| tmux | prefix+\| / prefix+- | Split side-by-side / stacked. Overrides Omarchy prefix+h/v. |
| tmux | prefix+h/j/k/l | Focus pane. prefix+k was kill-window. |
| tmux | prefix+X | Kill window. prefix+x is still kill-pane. |

## Invariants / landmines

- `SESSIONIZER_ROOT` is the `sessionizer/` package. Resolve install
  symlinks with `sessionizer_realpath "${BASH_SOURCE[0]}"` before taking
  `..`. Linux uses `readlink -f`; Darwin walks with BSD `readlink` (no `-f`).
  Using `dirname` of the symlink path looks for `~/.local/lib/sessionizer.bash`
  and dies. Taking `../..` from the binary looks for the repo root and also
  dies (`lib/` is not there). The walk is inlined in both binaries because
  they must resolve before they can source `lib/`.
- Install `ROOT` is the repo root (`dirname` of `./install`). Sessionizer
  paths are `$ROOT/sessionizer/...`.
- `set -u`: `SESSIONIZER_ROOTS` may be unset. Use `[[ ! -v SESSIONIZER_ROOTS ]]`
  (see `sessionizer_load_config`).
- `has-session -t "=$name"` (exact). Session names cannot contain `.` or `:`.
- Do not replace Omarchy's `tdl` / `tds` / `tsl` pane helpers.
- After Hyprland bind edits: `hyprctl reload` then `hyprctl configerrors`
  must be empty. See the omarchy skill (`~/.agents/skills/omarchy/`).
- Existing sessions and herdr workspaces are never rebuilt. Say so if a
  layout change will not appear until the user kills the session (or
  closes the herdr workspace).
- Desktop Super+Alt+Return stays tmux unless `SESSIONIZER_BACKEND=herdr`.
- `upsert_menu` is insert-if-missing. Changing the menu action later needs
  an edit of the user's jsonc (or a smarter installer).
