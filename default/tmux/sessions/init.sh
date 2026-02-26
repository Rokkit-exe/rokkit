#!/bin/bash

session_name=$1
dir_path=$2
reload=$3

[ -z "$session_name" ] && { echo "Usage: $0 <session_name> <directory_path>"; exit 1; }
[ -z "$dir_path" ] && { echo "Usage: $0 <session_name> <directory_path>"; exit 1; }
[ ! -d "$dir_path" ] && { echo "Directory $dir_path does not exist."; exit 1; }

# kill existing tmux session if it exists
[ "$reload" == "true" ] && {
  tmux has-session -t "$session_name" 2>/dev/null && tmux kill-session -t "$session_name"
}

# Template for tmux session setup
tmux new-session -d -s "$session_name" -n nvim
tmux send-keys -t "$session_name":nvim "nvim $dir_path" Enter
tmux new-window -t "$session_name" -n run
tmux send-keys -t "$session_name":run "cd $dir_path" Enter
tmux new-window -t "$session_name" -n cmd
tmux send-keys -t "$session_name":cmd "cd $dir_path" Enter

