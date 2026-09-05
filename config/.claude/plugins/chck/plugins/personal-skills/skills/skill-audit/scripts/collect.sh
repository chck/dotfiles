#!/usr/bin/env bash
# Inventory every loaded skill and subagent, with how often each was actually used.
#
# Usage: collect.sh [options]
#
#   --min-age <n>   Rows younger than <n> days are reported as `new`, never as a
#                   deletion candidate. Default 30.
#   --repo <dir>    dotfiles checkout used to date installs. Default $DOTFILES_DIR,
#                   else ~/Works/github.com/chck/dotfiles.
#   --no-git        Skip install dating. Much faster; `installed` and `age_days`
#                   come back empty and every verdict is `unknown-age`.
#   --all           Print every row. Default prints only rows worth a decision,
#                   with the `keep` count summarised on stderr.
#
# Writes a header-once TSV to stdout:
#
#   verdict  name  source  uses  slash  last_used  installed  age_days  desc_chars  path
#
#   verdict     drop         never used, old enough to judge
#               review       used once or twice
#               keep         in real use
#               new          installed within --min-age; no verdict yet
#               unknown-age  --no-git, or the install date could not be found
#   uses        Skill and Task invocations across every transcript. A qualified
#               name (`personal-skills:git-wt`) counts towards its bare name, so
#               the same skill reached two ways is one number
#   slash       times typed as a slash command (history.jsonl)
#   last_used   date of the most recent invocation, read from the transcript
#               record or the history entry, whichever is later
#   desc_chars  size of the frontmatter description. This is what a row costs:
#               every description is loaded into every session's prompt, whether
#               or not the thing is ever invoked
#
# Only *enabled* plugins are inventoried. A marketplace clone holds every plugin
# its publisher ships; the ones not enabled in settings.json cost nothing and are
# not candidates for anything.
#
# Counts and sources go to stderr. Nothing is cached; transcripts are read
# directly on every run.
#
# A count is evidence, not a verdict. Read `git log` for why a row was installed
# before proposing its removal — something installed deliberately for a rare job
# is not the same as something that arrived in a bundle and never fired.

set -euo pipefail

MIN_AGE=30
REPO="${DOTFILES_DIR:-$HOME/Works/github.com/chck/dotfiles}"
USE_GIT=1
SHOW_ALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --min-age) MIN_AGE="$2"; shift 2 ;;
    --repo)    REPO="$2"; shift 2 ;;
    --no-git)  USE_GIT=0; shift ;;
    --all)     SHOW_ALL=1; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//;$d'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

command -v rg >/dev/null || { echo "ripgrep (rg) is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------- usage counts

ROOTS=()
for d in "$HOME/.config/claude/projects" "$HOME/.claude/projects"; do
  [ -d "$d" ] && ROOTS+=("$d")
done
[ ${#ROOTS[@]} -gt 0 ] || { echo "no transcript directory found" >&2; exit 1; }

HISTORY=""
for f in "$HOME/.config/claude/history.jsonl" "$HOME/.claude/history.jsonl"; do
  [ -f "$f" ] && HISTORY="$f" && break
done

# `iso-timestamp<TAB>name`, one line per invocation, plugin prefix stripped.
# The timestamp comes from the transcript record itself, so it is the real
# invocation time rather than a file's mtime.
rg -I --no-heading -N '"(skill|subagent_type)"[[:space:]]*:[[:space:]]*"[^"]+"' "${ROOTS[@]}" 2>/dev/null \
  | jq -R -r 'fromjson? // empty
              | (.timestamp // "") as $t
              | [.. | objects | (.skill? // .subagent_type? // empty)][]
              | "\($t)\t\(.)"' 2>/dev/null \
  | awk -F'\t' 'NF==2 {sub(/^.*:/, "", $2); print substr($1,1,10) "\t" $2}' > "$TMP/tool_hits" || true

# Slash commands carry their own timestamp in history.jsonl (epoch ms).
: > "$TMP/slash_hits"
if [ -n "$HISTORY" ]; then
  jq -R -r 'fromjson? // empty
            | select(.display | type == "string" and startswith("/"))
            | [((.timestamp // 0) / 1000 | floor | todate | .[0:10]),
               (.display | ltrimstr("/") | split(" ")[0] | sub("^[^:]*:"; ""))]
            | @tsv' "$HISTORY" 2>/dev/null > "$TMP/slash_hits" || true
fi

count_by_name() { awk -F'\t' '{n[$2]++} END {for (k in n) print k "\t" n[k]}' "$1" | sort; }
count_by_name "$TMP/tool_hits"  > "$TMP/uses"
count_by_name "$TMP/slash_hits" > "$TMP/slash"

cat "$TMP/tool_hits" "$TMP/slash_hits" \
  | awk -F'\t' '$1 != "" && $1 != "1970-01-01" {if ($1 > d[$2]) d[$2] = $1}
                 END {for (k in d) print k "\t" d[k]}' | sort > "$TMP/lastuse"

lookup() { awk -F'\t' -v k="$2" '$1==k {print $2; f=1; exit} END {if (!f) print 0}' "$1"; }

# ------------------------------------------------------------------- inventory

: > "$TMP/rows"
emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$TMP/rows"; }

# Skills apm and the personal plugin deploy. Both target directories hold the
# same skill, so the name deduplicates them into one row.
for base in "$HOME/.config/claude/skills" "$HOME/.agents/skills"; do
  [ -d "$base" ] || continue
  for d in "$base"/*; do
    [ -f "$d/SKILL.md" ] || continue
    emit "$(basename "$d")" "skill" "apm" "$d/SKILL.md"
  done
done

# Enabled plugins only. A plugin lives wherever its .claude-plugin/plugin.json
# declares its name, which is the marketplace root for a single-plugin repo and
# plugins/<name>/ for a bundle.
SETTINGS=""
for f in "$HOME/.config/claude/settings.json" "$HOME/.claude/settings.json"; do
  [ -f "$f" ] && SETTINGS="$f" && break
done

enabled_count=0
if [ -n "$SETTINGS" ]; then
  while IFS= read -r entry; do
    plugin="${entry%@*}"; market="${entry##*@}"
    for root in "$HOME/.claude/plugins/marketplaces/$market" "$HOME/.config/claude/plugins/marketplaces/$market"; do
      [ -d "$root" ] || continue
      while IFS= read -r manifest; do
        jq -e --arg n "$plugin" '.name == $n' "$manifest" >/dev/null 2>&1 || continue
        dir="$(dirname "$(dirname "$manifest")")"
        while IFS= read -r f; do
          emit "$(basename "$f" .md)" "agent" "plugin:$plugin" "$f"
        done < <(find "$dir" -type f -path '*/agents/*.md' 2>/dev/null)
        while IFS= read -r f; do
          emit "$(basename "$(dirname "$f")")" "skill" "plugin:$plugin" "$f"
        done < <(find "$dir" -type f -name SKILL.md 2>/dev/null)
        enabled_count=$((enabled_count + 1))
      done < <(find "$root" -type f -path '*/.claude-plugin/plugin.json' 2>/dev/null)
    done
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$SETTINGS")
fi

sort -u -t$'\t' -k1,3 "$TMP/rows" -o "$TMP/rows"

# ------------------------------------------------------------------ reporting

desc_chars() {
  awk 'NR == 1 && /^---$/ {next}
       /^description:/ {inblock = 1}
       inblock && /^[a-z_-]+:[[:space:]]/ && !/^description:/ {exit}
       /^---$/ {exit}
       inblock {n += length($0) + 1}
       END {print n + 0}' "$1"
}

MANIFESTS="config/apm/apm.yml config/.claude/settings.json"
PERSONAL="config/.claude/plugins/chck/plugins/personal-skills/skills"

# When a row entered the setup, dated from the dotfiles history. Three cases,
# because three mechanisms put a row there:
#   - an apm dependency, named in apm.yml
#   - a plugin, named in settings.json — its skills and agents arrive with it,
#     so they take the plugin's date, not their own
#   - a first-party skill, whose directory was added to the personal plugin
install_date() {
  local name="$1" source="$2" d=""
  [ "$USE_GIT" -eq 1 ] || return 0
  [ -d "$REPO/.git" ] || return 0

  case "$source" in
    plugin:*)
      # shellcheck disable=SC2086
      d=$(git -C "$REPO" log --reverse --format=%ad --date=short -S "${source#plugin:}@" -- $MANIFESTS 2>/dev/null | head -1)
      ;;
  esac
  # shellcheck disable=SC2086
  [ -n "$d" ] || d=$(git -C "$REPO" log --reverse --format=%ad --date=short -S "$name" -- $MANIFESTS 2>/dev/null | head -1)
  [ -n "$d" ] || d=$(git -C "$REPO" log --reverse --diff-filter=A --format=%ad --date=short -- "$PERSONAL/$name" 2>/dev/null | head -1)
  printf '%s' "$d"
}

now=$(date +%s)
kept=0
: > "$TMP/all_rows"

{
  while IFS=$'\t' read -r name kind source path; do
    uses=$(lookup "$TMP/uses" "$name")
    slash=$(lookup "$TMP/slash" "$name")
    total=$((uses + slash))
    last_used=$(awk -F'\t' -v k="$name" '$1==k {print $2; exit}' "$TMP/lastuse")

    installed=$(install_date "$name" "$source")
    if [ -n "$installed" ]; then
      inst=$(date -j -f %Y-%m-%d "$installed" +%s 2>/dev/null || date -d "$installed" +%s 2>/dev/null || echo 0)
      age=$(( (now - inst) / 86400 ))
    else
      age=""
    fi

    if [ -z "$age" ];            then verdict="unknown-age"
    elif [ "$age" -lt "$MIN_AGE" ]; then verdict="new"
    elif [ "$total" -eq 0 ];        then verdict="drop"
    elif [ "$total" -le 2 ];        then verdict="review"
    else                                 verdict="keep"
    fi

    row=$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
      "$verdict" "$name" "$source/$kind" "$uses" "$slash" "$last_used" \
      "$installed" "$age" "$(desc_chars "$path")" "$path")
    printf '%s\n' "$row" >> "$TMP/all_rows"

    if [ "$SHOW_ALL" -eq 0 ] && [ "$verdict" = "keep" ]; then
      kept=$((kept + 1)); continue
    fi
    printf '%s\n' "$row"
  done < "$TMP/rows"
  echo "$kept" > "$TMP/kept"
} | sort -t$'\t' -k1,1 -k9,9nr > "$TMP/out"

printf 'verdict\tname\tsource\tuses\tslash\tlast_used\tinstalled\tage_days\tdesc_chars\tpath\n'
cat "$TMP/out"

# A plugin is enabled or disabled whole, so its unused rows only mean something
# added up — and only a unit whose rows are *all* unused can simply be turned
# off. `unused/total` says which is which; the counts include the `keep` rows
# withheld from stdout.
if [ -s "$TMP/all_rows" ]; then
  {
    echo
    echo "unused, rolled up by the unit you would actually turn off:"
    awk -F'\t' '{ split($3, a, "/"); unit = a[1]; total[unit]++
                  if ($1 == "drop") { n[unit]++; chars[unit] += $9 } }
                 END { for (u in n) printf "%6d\t%-40s %2d/%-2d unused  %6d desc chars%s\n",
                                            chars[u], u, n[u], total[u], chars[u],
                                            (n[u] == total[u] ? "  (all)" : "") }' "$TMP/all_rows" \
      | sort -rn | cut -f2- | sed 's/^/  /'
    awk -F'\t' '$1 == "drop" {n++; c += $9} END {if (n) printf "  %-40s %2d rows      %6d desc chars\n", "TOTAL", n, c}' "$TMP/all_rows"
  } >&2
fi

{
  echo "transcript roots: ${ROOTS[*]}"
  echo "history: ${HISTORY:-none}"
  echo "settings: ${SETTINGS:-none}  (enabled plugins resolved: $enabled_count)"
  if [ "$USE_GIT" -eq 1 ]; then echo "install dates from: $REPO"; else echo "install dating skipped (--no-git)"; fi
  echo "rows hidden as keep: $(cat "$TMP/kept" 2>/dev/null || echo 0) (rerun with --all)"
  echo
  echo "Check why a row was installed before proposing its removal."
} >&2
