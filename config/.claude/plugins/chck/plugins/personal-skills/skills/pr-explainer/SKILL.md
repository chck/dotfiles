---
name: pr-explainer
description: >
  Write a reviewer's map into a pull request body: one-line gist, a reading order with a one-line summary per file,
  new concepts, evidence you actually ran, what is not verified, ★ on the files to read closely, and a diagram of the change, all derived
  from the diff. Use when the user wants an agent-made PR to be easier to review, or says "PR を読みやすくして",
  "レビュー用の説明を付けて", "PR explainer", "explain this PR", "make this PR reviewable". Simple diagrams go in
  the body as Mermaid; complex ones are exported with diagram-design and hosted on a `pr-assets` branch.
argument-hint: "[PR number (defaults to the current branch's PR)] [--lang ja|en]"
---

# PR Explainer

Goal: the reviewer knows **what changed, where to look first, what was actually checked, and which files to read closely**
before opening the diff. Describe the change from the diff, not from the commit messages: agent-written messages
often describe intent, not result.

## Step 1: Resolve the PR and check visibility

- Use `$ARGUMENTS` as the PR number, else `gh pr view --json number` for the current branch.
- `gh repo view --json visibility,nameWithOwner` — keep both. **PUBLIC** changes Steps 4 and 6. For another
  repository pass it positionally (`gh repo view <owner/repo>`); `-R <owner/repo>` belongs to `gh pr`.
- `gh pr view <n> --json title,body,baseRefName,baseRefOid,headRefOid`, `gh pr diff <n>`, and `gh pr diff <n> --name-only`
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
  "gist": "one sentence: what happens once this is merged",
  "new_concepts": ["term: what it is, where it lives"],
  "reading_order": [{"path": "...", "what": "one line, from the diff", "why": "core | contract | migration | config | tests | docs | mechanical",
                     "focus": [{"where": "path:line", "what": "why this place deserves a close read", "how_to_check": "..."}]}],
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
`gh pr diff <n> --name-only`; it must exit 0. It rejects empty entries, "...", TODO, a missing `coverage`, a `why`
outside the list, a `what` over 300 characters, an edge whose cited `path:line` does not exist, any changed file that no
`reading_order` entry covers, and a directory entry whose `count` is not the number of files it really covers. A PR of
100 files is where this gets skipped.

Rules:
- **Facts and judgment stay apart.** `reading_order` (its `what`), `evidence` and `diagram.edges` are facts taken from the diff or from a
  run. A `focus` entry is the author's judgment: it asks the reviewer to look, it does not claim a defect. The ★ and the "Why look closely" line set it apart from the facts around it. Never write a verdict word anywhere
  (SAFE, LOW RISK, MERGEABLE, "no impact"): this skill reads a diff, it does not know runtime impact.
- `gist` is one sentence about the effect after merge, with a verb that says what now happens or what a user can
  now do ("calling X now writes Y"). "Adds X" or "changes Y" alone is a label, not a gist. The deletion test in
  Step 7 judges it; `check-model.py` only checks that it is not empty.
- `reading_order` is one list that is both the order to read in and the per-file summary. It starts with the file
  where a wrong line costs the most, and `why` is its category: core, contract, migration, config, tests, docs or mechanical. That is the
  default order, the costliest files first within a category. `what` is at most 300 characters. Mechanical files
  (renames, lockfiles, generated code) go last.
- Five or more files of one kind (mechanical files, or the test files of one directory) become **one** `reading_order`
  entry that cites the directory (ending in `/`), gives the count, and says what they cover; never one entry per
  file. Whatever the grouping, every changed file is covered by some entry (`check-model.py --files` checks it).
- A directory entry carries a `count`: the changed files under it that no other entry lists. `check-model.py --files`
  compares it with the real number, so a group cannot silently swallow files. A deleted file is covered by an entry
  with its old path; write it in plain text in the body, not in backticks.
- Numbers in the body (cases, tests, lines, files) come from a command you ran, or are left out. Do not estimate.
- Tests are a change like any other: say what behaviour they cover and roughly how much, in `reading_order`. A PR
  whose tests are only named reads as untested.
- `coverage` is honest: a file is *opened* when you read its diff or its content. Seeing its name in the diff stat
  or its title does not count. A file you read only in part is counted in `files_partial` and named under "Not verified".
  A starred file counts as opened: do not star a file you did not read. If fewer than half the files were opened,
  the gist or the first line of "Not verified" says so.
- Keep the section short enough to read: above about 25000 characters of the final, linked section, group `reading_order` by
  area. The PR body is capped at 65536 characters, the existing body included; `check-model.py --section` fails above
  45000. Links add about a third, so measure after linking.
- `new_concepts` comes before the reading order in the body, so the terms the order uses are already known. It lists only what the PR introduces. Do not re-explain what AGENTS.md or the code already states.
- A `reading_order` entry gets a `focus` list, and a ★ in the body, when a wrong line there costs the most. Each
  focus names a place (`path:line`, which may be in another file the change affects) and a way to check it; one with
  neither is noise, drop it. Write it as a reason to read closely, not as a verdict that something is broken. Star
  few entries: when most have a ★, none stands out.
- Every `diagram.edges` entry cites a place in the diff. An edge without one is not drawn.
- Empty sections are omitted, never padded. `diagram.type` is `none` when there is no structure to draw:
  typo, docs-only, config value, single-function fix.

## Step 3: Run before you write

Anything the body would say passes, works, or renders needs an `evidence` entry: run the command now, in the
PR-head checkout, and paste the output **verbatim**. Never retype or summarise output.

- Cheap checks to run when they apply: the test command, the linter named in AGENTS.md, `bash -n` and `shellcheck`
  for shell, a dry run of a new script.
- A claim you did not or could not run goes to `unverified` with the reason. "Not run" is a fine answer; an
  unlabelled claim is not.
- Claims copied from the PR body or commit messages ("278 tests pass") go to `unverified` unless you ran them.
  Operational steps the body lists (a flag to flip, a migration to run) are carried over there too, attributed to
  the PR body.
- Dependencies missing in the checkout: do not install. Name the repo's own check command first in
  `unverified`, one entry per toolchain (for example `cargo test` and `npm run check`), and say it was not run.
- A copied claim you could check by reading the code (not by running it) is written as exactly that: "read the
  code, did not run the test".
- If a check used a scratch file the reviewer cannot see, put the script in `cmd` or write "scratch file, not in
  the repo". Write its name in plain text or inside the fenced `cmd`, never in backticks in the body: the citation
  check reads backticked names as repo paths.
- Name the exact command you ran. If it differs from the repo's wrapper (a Makefile or task-runner target), say so.
  Keep the exit status: run the command without a pipe and print `exit=$?` on the next line (a pipe loses it, and
  `PIPESTATUS` differs between bash and zsh). A `cmd; echo exit=$?` sequence is fine. Avoid `sed -i` in scripts you give the reader: BSD and GNU differ.
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

**PNG** — when Mermaid cannot express it or the diagram is larger. Use the `diagram-design` skill with the model's
`diagram` block: at most 9 nodes, colour only the `focus` nodes, show the change and not the whole system.
1. Export with `scripts/rasterize.py <diagram.html> <diagram.png>`. The `diagram-design` exporter writes a
   transparent PNG, unreadable on GitHub's dark theme; this script flattens it onto an opaque background. If it
   reports Playwright missing, give the user the install command it prints and stop; do not install anything.
2. Read the PNG back; check the labels are legible and match `diagram.edges` in both directions.

## Step 6: Publish the image (PNG tier only)

Host the PNG on the `pr-assets` branch so it never enters the PR diff or `main`:

```bash
scripts/publish-asset.sh <owner/repo> <pr-number> <diagram.png>   # prints the pinned image URL
```

It creates `pr-assets` as an orphan branch on first use, commits `pr-<n>/diagram.png` through the contents API
(no checkout, no worktree), and prints a URL pinned to the commit SHA.

**On a PUBLIC repo, show the PNG path and ask before running it.** On a private repo, run it.

## Step 7: Write the body section

Build this section, then put it in the PR body between the markers so a re-run replaces it in place:

````markdown
<!-- pr-explainer:start -->
## Reviewer's map

**{gist}**

{Mermaid fence, or ![diagram](pinned image URL); omit when there is no diagram}

### New concepts
- term — what and where

### Read in this order
★ = read closely
1. ★ `path` — what changed ({category})
   - Why look closely: `path:line` — reason. Check by: how
2. `path` — what changed ({category})
3. ...
(files of one kind: one directory entry with the count; mechanical files last, one line)

### Evidence (ran just now)
- {what was checked, over what range}
```
{output pasted verbatim}
```

### Not verified
- Opened {files_opened} of {files_total} files ({files_partial} only in part); the rest are described from the diff stat
- {claim} — {why not}

<!-- pr-explainer:end -->
````

Headings by language (the marker lines are always the English comments, so a re-run finds them):

| `en` | `ja` |
|------|------|
| Reviewer's map | Reviewer's map (kept in English: the title is a fixed name, not a translation) |
| New concepts | 新しい概念 |
| Read in this order | 読む順序 |
| Evidence (ran just now) | 実行結果（直前に実行） |
| Not verified | 未検証 |
| ★ = read closely | ★ = 重点的に見てほしいファイル |
| Why look closely / Check by | 見る理由 / 確認方法 |

Translate the prose and the gist; keep paths, commands, identifiers, `path:line` citations and the pasted
evidence output **verbatim**. Mermaid node labels may be translated, but then the edge comparison in Step 5
runs on the translated labels.

Before applying:
1. **Deletion test.** Remove "Read in this order" and "Evidence": the gist must still stand. Remove the gist: if what
   remains only reads the evidence aloud, rewrite the gist. Cut any section whose removal changes nothing.
2. **Citation check.** `scripts/check-refs.py <body-file> --expect-head <headRefOid> [--root <dir>]` must exit 0:
   every backticked path or `path:line` in the body exists in the PR-head checkout. Fix or drop what it reports.
   It prints the text of every cited line but only checks that the line exists, so read each printed line and
   confirm it says what the body claims.
   Write the full repo-relative path on **every** mention, prose included: a bare `release.yml` fails. A bare name
   with an unrecognised extension is not checked and is listed on stderr; add its extension to `_refs.py`.
   Cite a directory ending in `/`, never a glob (globs are skipped). Write a deleted file in plain text, without
   backticks: it is not tracked at HEAD. Routes such as `/privacy` are not checked either.
3. **Link the citations.** After the check passes, run
   `scripts/link-refs.py <body-file> --repo <owner/repo> --pr <n> --base-sha <baseRefOid> --head-sha <headRefOid> --write`
   (`--root <dir>` for a fetched clone; it reads git objects, no checkout needed). Each backticked `path` or
   `path:line` becomes a link: to the PR's Files changed view (`.../pull/<n>/changes#diff-<sha256 of path>R<line>`)
   when the file is changed and every cited line sits inside a diff hunk, so the reviewer can comment on that line;
   otherwise to a permalink at the head commit (`.../blob/<sha>/<path>#L<line>`). Fenced code and existing links are
   left alone. Run `check-refs.py` once more on the linked text; it must still exit 0.
4. **Size and edges on the final text.** Run `check-model.py pr-<n>.json --files <names.txt> --root <dir> --section <body-file>`
   on the linked text, after the model-alone run of Step 2. Links add about a third to the length, so the size limit
   is judged here.

Apply only when the citation check exited 0. If it did not, fix the body and run it again; never apply past a failure.

Then:
- Existing body has the markers: replace between them. Otherwise append the section after the existing body.
  Never delete text outside the markers.
- Match each marker as a **whole line** (`^<!-- pr-explainer:start -->$`). A PR description may mention the
  marker text in prose (for example inside backticks); a substring match would cut there.
- Read the body with `body=$(gh pr view <n> --json body -q .body)`; the command substitution drops the newline
  `gh` appends. Writing `gh`'s raw output back adds one blank line per round trip.
- Write the section in the **reviewer's language**: `--lang ja|en` if given, else the language the user writes to
  you in (the user is the reviewer or answers for them), else the language the PR body already uses. The Japanese
  headings are in the table below.
- Apply with `gh pr edit <n> --body-file <file>`, then read the body back and confirm the text outside the
  markers is unchanged.
- Report the PR URL, which sections were included, and what is in "Not verified". If the diagram was skipped,
  say why.

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
