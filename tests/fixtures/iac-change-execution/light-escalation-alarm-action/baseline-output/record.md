**IaC change execution for:** `paymentapi` / `prod`
**Change:** Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one (`aws_cloudwatch_metric_alarm.paymentapi_cpu_low`, alarm `paymentapi-cpu-low-prod`)
**Date:** `2026-11-09 12:08`
**Commit:** `7f3a9c1` (on branch `iac-change/paymentapi-add-cpu-low-alarm`, from `origin/main` @ `a1b2c3d`)
**IaC tool(s):** Terraform (`required_version >= 1.5.0`, `hashicorp/aws ~> 5.0`; provider v5.74.0 per `terraform init`)
**Execution path:** PR (https://github.com/acme/paymentapi-infra/pull/142); applied on merge by the CI pipeline (`operator-stated`)
**Pre-flight record:** `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1143.md` (invoked inline, verdict: RED — soft block, acknowledged)

**Prerequisites (examples/aws.md):** AWS CLI v2 (`aws --version` >= 2.x; version not read in this run). Authentication: assumed role `paymentapi-operator` in account 333333333333. IAM: Tier 1 read-only (Steps 1 and 5, `Describe*`, `List*`, `Get*`, `cloudwatch:GetMetricStatistics`) was used for every read in this run. Tier 2 (mutation) was not used: the PR path applies nothing, CI applies on merge. Cost awareness: CloudWatch `GetMetric*` calls incur small per-call charges (6 `get-metric-statistics` calls were made in pre-flight L3).

## Research Summary

- Catalog: none (`.culiops/service-discovery/paymentapi.md` absent); service-discovery suggested.
- Duplicate check: **not done**. `code:` no hit for `cpu-low` or `cpu_low` in any file (git grep 10:01-10:03); only `scale_in` hits are the policy itself (`main.tf:213-214`), so nothing references it. `git:` `git log --all -S'cpu-low'` and `-S'cpu_low'` empty. No branch, no open PR (`gh pr list --state open --search 'cpu-low'`: none).
- Delivery model: CI applies on merge (`operator-stated`: no CI config, GitOps object or plan automation in the repo). Environment selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1-3`, `code: providers.tf:12-13`).
- Target check: `aws sts get-caller-identity` at 10:19 and again at 10:48 → account 333333333333, role `paymentapi-operator`; region ap-southeast-1 (`code: envs/prod.tfvars:2`); match with `aws_account_id` (`code: envs/prod.tfvars:3`): yes.
- Drift: none (`terraform plan -refresh-only` at 10:21: no changes). Gaps: the threshold value is not in the request.
- Key findings: the scale-in policy exists and no alarm drives it (`code: main.tf:212-230`, `live: describe-scaling-policies` 10:25: `alarms: []`).

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| `paymentapi-cpu-high-prod` config and actions | `code: main.tf:234-260` | `live: aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (10:23): same, state OK, actions enabled | match |
| `paymentapi-cpu-low-prod` does not exist | `code: none` | `live: describe-alarms --alarm-name-prefix paymentapi` (10:23): only CPU-high | match |
| Scale-in policy -1, cooldown 300, no alarm | `code: main.tf:212-230` | `live: aws application-autoscaling describe-scaling-policies` (10:25): same, `alarms: []` | match |
| Scale-out policy +1, cooldown 300 | `code: main.tf:193-210` | `live: describe-scaling-policies` (10:25): same, alarms `[paymentapi-cpu-high-prod]` | match |
| Scalable target min 2, max 6 | `code: main.tf:189-190` | `live: aws application-autoscaling describe-scalable-targets` (10:24): min 2, max 6, scale-in not suspended | match |
| Desired count 3 | `code: envs/prod.tfvars:11` | `live: aws ecs describe-services` (10:22): desired 3, running 3, pending 0 | match |
| Cluster and service names | `code: main.tf:9,72` | `live: describe-services` (10:22): service found | match |
| SNS topic exists | `code: main.tf:174-175` | `live: terraform plan -refresh-only` (10:21): no changes | match |
| Scale-in step cannot go below the floor | `code: main.tf:189` | `docs: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html` (read 2026-11-09: capacity changes within the target's min and max) | match |

Drift rows: 0. Unverified rows: 0. Unverified claims: the threshold 20 is a proposal (not in the request, approved at GATE 1); the drain behaviour of an ECS scale-in (no documentation read).

## Change Plan

**Phase 1 of 1: Add the CPU-low alarm that drives the existing scale-in policy**
- Files: `main.tf` (modify: new resource appended after `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`)
- Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_low`. 1 to add, 0 to change, 0 to destroy.
- Alarm values: `CPUUtilization`, `AWS/ECS`, dims cluster and service, `Average`, period 300, 3 evaluation periods, `LessThanThreshold` 20 (threshold proposed, mirroring the CPU-high layout). Actions: SNS alerts topic + `paymentapi_scale_in` policy; OK action: SNS alerts topic.
- Blast radius: the new alarm only. When it fires it triggers `paymentapi-scale-in-prod` (-1 task, cooldown 300 s), never below `min_capacity` 2. Live desired is 3, so at most one task is removed. Scale-out policy and CPU-high alarm unchanged.
- Disruption: none at apply (create only; confirmed by the plan: `+ create`, 1 to add). After the alarm fires, capacity drops by one task. In-flight request behaviour on scale-in: `UNVERIFIED`.
- Rollback path: reversible. `git revert` of the PR; CI plans and applies, which deletes the alarm. Does not undo a scale-in that already happened. Untested.
- Evidence: the table above.
- Success criteria (run after CI applies): `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-low-prod --query 'MetricAlarms[].{n:AlarmName,s:StateValue,a:ActionsEnabled,act:AlarmActions}'` returns the alarm, `a` true, `act` with the SNS topic and `...policyName/paymentapi-scale-in-prod`, `s` OK or INSUFFICIENT_DATA; `aws application-autoscaling describe-scaling-policies ... --query "ScalingPolicies[?PolicyName=='paymentapi-scale-in-prod'].Alarms[].AlarmName"` returns `["paymentapi-cpu-low-prod"]`; `terraform plan -var-file=envs/prod.tfvars` reports no changes.

**Execution path:** PR (CI applies on merge). **Branch:** `main` → `iac-change/paymentapi-add-cpu-low-alarm` from `origin/main` @ `a1b2c3d`. **Plan self-check:** 6/6.

## Execution Log

### Phase 1: Add the CPU-low alarm that drives the existing scale-in policy
- Files changed: `main.tf` (+30 lines, 0 removed)
- Self-check: plan 6/6 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types (the alarm's action scales the service, which the skip rule does not list)
- Plan output summary: 1 to add, 0 to change, 0 to destroy (`aws_cloudwatch_metric_alarm.paymentapi_cpu_low`)
- Plan hash: `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0`
- Pre-flight verdict: RED — soft block (4 of 11 categories Yellow or unknown: 1 blast radius, 4 dependency impact, 7 observability, 11 application compatibility; no hard block). Acknowledged at pre-flight GATE 2 and again at GATE 3, reason: "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged". No mitigation committed.
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142 (branch `iac-change/paymentapi-add-cpu-low-alarm`, commit `7f3a9c1` "paymentapi: add CPU-low alarm wired to scale-in policy"). Only `main.tf` staged. Nothing applied by this skill.
- Verification: not run. The success criteria need the apply, which CI performs after merge. No re-plan. The operator declined polling the PR checks.

## Outcome

partially completed: PR opened (phase 1 of 1 awaiting merge and apply)

**Applied:** no — PR open

## Ticket Reference

none
