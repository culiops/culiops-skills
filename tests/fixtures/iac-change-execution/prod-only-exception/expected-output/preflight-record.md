Intended path: `.culiops/pre-flight/paymentapi-raise-cpu-alarm-threshold-20261109-1101.md` (not written into the fixture; this file stands in for it)

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Raise the prod CPU alarm threshold from 80 to 90 (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high[0]`, in-place update of `threshold` and `alarm_description`)
**Date:** `2026-11-09 11:01` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `envs/prod.tfvars`)
**Target:** `333333333333 / ap-southeast-1` | `n/a (no Kubernetes)` | `Terraform default workspace / -var-file=envs/prod.tfvars / no declared backend`
**Plan hash:** `sha256:a064ec4b3620da485122e4d49f64ae579797abc4bc9577a7f170869d85a3bd73` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** `a CI pipeline applies on merge` (`UNVERIFIED` in the repo: no CI file found; operator-stated at [F2], 10:43)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's results plus the target check)`
**App source:** `not needed — only not-app-facing attributes changed`

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One alarm, one account, one region. Disruption `none`: updating an alarm replaces its settings and re-evaluates its state; no task, target or traffic is touched. Not user-facing, not shared infrastructure | `plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_high[0] update in-place; Plan: 0 to add, 1 to change, 0 to destroy`; `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html (2026-11-09)`; `live: describe-alarms (caller, 10:18)` | — |
| 2 | Reversibility | 🟢 | In-place update of `threshold` and `alarm_description`. Rollback: revert the line, re-apply through the same CI path (minutes). Putting the earlier threshold back restores the earlier behaviour. The rollback has not been tried on this alarm | `plan: update in-place`; `code: envs/prod.tfvars:17`; `docs: PutMetricAlarm (2026-11-09)`; `assessor: Reversibility, rollback mechanisms (Terraform)` | — |
| 3 | Change velocity | 🟢 | 0 commits on `envs/prod.tfvars` in the last 7 days on `origin/main`; no open PR or branch for the same change; the working tree holds only this change | `git: git log --since=7.days origin/main -- envs/prod.tfvars` → none (11:01); `git: gh pr list` → none (10:10); `git: git status --short` → only `envs/prod.tfvars` | — |
| 4 | Dependency impact | 🟢 | The only changed resource is a notify-only alarm (not-app-facing) and no output or export changes, so nothing can depend on it. In code the alarm is referenced only by its own definition | `plan: 1 to change, no output change`; `code: main.tf:186`, `outputs.tf:1-19`; `assessor: Dependency impact, not-app-facing exception` | — |
| 5 | Timing context | 🟢 | Q1 no incident, Q2 no freeze (both `operator`). Q3 not peak (`operator-stated`), and the live request rate equals the same hour a week ago (3,400–3,511 per 5 minutes both windows, ratio 1.00, below 1.5x) | `operator: Q1, Q2`; `operator-stated: Q3`; `live: RequestCount last hour and T-7d (caller, 10:30, 10:31)` | Merge time is not known (CI applies on merge): merge when someone who can respond is on hand |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator: Q4, Q5` | — |
| 7 | Observability readiness | 🟢 | The change only edits not-app-facing monitoring and changes nothing app-facing. The alarm exists live, is enabled (`ActionsEnabled true`) and is in `OK`; nothing else is firing | `live: describe-alarms --alarm-names paymentapi-cpu-high-prod (caller, 10:18)`; `live: describe-alarms-for-metric (caller, 10:19)`; `live: describe-alarms --state-value ALARM (caller, 10:20)`; `assessor: Observability readiness` | After apply, confirm the alarm still shows `ActionsEnabled true` and `OK` (SC1) |
| 8 | Cost impact | 🟢 | No new resources, no size increase | `plan: 0 to add`; `operator-stated: Q6 negligible` | — |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access, audit-log or secret change. Alarm actions are unchanged | `plan: only threshold and alarm_description change`; `code: main.tf:204-205` | — |
| 10 | Resource health | 🟡 | CPU `Average` 43.4–48.3 percent but `Maximum` reached 71.4 and 74.0 percent in 2 of 12 five-minute periods in the last hour (above the 70 percent default). Memory `Average` 50–54, `Maximum` 64.0 percent. The alarm went to ALARM 4 times in the last 7 days (peaks 85, 86, 87, 88 percent, 15 minutes each). Nothing firing now; targets 3 of 3 healthy; 5xx Sum 0; latency `Average` 36–40 ms; ECS 3 of 3 running | `live: get-metric-statistics CPUUtilization (caller, 10:24)`; `live: MemoryUtilization (caller, 10:25)`; `live: describe-alarm-history (caller, 10:21)`; `live: describe-target-health (caller, 10:27)`; `live: HTTPCode_Target_5XX_Count (caller, 10:28)`; `live: TargetResponseTime (caller, 10:29)`; `live: describe-services (caller, 10:23)` | Operator action: after the CI apply, run SC1 and SC2 and watch CPU `Average` over the next business day. At 90 the alarm fires only after three 5-minute averages above 90, so a sustained 85–88 percent will not page. Decide whether a second, lower signal is wanted |
| 11 | Application compatibility | 🟢 | Only `threshold` and `alarm_description` change. The alarm's only actions are the SNS topic `paymentapi-alerts-prod`, whose two subscriptions are `email`, so it is notify-only and not-app-facing | `plan: only not-app-facing attributes changed (threshold, alarm_description of a notify-only alarm)`; `live: sns list-subscriptions-by-topic protocols → email, email (caller, 10:22)`; `code: main.tf:204-205` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| prod alarm threshold | `code: envs/prod.tfvars:17` → 80 | `live: describe-alarms (caller, 10:18)` → 80.0 | ✓ |
| alarm description | `code: main.tf:197` → "above 80% for paymentapi prod" | `live: describe-alarms` → "CPU utilization above 80% for paymentapi prod" | ✓ |
| alarm actions | `code: main.tf:204-205` → `aws_sns_topic.paymentapi_alerts.arn` | `live: describe-alarms` → `arn:…:paymentapi-alerts-prod`; `live: list-subscriptions-by-topic` → `email`, `email` | ✓ |
| drift | `plan: terraform plan -refresh-only -var-file=envs/prod.tfvars` → no changes | `live: (caller, 10:17)` | ✓ none |
| alarm state history | n/a | `live: describe-alarm-history (caller, 10:21)` → 4 ALARM episodes in 7 days | n/a |

No drift rows. Unverified facts are listed under Verification › Not verified.

## Verification
- Citations checked: 14 (fixed: none). Every Green on categories 1, 2, 4, 7, 9, 10 and 11 re-opened against its cited line or read; the `docs:` page is the one read at 10:35 in this session.
- Verdict working: Red = none; Yellow + ⚪ = 1 (category 10); hard blocks checked: cat 2 irreversible data change (no), cat 5 active incident plus freeze (Q1 no, Q2 no), cat 9 public exposure / encryption removal / secrets (none), cat 10 error budget exhausted (no SLO declared; nothing firing) → YELLOW — proceed with caution.
- Fresh eyes: not run — dry run
- Not verified: Q3 (peak traffic) is `operator-stated`, with the live request rate in line; the merge time is unknown because CI applies on merge, and on-call cover at merge time was not asked; `iac-change.4=recent` is `operator-stated` — the last apply could not be read (the repo declares no backend and shows no CI history), and the alarm's `AlarmConfigurationUpdatedTimestamp` of 2026-11-08T14:11Z equals its last state-update time, so it is read as the state change, not a config edit (inferred); the delivery model is `operator-stated` (no CI file in the repo); the Yellow on category 10 uses the `Maximum` statistic against the 70 percent default (the `Average` statistic, which is what the alarm uses, is below 50 percent); the caller's reads were taken 10:17–10:31, 30 to 44 minutes before this assessment; the rollback has not been tried on this alarm.

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate

## Context Provided (L2)
Taken from the caller block (`iac-change-execution`, `[F2]` answers, 10:43):
- Q1 active incident: no (`operator`, from caller)
- Q2 deploy freeze: no (`operator`, from caller)
- Q3 peak traffic at apply time: no (`operator-stated`, from caller)
- Q4 changed this service before: many times (`operator`, from caller)
- Q5 used this IaC tool before: experienced (`operator`, from caller)
- Q6 expected cost impact: negligible (`operator-stated`, from caller)
- Q7 other context: none (`operator`, from caller)
- iac-change.1 plan run and reviewed: yes (`operator`, from caller)
- iac-change.2 delivery: PR, and a CI pipeline applies on merge (`operator-stated`, from caller)
- iac-change.3 `-target` / `-refresh=false` / non-default workspace or var-file: no; default workspace, the env's own var-file (`operator`, from caller)
- iac-change.4 applied successfully recently: recent (`operator-stated`, from caller)
- Q8 not asked: no app-facing attribute changed.

## L1 Analysis Detail
Scanned the plan text (`Plan: 0 to add, 1 to change, 0 to destroy`; one in-place update, no "Objects have changed" block), `main.tf:186-211`, `variables.tf:74-78`, `outputs.tf`, `envs/prod.tfvars`. Git history: no commit on `envs/prod.tfvars` in the last 7 days; the three most recent commits on `main` are older than 30 days. No service-discovery catalog (`.culiops/service-discovery/paymentapi.md` does not exist). Staging evidence: n/a — no staging phase ran (exception (b), prod-only).

## L3 Queries Run
Target check by pre-flight: `aws sts get-caller-identity` (10:59) → account 333333333333 = caller `Target`; match.
The caller's results, cited as `live: <cmd> (caller, <time>)`:
1. `terraform plan -refresh-only -var-file=envs/prod.tfvars` (caller, 10:17) — no changes
2. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` (caller, 10:18) — Threshold 80.0, enabled, OK, actions → SNS `paymentapi-alerts-prod`
3. `aws cloudwatch describe-alarms-for-metric` (ECS CPU, prod) (caller, 10:19) — one alarm, OK, enabled
4. `aws cloudwatch describe-alarms --state-value ALARM` (caller, 10:20) — none firing
5. `aws cloudwatch describe-alarm-history paymentapi-cpu-high-prod` (caller, 10:21) — 4 ALARM episodes in 7 days, peaks 85 to 88 percent
6. `aws sns list-subscriptions-by-topic paymentapi-alerts-prod` protocols (caller, 10:22) — email, email
7. `aws ecs describe-services paymentapi-svc-prod` (caller, 10:23) — 3 of 3 running, min healthy 100, max 200, last deployment 2026-10-12
8. `aws cloudwatch get-metric-statistics CPUUtilization` (caller, 10:24) — Average 43.4–48.3, Maximum up to 74.0 percent
9. `aws cloudwatch get-metric-statistics MemoryUtilization` (caller, 10:25) — Average 50–54, Maximum up to 64.0 percent
10. `aws elbv2 describe-target-groups paymentapi-tg-prod` (caller, 10:26) — ALB `paymentapi-alb-prod`, `/healthz`
11. `aws elbv2 describe-target-health` (caller, 10:27) — 3 of 3 healthy
12. `aws cloudwatch get-metric-statistics HTTPCode_Target_5XX_Count` (caller, 10:28) — Sum 0
13. `aws cloudwatch get-metric-statistics TargetResponseTime` (caller, 10:29) — Average 36–40 ms
14. `aws cloudwatch get-metric-statistics RequestCount` last hour and same hour 7 days ago (caller, 10:30, 10:31) — 3,400–3,511 per 5 minutes in both
Not run: last-apply read (`aws s3api head-object`) — no declared backend, no state bucket or key to name.
