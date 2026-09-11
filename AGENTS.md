# omarchy-tuner — notes for coding agents

Post-[Omarchy](https://omarchy.org/) personalization. This repo is the source
of truth. `./install` symlinks binaries into `~/.local/bin` and wires user
config. Editing the repo is live after install.

`sessionizer/` is the Primeagen-style tmux picker. The command name stays
`sessionizer`. Do not rename the binaries, `~/.config/sessionizer/`, or the
Hyprland app-id.

No compiler, package, or extra runtime. Dependencies are bash, tmux ≥ 3.3
(for fzf `--tmux`), and fzf ≥ 0.53 (Omarchy already has these). python3 is
used by the installer (menu row removal, leftover weather bar id, and grok toml).

## Layout

| Path | Role |
| --- | --- |
| `sessionizer/bin/sessionizer` | Picker + create/switch. Resolve this file with `sessionizer_realpath` before taking `..` for `SESSIONIZER_ROOT` — that is the `sessionizer/` package, not the repo root. Install is a symlink from `~/.local/bin/sessionizer`. |
| `sessionizer/bin/sessionizer-harness` | Right-pane agent loop. Same symlink/`sessionizer_realpath` rule. |
| `sessionizer/lib/sessionizer.bash` | Shared helpers. Sourced, never executed. |
| `sessionizer/share/tmux.conf` | `C-f` (root) and prefix+`f` → `run-shell -b sessionizer` |
| `sessionizer/share/bashrc` | bash Ctrl+F fallback when not inside tmux |
| `sessionizer/share/sessionizer.lua` | nvim Ctrl+F fallback when not inside tmux |
| `sessionizer/share/neo-tree.lua` | Wipe leftover `[No Name]` after opening a file from Neo-tree (`nvim .`) |
| `sessionizer/tests/run` | Sessionizer tests. No bats. |
| `share/tmux.binds.conf` | prefix+`\|`/`-` splits, prefix+hjkl panes, prefix+`;` last pane (keep zoom), prefix+X kill-window (overrides Omarchy defaults) |
| `share/bindings.lua` | Hyprland Super+Alt+Return, Ctrl+1–0 / H / L workspaces, mouse:275 workspace flick |
| `share/input.lua` | Caps Lock as Ctrl; natural scroll; touchpad disable-while-typing, clickfinger, no tap-click; three-finger horizontal workspace swipe |
| `share/looknfeel.lua` | Workspace slide animation (Omarchy default is off) |
| `share/uwsm/env.d/20-ssh-agent` | `SSH_AUTH_SOCK` for the OpenSSH user agent. Does not enable the socket. |
| `install` | Idempotent installer for the whole repo. `--check` is the drift test. |
| `tests/run` | Runs `sessionizer/tests/run`. |

## What to run after a change

```bash
./tests/run
./install --check          # after a first install; expect clean
```

New machine, or after changing `share/` / `sessionizer/share/` drop-ins that
install copies into marked blocks: `./install`. Safe to re-run. It reloads
tmux.conf if tmux is up, and `hyprctl reload` + `hyprctl configerrors` if
Hyprland is up.

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
| `~/.grok/config.toml` | Sets `[ui] screen_mode = "minimal"`. Only written if `grok` is on PATH or the file already exists. |
| `~/.config/hypr/bindings.lua` | Unbind Super+Alt+Return (was `omarchy-launch-terminal-tmux` → single session named `Work`) and bind Sessionizer. Also Super+Shift+A rebinds ChatGPT → Grok (Super+Shift+Alt+A stays Grok). Also Ctrl+1–0 / H / L workspace navigation and mouse:275 + horizontal flick (adjacent IDs, no wrap, empty neighbor allowed). Super+number stays. |
| `~/.config/hypr/input.lua` | `kb_options = "ctrl:nocaps"` (Caps Lock as Ctrl; Omarchy ships `compose:caps`). Mouse and touchpad `natural_scroll = true`. Touchpad `disable_while_typing = true`, `clickfinger_behavior = true`, `tap_to_click = false`. Three-finger horizontal swipe is Hyprland's 1:1 workspace gesture (desktop follows fingers; commit/cancel uses the `workspaces` slide animation). |
| `~/.config/hypr/looknfeel.lua` | Enables `workspaces` slide animation (Omarchy ships it disabled). |
| `~/.config/omarchy/extensions/omarchy-menu.jsonc` | Removes a leftover `sessionizer` row if present. Super+Alt+Return stays. |
| `~/.config/omarchy/shell.json` | Restores leftover `omarchy-tuner.weather` to `omarchy.weather`. Does not add weather if the slot is gone. Does not rewrite other bar entries. |

### New files only

| Path | What |
| --- | --- |
| `~/.local/bin/sessionizer` | symlink → `sessionizer/bin/sessionizer` |
| `~/.local/bin/sessionizer-harness` | symlink → `sessionizer/bin/sessionizer-harness` |
| `~/.config/nvim/lua/plugins/sessionizer.lua` | symlink → `sessionizer/share/sessionizer.lua` |
| `~/.config/nvim/lua/plugins/sessionizer-neo-tree.lua` | symlink → `sessionizer/share/neo-tree.lua` (no-op unless Neo-tree is already installed) |
| `~/.config/uwsm/env.d/20-ssh-agent` | symlink → `share/uwsm/env.d/20-ssh-agent` (`SSH_AUTH_SOCK`). Socket is not enabled by install. |
| `~/.config/omarchy/hooks/post-update.d/omarchy-tuner.hook` | generated; `exec $ROOT/install` after `omarchy update` |

Never touch: `/usr/share/omarchy/**`, other hypr files (except `bindings.lua`,
`input.lua`, and `looknfeel.lua`), nvim `init.lua` / `keymaps.lua` / existing plugins,
`~/.config/omarchy/defaults/agent`, existing tmux sessions. `shell.json` is
only edited to restore leftover `omarchy-tuner.weather` → `omarchy.weather`.
Do not clone weather or replace the stock bar widget. Do not write herdr
config or change herdr's prefix. `./install` only strips leftover
`# omarchy-tuner:` / `# sessionizer:` / `# omarchy-tune:` blocks from
`~/.config/herdr/config.toml` if a previous install left them.

`install` refuses to overwrite a non-symlink at a symlink destination.

## Behavior

### Picker

```
sessionizer              # fzf picker ([ + New ] is the last row)
sessionizer <dir>        # attach/create for that path
sessionizer <name>       # exact dir under a root, exact session, or unique basename prefix
sessionizer --list       # label<TAB>target ([tmux] sessions, then dirs, then [ + New ])
sessionizer --name <path>
sessionizer --create [name] # mkdir under the first root and attach (prompt if no name)
sessionizer --no-sessions   # hide the [tmux] rows (combine with --list)
sessionizer-harness --list
```

Default roots: immediate children of `~/Work` (`SESSIONIZER_DEPTH=1`), including
hidden dirs. `tries` is one row, not its children. `~/.config` is also
one row (`SESSIONIZER_EXTRAS`); its children are not listed.

Picking `[ + New ]` opens a second fzf prompt for a directory name (Enter
prints the query; Escape twice, or Escape then `q`, cancels). The new folder
is an immediate child of the first `SESSIONIZER_ROOTS` entry (`~/Work` by
default). Names cannot contain `/`. If that directory already exists, it is
reused. Then the usual new-session layout runs. `sessionizer --create <name>`
skips the pickers.
The name prompt is fzf, not `read` — Ctrl+F is `run-shell -b` and has no TTY.

Session name = `basename` with a leading `.` stripped, then `.` and `:` → `_`
(`sessionizer_name`). So `~/.config` is the tmux session `config`. This repo
lists as `omarchy-tuner`.

Selecting an **existing** session only attaches/switches. Layout is created
only for brand-new sessions. To apply a layout change, the user must kill
that session first. A leftover session named `sessionizer` or `omarchy-tune`
will not become `omarchy-tuner` until it is killed and recreated.

Inside tmux the picker is `fzf --tmux=center,80%,70%`. **Never wrap
`sessionizer` in `tmux display-popup`** — that nests and fails silently.
Outside tmux, fzf is fullscreen in the current terminal, then attach.
Hyprland launches via `omarchy-launch-tui`; if sessionizer exits non-zero in
a non-tmux TTY it pauses so the window does not flash closed. fzf cancel is
exit 0.

Every interactive picker (project list, new-name prompt, harness list) has a
pseudo-vim normal mode from `sessionizer_fzf_vim_bindings`: Escape enters it
(prompt shows `[N] `), `j`/`k`/`h`/`l` move, `g`/`G` jump to first/last, `q`
aborts. `i` returns to insert; a second Escape aborts. Enter still accepts.
No new dependency — it is all fzf `--bind`/`transform` actions (fzf ≥ 0.53).

Private tmux server for tests: `SESSIONIZER_TMUX_SOCKET=...`.

Optional `~/.config/sessionizer/config` (sourced if present):

```bash
SESSIONIZER_ROOTS=("$HOME/Work")
SESSIONIZER_DEPTH=1
SESSIONIZER_EXTRAS=("$HOME/.config")
```

`SESSIONIZER_ROOTS` and `SESSIONIZER_EXTRAS` are bash arrays. They are not
exported to child processes; tests that exec `sessionizer/bin/sessionizer`
must set them via that config file (and usually a fake `HOME`). An extra is
listed as itself (hidden names allowed). Unset extras default to `~/.config`;
set `SESSIONIZER_EXTRAS=()` to hide it.

### New session layout

1. Window `nvim` — `automatic-rename off`. Sends `nvim .` (or Omarchy's
   default *terminal* editor + ` .`). GUI editors fall back to nvim.
   Editor file: `~/.local/state/omarchy/defaults/editor`. Do not use `$EDITOR`
   — on Omarchy that is `omarchy-launch-editor --inline`. Neo-tree hijacks
   that directory and leaves a listed `[No Name]` buffer; `sessionizer-neo-tree.lua`
   wipes it when a file is opened. Restart nvim to pick up the plugin.
2. Window `scratch` — `automatic-rename off`. `split-window -h`: left is the
   default shell, right is `sessionizer-harness`. Focus stays on `nvim`.

Omarchy tmux has `base-index 1` and global `automatic-rename on`; the
per-window off is required so names stay `nvim` / `scratch`.

### Harness pane

`sessionizer-harness` loops: fzf list → run agent → on exit, list again.
Escape on fzf enters normal mode (see below); `q` or a second Escape re-prompts.
`shell` is `exec $SHELL` and leaves the loop.

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
| bash, not in tmux | Ctrl+F | Inserts `sessionizer` + newline. **Do not use `bind -x`** — fzf gets no TTY. |
| nvim, not in tmux | `<C-f>` | `sessionizer/share/sessionizer.lua` |
| fzf pickers | Escape | Pseudo-vim normal mode (`[N] ` prompt): `j`/`k`/`h`/`l` move, `g`/`G` first/last, `q` aborts. `i` returns to insert; second Escape aborts. |
| Hyprland | Super+Alt+Return | `omarchy-launch-tui --app-id=org.omarchy.sessionizer sessionizer`. Previously the single `Work` session. |
| Hyprland | Ctrl+1–0 | Switch to workspace 1–10. Super+number is unchanged. |
| Hyprland | Ctrl+H / Ctrl+L | Previous / next workspace. |
| Hyprland | mouse:275 + horizontal flick | Side button (BTN_SIDE) hold + flick. Right → previous ID, left → next ID. Does not wrap. An empty neighbor is allowed (one empty workspace past the occupied range). Click without moving does nothing. `mouse:276` is the other side button. Consumes the button (browser back/forward will not fire). Workspace changes use Hyprland `slide`. |
| Hyprland | 3-finger horizontal touchpad swipe | Native Hyprland workspace gesture. Desktop follows the fingers; lift to commit or cancel. Same `workspaces` slide animation as the mouse flick. Default invert: fingers right → previous ID. |
| tmux | prefix+\| / prefix+- | Split side-by-side / stacked. Overrides Omarchy prefix+h/v. |
| tmux | prefix+h/j/k/l | Focus pane. prefix+k was kill-window. |
| tmux | prefix+`;` | Last pane, keep zoom (`select-pane -lZ`). |
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
- Existing sessions are never rebuilt. Say so if a layout change will not
  appear until the user kills the session.
- Super+Alt+Return launches sessionizer in tmux. Do not add a herdr backend
  or write `~/.config/herdr/`.
- `20-ssh-agent` only exports `SSH_AUTH_SOCK`. Do not enable `ssh-agent.socket`
  or write `~/.ssh/config` from `./install`. UWSM env applies on the next
  graphical session.
- Do not add a Sessionizer row to the Omarchy menu. `remove_menu_row` strips
  a leftover `sessionizer` key from the user jsonc if a previous install
  inserted one.
- Do not ship a weather plugin. Stock `omarchy.weather` stays on the bar.
  `./install` restores that id if a leftover `omarchy-tuner.weather` slot
  remains, and removes `~/.config/omarchy/plugins/omarchy-tuner.weather`.
