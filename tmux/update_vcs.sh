#!/usr/bin/env bash
set -euo pipefail

pane_id="${1:-}"
if [[ -z "$pane_id" ]]; then
  pane_id="$(tmux display-message -p "#{pane_id}")"
fi

path="$(tmux display-message -p -t "$pane_id" "#{pane_current_path}")"

# NEW: skip work if pwd hasn't changed since last run
last_path="$(tmux show-option -p -t "$pane_id" -qv @vcs_last_path || true)"
if [[ "$path" == "$last_path" ]]; then
  exit 0
fi
tmux set-option -p -t "$pane_id" @vcs_last_path "$path"
updated=1

git_repo=""
jj_ws=""
jj_main=""

# git
if top="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)"; then
  git_repo="$(basename "$top")"
fi

# jj
if jj_root="$(jj -R "$path" root 2>/dev/null)"; then
  jj_ws="$(basename "$jj_root")"
  if jj_git_root="$(jj -R "$path" git root 2>/dev/null)"; then
    jj_main="$(basename "$(dirname "$jj_git_root")")"
  fi
fi

# Match your existing logic:
git_status_line=""
if [[ -n "$jj_main" ]]; then
  git_status_line="$jj_main"
elif [[ -n "$git_repo" ]]; then
  git_status_line="$git_repo"
fi

jj_ws_status_line=""
if [[ -n "$jj_ws" && "$jj_ws" != "$jj_main" ]]; then
  jj_ws_status_line="$jj_ws"
fi

# Store plain strings as *pane* options
tmux set-option -p -t "$pane_id" @git_repo_name "$git_repo"
tmux set-option -p -t "$pane_id" @jj_ws_path "$jj_ws"
tmux set-option -p -t "$pane_id" @jj_main_repo "$jj_main"
tmux set-option -p -t "$pane_id" @git_status_line "$git_status_line"
tmux set-option -p -t "$pane_id" @jj_ws_status_line "$jj_ws_status_line"

[[ -n "${updated:-}" ]] && tmux refresh-client -S
