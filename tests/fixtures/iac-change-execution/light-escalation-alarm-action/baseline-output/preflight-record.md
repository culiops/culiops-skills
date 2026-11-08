**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Add CloudWatch alarm `paymentapi-cpu-low-prod` (CPU below 20% for 3 x 5 min), wired like CPU-high: SNS alerts topic plus the existing scale-in policy
**Date:** `2026-11-09 11:43` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`, on branch `iac-change/paymentapi-add-cpu-low-alarm`)
**Target:** `333333333333 / ap-southeast-1` | no kube context | var-file `envs/prod.tfvars`, no workspace, no backend key declared
**Plan hash:** `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (after `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 2026-11-09 10:54)
**Delivery model:** CI applies on merge (`operator-stated`; no pipeline file in the repo)
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** `not available — category 11 ⚪` (Q8 answer: c)

## Verdict: RED — SOFT BLOCK

Escalation, not a single Red: 4 of 11 categories are Yellow or unknown (1, 4, 7, 11); 3 or more escalates. No hard block.

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One resource added in one region, but its action is the existing scale-in policy: when the alarm fires, desired count drops by 1 (live desired 3, floor min_capacity 2, so -33% capacity), one step per 300 s cooldown. Softeners: floor of 2, 3 of 3 targets healthy in two AZs, minimum healthy 100%. Disruption at apply: none (create only). What in-flight requests see when ECS stops a task is not established. | `plan:6-7,43`, `code:main.tf:212-230`, `live:S1-6`, `live:S1-7`, `live:3`, `live:8`, `docs: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html (read 2026-11-09, scaling stays within min/max capacity; cooldown limits repeat steps)` | Operator action: confirm 2 tasks is an acceptable floor at peak; after merge watch `describe-scaling-activities` for the first scale-in |
| 2 | Reversibility | 🟢 | Create only; no in-place attribute change and nothing on the one-way table. Rollback: revert the PR and CI deletes the alarm. A scale-in that already happened is not undone by a revert (desired count is under `ignore_changes`; CPU-high re-grows it). | `plan:6,43`, `code:main.tf:93-95` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` on `origin/main` in 7 days; no open PR; last ECS deployment 2026-10-12. Last successful apply not checked (no backend bucket or key in the repo). | `git log --since=7.days origin/main -- main.tf` (empty), `gh pr list --state open` (empty), `live:3` | — |
| 4 | Dependency impact | ⚪ | No catalog. The alarm's action scales the service, so it is app-facing and the not-app-facing exception does not apply. No consumer query exists for the alarm. | `assessor: Dependency impact (no catalog → ⚪, one exception)` | Evidence that would resolve it: run service-discovery to build a catalog, or confirm nothing (composite alarm, dashboard, automation) will reference `paymentapi-cpu-low-prod` |
| 5 | Timing context | 🟢 | No incident, no freeze (Q1, Q2). Not peak: 41,442 requests in the last hour against 41,442 for the same hour a week earlier, ratio 1.00, below 1.5x. Nothing firing. | `operator` (Q1, Q2), `operator-stated` (Q3, corroborated by `live:11`, `live:12`, `live:13`) | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform. | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | `paymentapi-cpu-high-prod` exists live and is enabled (state OK, `ActionsEnabled` true), but static CPU thresholds are the only alarm on the service. No SLO or burn-rate alert, no dashboard, no 5xx or healthy-host alarm in code. The new alarm is app-facing, so the "only adds not-app-facing monitoring" rule does not make this Green. | `code:main.tf:234-260`, `live:14` | After apply, confirm the new alarm leaves `INSUFFICIENT_DATA`; consider a 5xx or healthy-host alarm so a bad scale-in is detected |
| 8 | Cost impact | 🟢 | One standard alarm: 0.10 USD per alarm metric month in ap-southeast-1 (price list publication 2026-10-07, looked up 2026-11-09). A scale-in only removes Fargate task-hours; nothing is left billing. | `live:17`, `operator-stated` (Q6 negligible) | — |
| 9 | Security posture | 🟢 | No IAM, security group, encryption, public-access, audit or secret change. The actions point at the existing SNS topic and the existing scaling policy. | `plan:6-41` | — |
| 10 | Resource health | 🟢 | Nothing in ALARM. CPU average 39.8%, max 52.8%; memory average 53.8%, max 66% (both under 70%); target 5xx sum 0; target latency 36-40 ms; 3 of 3 targets healthy; ECS 3 of 3 running at steady state. CPU-high was in ALARM 2026-11-08 08:48Z to 09:03Z and scaled out to 3 (08:49Z); it is OK now. A Green here does not clear category 11. | `live:13`, `live:4`, `live:5`, `live:9`, `live:10`, `live:8`, `live:2`, `live:15`, `live:16`, `live:S1-4` | — |
| 11 | Application compatibility | ⚪ | Triggered: the alarm's action is an Application Auto Scaling policy ARN (plan:11), which the assessor lists as app-facing. Q8 answer (c): no application source, so the app's behaviour at 2 tasks instead of 3 (pool sizes, task-local state) was not read. Silent-breakage caution: a bad scale-in shows only as higher CPU, so health, error-rate and alarm signals stay green until saturation. | `plan:11`, `operator` (Q8) | Evidence that would resolve it: give the application source (a local path, or `owner/repo` and the deployed ref) |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| The only change is one alarm create | `plan:6-41,43` (1 to add, 0 to change, 0 to destroy) | — | ✓ |
| CPU-high alarm config and actions | `code:main.tf:234-260` | `live:S1-5` | ✓ |
| Scale-in policy -1, cooldown 300, no alarm drives it | `code:main.tf:212-230` | `live:S1-7` (`alarms: []`) | ✓ |
| Scale-in policy ARN in the plan equals the live ARN | `plan:11` | `live:S1-7` | ✓ |
| Scalable target min 2, max 6; scale-in not suspended | `code:main.tf:189-190` | `live:S1-6` | ✓ |
| Desired count 3 | `code:envs/prod.tfvars:11` | `live:S1-4` | ✓ |
| No drift | refresh-only plan | `live:S1-3` (no changes) | ✓ |
| Alarm `paymentapi-cpu-low-prod` does not exist yet | `git grep` (no hits) | `live:S1-5`, `live:14` | ✓ |

Drift rows: none. Unverified facts: the threshold 20 (the request gives none; the operator approved the proposal at GATE 1 of iac-change-execution); the drain behaviour of an ECS scale-in (no documentation read).

## Verification

- Citations checked: 12 (Green categories 2, 9, 10) plus 4 mitigation premises (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 4 (1, 4, 7, 11), 3 or more so the escalation applies; hard blocks checked: 2 irreversible data change (none), 5 incident plus freeze (none), 9 public exposure, encryption removal, secrets (none), 10 error budget exhausted (no SLO declared, nothing firing) → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model (`operator-stated`, no pipeline file in the repo); Q3 and Q6 (`operator-stated`, corroborated live); assessor Q4, last successful apply (`operator-stated: unsure`); merge time and who is on hand then (no question covers it); the threshold 20; ECS scale-in drain behaviour; the app's behaviour at 2 tasks (no source)

## Hard Blocks

none

## Acknowledged Risks

Acknowledged at pre-flight GATE 2 (2026-11-09 11:43), each with the stated reason "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged":
- Category 1 blast radius (Yellow)
- Category 4 dependency impact (⚪)
- Category 7 observability readiness (Yellow)
- Category 11 application compatibility (⚪)
- The multi-Yellow escalation to RED (soft block)

## Mitigations Committed

none stated by the operator at the gate. Offered, not committed: confirm the floor of 2 tasks and watch the first scale-in (1); service-discovery catalog or a check that nothing references the alarm (4); post-apply `INSUFFICIENT_DATA` check and a 5xx or healthy-host alarm (7); provide the application source (11).

## Context Provided (L2)

1. Active incident: no (`operator`)
2. Deploy freeze or change window: no (`operator`)
3. Peak traffic at the expected apply time: no (`operator-stated`; with CI the apply happens at merge)
4. Changed this service before: many times (`operator`)
5. Used this IaC tool before: experienced (`operator`)
6. Expected cost impact: negligible (`operator-stated`)
7. Other context: none (`operator`)
8. Application source: (c) not available (`operator`)

iac-change assessor questions (asked with proposed answers; operator replied "as proposed"):
1. Plan run and reviewed: yes (the plan was run by iac-change-execution and shown)
2. Delivery: CI pipeline applies on merge (`operator-stated`)
3. `-target`, `-refresh=false` or non-default workspace / var-file: no (`terraform plan -out=tfplan -var-file=envs/prod.tfvars`)
4. Applied successfully recently: unsure (`operator-stated`)

## L1 Analysis Detail

Plan text: one resource, `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` created (plan:6-41); `Plan: 1 to add, 0 to change, 0 to destroy.` (plan:43). No "Objects have changed outside of Terraform" block; the refresh-only plan at 10:21 found no drift. Plan made without `-target` or `-refresh=false`. IaC code: `main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`. Catalog: none (`.culiops/service-discovery/` absent). Git history: no commit to `main.tf` in 7 days on `origin/main`; no open PR; this change's own edit is the only uncommitted change. Changed attributes marked app-facing: `alarm_actions` (carries an Application Auto Scaling policy action). Not-app-facing: tags, description.

## L3 Queries Run

Run after the target check (account 333333333333 matched the plan's target). No secret values fetched.

1. `aws sts get-caller-identity --query Account --output text` → 333333333333
2. `aws ecs describe-services ... events[:10]` → one event, "has reached a steady state" (2026-11-09 01:12Z)
3. `aws ecs describe-services ... deploy + deployments` → circuit breaker off, maximum 200%, minimum healthy 100%; one PRIMARY deployment COMPLETED, created 2026-10-12
4. CPUUtilization, last hour → average 37.2 to 42.8 (mean 39.8), maximum up to 52.8
5. MemoryUtilization, last hour → average 52 to 56 (mean 53.8), maximum up to 66
6. `aws elbv2 describe-target-groups --names paymentapi-tg-prod` → target group on `paymentapi-alb-prod`, health check `/healthz`
7. `aws elbv2 describe-load-balancers ...` → internal application load balancer, active
8. `aws elbv2 describe-target-health ...` → 3 targets, all healthy (2 in ap-southeast-1a, 1 in ap-southeast-1b)
9. HTTPCode_Target_5XX_Count (Sum), last hour → 0 in every window
10. TargetResponseTime (Average), last hour → 0.036 to 0.040 s
11. RequestCount, last hour → 41,442
12. RequestCount, same hour a week earlier → 41,442 (ratio 1.00)
13. `aws cloudwatch describe-alarms --state-value ALARM` → none firing
14. `aws cloudwatch describe-alarms-for-metric` (AWS/ECS CPUUtilization of the service) → `paymentapi-cpu-high-prod`, OK, actions enabled
15. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod` → ALARM 2026-11-08 08:48Z to OK 09:03Z; ALARM 2026-11-05 05:02Z to OK 05:17Z
16. `aws application-autoscaling describe-scaling-activities` → 2026-11-08 08:49Z desired count set to 3 by CPU-high via the scale-out policy, Successful
17. `aws pricing get-products` (CloudWatch standard alarm, ap-southeast-1) → 0.10 USD per alarm metric month, publication 2026-10-07, looked up 2026-11-09

Queries cited as `live:S1-<n>` come from the iac-change-execution Step 1 batch (2026-11-09 10:19 to 10:25): 1 identity, 2 terraform init, 3 refresh-only drift plan, 4 ECS desired/running/pending (3, 3, 0), 5 alarm list by prefix, 6 scalable targets (min 2, max 6), 7 scaling policies.
