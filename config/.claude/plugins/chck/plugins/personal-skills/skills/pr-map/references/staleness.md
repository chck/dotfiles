# Staleness

Read this when asked whether a map is stale, when re-running the skill on a PR that already has a block, or when
the marker names below show up unexplained in a PR body.

(The marker names in a PR body, `<!-- pr-explainer:start -->`, `end` and `head`, keep the skill's old name on purpose:
they are invisible to readers, already sit in existing PR bodies, and a re-run finds its block by them. Do not
rename them. The old environment variable `PR_EXPLAINER_AUTO` still works as `PR_MAP_AUTO`.)

A map and a report are snapshots of one commit. The block records it in its first comment line,
`<!-- pr-explainer:head <headRefOid> -->`; a reviewer report names it on the Mode line ("Target commit"). A later
commit can change a file the map cites, answer a question or overturn a gap, and nothing else says so.

- `scripts/stale-check.py <file | --pr N>` compares the recorded commit with the current head and lists the cited
  files that changed since (exit 0 current, 1 stale, 2 unknown).
- The user's PostToolUse hooks run `scripts/nudge.py`: after `gh pr create` it tells you to ASK the user whether to run
  this skill for the new PR only when the PR's size, whether a reviewer is requested and how often the repository's recent PRs got a
  human review say a map is worth it (a PR its author merges alone rarely needs one, and then the hook says not to ask; a PUBLIC repository: privacy check and confirm first; a draft may wait), and
  after `git push` it says so when a map already in the PR body is stale. It only prompts; the skill does the work.
  `PR_MAP_AUTO=0` silences it, `=always` makes the first hook say to run the skill without asking.
- A re-run replaces only the block between the markers. Do it when the PR is ready for review, or when asked; there is
  no partial refresh.
