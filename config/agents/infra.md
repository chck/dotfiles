# Infra / Terraform Instructions

Terraformファイルはすべて `infra/` 配下に置く。リポジトリルートや他のディレクトリには置かない。

## Stack
- IaC: Terraform
- CI/CD: OpenTaco (ex. digger) — PRごとにplan/applyが走る
- State backend: GCS (versioning enabled)
- Cloud: GCP

## File naming
ファイル名は数値プレフィックスで依存順序を表す（Layered Architectureに倣う）。
数字が小さいほど他に依存しない独立したリソース。高番号ファイルが低番号ファイルを参照するのが基本。

```
01_setting.tf    ... Terraform/provider version pins, shared variable "common", provider blocks
02_storage.tf    ... GCS, Artifact Registry など
03_parameter.tf  ... Secret Manager など
04_database.tf   ... Cloud SQL など
05_*.tf          ... Compute (Cloud Run, GCE など)
06_*.tf          ... Jobs / Scheduler
07_ci.tf         ... Workload Identity Federation (GitHub Actions)
08_domain.tf     ... DNS, Domain Mapping
```

**`01_setting.tf` は特別**: Terraform/provider version pins、共有 `variable "common"`、provider blocks のみ置く。
インスタンス名・バケット名などサービス固有パラメータは各サービスファイルに書く。

## Variables
- 変数はそれを使うサービスファイルにスコープを閉じて定義する（`variables.tf` に集約しない）
- 環境ごとに値が異なる場合は workspace 名をキーにしたマップ変数 + `locals` で解決する
- `terraform.tfvars` は不要（全変数に `default` を定義する）

```hcl
# 05_cloudrun.tf — このファイル専用の変数
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

リソース内では `local.<service>.*` や `terraform.workspace` を使い、環境名を文字列ハードコードしない。

## Labels
`labels` をサポートする全リソースに付ける:

```hcl
labels = { owner = var.common.owner }                               # 全リソース共通
labels = { owner = var.common.owner, env = terraform.workspace }    # ワークスペース固有リソース
```

`google_service_account`、`google_cloud_scheduler_job` など labels 非対応リソースは対象外。

## Environments & Workspaces
複数環境が必要な場合は `stg` / `prod` を Terraform workspaces で管理する。
環境分離が不要な場合は `default` workspace をそのまま使う。

```bash
terraform workspace list
terraform workspace select stg   # or prod
```

## Coding rules
- `count` より `for_each` を優先（インデックスずれを防ぐ）
- sensitive な値は `variable` に `sensitive = true` を付ける
- ステートフルリソース（DB, GCS等）には `lifecycle { prevent_destroy = true }` を付ける
- プロバイダーバージョンは `~>` で minor までpin

## Authentication (local)
SA impersonation で操作する。`GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` を export すると Google provider が自動で使う:

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

- planなしに apply しない
- stateを直接編集しない（`terraform state mv` を使う）

## CI/CD (OpenTaco)
| タイミング | トリガー | 動作 |
|-----------|---------|------|
| PR上 | `/terraform plan` コメント | stg・prod の plan 結果をPRコメントに投稿 |
| PR上 | `/terraform apply` コメント | stg に apply |
| main マージ | `infra/**` の変更を検知 | prod に自動 apply |

`infra/**` に変更があるPRでは plan `-detailed-exitcode` が自動実行され、差分が残っていると CI が失敗する。

## Security
- シークレット値を tfstate やコードに平文で書かない（Secret Manager に格納、値は手動投入）
- `*.tfvars` はコミットしない
- IAMポリシーは最小権限原則に従う
