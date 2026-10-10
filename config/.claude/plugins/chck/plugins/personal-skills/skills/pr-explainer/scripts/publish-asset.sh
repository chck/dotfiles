#!/usr/bin/env bash
# Host a PR image on the `pr-assets` branch and print a commit-pinned URL.
#
# Usage: publish-asset.sh <owner/repo> <pr-number> <image.png>
#
# Commits `pr-<n>/<basename>` to the `pr-assets` branch through the contents
# API, so nothing is checked out and the PR diff and `main` stay untouched.
# On first use the branch is created as an orphan (no shared history with main).
#
# Prints the image URL on stdout as its last line. The URL points at the commit
# SHA, so a later push to `pr-assets` cannot change what the PR shows.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $(basename "$0") <owner/repo> <pr-number> <image.png>" >&2
  exit 64
fi

repo=$1 pr=$2 image=$3
branch="pr-assets"

[[ -f $image ]] || { echo "$image: no such file. Pass the PNG that rasterize.py wrote." >&2; exit 1; }
[[ $pr =~ ^[0-9]+$ ]] || { echo "$pr: PR number must be an integer." >&2; exit 64; }

dest="pr-${pr}/$(basename "$image")"

# Create the orphan branch on first use: empty tree -> parentless commit -> ref.
if ! gh api "repos/${repo}/git/ref/heads/${branch}" >/dev/null 2>&1; then
  tree=$(jq -n '{tree: [{path: "README.md", mode: "100644", type: "blob",
      content: "Images referenced by pull request descriptions. Not part of the codebase."}]}' \
    | gh api -X POST "repos/${repo}/git/trees" --input - --jq .sha)
  commit=$(gh api -X POST "repos/${repo}/git/commits" -f message='chore: create pr-assets branch' -f "tree=${tree}" --jq .sha)
  gh api -X POST "repos/${repo}/git/refs" -f "ref=refs/heads/${branch}" -f "sha=${commit}" >/dev/null
fi

# Re-publishing the same path needs the current blob SHA.
if ! existing=$(gh api "repos/${repo}/contents/${dest}?ref=${branch}" --jq .sha 2>&1); then
  if [[ $existing == *"Not Found"* ]]; then
    existing=""
  else
    echo "could not read ${dest} on ${branch}: ${existing}. Check gh auth and access to ${repo}." >&2
    exit 1
  fi
fi

args=(-X PUT "repos/${repo}/contents/${dest}" -f "message=chore: add ${dest}" -f "branch=${branch}")
[[ -n $existing ]] && args+=(-f "sha=${existing}")

commit_sha=$(base64 < "$image" | tr -d '\n' | gh api "${args[@]}" -F content=@- --jq .commit.sha)

echo "https://github.com/${repo}/blob/${commit_sha}/${dest}?raw=true"
