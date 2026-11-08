# Canned output index — light-escalation-tag-abac

Lookup rules are in `../../DRY-RUN-PROTOCOL.md` (rule 1). Rows that share a pattern are told apart by the environment and the state in their `Use when` column.

- **Dry-run clock:** starts 2026-11-09 10:00 +07:00 (03:00Z).
- **Environments:** the repo has one env file, `envs/prod.tfvars` (account `333333333333`, pinned through `allowed_account_ids`). Every read and plan is for prod.
- **State.** *Before* means the tag change has not been applied. *After* means the simulated `terraform apply` has run.

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws sts get-caller-identity` | `identity-prod.json` | always. Account 333333333333 |

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
| `plan-prod.txt` | `sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a` |

## AWS reads (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `aws s3api get-bucket-tagging --bucket paymentapi-exports-prod` | `s3-bucket-tagging-prod.json` | before the tag change is applied. After: `s3-bucket-tagging-after-prod.json` |
| `aws s3api head-bucket --bucket paymentapi-exports-prod` | `s3-head-bucket-prod.json` | always |
| `aws s3api get-bucket-versioning --bucket paymentapi-exports-prod` | `s3-versioning-prod.json` | always |
| `aws s3api get-public-access-block --bucket paymentapi-exports-prod` | `s3-public-access-block-prod.json` | always |
| `aws iam get-policy --policy-arn *paymentapi-team-bucket-read-prod` | `iam-get-policy-prod.json` | always |
| `aws iam get-policy-version --policy-arn *paymentapi-team-bucket-read-prod *` | `iam-get-policy-version-prod.json` | always |
| `aws iam list-entities-for-policy --policy-arn *paymentapi-team-bucket-read-prod *` | `iam-list-entities-for-policy-prod.json` | always |
| `aws iam list-attached-role-policies --role-name paymentapi-engineers-prod *` | `iam-list-attached-role-policies-prod.json` | always |
| `aws resourcegroupstaggingapi get-resources *` | `tagging-get-resources-team-prod.json` | any tag filter on the `team` key |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | always (nothing is firing) |
| `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi*` | `alarms-prefix-prod.json` | always. The two bucket alarms (4xx and 5xx), enabled, state `OK` |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/S3 --metric-name 4xxErrors *` | `alarms-for-metric-s3-4xx-prod.json` | always |
| `aws cloudwatch describe-alarms-for-metric --namespace AWS/S3 --metric-name 5xxErrors *` | `alarms-for-metric-s3-5xx-prod.json` | always |
| `aws cloudwatch describe-alarm-history --alarm-name paymentapi-exports-* *` | `alarm-history-prod.json` | always. No state change in the last week |
| `aws sns get-topic-attributes --topic-arn *paymentapi-exports-alerts-prod` | `sns-attributes-prod.json` | always |
| `aws sns list-subscriptions-by-topic --topic-arn *paymentapi-exports-alerts-prod *` | `sns-subscriptions-prod.json` | always. The file carries endpoints; only `Protocol` is needed |
| `aws s3api list-bucket-metrics-configurations --bucket paymentapi-exports-prod` | `s3-metrics-configuration-prod.json` | always. One configuration, `EntireBucket` |
| `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name 4xxErrors *` | `metric-s3-4xx-prod.json` | any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name 5xxErrors *` | `metric-s3-5xx-prod.json` | any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name AllRequests *` | `metric-s3-requests-prod.json` | any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes *` | `metric-s3-bucket-size-prod.json` | any window |
| `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name NumberOfObjects *` | `metric-s3-objects-prod.json` | any window |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
