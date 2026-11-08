**Pre-flight assessment for:** `paymentapi` / `—`
**Action:** `Add CloudWatch CPU utilization alarm paymentapi-cpu-high-prod (Terraform, 1 resource create)`
**Date:** `2026-11-09 10:50` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes)
**Target:** `123456789012 / ap-southeast-1` | `n/a` | `TF workspace default (operator-stated) / var-file envs/prod.tfvars / backend key: none declared in the repo`
**Plan hash:** `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` (SHA-256 of the exact plan/diff text assessed)
**Plan source:** `terraform show -no-color tfplan` (from `terraform plan -input=false -out=tfplan -var-file=envs/prod.tfvars`)
**Delivery model:** `CI pipeline applies on merge` (`UNVERIFIED in the repo (no CI / Atlantis / Spacelift / GitOps file) — operator-stated at [A]`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live: the caller's reads, plus pre-flight's own target check)`
**App source:** `not needed — only not-app-facing attributes changed` (Q8 was answered `(c) not available` at [A]; not used)

## Verdict: GREEN

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One resource added, one account and region. Additions only. Nothing references the alarm. Not-app-facing. | `plan:42` (1 to add, 0 to change, 0 to destroy), `code: main.tf:185-208`, `code: outputs.tf:1-19` (no alarm output) | — |
| 2 | Reversibility | 🟢 | Pure create, no in-place attribute change, no data store. Rollback is `git revert` then PR then CI apply, which removes the alarm. | `plan:6`, `plan:42`, `code: main.tf:185-208` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` on `origin/main` in 7 days. No open PR. This change's own uncommitted edit to `main.tf` is excluded. Last ECS deployment 2026-10-12 (about 27 days before the run), inside the 90-day lag threshold. | `git: git log --since=7.days --oneline origin/main -- main.tf → none (10:45)`, `git: gh pr list --state open → none (10:47)`, `live: R3 (caller, 10:23)`, `operator` (`iac-change.4=recent`, operator-stated) | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing (alarm whose actions are an SNS topic with only `email` subscriptions) and the plan changes no output or export. | `plan:42`, `plan: no output change`, `live: R8 (caller, 10:28)` → `["email","email"]` | — |
| 5 | Timing context | 🟢 | Q1=no, Q2=no, Q3=no. Request count over the last hour 41,442; same hour a week ago 41,442 (ratio 1.00, under 1.5x), so not peak. The apply happens at merge by CI, which the operator triggers; run time is Monday 10:50 +07:00. | `operator` (Q1, Q2), `operator-stated` (Q3), `live: R18, R19 (caller, 10:38-10:39)` | — |
| 6 | Operator familiarity | 🟢 | Q4=many times, Q5=experienced. | `operator` | — |
| 7 | Observability readiness | 🟢 | The change only adds not-app-facing monitoring and changes nothing app-facing. Today the service has no alarm on `CPUUtilization`, none under prefix `paymentapi`, none named `paymentapi-cpu-high-prod`; this adds the first. | `plan:6`, `live: R10, R11, R12, R13 (caller, 10:30-10:33)` → all empty | After apply, confirm the alarm leaves `INSUFFICIENT_DATA` (success criterion S1). |
| 8 | Cost impact | 🟢 | One standard alarm, 0.10 USD per alarm metric month (standard resolution) in `ap-southeast-1`; price list published 2026-10-07, looked up 2026-11-09. Q6=negligible (operator-stated). | `live: R20 (caller, 10:40)`, `plan:42` | — |
| 9 | Security posture | 🟢 | No IAM, security-group, encryption, public-access, audit-logging or secret change. The alarm action is an existing SNS topic ARN. | `plan:6`, `plan:10`, `plan:26`, `plan:42` | — |
| 10 | Resource health | 🟢 | Service `ACTIVE`, 3 of 3 running, deployment `PRIMARY` / `COMPLETED`, last event "has reached a steady state". 3 of 3 targets healthy. No alarm in `ALARM`. CPU average 34.8-41.2 percent (max 51.2), memory average 49.8-54.2 percent (max 64.2), both under 70. Target 5xx sum 0 in all 12 periods. Target response time average 0.036-0.040 s. | `live: R3, R5, R9, R14, R15, R16, R17 (caller, 10:23-10:37)` | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes change: an alarm create whose SNS action has only `email` subscribers, and `Service` / `Environment` tags that nothing reads at runtime in this repo. | `plan:6`, `plan:10`, `plan:30-37`, `live: R8 (caller, 10:28)`, `code: E2 greps (no IAM tag condition)` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| ECS cluster `paymentapi-cluster-prod` | `code: main.tf:9`, `code: envs/prod.tfvars:1` | `live: R3` service found, `ACTIVE`, 3 of 3 running | ✓ |
| ECS service `paymentapi-svc-prod` (alarm dimension) | `code: main.tf:72` | `live: R3` | ✓ |
| SNS topic `paymentapi-alerts-prod` (alarm action) | `code: main.tf:174-175`, `code: outputs.tf:16-19` | `live: R7` TopicArn matches, 2 confirmed, 0 pending | ✓ |
| SNS subscriber protocols | `code: none` (no subscription resource in this repo) | `live: R8` `["email","email"]` | not managed here, not drift: the code claims nothing, and the refresh-only plan (R2) is clean |
| No alarm on the service CPU or under the new name | `code: none` (no `aws_cloudwatch_metric_alarm` in the repo) | `live: R10, R11, R12, R13` all empty | ✓ |
| CPU headroom for the 80 percent threshold | `plan:38` (threshold 80, a plan proposal, not in the repo) | `live: R14` max 51.2 over 12 x 5 min | ✓ supports the value |
| Alarm price | none | `live: R20` 0.10 USD per alarm metric month | ✓ |

No drift rows. UNVERIFIED rows: none that scores depend on, apart from the items under Not verified.

## Verification
- Citations checked: 14 (fixed: none). Re-opened: every Green on categories 1, 2, 4, 7, 9, 10, 11 against its plan line, code line or caller live result.
- Verdict working: Red = none; Yellow + ⚪ = 0; hard blocks checked: irreversible data change (cat 2: none, pure create), active incident + deploy freeze (cat 5: Q1=no, Q2=no), public exposure / encryption removal / secrets (cat 9: none), error budget exhausted (cat 10: no SLO declared, no alarm firing) → GREEN
- Fresh eyes: not run — dry run
- Not verified: Q1, Q2, Q4, Q5 are `operator`; Q3 and Q6 are `operator-stated` (Q3 cross-checked by the request-count ratio, Q6 by the price lookup); delivery model and the prod tier are `operator-stated` (no CI file and no account pin in the repo); `iac-change.3` (default workspace, the env's own var-file) is `operator-stated`; `iac-change.4=recent` is `operator-stated`, cross-checked only by an ECS deployment date, which is not a Terraform apply date; resource-health baseline is the same 1-hour window (no longer history read); the alarm's enabled state after apply is checked at the caller's 5a, not before; tag-driven automation in other repos or SCPs is not visible from this repo

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate

## Context Provided (L2)
All answers come from the caller block (`[A]`, 10:20).
- Q1 active incident: no (`operator`, from the caller block)
- Q2 deploy freeze: no (`operator`, from the caller block)
- Q3 peak at apply time: no (`operator-stated`, from the caller block; CI applies at merge)
- Q4 changed this service before: many times (`operator`, from the caller block)
- Q5 used this IaC tool before: experienced (`operator`, from the caller block)
- Q6 cost impact: negligible (`operator-stated`, from the caller block; priced live at R20)
- Q7 other context: none (from the caller block)
- Q8 application source: `(c) not available` (from the caller block; not needed, nothing app-facing)
- `iac-change.1` plan reviewed: yes; `iac-change.2` delivery: a CI pipeline applies on merge; `iac-change.3` `-target` / `-refresh=false` / non-default workspace: no (default workspace, the env's own var-file; the plan command carries none of these flags); `iac-change.4` applied recently: recent (all `operator-stated`, from the caller block)

## L1 Analysis Detail
Plan: 1 add, 0 change, 0 destroy; `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`, `AWS/ECS` `CPUUtilization`, `ClusterName=paymentapi-cluster-prod`, `ServiceName=paymentapi-svc-prod`, Average greater than 80 for 3 x 300 s, `alarm_actions` and `ok_actions` set to the SNS topic `paymentapi-alerts-prod`, tags `Service` and `Environment`. Plan hygiene: no "objects have changed outside of Terraform" block; the refresh-only plan (R2) reports no changes; no `-target`, no `-refresh=false`, var-file `envs/prod.tfvars`. No service-discovery catalog (`.culiops/service-discovery/paymentapi.md` does not exist). Git history: no commit to `main.tf` in 7 days (`git log --since=7.days`). Changed attributes: every one is not-app-facing, so category 11 is Green from the plan.

## L3 Queries Run
The caller's results, cited as `live: <cmd> (caller, <time>)`, plus pre-flight's own target check. Reads were run with `--query` projections; no endpoint or environment value was copied.
1. `aws sts get-caller-identity` (pre-flight target check, 10:48): account 123456789012, role `paymentapi-operator`; equals the Target.
2. R2 `terraform plan -refresh-only` (caller, 10:22): no changes.
3. R3 `aws ecs describe-services …` (caller, 10:23): `ACTIVE`, desired 3, running 3, pending 0; one deployment `PRIMARY` / `COMPLETED` created 2026-10-12; circuit breaker off; steady-state event.
4. R4 `aws elbv2 describe-target-groups --names paymentapi-tg-prod` (caller, 10:24): one group, one load balancer.
5. R5 `aws elbv2 describe-target-health …` (caller, 10:25): 3 targets, all `healthy`.
6. R6 `aws elbv2 describe-load-balancers …` (caller, 10:26): `paymentapi-alb-prod`, internal, active.
7. R7 `aws sns get-topic-attributes …` (caller, 10:27): topic exists, 2 confirmed, 0 pending.
8. R8 `aws sns list-subscriptions-by-topic … --query 'Subscriptions[].Protocol'` (caller, 10:28): `["email","email"]`.
9. R9 `aws cloudwatch describe-alarms --state-value ALARM …` (caller, 10:29): none firing.
10. R10 `aws cloudwatch describe-alarms-for-metric … CPUUtilization …` (caller, 10:30): none.
11. R11 `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (caller, 10:31): none.
12. R12 `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` (caller, 10:32): none.
13. R13 `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod` (caller, 10:33): no items.
14. R14 CPU (caller, 10:34): average 34.8-41.2, max 51.2, 12 periods.
15. R15 memory (caller, 10:35): average 49.8-54.2, max 64.2, 12 periods.
16. R16 target 5xx (caller, 10:36): sum 0, 12 periods.
17. R17 target response time (caller, 10:37): average 0.036-0.040 s, 12 periods.
18. R18 request count, last hour (caller, 10:38): 41,442.
19. R19 request count, same hour a week ago (caller, 10:39): 41,442.
20. R20 `aws pricing get-products` CloudWatch standard alarm, `ap-southeast-1` (caller, 10:40): 0.10 USD per alarm metric month, publication 2026-10-07.
