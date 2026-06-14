---
name: init-infra
description: Set up infra/AGENTS.md in the current project by copying the dotfiles infra template. Use when starting infra work in a new project, when infra/ directory exists but AGENTS.md is missing, or when the user says "infraセットアップ", "init infra", "infra/AGENTS.md を作る", or "infraのルールを追加して".
---

# Init Infra AGENTS.md

Copy the standard infra template from dotfiles to the current project's `infra/AGENTS.md`.

## Steps

1. **Read the template** from `~/Works/github.com/chck/dotfiles/config/agents/infra.md`

2. **Check project context** — ask only if not clear from conversation:
   - Does the project use a different CI/CD tool than OpenTaco? (e.g. Atlantis, GitHub Actions directly)
   - Does the project use a cloud other than GCP?

3. **Create `infra/AGENTS.md`** in the current working directory (not dotfiles):
   - Copy the template content verbatim
   - Update the Stack section if the project uses different tools (step 2)
   - Do NOT modify anything else — the rest of the rules are project-agnostic

4. **Confirm** by showing the created file path and a one-line summary of any customizations made.

## Notes

- If `infra/` directory does not exist, create it (just the directory, no other files)
- Never overwrite an existing `infra/AGENTS.md` without user confirmation
- The template lives at: `~/Works/github.com/chck/dotfiles/config/agents/infra.md`
