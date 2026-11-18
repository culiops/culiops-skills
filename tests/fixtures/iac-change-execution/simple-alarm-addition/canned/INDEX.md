# Canned output index — simple-alarm-addition

Lookup rules are in `../../DRY-RUN-PROTOCOL.md` (rule 1). A row with no file is answered as its last column says.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Live account:** `123456789012`, in every canned file. It is the account the role ARNs and the ECR repo in `envs/prod.tfvars` name.
- **Environments:** the repo has one env file, `envs/prod.tfvars`. Every read and plan is for prod.

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws sts get-caller-identity` | `identity-prod.json` | always. Account 123456789012, region `ap-southeast-1` from the var-file |

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
| `terraform show -no-color tfplan` | `plan-prod.txt` | the same text as the plan |
| `sha256sum <scratch file holding the plan text>` | (see Plan hashes) | the plan hash |
| `terraform apply *tfplan*` | `apply-prod.txt` | direct apply path only |
| `terraform plan *-var-file=envs/prod.tfvars*` | `plan-after-prod.txt` | re-plan, only after the simulated apply has run |

## Plan hashes

| Plan text | SHA-256 |
|---|---|
| `plan-prod.txt` | `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` |

## AWS reads (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod *` | `ecs-describe-services-prod.json` | reads of prod. Any `--query` is applied by the runner |
| `aws ecs describe-task-definition --task-definition paymentapi-prod*` | `ecs-describe-task-definition-prod.json` | reads of prod |
| `aws elbv2 describe-target-health --target-group-arn *paymentapi-tg-prod*` | `tg-health-prod.json` | reads of prod |
| `aws elbv2 describe-target-groups --names paymentapi-tg-prod *` | `tg-describe-prod.json` | reads of prod. Names the load balancer in front of the service |
| `aws elbv2 describe-target-groups --target-group-arns *paymentapi-tg-prod*` | `tg-describe-prod.json` | reads of prod. The same file as the `--names` form |
| `aws elbv2 describe-load-balancers --load-balancer-arns *paymentapi-alb-prod*` | `lb-describe-prod.json` | reads of prod |
| `aws sns get-topic-attributes --topic-arn *paymentapi-alerts-prod` | `sns-attributes-prod.json` | reads of prod |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-prod *` | `sns-subscriptions-prod.json` | reads of prod. The file carries endpoints; only `Protocol` is needed |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | S0/S1, before the alarm exists: reads of prod (nothing is firing) |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-prod*` | `metric-cpu-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization *paymentapi-svc-prod*` | `metric-memory-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count *paymentapi-alb-prod*` | `metric-alb-5xx-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime *paymentapi-alb-prod*` | `metric-alb-latency-prod.json` | reads of prod. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name RequestCount *paymentapi-alb-prod*` | `metric-alb-requests-prod.json` | reads of prod. The same file for the last hour and for the same hour a week ago |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | before the alarm exists (no alarm is on the service). After an apply or a merge that has been applied: `alarms-prefix-after-prod.json` |
| `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod *` | `alarm-cpu-high-before-prod.json` | before the alarm exists. After an apply or an applied merge: `alarm-cpu-high-after-prod.json` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization *` | `alarms-for-metric-cpu-prod.json` | before the alarm exists (no alarm on this metric). After an apply or an applied merge: `alarms-for-metric-cpu-after-prod.json` |
| `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod *` | `alarm-history-prod.json` | before the alarm exists. After an apply or an applied merge: `alarm-history-after-prod.json` |
| `aws pricing get-products *` | `pricing-cloudwatch-alarm.json` | any filters. CloudWatch standard alarm, 0.10 USD, publication 2026-10-07 |

## Operator profile

| Command pattern | Canned file | Use when |
|---|---|---|
| `operator profile read` (`$CULIOPS_HOME/operator.md`, else `~/.culiops/operator.md`) | (none) | `operator-script-no-profile.md` only: file not found. This row comes first, so it wins for that script |
| `operator profile read` | `operator-profile.md` | every other script. Q5 for terraform and Q4 for `acme/paymentapi-infra/paymentapi`, each dated 2026-10-19; none is `first time`; no `incident check:` line |

## App-source search (in the read batch)

No app source is findable: no directory beside the repo matches `paymentapi` by name or by origin.

| Command pattern | Canned file | Use when |
|---|---|---|
| `ls <parent of the repo>` (`ls ..`, `ls ../`, or the parent's path) | `siblings-ls.txt` | always. `dotfiles` and `paymentapi-infra` (this repo) |
| `git -C ../dotfiles remote get-url origin` | `sibling-origin-dotfiles.txt` | always. `git@github.com:acme/dotfiles.git`, not the app |

## Snapshot reads (prod)

S0/S1 = before the apply or the merge (the Step 1 batch, and the re-read just before the apply). S2 = after an apply or an applied merge. The change adds an alarm that nothing reads, so a run reads the service and its load balancer only. A `get-metric-data` file answers whatever query file the skill writes (protocol, Notes › `get-metric-data` files).

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-after-prod.json` | S2: nothing is firing; the new alarm exists and is not in `ALARM` |
| `aws cloudwatch get-metric-data *` | `metric-data-7d-prod.json` | a window longer than one day (the 7-day peak-hours read for Q3 on the PR / CI path). `RequestCount` for `paymentapi-alb-prod`, one value per hour, 169 hours oldest first, the last the hour ending at the clock start (41,442) and the first the same hour a week earlier. Weekdays peak between 13:00 and 16:00 +07:00 (about 57,000–61,000 per hour); the weekend is about 60% of a weekday |
| `aws cloudwatch get-metric-data *` | `metric-data-s0-prod.json` | S0/S1, a window of one hour or less (the hour ending now, and the same hour a week ago). For the load balancer `paymentapi-alb-prod`: `RequestCount` (about 3,450 per 5 minutes, the same hour a week ago about 3,400), `HTTPCode_Target_5XX_Count` (0), `TargetResponseTime` p95 (about 0.11 s). For `paymentapi-svc-prod`: CPU 35–41%, memory 50–54% |
| `aws cloudwatch get-metric-data *` | `metric-data-s2-prod.json` | S2: the same signals for the 6 periods after the apply, unchanged. Only if the skill reads metrics after the apply |
| `gh run list *` | `gh-run-list.json` | CI history. The operator-stated delivery model is a CI pipeline that applies on merge: its last run succeeded 2026-11-06 11:31 +07:00, 3 days before the clock start |
| `aws s3api head-object --bucket * --key *` | `s3-head-object-state-prod.json` | the state object's metadata. `LastModified` 2026-11-06 11:32 +07:00. The code declares no backend block, so a skill that cannot name the bucket and key does not run this |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup, any page) |  | `no canned output`: this fixture has no documentation entries |
