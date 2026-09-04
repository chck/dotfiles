#!/usr/bin/env bash
# Find the Claude Code sessions that mention a string, across every project.
#
# Usage: search.sh <query> [options]
#
#   --regex            Treat <query> as a regular expression (default: literal).
#   --since <date>     Only sessions started on or after this ISO date.
#   --until <date>     Only sessions started on or before this ISO date.
#   --scope <dir>      Only sessions whose cwd is inside <dir>.
#   --limit <n>        Max rows to print. Default 20, 0 for no limit.
#   --include-noise    Do not apply the exclusion patterns in exclude.conf.
#
# Writes a header-once TSV to stdout:
#
#   kind  session  project  started  hits  direct  resume  file  snippet
#
#   kind     direct   the string appears in a user or assistant message
#            indirect it only appears in tool output, hook output, a memory
#                     observer log, or a subagent transcript
#   resume   the session id to pass to `claude --resume`; for a subagent
#            transcript this is the parent session, which is the resumable one
#
# Totals go to stderr. There is no index to build or refresh: the search reads
# the transcripts directly, so it cannot go stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDE_CONF="$SCRIPT_DIR/../exclude.conf"

QUERY=""
MODE="fixed"
SINCE=""
UNTIL=""
SCOPE=""
LIMIT=20
INCLUDE_NOISE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --regex)         MODE="regex"; shift ;;
    --since)         SINCE="$2"; shift 2 ;;
    --until)         UNTIL="$2"; shift 2 ;;
    --scope)         SCOPE="$2"; shift 2 ;;
    --limit)         LIMIT="$2"; shift 2 ;;
    --include-noise) INCLUDE_NOISE=1; shift ;;
    --) shift; QUERY="${QUERY:-$1}"; shift || true ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *)  if [ -z "$QUERY" ]; then QUERY="$1"; else echo "unexpected argument: $1" >&2; exit 2; fi; shift ;;
  esac
done

[ -n "$QUERY" ] || { echo "usage: search.sh <query> [--regex] [--since D] [--until D] [--scope DIR] [--limit N] [--include-noise]" >&2; exit 2; }
command -v rg >/dev/null || { echo "ripgrep (rg) is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# Claude Code has used both locations; a machine can hold sessions in either.
ROOTS=()
if [ -n "${CLAUDE_PROJECTS_DIRS:-}" ]; then
  IFS=: read -r -a ROOTS <<< "$CLAUDE_PROJECTS_DIRS"
else
  for d in "$HOME/.config/claude/projects" "$HOME/.claude/projects"; do
    [ -d "$d" ] && ROOTS+=("$d")
  done
fi
[ ${#ROOTS[@]} -gt 0 ] || { echo "no session logs found" >&2; exit 1; }

[ -n "$SCOPE" ] && SCOPE="$(cd "$SCOPE" 2>/dev/null && pwd || echo "$SCOPE")"

# Phase 1: narrow to candidate files with a raw text scan. Matching the escaped
# JSON as plain text is what makes this survive schema changes.
RG_MODE=(-F)
[ "$MODE" = "regex" ] && RG_MODE=(-e)

CANDIDATES=$(rg -l --no-messages "${RG_MODE[@]}" "$QUERY" --glob '*.jsonl' "${ROOTS[@]}" 2>/dev/null || true)
[ -n "$CANDIDATES" ] || { echo "no session mentions this" >&2; printf 'kind\tsession\tproject\tstarted\thits\tdirect\tresume\tfile\tsnippet\n'; exit 0; }

EXCLUDED=0
if [ "$INCLUDE_NOISE" -eq 0 ] && [ -f "$EXCLUDE_CONF" ]; then
  PATTERNS=$(grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$EXCLUDE_CONF" || true)
  if [ -n "$PATTERNS" ]; then
    KEPT=$(printf '%s\n' "$CANDIDATES" | rg -v -f <(printf '%s\n' "$PATTERNS") || true)
    EXCLUDED=$(( $(printf '%s\n' "$CANDIDATES" | grep -c . || true) - $(printf '%s\n' "$KEPT" | grep -c . || true) ))
    CANDIDATES="$KEPT"
  fi
fi

# Phase 2: classify the matching lines of each candidate.
#
# A hit is "direct" only when the string is in what a human wrote or what the
# assistant said back. Tool results, hook output, injected reminders and
# subagent transcripts are the same string travelling as machinery, so they are
# reported separately instead of being dropped.
JQ_CLASSIFY='
def blocks:
  (.message.content? // null) as $c
  | if ($c | type) == "string" then [{type: "text", text: $c}]
    elif ($c | type) == "array" then $c
    else [] end;

def humantext:
  [ blocks[]
    | select(type == "object")
    | select(.type == "text" or .type == "thinking")
    | (.text // .thinking // "")
    | select(type == "string")
    | select(contains("<system-reminder>") | not)
  ] | join("\n");

(.timestamp // .created_at // "") as $ts
| (.type // .role // "?") as $role
| (if ($role == "user" or $role == "assistant") and (.isMeta != true)
   then humantext else "" end) as $human
| (if $mode == "regex" then ($human | test($q)) else ($human | contains($q)) end) as $direct
| (if $direct then $human else (. | tostring) end) as $src
| ($src | gsub("[[:space:]]+"; " ")) as $flat
| (if $mode == "regex" then 0 else (($flat | index($q)) // 0) end) as $i
| (if $i > 100 then $i - 100 else 0 end) as $from
| ($flat[$from : $from + 300]) as $snip
| [(if $direct then "direct" else "indirect" end), $ts, ($snip | gsub("\t"; " "))]
| @tsv
'

ROWS=$(mktemp)
SCANNED=0

while IFS= read -r f; do
  [ -n "$f" ] || continue
  SCANNED=$((SCANNED + 1))

  # A subagent transcript repeats its parent's work and cannot be resumed on
  # its own, so it is always indirect and points at the parent session.
  session=$(basename "$f" .jsonl)
  resume="$session"
  forced_kind=""
  case "$f" in
    */subagents/*)
      parent_dir=$(dirname "$(dirname "$f")")
      resume=$(basename "$parent_dir")
      forced_kind="indirect"
      ;;
  esac

  project=$(basename "$(dirname "$f")")
  [ "$project" = "subagents" ] && project=$(basename "$(dirname "$(dirname "$(dirname "$f")")")")

  meta=$(jq -rc 'select(.timestamp or .cwd) | {t: (.timestamp // ""), c: (.cwd // "")}' "$f" 2>/dev/null | head -20 || true)
  started=$(printf '%s\n' "$meta" | jq -rs 'map(.t) | map(select(. != "")) | first // ""' 2>/dev/null || echo "")
  cwd=$(printf '%s\n' "$meta" | jq -rs 'map(.c) | map(select(. != "")) | first // ""' 2>/dev/null || echo "")
  started="${started:0:19}"
  started="${started/T/ }"

  [ -n "$SINCE" ] && [ -n "$started" ] && [[ "${started:0:10}" < "$SINCE" ]] && continue
  [ -n "$UNTIL" ] && [ -n "$started" ] && [[ "${started:0:10}" > "$UNTIL" ]] && continue
  if [ -n "$SCOPE" ]; then
    case "$cwd" in "$SCOPE"|"$SCOPE"/*) ;; *) continue ;; esac
  fi

  # jq can only fail here if the schema moved under us; the raw grep line is
  # still a true hit, so report it as unknown rather than losing the session.
  classified=$(rg --no-messages "${RG_MODE[@]}" "$QUERY" "$f" 2>/dev/null \
    | jq -r --arg q "$QUERY" --arg mode "$MODE" "$JQ_CLASSIFY" 2>/dev/null || true)

  if [ -z "$classified" ]; then
    hits=$(rg -c --no-messages "${RG_MODE[@]}" "$QUERY" "$f" 2>/dev/null || echo 0)
    snippet=$(rg -m1 --no-messages -o "${RG_MODE[@]}" "$QUERY" "$f" 2>/dev/null || true)
    printf 'unknown\t%s\t%s\t%s\t%s\t0\t%s\t%s\t%s\n' \
      "$session" "$project" "$started" "$hits" "$resume" "$f" "${snippet:-（本文抽出に失敗）}" >> "$ROWS"
    continue
  fi

  hits=$(printf '%s\n' "$classified" | grep -c . || true)
  direct=$(printf '%s\n' "$classified" | grep -c '^direct' || true)
  kind="indirect"
  [ "$direct" -gt 0 ] && kind="direct"
  [ -n "$forced_kind" ] && kind="$forced_kind"

  # Show the first direct hit when there is one; it is the sentence a human wrote.
  line=$(printf '%s\n' "$classified" | grep -m1 '^direct' || printf '%s\n' "$classified" | head -1)
  ts=$(printf '%s' "$line" | cut -f2)
  snippet=$(printf '%s' "$line" | cut -f3-)
  [ -n "$started" ] || { started="${ts:0:19}"; started="${started/T/ }"; }

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$kind" "$session" "$project" "$started" "$hits" "$direct" "$resume" "$f" "$snippet" >> "$ROWS"
done <<< "$CANDIDATES"

printf 'kind\tsession\tproject\tstarted\thits\tdirect\tresume\tfile\tsnippet\n'
if [ -s "$ROWS" ]; then
  if [ "$LIMIT" -gt 0 ]; then
    sort -t$'\t' -k1,1 -k4,4r "$ROWS" | head -n "$LIMIT"
  else
    sort -t$'\t' -k1,1 -k4,4r "$ROWS"
  fi
fi

n_direct=$(grep -c '^direct' "$ROWS" || true)
n_total=$(grep -c . "$ROWS" || true)
shown=$n_total
[ "$LIMIT" -gt 0 ] && [ "$n_total" -gt "$LIMIT" ] && shown=$LIMIT
echo "scanned $SCANNED candidate files, $n_total sessions matched ($n_direct direct), $EXCLUDED excluded as noise, $shown shown" >&2
[ "$shown" -lt "$n_total" ] && echo "note: $((n_total - shown)) rows hidden by --limit $LIMIT" >&2

rm -f "$ROWS"
