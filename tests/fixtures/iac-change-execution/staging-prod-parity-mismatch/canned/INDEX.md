# Canned output index — staging-prod-parity-mismatch

Lookup rules are in `../../DRY-RUN-PROTOCOL.md`. The first matching row wins, and rows that share a pattern are told apart by their `Use when` column.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Environments:** `staging` (account `222222222222`) and `prod` (account `333333333333`), each pinned in its var-file through `aws_account_id` and the provider's `allowed_account_ids`.
- **Identity.** `aws sts get-caller-identity` returns the account of the environment the skill is working on: staging while it reads, plans or applies for staging, prod once it moves on to prod. Both credentials are available to the operator; switching is not a stop.
- **State.** *Before* means staging has not been applied in this run. *After* means the simulated staging `terraform apply` has run. Prod is never applied.

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
| `terraform plan *-var-file=envs/staging.tfvars*` | `plan-staging.txt` | staging, before the staging apply. The plan for the change as asked |
| `terraform plan *-var-file=envs/staging.tfvars*` | `plan-after-staging.txt` | staging re-plan, after the staging apply |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-prod.txt` | prod |
| `terraform show -no-color tfplan` | `plan-staging.txt` | the last plan the skill ran was for staging |
| `terraform show -no-color tfplan` | `plan-prod.txt` | the last plan the skill ran was for prod |
| `sha256sum <scratch file holding the plan text>` | (see Plan hashes) | the plan hash of the plan being assessed |
| `terraform apply *tfplan*` | `apply-staging.txt` | the apply is for staging. A prod apply has no canned output |

## Plan hashes

| Plan text | SHA-256 |
|---|---|
| `plan-staging.txt` | `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd` |
| `plan-prod.txt` | `sha256:25ca45650f7c2067c858c5cc4507499de09f9a762e9bce363c94b594c05177c9` |

## AWS reads (staging)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging *` | `rds-instance-staging.json` | reads of staging, before the staging apply. Any `--query` is applied by the runner |
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging *` | `rds-instance-after-staging.json` | after the staging apply: engine 15.7, `available` |
| `aws rds describe-db-parameter-groups --db-parameter-group-name paymentapi-staging-20250920071544123400000001 *` | `rds-parameter-group-staging.json` | reads of staging |
| `aws rds describe-db-snapshots *paymentapi-db-staging*` | `rds-snapshots-staging.json` | reads of staging. Three automated snapshots, the newest from 2026-11-09 02:05 +00:00 |
| `aws rds describe-events *paymentapi-db-staging*` | `rds-events-staging.json` | reads of staging. Only backup events in the last day |
| `aws rds describe-pending-maintenance-actions *` | `rds-pending-maintenance-staging.json` | reads of staging. None |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name DatabaseConnections *paymentapi-db-staging*` | `metric-rds-connections-staging.json` | reads of staging, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization *paymentapi-db-staging*` | `metric-rds-cpu-staging.json` | reads of staging, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeableMemory *paymentapi-db-staging*` | `metric-rds-freeable-memory-staging.json` | reads of staging, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeStorageSpace *paymentapi-db-staging*` | `metric-rds-free-storage-staging.json` | reads of staging, any window |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-staging.json` | reads of staging |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization *paymentapi-db-staging*` | `alarms-for-metric-cpu-staging.json` | reads of staging |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-staging.json` | reads of staging (nothing is firing) |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-staging *` | `sns-subscriptions-staging.json` | reads of staging. The file carries endpoints; only `Protocol` is needed |

## AWS reads (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod *` | `rds-instance-prod.json` | reads of prod. Any `--query` is applied by the runner |
| `aws rds describe-db-parameter-groups --db-parameter-group-name paymentapi-prod-20250617043012345600000001 *` | `rds-parameter-group-prod.json` | reads of prod |
| `aws rds describe-db-snapshots *paymentapi-db-prod*` | `rds-snapshots-prod.json` | reads of prod. Three automated snapshots, the newest from 2026-11-09 02:05 +00:00 |
| `aws rds describe-events *paymentapi-db-prod*` | `rds-events-prod.json` | reads of prod. Only backup events in the last day |
| `aws rds describe-pending-maintenance-actions *` | `rds-pending-maintenance-prod.json` | reads of prod. None |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name DatabaseConnections *paymentapi-db-prod*` | `metric-rds-connections-prod.json` | reads of prod, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization *paymentapi-db-prod*` | `metric-rds-cpu-prod.json` | reads of prod, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeableMemory *paymentapi-db-prod*` | `metric-rds-freeable-memory-prod.json` | reads of prod, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeStorageSpace *paymentapi-db-prod*` | `metric-rds-free-storage-prod.json` | reads of prod, any window |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | reads of prod |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization *paymentapi-db-prod*` | `alarms-for-metric-cpu-prod.json` | reads of prod |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | reads of prod (nothing is firing) |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-prod *` | `sns-subscriptions-prod.json` | reads of prod. The file carries endpoints; only `Protocol` is needed |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
