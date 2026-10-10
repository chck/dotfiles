---
name: pr-explainer
description: >
  Write a reviewer's map into a pull request body: one-line gist, review order, per-file change summary,
  new concepts, evidence you actually ran, what is not verified, risks, and a diagram of the change, all derived
  from the diff. Use when the user wants an agent-made PR to be easier to review, or says "PR を読みやすくして",
  "レビュー用の説明を付けて", "PR explainer", "explain this PR", "make this PR reviewable". Simple diagrams go in
  the body as Mermaid; complex ones are exported with diagram-design and hosted on a `pr-assets` branch.
argument-hint: "[PR number (defaults to the current branch's PR)]"
---

# PR Explainer

Goal: the reviewer knows **what changed, where to look first, what was actually checked, and what could be wrong**
before opening the diff. Describe the change from the diff, not from the commit messages: agent-written messages
often describe intent, not result.

## Step 1: Resolve the PR and check visibility

- Use `$ARGUMENTS` as the PR number, else `gh pr view --json number` for the current branch.
- `gh repo view --json visibility,nameWithOwner` — keep both. **PUBLIC** changes Steps 4 and 6.
- `gh pr view <n> --json title,body,files,baseRefName,headRefOid` and `gh pr diff <n>`.
- Work from a checkout of the PR head (the PR's own worktree, or `gh pr checkout`); Steps 3 and 7 read files from it.
- Read the repo's `AGENTS.md` for conventions the diff is judged against.

## Step 2: Build the model first, prose second

Write one structured model to the scratchpad (`pr-<n>.json`); the body and the diagram both come from it,
so they cannot disagree.

```json
{
  "gist": "one sentence: what the PR does now that it did not before",
  "review_order": [{"path": "...", "why": "core logic | contract change | tests | mechanical"}],
  "changes": [{"path": "...", "what": "one line, from the diff"}],
  "new_concepts": ["term: what it is, where it lives"],
  "evidence": [{"claim": "...", "cmd": "...", "output": "pasted verbatim"}],
  "unverified": [{"claim": "...", "why_not": "..."}],
  "risks": [{"where": "path:line", "what": "behaviour that could be wrong", "how_to_check": "..."}],
  "diagram": {
    "type": "mermaid | sequence | data-flow | architecture | none",
    "focus": ["1-2 nodes that changed"],
    "edges": [{"from": "...", "to": "...", "evidence": "path:line"}]
  }
}
```

Rules:
- **Facts and judgment stay apart.** `changes`, `evidence` and `diagram.edges` are facts taken from the diff or from a
  run. `risks` is the author's judgment and the body labels it so. Never write a verdict word anywhere
  (SAFE, LOW RISK, MERGEABLE, "no impact"): this skill reads a diff, it does not know runtime impact.
- `review_order` starts with the file where a wrong line costs the most; mechanical files (renames, lockfiles,
  generated code) go last and collapse into one line in the body.
- `new_concepts` lists only what the PR introduces. Do not re-explain what AGENTS.md or the code already states.
- `risks` must name a place and a way to verify. A risk with neither is noise; drop it.
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
2. List the edges in the finished source and compare with `diagram.edges` **in both directions**: an edge only in
   the source is invented, an edge only in the model is missing. Fix the source until both lists match.

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

### Read in this order
1. `path` — why
2. ...
(mechanical files: one collapsed line)

### What changed
- `path` — what

### New concepts
- term — what and where

### Evidence (ran just now)
- {what was checked, over what range}
```
{output pasted verbatim}
```

### Not verified
- {claim} — {why not}

### Where it could be wrong (author's judgment)
- `path:line` — what. Check by: how
<!-- pr-explainer:end -->
````

Before applying:
1. **Deletion test.** Remove "What changed" and "Evidence": the gist must still stand. Remove the gist: if what
   remains only reads the evidence aloud, rewrite the gist. Cut any section whose removal changes nothing.
2. **Citation check.** `scripts/check-refs.py <body-file> --expect-head <headRefOid>` must exit 0: every
   backticked path or `path:line` in the body exists in the PR-head checkout. Fix or drop what it reports.

Apply only when the citation check exited 0. If it did not, fix the body and run it again; never apply past a failure.

Then:
- Existing body has the markers: replace between them. Otherwise append the section after the existing body.
  Never delete text outside the markers.
- Match each marker as a **whole line** (`^<!-- pr-explainer:start -->$`). A PR description may mention the
  marker text in prose (for example inside backticks); a substring match would cut there.
- Read the body with `body=$(gh pr view <n> --json body -q .body)`; the command substitution drops the newline
  `gh` appends. Writing `gh`'s raw output back adds one blank line per round trip.
- Write in the language the PR body already uses; default to the user's language.
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
  mechanism and the deletion test (Step 7); literate-diff order (`review_order`); Mermaid first because GitHub
  renders it in a PR body (Step 5). Its persona building, `first-reader` simulation and `verify-doc.mjs` pipeline
  are not adopted: they need Node 24, Playwright and extra tools, and verification covers quoted output, not whether
  the explanation is right.
- **eli5**: not adopted. Its whole body is one sentence aimed at a layperson; a reviewer needs the detail.
- **laiso's comparison Gist**: the reader-map habit of separating what the requester said from what was guessed.

Also: `diagram-design`'s `references/export.md` says its PNG export is always transparent (`omit_background=True`).
`scripts/rasterize.py` exists because of that; revisit it if the exporter gains a background option.

The `pr-assets` branch, commit-pinned URLs, and the marker-delimited body section are original to this skill.
