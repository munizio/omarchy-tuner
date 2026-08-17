# Shared helpers for sessionizer and sessionizer-harness.
# Sourced, not executed.

# Canonical path of a file that may be a symlink. Linux: readlink -f.
# Darwin has no readlink -f; walk the chain with BSD readlink.
sessionizer_realpath_walk() {
  local path="$1" dir
  if [[ $path != /* ]]; then
    path="$(pwd)/$path"
  fi
  while [[ -L $path ]]; do
    dir="$(cd "$(dirname "$path")" && pwd)"
    path="$(readlink "$path")"
    [[ $path == /* ]] || path="$dir/$path"
  done
  dir="$(cd "$(dirname "$path")" && pwd)"
  printf '%s\n' "$dir/$(basename "$path")"
}

sessionizer_realpath() {
  local path="$1"
  case "$(uname -s)" in
  Darwin) sessionizer_realpath_walk "$path" ;;
  *) readlink -f "$path" ;;
  esac
}

# Harness selector roster, in display order. Launch flags still match
# omarchy-agent --inline. shell is always last and always listed.
SESSIONIZER_AGENTS=(grok pi omp opencode claude)

sessionizer_load_config() {
  local config="${XDG_CONFIG_HOME:-$HOME/.config}/sessionizer/config"
  # Defaults before the user file so it can append to SESSIONIZER_ROOTS
  # / SESSIONIZER_EXTRAS.
  if [[ ! -v SESSIONIZER_ROOTS || ${#SESSIONIZER_ROOTS[@]} -eq 0 ]]; then
    SESSIONIZER_ROOTS=("$HOME/Work")
  fi
  if [[ ! -v SESSIONIZER_EXTRAS ]]; then
    SESSIONIZER_EXTRAS=("$HOME/.config")
  fi
  : "${SESSIONIZER_DEPTH:=1}"
  : "${SESSIONIZER_BACKEND:=auto}"
  if [[ -f $config ]]; then
    # shellcheck disable=SC1090
    source "$config"
  fi
  if [[ ! -v SESSIONIZER_ROOTS || ${#SESSIONIZER_ROOTS[@]} -eq 0 ]]; then
    SESSIONIZER_ROOTS=("$HOME/Work")
  fi
  if [[ ! -v SESSIONIZER_EXTRAS ]]; then
    SESSIONIZER_EXTRAS=("$HOME/.config")
  fi
  : "${SESSIONIZER_BACKEND:=auto}"
}

sessionizer_tmux() {
  if [[ -n ${SESSIONIZER_TMUX_SOCKET:-} ]]; then
    command tmux -L "$SESSIONIZER_TMUX_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

# auto: HERDR_ENV=1 → herdr, otherwise tmux.
# herdr / tmux: force that backend (desktop Super+Alt+Return stays tmux unless herdr).
sessionizer_backend() {
  local backend="${SESSIONIZER_BACKEND:-auto}"
  case "$backend" in
  herdr | tmux)
    printf '%s\n' "$backend"
    ;;
  auto)
    if [[ ${HERDR_ENV:-} == 1 ]]; then
      printf 'herdr\n'
    else
      printf 'tmux\n'
    fi
    ;;
  *)
    echo "sessionizer: unknown SESSIONIZER_BACKEND: $backend" >&2
    return 1
    ;;
  esac
}

# Talk to a herdr session socket. SESSIONIZER_HERDR_SESSION selects a named
# session (tests). Unset means the default session.
sessionizer_herdr() {
  if [[ -n ${SESSIONIZER_HERDR_SESSION:-} ]]; then
    command herdr --session "$SESSIONIZER_HERDR_SESSION" "$@"
  else
    command herdr "$@"
  fi
}

sessionizer_herdr_session_name() {
  printf '%s\n' "${SESSIONIZER_HERDR_SESSION:-default}"
}

# True when that herdr session's server is up. Uses `herdr session list`
# (no --session) so it works before the server exists.
sessionizer_herdr_running() {
  local name json
  name="$(sessionizer_herdr_session_name)"
  json="$(command herdr session list --json 2>/dev/null)" || return 1
  printf '%s' "$json" | python3 -c '
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for session in data.get("sessions", []):
    if session.get("name") == name and session.get("running"):
        raise SystemExit(0)
raise SystemExit(1)
' "$name"
}

sessionizer_herdr_ensure_server() {
  local i
  if sessionizer_herdr_running; then
    return 0
  fi
  sessionizer_herdr server >/dev/null 2>&1 &
  for i in $(seq 1 50); do
    if sessionizer_herdr_running; then
      return 0
    fi
    sleep 0.1
  done
  echo "sessionizer: herdr server failed to start" >&2
  return 1
}

# Read JSON from stdin and print a dotted path (result.workspace.workspace_id).
sessionizer_json_get() {
  python3 -c '
import json, sys
data = json.load(sys.stdin)
cur = data
for part in sys.argv[1].split("."):
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        raise SystemExit(1)
if isinstance(cur, (dict, list)):
    json.dump(cur, sys.stdout)
    sys.stdout.write("\n")
else:
    print(cur)
' "$1"
}

# Print label<TAB>workspace_id for labeled workspaces, skipping current.
sessionizer_herdr_workspace_rows() {
  local json current="${HERDR_WORKSPACE_ID:-}"
  json="$(sessionizer_herdr workspace list 2>/dev/null)" || return 0
  printf '%s' "$json" | python3 -c '
import json, sys
current = sys.argv[1]
data = json.load(sys.stdin)
for workspace in data.get("result", {}).get("workspaces", []):
    label = workspace.get("label") or ""
    wid = workspace.get("workspace_id") or ""
    if not label or not wid or wid == current:
        continue
    print(f"{label}\t{wid}")
' "$current"
}

sessionizer_herdr_workspace_id() {
  local label="$1" json
  json="$(sessionizer_herdr workspace list 2>/dev/null)" || return 1
  printf '%s' "$json" | python3 -c '
import json, sys
want = sys.argv[1]
data = json.load(sys.stdin)
for workspace in data.get("result", {}).get("workspaces", []):
    if workspace.get("label") == want:
        print(workspace["workspace_id"])
        raise SystemExit(0)
raise SystemExit(1)
' "$label"
}

# fzf display args. Inside herdr never use --tmux (herdr can sit inside tmux).
sessionizer_fzf_display_args() {
  if [[ -n ${TMUX:-} && ${HERDR_ENV:-} != 1 ]]; then
    printf '%s\n' --tmux=center,80%,70%
  else
    printf '%s\n' --height=100%
  fi
}

sessionizer_name() {
  local base
  base="$(basename "${1%/}")"
  printf '%s\n' "${base#.}" | tr '.:' '__'
}

# Extra rows that are themselves sessions (not scanned for children).
# Hidden names are allowed here; find-pruning applies only to ROOTS.
sessionizer_list_extras() {
  local extra
  [[ -v SESSIONIZER_EXTRAS ]] || return 0
  for extra in "${SESSIONIZER_EXTRAS[@]}"; do
    extra="${extra/#\~/$HOME}"
    extra="${extra%/}"
    [[ -d $extra ]] || continue
    printf '%s\n' "$extra"
  done
}

sessionizer_list_dirs() {
  local root depth="${SESSIONIZER_DEPTH:-1}"
  sessionizer_list_extras
  for root in "${SESSIONIZER_ROOTS[@]}"; do
    root="${root/#\~/$HOME}"
    [[ -d $root ]] || continue
    find "$root" -mindepth 1 -maxdepth "$depth" \( -name '.*' -prune \) -o -type d -print | sort
  done
}

# Print installed harness names in SESSIONIZER_AGENTS order, then shell.
sessionizer_list_harnesses() {
  local agent
  for agent in "${SESSIONIZER_AGENTS[@]}"; do
    command -v "$agent" >/dev/null 2>&1 || continue
    printf '%s\n' "$agent"
  done
  printf 'shell\n'
}

# Print the argv for an Omarchy harness. Flags match omarchy-agent --inline.
sessionizer_agent_argv() {
  local agent="$1"
  case "$agent" in
  opencode) printf '%s\n' opencode --auto ;;
  gemini) printf '%s\n' gemini --yolo ;;
  copilot) printf '%s\n' copilot --allow-all ;;
  crush) printf '%s\n' crush --yolo ;;
  claude | grok) printf '%s\n' "$agent" --permission-mode bypassPermissions ;;
  codex) printf '%s\n' codex --dangerously-bypass-approvals-and-sandbox ;;
  omp) printf '%s\n' omp --auto-approve ;;
  pi) printf '%s\n' pi ;;
  shell) printf '%s\n' "${SHELL:-bash}" ;;
  *)
    echo "Unsupported harness: $agent" >&2
    return 1
    ;;
  esac
}

# Project picker. Inside tmux this is fzf's own popup (--tmux), so callers
# must NOT wrap sessionizer in display-popup (that nests and fails silently).
# Inside herdr the keybind already opens a popup; use inline fzf there.
sessionizer_pick_row() {
  local prompt="${1:-session> }"
  shift
  local -a args=(--prompt="$prompt" --reverse --info=inline)
  args+=("$(sessionizer_fzf_display_args)")
  fzf "${args[@]}" "$@"
}

sessionizer_resolve_editor() {
  local file="$HOME/.local/state/omarchy/defaults/editor"
  local editor=nvim
  if [[ -f $file ]]; then
    read -r editor <"$file"
  fi
  editor="${editor##*/}"
  case "$editor" in
  nvim | vim | nano | micro | hx | helix | fresh) ;;
  *) editor=nvim ;;
  esac
  command -v "$editor" >/dev/null 2>&1 || editor=nvim
  printf '%s\n' "$editor"
}
