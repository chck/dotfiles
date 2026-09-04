---
name: session-grep
description: Find which past Claude Code sessions mentioned a string — a URL, a ticket ID, an error message, a function name — by searching every session transcript on this machine. Use when the user says "〜に言及したセッションを探して", "いつ〜の話をした", "過去のセッションを検索", "どのセッションでやったっけ", "session grep", or asks which conversation a link, ID, or phrase came up in.
---

# Session Grep

`/resume` only matches a session's name, title, summary and first prompt, and there is no
official way to search transcript bodies. This skill does that: it scans every session
JSONL under `~/.config/claude/projects` and `~/.claude/projects` for a string and reports
which sessions mentioned it.

There is no index. The search reads the transcripts directly every time, so nothing can go
stale and nothing needs rebuilding.

## Steps

1. **Run the bundled script.** Resolve `scripts/search.sh` against this skill's base
   directory, printed when the skill loads:

   ```bash
   bash <skill-base-dir>/scripts/search.sh "<query>" [--regex] [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--scope <dir>] [--limit N] [--include-noise]
   ```

   The query is a literal string by default. Use the longest stable fragment: for a URL,
   the page ID alone (`a1b2c3d4e5f60718293a4b5c6d7e8f90`) beats the full URL, because the
   same page gets linked with different prefixes, anchors and query strings.

   Pass `--scope $(pwd)` when the user scopes the question to the current directory
   ("配下の", "このリポジトリで"). Sessions are matched on their `cwd`, not on the project
   directory name.

2. **Read the TSV on stdout.** Columns:

   ```
   kind  session  project  started  hits  direct  resume  file  snippet
   ```

   `kind` is the whole point of the output:

   - `direct` — the string is in something a human wrote or the assistant said. These are
     the sessions the user is asking about.
   - `indirect` — it only appears in tool output, hook output, an injected reminder, a
     memory observer log, or a subagent transcript. The string is travelling as machinery,
     usually because it was mentioned in some *other* session that a digest or a search
     later scraped. Report these separately, never mixed in with the direct hits.
   - `unknown` — the raw text matched but the JSONL could not be parsed (the transcript
     format changes between Claude Code versions). Still a real hit; say so plainly.

   Totals go to stderr — read them, and pass on anything they say about hidden rows.

3. **Format the answer** in Japanese, direct hits first:

   ```
   ## 直接言及
   1. my-repo / 0a1b2c3d (2026-08-21 16:08, 37件中2件が直接)
      「<マッチした発言の抜粋>…」
      claude --resume 0a1b2c3d-1111-2222-3333-444455556666

   ## 間接ヒット
   - other-repo / agent-9f8e7d6c（work-digest のサブエージェント経由）
     親セッション: claude --resume 5a4b3c2d-...
   ```

   Use the `resume` column, not `session`, for the resume command: a subagent transcript
   cannot be resumed, so `resume` already points at its parent. Timestamps are UTC in the
   transcripts — convert to JST when showing them.

4. **Only if the user needs more context**, dig into at most three transcripts, and never
   by reading them whole — a session JSONL runs to megabytes and will blow up the context.
   Pull just the neighbourhood of the hit:

   ```bash
   rg -n -F "<query>" <file> | head -3           # line numbers of the hits
   sed -n '<line-20>,<line+5>p' <file> | jq -r '.message.content? // empty | if type=="string" then . else [.[]?.text // empty] | join(" ") end' | cut -c1-400
   ```

## When nothing comes back

Say so, then widen deliberately — one change at a time, reporting what you changed:

- shorten the query to its most distinctive fragment
- `--regex` for a pattern (`ABC-[0-9a-f]{8,}`)
- `--include-noise` to search the excluded logs too
- drop `--since` / `--scope` if either was set

## Noise exclusions

`exclude.conf` next to this file lists path patterns dropped before classification — logs
*about* sessions rather than sessions, which otherwise crowd out the answer. When a new
source of that kind shows up, add a line to `exclude.conf` rather than filtering it by hand
each time; that is the difference between a fix and a habit.

## Notes

- The script needs `rg` and `jq`.
- `CLAUDE_PROJECTS_DIRS` overrides the searched roots (colon-separated).
- The current session's own transcript will match your own query. It is a genuine hit, but
  point it out as the session you are in rather than presenting it as a find.
