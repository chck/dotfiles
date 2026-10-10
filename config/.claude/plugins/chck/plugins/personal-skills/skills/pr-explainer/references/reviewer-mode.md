# Reviewer mode (a PR someone else wrote)

The goal changes from "make this PR easy to read" to "help me decide what to ask the author". The model, the
evidence, the ★ reading order and the citation links all apply unchanged; these differ.

## Rules

- **Read-only against the remote.** Never edit the PR body, never comment, never push `pr-assets` or anything else.
  Skip Steps 4 and 6 and the marker block. The detached worktree of Step 1 is not optional: you have no checkout.
- **Do not run code you do not trust.** Tests and builds execute the PR's own code with the user's credentials. Run
  them only when `gh pr view <n> --json isCrossRepository` is false and the author is someone the user works with;
  otherwise read only, and put "not run: code from a fork or a stranger" in `unverified`. Read the diff before
  running anything.
- **The author's account is the text outside the markers.** If the body already holds a pr-explainer block (between
  the `<!-- pr-explainer:start -->` and `end` lines), a tool wrote it: take no claim from it, and do not treat it as
  the author's words.
- **Write everything in the reviewer's language**: every question, every gap, even when the PR, its commits and the
  author are in English. Keep only a short quote of the author's own words in its language, inside a sentence in the
  reviewer's language. Run `check-model.py --lang <ja|en>` so a Japanese report cannot ship in English. When the user
  posts the questions, offer an English version if the author reads English.

## The model

Set `"mode": "reviewer"` and add three lists:

```json
  "mode": "reviewer",
  "claims": [{"claim": "what the title, body or a commit says, in the author's words",
              "source": "title | body | commit <sha>",
              "status": "matches | partial | differs | not_in_diff | not_checked",
              "evidence": "path:line, or what you ran"}],
  "unmentioned": [{"path": "a changed file the description does not mention, or a directory ending in / with a `count`",
                   "what": "one line"}],
  "questions": [{"where": "path:line", "ask": "a question the author can answer in one line"}]
```

- Judge **every** claim the description makes. Statuses:
  - `matches`: the diff does what the text says.
  - `partial`: the diff does something, but the text overstates it or implies what the diff does not do ("seed data
    removed", yet the rows that already exist stay).
  - `differs`: the diff contradicts the text.
  - `not_in_diff`: the diff does not show it (which is not the same as false); say what you searched for.
  - `not_checked`: you could not check it (needs a database, a browser, a remote); it also gets an `unverified` entry.
- A `differs` or `partial` claim cites a `path:line` in `evidence`; `check-model.py` fails without one, and with
  `--root` it checks that the line exists.
- `unmentioned` lists changed files the description never mentions. A directory entry (for example all the test files)
  carries a `count` equal to the changed files under it; `--files` checks it. The description saying nothing about
  tests is an `unmentioned` entry for the test directory.
- Agent-written PRs overstate, so look first at "tests added", "no behaviour change", "refactor only" and the test
  counts they quote. A test gap is not a list of its own: put it in the ★ "why look closely" line of the file it
  concerns, or in a question.

## The report

One short Markdown report, in this order:

1. The gist, then one line with the mode: "Mode: reviewer (author X, you Y; detected | forced with --as)".
2. **Gaps in the description** (説明のずれ): only the `differs`, `partial` and `not_in_diff` claims and the `unmentioned`
   entries, one line each, after a single count line ("38 of 42 claims match the diff"). Do not list the claims that
   match. The `not_checked` claims go under "Not verified", not here, so they do not bury the real gaps.
3. **New concepts**, then the diagram if the change has a flow worth drawing (otherwise set `diagram.type` to `none`).
   The model and the report agree: a model that keeps a diagram needs its fence in the report, or `--section` fails
   on the missing edges.
4. **Read in this order**: the ★ lines and links, as in author mode.
5. **Questions for the author** (作者への質問), about five at most. Each comes from a gap or a ★ line and says which:
   cite the same `path:line`. The questions lead the decision, so make them the part the reader cannot skip.
6. **Not verified**, then **Evidence** last. Do not fold the evidence: the report is read in the terminal.

Headings come from the table in SKILL.md; the two that only a reviewer report has are "Gaps in the description" =
説明のずれ and "Questions for the author" = 作者への質問. Name the file after the PR (`pr-<n>-review.md`) and start it
with a one-line heading, so the Artifact has a meaningful title.

## Checks and output

1. `check-model.py <model> --files <names.txt> --root <checkout> --lang <ja|en>` before writing the report.
2. Run `link-refs.py --wrap-bare --write` on the report: it puts bare repo paths and identifiers with underscores in
   backticks (outside them Markdown reads the underscores as emphasis) and then links the citations. Run
   `check-refs.py` before and after, and `check-model.py --section` on the linked report.
3. Print the report in the terminal. That is the primary output.
4. If the `Artifact` tool is available, load `artifact-design` and publish the same report as a **private** Artifact
   (this skill asks for a Markdown page: it is a text report with links). Do not share it. If the Artifact renders a
   link or a fence badly, the terminal copy is the reference.
5. The questions are **displayed only**. Do not post them as a review or a comment. If the user asks, draft a pending
   review for them to submit themselves.

## Details that are easy to get wrong

- The size limit does not apply to a report, but `check-model.py --section` prints a note above 20000 characters of
  the linked text (links add 40-60%). It counts characters, not bytes (`wc -c` counts bytes).
- The verdict-word check reads quoted claims too. Paraphrase the author's wording ("the author calls it safe")
  instead of quoting SAFE, LOW RISK or MERGEABLE.
- A deleted file is written in plain text, without backticks, and without a path the citation check could look up:
  it is not tracked at HEAD, so a backticked name fails.
- `check-refs.py` only sees backticked paths and `path:line` outside fenced code. Paste command output inside a
  fence; to show a fence inside a fence, open the outer one with four backticks.
- `--expect-head` takes `headRefOid` from `gh pr view <n> --json headRefOid`. `coverage` counts exactly as in
  author mode; the opened counts are your own declaration, which the script cannot verify.
