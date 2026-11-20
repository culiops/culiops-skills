**IaC change execution for:** `paymentapi` / none
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi in prod.
**Date:** `2026-11-09 11:10`
**Commit:** `7f3a9c1`
**IaC tool(s):** Terraform (hashicorp/aws v5.74.0)
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1100.md` (invoked inline — verdict: YELLOW — PROCEED WITH CAUTION)
**Lane:** light — L1 create only (`plan:` 1 add, 0 change, 0 destroy); L2 `aws_cloudwatch_metric_alarm` create is on the allowlist; L3 one phase, no drift row, duplicate check not done; L4 E1, E2, E3 pass on the diff and again on the plan; no proven dev target
**Escalations:** none
**Environment tier:** prod=prod (operator-stated, `[A]` 10:34; no pin in the repo, so unproven; identity `live:` 123456789012 `assumed-role/paymentapi-operator`, 10:01)
**Staging-first:** n/a — no staging env (`code:` `envs/prod.tfvars` is the only environment file)
**Waived:** none

Prerequisites listed for the examples file used: `examples/aws.md` — AWS CLI v2; read-only role (Tier 1: `Describe*`, `List*`, `Get*`, `cloudwatch:GetMetricData`, `cloudwatch:DescribeAlarms`); no Tier 2 mutation by the skill (the CI pipeline applies after merge); `GetMetricData` is billed per metric requested.

## Research Summary
- Catalog used: none — no `.culiops/service-discovery/paymentapi.md`; proceeded without it.
- Duplicate check: not done — no hits for `paymentapi-cpu-high`, `paymentapi_cpu_high`, `aws_cloudwatch_metric_alarm`, `CPUUtilization` in any env (`code:` greps 10:05-10:08); no history hits (`git: log -S`, 10:09-10:10); no in-flight branch (10:11) or open PR (10:12).
- Delivery model: CI applies on merge — UNVERIFIED in the repo (no CI config, `code:` grep 10:13); operator-stated at `[A]` (10:34). `live:` `gh run list` (10:43) shows a `terraform-apply` run on push to `main`, success 2026-11-06 11:31 +07:00.
- Env selection: `-var-file=envs/prod.tfvars`, default workspace (`code: envs/prod.tfvars:1`, `code: variables.tf:1-34`).
- Target check: account 123456789012, `assumed-role/paymentapi-operator`, `ap-southeast-1` (`live: aws sts get-caller-identity`, 10:01 and 10:47; region `code: envs/prod.tfvars:2`). Same identity at both reads.
- Operator profile: not found (10:02). Q4 and Q5 were asked at `[A]` and saved to `~/.culiops/operator.md` (Q5 terraform=experienced, Q4 acme/paymentapi-infra/paymentapi=many times, both 2026-11-09). Freeze source: none in the repo. Incident command: none.
- Alarm values: not in the request; `guess` (no repo precedent): Average CPUUtilization > 80 for 3 x 300 s, actions and OK actions to `aws_sns_topic.paymentapi_alerts` (`code: main.tf:174`); operator confirmed by approving `[A]`. Context: 7-day hourly CPU range 14.0-57.3 % (`live:` 10:39).
- Snapshot set and coverage: see Health Snapshot.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| Alarm `paymentapi-cpu-high-prod` does not exist | `code: none` | `live: aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` -> none (10:40) | ✅ absent in both |
| No alarm on the service's CPU metric | `code: none` | `live: aws cloudwatch describe-alarms-for-metric …` -> none (10:41) | ✅ |
| ECS service `paymentapi-svc-prod` desired 3 | `code: envs/prod.tfvars:10`, `code: main.tf:71-72` | `live: aws ecs describe-services …` -> desired 3, running 3 (10:35) | ✅ |
| Service sits behind target group `paymentapi-tg-prod` | `code: main.tf:84-88` | `live: aws ecs describe-services …` loadBalancers (10:35); `live: aws elbv2 describe-target-groups` -> ALB `paymentapi-alb-prod` (10:36) | ✅ |
| Alert topic subscribers | `code: main.tf:174-175` (no subscription resource in code) | `live: aws sns list-subscriptions-by-topic … Protocol` -> email, email (10:42) | ✅ (subscriptions live outside this repo) |
| Stack matches the code | — | `live: terraform plan -refresh-only` -> No changes (10:46) | ✅ |

Drift rows: 0. Unverified rows: 0. Code-only rows: 0.

## Change Plan

**Phase 1 of 1: add the CPU alarm**
- Files: `main.tf`
- Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`); `plan:` 1 add, 0 change, 0 destroy (`plan-prod.txt:42`)
- Blast radius: the snapshot set (the alarm, `paymentapi-svc-prod`, `paymentapi-alb-prod`), coverage line in Health Snapshot
- Disruption: `none` — `plan:` create only; the alarm changes no running resource
- Rollback path: reversible — `git revert`, then plan and apply through the same reviewed path (`code:` pure addition); untested
- Evidence: the six rows above
- Success criteria: (1) `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actions:ActionsEnabled}'` -> one alarm, actions true, state `OK` or `INSUFFICIENT_DATA`; (2) `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue}'` -> only `paymentapi-cpu-high-prod`; (3) `terraform plan -var-file=envs/prod.tfvars` -> `No changes.`; (4) S2: `describe-alarms --state-value ALARM`, `describe-services` (3/3), `describe-target-health` (3 healthy); not-app-facing change, no metrics call and no two-period wait

Execution path: PR. Staging-first: (a) no staging env. Observation window: n/a. Branch: `main` -> `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d`. Plan self-check 8/8.

## Execution Log
### Phase 1: add the CPU alarm
- Files changed: `main.tf` (+27 lines: section header and the `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` block at `main.tf:182-208`)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89`
- Parity check: n/a
- Pre-flight verdict: YELLOW — one ⚪ (timing context, category 5: Q3 unsure, apply at merge, peak hours 14-18 +07:00); mitigation: merge outside that window or with the service owner on hand, and confirm the alarm leaves `INSUFFICIENT_DATA` after the apply; acknowledged by approving `[B]` (operator, 11:07)
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142 (branch `iac-change/paymentapi-cpu-high-alarm`, commit `7f3a9c1`, pushed 11:09). Merge and apply by the CI pipeline: pending.
- Verification: not run — PR open, apply pending. Success criteria 1-4 and S2 run after the operator says the apply has landed. Re-plan not run.
- Snapshot: before 10:58 (S1; S0 10:35-10:39) · after not taken (PR open, apply pending) · n/a (no after value claimed)

## Health Snapshot

Snapshot coverage: code + live reads; not covered: callers outside this repo (no catalog, no runtime profile).

Members:
- `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` — source `plan:` — n/a — new resource, no before state
- `paymentapi-svc-prod` (ECS service) — source `code: main.tf:71-72`
- `paymentapi-alb-prod` (ALB in front) — source `live: aws elbv2 describe-target-groups` (10:36), `code: main.tf:84-88`
No dependents or dependencies: not-app-facing change (`snapshot.md` › Snapshot set). Not snapshotted — over cap: none.

### prod — S0 (10:35-10:39)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| `paymentapi-svc-prod` | running vs desired | 3 / 3, deployment PRIMARY COMPLETED | — | — | `aws ecs describe-services …` | 10:35 |
| `paymentapi-alb-prod` | targets healthy | 3 healthy (3 of 3) | — | — | `aws elbv2 describe-target-health …` | 10:37 |
| set (region) | alarms firing | 0 | — | — | `aws cloudwatch describe-alarms --state-value ALARM …` | 10:38 |
| `paymentapi-alb-prod` | request count | 41,442 per h (1w ago 40,827) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |
| `paymentapi-alb-prod` | target 5xx count | 0 (1w ago 0) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |
| `paymentapi-alb-prod` | ELB 5xx count | 0 (1w ago 0) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |
| `paymentapi-alb-prod` | p95 response time | 0.114 s (1w ago 0.116 s) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |
| `paymentapi-alb-prod` | healthy / unhealthy hosts (min) | 3 / 0 (1w ago 3 / 0) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |
| `paymentapi-svc-prod` | CPU (average) | 38.0 % (1w ago 37.4 %) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |
| `paymentapi-svc-prod` | memory (average) | 52.0 % (1w ago 51.5 %) | — | — | `aws cloudwatch get-metric-data …` | 10:39 |

### prod — S1 (10:55-10:58)

S0 was 19 minutes old at 10:54 (oldest read 10:35), over 15, so S1 is its own read, not a reuse.

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| `paymentapi-svc-prod` | running vs desired | 3 / 3, deployment PRIMARY COMPLETED | — | — | `aws ecs describe-services …` | 10:55 |
| `paymentapi-alb-prod` | targets healthy | 3 healthy (3 of 3) | — | — | `aws elbv2 describe-target-health …` | 10:56 |
| set (region) | alarms firing | 0 | — | — | `aws cloudwatch describe-alarms --state-value ALARM …` | 10:57 |
| `paymentapi-alb-prod` | request count | 41,442 per h (1w ago 40,827) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |
| `paymentapi-alb-prod` | target 5xx count | 0 (1w ago 0) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |
| `paymentapi-alb-prod` | ELB 5xx count | 0 (1w ago 0) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |
| `paymentapi-alb-prod` | p95 response time | 0.114 s (1w ago 0.116 s) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |
| `paymentapi-alb-prod` | healthy / unhealthy hosts (min) | 3 / 0 (1w ago 3 / 0) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |
| `paymentapi-svc-prod` | CPU (average) | 38.0 % (1w ago 37.4 %) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |
| `paymentapi-svc-prod` | memory (average) | 52.0 % (1w ago 51.5 %) | — | — | `aws cloudwatch get-metric-data …` | 10:58 |

### prod — S2

No S2 yet (PR open, apply pending): S0 and S1 only, and no after value is claimed.

Snapshot commands added to the batch for prod: 4 per snapshot read (one alarms read, one `get-metric-data` call, one ECS state read, one ALB target-health read), plus one membership read (`describe-target-groups`, once). S0 and S1 each ran the 4; the S2 form (alarms, ECS state, target health; no metrics call) is planned.

## Outcome
completed

**Applied:** no — PR open

## Ticket Reference
none
