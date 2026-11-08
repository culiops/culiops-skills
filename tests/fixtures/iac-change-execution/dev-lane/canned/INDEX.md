# Canned output index — dev-lane

Lookup rules are in `../../DRY-RUN-PROTOCOL.md`. The first matching row wins, and rows that share a pattern are told apart by their `Use when` column.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Environments:** `dev` (account `111111111111`) and `prod` (account `333333333333`), each pinned in its var-file through `aws_account_id` and the provider's `allowed_account_ids`. The change is for dev.
- **Which operator script is running decides the identity.** With `operator-script.md` the operator's credentials are for the dev account: STS returns `identity-dev.json`. With `operator-script-mismatch.md` the shell is on the prod profile: STS returns `identity-prod.json` for every call, whatever environment the skill is working on.
- **Mismatch rows.** With `operator-script-mismatch.md` the credentials are for the prod account, where the dev resources do not exist. Git and the local terraform commands (`init`, `fmt`, `validate`) answer as usual. Every other `aws` or `terraform` command answers from the *Mismatch script* section, and a command that section does not list returns `no canned output`.
- **State.** *Before* means the dev apply has not run. *After* means the simulated `terraform apply` has run.

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws sts get-caller-identity` | `identity-dev.json` | script `operator-script.md`. Account 111111111111 |
| `aws sts get-caller-identity` | `identity-prod.json` | script `operator-script-mismatch.md`. Account 333333333333, for every call |

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

## Terraform (script `operator-script.md`)

| Command pattern | Canned file | Use when |
|---|---|---|
| `terraform init *` | `terraform-init.txt` | always |
| `terraform fmt *` | `empty.txt` | always: files are already formatted, so nothing is printed |
| `terraform validate` | `terraform-validate.txt` | always |
| `terraform version` | `terraform-version.txt` | always |
| `aws --version` | `aws-version.txt` | always |
| `terraform plan -refresh-only *-var-file=envs/dev.tfvars*` | `plan-refresh-only-dev.txt` | the drift check. No drift |
| `terraform plan *-var-file=envs/dev.tfvars*` | `plan-dev.txt` | before the simulated apply. The plan for the change as asked |
| `terraform plan *-var-file=envs/dev.tfvars*` | `plan-after-dev.txt` | re-plan, after the simulated apply |
| `terraform show -no-color tfplan` | `plan-dev.txt` | the same text as the plan |
| `sha256sum <scratch file holding the plan text>` | (see Plan hashes) | the plan hash |
| `terraform apply *tfplan*` | `apply-dev.txt` | the apply |

## Plan hashes

| Plan text | SHA-256 |
|---|---|
| `plan-dev.txt` | `sha256:16bfca0073020ff4eaf0ecb203b9711d719438110fed0ba3bc502016af6c2394` |

## AWS reads (dev, script `operator-script.md`)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws ecs describe-services --cluster paymentapi-cluster-dev --services paymentapi-svc-dev *` | `ecs-describe-services-dev.json` | before the apply. After it: `ecs-describe-services-dev-after.json` |
| `aws ecs describe-task-definition --task-definition paymentapi-dev*` | `ecs-describe-task-definition-dev.json` | before the apply (revision 7, cpu 256). After it: `ecs-describe-task-definition-dev-after.json` (revision 8, cpu 512) |
| `aws elbv2 describe-target-health --target-group-arn *paymentapi-tg-dev*` | `tg-health-dev.json` | reads of dev |
| `aws sns get-topic-attributes --topic-arn *paymentapi-alerts-dev` | `sns-attributes-dev.json` | reads of dev |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-alerts-dev *` | `sns-subscriptions-dev.json` | reads of dev. The file carries endpoints; only `Protocol` is needed |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-dev.json` | reads of dev (nothing is firing) |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization *paymentapi-svc-dev*` | `metric-cpu-dev.json` | reads of dev. Any time window or period gives this file |
| `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization *paymentapi-svc-dev*` | `metric-memory-dev.json` | reads of dev. Any time window or period gives this file |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-dev.json` | dev has no alarms |

## Mismatch script (`operator-script-mismatch.md`)

| Command pattern | Canned file | Use when |
|---|---|---|
| `terraform plan *` | `plan-mismatch-error.txt` | any plan, refresh-only plan or `terraform show`: the provider refuses the account |
| `terraform apply *` | `plan-mismatch-error.txt` | the provider refuses the account |
| `aws ecs *` | `aws-error-cluster-not-found.txt` | any ECS read: the dev cluster is not in the prod account |
| `aws * (any other command)` |  | `no canned output` |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
