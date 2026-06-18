#!/usr/bin/env python3
"""Helpers for beta release draft tag and title metadata."""

from __future__ import annotations

import json
import re
import subprocess

BETA_TAG_PATTERN = re.compile(r"^v?(\d+\.\d+\.\d+)-beta\.(\d+)$")


def format_beta_release_title(tag_name: str) -> str:
    match = BETA_TAG_PATTERN.match(tag_name)
    if match is None:
        raise ValueError(f"Tag does not match beta prerelease pattern: {tag_name}")
    return f"V{match.group(1)} Beta {match.group(2)}"


def build_release_patch_payload(
    *,
    body: str | None = None,
    tag_name: str | None = None,
    release_name: str | None = None,
    target_commitish: str | None = None,
) -> dict[str, str]:
    payload: dict[str, str] = {}
    if body is not None:
        payload["body"] = body
    if tag_name is not None and tag_name != "":
        payload["tag_name"] = tag_name
    if release_name is not None and release_name != "":
        payload["name"] = release_name
    elif tag_name is not None and tag_name != "":
        payload["name"] = format_beta_release_title(tag_name)
    if target_commitish is not None and target_commitish != "":
        payload["target_commitish"] = target_commitish
    return payload


def patch_release(repository: str, release_id: str, payload: dict[str, str]) -> None:
    subprocess.run(
        [
            "gh",
            "api",
            "--method",
            "PATCH",
            f"repos/{repository}/releases/{release_id}",
            "--input",
            "-",
        ],
        input=json.dumps(payload),
        text=True,
        check=True,
    )
