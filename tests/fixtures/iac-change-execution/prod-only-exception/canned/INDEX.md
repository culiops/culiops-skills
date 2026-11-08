# Canned output index — prod-only-exception

Lookup rules are in `../../DRY-RUN-PROTOCOL.md`. The first matching row wins, and rows that share a pattern are told apart by their `Use when` column.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Environments:** `staging` (account `222222222222`) and `prod` (account `333333333333`), each pinned in its var-file through `aws_account_id` and the provider's `allowed_account_ids`.
- **Identity.** `aws sts get-caller-identity` returns the account of the environment the skill is working on. Both credentials are available to the operator; switching is not a stop.
- **State.** *Before* means the threshold change has not been applied. *After* means the simulated `terraform apply` for prod has run. Staging is never applied in this change.

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws sts get-caller-identity` | `identity-staging.json` | the skill is working on staging. Account 222222222222 |
| `aws sts get-caller-identity` | `identity-prod.json` | the skill is working on prod. Account 333333333333 |

## Git and GitHub (simulated)

| Command pattern | Canned file | Use when |
|---|---|---|
| `git branch --show-current` | `git-branch.txt` | always (the repo is on `main`) |
| `git status` | `git-status-clean.txt` | always, before the skill writes code. `git status --short` prints nothing |
| `git fetch origin *` | `empty.txt` | always (no output) |
| `git remote get-url origin` | `git-remote.txt` | always |
| `git rev-parse *` | `git-rev-parse.txt` | always. `--short` gives the first 7 characters, `a1b2c3d` |
| `git log * --since=*` | `empty.txt` | change velocity: no commit touched the changed paths in the window |
| `git log * --grep=*` | `empty.txt` | duplicate check by ticket key: no hits |
| `git log * -S*` | `empty.txt` | duplicate check by identifier: no hits |
| `git log *` | `git-log-recent.txt` | any other `git log` (all three commits are older than 30 days) |
| `git branch -a --list *` | `empty.txt` | duplicate check for an in-flight branch: none |
| `git branch -a` | `git-branches.txt` | always |
| `gh pr list *` | `gh-pr-list-empty.txt` | duplicate check for an in-flight PR: none |
| `git switch -c *` | `git-switch.txt` | the runner puts the real branch name where `<branch>` stands |
| `git add *` | `empty.txt` | no output |
| `git commit *` | `git-commit.txt` | the runner fills in the branch, subject and counts |
| `git push *` | `git-push.txt` | the runner fills in the branch |
| `gh pr create *` | `gh-pr-create.txt` | the PR URL |

## Terraform

| Command pattern | Canned file | Use when |
|---|---|---|
| `terraform init *` | `terraform-init.txt` | always |
| `terraform fmt *` | `empty.txt` | always: files are already formatted, so nothing is printed |
| `terraform validate` | `terraform-validate.txt` | always |
| `terraform version` | `terraform-version.txt` | always |
| `aws --version` | `aws-version.txt` | always |
| `terraform plan -refresh-only *-var-file=envs/staging.tfvars*` | `plan-refresh-only-staging.txt` | the drift check for staging. No drift |
| `terraform plan -refresh-only *-var-file=envs/prod.tfvars*` | `plan-refresh-only-prod.txt` | the drift check for prod. No drift |
| `terraform plan *-var-file=envs/staging.tfvars*` | `plan-staging.txt` | staging. No changes: staging sets no threshold and has no alarm |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-prod.txt` | prod, before the simulated apply (or when no apply runs). The plan for the change as asked |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-after-prod.txt` | prod re-plan, after the simulated apply |
| `terraform show -no-color tfplan` | `plan-prod.txt` | the last plan the skill ran was for prod |
| `terraform show -no-color tfplan` | `plan-staging.txt` | the last plan the skill ran was for staging |
| `sha256sum <scratch file holding the plan text>` | (see Plan hashes) | the plan hash of the plan being assessed |
| `terraform apply *tfplan*` | `apply-prod.txt` | direct apply path, prod |

## Plan hashes

| Plan text | SHA-256 |
|---|---|
| `plan-prod.txt` | `sha256:a064ec4b3620da485122e4d49f64ae579797abc4bc9577a7f170869d85a3bd73` |
| `plan-staging.txt` | `sha256:dd2667202fa342fb3240c45e67c5b2315efd53741b0be4c4ede60dd077a35c8e` |

## AWS reads (staging)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws ecs describe-services --cluster paymentapi-cluster-staging --services paymentapi-svc-staging *` | `ecs-describe-services-staging.json` | reads of staging. Any `--query` is applied by the runner |
| `aws ecs describe-task-definition --task-definition paymentapi-staging*` | `ecs-describe-task-definition-staging.json` | reads of staging |
| `aws elbv2 describe-target-health --target-group-arn *paymentapi-tg-staging*` | `tg-health-staging.json` | reads of staging |
| `aws sns get-topic-attributes --topic-arn *paymentapi-alerts-staging` | `sns-attributes-staging.json` | reads of staging |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-staging *` | `sns-subscriptions-staging.json` | reads of staging. The file carries endpoints; only `Protocol` is needed |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-staging.json` | reads of staging (nothing is firing) |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-staging*` | `metric-cpu-staging.json` | reads of staging. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization *paymentapi-svc-staging*` | `metric-memory-staging.json` | reads of staging. Any time window or period gives this file |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-staging.json` | staging. No alarm |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-staging*` | `alarms-for-metric-cpu-staging.json` | staging. No alarm |

## AWS reads (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod *` | `ecs-describe-services-prod.json` | reads of prod. Any `--query` is applied by the runner |
| `aws ecs describe-task-definition --task-definition paymentapi-prod*` | `ecs-describe-task-definition-prod.json` | reads of prod |
| `aws elbv2 describe-target-health --target-group-arn *paymentapi-tg-prod*` | `tg-health-prod.json` | reads of prod |
| `aws sns get-topic-attributes --topic-arn *paymentapi-alerts-prod` | `sns-attributes-prod.json` | reads of prod |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-prod *` | `sns-subscriptions-prod.json` | reads of prod. The file carries endpoints; only `Protocol` is needed |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | reads of prod (nothing is firing) |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-prod*` | `metric-cpu-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization *paymentapi-svc-prod*` | `metric-memory-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | prod, before the apply. After it: `alarms-prefix-after-prod.json` |
| `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod *` | `alarm-cpu-high-prod.json` | prod, before the apply. After it: `alarm-cpu-high-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-prod*` | `alarms-for-metric-cpu-prod.json` | prod, before the apply. After it: `alarms-for-metric-cpu-after-prod.json` |
| `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod *` | `alarm-history-prod.json` | prod. Four episodes in the last week, peaks of 85 to 88 percent |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup, any page) |  | `no canned output`: this fixture has no documentation entries |
