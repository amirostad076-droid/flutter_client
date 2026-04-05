#!/usr/bin/env python3
"""Run `flutter widget-preview start` and patch scaffold web/index.html when Flutter creates it.

Workaround for https://github.com/flutter/flutter/issues/179577 — the preview scaffold uses a
stock index.html while transitive web plugins (passkeys, flutter_inappwebview) expect the same
scripts as the main app.

Usage (from repo root):
  python3 tool/run_widget_preview_patched.py
  python3 tool/run_widget_preview_patched.py -- --web-server

Forward any arguments after `--` to `flutter widget-preview start`.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

_PATCH_MARKER = "<!-- fluxer_widget_preview_web_patch -->"

_PASSKEYS_SCRIPT = """
  {_PATCH_MARKER}
  <script
    src="https://github.com/corbado/flutter-passkeys/releases/download/2.4.0/bundle.js"
    type="application/javascript"
  ></script>
  <script
    defer
    src="/assets/packages/flutter_inappwebview_web/assets/web/web_support.js"
    type="application/javascript"
  ></script>
""".replace("{_PATCH_MARKER}", _PATCH_MARKER).strip(
    "\n"
)

_BOOTSTRAP_LINE = '  <script src="flutter_bootstrap.js" async></script>'

_RE_SCAFFOLD = re.compile(
    r"Creating widget preview scaffolding at:\s*(.+?)\s*$",
)
_RE_MANIFEST = re.compile(
    r"Creating the Widget Preview Scaffold manifest at\s*(.+?)\s*$",
)


def _repo_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _patch_scaffold_index_html(scaffold_dir: str) -> None:
    index_path = os.path.join(scaffold_dir, "web", "index.html")
    if not os.path.isfile(index_path):
        return
    with open(index_path, encoding="utf-8") as handle:
        content = handle.read()
    if _PATCH_MARKER in content:
        return
    if _BOOTSTRAP_LINE not in content:
        print(
            f"[run_widget_preview_patched] Expected bootstrap script not found in {index_path}; "
            "skipping patch.",
            file=sys.stderr,
        )
        return
    patched = content.replace(
        _BOOTSTRAP_LINE,
        _BOOTSTRAP_LINE + "\n" + _PASSKEYS_SCRIPT + "\n",
        1,
    )
    with open(index_path, "w", encoding="utf-8") as handle:
        handle.write(patched)
    print(f"[run_widget_preview_patched] Patched {index_path}", file=sys.stderr)


def _maybe_patch_from_line(line: str) -> None:
    match = _RE_SCAFFOLD.search(line)
    if match:
        _patch_scaffold_index_html(match.group(1).strip())
        return
    match = _RE_MANIFEST.search(line)
    if match:
        manifest_path = match.group(1).strip()
        scaffold_dir = os.path.dirname(manifest_path)
        _patch_scaffold_index_html(scaffold_dir)


def main() -> int:
    argv = sys.argv[1:]
    if argv and argv[0] == "--":
        argv = argv[1:]
    repo = _repo_root()
    cmd = ["flutter", "widget-preview", "start", *argv]
    process = subprocess.Popen(
        cmd,
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        env=os.environ.copy(),
    )
    assert process.stdout is not None
    try:
        for line in process.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            _maybe_patch_from_line(line)
    finally:
        if process.stdout:
            process.stdout.close()
    return process.wait()


if __name__ == "__main__":
    raise SystemExit(main())
