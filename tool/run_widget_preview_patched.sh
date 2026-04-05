#!/usr/bin/env bash
# Thin wrapper; forwards args to flutter widget-preview start (pass -- for flutter flags).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "${ROOT}/tool/run_widget_preview_patched.py" "$@"
