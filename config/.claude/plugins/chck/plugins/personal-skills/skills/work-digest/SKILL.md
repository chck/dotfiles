---
name: work-digest
description: Build a progress digest for the biweekly team meeting from local Claude Code session logs and git history across every repository worked on. Use when the user says "定例のまとめ", "進捗定例の資料", "この2週間の作業をまとめて", "作業サマリを作って", "work digest", or asks what they have been working on over a recent period.
---

# Work Digest

Reconstruct what was worked on over a period by pairing **what was asked** (Claude Code
session logs) with **what shipped** (git log), one repository at a time, then synthesise
across repositories.

**Scope is everything chck did, never the repository the session happens to run in.** Run the
skill from any directory; the digest still covers every repository, plus the tools below.
Digesting only the current repo is the wrong output.

Default window is the last 14 days, matching the biweekly meeting cadence. The user may
override it (`/work-digest 1ヶ月`, `--since 2026-07-27`).

## Steps

1. **Collect** — run the bundled script. Resolve `scripts/collect.sh` against this
   skill's base directory, which is printed when the skill loads:

   ```bash
   bash <skill-base-dir>/scripts/collect.sh --since <YYYY-MM-DD> [--until <YYYY-MM-DD>]
   ```

   It prints the output directory on its last stdout line and the totals on stderr.
   Takes ~30s for a two-week window. Never hand-roll this extraction — see "Why a script".

2. **Read `index.tsv` and `summary.txt`** — nothing else. Columns of `index.tsv`:

   ```
   slug  repo_path  prompts  commits  commits_by_me  sessions  active_days  prompts_file|gitlog_file
   ```

   Rows are ordered busiest-first. Do not open the per-repo files yourself; they are
   large and they are the subagents' input.

3. **Fan out one subagent per repository**, all in a single message so they run
   concurrently. Group repositories with fewer than ~40 prompts together so the fleet
   stays at six agents or fewer. Each prompt must:

   - name the repository, the window, and the two absolute file paths
   - say the two files are the **only** input and that repo source must not be explored
   - ask for the report in Japanese, shaped to drop straight into the repo block of the page
     (see step 5): a headline naming what the repo's work achieved this period, a one- or
     two-sentence lede, 3-6 bullets each opening with a bold aspect label (取り込み, 指標の定義,
     コスト, ドキュメント ...) followed by the concrete deliverables and PR numbers, the merged
     PR count, and an 進行中 line with the open PR numbers
   - require that inferences are marked 推定 and that PR numbers, file names, and features
     are quoted from the data rather than guessed
   - state that its final message *is* the report and gets relayed to a human

   Do not read the agents' `output_file` — that is the full transcript and it will
   overflow context. Wait for the completion notifications.

4. **Collect outside git** — work that leaves no commit lives in other tools. Query each for
   the window, in parallel, and skip any that is not connected rather than failing:

   - GitHub across all repositories: `gh search prs --author @me`, `gh search issues
     --involves @me`, and reviews given (`gh search prs --reviewed-by @me`)
   - Slack (own posts and threads), Notion (pages edited), Linear (issues touched),
     Google Calendar (meetings held)

   Keep these as リポジトリ外の作業, grouped by theme, with titles and dates only.

5. **Synthesise by repository.** The digest is organised around repositories, not themes: a
   reader finds a repo and sees what moved in it. Build the page from these parts, in order:

   - **Masthead** — period and one line of scope
   - **Metrics strip** — merged PRs split into 業務 and 環境, repository count, open PRs
   - **One block per repository**, busiest first. The repo with the most PRs is marked 主軸.
     Repositories that share a purpose (a family of skill repos, say) may share one block,
     with a bullet per repo. Each block holds the slug and PR count, the headline, the lede,
     the labelled bullets, and an 進行中 box listing open PR numbers
   - **リポジトリ外の作業** — one block after the repos, grouped by theme, from step 4
   - **Footer** — what the digest leaves out (personal repositories, manuscripts) so the
     omission is visible

   Cross-cutting themes are not a section. Mention one only inside a block when it explains
   why that repo moved, and give the full list in chat if the user wants it. Open items live
   in each block's 進行中 box; sort them into 次 (picked up next) and 保留 (parked) only when
   the window ends with a clear split.

6. **Publish an Artifact, always** — load `artifact-design` first, write the page to a file named
   `work-digest-<until-date>.html`, then publish it. A new file path per period means each
   meeting keeps its own URL and the previous digest stays readable. Set the `<title>` to
   the period, e.g. 「進捗ダイジェスト 8/27–9/10」.

7. **Submit** — when the user asks to submit, find the Notion page titled `Debriefing` with
   Notion search and add the digest there. The page URL contains a company domain and is not
   stored in this repository; if search does not find it, ask the user for the link.

8. **Answer in chat** with the spoken version: the totals line, one line per repo
   (busiest first), and the open items worth raising. Put the Artifact URL first.

## Reading the numbers honestly

- `commits` counts **all branches and all authors** — teammates' work is included. Use
  `commits_by_me` when the question is about personal output, and say which one is being
  quoted.
- Some repos commit on a timer (`obsidian-vault` backs itself up). Check whether one author
  and one subject dominate before reporting a commit count as effort.
- Sessions started before `--since` are included when they have prompts inside the window,
  so `sessions` means "sessions that did work in this period", not "sessions opened".
- A repository with prompts but zero commits is real signal: design discussion, review,
  investigation, or work that landed elsewhere. Report it as such rather than dropping it.
- Much of the work leaves no commit at all — calendar wrangling, spreadsheet analysis,
  Slack threads, Notion pages. It shows up in the prompts only. Keep it, labelled as
  リポジトリ外の作業.

## Why a script

The extraction is fiddly enough that writing it inline gets it wrong:

- Subagent transcripts under `*/subagents/` repeat the parent session's work and must be
  excluded, or every prompt is counted twice.
- A user turn is either a plain string or a content array; tool results, hook output, and
  injected `<system-reminder>` blocks share the same `type: "user"` envelope.
- Truncation has to happen in `jq` (codepoint-based). `cut -c` and BSD `awk`'s `substr`
  count bytes and will slice a Japanese prompt mid-character.
- Repositories are identified from each session's `cwd` via `git rev-parse
  --git-common-dir`, not by decoding the mangled project directory name. That also folds
  `.worktrees/<branch>` sessions back into the repository they belong to.

## Notes

- Session logs live in `~/.config/claude/projects`, overridable with `CLAUDE_PROJECTS_DIR`.
  `~/.claude/projects` holds an older archive and is not read.
- This skill lives in a public repository. Never write an organisation name, a private
  repository name, or a workspace URL into it. The Artifact is private and may name them;
  anything posted to a public place may not.
- Prompts are the user's own words and can contain anything personal. Summarise topics at a
  high level for anything outside work; never quote it into the digest.
- If `collect.sh` reports zero repos, the window is wrong before the logs are missing —
  check the dates first.
