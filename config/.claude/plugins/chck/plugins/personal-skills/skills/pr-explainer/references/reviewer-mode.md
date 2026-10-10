# Reviewer mode (a PR someone else wrote)

The goal changes from "make this PR easy to read" to "help me decide what to ask the author". The model, the
evidence, the ★ reading order and the citation links all apply unchanged; these differ.

- **Read-only against the remote.** Never edit the PR body, never comment, never push `pr-assets` or anything else.
  Skip Steps 4 and 6 and the marker block. The detached worktree of Step 1 is not optional: you have no checkout.
- **Do not run code you do not trust.** Tests and builds execute the PR's own code with the user's credentials. Run
  them only when `gh pr view <n> --json isCrossRepository` is false and the author is someone the user works with;
  otherwise read only, and put "not run: code from a fork or a stranger" in `unverified`. Read the diff before
  running anything.
- **Judge the PR's account of itself.** Set `"mode": "reviewer"` in the model and add four lists:

```json
  "mode": "reviewer",
  "claims": [{"claim": "what the title, body or a commit says, in the author's words",
              "source": "title | body | commit <sha>",
              "status": "matches | differs | not_in_diff | not_checked", "evidence": "path:line, or what you ran"}],
  "unmentioned": [{"path": "a changed file the description does not mention", "what": "one line"}],
  "test_gaps": [{"behaviour": "...", "where": "path:line", "note": "no test covers it, or the test asserts less than its name says"}],
  "questions": [{"where": "path:line", "ask": "a question the author can answer in one line"}]
```

  `check-model.py` checks the shape and, with `--files`, that every `unmentioned` path is a changed file. List every
  claim the description makes; `not_in_diff` means the diff does not show it, which is not the same as false.
  Agent-written PRs overstate, so look first at "tests added", "no behaviour change" and "refactor only". The size
  limit does not apply to a report.
- **Output**, in the reviewer's language, as one Markdown report: the gist; "Claims vs the diff" (every claim with
  its status and place); "Not in the description" (`unmentioned`); "Test gaps"; then "New concepts", "Read in this
  order" (★ lines and links), "Evidence", "Not verified"; and "Questions for the author", each with its `path:line`
  link. Run the citation check and `link-refs.py` on it as in Step 7. Then:
  1. Print the report in the terminal. That is the primary output.
  2. If the `Artifact` tool is available, load `artifact-design` and publish the same report as a **private**
     Artifact (this skill asks for a Markdown page: it is a text report with links). Do not share it.
  3. The questions are **displayed only**. Do not post them as a review or a comment. If the user asks, draft a
     pending review for them to submit themselves.

Details that are easy to get wrong:
- `claims` records what the PR says and how it fared. A claim with status `not_checked` also gets an `unverified`
  entry with the reason; that overlap is intended. `coverage` counts exactly as in author mode.
- The verdict-word check reads quoted claims too. Paraphrase the author's wording ("the author calls it safe")
  instead of quoting SAFE, LOW RISK or MERGEABLE.
- `check-refs.py` only sees backticked paths and `path:line` outside fenced code. In `claims[].evidence`, cite a
  backticked `path:line` to have it checked; a note of what you ran is not checked. Paste command output inside a
  fence; to show a fence inside a fence, open the outer one with four backticks.
- `--expect-head` takes `headRefOid` from `gh pr view <n> --json headRefOid`.
- The report may carry a Mermaid fence under the gist when the change has a flow worth drawing; otherwise set
  `diagram.type` to `none`.
- If the Artifact renders a link or a fence badly, the terminal copy is the reference.
