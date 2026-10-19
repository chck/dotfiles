---
name: pr-map
description: >
  Make a pull request easy to review. For your own PR (author mode) it writes a reviewer's map into the PR body: a
  one-line gist, new concepts, a reading order with a one-line summary per file and a star on the files to read
  closely, the checks you actually ran, what is not verified, and a diagram. For someone else's PR (reviewer mode) it
  prints a report in the terminal and a private Artifact instead: the PR's claims against the diff, changes the
  description does not mention, the reading order, and draft questions for the author; it never edits the PR. Use when the user says "PR を読みやすくして", "レビュー用の説明を付けて", "この PR をレビューしたい",
  "この PR を理解したい", "PR explainer", "explain this PR", "make this PR reviewable", "review this PR".
  Small diagrams go in as Mermaid; large ones are exported with diagram-design and hosted on a `pr-assets` branch.
argument-hint: "[PR number (defaults to the current branch's PR)] [--lang ja|en] [--as author|reviewer]"
---

# PR Explainer

Goal (author mode; for reviewer mode read `references/reviewer-mode.md`): the reviewer knows **what changed, where to look first, what was actually checked, and which files to read closely**
before opening the diff. Describe the change from the diff, not from the commit messages: agent-written messages
often describe intent, not result.

## Step 1: Resolve the PR and check visibility

- Use `$ARGUMENTS` as the PR number, else `gh pr view --json number` for the current branch.
- Pick the mode: the PR's author (`gh pr view <n> --json author -q .author.login`) against you (`gh api user -q .login`).
  The same login is author mode, even for an agent-made PR opened under your account; a different one is
  reviewer mode (`references/reviewer-mode.md`). `--as author|reviewer` overrides.
- `gh repo view --json visibility,nameWithOwner` — keep both. **PUBLIC** changes Steps 4 and 6. For another
  repository pass it positionally (`gh repo view <owner/repo>`); `-R <owner/repo>` belongs to `gh pr`.
- `gh pr view <n> --json title,body,commits,baseRefName,baseRefOid,headRefOid`, `gh pr diff <n>`, and `gh pr diff <n> --name-only`
  for the file list: `gh pr view --json files` stops at 100 files.
- Work from a checkout of the PR head; Steps 3 and 7 read files from it, and the scripts take `--root <dir>`.
  For your own open PR that is its worktree. For a merged PR or someone else's:
  `git fetch origin pull/<n>/head`, `git worktree add --detach <dir> FETCH_HEAD`, and remove it when done.
- Read the repo's `AGENTS.md` (or `CLAUDE.md` when there is none) for conventions the diff is judged against.

## Step 2: Build the model first, prose second

Write one structured model to the scratchpad (`pr-<n>.json`); the body and the diagram both come from it,
so they cannot disagree.

```json
{
  "mode": "author",
  "gist": "one sentence: what happens once this is merged",
  "before_merge": [{"check": "what to confirm before merging", "how": "backtick a command here, e.g. run `npm test`", "pass_when": "backtick it here too, e.g. `npm test` exits 0"}],
  "new_concepts": ["term: what it is, where it lives"],
  "reading_order": [{"path": "...", "what": "one line, from the diff", "why": "core | contract | migration | config | tests | docs | mechanical",
                     "focus": [{"where": "path:line", "what": "why this place deserves a close read", "how_to_check": "optional: only when it is not a before_merge item"}]}],
  "evidence": [{"claim": "...", "cmd": "...", "output": "pasted verbatim"}],
  "unverified": [{"claim": "...", "why_not": "..."}],
  "coverage": {"files_total": 0, "files_opened": 0, "files_partial": 0},
  "diagram": {
    "type": "mermaid | sequence | data-flow | architecture | none",
    "focus": ["1-2 nodes that changed"],
    "edges": [{"from": "node id", "to": "node id", "evidence": "path:line"}]
  }
}
```

Write the **whole** model before any prose: no placeholders, no stub entries. Then run
`scripts/check-model.py pr-<n>.json --files <names.txt> --root <checkout>`, where `names.txt` is the output of
`gh pr diff <n> --name-only`; it must exit 0; add `--lang ja` when the report language is Japanese, so a field written in English is rejected. It rejects empty entries, "...", TODO, a missing `coverage`, a `why`
outside the list, a `what` over 300 characters, an edge whose cited `path:line` does not exist, any changed file that no
`reading_order` entry covers, and a directory entry whose `count` is not the number of files it really covers. A PR of
100 files is where this gets skipped.

Rules:
- **Facts and judgment stay apart.** `reading_order` (its `what`), `evidence` and `diagram.edges` are facts taken from the diff or from a
  run. A `focus` entry is the author's judgment: it asks the reviewer to look, it does not claim a defect. The ★ and the "Why look closely" line set it apart from the facts around it. Never write a verdict word anywhere
  (SAFE, LOW RISK, MERGEABLE, "no impact"): this skill reads a diff, it does not know runtime impact.
- `before_merge` is the shortest list that lets the reader decide, at most 5 items, each with the check, how to do
  it, and the result that lets the merge go ahead (`pass_when`). Take them from the `focus` places and from the
  `unverified` claims whose failure would hurt most; a `focus` whose check is here leaves out its own
  `how_to_check`, so nothing is said twice. It is a to-do list for the reader, never a verdict: do not write "OK to merge" or "no
  problem found". An empty list is for a PR with nothing to check by hand, and the gist says so. Backtick any
  command inside `check`, `how`, or `pass_when` (`` `npm test` ``, not `npm test`): `--lang ja` strips code spans
  before counting the Japanese ratio, so an un-backticked command's ASCII letters count against it and can fail
  the check on an otherwise-Japanese field. Two backticking mistakes fail `check-refs.py` instead (it reads any
  backticked span with a recognised extension as a path citation): a command run as `./script.sh` fails because
  git tracks it as `script.sh`, not `./script.sh` — drop the `./`, or drop the backticks if it is not really a
  citation; and a bare filename used as a generic example (`` `default.rb` `` meaning "any recipe file", not one
  real path) fails because no file is tracked under that exact bare name — leave it unbackticked, or name the one
  real path you mean.
- `gist` is one sentence about the effect after merge, with a verb that says what now happens or what a user can
  now do ("calling X now writes Y"). "Adds X" or "changes Y" alone is a label, not a gist. The deletion test in
  Step 7 judges it; `check-model.py` only checks that it is not empty.
- `reading_order` is one list that is both the order to read in and the per-file summary. It starts with the file
  where a wrong line costs the most, and `why` is its category: core, contract, migration, config, tests, docs or mechanical. That is the
  default order, the costliest files first within a category. `what` is at most 300 characters. The order is advisory: `check-model.py` does not check it. Mechanical files
  (renames, lockfiles, generated code) go last.
- Five or more files of one kind (mechanical files, or the test files of one directory) become **one** `reading_order`
  entry that cites the directory (ending in `/`), gives the count, and says what they cover; never one entry per
  file. Whatever the grouping, every changed file is covered by some entry (`check-model.py --files` checks it).
- A directory entry carries a `count`: the changed files under it that no other entry lists. `check-model.py --files`
  compares it with the real number, so a group cannot silently swallow files. A deleted file is covered by an entry
  with its old path; write it in plain text in the body, not in backticks.
- Numbers in the body (cases, tests, lines, files) come from a command you ran, or are left out. Do not estimate.
  Count test cases with the runner when it can list them (`vitest list`, `cargo test -- --list`); a pattern count
  must handle multi-line `it.each([`, and is called approximate.
- Tests are a change like any other: say what behaviour they cover and roughly how much, in `reading_order`. A PR
  whose tests are only named reads as untested.
- `coverage` is honest: a file is *opened* when you read its diff or its content. Seeing its name in the diff stat
  or its title does not count. A file you read only in part is counted in `files_partial` and named under "Not verified". Partial means the head or
  a slice of a long file, or one sample standing for a family of similar files (query caches, generated code, a
  lockfile); say which in "Not verified".
  A starred file counts as opened: do not star a file you did not read (`check-model.py` can only compare the number of starred entries with `files_opened`). If fewer than half the files were opened,
  the gist or the first line of "Not verified" says so.
- Keep the section short enough to read: above about 25000 characters of the final, linked section, group `reading_order` by
  area. The PR body is capped at 65536 characters, the existing body included; `check-model.py --section` fails above
  45000. Links add 30-60%, so measure after linking.
- `new_concepts` comes before the reading order in the body, so the terms the order uses are already known. It lists only what the PR introduces. Do not re-explain what AGENTS.md or the code already states. Do not
  backtick a bare filename used as a stand-in for a category (`` `default.rb` `` meaning "any recipe file"):
  `check-refs.py` reads it as a path citation and fails because no file is tracked under that exact bare name.
- A `reading_order` entry gets a `focus` list, and a ★ in the body, when a wrong line there costs the most. Each
  focus names a place (`path:line`, which may be in another file the change affects) and a way to check it; one with
  neither is noise, drop it. Write it as a reason to read closely, not as a verdict that something is broken. Star
  few entries: when most have a ★, none stands out.
- Every `diagram.edges` entry cites a place in the diff. An edge without one is not drawn.
- Empty sections are omitted, never padded. `diagram.type` is `none` when there is no structure to draw:
  typo, docs-only, config value, single-function fix.

## Step 3: Run before you write

Anything the body would say passes, works, or renders needs an `evidence` entry: run the command now, in the
PR-head checkout, and paste the output **verbatim**. Never retype or summarise output. A long output may be cut by a pattern (the summary
  lines of a test run, say): show the command with its filter, and keep every pasted line exactly as printed.

- Cheap checks to run when they apply: the test command, the linter named in AGENTS.md, `bash -n` and `shellcheck`
  for shell, a dry run of a new script.
- A claim you did not or could not run goes to `unverified` with the reason. "Not run" is a fine answer; an
  unlabelled claim is not.
- Claims copied from the PR body or commit messages ("278 tests pass") go to `unverified` unless you ran them.
  Operational steps the body lists (a flag to flip, a migration to run) are carried over there too, attributed to
  the PR body. (In reviewer mode a copied claim is judged in `claims`; only the `not_checked` ones also go here.)
- Dependencies missing in the checkout: do not install, and do not borrow another checkout's `node_modules` or build
  cache: a test run writes into the checkout. Name the repo's own check command first in
  `unverified`, one entry per toolchain (for example `cargo test` and `npm run check`), and say it was not run.
- A copied claim you could check by reading the code (not by running it) is written as exactly that: "read the
  code, did not run the test".
- If a check used a scratch file the reviewer cannot see, put the script in `cmd` or write "scratch file, not in
  the repo". Write its name in plain text or inside the fenced `cmd`, never in backticks in the body: the citation
  check reads backticked names as repo paths.
- Name the exact command you ran. If it differs from the repo's wrapper (a Makefile or task-runner target), say so.
  Keep the exit status: run the command without a pipe and print `exit=$?` on the next line (a pipe loses it, and
  `PIPESTATUS` differs between bash and zsh). A `cmd; echo exit=$?` sequence is fine, and a loop prints one line per pass
  (`for f in ...; do cmd "$f"; echo "exit=$? $f"; done`). Avoid `sed -i` in scripts you give the reader: BSD and GNU differ.
- When reporting a green result, say what was checked and over what range ("shellcheck on the one new script"),
  not just "passes".

## Step 4: Privacy check (mandatory on PUBLIC repos)

Everything below becomes world-readable, and a pushed image cannot be fully removed afterwards.
Before writing the body or the diagram, scan the model for private or internal org, repo, host, and project
names. Replace each with a generic description. Do not carry them into node labels, Mermaid text, or evidence output.

## Step 5: Diagram (skip when `diagram.type` is `none`)

Pick the cheaper tier that is enough.

**Mermaid in the body** — when the diagram is a flowchart or sequence of up to about 6 nodes. GitHub renders a
```` ```mermaid ```` fence in a PR body, so nothing is exported or hosted.
1. Write the fence from `diagram.edges` only.
2. Run `scripts/check-model.py pr-<n>.json --section <section.md>`. It also rejects verdict words and an
   oversized section. It compares the fence's edges with `diagram.edges` **in both directions** (an edge only in the source is invented, one only in the model is
   missing); `from` and `to` in the model are the Mermaid node ids. Fix the source until it exits 0. Label an
   edge that only sometimes runs (`a -->|when X changed| b`); the label does not affect the comparison.
3. When the flow needs more than about 6 nodes, or one diagram is not enough: draw only the path that changed
   and add one line under the diagram saying what is not drawn. Do not pack extra nodes in. If the PNG tier
   is the right one but publishing is not allowed (public repository, no consent yet), stay on Mermaid with
   that line.

**PNG** — when Mermaid cannot express it or the diagram is larger: read `references/png-diagram.md` for the
export, review and publishing steps (this is the old Step 6; it now lives there since most runs are Mermaid-only
and never need it).

## Step 7: Write the body section

(Author mode. In reviewer mode nothing is written to the PR: see `references/reviewer-mode.md`.)

`scripts/render-section.py` builds this section from the model (the judgment is already in the JSON; do not
retype it as prose) and runs every check below in one command instead of five separate ones. Put the result in the
PR body between the markers so a re-run replaces it in place. It has no title (the body is the map, and it starts
with the gist). If the PR body already holds the author's own text above the block, pass `--prefix-dash` so a `---`
line sets the generated part apart; when the block is the whole body, omit it.

1. **Deletion test, on the model, before rendering.** Remove `before_merge` and `reading_order` from the judgment:
   the `gist` must still stand on its own. If `gist` only reads the evidence aloud, rewrite it first — rendering a
   weak gist just makes it official.
2. A diagram is not auto-drawn: when `diagram.type` is not `"none"`, write its body to a file — the Mermaid lines with
   no fence delimiters, or one `![diagram](pinned image URL)` line for the PNG tier — and pass `--diagram-file`.
3. Run:
   ```
   scripts/render-section.py pr-<n>.json --head-sha <headRefOid> --lang ja|en -o <body-file> \
     --root <checkout> --files <names.txt> [--diagram-file <file>] [--prefix-dash] \
     --repo <owner/repo> --pr <n> --base-sha <baseRefOid> [--wrap-bare]
   ```
   This validates the model (Step 2's check), writes `<body-file>`, checks its citations, links them (Files changed
   view when a cited line sits in a diff hunk, else a permalink at the head commit; `--wrap-bare` first backticks bare
   repo paths and underscored identifiers so Markdown does not read them as emphasis), re-checks the linked
   citations, and re-validates the model against the final linked text (size, Mermaid edges both ways, no verdict
   word). A `reading_order` path not tracked at the head commit is written in plain text, without backticks (a
   deleted file), automatically. Omit `--repo`/`--pr`/`--base-sha` to get the unlinked text only (for example, to
   look at it before the PR exists).
4. Exit 0: `<body-file>` is ready to apply. Exit 1: a check failed; its output names the field or line. Fix the model
   JSON or the diagram file and rerun — never apply past a failure. Exit 2: usage, or `--diagram-file` was required
   and missing.

The template it renders, for reference (the headings-by-language table below is what `--lang` selects):

````markdown
<!-- pr-explainer:start -->
<!-- pr-explainer:head {headRefOid} -->
{--- only when the author's own text comes first}

**{gist}**

### Before merging
1. what to confirm — how. Passes when: the result
2. ...

### New concepts
- term — what and where

{Mermaid fence, or ![diagram](pinned image URL); omit when there is no diagram}

### Read in this order
★ = read closely
1. ★ `path` — what changed ({category})
   - Why look closely: `path:line` — reason. {Check by: how — only when the focus has `how_to_check`}
2. `path` — what changed ({category})
3. ...
(files of one kind: one directory entry with the count; mechanical files last, one line)

### Not verified
- Opened {files_opened} of {files_total} files ({files_partial} only in part); the rest are described from the diff stat
- {claim} — {why not}

### Evidence (ran just now)
{one line: how many commands ran, and which check was not run}

<details>
<summary>Show the commands and output</summary>

- {what was checked, over what range}
```
{output pasted verbatim}
```

</details>

<!-- pr-explainer:end -->
````

Headings by language (the marker lines are always the English comments, so a re-run finds them):

| `en` | `ja` |
|------|------|
| Before merging | マージ前に確かめること |
| New concepts | 新要素 |
| Read in this order | 読む順序 |
| Not verified | 未検証 |
| Gaps in the description (reviewer report) | 説明のずれ |
| Questions for the author (reviewer report) | 作者への質問 |
| Mode: reviewer (author X, you Y; detected or forced). Target commit | モード: reviewer（作者 X、あなた Y。自動判定または指定）。対象 commit |
| Evidence (ran just now) | 実行結果（直前に実行） |
| Show the commands and output | コマンドと出力を表示 |
| ★ = read closely | ★ = 重点的に見てほしいファイル |
| Why look closely / Check by | 見る理由 / 確認方法 |
| Passes when | 合格の条件 |

Translate the prose and the gist; keep paths, commands, identifiers, `path:line` citations and the pasted
evidence output **verbatim**. Mermaid node labels may be translated, but then the edge comparison in Step 5
runs on the translated labels.

The order follows what the reader needs next: the gist, what to check before merging, the terms the rest uses, the diagram that maps onto the files, the
files to read, what is left for the reader to check, and last the evidence. Evidence is the longest part and the least
actionable, so it is folded in `<details>` with one visible summary line (author mode only: a terminal report is not
folded). Leave a blank line after `<summary>` and before `</details>`, or GitHub shows the Markdown raw.

What `render-section.py` checks for you, in order: the model (Step 2's rules), the unlinked citations, the model
again against the unlinked text (size, Mermaid edges, no verdict word), the links, the linked citations, and the
model again against the linked text. Facts worth knowing about that pipeline:
- A citation names the full repo-relative path: a bare `release.yml` fails `check-refs.py`. Each one becomes a link
  of about 170 characters, so name a file once per `reading_order` entry and refer to it afterwards without
  backticks. A bare name with an unrecognised extension is not checked and is listed on stderr; add its extension
  to `_refs.py`.
- Cite a directory ending in `/`, never a glob (globs are skipped). Routes such as `/privacy` are not checked
  either.
- `check-refs.py` prints the text of every cited line but only checks that the line exists: after it passes, read
  each printed line yourself and confirm it says what the body claims — the script cannot judge that.

Apply only when `render-section.py` exits 0. If it does not, fix the model or the diagram file and run it again;
never apply past a failure.

Then:
- Existing body has the markers: replace between them. Otherwise append the section after the existing body.
  Never delete text outside the markers.
- Match each marker as a **whole line** (`^<!-- pr-explainer:start -->$`). A PR description may mention the
  marker text in prose (for example inside backticks); a substring match would cut there.
- Read the body with `body=$(gh pr view <n> --json body -q .body)`; the command substitution drops the newline
  `gh` appends. Writing `gh`'s raw output back adds one blank line per round trip.
- Write the section in the **reviewer's language**: pass it as `render-section.py --lang ja|en` — `ja|en` if given,
  else the language the user writes to you in (the user is the reviewer or answers for them), else the language the
  PR body already uses. The Japanese headings are in the table above.
- Apply with `gh pr edit <n> --body-file <file>`, then read the body back and confirm the text outside the
  markers is unchanged.
- Report the PR URL, which sections were included, and what is in "Not verified". If the diagram was skipped,
  say why.

## Staleness

Read `references/staleness.md`: when a map goes stale, `scripts/stale-check.py`, the PostToolUse hooks that nudge
re-running this skill, and what the `pr-explainer:*` marker names mean.

## Reviewer mode (a PR someone else wrote)

Read `references/reviewer-mode.md` as soon as Step 1 picks reviewer mode. The model gets `"mode": "reviewer"` and three more lists (`claims`,
`unmentioned`, `questions`). Nothing is written to the PR: the report goes to the terminal and a private
Artifact, and the questions for the author are displayed only. Never run the PR's code unless it is trusted.

## Design sources

Ideas from [ELI5 / Archify / Explainer skills (laiso)](https://blog.lai.so/eli5-archify-explainer-skills/) and the
repositories it links to ([eli5](https://github.com/anthropics/claude-plugins-community/tree/main/eli5),
[archify](https://github.com/tt-a1i/archify), [mizchi/explainer](https://github.com/mizchi/explainer)), read in full.
The `explainer` skill was tried once without its Node tooling (`npx skills use`); its `verify-doc.mjs` and
`first-reader` were not run.

- **archify**: build a typed intermediate representation first, then render from it (Step 2). Its Architecture Delta
  records "no runtime impact, causality, risk, or mergeability is inferred" and rejects verdict words (the
  no-verdict rule). Every node carries a source location (`diagram.edges[].evidence`).
- **mizchi/explainer**: paste executed output instead of retyping it, and mark unchecked claims "未検証" (Step 3,
  "Not verified"); check that a drawn figure's edges equal the edges claimed, both ways (Step 5); value before
  mechanism and the deletion test (Step 7); literate-diff order (`reading_order`); Mermaid first because GitHub
  renders it in a PR body (Step 5). Its persona building, `first-reader` simulation and `verify-doc.mjs` pipeline
  are not adopted: they need Node 24, Playwright and extra tools, and verification covers quoted output, not whether
  the explanation is right.
- **eli5**: not adopted. Its whole body is one sentence aimed at a layperson; a reviewer needs the detail.
- **laiso's comparison Gist**: the reader-map habit of separating what the requester said from what was guessed.

Also: `diagram-design`'s `references/export.md` says its PNG export is always transparent (`omit_background=True`).
`scripts/rasterize.py` exists because of that; revisit it if the exporter gains a background option.

The `pr-assets` branch, commit-pinned URLs, and the marker-delimited body section are original to this skill.
