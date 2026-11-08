Pre-flight record, written inline by the dry run. Intended path under the output root: `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1107.md`. The record is left uncommitted (invoked by another skill).

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** `Add CloudWatch alarm paymentapi-cpu-low-prod (CPU below 20% for 3 x 5 min); alarm actions: alerts SNS topic + Application Auto Scaling scale-in policy`
**Date:** `2026-11-09 11:07` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf` modified on branch `iac-change/paymentapi-cpu-low-alarm`)
**Target:** `333333333333 / ap-southeast-1` | `n/a (no Kubernetes)` | `Terraform var-file envs/prod.tfvars, default workspace (operator-stated), no backend key declared in code`
**Plan hash:** `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (after `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 2026-11-09 10:57)
**Delivery model:** `PR, then a CI pipeline applies on merge` (`UNVERIFIED in the repo: no CI config, controller object or backend found; operator-stated at [F2], 2026-11-09 10:44`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live: the caller's reads, plus pre-flight's own target check)`
**App source:** `not available — category 11 unknown` (Q8 = (c))

## Verdict: RED — SOFT BLOCK

No category is Red. Three categories are Yellow or unknown (1, 7, 11), which escalates the verdict to RED (soft block).

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | YELLOW | One create, but its second action is the scale-in policy, which nothing drives today (`Alarms: []`). Capacity can fall from 3 to 2 tasks, one task per 300 s cooldown, floor `min_capacity` 2. Whether in-flight requests on the stopped task are drained is not established, so disruption is not `none`. 3 of 3 tasks healthy across two AZs now. | `plan: Plan: 1 to add, 0 to change, 0 to destroy`; `code: main.tf:189,213-230`; `live: B3, B5, B18, B19` (caller, 10:16-10:32); `docs: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html (2026-11-09)`: an alarm breach changes capacity by the step adjustment within the target's min and max; `assessor: Blast radius, capacity reductions` | Operator action: after the apply lands, watch desired / running count and target health around the first scale-in. Scale-in cannot go below 2 tasks, and the scale-out policy (+1) is unchanged |
| 2 | Reversibility | GREEN | Create only. `git revert` + plan + apply through the same path removes the alarm; it is stateless. It does not undo a scale-in that already ran; Terraform does not own the task count (`ignore_changes = [desired_count]`), so the scale-out policy or `aws ecs update-service` restores it. | `plan: 1 to add, 0 to change`; `code: main.tf:93-95`; `assessor: rollback mechanisms, Terraform` | none needed |
| 3 | Change velocity | GREEN | No commit touched `main.tf` in the last 7 days. No open PR. Last ECS deployment 2026-10-12 (28 days). Last apply "recent" is operator-stated (no state backend declared, so no `head-object` read). | `git: git log --since=7.days origin/main -- main.tf, empty (11:01)`; `gh pr list --state open, none (11:02)`; `live: B3`; `operator-stated: iac-change.4=recent` | none needed |
| 4 | Dependency impact | GREEN | The alarm is new, so nothing consumes it: no reference in code, no output or export changes, no composite alarm with this prefix. The scale-in policy and the ECS service are not modified by the plan. | `code: grep paymentapi_cpu_low, none (10:04)`; `plan: 1 add, no output change`; `live: B13 (composite: []), B16 (alarm absent)` | none needed |
| 5 | Timing context | GREEN | Q1 no, Q2 no. Q3 no, and live traffic equals the same hour last week (ratio 1.0, below 1.5x). Apply time is the merge time, unknown. | `operator: Q1, Q2`; `operator-stated + live: Q3, B10, B11` | none needed |
| 6 | Operator familiarity | GREEN | Many times with this service; experienced with Terraform. | `operator: Q4, Q5` | none needed |
| 7 | Observability readiness | YELLOW | CPU-high is live and enabled (`ActionsEnabled: true`) and the new alarm adds a CPU-low, but both are static thresholds on one metric. No SLO, no dashboard in code, and no 5xx or latency alarm on the ALB would catch under-capacity after a scale-in. The assessor's "monitoring-only change" exemption does not apply because the alarm is app-facing. | `code: main.tf (no aws_cloudwatch_dashboard or SLO resource)`; `live: B13, B14, B15`; `assessor: Observability readiness, static threshold alerting` | Operator action: after the apply, confirm the new alarm leaves `INSUFFICIENT_DATA`. Consider a separate change that adds an ALB 5xx or latency alarm |
| 8 | Cost impact | GREEN | One standard alarm: USD 0.10 per alarm metric month in ap-southeast-1. Scale-in lowers task-hours. | `live: B23 (caller, 10:36; pricing publication 2026-10-07, lookup 2026-11-09)`; `operator: Q6 (negligible)` | none needed |
| 9 | Security posture | GREEN | No IAM, network, encryption, audit-logging or secret change. | `plan: 1 add, alarm only`; `code: diff of main.tf` | none needed |
| 10 | Resource health | GREEN | 3/3 running, 3/3 healthy, steady state since 2026-11-09T01:12Z, nothing firing. CPU 37-43 % (max 52.8 %), memory 52-56 % (max 66 %), both under 70 %. Target 5xx sum 0 in all 12 periods. Latency 36-40 ms. | `live: B3, B5, B6, B7, B8, B9, B12` (caller, 10:16-10:25) | none needed |
| 11 | Application compatibility | UNKNOWN | The alarm has a scaling action, so it is app-facing (the SNS action alone would be notify-only: the topic's subscribers are all `email`). No app source is available (Q8 = (c)), so whether the app handles a stopped task is unknown. Silent breakage: if it does not, health checks and alarms stay green. | `plan: alarm_actions[1] is a scaling policy ARN`; `live: B21`; `assessor: Application compatibility, notify-only list`; `operator: Q8` | Evidence that would resolve it: a local checkout or the deployed ref of the app (Q8 a or b), to read its shutdown handling |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| CPU-high alarm: 70 %, 3 x 300 s, Average, actions SNS + scale-out policy, enabled | `code: main.tf:234-260` | `live: B15` same values | match |
| `paymentapi-cpu-low-prod` does not exist | `code: none` | `live: B16` `MetricAlarms: []` | match |
| Scale-in policy exists, -1, cooldown 300, no alarm | `code: main.tf:213-230` | `live: B19` `Alarms: []` | match |
| Scale-out policy driven by CPU-high | `code: main.tf:193-210, 252` | `live: B19` | match |
| Scalable target min 2, max 6 | `code: main.tf:189-190` | `live: B18` | match |
| Desired count 3 | `code: envs/prod.tfvars:11`, `main.tf:93-95` | `live: B3` desired 3, running 3 | match |
| Alerts topic has email subscribers only | `code: main.tf:174-181` | `live: B21` (protocols only), `B22` | match |
| No drift | n/a | `live: B2` refresh-only "No changes" | match |
| Delivery model | `code: none` | n/a | UNVERIFIED (operator-stated) |
| In-flight request handling when scale-in stops a task | `code: none` | n/a | UNVERIFIED (no docs read) |

Drift rows: none. Unverified facts: delivery model, in-flight request handling on scale-in stop.

## Verification

- Citations checked: 22 (fixed: category 4's "no composite alarm" claim first cited B12, which lists only alarms in `ALARM` state. Changed to B13 (all alarms with the prefix, `composite: []`), B16 and the code search.)
- Verdict working: Red = none; Yellow + unknown = 3 (categories 1, 7, 11) → multi-Yellow escalation; hard blocks checked: category 2 (no irreversible data change), 5 (no incident + freeze), 9 (no public exposure, encryption removal or secret), 10 (no exhausted error budget): none → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model (operator-stated); Q3 (operator-stated, supported by B10 / B11); last successful apply ("recent", operator-stated, no state backend declared); how ECS drains in-flight requests when scale-in stops a task (no docs read, not relied on); how the app handles a stopped task (no app source); alarm threshold and window (operator-supplied at `[F2]`); whether someone is on hand at the merge time (not asked)

## Hard Blocks

none

## Acknowledged Risks

Acknowledged at `[H5]` by the operator, 2026-11-09 11:07, for findings 1 (Blast radius, YELLOW), 7 (Observability readiness, YELLOW) and 11 (Application compatibility, UNKNOWN), reason given for each: "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged".

## Mitigations Committed

none committed by the operator at `[H5]` (the answer is a reason, not a commitment). The mitigations listed in the scorecard remain operator actions.

## Context Provided (L2)

All answers taken from the caller block (said by the operator at `[F2]`, 2026-11-09 10:44); nothing was asked by pre-flight.

- Q1 active incident: no (`operator`, from caller)
- Q2 deploy freeze: no (`operator`, from caller)
- Q3 peak traffic at apply time: no (`operator-stated`, from caller; cross-checked live)
- Q4 changed this service before: many times (`operator`, from caller)
- Q5 used this IaC tool before: experienced (`operator`, from caller)
- Q6 cost impact: negligible (`operator-stated`, from caller; category 8 is scored from the plan and the price lookup)
- Q7 other context: none (`operator`, from caller)
- Q8 application source: (c) not available (`operator`, from caller)
- iac-change.1 plan run and reviewed: yes. iac-change.2 delivery: PR, and a CI pipeline applies on merge (`operator-stated`). iac-change.3 non-default target / workspace / var-file: no, default workspace and the env's own var-file (`operator-stated`). iac-change.4 applied recently: recent (`operator-stated`) (all from caller)

## L1 Analysis Detail

Plan text: one `+ create` of `aws_cloudwatch_metric_alarm.paymentapi_cpu_low`; no change, no destroy, no refresh drift block, no output change. Alarm actions: the alerts SNS topic and the `paymentapi-scale-in-prod` scaling policy. Changed attributes are all app-facing because of the scaling action. Git history: nothing on `main.tf` in 7 days; no open PR; the one uncommitted change is this change's own. No service-discovery catalog (`.culiops/service-discovery/paymentapi.md` absent), so nothing is cited as `catalog:`.

## L3 Queries Run

Pre-flight's own target check:

1. `aws sts get-caller-identity --query Account --output text` · 2026-11-09 11:00 · `333333333333`, equals the caller's `Target:` account

The caller's reads, cited as `live: <cmd> (caller, <time>)`:

- B2 `terraform plan -refresh-only -var-file=envs/prod.tfvars` (caller, 10:15): No changes
- B3 `aws ecs describe-services` (caller, 10:16): ACTIVE, desired 3, running 3, pending 0, min healthy 100 %, max 200 %, circuit breaker off, last deployment 2026-10-12 COMPLETED
- B4 `aws elbv2 describe-target-groups --names paymentapi-tg-prod` (caller, 10:17): behind `paymentapi-alb-prod` (internal), health path `/healthz`
- B5 `aws elbv2 describe-target-health` (caller, 10:18): 3 of 3 healthy
- B6 `CPUUtilization` (caller, 10:19): Average 37.2-42.8 %, Maximum 52.8 %
- B7 `MemoryUtilization` (caller, 10:20): Average 52-56 %, Maximum 66 %
- B8 `HTTPCode_Target_5XX_Count` (caller, 10:21): Sum 0 in all periods
- B9 `TargetResponseTime` (caller, 10:22): Average 36-40 ms, Maximum 140 ms
- B10 `RequestCount`, last hour (caller, 10:23): 3400-3511 per 5 min
- B11 `RequestCount`, same hour a week ago (caller, 10:24): 3400-3511 per 5 min, ratio 1.0
- B12 `describe-alarms --state-value ALARM` (caller, 10:25): none firing
- B13 `describe-alarms --alarm-name-prefix paymentapi` (caller, 10:26): one alarm (CPU-high, OK, enabled), no composite alarms
- B14 `describe-alarms-for-metric` CPU (caller, 10:27): only CPU-high
- B15 `describe-alarms --alarm-names paymentapi-cpu-high-prod` (caller, 10:28): 70 %, 3 x 300 s, actions SNS + scale-out policy, enabled, OK
- B16 `describe-alarms --alarm-names paymentapi-cpu-low-prod` (caller, 10:29): does not exist
- B17 `describe-alarm-history` CPU-high (caller, 10:30): ALARM 2026-11-08T08:48:51Z to OK 09:03:51Z; ALARM 2026-11-05T05:02:51Z to OK 05:17:51Z
- B18 `describe-scalable-targets` (caller, 10:31): min 2, max 6, scale-in not suspended
- B19 `describe-scaling-policies` (caller, 10:32): scale-out (+1, cooldown 300) driven by CPU-high; scale-in (-1, cooldown 300) has no alarm
- B20 `describe-scaling-activities` (caller, 10:33): last activity 2026-11-08T08:49:02Z, scale-out to 3 by CPU-high, Successful
- B21 `sns list-subscriptions-by-topic` protocols (caller, 10:34): email, email
- B22 `sns get-topic-attributes` (caller, 10:35): 2 confirmed, 0 pending
- B23 `aws pricing get-products` (caller, 10:36): USD 0.10 per alarm metric month, publication 2026-10-07

Local reads by pre-flight: `git log --since=7.days --oneline origin/main -- main.tf` (11:01, empty); `gh pr list --state open` (11:02, none).
