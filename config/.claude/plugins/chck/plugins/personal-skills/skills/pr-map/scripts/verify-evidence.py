#!/usr/bin/env python3
"""Re-run the evidence of a pr-map model and check that each pasted output is what the command prints.

Usage: verify-evidence.py <pr-N.json> [--root DIR] [--timeout SECONDS]

For every `evidence` entry, `cmd` is run with bash from --root (the PR-head checkout; default ".") and its output
(stdout and stderr together) is compared with the pasted `output`: colour codes and trailing whitespace are ignored,
everything else must be equal, line for line. A cut output is fine when the command itself cuts it (`| tail -3`,
`| rg ...`): the skill's rule is that the command shows its filter and every pasted line is exactly as printed.

An entry that cannot be re-run says so: "rerun": false with a "why_not_rerun" (a scratch file the reader cannot see,
another system such as a database or a cloud service, output that changes on every run). A part that changes on every
run (a duration, a date) is hidden by "mask", a list of regular expressions replaced by "..." in both texts.

This proves that the pasted text is what the command prints now. It does not prove that the command checks the right
thing. Run it only on code you would run anyway: it executes the commands the model lists.

Exit 0: every re-run entry matched. Exit 1: a mismatch or an error. Exit 2: the model cannot be read.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import subprocess
import sys

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


def normalise(text: str, masks: list[str]) -> list[str]:
    text = ANSI.sub("", text).replace("\r\n", "\n")
    for pattern in masks:
        text = re.sub(pattern, "...", text)
    lines = [line.rstrip() for line in text.split("\n")]
    while lines and not lines[-1]:
        lines.pop()
    return lines


def first_difference(pasted: list[str], actual: list[str]) -> str:
    for i in range(max(len(pasted), len(actual))):
        a = pasted[i] if i < len(pasted) else "(nothing)"
        b = actual[i] if i < len(actual) else "(nothing)"
        if a != b:
            return f"line {i + 1}: pasted {a[:100]!r}, now {b[:100]!r}"
    return "the texts differ"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", type=pathlib.Path)
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path("."))
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()

    try:
        evidence = json.loads(args.model.read_text()).get("evidence", [])
    except (OSError, json.JSONDecodeError) as exc:
        print(f"{args.model}: cannot read the model ({exc}).", file=sys.stderr)
        return 2

    env = dict(os.environ, NO_COLOR="1", TERM="dumb", CI="1")
    matched = skipped = failed = 0
    for i, entry in enumerate(evidence):
        claim = str(entry.get("claim", f"evidence[{i}]"))[:70]
        if entry.get("rerun") is False:
            skipped += 1
            print(f"skipped   {claim}: {entry.get('why_not_rerun') or 'no reason given'}")
            continue
        try:
            r = subprocess.run(["bash", "-c", entry["cmd"]], cwd=args.root, capture_output=True, text=True,
                               timeout=args.timeout, env=env, stdin=subprocess.DEVNULL)
        except subprocess.TimeoutExpired:
            failed += 1
            print(f"ERROR     {claim}: timed out after {args.timeout}s. Raise --timeout or mark it rerun: false with a reason.")
            continue
        masks = [str(m) for m in entry.get("mask", [])]
        pasted = normalise(str(entry.get("output", "")), masks)
        actual = normalise(r.stdout + r.stderr, masks)
        if pasted == actual:
            matched += 1
            print(f"matched   {claim}")
        else:
            failed += 1
            print(f"MISMATCH  {claim}: {first_difference(pasted, actual)}")
    print(f"{matched} matched, {skipped} not re-run, {failed} failed ({len(evidence)} evidence entries)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
