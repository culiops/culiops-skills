**IaC change execution for:** `paymentapi` / `prod`
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi in prod
**Date:** `2026-11-09 11:57` (+07:00, dry-run clock)
**Commit:** `7f3a9c1` on `iac-change/paymentapi-cpu-high-alarm` (from `origin/main` @ `a1b2c3d`)
**IaC tool(s):** Terraform (AWS provider v5.74.0, from the `terraform init` output)
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1132.md` (invoked inline — verdict: GREEN)
**Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset)
**Prerequisites** (`examples/aws.md`): AWS CLI v2 (version not read in this run); authentication by a named profile, SSO, IAM role or STS credentials, identity confirmed with `aws sts get-caller-identity` (role `paymentapi-operator`, account `123456789012`); Tier 1 read-only access for Steps 1 and 5 (`Describe*`, `List*`, `Get*`, `cloudwatch:GetMetricStatistics`); Tier 2 mutation role not used by the skill on the PR path (CI applies on merge); CloudWatch `GetMetric*` calls carry small per-call charges.

## Research Summary

- Catalog used: none — `.culiops/service-discovery/paymentapi.md` does not exist (suggested running service-discovery first).
- Duplicate check: **not done** — `code:` no hit for `paymentapi-cpu-high`, `aws_cloudwatch_metric_alarm` or `CPUUtilization` in any file; `git:` `git log --all -S` finds no commit for either identifier; no in-flight branch (`git branch -a --list '*cpu*'`) and no open PR (`gh pr list --state open --search 'cpu alarm'`).
- Delivery model: CI applies on merge — `operator-stated` (nothing in the repo showed it: no CI config, GitOps object, Atlantis, Terraform Cloud or Spacelift file). Result: PR path only.
- Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1`, the only env file).
- Target check: `aws sts get-caller-identity` (2026-11-09 10:19 and 10:45) → account `123456789012`, role `paymentapi-operator`; region `ap-southeast-1` (`code: envs/prod.tfvars:2`); var-file `envs/prod.tfvars`. Plan is for prod: match yes.
- Key findings: no existing alarm on the service; no drift (`terraform plan -refresh-only`, `No changes`); CPU Average 34.8 to 41.2, Maximum up to 51.2 over the last hour, so the proposed threshold of 80 sits well above baseline; SNS topic live state was a gap at Step 1 and was settled by pre-flight L3 (`email`, `email` subscribers).

## Evidence

| Fact | Code evidence | Live evidence | Match |
|---|---|---|---|
| ECS cluster name | `code: main.tf:9`, `envs/prod.tfvars:1` → `paymentapi-cluster-prod` | `live: aws ecs describe-services` (10:22) → clusterArn ends `cluster/paymentapi-cluster-prod` | ok |
| ECS service name and state | `code: main.tf:72` → `paymentapi-svc-prod` | `live: aws ecs describe-services` (10:22) → ACTIVE, 3 of 3 running | ok |
| SNS alert topic | `code: main.tf:175` → `paymentapi-alerts-${var.env}` | Step 1: not read (UNVERIFIED). Settled in pre-flight L3 `aws sns list-subscriptions-by-topic` (11:15) → protocols `email`, `email` | ok (settled after Step 1) |
| Existing CPU alarm on the service | `code: none` | `live: aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (10:23) → none | ok (absent in both) |
| Drift on the stack | n/a | `live: terraform plan -refresh-only` (10:21) → `No changes` | no drift |
| Service CPU before the change | n/a | `live: aws cloudwatch get-metric-statistics` (10:24) → Average 34.8 to 41.2, Maximum up to 51.2 | baseline |

Drift rows: 0. Unverified rows at the end of Step 1: 1 (SNS topic, later settled). `code-only` rows: 0.

## Change Plan

**Phase 1 of 1: Add CPU utilization alarm for `paymentapi-svc-prod`** (approved at GATE 1, 10:33)
- Files: `main.tf` (modify; new section "CloudWatch alarm (CPU)" at the end)
- Resources affected: add 1: `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`, `AWS/ECS` `CPUUtilization`, `Average` greater than 80 for 3 periods of 300 s, alarm and OK actions to SNS `paymentapi-alerts-prod`). Threshold, periods and statistic were proposed by the skill and approved by the operator; the request did not give them.
- Blast radius: one new resource; no existing resource edited (`code: main.tf:9`, `main.tf:72`, `main.tf:175` are read by reference only).
- Disruption: none — `code:` add-only; confirmed by `plan:` at Step 4a (1 to add, 0 to change, 0 to destroy).
- Rollback path: reversible; revert the PR, then plan and apply the revert; deletes only the alarm and its state history. Untested.
- Evidence: the rows above.
- Success criteria:
  1. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{n:AlarmName,s:StateValue,a:ActionsEnabled}'` → one alarm, `n = paymentapi-cpu-high-prod`, `a = true`, `s` is `OK` or `INSUFFICIENT_DATA`
  2. `terraform plan -var-file=envs/prod.tfvars` → `No changes.`
- Execution path: PR only (CI applies on merge). Branch `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d`.

## Execution Log

### Phase 1: Add CPU utilization alarm for `paymentapi-svc-prod`
- Files changed: `main.tf` (+28 lines, 0 removed)
- Self-check: plan 6/6 · diff 6/6, no accepted failures
- Fresh eyes: skipped — add-only, no sensitive types (alarm add, `SKILL.md:268` rule)
- Plan output summary: 1 to add, 0 to change, 0 to destroy (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high` will be created)
- Plan hash: `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` (SHA-256 of `terraform show -no-color tfplan`)
- Pre-flight verdict: GREEN, no Red findings, no hard blocks, no acknowledged risks beyond "acknowledge and proceed" at pre-flight GATE 2 (11:32)
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142, commit `7f3a9c1`, branch `iac-change/paymentapi-cpu-high-alarm`, opened 11:52 after GATE 4 (11:49). Not merged.
- Verification: none run. The PR path was taken, CI applies on merge, and the operator declined polling the PR checks or pipeline status. Success criteria 1 and 2 are not run. Re-plan after apply: not applicable (nothing applied by this skill).

## Outcome

Completed through PR creation (phase 1 of 1). Apply is left to the CI pipeline after merge.

**Applied:** no — PR open

## Ticket Reference

none

## Operator decisions and offers (audit trail)

- Delivery model question (10:13): "A CI pipeline applies on merge" (`operator-stated`).
- Read batch (10:18): approved, 6 commands.
- GATE 1 (10:33): approved, PR path. GATE 2 (10:44): approved. Target check Proceed (10:50): yes.
- Pre-flight GATE 1 (10:59): confirmed. L2 (11:08): answered; L3 (11:13): yes. Pre-flight GATE 2 (11:32): acknowledged, proceed.
- GATE 3 (11:37): approved. `change-comms` heads-up offer (11:42): declined. GATE 4 (11:49): approved.
- Poll offer (11:57): declined. GATE 5 commit-the-record offer (12:02): declined, so this record is not committed. `change-comms` result / ticket-closing offer (12:07): declined.
