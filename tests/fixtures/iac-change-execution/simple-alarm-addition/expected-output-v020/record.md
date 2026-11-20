# Record the skill would write to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1112.md`

**IaC change execution for:** `paymentapi` / `none (single environment)`
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi in prod. (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`, `paymentapi-cpu-high-prod`: ECS `CPUUtilization` Average above 80 for 3 x 300 s, alarm and ok actions to `paymentapi-alerts-prod`)
**Date:** `2026-11-09 11:12` (+07:00)
**Commit:** `7f3a9c1`
**IaC tool(s):** Terraform (AWS provider v5.74.0)
**Execution path:** PR (`https://github.com/acme/paymentapi-infra/pull/142`, branch `iac-change/paymentapi-cpu-high-alarm`)
**Pre-flight record:** `invoked inline — verdict: YELLOW` (record: `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1101.md`; no earlier record existed to reuse)
**Lane:** light — L1 plan 1 add / 0 change / 0 destroy (`plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_high create`); L2 `aws_cloudwatch_metric_alarm` create is allowlist row 1; L3 one phase, one environment, no drift row, duplicate check not done; L4 E1 `alarm_actions` and `ok_actions` are the SNS topic ARN, E2 keys `Service` / `Environment` cleared after reading every hit, E3 no
**Escalations:** none
**Environment tier:** prod=prod (operator-stated at `[A]`, 10:34; no account pin in code, so unproven and at prod gate levels; `live:` identity 123456789012 / `paymentapi-operator`, 10:01 and 10:48)
**Staging-first:** n/a — no staging env (code: `envs/prod.tfvars` is the only environment file; no staging var-file, workspace or overlay)
**Waived:** none

## Research Summary

- Catalog: none — proceeding without catalog (service-discovery not run).
- Duplicate check: **not done** — `code:` no hit for `CPUUtilization`, `aws_cloudwatch_metric_alarm`, `paymentapi-cpu-high` in any file (3 greps); `git:` no commit added or removed `CPUUtilization` or `paymentapi-cpu-high` (2 `git log -S`); no branch `*cpu*`; no open PR for the alarm (`gh pr list`). No ticket key. (`main.tf:3-4` has a comment that the alarm is intentionally absent: code-comment text, not used as evidence.)
- Delivery model: `UNVERIFIED` in the repo (no CI, GitOps, Atlantis / TFC / Spacelift config); operator-stated at `[A]`: a CI pipeline applies on merge; corroborated by `live: gh run list` (10:46): a push-triggered `terraform-apply` run on `main` succeeded 2026-11-06 11:31 +07. Env selection: `-var-file=envs/prod.tfvars`, default workspace (`code: envs/prod.tfvars:1`).
- Target check: `live: aws sts get-caller-identity` (10:01, re-checked at 4a 10:48 and by pre-flight 11:00): account 123456789012, `assumed-role/paymentapi-operator`, region `ap-southeast-1` (`code: envs/prod.tfvars:2`).
- Output root: `.culiops/` at the repo root (`CULIOPS_HOME` not set). Operator profile `~/.culiops/operator.md` read: Q5 terraform experienced, Q4 `acme/paymentapi-infra/paymentapi` many times (both 2026-10-19). No freeze calendar, no incident command. Nothing saved to the profile.
- Drift: none (`live: terraform plan -refresh-only -var-file=envs/prod.tfvars`, 10:36: "No changes").
- Key findings: topic `paymentapi-alerts-prod` exists with 2 confirmed `email` subscriptions (notify-only, so the alarm is not-app-facing); service 3/3 running, steady, nothing firing; the load balancer in front (`paymentapi-alb-prod`) is not in this repo.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| CPU alarm for the service | `code: none` (greps at 10:06-10:08) | `live: describe-alarms-for-metric` -> none (10:42); `describe-alarms --alarm-name-prefix paymentapi` -> none (10:43) | ✅ absent in both |
| SNS topic `paymentapi-alerts-prod` | `code: main.tf:174-175` | `live: sns get-topic-attributes` -> exists, 2 confirmed, 0 pending (10:40) | ✅ |
| Topic subscribers | `code: none` (no `aws_sns_topic_subscription`, grep 10:29) | `live: sns list-subscriptions-by-topic` protocols -> email, email (10:41) | ✅ notify-only |
| Service `paymentapi-svc-prod`, desired 3 | `code: envs/prod.tfvars:10`, `main.tf:72,94` | `live: ecs describe-services` -> ACTIVE, desired 3, running 3, 1 PRIMARY deployment COMPLETED (10:37, 10:54) | ✅ |
| Front door of the service | `code: none` (not in this repo) | `live: elbv2 describe-target-groups` -> `paymentapi-alb-prod` (10:38) | live only; not drift (not managed here) |
| Last apply | `code: none` (no backend block) | `live: gh run list` -> `terraform-apply` success 2026-11-06 11:31 +07 (10:46) | — |
| Delivery model | `UNVERIFIED` | `live: gh run list` -> push-triggered apply on `main` (10:46) | operator-stated, corroborated |
| Price of the new alarm | — | `live: aws pricing get-products` -> USD 0.10 per alarm metric month, `ap-southeast-1`, publication 2026-10-07, looked up 2026-11-09 (10:47) | — |

Drift rows: 0. Unverified rows: 0 (the delivery model is `operator-stated`). Not read: the Terraform state object `head-object` (no backend block, so no bucket or key; the CI history is the automation-lag source).

## Change Plan

**Phase 1 of 1: add the CPU alarm**
- Files: `main.tf`
- Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`
- Blast radius: the snapshot set — new alarm (n/a — no health signals of its own), ECS service `paymentapi-svc-prod` (`code: main.tf:71`), ALB `paymentapi-alb-prod` (`live:` `describe-target-groups`, 10:38). `Snapshot coverage: code + live reads of the service's front door; not covered: dependents and dependencies (skipped, not-app-facing change), callers in other repos, no catalog or runtime profile`
- Disruption: `none` — `plan:` create only, 1 add / 0 change / 0 destroy (4a, 10:49); no existing resource changes
- Rollback path: revert the PR; CI plans and applies the destroy of the alarm. Reversible; untested
- Evidence: rows above
- Success criteria:
  1. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,enabled:ActionsEnabled,actions:AlarmActions}'` -> one alarm, `enabled: true`, `actions: [arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod]`, state `OK` (`INSUFFICIENT_DATA` acceptable for the first 15 min, not `ALARM`)
  2. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod --region ap-southeast-1` -> a `ConfigurationUpdate` item "created"
  3. S2: `describe-alarms --state-value ALARM`, `ecs describe-services`, `elbv2 describe-target-health` -> nothing firing on the set, 3/3 running, 3 healthy (not-app-facing change: no metrics call, no two-period wait)

Execution path: PR. After merge a CI pipeline applies it (operator-stated). Values chosen by the skill because the request did not give them: threshold 80, Average, 3 x 300 s (basis: guess; shown at `[A]`, approved).

## Execution Log

### Phase 1: add the CPU alarm
- Files changed: `main.tf` (27 lines added after the SNS topic, lines 182-208; 0 removed)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` (`terraform show -no-color tfplan`)
- Parity check: n/a
- Pre-flight verdict: YELLOW — proceed with caution. One finding: category 5 timing ⚪ (apply at merge, Q3 unsure; busiest hours 14–18 +07 live). Mitigation proposed: merge outside that window or with the on-call on hand. Acknowledged by approving `[B]`, 11:08. Mitigations committed: none stated by the operator.
- Execution: PR `https://github.com/acme/paymentapi-infra/pull/142` opened at 11:11 (commit `7f3a9c1` `paymentapi: add CPU utilization alarm (prod)`, pushed to `iac-change/paymentapi-cpu-high-alarm`). Not merged. A CI pipeline applies on merge (operator-stated).
- Verification: not run — PR open, apply pending. The success criteria and S2 run once the operator says the apply has landed. No re-plan on the PR path.
- Snapshot: before 10:54–10:57 · after not read (PR open, apply pending) · n/a (no S2 yet)

## Health Snapshot

`Snapshot coverage: code + live reads of the service's front door; not covered: dependents and dependencies (skipped, not-app-facing change), callers in other repos, no catalog or runtime profile`

Members (cap 10; 3):
1. `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` — source `plan:` / `code: main.tf:185` — `n/a — no health signals of its own` (new alarm: no before state; judged by the success criteria)
2. ECS service `paymentapi-svc-prod` (cluster `paymentapi-cluster-prod`) — source `code: main.tf:71,8`, the alarm's dimensions
3. ALB `paymentapi-alb-prod`, target group `paymentapi-tg-prod` — source `code: main.tf:84-85,137-138` + `live: describe-target-groups` (10:38)

### prod — S0 (taken 10:37–10:45)

| Member | Signal | Before (now; same hour last week) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| paymentapi-svc-prod | alarms firing | 0 | — | — | `describe-alarms --state-value ALARM` | 10:44 |
| paymentapi-svc-prod | running vs desired | 3 / 3 (pending 0), 1 PRIMARY deployment COMPLETED | — | — | `ecs describe-services` | 10:37 |
| paymentapi-svc-prod | CPUUtilization (Average, hour) | 38.0 % (37.4 %) | — | — | `get-metric-data` (7 d hourly) | 10:45 |
| paymentapi-svc-prod | MemoryUtilization (Average, hour) | 52.0 % (51.5 %) | — | — | `get-metric-data` | 10:45 |
| paymentapi-alb-prod | alarms firing | 0 | — | — | `describe-alarms --state-value ALARM` | 10:44 |
| paymentapi-alb-prod | RequestCount (Sum, hour) | 41,442 (40,827) | — | — | `get-metric-data` | 10:45 |
| paymentapi-alb-prod | HTTPCode_Target_5XX_Count | 0 (0) | — | — | `get-metric-data` | 10:45 |
| paymentapi-alb-prod | HTTPCode_ELB_5XX_Count | 0 (0) | — | — | `get-metric-data` | 10:45 |
| paymentapi-alb-prod | TargetResponseTime p95 | 0.114 s (0.116 s) | — | — | `get-metric-data` | 10:45 |
| paymentapi-alb-prod | HealthyHostCount / UnHealthyHostCount (Minimum) | 3 / 0 (3 / 0) | — | — | `get-metric-data` | 10:45 |
| paymentapi-alb-prod | target health | 3 of 3 healthy | — | — | `elbv2 describe-target-health` | 10:39 |

Peak hours (Q3 on the PR path), from the 7-day hourly `RequestCount`, buckets mapped to the clock hour holding most of them: 14–18 (+07; 07–11 UTC); weekday hourly averages 57k–61k in those hours, 44k at 18, 47k at 13 (`live: get-metric-data`, 10:45).

### prod — S1 (a fresh read: S0's oldest read was 17 minutes old at 10:54; taken 10:54–10:57)

| Member | Signal | Before (now; same hour last week) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| paymentapi-svc-prod | alarms firing | 0 | — | — | `describe-alarms --state-value ALARM` | 10:56 |
| paymentapi-svc-prod | running vs desired | 3 / 3 (pending 0), 1 PRIMARY deployment COMPLETED | — | — | `ecs describe-services` | 10:54 |
| paymentapi-svc-prod | CPUUtilization (Average, hour) | 38.0 % (37.4 %) | — | — | `get-metric-data` (7 d hourly) | 10:57 |
| paymentapi-svc-prod | MemoryUtilization (Average, hour) | 52.0 % (51.5 %) | — | — | `get-metric-data` | 10:57 |
| paymentapi-alb-prod | alarms firing | 0 | — | — | `describe-alarms --state-value ALARM` | 10:56 |
| paymentapi-alb-prod | RequestCount (Sum, hour) | 41,442 (40,827) | — | — | `get-metric-data` | 10:57 |
| paymentapi-alb-prod | HTTPCode_Target_5XX_Count | 0 (0) | — | — | `get-metric-data` | 10:57 |
| paymentapi-alb-prod | HTTPCode_ELB_5XX_Count | 0 (0) | — | — | `get-metric-data` | 10:57 |
| paymentapi-alb-prod | TargetResponseTime p95 | 0.114 s (0.116 s) | — | — | `get-metric-data` | 10:57 |
| paymentapi-alb-prod | HealthyHostCount / UnHealthyHostCount (Minimum) | 3 / 0 (3 / 0) | — | — | `get-metric-data` | 10:57 |
| paymentapi-alb-prod | target health | 3 of 3 healthy | — | — | `elbv2 describe-target-health` | 10:55 |

S1 is the "before" of the apply. No S2: the PR is open and the apply is pending, so no after value is claimed. Not-app-facing change: when S2 is read it covers alarms and point-in-time state only, with no metrics call and no two-period wait.

## Outcome

completed (the skill's work on the PR path: the PR is open; no apply has run)

**Applied:** no — PR open

## Ticket Reference

none
