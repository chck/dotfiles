import os
import stat
import subprocess
import sys
import tomllib
from pathlib import Path

import pytest

import sync_config


@pytest.fixture
def configs(tmp_path: Path) -> tuple[Path, Path, Path]:
    source, removals, target = (tmp_path / name for name in ("source.toml", "remove.toml", "config.toml"))
    source.write_text("check_for_update_on_startup = false\n[features]\nmanaged = true\n")
    removals.write_text("remove = []\n")
    target.write_text(
        "# Local preferences\ncheck_for_update_on_startup = true\n"
        "[features]\nmanaged = false\nlocal = true # keep me\n"
        '[projects."/example/project"]\ntrust_level = "trusted"\n'
    )
    return source, removals, target


def run_cli(configs: tuple[Path, Path, Path], *, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(Path(sync_config.__file__)),
            *(str(path) for path in configs),
            *(["--check"] if check else []),
        ],
        capture_output=True,
        text=True,
        check=False,
    )


def test_updates_managed_keys_preserving_local_state_and_comments(configs: tuple[Path, Path, Path]) -> None:
    result = run_cli(configs)
    assert result.returncode == 0, result.stderr
    rendered = configs[2].read_text()
    parsed = tomllib.loads(rendered)
    assert parsed["check_for_update_on_startup"] is False
    assert parsed["features"] == {"managed": True, "local": True}
    assert parsed["projects"]["/example/project"]["trust_level"] == "trusted"
    assert "# Local preferences" in rendered
    assert "# keep me" in rendered


def test_second_run_does_not_write(configs: tuple[Path, Path, Path]) -> None:
    assert run_cli(configs).returncode == 0
    target = configs[2]
    os.utime(target, ns=(1_600_000_000_000_000_000, 1_600_000_000_000_000_000))
    before = target.stat()
    result = run_cli(configs)
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""
    assert target.stat().st_mtime_ns == before.st_mtime_ns
    assert target.stat().st_ino == before.st_ino


def test_check_reports_drift_without_writing(configs: tuple[Path, Path, Path]) -> None:
    target = configs[2]
    original = target.read_bytes()
    before = target.stat()
    assert run_cli(configs, check=True).returncode == 1
    assert target.read_bytes() == original
    assert target.stat().st_mtime_ns == before.st_mtime_ns
    assert run_cli(configs).returncode == 0
    assert run_cli(configs, check=True).returncode == 0


@pytest.mark.parametrize("position", [0, 1, 2])
def test_malformed_toml_fails_without_mutation(configs: tuple[Path, Path, Path], position: int) -> None:
    configs[position].write_text('broken = "DO_NOT_DISCLOSE\n')
    original = configs[2].read_bytes()
    result = run_cli(configs)
    assert result.returncode == 2
    assert "Invalid TOML" in result.stderr
    assert "DO_NOT_DISCLOSE" not in result.stderr
    assert configs[2].read_bytes() == original


@pytest.mark.parametrize(
    "policy",
    [
        "unexpected = []\n",
        'remove = "features"\n',
        "remove = [[]]\n",
        'remove = [[""]]\n',
        "remove = [[1]]\n",
        'remove = [["features", "managed"]]\n',
        'remove = [["projects"]]\n',
        'remove = [["features", "local"], ["projects"]]\n',
    ],
)
def test_invalid_removal_policy_fails_without_mutation(configs: tuple[Path, Path, Path], policy: str) -> None:
    configs[1].write_text(policy)
    original = configs[2].read_bytes()
    result = run_cli(configs)
    assert result.returncode == 2
    assert configs[2].read_bytes() == original


def test_explicit_leaf_removal_preserves_siblings(configs: tuple[Path, Path, Path]) -> None:
    configs[1].write_text('remove = [["features", "local"], ["absent", "key"]]\n')
    assert run_cli(configs).returncode == 0
    parsed = tomllib.loads(configs[2].read_text())
    assert parsed["features"] == {"managed": True}
    assert parsed["projects"]["/example/project"]["trust_level"] == "trusted"
    assert run_cli(configs, check=True).returncode == 0


@pytest.mark.parametrize(
    ("source", "target"),
    [("setting = true\n", "[setting]\nlocal = true\n"), ("[setting]\nmanaged = true\n", "setting = true\n")],
)
def test_table_value_conflicts_fail_without_mutation(
    configs: tuple[Path, Path, Path], source: str, target: str
) -> None:
    configs[0].write_text(source)
    configs[2].write_text(target)
    result = run_cli(configs)
    assert result.returncode == 2
    assert "Table/value conflict" in result.stderr
    assert configs[2].read_text() == target


@pytest.mark.parametrize(("source_value", "live_value"), [("false", "0"), ("true", "1"), ("0", "false"), ("1", "true")])
def test_managed_scalar_type_is_updated(configs: tuple[Path, Path, Path], source_value: str, live_value: str) -> None:
    configs[0].write_text(f"setting = {source_value}\n")
    configs[2].write_text(f"setting = {live_value}\n")
    assert run_cli(configs, check=True).returncode == 1
    assert run_cli(configs).returncode == 0
    actual = tomllib.loads(configs[2].read_text())["setting"]
    expected = tomllib.loads(configs[0].read_text())["setting"]
    assert type(actual) is type(expected)
    assert actual == expected


def test_symlink_migration_preserves_destination_and_permissions(configs: tuple[Path, Path, Path]) -> None:
    target = configs[2]
    destination = target.with_name("old-source.toml")
    target.rename(destination)
    destination.chmod(0o640)
    original = destination.read_bytes()
    target.symlink_to(destination)
    assert run_cli(configs, check=True).returncode == 1
    assert target.is_symlink()
    assert run_cli(configs).returncode == 0
    assert not target.is_symlink()
    assert destination.read_bytes() == original
    assert stat.S_IMODE(target.stat().st_mode) == 0o640
    assert tomllib.loads(target.read_text())["check_for_update_on_startup"] is False


def test_missing_target_created_privately(configs: tuple[Path, Path, Path]) -> None:
    source, removals, existing = configs
    target = existing.parent / "new" / "config.toml"
    args = (source, removals, target)
    assert run_cli(args, check=True).returncode == 1
    assert not target.parent.exists()
    assert run_cli(args).returncode == 0
    assert tomllib.loads(target.read_text()) == tomllib.loads(source.read_text())
    assert stat.S_IMODE(target.stat().st_mode) == 0o600


def test_concurrent_edit_is_preserved(configs: tuple[Path, Path, Path], monkeypatch: pytest.MonkeyPatch) -> None:
    target = configs[2]
    concurrent = '# Concurrent edit\nmodel = "local-model"\n'
    fsync = os.fsync

    def edit_during_sync(fd: int) -> None:
        fsync(fd)
        target.write_text(concurrent)

    monkeypatch.setattr(sync_config.os, "fsync", edit_during_sync)
    with pytest.raises(sync_config.ConfigSyncError, match="changed during sync"):
        sync_config.synchronize(*configs, check=False)
    assert target.read_text() == concurrent
    assert set(target.parent.iterdir()) == set(configs)
