#!/usr/bin/env bash
# Collect the raw material for a work digest: what was asked (Claude Code
# session logs) and what shipped (git log), grouped by repository.
#
# Usage: collect.sh [--since <date>] [--until <date>] [--out <dir>]
#
#   --since   ISO date, inclusive. Default: 14 days ago.
#   --until   ISO date, inclusive. Default: today.
#   --out     Output directory. Default: a mktemp -d directory.
#
# Writes to <out>:
#   index.tsv          one row per repo: slug, path, counts, file paths
#   summary.txt        totals across all repos
#   prompts/<slug>.tsv  date <TAB> user prompt (400 chars max)
#   gitlog/<slug>.txt   commit date <TAB> author <TAB> subject
#
# Prints the output directory on stdout as its last line.

set -euo pipefail

PROJECTS="${CLAUDE_PROJECTS_DIR:-$HOME/.config/claude/projects}"
SINCE=""
UNTIL=""
OUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --until) UNTIL="$2"; shift 2 ;;
    --out)   OUT="$2";   shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# date(1) differs between macOS and GNU; try BSD syntax first.
[ -n "$SINCE" ] || SINCE=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d '14 days ago' +%Y-%m-%d)
[ -n "$UNTIL" ] || UNTIL=$(date +%Y-%m-%d)
[ -n "$OUT" ]   || OUT=$(mktemp -d)

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
[ -d "$PROJECTS" ] || { echo "no session logs at $PROJECTS" >&2; exit 1; }

mkdir -p "$OUT/prompts" "$OUT/gitlog"
: > "$OUT/index.tsv"

ME=$(git config --get user.name || echo "")

# Subagent transcripts live in */subagents/ and repeat the parent's work, so
# they are excluded. Session files carry a `cwd`, which is more reliable than
# decoding the mangled project directory name.
find "$PROJECTS" -name '*.jsonl' -not -path '*/subagents/*' -print0 |
while IFS= read -r -d '' session; do
  first=$(jq -rc 'select(.timestamp) | {t: .timestamp[0:10], cwd: .cwd} | select(.cwd != null)' "$session" 2>/dev/null | head -1 || true)
  [ -n "$first" ] || continue

  started=$(printf '%s' "$first" | jq -r '.t')
  cwd=$(printf '%s' "$first" | jq -r '.cwd')
  if [[ "$started" > "$UNTIL" ]]; then continue; fi
  [ -d "$cwd" ] || continue

  # Collapse worktrees back onto the main checkout so .worktrees/<branch>
  # sessions land in the same bucket as the repository they belong to.
  common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
  repo=${common%/.git}
  [ -d "$repo" ] || continue

  slug=$(printf '%s' "$repo" | awk -F/ '{ print ($(NF-1) == "" ? $NF : $(NF-1) "-" $NF) }')
  printf '%s\t%s\n' "$slug" "$repo" >> "$OUT/.repos"
  printf '%s\n' "$session" >> "$OUT/.sessions-$slug"
done

[ -f "$OUT/.repos" ] || { echo "no sessions found between $SINCE and $UNTIL" >&2; exit 1; }
sort -u "$OUT/.repos" > "$OUT/.repos.uniq"

while IFS=$'\t' read -r slug repo; do
  prompts="$OUT/prompts/$slug.tsv"
  gitlog="$OUT/gitlog/$slug.txt"

  # A user turn is a plain string, or a content array whose text parts are the
  # typed message. Everything else (tool results, hook output) is skipped, and
  # the injected reminder blocks are dropped afterwards.
  #
  # Sessions are counted here rather than upstream: a session may start before
  # --since and still contribute nothing to the window, so only the ones that
  # yield at least one prompt count as work done in the period.
  : > "$prompts"
  sessions=0
  while IFS= read -r session; do
    jq -rc --arg since "$SINCE" --arg until "$UNTIL" '
      select(.type == "user" and .isMeta != true)
      | select(.timestamp[0:10] >= $since and .timestamp[0:10] <= $until)
      | .message.content as $c
      | (if ($c | type) == "string" then $c
         elif ($c | type) == "array" then ($c | map(select(.type == "text") | .text) | join(" "))
         else empty end) as $t
      | select($t != null and ($t | length) > 0)
      | [.timestamp[0:10], ($t | gsub("\n"; " ") | .[0:400])]
      | @tsv
    ' "$session" 2>/dev/null |
      grep -v -e '<system-reminder>' -e '<local-command-stdout>' -e 'tool_use_id' \
              -e 'Caveat: The messages below' |
      sed -e 's|<command-message>[^<]*</command-message> *||g' \
          -e 's|</*command-\(name\|args\)>||g' > "$OUT/.turn" || true
    if [ -s "$OUT/.turn" ]; then
      cat "$OUT/.turn" >> "$prompts"
      sessions=$((sessions + 1))
    fi
  done < "$OUT/.sessions-$slug"
  rm -f "$OUT/.turn"

  # %cd, not %ad: --since/--until select on commit date, so printing the author
  # date lets a rebased or cherry-picked commit report a date outside the window
  # and inflate the active-day count.
  git -C "$repo" log --all --since="$SINCE" --until="$UNTIL 23:59:59" \
      --date=short --pretty=$'%cd\t%an\t%s' > "$gitlog" 2>/dev/null || : > "$gitlog"

  n_prompts=$(wc -l < "$prompts" | tr -d ' ')
  n_commits=$(wc -l < "$gitlog" | tr -d ' ')

  # A repo with neither prompts nor commits in the window was only visited, not
  # worked on. Dropping it keeps the digest about work that actually happened.
  if [ "$n_prompts" -eq 0 ] && [ "$n_commits" -eq 0 ]; then
    rm -f "$prompts" "$gitlog"
    continue
  fi

  n_mine=$(awk -F'\t' -v me="$ME" '$2 == me { n++ } END { print n + 0 }' "$gitlog")
  active=$(awk -F'\t' '!seen[$1]++ { n++ } END { print n + 0 }' "$gitlog")

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$slug" "$repo" "$n_prompts" "$n_commits" "$n_mine" "$sessions" "$active" \
    "$prompts|$gitlog" >> "$OUT/index.tsv"
done < "$OUT/.repos.uniq"

# Busiest repos first — that is the order the digest should read in.
sort -t$'\t' -k3,3nr -o "$OUT/index.tsv" "$OUT/index.tsv"
rm -f "$OUT/.repos" "$OUT/.repos.uniq" "$OUT"/.sessions-*

{
  echo "window: $SINCE .. $UNTIL"
  echo "repos: $(wc -l < "$OUT/index.tsv" | tr -d ' ')"
  awk -F'\t' '{ p += $3; c += $4; m += $5; s += $6 }
    END { printf "prompts: %d\ncommits: %d\ncommits by me: %d\nsessions: %d\n", p, c, m, s }' "$OUT/index.tsv"
  echo "active days: $(cat "$OUT"/gitlog/*.txt 2>/dev/null | awk -F'\t' '!seen[$1]++ { n++ } END { print n + 0 }')"
} > "$OUT/summary.txt"

cat "$OUT/summary.txt" >&2
echo "$OUT"
