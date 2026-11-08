<!-- Would be written to .culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1100.md (CULIOPS_HOME unset, so the root is .culiops/ at the repo root) -->

**Prerequisites (examples/aws.md):** AWS CLI v2 (`aws --version` → aws-cli/2.17.21); authentication: assumed role `paymentapi-operator` in account 123456789012 (`aws sts get-caller-identity`); Tier 1 read-only reads only (the permission set itself was not inspected); Tier 2 mutation role: not used, the apply is done by CI on merge; cost awareness: CloudWatch `GetMetric*` and pricing reads carry small per-call charges.

**IaC change execution for:** `paymentapi` / `—`
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi in prod
**Date:** 2026-11-09 11:00
**Commit:** `7f3a9c1`
**IaC tool(s):** Terraform (`hashicorp/aws` v5.74.0, from the `terraform init` output)
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1050.md` (invoked inline — verdict: GREEN)
**Lane:** light — L1 every action is a create (`plan:42`: 1 to add, 0 to change, 0 to destroy); L2 `aws_cloudwatch_metric_alarm` create is on the allowlist; L3 one phase for the one environment, no drift row, duplicate check not done; L4 E1 pass (`alarm_actions` and `ok_actions` are the SNS ARN `arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod`, `plan:10`, `plan:26`), E2 pass (keys `Service`, `Environment`: no IAM tag condition in the repo; both keys already on every existing resource), E3 no (R8: SNS subscriptions are all `email`; nothing reads the alarm). The dev lane was not available: the tier is not proven.
**Escalations:** none
**Environment tier:** prod=prod (operator-stated, unproven: no `allowed_account_ids`, account variable or `assume_role` pin in the repo; identity `123456789012` / `paymentapi-operator` read at 10:01 matches the account in `code: envs/prod.tfvars:6-8`, which is not a pin) → prod gate levels
**Staging-first:** n/a — no staging env (`code: envs/prod.tfvars` is the only environment file; no staging var-file, workspace, backend or overlay in the repo; `variables.tf:2` names `staging` only as an example value)
**Waived:** none

## Research Summary
- Catalog used: none — `.culiops/service-discovery/paymentapi.md` does not exist; suggested running service-discovery for a fuller picture.
- Duplicate check: **not done.** `git grep -F` for `aws_cloudwatch_metric_alarm` and `CPUUtilization` over every file: no hit (only `main.tf:3`, a comment that says the alarm is absent). `git log --all -S'aws_cloudwatch_metric_alarm'` and `-S'CPUUtilization'`: no commits. `git branch -a --list '*alarm*'`: none. `gh pr list --state open --search 'paymentapi alarm'`: none. No ticket key was given. Live: no alarm on the service CPU metric, none under prefix `paymentapi`, none named `paymentapi-cpu-high-prod` (R10-R13).
- Delivery model: CI pipeline applies on merge (`UNVERIFIED` in the repo: no CI, Atlantis, Spacelift or GitOps file in the tree; operator-stated at `[A]`). PR path only.
- Env selection: var-file `envs/prod.tfvars` (the only one), default workspace (operator-stated). No `terraform {}` or backend block in the repo, so the state backend is not shown in code.
- Target check: identity read 10:01 (re-checked 10:41 and by pre-flight at 10:48, identical): account 123456789012, role `paymentapi-operator`, region `ap-southeast-1` (`code: envs/prod.tfvars:2`). No mismatch.
- Drift: refresh-only plan (R2, 10:22): no changes. Drift rows: 0.
- Key findings: the service is healthy (3 of 3 running, 3 of 3 targets healthy, nothing firing); CPU average 34.8-41.2 percent, max 51.2, so the 80 percent threshold has headroom.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| ECS cluster `paymentapi-cluster-prod` | `code: main.tf:9`, `code: envs/prod.tfvars:1` | `live: R3 (10:23)` service found, `ACTIVE`, 3 of 3 running | ✅ |
| ECS service `paymentapi-svc-prod` (alarm dimension) | `code: main.tf:72` | `live: R3 (10:23)` | ✅ |
| SNS topic `paymentapi-alerts-prod` (alarm action) | `code: main.tf:174-175`, `code: outputs.tf:16-19` | `live: R7 (10:27)` TopicArn matches, 2 confirmed, 0 pending | ✅ |
| SNS subscriber protocols | `code: none` (no subscription resource in this repo) | `live: R8 (10:28)` `["email","email"]` | not managed here, not drift (R2 clean) |
| No alarm on the service CPU or under the new name | `code: none` | `live: R10-R13 (10:30-10:33)` all empty | ✅ |
| CPU headroom for the 80 percent threshold | `plan:38` (a plan proposal, not in the repo) | `live: R14 (10:34)` average 34.8-41.2, max 51.2 over 12 x 5 min | ✅ no revision needed |
| Alarm price | none | `live: R20 (10:40)` 0.10 USD per alarm metric month, `ap-southeast-1`, price list 2026-10-07 | ✅ |
| Delivery model | `code: none` | operator-stated: CI applies on merge | UNVERIFIED, operator-stated |

Drift rows: 0. Unverified rows: 1 (delivery model, operator-stated). Gaps: state backend not declared in the repo; no state-bucket read was possible.

## Change Plan
**Phase 1 of 1: Add CPU utilization alarm (prod)**
- Files: `main.tf` (append one resource block).
- Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`, `AWS/ECS` `CPUUtilization`, `ClusterName=paymentapi-cluster-prod`, `ServiceName=paymentapi-svc-prod`, Average greater than 80 for 3 x 300 s, `alarm_actions` and `ok_actions` = SNS topic `paymentapi-alerts-prod`, tags `Service`, `Environment`). Threshold and periods were the skill's proposal, approved at `[A]`.
- Blast radius: one new alarm; nothing references it; no change to the ECS service, task definition or SNS topic.
- Disruption: none (`code:` the diff only appends a block; `plan:42` confirms 1 to add, 0 to change, 0 to destroy).
- Rollback path: `git revert`, PR, CI apply removes the alarm. Reversible. Untested. No data store touched.
- Evidence: the table above.
- Success criteria: S1 `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled,actions:AlarmActions}'` → one alarm, `actionsEnabled` true, `actions` = the SNS topic ARN, `state` `OK` (CPU average is about 40 percent, under 80; `INSUFFICIENT_DATA` right after creation means wait one more period and read again). S2 `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1 --query '{metric:MetricAlarms[].AlarmName,composite:CompositeAlarms[].AlarmName}'` → nothing firing. S3 `terraform plan -input=false -var-file=envs/prod.tfvars` → `No changes.`
- Execution path: PR. Staging-first: (a) no staging env. Observation window: n/a. Branch: `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d`. Self-check 8/8. Drift: none. L2 answers and delivery model taken at `[A]`.

## Execution Log
### Phase 1: Add CPU utilization alarm (prod)
- Files changed: `main.tf` (+27 lines, 0 removed; block at lines 182-208)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89
- Parity check: n/a
- Pre-flight verdict: GREEN — no Yellow or ⚪ finding, so no mitigation to commit; acknowledged by approving `[B]` (operator, 10:57)
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142 (branch `iac-change/paymentapi-cpu-high-alarm`, commit `7f3a9c1`, pushed 10:59). Staged by explicit path: `main.tf`. Nothing applied by this skill.
- Verification: not run — the apply has not landed (CI applies on merge). S1-S3 are approved and wait for the operator's word that the apply landed.

## Outcome
completed

**Applied:** no — PR open

## Ticket Reference
none
