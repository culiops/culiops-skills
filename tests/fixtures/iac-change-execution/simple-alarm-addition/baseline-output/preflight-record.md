**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Add CloudWatch CPU utilization alarm `paymentapi-cpu-high-prod` (Terraform, 1 resource added)
**Date:** `2026-11-09 11:32` (+07:00, dry-run clock)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`, this change's own edit)
**Target:** `123456789012 / ap-southeast-1` | none | var-file `envs/prod.tfvars`, default workspace, backend key unknown (no `backend` block in the repo)
**Plan hash:** `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (plan made with `terraform plan -out=tfplan -var-file=envs/prod.tfvars`)
**Delivery model:** CI applies on merge (`operator-stated`; nothing in the repo shows how changes are applied)
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** `not needed — only not-app-facing attributes changed` (the alarm is notify-only per `live:2`; Q8 was answered "(c) not available" before L3 settled it)

## Verdict: GREEN

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One new resource in one region; nothing existing is edited | `plan: Plan: 1 to add, 0 to change, 0 to destroy` | — |
| 2 | Reversibility | 🟢 | Pure addition, no in-place attribute change. Rollback is revert, plan, apply; it removes only the alarm | `plan:` (create only) | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in the last 7 days; no open PR; last ECS deployment 2026-10-12 (28 days ago, under the 90-day lag threshold) | `git: git log --since=7.days` (empty), `live:3`, `operator-stated` (applied recently) | — |
| 4 | Dependency impact | 🟢 | No catalog. Every changed resource is not-app-facing (notify-only alarm) and the plan changes no output or export | `plan:`, `live:2`, `code: outputs.tf` unchanged | — |
| 5 | Timing context | 🟢 | No incident, no freeze, not peak: request rate 3,400 to 3,511 per 5 min, 1.00 times the same hour last week | `operator` Q1 Q2, `operator-stated` Q3, `live:10`, `live:11` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator` Q4 Q5 | — |
| 7 | Observability readiness | 🟢 | The change only adds not-app-facing monitoring; no alarm exists on `AWS/ECS CPUUtilization` for this service today | `plan:`, `live:13` | After apply, confirm the alarm leaves `INSUFFICIENT_DATA` |
| 8 | Cost impact | 🟢 | One standard alarm, `$0.10` per alarm metric month in ap-southeast-1 (price list publication 2026-10-07, looked up 2026-11-09) | `live:14`, `operator-stated` Q6 (negligible) | — |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access or audit-logging change | `plan:` | — |
| 10 | Resource health | 🟢 | 3 of 3 tasks running, one PRIMARY deployment COMPLETED, 3 of 3 targets healthy, no alarm firing; CPU Average up to 41.2, memory Average up to 54.2 (Maximum 64.2), both under 70 percent; target 5xx Sum 0 in 12 periods; response time Average 36 to 40 ms | `live:3`, `live:4`, `live:5`, `live:7`, `live:8`, `live:9`, `live:12`, `live: B6` (iac-change-execution Step 1) | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: the alarm's action is an SNS topic whose subscriptions are all `email` | `plan: only not-app-facing attributes changed (alarm, notify-only per live:2)` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Alarm dimensions point at the real cluster and service | `plan:` `ClusterName = paymentapi-cluster-prod`, `ServiceName = paymentapi-svc-prod`; `code: main.tf:9`, `main.tf:72` | iac-change-execution evidence table: `describe-services` 10:22 → same names, ACTIVE, 3 of 3 | ✓ |
| Alarm action target exists and only notifies | `plan:` `alarm_actions` and `ok_actions` = `arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod`; `code: main.tf:175` | `live:2` → 2 subscriptions, protocols `email`, `email` | ✓ |
| No alarm on this metric today | `code: none` | `live:13` → none; iac-change-execution `describe-alarms --alarm-name-prefix paymentapi` 10:23 → none | ✓ |
| No drift | `plan:` no "Objects have changed outside of Terraform" block | iac-change-execution `terraform plan -refresh-only` 10:21 → `No changes` | ✓ |
| Service saturation | n/a | `live:5` memory, iac-change-execution CPU read 10:24 | ✓ (under 70 percent) |

No drift rows. No UNVERIFIED facts remain, except those under Verification.

## Verification
- Citations checked: 7 (Green on categories 1, 2, 4, 7, 9, 10 and 11) (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 0; hard blocks checked: irreversible data change (cat 2), active incident with deploy freeze (cat 5), public exposure, encryption removal or secrets (cat 9), exhausted error budget (cat 10) → none triggered → GREEN
- Fresh eyes: not run — dry run
- Not verified: delivery model (`operator-stated`); Q3 peak and Q6 cost (`operator-stated`, each also backed by `live:10` / `live:11` and `live:14`); Q1 and Q2 (`operator` only); who is on hand at merge time (not asked; merge time is set by the operator); "applied recently" (`operator-stated`; `live:3` shows an ECS deployment 28 days ago, which is not proof of a Terraform apply); SNS endpoints (only protocols read, by design); latency and error rate have no separate week-ago baseline (last hour only)

## Hard Blocks
none

## Acknowledged Risks
none (all categories Green). Operator acknowledged the GREEN verdict and chose to proceed at pre-flight GATE 2 (11:32).

## Mitigations Committed
none required. Suggested after apply: confirm the new alarm leaves `INSUFFICIENT_DATA` (not committed to by the operator; no question was asked).

## Context Provided (L2)
- Q1 active incident: no (`operator`)
- Q2 deploy freeze: no (`operator`)
- Q3 peak traffic at apply time: no (`operator-stated`; CI applies at merge)
- Q4 changed this service before: many times (`operator`)
- Q5 used this IaC tool before: experienced (`operator`)
- Q6 expected cost impact: negligible (`operator-stated`)
- Q7 other context: none
- Q8 app source: (c) not available (unscripted default; moot after `live:2`)
- IaC question "applied successfully recently?": recent (`operator-stated`; unscripted default)
- Skipped, answered by L1 evidence: plan run and reviewed (plan hash passed by the caller), delivery model (caller's `operator-stated` answer), plan options (caller's command was `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, no `-target`, no `-refresh=false`)

## L1 Analysis Detail
Scanned: the plan text; `main.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`; git history of `main.tf` on `origin/main` for the last 7 days (none); open PRs (none); working-tree status (`main.tf` modified, this change's own edit). Catalog: none. Assessor `iac-change`: plan hygiene (no drift block, no `-target`, no `-refresh=false`, plan is not "No changes", no unexpected resources), blast radius (one add), reversibility (no in-place update), observability (adds monitoring only), cost (alarm add), security (nothing relevant), application compatibility (alarm treated as app-facing at L1 until subscriber protocols were read).

## L3 Queries Run
1. `aws sts get-caller-identity` → account `123456789012`, matches the target
2. `aws sns list-subscriptions-by-topic ... --query 'Subscriptions[].Protocol'` → `email`, `email`
3. `aws ecs describe-services ... deployments` → 1 deployment, PRIMARY, COMPLETED, created 2026-10-12, task definition `paymentapi-prod:12`
4. `aws ecs describe-services ... events[:10]` → 1 event, steady state reached, 2026-11-09T01:12:40Z
5. `aws cloudwatch get-metric-statistics ... MemoryUtilization` (1h) → Average 49.8 to 54.2, Maximum up to 64.2
6. `aws elbv2 describe-target-groups --names paymentapi-tg-prod` → behind internal load balancer `paymentapi-alb-prod`
7. `aws elbv2 describe-target-health` → 3 of 3 healthy
8. `aws cloudwatch get-metric-statistics ... HTTPCode_Target_5XX_Count` (1h) → Sum 0 in all periods
9. `aws cloudwatch get-metric-statistics ... TargetResponseTime` (1h) → Average 0.036 to 0.040 s
10. `aws cloudwatch get-metric-statistics ... RequestCount` (1h) → 3,400 to 3,511 per 5 min
11. `aws cloudwatch get-metric-statistics ... RequestCount` (same hour 7 days ago) → same values, ratio 1.00
12. `aws cloudwatch describe-alarms --state-value ALARM` → none firing
13. `aws cloudwatch describe-alarms-for-metric ... CPUUtilization` → none
14. `aws pricing get-products ... AmazonCloudWatch` → standard alarm `$0.10` per alarm metric month, ap-southeast-1, publication 2026-10-07
