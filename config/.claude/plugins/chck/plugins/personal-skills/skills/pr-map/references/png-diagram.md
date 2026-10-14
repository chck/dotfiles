# PNG diagram tier

Read this when Step 5 picks the PNG tier: Mermaid cannot express the diagram, or it needs more nodes than
Mermaid's ~6-node limit for a PR body.

Use the `diagram-design` skill with the model's `diagram` block: at most 9 nodes, colour only the `focus` nodes,
show the change and not the whole system.

1. Export with `scripts/rasterize.py <diagram.html> <diagram.png>`. The `diagram-design` exporter writes a
   transparent PNG, unreadable on GitHub's dark theme; this script flattens it onto an opaque background. If it
   reports Playwright missing, give the user the install command it prints and stop; do not install anything.
2. Read the PNG back; check the labels are legible and match `diagram.edges` in both directions.

## Publish the image

Host the PNG on the `pr-assets` branch so it never enters the PR diff or `main`:

```bash
scripts/publish-asset.sh <owner/repo> <pr-number> <diagram.png>   # prints the pinned image URL
```

It creates `pr-assets` as an orphan branch on first use, commits `pr-<n>/diagram.png` through the contents API
(no checkout, no worktree), and prints a URL pinned to the commit SHA.

**On a PUBLIC repo, show the PNG path and ask before running it.** On a private repo, run it.

Pass the printed URL to `render-section.py --diagram-file` as a single `![diagram](<url>)` line (no fence
delimiters) — Step 7 tells it apart from a Mermaid body by that `![` prefix.
