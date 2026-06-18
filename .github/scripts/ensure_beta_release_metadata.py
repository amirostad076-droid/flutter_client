#!/usr/bin/env python3
"""Ensure a beta draft release has the expected tag and title."""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from beta_release_metadata import build_release_patch_payload, patch_release


def main() -> int:
    release_id = os.environ.get("RELEASE_ID", "").strip()
    tag_name = os.environ.get("RELEASE_TAG", "").strip()
    target_commitish = os.environ.get("COMMITISH", "beta").strip()
    repository = os.environ.get("GITHUB_REPOSITORY", "").strip()
    if release_id == "":
        print("RELEASE_ID is required", file=sys.stderr)
        return 1
    if tag_name == "":
        print("RELEASE_TAG is required", file=sys.stderr)
        return 1
    if repository == "":
        print("GITHUB_REPOSITORY is required", file=sys.stderr)
        return 1
    payload = build_release_patch_payload(
        tag_name=tag_name,
        target_commitish=target_commitish,
    )
    patch_release(repository, release_id, payload)
    print(f"Set release tag to {tag_name} with title {payload['name']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
