import os
import stat
import tempfile
from collections.abc import MutableMapping
from copy import deepcopy
from pathlib import Path
from typing import Annotated, Any

import tomlkit
import typer
from tomlkit.exceptions import ParseError


class ConfigSyncError(ValueError):
    pass


def key_name(path: tuple[str, ...]) -> str:
    return ".".join(repr(part) for part in path)


def same_value(left: Any, right: Any) -> bool:
    left, right = tomlkit.item(left).unwrap(), tomlkit.item(right).unwrap()
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(same_value(value, right[key]) for key, value in left.items())
    if isinstance(left, list):
        return len(left) == len(right) and all(same_value(a, b) for a, b in zip(left, right, strict=True))
    return left == right


def merge(live: MutableMapping[str, Any], managed: MutableMapping[str, Any], prefix: tuple[str, ...] = ()) -> list[str]:
    changes: list[str] = []
    for key, value in managed.items():
        path = (*prefix, key)
        if isinstance(value, MutableMapping) and key in live:
            if not isinstance(live[key], MutableMapping):
                raise ConfigSyncError(f"Table/value conflict at {key_name(path)}; resolve it in the live config first")
            changes.extend(merge(live[key], value, path))
        elif key not in live or not same_value(live[key], value):
            if key in live and isinstance(live[key], MutableMapping):
                raise ConfigSyncError(f"Table/value conflict at {key_name(path)}; resolve it in the live config first")
            live[key] = deepcopy(value)
            changes.append(f"set {key_name(path)}")
    return changes


def remove_keys(live: MutableMapping[str, Any], managed: MutableMapping[str, Any], policy: Any) -> list[str]:
    if not isinstance(policy, list):
        raise ConfigSyncError("remove-keys.toml must contain a remove array of nonempty string paths")
    changes: list[str] = []
    for path in policy:
        if not isinstance(path, list) or not path or any(not isinstance(key, str) or not key for key in path):
            raise ConfigSyncError("Each remove entry must be a nonempty array of nonempty strings")
        owner: Any = managed
        for key in path:
            if not isinstance(owner, MutableMapping) or key not in owner:
                break
            owner = owner[key]
        else:
            raise ConfigSyncError(f"Key {key_name(tuple(path))} is both managed and removed; fix the source files")
        parent: Any = live
        for key in path[:-1]:
            if not isinstance(parent, MutableMapping) or key not in parent:
                parent = None
                break
            parent = parent[key]
        if isinstance(parent, MutableMapping) and path[-1] in parent:
            if isinstance(parent[path[-1]], MutableMapping):
                raise ConfigSyncError(f"Refusing to remove table {key_name(tuple(path))}; list individual keys instead")
            del parent[path[-1]]
            changes.append(f"remove {key_name(tuple(path))}")
    return changes


def synchronize(source: Path, removals: Path, target: Path, check: bool) -> list[str]:
    managed = tomlkit.parse(source.read_text())
    policy = tomlkit.parse(removals.read_text())
    if set(policy) != {"remove"}:
        raise ConfigSyncError("remove-keys.toml must contain only the remove array")
    exists = target.exists()
    if target.is_symlink() and not exists:
        raise ConfigSyncError(f"Broken symlink: {target}; repair or remove it before syncing")
    original = target.read_text() if exists else ""
    live = tomlkit.parse(original)
    changes = remove_keys(live, managed, policy.unwrap()["remove"])
    changes.extend(merge(live, managed))
    if target.is_symlink():
        changes.append("replace config symlink with a regular file")
    if not exists:
        changes.append("create config file")
    if check or not changes:
        return changes
    rendered = tomlkit.dumps(live)
    tomlkit.parse(rendered)
    mode = stat.S_IMODE(target.stat().st_mode) if exists else 0o600
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=target.parent, delete=False) as temporary:
        temporary_path = Path(temporary.name)
        try:
            os.fchmod(temporary.fileno(), mode)
            temporary.write(rendered)
            temporary.flush()
            os.fsync(temporary.fileno())
            # Detect edits made while calculating the update, including atomic replacements.
            if target.exists() != exists or (exists and target.read_text() != original):
                raise ConfigSyncError(f"{target} changed during sync; close Codex and retry")
            os.replace(temporary_path, target)
        finally:
            temporary_path.unlink(missing_ok=True)
    return changes


def main(
    source: Path,
    removals: Path,
    target: Path,
    check: Annotated[bool, typer.Option(help="Show changed key names without writing; exit 1 for drift.")] = False,
) -> None:
    try:
        changes = synchronize(source, removals, target, check)
    except (ConfigSyncError, OSError, ParseError) as error:
        # TOML parser errors may contain a local value; do not print their contents.
        message = (
            "Invalid TOML; validate source, removals and target files before retrying"
            if isinstance(error, ParseError)
            else str(error)
        )
        typer.echo(f"Codex config sync failed: {message}", err=True)
        raise typer.Exit(2) from error
    for change in changes:
        typer.echo(change)
    if check and changes:
        raise typer.Exit(1)


if __name__ == "__main__":
    typer.run(main)
