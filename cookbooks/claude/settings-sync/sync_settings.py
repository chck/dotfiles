"""Merge the tracked Claude Code settings into the live settings file.

Keys present in the tracked file are written into the live file; every other
live key is kept. Dicts merge recursively, any other value (arrays included) is
replaced as a whole. Output names key paths only, never values.

Exit codes: 0 = in sync, 1 = drift (--check), 2 = error.
"""

import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any


class SyncError(Exception):
    pass


def load(path: Path, *, required: bool) -> dict[str, Any]:
    if not path.exists():
        if required:
            raise SyncError(f"{path} does not exist; check the dotfiles checkout")
        return {}
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        # The message can quote a local value; report the position only.
        raise SyncError(f"{path} is not valid JSON (line {error.lineno}); fix it and retry") from None
    if not isinstance(data, dict):
        raise SyncError(f"{path} must contain a JSON object")
    return data


def merge(live: dict[str, Any], managed: dict[str, Any], prefix: str = "") -> list[str]:
    changes: list[str] = []
    for key, value in managed.items():
        name = f"{prefix}{key}"
        if isinstance(value, dict) and isinstance(live.get(key), dict):
            changes += merge(live[key], value, f"{name}.")
        elif key not in live or live[key] != value:
            live[key] = value
            changes.append(f"set {name}")
    return changes


def synchronize(source: Path, target: Path, check: bool) -> list[str]:
    managed = load(source, required=True)
    live = load(target, required=False)
    changes = merge(live, managed)
    was_symlink = target.is_symlink()
    if was_symlink:
        changes.append("replace settings symlink with a regular file")
    if check or not changes:
        return changes
    target.parent.mkdir(parents=True, exist_ok=True)
    original = target.read_text() if target.exists() else None
    with tempfile.NamedTemporaryFile("w", dir=target.parent, delete=False) as temporary:
        temporary_path = Path(temporary.name)
        try:
            os.fchmod(temporary.fileno(), 0o644)
            temporary.write(json.dumps(live, indent=2, ensure_ascii=False) + "\n")
            temporary.flush()
            os.fsync(temporary.fileno())
            current = target.read_text() if target.exists() else None
            if current != original:
                raise SyncError(f"{target} changed during sync; close Claude Code and retry")
            os.replace(temporary_path, target)
        finally:
            temporary_path.unlink(missing_ok=True)
    return changes


def main(argv: list[str]) -> int:
    check = "--check" in argv
    paths = [Path(a) for a in argv if a != "--check"]
    if len(paths) != 2:
        print("usage: sync_settings.py SOURCE TARGET [--check]", file=sys.stderr)
        return 2
    try:
        changes = synchronize(paths[0], paths[1], check)
    except (SyncError, OSError) as error:
        print(f"Claude settings sync failed: {error}", file=sys.stderr)
        return 2
    for change in changes:
        print(change)
    return 1 if check and changes else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
