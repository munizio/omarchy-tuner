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
}

sessionizer_tmux() {
  if [[ -n ${SESSIONIZER_TMUX_SOCKET:-} ]]; then
    command tmux -L "$SESSIONIZER_TMUX_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

# fzf display args. Inside tmux this is fzf's own popup; callers must
# NOT wrap sessionizer in tmux display-popup (that nests and fails silently).
sessionizer_fzf_display_args() {
  if [[ -n ${TMUX:-} ]]; then
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

# First SESSIONIZER_ROOTS entry. New projects from [ + New ] land here.
sessionizer_create_root() {
  local root="${SESSIONIZER_ROOTS[0]}"
  root="${root/#\~/$HOME}"
  printf '%s\n' "${root%/}"
}

# Single path component for a new project directory. Rejects empty names,
# '.'/'..', slashes, and control characters.
sessionizer_sanitize_project_name() {
  local name="$1"
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  if [[ -z $name ]]; then
    echo "sessionizer: project name is empty" >&2
    return 1
  fi
  if [[ $name == */* ]]; then
    echo "sessionizer: project name cannot contain '/'" >&2
    return 1
  fi
  if [[ $name == . || $name == .. ]]; then
    echo "sessionizer: invalid project name: $name" >&2
    return 1
  fi
  if [[ $name == *[[:cntrl:]]* ]]; then
    echo "sessionizer: project name contains control characters" >&2
    return 1
  fi
  printf '%s\n' "$name"
}

# mkdir -p the first root and $root/$name. Prints the new (or existing) path.
sessionizer_create_project() {
  local name dir root
  name="$(sessionizer_sanitize_project_name "$1")" || return 1
  root="$(sessionizer_create_root)"
  mkdir -p "$root" || return 1
  dir="$root/$name"
  mkdir -p "$dir" || return 1
  printf '%s\n' "$dir"
}

# Extra rows that are themselves sessions (not scanned for children).
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
    find "$root" -mindepth 1 -maxdepth "$depth" -type d | sort
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
  opencode) printf '%s\n' opencode ;;
  claude | grok) printf '%s\n' "$agent" ;;
  omp) printf '%s\n' omp ;;
  pi) printf '%s\n' pi ;;
  shell) printf '%s\n' "${SHELL:-bash}" ;;
  *)
    echo "Unsupported harness: $agent" >&2
    return 1
    ;;
  esac
}

# Project picker. Inside tmux this is fzf's own popup (--tmux).
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
