"""Shared parsing of backticked file citations (`path`, `path:line`, `path:a-b`) for the pr-explainer scripts."""

from __future__ import annotations

import re

# A span with no "/" is read as a file name only when its extension is one of these,
# so identifiers such as `ast.parse` or `os.path` are not mistaken for files.
BARE_EXTENSIONS = {
    "py", "sh", "md", "json", "toml", "yaml", "yml", "js", "ts", "tsx", "jsx", "rs", "go", "rb",
    "java", "kt", "swift", "c", "h", "cpp", "html", "css", "txt", "cfg", "ini", "lock", "tf",
    "png", "svg", "jpg", "gif", "sql", "rake", "jsonc", "mjs", "cjs", "mts", "cts", "vue", "svelte", "scss",
}

SPAN = re.compile(r"`([^`\n]+)`")
PATH = re.compile(r"(?P<path>[\w.@+()\[\]~-]+(?:/[\w.@+()\[\]~-]+)*(?:\.\w{1,8}|/))(?::(?P<start>\d+)(?:-(?P<end>\d+))?)?")


def parse_span(span: str) -> re.Match[str] | None:
    """Return the match (groups: path, start, end) when the span cites a file or directory, else None."""
    match = PATH.fullmatch(span)
    if not match:
        return None
    path = match["path"]
    if "/" not in path and path.rsplit(".", 1)[-1] not in BARE_EXTENSIONS:
        return None
    return match
