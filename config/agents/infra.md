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
  }, var.cloudrun[terraform.workspace])
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
- Pin provider versions to minor with `~>` (e.g. `~> 5.0`)

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

PRs with changes under `infra/**` run `plan -detailed-exitcode` automatically — CI fails if a diff remains after apply.

## Security
- Never store secret values in plaintext in tfstate or code (store in Secret Manager, populate values manually)
- Do not commit `*.tfvars`
- Follow least-privilege principle for IAM policies
