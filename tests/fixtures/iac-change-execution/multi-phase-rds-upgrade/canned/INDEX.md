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
| `git remote get-url origin` | `git-remote.txt` | always, for the repo itself (a `git -C <dir>` read of a sibling checkout is in App-source search) |
| `git rev-parse *` | `git-rev-parse.txt` | always, for the repo itself. `--short` gives the first 7 characters, `a1b2c3d` |
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
| `aws elbv2 describe-target-groups --names paymentapi-tg-prod *` | `tg-describe-prod.json` | the app tier. Names the load balancer in front of it |
| `aws elbv2 describe-target-groups --target-group-arns *paymentapi-tg-prod*` | `tg-describe-prod.json` | the app tier. The same file as the `--names` form |
| `aws elbv2 describe-load-balancers --load-balancer-arns *paymentapi-alb-prod*` | `lb-describe-prod.json` | the load balancer `paymentapi-alb-prod` |

## CloudWatch alarms (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | before the phase-1 apply. After it: `alarms-prefix-after-prod.json` |
| `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod *` | `alarm-connections-before-prod.json` | before the phase-1 apply. After it: `alarm-connections-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name DatabaseConnections *` | `alarms-for-metric-connections-prod.json` | before the phase-1 apply. After it: `alarms-for-metric-connections-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization *` | `alarms-for-metric-cpu-prod.json` | always |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | S0/S1 of phase 1 (the connections alarm is `OK` now; its history shows it flips often) |
| `aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod *` | `alarm-history-connections-prod.json` | always |
| `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod *` | `sns-subscriptions-prod.json` | always. The file carries endpoints; only `Protocol` is needed |

## Operator profile

| Command pattern | Canned file | Use when |
|---|---|---|
| `operator profile read` (`$CULIOPS_HOME/operator.md`, else `~/.culiops/operator.md`) | `operator-profile.md` | always. Q5 for terraform and Q4 for `acme/paymentapi-infra/paymentapi`, each dated 2026-10-19; none is `first time`; no `incident check:` line |

## App-source search (in the read batch)

The change touches an app-facing attribute (`max_connections`), so Step 1 predicts an app-facing change and the skill looks for the app source. It is a sibling checkout, `../paymentapi`, whose directory name and origin match the service. The checkout is not at the deployed version. The deployed image is `paymentapi:v2.4.1` (`ecs-describe-task-definition-prod.json`, the task definition `paymentapi-prod:12` that `ecs-describe-services-prod.json` names). `HEAD` is 3 commits past the tag `v2.5.0`, and `v2.4.1` is an older commit that exists in the checkout. The tree is clean, so pre-flight's local mode reads the deployed ref without checking it out (`skills/pre-flight/examples/app-source.md` › Mode A). A read of the working tree at `HEAD`, or of any other file, gets `no canned output`.

At the deployed ref `v2.4.1` the app builds its connection pool from `DB_POOL_SIZE` (default 20) and `DB_MAX_OVERFLOW` (default 5), and the task definition sets neither. That is at most 25 connections per task. The service runs 3 tasks, so about 75 connections, which fits under the current 100 and the new 200 (the live maximum was 78). The pool uses `pool_pre_ping`, so a connection closed by a restart is replaced on checkout.

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws ecs describe-task-definition --task-definition paymentapi-prod*` | `ecs-describe-task-definition-prod.json` | reads of prod. The deployed image tag is `v2.4.1` |
| `ls <parent of the repo>` (`ls ..`, `ls ../`, or the parent's path) | `siblings-ls.txt` | always. `dotfiles`, `paymentapi` (the app) and `paymentapi-infra` (this repo) |
| `git -C ../dotfiles remote get-url origin` | `sibling-origin-dotfiles.txt` | always. `git@github.com:acme/dotfiles.git`, not the app |
| `git -C ../paymentapi remote get-url origin` | `sibling-origin-paymentapi.txt` | always. `git@github.com:acme/paymentapi.git` |
| `git -C ../paymentapi rev-parse HEAD` | `app-source-rev-parse.txt` | always. `5d1c8e4a7b2f90361a4c6e8d0b3f5a7c9e1d2b4f`, not the commit of `v2.4.1` |
| `git -C ../paymentapi status --porcelain` | `empty.txt` | always. The tree is clean |
| `git -C ../paymentapi describe --tags*` | `app-source-describe.txt` | always. `v2.5.0-3-g5d1c8e4` |
| `git -C ../paymentapi rev-parse v2.4.1*` | `app-source-rev-parse-tag.txt` | always. The commit of the deployed tag, `c0a7e93f1b6d4285a9e0c3b7d5f2a18e46b9d07c`; the ref exists in the checkout |
| `git -C ../paymentapi grep -n * v2.4.1 -- .` | `app-source-grep-deployed.txt` | any search at the deployed ref for the pool, the connection limit or the database engine. The lines that set the pool size and the overflow |
| `git -C ../paymentapi show v2.4.1:app/db.py` | `app-source-show-db.py.txt` | the file that builds the engine |
| `git -C ../paymentapi show v2.4.1:app/config.py` | `app-source-show-config.py.txt` | the config loader. It holds no password |

## Snapshot reads (prod)

The snapshot set has three kinds of member: the database `paymentapi-db-prod` (the parameter group has no signals of its own and is measured through the instance that uses it), the ECS service `paymentapi-svc-prod` (the consumer: `main.tf` lets `var.app_security_group_id` into the database's security group, and the catalog lists the service as downstream) and the load balancer `paymentapi-alb-prod` in front of that service (the nearest member with a request rate). States:

- S0/S1 of phase 1: before the phase-1 apply.
- S2 of phase 1, and S1 of phase 2: after the phase-1 apply, before the reboot command. The instance is `pending-reboot`; no metric has changed.
- S2 of phase 2: after the reboot command. The first period after the reboot is the reboot itself: the instance is `rebooting`, CPU is 86% and connections are 0. From the second period the instance is `available` and every series is back to normal. The app tier rides through the reboot, so only the database's own series shows it.

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-after-prod.json` | S2 of phase 1, S1 of phase 2 and S2 of phase 2: nothing is firing (the reboot period is one period, shorter than either database alarm needs) |
| `aws cloudwatch get-metric-data *` | `metric-data-s0-prod.json` | S0/S1 of phase 1, and S2 of phase 1 / S1 of phase 2 (nothing changed in the metrics). Database: CPU 31–37%, connections average 50–53 and maximum 76–78 of `max_connections` 100. ECS service: CPU 35–41%, memory 50–54%. Load balancer: `RequestCount` about 3,450 per 5 minutes, 5XX 0, p95 about 0.11 s. Each with the same hour a week ago |
| `aws cloudwatch get-metric-data *` | `metric-data-s2-reboot-prod.json` | S2 of phase 2: 6 periods from the reboot command, database series as described above, the others unchanged. The runner returns the periods inside the window the skill asked for |
| `gh run list *` | `gh-run-list-empty.json` | always. The repo has no CI config: `[]` |
| `aws s3api head-object --bucket * --key *` | `s3-head-object-state-prod.json` | the state object's metadata. `LastModified` 2026-10-30 16:14 +07:00. The code declares no backend block, so a skill that cannot name the bucket and key does not run this |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
