---
name: pr-explainer
description: >
  Write a reviewer's map into a pull request body: one-line gist, review order, per-file change summary,
  new concepts, risks, and a PNG diagram of the change, all derived from the diff. Use when the user wants
  an agent-made PR to be easier to review, or says "PR を読みやすくして", "レビュー用の説明を付けて",
  "PR explainer", "explain this PR", "make this PR reviewable". Reads the diff and the repo's conventions;
  the diagram comes from diagram-design and is hosted on a `pr-assets` branch so the PR diff stays clean.
argument-hint: "[PR number (defaults to the current branch's PR)]"
---

# PR Explainer

Goal: the reviewer knows **what changed, where to look first, and what could be wrong** before opening the diff.
Describe the change from the diff, not from the commit messages: agent-written messages often describe intent, not result.

## Step 1: Resolve the PR and check visibility

- Use `$ARGUMENTS` as the PR number, else `gh pr view --json number` for the current branch.
- `gh repo view --json visibility,nameWithOwner` — keep both. **PUBLIC** changes Steps 3 and 5.
- `gh pr view <n> --json title,body,files,baseRefName,headRefOid` and `gh pr diff <n>`.
- Read the repo's `AGENTS.md` for conventions the diff is judged against.

## Step 2: Build the model first, prose second

Write one structured model to the scratchpad (`pr-<n>.json`); both the body and the diagram come from it,
so they cannot disagree.

```json
{
  "gist": "one sentence: what the PR does now that it did not before",
  "review_order": [{"path": "...", "why": "core logic | contract change | tests | mechanical"}],
  "changes": [{"path": "...", "what": "one line, from the diff"}],
  "new_concepts": ["term: what it is, where it lives"],
  "risks": [{"where": "path:line", "what": "behaviour that could be wrong", "how_to_check": "..."}],
  "diagram": {"type": "sequence | data-flow | architecture | none", "focus": ["1-2 nodes that changed"]}
}
```

Rules:
- `review_order` starts with the file where a wrong line costs the most; mechanical files (renames, lockfiles,
  generated code) go last and are collapsed into one line in the body.
- `new_concepts` lists only what the PR introduces. Do not re-explain what the repo's AGENTS.md or code already states.
- `risks` must name a place and a way to verify. A risk with neither is noise; drop it.
- Empty sections are omitted, never padded.
- `diagram.type` is `none` when the change has no structure to draw: typo, docs-only, config value, single-function fix.

## Step 3: Privacy check (mandatory on PUBLIC repos)

Everything below becomes world-readable, and an image pushed to GitHub cannot be fully removed afterwards.
Before writing the body or the diagram, scan the model for private or internal org, repo, host, and
project names. Replace each with a generic description. Do not carry them into node labels either.

## Step 4: Diagram (skip when `diagram.type` is `none`)

1. Use the `diagram-design` skill with the model's `diagram` block. At most 9 nodes; colour only the `focus` nodes.
   Show **the change**, not the whole system. Sequence for control flow, data-flow for pipelines,
   architecture for module boundaries.
2. Export a PNG with `scripts/rasterize.py <diagram.html> <diagram.png>`.
   The `diagram-design` exporter writes a transparent PNG, which is unreadable on GitHub's dark theme;
   this script flattens it onto an opaque background. If it reports Playwright missing, give the user the
   install command it prints and stop; do not install anything.
3. Read the PNG back and check the labels are legible and match the model.

## Step 5: Publish the image

Host the PNG on the `pr-assets` branch so it never enters the PR diff or `main`:

```bash
scripts/publish-asset.sh <owner/repo> <pr-number> <diagram.png>   # prints the pinned image URL
```

It creates `pr-assets` as an orphan branch on first use, commits `pr-<n>/diagram.png` through the contents API
(no checkout, no worktree), and prints a URL pinned to the commit SHA.

**On a PUBLIC repo, show the PNG path and ask before running it.** On a private repo, run it.

## Step 6: Write the body section

Build this section, then put it in the PR body between the markers so a re-run replaces it in place:

```markdown
<!-- pr-explainer:start -->
## Reviewer's map

**{gist}**

![diagram]({pinned image URL})   <!-- omit when there is no diagram -->

### Read in this order
1. `path` — why
2. ...
(mechanical files: one collapsed line)

### What changed
- `path` — what

### New concepts
- term — what and where

### Where it could be wrong
- `path:line` — what. Check by: how
<!-- pr-explainer:end -->
```

- Existing body has the markers: replace between them. Otherwise append the section after the existing body.
  Never delete text outside the markers.
- Write in the language the PR body already uses; default to the user's language.
- Apply with `gh pr edit <n> --body-file <file>`.
- Report the PR URL and which sections were included. If the diagram was skipped, say why.
