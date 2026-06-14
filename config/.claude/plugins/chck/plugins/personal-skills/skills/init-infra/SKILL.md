---
name: init-infra
description: Set up infra/AGENTS.md in the current project. Use when starting infra work in a new project, when infra/ directory exists but AGENTS.md is missing, or when the user says "infraセットアップ", "init infra", "infra/AGENTS.md を作る", or "infraのルールを追加して".
---

# Init Infra AGENTS.md

Write the standard infra template directly to the current project's `infra/AGENTS.md`.

## Steps

1. **Check project context** — ask only if not clear from conversation:
   - Does the project use a different CI/CD tool than OpenTaco? (e.g. Atlantis, GitHub Actions directly)
   - Does the project use a cloud other than GCP?

2. **Create `infra/AGENTS.md`** in the current working directory with the template below:
   - Copy verbatim
   - Update only the Stack section if the project uses different tools (step 1)

3. **Confirm** by showing the created file path and a one-line summary of any customizations made.

## Notes

- If `infra/` directory does not exist, create it (just the directory, no other files)
- Never overwrite an existing `infra/AGENTS.md` without user confirmation

## Template

```markdown
# Infra / Terraform Instructions

All Terraform files live under `infra/`. Do not place them in the repository root or other directories.

## Stack
- IaC: Terraform
- CI/CD: OpenTaco (ex. digger) — plan/apply triggered per PR
- State backend: GCS (versioning enabled)
- Cloud: GCP

## File naming
Numeric prefixes represent dependency order, inspired by Layered Architecture: lower-numbered files are more independent; higher-numbered files depend on them.

```
01_setting.tf    ... Terraform/provider version pins, shared variable "common", provider blocks
02_storage.tf    ... GCS, Artifact Registry
03_parameter.tf  ... Secret Manager
04_database.tf   ... Cloud SQL
05_*.tf          ... Compute (Cloud Run, GCE, etc.)
06_*.tf          ... Jobs / Scheduler
07_ci.tf         ... Workload Identity Federation (GitHub Actions)
08_domain.tf     ... DNS, Domain Mapping
```

**`01_setting.tf` is special**: holds only Terraform/provider version pins, the shared `variable "common"`, and provider blocks. Service-specific parameters (instance names, bucket names, etc.) belong in each service file.

## Variables
- Define variables in the service file that uses them — do not centralize in `variables.tf`
- For values that differ per environment, use a map variable keyed by workspace name and resolve in `locals`
- No `terraform.tfvars` needed — define `default` on all variables

```hcl
# 05_cloudrun.tf — variables scoped to this file
variable "cloudrun" {
  default = {
    stg  = { service_name = "myapp-stg", min_instances = 1 }
    prod = { service_name = "myapp",     min_instances = 2 }
  }
}

locals {
  cloudrun = merge({
    shared_param = "value"
  }, try(var.cloudrun[terraform.workspace], error("No config defined for workspace '${terraform.workspace}'")))
}
```

Use `local.<service>.*` or `terraform.workspace` in resource blocks. Never hardcode environment names as strings.

## Labels
Add `labels` to every resource that supports them:

```hcl
labels = { owner = var.common.owner }                               # all resources
labels = { owner = var.common.owner, env = terraform.workspace }    # workspace-specific resources
```

`google_service_account`, `google_cloud_scheduler_job`, and other resources that do not support `labels` are exempt.

## Environments & Workspaces
Use `stg` / `prod` Terraform workspaces when multiple environments are needed.
Use the `default` workspace when environment separation is not required.

```bash
terraform workspace list
terraform workspace select stg   # or prod
```

## Coding rules
- Prefer `for_each` over `count` to avoid index shift issues
- Mark sensitive values with `sensitive = true` on the variable
- Add `lifecycle { prevent_destroy = true }` to stateful resources (DB, GCS, etc.)
- Pin provider versions to patch with `~>` (e.g. `~> 5.0.0` allows patch updates within 5.0, not `~> 5.0` which allows any 5.x)

## Authentication (local)
Operate via SA impersonation. The Google provider picks up `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` automatically:

```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=<project>-terraform@<project-id>.iam.gserviceaccount.com
```

## Workflow
```bash
cd infra
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=...
terraform workspace select stg    # or prod
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

- Never run `terraform apply` without reviewing `plan` output first
- Never edit state directly — use `terraform state mv`

## CI/CD (OpenTaco)
| Trigger | Action |
|---------|--------|
| PR comment `/terraform plan` | Posts stg & prod plan results as PR comment |
| PR comment `/terraform apply` | Applies to stg |
| Merge to main (`infra/**` changed) | Auto-applies to prod |

PRs with changes under `infra/**` run `terraform plan -detailed-exitcode` automatically — CI fails if the plan produces a non-empty diff.

## Security
- Never store secret values in plaintext in tfstate or code — do not use `secret_data` or read secret payloads via data sources, as Terraform writes them to state; reference secrets by name/ID only and populate values manually outside Terraform
- Do not commit `*.tfvars`
- Follow least-privilege principle for IAM policies
```
