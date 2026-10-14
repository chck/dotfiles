#!/usr/bin/env python3
"""Render the pr-map author-mode PR body section from a model JSON, and run every Step 7 check in one pass.

Usage: render-section.py <pr-N.json> --head-sha SHA --lang ja|en -o section.md
           [--prefix-dash] [--diagram-file FILE] [--root DIR] [--files names.txt]
           [--evidence-summary "..."] [--repo OWNER/REPO --pr N --base-sha SHA [--wrap-bare]]

The model (gist, new_concepts, reading_order, evidence, unverified, before_merge, diagram) is the
author's own judgment and is written once, in the JSON. This script arranges that text into the
Step 7 template (headings by language, numbering, stars, the folded evidence block) instead of
having it typed out by hand a second time, and chains check-model.py, check-refs.py and
link-refs.py so one invocation replaces the five separate ones Step 7 used to need.

Order of operations, each gating the next (an earlier failure stops the run before any file is
written past the one the check complained about):
  1. check-model.py <model> [--files] [--root] [--lang]           (Step 2's gate, model alone)
  2. build the unlinked section, write it to -o
  3. check-refs.py <out> --expect-head <head-sha> [--root]
  4. check-model.py <model> --section <out> [--files] [--root] [--lang]
  5. with --repo/--pr/--base-sha: link-refs.py <out> --write [--wrap-bare], then repeat 3 and 4
     on the linked text

A diagram is not auto-drawn: pass --diagram-file with the Mermaid body (no fence delimiters) or a
single `![...](...)` line (PNG tier); omit it when diagram.type is "none". With --root, a
reading_order path not tracked at the head commit is written in plain text, without backticks (a
deleted file, per the skill's citation rule), instead of left to the author to notice by hand.

Exit 0: section.md written and every check passed. Exit 1: a check failed (section.md may still be
on disk from an earlier successful step; fix the model or the diagram and rerun). Exit 2: usage,
missing diagram-file, or a script in this directory failed to run.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent

HEADINGS = {
    "ja": {
        "before_merge": "マージ前に確かめること",
        "new_concepts": "新要素",
        "read_order": "読む順序",
        "not_verified": "未検証",
        "evidence": "実行結果（直前に実行）",
        "show_cmds": "コマンドと出力を表示",
        "star_legend": "★ = 重点的に見てほしいファイル",
        "why_focus": "見る理由",
        "check_by": "確認方法",
        "pass_when": "合格の条件",
    },
    "en": {
        "before_merge": "Before merging",
        "new_concepts": "New concepts",
        "read_order": "Read in this order",
        "not_verified": "Not verified",
        "evidence": "Evidence (ran just now)",
        "show_cmds": "Show the commands and output",
        "star_legend": "★ = read closely",
        "why_focus": "Why look closely",
        "check_by": "Check by",
        "pass_when": "Passes when",
    },
}


def run(cmd: list[str]) -> tuple[int, str]:
    result = subprocess.run([sys.executable, "-B", *cmd], capture_output=True, text=True)
    out = (result.stdout + result.stderr).strip()
    return result.returncode, out


def check_model(model_path: pathlib.Path, args, section: pathlib.Path | None) -> int:
    cmd = [str(HERE / "check-model.py"), str(model_path)]
    if args.files:
        cmd += ["--files", str(args.files)]
    if args.root:
        cmd += ["--root", str(args.root)]
    if args.lang:
        cmd += ["--lang", args.lang]
    if section:
        cmd += ["--section", str(section)]
    code, out = run(cmd)
    label = "check-model.py" + (" --section" if section else "")
    print(f"-- {label}: {'ok' if code == 0 else 'FAILED'}")
    if out:
        print(out)
    return code


def check_refs(section: pathlib.Path, args) -> int:
    cmd = [str(HERE / "check-refs.py"), str(section), "--expect-head", args.head_sha]
    if args.root:
        cmd += ["--root", str(args.root)]
    code, out = run(cmd)
    print(f"-- check-refs.py: {'ok' if code == 0 else 'FAILED'}")
    if out:
        print(out)
    return code


def link(section: pathlib.Path, args) -> int:
    cmd = [
        str(HERE / "link-refs.py"), str(section),
        "--repo", args.repo, "--pr", str(args.pr),
        "--base-sha", args.base_sha, "--head-sha", args.head_sha, "--write",
    ]
    if args.root:
        cmd += ["--root", str(args.root)]
    if args.wrap_bare:
        cmd.append("--wrap-bare")
    code, out = run(cmd)
    print(f"-- link-refs.py: {'ok' if code == 0 else 'FAILED'}")
    if out:
        print(out)
    return code


def tracked_paths(root: pathlib.Path | None) -> set[str] | None:
    if root is None:
        return None
    result = subprocess.run(["git", "-C", str(root), "ls-files"], capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return set(result.stdout.splitlines())


def cite(path: str, tracked: set[str] | None) -> str:
    """Backtick a path, unless it is known not to be tracked at the head commit (a deleted file,
    which the skill's citation check rejects if backticked)."""
    if tracked is not None and not path.endswith("/") and path not in tracked:
        return path
    return f"`{path}`"


def render_before_merge(model: dict, h: dict) -> str | None:
    items = model.get("before_merge") or []
    if not items:
        return None
    lines = [f"### {h['before_merge']}"]
    for i, item in enumerate(items, 1):
        lines.append(f"{i}. {item['check']} — {item['how']}. {h['pass_when']}: {item['pass_when']}")
    return "\n".join(lines)


def render_new_concepts(model: dict, h: dict) -> str | None:
    concepts = model.get("new_concepts") or []
    if not concepts:
        return None
    return "\n".join([f"### {h['new_concepts']}"] + [f"- {c}" for c in concepts])


def render_diagram(model: dict, diagram_text: str | None) -> str | None:
    dtype = (model.get("diagram") or {}).get("type", "none")
    if dtype == "none":
        return None
    if diagram_text is None:
        print("diagram.type is not \"none\" but --diagram-file was not given.", file=sys.stderr)
        sys.exit(2)
    if diagram_text.lstrip().startswith("!["):
        return diagram_text.strip()
    return "```mermaid\n" + diagram_text.strip("\n") + "\n```"


def render_reading_order(model: dict, h: dict, lang: str, tracked: set[str] | None) -> str:
    lines = [f"### {h['read_order']}", h["star_legend"]]
    for i, entry in enumerate(model.get("reading_order") or [], 1):
        star = "★ " if entry.get("focus") else ""
        path_disp = cite(entry["path"], tracked)
        category = entry["why"]
        if str(entry.get("path", "")).endswith("/") and isinstance(entry.get("count"), int):
            category = f"{category}、{entry['count']} ファイル" if lang == "ja" else f"{category}, {entry['count']} files"
        paren = f"（{category}）" if lang == "ja" else f" ({category})"
        lines.append(f"{i}. {star}{path_disp} — {entry['what']}{paren}")
        for f in entry.get("focus") or []:
            where = f"`{f['where']}`"  # a focus cites a path:line inside the diff, always tracked at head
            if lang == "ja":
                tail = f"。{h['check_by']}: {f['how_to_check']}" if f.get("how_to_check") else ""
                lines.append(f"   - {h['why_focus']}: {where} — {f['what']}{tail}")
            else:
                tail = f" {h['check_by']}: {f['how_to_check']}" if f.get("how_to_check") else ""
                lines.append(f"   - {h['why_focus']}: {where} — {f['what']}.{tail}")
    return "\n".join(lines)


def render_not_verified(model: dict, h: dict, lang: str) -> str:
    cov = model["coverage"]
    opened, total, partial = cov["files_opened"], cov["files_total"], cov["files_partial"]
    if lang == "ja":
        coverage_line = f"{opened} 件中 {total} 件のファイルを開いた（うち {partial} 件は一部のみ）"
    else:
        coverage_line = f"Opened {opened} of {total} files ({partial} only in part); the rest are described from the diff stat"
    lines = [f"### {h['not_verified']}", f"- {coverage_line}"]
    for u in model.get("unverified") or []:
        lines.append(f"- {u['claim']} — {u['why_not']}")
    return "\n".join(lines)


def render_evidence(model: dict, h: dict, lang: str, summary_override: str | None) -> str:
    evidence = model.get("evidence") or []
    n = len(evidence)
    if lang == "ja":
        top = f"{n} 件の確認を実行しました。実行しなかった確認は「未検証」にあります。"
    else:
        top = f"{n} checks ran just now. Checks not run are under \"Not verified\"."
    summary = summary_override or ("、".join(e["claim"] for e in evidence) if lang == "ja" else "; ".join(e["claim"] for e in evidence))
    output = "\n".join(e["output"] for e in evidence)
    return (
        f"### {h['evidence']}\n{top}\n\n"
        f"<details>\n<summary>{h['show_cmds']}</summary>\n\n"
        f"- {summary}\n```\n{output}\n```\n\n</details>"
    )


def build_section(model: dict, args, diagram_text: str | None, tracked: set[str] | None) -> str:
    h = HEADINGS[args.lang]
    blocks = ["<!-- pr-explainer:start -->", f"<!-- pr-explainer:head {args.head_sha} -->"]
    if args.prefix_dash:
        blocks.append("---")
    blocks.append(f"**{model['gist']}**")
    for block in (
        render_before_merge(model, h),
        render_new_concepts(model, h),
        render_diagram(model, diagram_text),
        render_reading_order(model, h, args.lang, tracked),
        render_not_verified(model, h, args.lang),
        render_evidence(model, h, args.lang, args.evidence_summary),
    ):
        if block:
            blocks.append(block)
    blocks.append("<!-- pr-explainer:end -->")
    return "\n\n".join(blocks) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("model", type=pathlib.Path)
    parser.add_argument("--head-sha", required=True)
    parser.add_argument("--lang", required=True, choices=("ja", "en"))
    parser.add_argument("-o", "--out", required=True, type=pathlib.Path)
    parser.add_argument("--prefix-dash", action="store_true")
    parser.add_argument("--diagram-file", type=pathlib.Path)
    parser.add_argument("--root", type=pathlib.Path)
    parser.add_argument("--files", type=pathlib.Path)
    parser.add_argument("--evidence-summary")
    parser.add_argument("--repo")
    parser.add_argument("--pr", type=int)
    parser.add_argument("--base-sha")
    parser.add_argument("--wrap-bare", action="store_true")
    args = parser.parse_args()

    try:
        model = json.loads(args.model.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        print(f"{args.model}: cannot read the model ({exc}).", file=sys.stderr)
        return 2

    if check_model(args.model, args, section=None) != 0:
        return 1

    diagram_text = args.diagram_file.read_text() if args.diagram_file else None
    tracked = tracked_paths(args.root)
    section = build_section(model, args, diagram_text, tracked)
    args.out.write_text(section)
    print(f"-- wrote {args.out} ({len(section)} chars)")

    if check_refs(args.out, args) != 0:
        return 1
    if check_model(args.model, args, section=args.out) != 0:
        return 1

    if args.repo:
        if not (args.pr and args.base_sha):
            print("--repo given without --pr and --base-sha.", file=sys.stderr)
            return 2
        if link(args.out, args) != 0:
            return 1
        if check_refs(args.out, args) != 0:
            return 1
        if check_model(args.model, args, section=args.out) != 0:
            return 1
        print(f"-- linked {args.out} ({len(args.out.read_text())} chars)")

    print(f"ok: {args.out} ready")
    return 0


if __name__ == "__main__":
    sys.exit(main())
