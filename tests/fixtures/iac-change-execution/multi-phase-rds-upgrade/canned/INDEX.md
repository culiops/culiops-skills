# Canned output index — multi-phase-rds-upgrade

Lookup rules are in `../../DRY-RUN-PROTOCOL.md` (rule 1). Rows that share a pattern are told apart by the environment and the state in their `Use when` column.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Live account:** `123456789012`, in every canned file. It is the account the catalog and the `sns_topic_arn` in `envs/prod.tfvars` name, and the live alarms carry that topic ARN.
- **Environments:** the repo has one env file, `envs/prod.tfvars`. Every read and plan is for prod.
- **State.** The instance moves through four states: *before* (nothing applied), *after phase 1* (the phase-1 `terraform apply` has run), *rebooting* (the first read after the reboot command), *after reboot* (every later read).

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws sts get-caller-identity` | `identity-prod.json` | always. Account 123456789012 |

## Git and GitHub (simulated)

| Command pattern | Canned file | Use when |
|---|---|---|
| `git branch --show-current` | `git-branch.txt` | before the skill switches branch: the default branch, `main` |
| `git branch --show-current` | `git-branch-after-switch.txt` | after `git switch -c <name>` or `git checkout -b <name>`: that new branch. The runner puts `<name>` where `<branch>` stands |
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
| `git switch -c *`, `git checkout -b *` | `git-switch.txt` | the runner puts the real branch name where `<branch>` stands |
| `git add *` | `empty.txt` | no output |
| `git commit *` | `git-commit.txt` | the runner fills in the branch, subject and counts |
| `git push *` | `git-push.txt` | the runner fills in the branch |
| `gh pr create *` | `gh-pr-create.txt` | the PR URL |

## Terraform (phase 1)

| Command pattern | Canned file | Use when |
|---|---|---|
| `terraform init *` | `terraform-init.txt` | always |
| `terraform fmt *` | `empty.txt` | always: files are already formatted, so nothing is printed |
| `terraform validate` | `terraform-validate.txt` | always |
| `terraform version` | `terraform-version.txt` | always |
| `aws --version` | `aws-version.txt` | always |
| `terraform plan -refresh-only *` | `plan-refresh-only-prod.txt` | the drift check. No drift |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-prod.txt` | before the phase-1 apply. The plan for the change as asked |
| `terraform show -no-color tfplan` | `plan-prod.txt` | the same text as the plan |
| `sha256sum <scratch file holding the plan text>` | (see Plan hashes) | the plan hash |
| `terraform apply *tfplan*` | `apply-prod.txt` | phase 1 |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-after-prod.txt` | re-plan after the phase-1 apply |

## Plan hashes

| Plan text | SHA-256 |
|---|---|
| `plan-prod.txt` | `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` |

## AWS reads and the phase-2 command (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod *` | `rds-instance-prod.json` | before the phase-1 apply. Any `--query` is applied by the runner |
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod *` | `rds-instance-pending-reboot-prod.json` | after the phase-1 apply, before the reboot command |
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod *` | `rds-instance-rebooting-prod.json` | the first read after the reboot command |
| `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod *` | `rds-instance-after-reboot-prod.json` | every later read |
| `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 *` | `rds-parameters-max-connections-before.json` | before the phase-1 apply (the runner filters to the named parameter) |
| `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 *` | `rds-parameters-max-connections-after.json` | after the phase-1 apply |
| `aws rds describe-db-snapshots *` | `rds-snapshots-prod.json` | always. Three automated snapshots, the newest from 2026-11-09 02:05 +00:00 |
| `aws rds describe-events *` | `rds-events-prod.json` | always. Only backup events in the last day |
| `aws rds describe-pending-maintenance-actions *` | `rds-pending-maintenance-prod.json` | always. None |
| `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod *` | `rds-reboot-prod.json` | phase 2. The instance moves to *rebooting* |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name DatabaseConnections *paymentapi-db-prod*` | `metric-rds-connections-prod.json` | reads of prod, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization *paymentapi-db-prod*` | `metric-rds-cpu-prod.json` | reads of prod, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeableMemory *paymentapi-db-prod*` | `metric-rds-freeable-memory-prod.json` | reads of prod, any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeStorageSpace *paymentapi-db-prod*` | `metric-rds-free-storage-prod.json` | reads of prod, any window |
| `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod *` | `ecs-describe-services-prod.json` | the app tier that connects to the database |
| `aws elbv2 describe-target-health --target-group-arn *paymentapi-tg-prod*` | `tg-health-prod.json` | the app tier |

## CloudWatch alarms (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | before the phase-1 apply. After it: `alarms-prefix-after-prod.json` |
| `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod *` | `alarm-connections-before-prod.json` | before the phase-1 apply. After it: `alarm-connections-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name DatabaseConnections *` | `alarms-for-metric-connections-prod.json` | before the phase-1 apply. After it: `alarms-for-metric-connections-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization *` | `alarms-for-metric-cpu-prod.json` | always |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | always (the connections alarm is `OK` now; its history shows it flips often) |
| `aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod *` | `alarm-history-connections-prod.json` | always |
| `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod *` | `sns-subscriptions-prod.json` | always. The file carries endpoints; only `Protocol` is needed |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
