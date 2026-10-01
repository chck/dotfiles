# Managed Codex configuration

`config/codex/config.toml` declares the keys dotfiles owns. Each provision merges
those keys recursively into `~/.codex/config.toml`, preserving other keys,
comments and existing permissions. Arrays are managed as whole values. A legacy
symlink is replaced with a regular file without writing to its target.

To retire a setting, remove it from the managed file and add its path to
`config/codex/remove-keys.toml`, for example `remove = [["tui", "old_setting"]]`.
Removing it from the managed file alone releases management and leaves its live
value intact. Removing a table is rejected; list its individual keys instead.
Table/value conflicts and invalid TOML fail without changing the live file.

From the main checkout, preview or apply only this configuration:

```sh
mise exec -- uv run --locked --no-dev --project cookbooks/codex/config-sync \
  python cookbooks/codex/config-sync/src/sync_config.py \
  config/codex/config.toml config/codex/remove-keys.toml \
  "$HOME/.codex/config.toml" --check
# Remove --check to apply. Exit codes: 0 = in sync, 1 = drift, 2 = error.
```

`./install.sh -n` also runs the check through the cookbook guard. A fresh
machine needs mise/uv installed before that guard can report key-level changes;
the normal apply installs them first. A check can populate uv's dependency
cache but never writes the Codex config. Output contains key names, not values.

Updates use an atomic replacement and detect content changes during preparation.
Close Codex before applying: Codex does not share a lock with this writer and
can still overwrite the configuration after a sync. Restart it to read changes.
A second apply makes no write when the managed values already match.

Run verification:

```sh
uv run --locked --project cookbooks/codex/config-sync pytest cookbooks/codex/config-sync/tests
uv run --locked --project cookbooks/codex/config-sync ruff check cookbooks/codex/config-sync
uv run --locked --project cookbooks/codex/config-sync ty check cookbooks/codex/config-sync/src
```
