# Record the skill would write to `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1101.md`

**Pre-flight assessment for:** `paymentapi` / `none (single environment)`
**Action:** Add the CloudWatch CPU alarm `paymentapi-cpu-high-prod` (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`)
**Date:** `2026-11-09 11:01` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `123456789012 / ap-southeast-1` | `n/a` | `Terraform default workspace / -var-file=envs/prod.tfvars / no backend declared in code`
**Plan hash:** `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** `a CI pipeline applies on merge` (`UNVERIFIED` in the repo — operator-stated at the caller's `[A]`, 10:34; `live: gh run list` (caller, 10:46) shows a push-triggered terraform-apply run on main)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, answered by the caller's evidence) + L3 (live, the caller's reads)`
**App source:** `not needed — only not-app-facing attributes changed`

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One monitoring resource added in one region; no existing resource touched. Pure addition of an alarm: no behaviour claim needed | `plan:42` (1 to add, 0 to change, 0 to destroy), `plan:6-7` | — |
| 2 | Reversibility | 🟢 | Create only, no in-place attribute change. Rollback: revert the PR, CI plans and applies the alarm's destroy (minutes, nothing stateful is lost) | `plan:42`, `plan:6` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` on `main` in the last 7 days; last successful apply 2026-11-06 11:31 (about 3 days, under 90); no open PR for the same files | `code: git log --since=7.days --oneline origin/main -- main.tf` -> none (11:01), `live: gh run list (caller, 10:46)`, `live: gh pr list (caller, 10:12)` | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing (an alarm whose actions are an SNS topic with only `email` subscribers) and no output or export changes: nothing can depend on it | `plan:7-40`, `code: outputs.tf:1-19` (unchanged), `live: sns list-subscriptions-by-topic (caller, 10:41)` -> email, email | — |
| 5 | Timing context | ⚪ | Q1(alarms) no, Q1(declared) no, Q2 no. Q3 is `unsure`: the apply happens at merge, so who is on hand and whether it lands in the busy window is not established. Busiest hours of the last 7 days: 14–18 (+07; 07–11 UTC) | `live: get-metric-data (caller, 10:57)`, `live: describe-alarms --state-value ALARM (caller, 10:56)`, `operator (no objection at [A], 10:34)` | Merge outside 14–18 +07, or with the on-call on hand; then timing is known |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟢 | The change only adds not-app-facing monitoring and changes nothing app-facing, so nothing in it can break unnoticed. No CPU alarm exists live yet | `plan:6`, `live: describe-alarms-for-metric (caller, 10:42)` -> none | After the merge, confirm the new alarm leaves `INSUFFICIENT_DATA` (the plan's success criterion 1) |
| 8 | Cost impact | 🟢 | Alarms only; one standard alarm metric priced USD 0.10 per month in `ap-southeast-1` (publication 2026-10-07, looked up 2026-11-09) | `plan:42`, `live: aws pricing get-products (caller, 10:47)` | — |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access, audit-logging or secret change; the alarm publishes to the existing topic | `plan:8-40`, `code: main.tf:174` | — |
| 10 | Resource health | 🟢 | Nothing firing on the set; target 5xx 0 (week ago 0); p95 0.114 s (0.116 s); CPU 38.0 % (37.4 %) and memory 52.0 % (51.5 %), both under 70 %; 3 of 3 running and healthy; ECS in steady state | `live: aws ecs describe-services (caller, 10:54)`, `live: describe-target-health (caller, 10:55)`, `live: describe-alarms --state-value ALARM (caller, 10:56)`, `live: get-metric-data (caller, 10:57)` | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed (new alarm, notify-only: SNS action, `email` subscribers) | `plan: only not-app-facing attributes changed (new alarm)`, `live: list-subscriptions-by-topic (caller, 10:41)` | — |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| CPU alarm not yet present | `code: none` | `live: describe-alarms-for-metric` -> none (caller, 10:42); prefix read -> none (10:43) | ✓ |
| SNS topic exists | `code: main.tf:174-175` | `live: get-topic-attributes` -> exists, 2 confirmed (caller, 10:40) | ✓ |
| Topic subscribers are notify-only | `code: none` | `live: list-subscriptions-by-topic` protocols -> email, email (caller, 10:41) | ✓ |
| No drift | `plan: refresh-only` | `live: terraform plan -refresh-only` -> no changes (caller, 10:36) | ✓ |

No drift rows. Nothing `UNVERIFIED` that a score depends on.

## Verification
- Citations checked: 12 (fixed: none) — Greens on categories 1, 2, 4, 7, 9, 10, 11; the hard-block conditions of categories 2, 5, 9, 10; the mitigation's peak-hours premise
- Verdict working: Red = none; Yellow + ⚪ = 1 (category 5); hard blocks checked: irreversible data change (cat 2) no, active incident + freeze (cat 5) no, public exposure / encryption removal / secrets (cat 9) no, error budget exhausted (cat 10) no (no SLO declared) → YELLOW
- Fresh eyes: not run — dry run
- Not verified: Q1(declared), Q2 and Q7 rest on "no objection" at the caller's `[A]` (`operator`); the delivery model and the environment tier are operator-stated; Q3 is unsure (apply time unknown); no service-discovery catalog (callers in other repos unknown); who reads the two `email` subscriptions; category 7 Green rests on the assessor's rule for pure monitoring additions, not on a live alarm

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate

## Context Provided (L2)
- Q1 active incident: `Q1(alarms)=no` (`live: aws cloudwatch describe-alarms --state-value ALARM`, 10:56: 0 firing on the snapshot set); `Q1(declared)=no` (`operator (no objection at [A], 10:34)`)
- Q2 deploy freeze: no (`operator (no objection at [A], 10:34)`; no freeze calendar in the repo)
- Q3 peak traffic: `unsure` (apply at merge; peak hours 14–18 +07, `live: get-metric-data`, 10:57)
- Q4 changed this service before: many times (`operator (profile, 2026-10-19)`)
- Q5 used this IaC tool: experienced (`operator (profile, 2026-10-19)`)
- Q6 cost: not asked; scored from the plan and the price lookup (L1)
- Q7 other context: none (`operator (no objection at [A], 10:34)`)
- Q8: not applicable (nothing app-facing)
- iac-change.1 plan run and reviewed: yes (`Plan hash:` with `terraform show -no-color tfplan`)
- iac-change.2 delivery: a CI pipeline applies on merge (`UNVERIFIED — operator-stated`)
- iac-change.3 `-target` / `-refresh=false` / non-default workspace: no; default workspace, `-var-file=envs/prod.tfvars` (`Target:` + plan command)
- iac-change.4 applied recently: recent (`live: gh run list`, 10:46: success 2026-11-06 11:31 +07)

## L1 Analysis Detail
Scanned: the plan (`plan:6-42`), `main.tf`, `outputs.tf`, `variables.tf`, `envs/prod.tfvars`, `git log` of `main.tf` (7 days), the caller's evidence table. No catalog. Plan hygiene: not made with `-target` or `-refresh=false`, default workspace, the var-file named; "Objects have changed outside of Terraform": none. Changed attributes: all of one new `aws_cloudwatch_metric_alarm`, all not-app-facing.

## L3 Queries Run
All are the caller's reads, cited `live: <cmd> (caller, <time>)`; pre-flight ran only its own target check and the `git log`:
1. `aws sts get-caller-identity` (pre-flight target check, 11:00) -> account 123456789012, role `paymentapi-operator`, equals `Target:`
2. `terraform plan -refresh-only -var-file=envs/prod.tfvars` (caller, 10:36) -> no changes
3. `aws ecs describe-services ...` (caller, S1, 10:54) -> ACTIVE, 3/3, one PRIMARY deployment COMPLETED, circuit breaker off, min healthy 100 / max 200
4. `aws elbv2 describe-target-groups --names paymentapi-tg-prod` (caller, 10:38) -> behind `paymentapi-alb-prod`
5. `aws elbv2 describe-target-health` (caller, S1, 10:55) -> 3 healthy
6. `aws sns get-topic-attributes` (caller, 10:40) -> exists, 2 confirmed
7. `aws sns list-subscriptions-by-topic` protocols (caller, 10:41) -> email, email
8. `aws cloudwatch describe-alarms-for-metric` (caller, 10:42) -> none
9. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (caller, 10:43) -> none
10. `aws cloudwatch describe-alarms --state-value ALARM` (caller, S1, 10:56) -> none firing
11. `aws cloudwatch get-metric-data` 7 d hourly (caller, S1, 10:57) -> request count, target and ELB 5xx, p95, CPU, memory, hosts as in the scorecard; peak hours 14–18 +07
12. `gh run list` (caller, 10:46) -> last terraform-apply run success 2026-11-06 11:31 +07
13. `aws pricing get-products` (caller, 10:47) -> USD 0.10 per alarm metric month
14. `git log --since=7.days --oneline origin/main -- main.tf` (11:01) -> no commits
