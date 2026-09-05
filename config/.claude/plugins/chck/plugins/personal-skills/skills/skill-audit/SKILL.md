---
name: skill-audit
description: Find which installed skills, commands, subagents and plugins are never used, and retire them so their descriptions stop costing prompt tokens in every session. Use when the user says "skillの棚卸し", "使ってないskillを消したい", "トークンを節約したい", "skill audit", "プラグインを整理したい", or asks which of their skills are actually being used.
---

# Skill Audit

Every installed skill, slash command and subagent puts its `description` into the prompt
of every session, whether or not it is ever invoked. A skill nobody calls is not free — it is a
standing charge. This skill measures which ones are earning it.

The measurement is a script. The judgement is not: a count says a row was never invoked,
never why, and the difference decides whether removing it is a cleanup or a mistake.

There are three outcomes, not two — keep, hide, remove. Hiding (step 5) keeps a skill
working while dropping it from the model's listing, which fits every skill the user
invokes by name.

## Steps

1. **Collect.** Resolve `scripts/collect.sh` against this skill's base directory, printed
   when the skill loads:

   ```bash
   bash <skill-base-dir>/scripts/collect.sh [--min-age 30] [--all] [--no-git] [--repo <dir>]
   ```

   Takes about 15 seconds. It reads the transcripts directly — there is no index and
   nothing to refresh.

2. **Read the TSV on stdout.** Columns:

   ```
   verdict  name  source  uses  slash  last_used  installed  age_days  desc_chars  desc_tokens  path
   ```

   `verdict` is a first pass over `uses + slash` and `age_days`, nothing more:

   - `drop` — never invoked, installed long enough ago to judge
   - `review` — invoked once or twice
   - `keep` — in real use. Withheld from stdout unless `--all`
   - `new` — installed within `--min-age`; too early to have a track record
   - `unknown-age` — the install date was not found in the dotfiles history

   `desc_tokens` is the per-session cost of the row, and rows are sorted by it. It is an
   estimate from description length — ASCII at four characters to the token, CJK at one —
   not a tokenizer run, so treat it as a magnitude rather than a figure. A Japanese
   description costs far more per character than its length suggests: 209 characters of
   Japanese runs about 191 tokens where the same length of English runs about 52.

   A file with no frontmatter `description` is never loaded into the prompt and is
   skipped rather than reported as free — the count of those goes to stderr.

3. **Read the rollup on stderr.** Plugins are enabled and disabled whole, so a single
   unused skill inside a plugin is not actionable on its own. The rollup groups the
   `drop` rows by the unit you would actually turn off and marks `(all)` where every row
   in that unit is unused.

   The rollup also converts to a monthly figure, multiplying by the interactive sessions
   in the last 30 days (from `history.jsonl`). Automated and subagent sessions are not
   counted, so it errs low.

   Report the saving as **cached input tokens**, not as full-price input. The system
   prompt is prompt-cached, so on any repeat session these descriptions are cache reads.
   The number is real but it is the cheap kind of token, and saying so keeps the estimate
   honest.

   **Only propose disabling a plugin marked `(all)`.** A plugin showing `17/19 unused`
   has two rows carrying it — `claude-mem` is mostly unused *skills* around a memory
   system that runs on every session. Turning it off to reclaim the skills breaks the
   part that works.

4. **Establish why each candidate was installed**, before proposing anything. A row
   installed on purpose for a rare job is not the same as a row that arrived inside a
   bundle and never fired.

   ```bash
   git -C <dotfiles> log --format='%ad %h %s' --date=short -S '<name>' -- \
     config/apm/apm.yml config/.claude/settings.json
   ```

   A commit message naming the row as the reason for the change (`install X marketplace
   for <feature>`) means it was wanted. Ask rather than propose. A row that appears in a
   commit adding twelve others at once is a bundle passenger.

5. **Consider hiding before removing.** Removal is not the only lever. The
   `skillOverrides` setting controls how each skill is listed, so a skill can stay fully
   available while costing the model nothing:

   ```json
   "skillOverrides": { "<skill>": "on" | "name-only" | "user-invocable-only" | "off" }
   ```

   | value | listed to the model | `/name` |
   |---|---|---|
   | absent / `on` | name + description | works |
   | `name-only` | name only | works |
   | `user-invocable-only` | not listed | works |
   | `off` | not listed | fails |

   `user-invocable-only` is the useful one, and it fits the pattern the counts keep
   showing: a skill that gets used is usually one the user types by name, and a skill
   typed by name does not need advertising. It saves the whole row.

   Decide by asking what the description is *for*. Where it carries trigger phrases the
   user actually relies on — `gcal-scheduling` on 「予定を調整して」,
   `review-pr-comments` on 「#123のレビューに対応」, both confirmed in the transcripts —
   hiding removes function, not waste. Where the skill is a chore invoked by name, hiding
   costs nothing.

   Two limits:

   - **It does not work on plugin skills.** The resolver returns `on` before reading the
     setting when a skill's source is a plugin, so a plugin's unused skills cannot be
     trimmed this way. Nor can its manifest: `plugin.json`'s `skills` array *adds to* the
     default `skills/` scan rather than replacing it, and an update would revert an edit
     to the installed copy. For a plugin it is all or nothing.
   - **It is a Claude Code setting only.** apm also deploys to `~/.agents/skills/`, where
     the other agents read; those copies still advertise in full.

6. **Report, then ask.** Group by unit, largest `desc_tokens` first. For each: what it is,
   how long unused, what it costs, whether hiding would do instead of removing, and —
   where you found one — the reason it was installed. Recommend, do not act. The call is
   the user's.

7. **On approval, apply it.** Use the `git-wt` skill and change the source, never the
   deployed copy.

   To hide rather than remove, add the entry to `skillOverrides` in
   `config/.claude/settings.json`. To remove:

   - apm skill → remove its line from `config/apm/apm.yml`, then `apm install -g`
   - plugin → remove its `"<plugin>@<marketplace>": true` line from
     `config/.claude/settings.json`, then `claude plugins uninstall <plugin>@<marketplace>`
   - a marketplace with nothing left enabled → also drop its `extraKnownMarketplaces`
     entry and run `claude plugins marketplace remove <marketplace>`

   Then verify what actually left, rather than trusting an exit code:

   ```bash
   ls ~/.config/claude/skills/ ~/.agents/skills/
   git -C <dotfiles> status --porcelain     # settings.json is a tracked symlink
   ```

   A `skillOverrides` change leaves the files in place, so check its effect instead of
   its presence. `claude -p` starts a new process and rebuilds the prompt from current
   settings, so there is no need to wait for the next interactive session:

   ```bash
   claude -p --model claude-haiku-4-5-20251001 \
     "Answer with exactly two lines, yes or no: does your available-skills list contain \
      an entry named exactly '<hidden>'? and '<a skill left listed>'?"
   claude -p --model claude-haiku-4-5-20251001 \
     "/<hidden> Do not execute anything. Reply with the first heading of the skill \
      instructions you just received, or UNKNOWN-COMMAND if no skill loaded."
   ```

   Expect `no` then `yes`, then the skill's heading. Always include a skill left listed
   as a control — otherwise a listing that failed to load reads as a success.

   `apm install -g` cleans most stale files but has been seen to leave a skill directory
   behind in `~/.config/claude/skills/`. Check, and remove it by hand if so.

## What the numbers do not say

- **`uses` counts the Skill and Task tools; `slash` counts typed commands.** A skill can
  be reached both ways, and either column alone under-reports it. `commit` reads 3 / 32.
- **A skill can be used without being invoked.** An instruction file that names a skill
  drives it far harder than any description does: `git-wt` is the most-used row here and
  it is mandated by `AGENTS.md`. Removing a mandated row breaks the instruction that
  points at it, so grep the instruction files before proposing one:

  ```bash
  rg -l '<name>' <dotfiles>/config/AGENTS.md <dotfiles>/config/*/AGENTS.md <dotfiles>/CLAUDE.md
  ```
- **Zero is expected for the seasonal.** A release skill used at each release, an
  onboarding skill used per new repository — the count is low because the event is rare,
  not because the skill failed.
- **Only enabled plugins are inventoried.** A marketplace clone holds everything its
  publisher ships; what is not enabled costs nothing and is not a candidate.
- **Built-in skills and commands are invisible here.** They ship inside the CLI, so they
  never appear as a row — but they are the reason a row can be redundant. Before keeping
  something, check whether a built-in already does it.

## Cadence

Monthly is the natural interval: long enough for a new skill to have a track record,
short enough that a bundle installed on a whim does not sit for a year. Nothing schedules
this — run it when the prompt feels heavy, or after installing a batch.

## Notes

- Needs `rg` and `jq`.
- `--no-git` skips install dating. Faster, but every verdict degrades to `unknown-age`,
  which removes the one guard against deleting something installed last week.
- `--repo` points at the dotfiles checkout. It defaults to `$DOTFILES_DIR`, then to the
  ghq path; pass it explicitly if neither resolves.
