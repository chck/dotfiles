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
DOTFILE = r"(?:[\w.@+()\[\]~-]+/)*\.(?:gitignore|gitattributes|editorconfig|dockerignore|npmrc|nvmrc)"
PATH = re.compile(r"(?P<path>[\w.@+()\[\]~-]+(?:/[\w.@+()\[\]~-]+)*(?:\.\w{1,8}|/)|" + DOTFILE + r")(?::(?P<start>\d+)(?:-(?P<end>\d+))?)?")


FENCE = re.compile(r"^\s*(`{3,}|~{3,})")


def fenced_lines(text: str):
    """Yield (line, in_fence): a fence line and every line inside it count as fenced.

    A fence closes only on a line of the same character that is at least as long as the opening one, so a
    four-backtick block can show a three-backtick block.
    """
    opener: tuple[str, int] | None = None
    for line in text.splitlines():
        m = FENCE.match(line)
        if opener is None:
            if m:
                opener = (m[1][0], len(m[1]))
                yield line, True
            else:
                yield line, False
        else:
            yield line, True
            if m and m[1][0] == opener[0] and len(m[1]) >= opener[1] and line.strip() == m[1]:
                opener = None


def parse_span(span: str) -> re.Match[str] | None:
    """Return the match (groups: path, start, end) when the span cites a file or directory, else None."""
    match = PATH.fullmatch(span)
    if not match:
        return None
    path = match["path"]
    if "/" not in path and path.rsplit(".", 1)[-1] not in BARE_EXTENSIONS and not path.startswith("."):
        return None
    return match
