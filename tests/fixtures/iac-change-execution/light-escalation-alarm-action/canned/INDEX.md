# Canned output index — light-escalation-alarm-action

Lookup rules are in `../../DRY-RUN-PROTOCOL.md` (rule 1). Rows that share a pattern are told apart by the environment and the state in their `Use when` column.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Environments:** the repo has one env file, `envs/prod.tfvars` (account `333333333333`, pinned through `allowed_account_ids`). Every read and plan is for prod.
- **State.** *Before* means the new alarm does not exist yet. *After* means the simulated `terraform apply` has run. The existing `paymentapi-cpu-high-prod` alarm exists in both states.

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws sts get-caller-identity` | `identity-prod.json` | always. Account 333333333333 |

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
| `terraform plan -refresh-only *` | `plan-refresh-only-prod.txt` | the drift check. No drift |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-prod.txt` | before the simulated apply (or when no apply runs). The plan for the change as asked |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-after-prod.txt` | re-plan, after the simulated apply |
| `terraform show -no-color tfplan` | `plan-prod.txt` | the same text as the plan |
| `sha256sum <scratch file holding the plan text>` | (see Plan hashes) | the plan hash |
| `terraform apply *tfplan*` | `apply-prod.txt` | direct apply path only |

## Plan hashes

| Plan text | SHA-256 |
|---|---|
| `plan-prod.txt` | `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0` |

## AWS reads (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod *` | `ecs-describe-services-prod.json` | reads of prod. Any `--query` is applied by the runner |
| `aws ecs describe-task-definition --task-definition paymentapi-prod*` | `ecs-describe-task-definition-prod.json` | reads of prod |
| `aws elbv2 describe-target-health --target-group-arn *paymentapi-tg-prod*` | `tg-health-prod.json` | reads of prod |
| `aws elbv2 describe-target-groups --names paymentapi-tg-prod *` | `tg-describe-prod.json` | reads of prod. Names the load balancer in front of the service |
| `aws elbv2 describe-load-balancers --load-balancer-arns *paymentapi-alb-prod*` | `lb-describe-prod.json` | reads of prod |
| `aws sns get-topic-attributes --topic-arn *paymentapi-alerts-prod` | `sns-attributes-prod.json` | reads of prod |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-prod *` | `sns-subscriptions-prod.json` | reads of prod. The file carries endpoints; only `Protocol` is needed |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | reads of prod (nothing is firing) |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-prod*` | `metric-cpu-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization *paymentapi-svc-prod*` | `metric-memory-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count *paymentapi-alb-prod*` | `metric-alb-5xx-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime *paymentapi-alb-prod*` | `metric-alb-latency-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name RequestCount *paymentapi-alb-prod*` | `metric-alb-requests-prod.json` | reads of prod. The same file for the last hour and for the same hour a week ago |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | before the new alarm exists (it lists `paymentapi-cpu-high-prod`). After the apply: `alarms-prefix-after-prod.json` |
| `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod *` | `alarm-cpu-high-prod.json` | always |
| `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-low-prod *` | `alarm-cpu-low-before-prod.json` | before the new alarm exists. After the apply: `alarm-cpu-low-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-prod*` | `alarms-for-metric-cpu-prod.json` | before the new alarm exists (it lists `paymentapi-cpu-high-prod`). After the apply: `alarms-for-metric-cpu-after-prod.json` |
| `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod *` | `alarm-history-prod.json` | always |
| `aws application-autoscaling describe-scalable-targets *` | `appautoscaling-targets-prod.json` | always |
| `aws application-autoscaling describe-scaling-policies *` | `appautoscaling-policies-prod.json` | always |
| `aws application-autoscaling describe-scaling-activities *` | `appautoscaling-activities-prod.json` | always |
| `aws pricing get-products *` | `pricing-cloudwatch-alarm.json` | any filters. CloudWatch standard alarm, 0.10 USD, publication 2026-10-07 |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
