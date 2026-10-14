#!/bin/bash

run_app() {
    local target_path="$1"

    if [ -z "$target_path" ]; then
        read -p "Enter project directory suffix name to execute: " check_suffix
        target_path="attendance_tracker_${check_suffix}"
    fi

    if [ ! -d "$target_path" ]; then
        echo "[ERROR] Project directory '$target_path' not found — deploy it first." >&2
        return 1
    fi

    local starting_dir
    starting_dir=$(pwd)
    cd "$target_path" || return 1
    python3 attendance_checker.py
    cd "$starting_dir" || return 1
    # Restored from your original screenshot version
    echo "Session Ended!"
}


