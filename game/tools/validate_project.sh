#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skip_exports=false
if [[ "${1:-}" == "--skip-exports" ]]; then
    skip_exports=true
fi

godot_bin="${ASTERFOLD_GODOT:-}"
if [[ -z "$godot_bin" ]]; then
    godot_bin="$(command -v godot || true)"
fi
if [[ -z "$godot_bin" || ! -x "$godot_bin" ]]; then
    echo "Asterfold requires Godot 4.7.2 Standard. Set ASTERFOLD_GODOT or put godot on PATH." >&2
    exit 1
fi
if [[ "$($godot_bin --version | head -n 1)" != 4.7.2.* ]]; then
    echo "Asterfold requires exactly Godot 4.7.2 Standard." >&2
    exit 2
fi

log_root="$project_root/logs/validation"
build_root="$project_root/builds"
mkdir -p "$log_root" "$build_root"

run_step() {
    local name="$1"
    local log_name="$2"
    shift 2
    local log_path="$log_root/$log_name"
    echo "[VALIDATE] $name"
    "$godot_bin" "$@" --log-file "$log_path"
    if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$log_path"; then
        tail -n 200 "$log_path"
        echo "$name logged engine or script errors." >&2
        exit 1
    fi
}

run_step 'Import and typed-script parse' '01_import.log' \
    --headless --editor --quit --path "$project_root"
run_step 'Unit and integration tests' '02_tests.log' \
    --headless --path "$project_root" --script res://tests/run_tests.gd
run_step 'Content and provenance validation' '03_content.log' \
    --headless --path "$project_root" --script res://tools/validate_content.gd
run_step 'Runtime title smoke' '04_runtime.log' \
    --headless --path "$project_root" --quit-after 120

if [[ "$skip_exports" == false ]]; then
    template_root="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.7.2.stable"
    for template in windows_debug_x86_64.exe linux_debug.x86_64; do
        if [[ ! -f "$template_root/$template" ]]; then
            echo "Godot export template '$template' is not installed." >&2
            exit 1
        fi
    done

    mkdir -p "$build_root/windows" "$build_root/linux"
    run_step 'Windows debug export' '05_export_windows.log' \
        --headless --path "$project_root" --export-debug 'Windows Debug' "$build_root/windows/Asterfold.exe"
    run_step 'Linux debug export' '06_export_linux.log' \
        --headless --path "$project_root" --export-debug 'Linux Debug' "$build_root/linux/Asterfold.x86_64"
    [[ -s "$build_root/windows/Asterfold.exe" ]]
    [[ -s "$build_root/linux/Asterfold.x86_64" ]]
    chmod +x "$build_root/linux/Asterfold.x86_64"
    echo '[VALIDATE] Linux exported-runtime smoke'
    "$build_root/linux/Asterfold.x86_64" --headless --quit-after 120 --log-file "$log_root/07_export_runtime.log"
    if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$log_root/07_export_runtime.log"; then
        tail -n 200 "$log_root/07_export_runtime.log"
        exit 1
    fi
fi

echo '[VALIDATE] PASS: import, tests, content, runtime, and requested exports completed.'
