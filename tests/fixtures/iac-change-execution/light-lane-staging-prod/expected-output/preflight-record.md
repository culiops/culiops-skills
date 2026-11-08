<!-- Two records, one per environment (pre-flight runs again for prod, its own run). Each is the text pre-flight Step 7 would write under .culiops/pre-flight/. Neither is committed. -->

<!-- Record 1 of 2: .culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1048.md -->

**Pre-flight assessment for:** `paymentapi` / `staging`
**Action:** add CloudWatch CPU alarm `paymentapi-cpu-high-staging` (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`); plan: 1 to add, 0 to change, 0 to destroy
**Date:** `2026-11-09 10:48` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `222222222222 / ap-southeast-1` | none (no Kubernetes) | `Terraform default workspace / var-file envs/staging.tfvars / backend: none declared (code: providers.tf:1-10)`
**Plan hash:** `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (plan made by `terraform plan -out=tfplan -var-file=envs/staging.tfvars`, 10:42)
**Delivery model:** `manual apply by the operator from a workstation, direct apply; local workstation apply — not going through CI/CD pipeline` (`UNVERIFIED in the repo: code: no CI, GitOps or PR-automation config; operator-stated at [A], 10:22`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads)`
**App source:** `not needed — only not-app-facing attributes changed`
**Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset)

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One new alarm, one region; Green on the plan alone. Raised one step: direct apply from a workstation, outside CI/CD (iac-change-execution 4b) | `plan:42`, `operator-stated` (delivery model) | Operator action: apply only the saved plan (`terraform apply tfplan`, hash above); re-plan must show No changes; open a PR for the code afterwards so `main` matches live |
| 2 | Reversibility | 🟢 | Create only, no in-place change, no data. Rollback: revert, plan, apply (untested) | `plan:6`, `plan:42`, `code: main.tf:185-208` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; last ECS deployment 2026-11-04 (5 days), none in 24 h; `iac-change.4=recent` | `code: git log --since=7.days origin/main -- main.tf (10:45)`, `live: aws ecs describe-services (caller, 10:24)` | — |
| 4 | Dependency impact | 🟢 | Only changed resource is a notify-only alarm; the plan changes no output or export | `plan:42`, `code: outputs.tf` untouched, `live: aws sns list-subscriptions-by-topic (caller, 10:30)` | — |
| 5 | Timing context | 🟢 | No incident, no freeze (Q1, Q2); Q3 no, request rate 2,562 over the hour vs 2,562 the same hour last week (ratio 1.00); the operator applies by hand now (Monday 10:54) | `operator` (Q1, Q2), `operator-stated` (Q3), `live: aws cloudwatch get-metric-statistics RequestCount (caller, 10:37, 10:38)` | — |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator` | — |
| 7 | Observability readiness | 🟢 | Adds not-app-facing monitoring only and changes nothing app-facing; no CPU alarm exists today, so no monitoring is lost | `plan:6`, `live: aws cloudwatch describe-alarms-for-metric (caller, 10:26)`, `live: aws cloudwatch describe-alarms (caller, 10:25)` | Confirm after apply that the alarm leaves `INSUFFICIENT_DATA` (success criteria 3 and 4) |
| 8 | Cost impact | 🟢 | Only an alarm is added: USD 0.10 per alarm metric month, standard, ap-southeast-1 (price list publication 2026-10-07, looked up 2026-11-09). Q6 negligible | `live: aws pricing get-products (caller, 10:39)`, `operator-stated` (Q6) | — |
| 9 | Security posture | 🟡 | No IAM, network, encryption, public-access or secret change. Raised one step: the apply runs on the operator's workstation credentials, not a pipeline role (iac-change-execution 4b) | `plan:6-42`, `operator-stated` (delivery model), `live: aws sts get-caller-identity (10:47)` | Same as #1; the target was re-checked at 10:41 and 10:47 |
| 10 | Resource health | 🟢 | ECS running 1 of 1; target `healthy`; nothing firing; CPU avg 9.6-14.4 %, max 24.4 %; memory avg 26-30 %, max 40 %; 5xx Sum 0; latency avg 36-40 ms, max 140 ms | `live: aws ecs describe-services (caller, 10:24)`, `describe-alarms --state-value ALARM (caller, 10:28)`, `get-metric-statistics CPUUtilization / MemoryUtilization (caller, 10:31, 10:32)`, `describe-target-health (caller, 10:34)`, `HTTPCode_Target_5XX_Count / TargetResponseTime (caller, 10:35, 10:36)` | — |
| 11 | Application compatibility | 🟢 | Not triggered: the alarm's actions go to an SNS topic whose subscriptions are all `email`; every changed attribute is not-app-facing | `plan:6-42`, `live: aws sns list-subscriptions-by-topic (caller, 10:30)` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| One alarm is added, nothing else | `plan:6`, `plan:42` (1 to add, 0 to change, 0 to destroy) | n/a | ✓ |
| Alarm actions are the in-account SNS topic `paymentapi-alerts-staging` | `code: main.tf:201-202`, plan `alarm_actions` / `ok_actions` | `live: sns get-topic-attributes (caller, 10:29)`: topic exists, 2 confirmed, 0 pending | ✓ |
| The topic's subscribers are email only | `code: none` (no subscription resource in the repo) | `live: sns list-subscriptions-by-topic (caller, 10:30)`: `email`, `email` (protocols only) | ✓ |
| No alarm on the service today | `code: none` | `live: describe-alarms (10:25)`, `describe-alarms-for-metric (10:26)`, `describe-alarm-history (10:27)`: empty | ✓ |
| No drift | n/a | `live: terraform plan -refresh-only -var-file=envs/staging.tfvars (caller, 10:40)`: No changes | ✓ |
| Target is staging | `code: envs/staging.tfvars:3`, `providers.tf:16` | `live: aws sts get-caller-identity (10:41, 10:47)`: 222222222222 | ✓ |
| Where state lives per environment | `code: none` (no `backend` block) | none | UNVERIFIED |
| How the change is delivered | `code: none` | operator-stated | UNVERIFIED (operator-stated) |

Drift rows: none. Unverified facts: state location, delivery model.

## Verification
- Citations checked: 7 (fixed: none). Re-opened: the Greens on categories 2, 4, 7, 10, 11, and the premises of the two mitigations (saved-plan apply and re-plan; code uncommitted on the branch).
- Verdict working: Red = none; Yellow + ⚪ = 2 (1 Blast radius, 9 Security posture); hard blocks checked: 2 (no one-way change), 5 (no incident, no freeze), 9 (no public exposure, encryption removal or secrets), 10 (error budget not exhausted, nothing firing) → YELLOW.
- Fresh eyes: not run — dry run
- Not verified: Q3, Q6 and `iac-change.4` and the delivery model rest on `operator-stated` (Q3 and the request rate agree; `iac-change.4` is consistent with the 2026-11-04 ECS deployment, which is not itself a Terraform apply); the alarm's e-mail delivery is not tested (only subscription protocols were read, never endpoints); where state lives is unknown.

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, staging). Yellow findings carried to that stop: #1 Blast radius, #9 Security posture.

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, staging).

## Context Provided (L2)
From the caller block (`[A]`, 10:22): Q1 no (`operator`), Q2 no (`operator`), Q3 no (`operator-stated`), Q4 many times (`operator`), Q5 experienced (`operator`), Q6 negligible (`operator-stated`), Q7 none, Q8 (c) application source not available (`operator`; not needed, category 11 not triggered), `iac-change.1` yes, `iac-change.2` applied by hand from the operator's workstation, direct apply fine (`operator-stated`), `iac-change.3` no, default workspace and the environment's own var-file (`operator`), `iac-change.4` recent (`operator-stated`).

## L1 Analysis Detail
Scanned the plan text (1 resource, create), `main.tf`, `outputs.tf`, `providers.tf`, `envs/staging.tfvars`. No catalog (`.culiops/service-discovery/paymentapi.md` does not exist). Git history: `git log --since=7.days --oneline origin/main -- main.tf` printed nothing (10:45). The change has no commits of its own. Plan hygiene: no `-target`, no `-refresh=false` (the plan command is `terraform plan -out=tfplan -var-file=envs/staging.tfvars`); "Objects have changed outside of Terraform" absent; the plan is not "No changes".

## L3 Queries Run
All results are the caller's (`live: <cmd> (caller, <time>)`); pre-flight added no read except the target check.
1. `aws ecs describe-services` (staging service) · 10:24 · ACTIVE, desired 1, running 1, one PRIMARY deployment COMPLETED 2026-11-04T08:20:41Z
2. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` · 10:25 · no alarms
3. `aws cloudwatch describe-alarms-for-metric` (ECS CPUUtilization) · 10:26 · no alarms
4. `aws cloudwatch describe-alarm-history` (paymentapi-cpu-high-staging) · 10:27 · no history
5. `aws cloudwatch describe-alarms --state-value ALARM` · 10:28 · nothing firing
6. `aws sns get-topic-attributes` · 10:29 · 2 confirmed, 0 pending
7. `aws sns list-subscriptions-by-topic` (protocols) · 10:30 · email, email
8. `aws cloudwatch get-metric-statistics` CPUUtilization · 10:31 · avg 9.6-14.4 %, max 24.4 %
9. `aws cloudwatch get-metric-statistics` MemoryUtilization · 10:32 · avg 26-30 %, max 40 %
10. `aws elbv2 describe-target-groups` · 10:33 · ALB paymentapi-alb-staging, `/healthz`
11. `aws elbv2 describe-target-health` · 10:34 · 1 target, healthy
12. `aws cloudwatch get-metric-statistics` HTTPCode_Target_5XX_Count · 10:35 · Sum 0 in all 12 periods
13. `aws cloudwatch get-metric-statistics` TargetResponseTime · 10:36 · avg 36-40 ms, max 140 ms
14. `aws cloudwatch get-metric-statistics` RequestCount (last hour) · 10:37 · 2,562
15. `aws cloudwatch get-metric-statistics` RequestCount (same hour last week) · 10:38 · 2,562
16. `aws pricing get-products` (CloudWatch standard alarm, ap-southeast-1) · 10:39 · USD 0.10 per alarm metric month
17. `terraform plan -refresh-only -var-file=envs/staging.tfvars` · 10:40 · No changes
18. Target check, `aws sts get-caller-identity` (pre-flight's own, no stop) · 10:47 · 222222222222, equals the caller's `Target:`

---

<!-- Record 2 of 2: .culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1123.md -->

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** add CloudWatch CPU alarm `paymentapi-cpu-high-prod` (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`); plan: 1 to add, 0 to change, 0 to destroy
**Date:** `2026-11-09 11:23` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `333333333333 / ap-southeast-1` | none (no Kubernetes) | `Terraform default workspace / var-file envs/prod.tfvars / backend: none declared (code: providers.tf:1-10)`
**Plan hash:** `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (plan made by `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 11:18)
**Delivery model:** `manual apply by the operator from a workstation, direct apply; local workstation apply — not going through CI/CD pipeline` (`UNVERIFIED in the repo: code: no CI, GitOps or PR-automation config; operator-stated at [A], 10:22`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads)`
**App source:** `not needed — only not-app-facing attributes changed`
**Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset)

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One new alarm, one region, not on the data path. Raised one step: direct apply from a workstation, outside CI/CD (iac-change-execution 4b). Staging showed no disruption from the same create | `plan:42`, `operator-stated` (delivery model), staging evidence `live: aws ecs describe-services (staging, 10:59)` | Operator action: apply only the saved plan (`terraform apply tfplan`, hash above); re-plan must show No changes; open a PR for the code afterwards so `main` matches live |
| 2 | Reversibility | 🟢 | Create only, no data. Rollback: revert, plan, apply (untested in either environment) | `plan:6`, `plan:42`, `code: main.tf:185-208` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; last prod ECS deployment 2026-10-12 (27 days), none in 24 h; `iac-change.4=recent` | `code: git log --since=7.days origin/main -- main.tf (11:21)`, `live: aws ecs describe-services (caller, 11:01)` | — |
| 4 | Dependency impact | 🟢 | Only changed resource is a notify-only alarm; the plan changes no output or export | `plan:42`, `code: outputs.tf` untouched, `live: aws sns list-subscriptions-by-topic (caller, 11:07)` | — |
| 5 | Timing context | 🟢 | Q1-Q3 as answered at `[A]` (no, no, no), re-asked at `[B]`; request rate 41,442 over the hour vs 41,442 the same hour last week (ratio 1.00); the operator applies by hand now (Monday 11:29) | `operator` (Q1, Q2), `operator-stated` (Q3), `live: aws cloudwatch get-metric-statistics RequestCount (caller, 11:14, 11:15)` | — |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator` | — |
| 7 | Observability readiness | 🟢 | Adds not-app-facing monitoring only and changes nothing app-facing; no CPU alarm in prod today. Prod CPU is about 38 % against the 80 % threshold | `plan:6`, `live: aws cloudwatch describe-alarms-for-metric (caller, 11:03)`, `live: aws cloudwatch describe-alarms (caller, 11:02)` | Confirm after apply that the alarm leaves `INSUFFICIENT_DATA` (success criteria 3 and 4) |
| 8 | Cost impact | 🟢 | Only an alarm is added: USD 0.10 per alarm metric month, standard, ap-southeast-1 (publication 2026-10-07, looked up 2026-11-09 at 10:39). Q6 negligible | `live: aws pricing get-products (caller, 10:39)`, `operator-stated` (Q6) | — |
| 9 | Security posture | 🟡 | No IAM, network, encryption, public-access or secret change. Raised one step: the apply runs on the operator's workstation credentials, not a pipeline role (iac-change-execution 4b) | `plan:6-42`, `operator-stated` (delivery model), `live: aws sts get-caller-identity (11:22)` | Same as #1; the target was re-checked at 11:17 and 11:22 |
| 10 | Resource health | 🟢 | ECS running 3 of 3; 3 targets `healthy`; nothing firing; CPU avg 35.6-40.4 %, max 50.4 % (below the 70 % mark); memory avg 50-54 %, max 64 %; 5xx Sum 0; latency avg 36-40 ms, max 140 ms | `live: aws ecs describe-services (caller, 11:01)`, `describe-alarms --state-value ALARM (caller, 11:05)`, `get-metric-statistics CPUUtilization / MemoryUtilization (caller, 11:08, 11:09)`, `describe-target-health (caller, 11:11)`, `HTTPCode_Target_5XX_Count / TargetResponseTime (caller, 11:12, 11:13)` | — |
| 11 | Application compatibility | 🟢 | Not triggered: email-only subscribers; every changed attribute is not-app-facing | `plan:6-42`, `live: aws sns list-subscriptions-by-topic (caller, 11:07)` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| One alarm is added, nothing else | `plan:6`, `plan:42` (1 to add, 0 to change, 0 to destroy) | n/a | ✓ |
| Alarm actions are the in-account SNS topic `paymentapi-alerts-prod` | `code: main.tf:201-202`, plan `alarm_actions` / `ok_actions` | `live: sns get-topic-attributes (caller, 11:06)`: topic exists, 2 confirmed, 0 pending | ✓ |
| The topic's subscribers are email only | `code: none` | `live: sns list-subscriptions-by-topic (caller, 11:07)`: `email`, `email` (protocols only) | ✓ |
| No alarm on the service today | `code: none` | `live: describe-alarms (11:02)`, `describe-alarms-for-metric (11:03)`, `describe-alarm-history (11:04)`: empty | ✓ |
| No drift | n/a | `live: terraform plan -refresh-only -var-file=envs/prod.tfvars (caller, 11:16)`: No changes | ✓ |
| Target is prod | `code: envs/prod.tfvars:3`, `providers.tf:16` | `live: aws sts get-caller-identity (11:17, 11:22)`: 333333333333 | ✓ |
| Where state lives per environment | `code: none` | none | UNVERIFIED |
| How the change is delivered | `code: none` | operator-stated | UNVERIFIED (operator-stated) |

Staging evidence (evidence, not proof), passed by the caller; it does not make any category Green by itself:
- Measured disruption: staging's apply took 1 s; no restart or failover: `live: aws ecs describe-services (staging, 10:59)` shows no new deployment and running 1 = desired 1.
- Staging's success-criteria outputs: `live: terraform plan (staging, 10:55)` No changes; `live: aws cloudwatch describe-alarms-for-metric (staging, 10:56)` alarm `OK`, actions enabled; `live: aws cloudwatch describe-alarms (staging, 10:57)` state `OK`; `live: aws cloudwatch describe-alarm-history (staging, 10:58)` created, then `INSUFFICIENT_DATA` to `OK`.
- Staging health before and after: `live: aws ecs describe-services (staging, 10:24 and 10:59)` running 1 of 1 both times; `live: aws elbv2 describe-target-health (staging, 10:34 and 11:00)` 1 healthy both times.
- Var-file size differences: `desired_count` 1 (`code: envs/staging.tfvars:11`) vs 3 (`code: envs/prod.tfvars:11`); `task_cpu` 256 (`code: envs/staging.tfvars:12`) vs 512 (`code: envs/prod.tfvars:12`); `task_memory` 512 (`envs/staging.tfvars:13`) vs 1024 (`envs/prod.tfvars:13`); `image_tag` v2.5.0-rc2 (`envs/staging.tfvars:10`) vs v2.4.1 (`envs/prod.tfvars:10`).

Drift rows: none. Unverified facts: state location, delivery model.

## Verification
- Citations checked: 7 (fixed: none). Re-opened: the Greens on categories 2, 4, 7, 10, 11, and the premises of the two mitigations.
- Verdict working: Red = none; Yellow + ⚪ = 2 (1 Blast radius, 9 Security posture); hard blocks checked: 2 (no one-way change), 5 (no incident, no freeze), 9 (no public exposure, encryption removal or secrets), 10 (error budget not exhausted, nothing firing) → YELLOW.
- Fresh eyes: not run — dry run
- Not verified: Q3, Q6, `iac-change.4` and the delivery model rest on `operator-stated`; Q1-Q3 are re-asked at `[B]` and a change there would re-run this assessment; the alarm's e-mail delivery is not tested (protocols only); where state lives is unknown; the staging evidence describes staging, not prod.

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, prod). Yellow findings carried to that stop: #1 Blast radius, #9 Security posture.

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, prod).

## Context Provided (L2)
From the caller block (`[A]`, 10:22; Q1-Q3 re-asked at prod's `[B]`): Q1 no (`operator`), Q2 no (`operator`), Q3 no (`operator-stated`), Q4 many times (`operator`), Q5 experienced (`operator`), Q6 negligible (`operator-stated`), Q7 none, Q8 (c) application source not available (`operator`; not needed, category 11 not triggered), `iac-change.1` yes, `iac-change.2` applied by hand from the operator's workstation, direct apply fine (`operator-stated`), `iac-change.3` no, default workspace and the environment's own var-file (`operator`), `iac-change.4` recent (`operator-stated`).

## L1 Analysis Detail
Scanned the plan text (1 resource, create), `main.tf`, `outputs.tf`, `providers.tf`, `envs/prod.tfvars`. No catalog. Git history: `git log --since=7.days --oneline origin/main -- main.tf` printed nothing (11:21). No commits of the change's own. Plan hygiene: no `-target`, no `-refresh=false`; no "Objects have changed outside of Terraform"; the plan is not "No changes". Parity check against staging: pass.

## L3 Queries Run
All results are the caller's (`live: <cmd> (caller, <time>)`); pre-flight added no read except the target check.
1. `aws ecs describe-services` (prod service) · 11:01 · ACTIVE, desired 3, running 3, one PRIMARY deployment COMPLETED 2026-10-12T14:02:11Z
2. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` · 11:02 · no alarms
3. `aws cloudwatch describe-alarms-for-metric` (ECS CPUUtilization) · 11:03 · no alarms
4. `aws cloudwatch describe-alarm-history` (paymentapi-cpu-high-prod) · 11:04 · no history
5. `aws cloudwatch describe-alarms --state-value ALARM` · 11:05 · nothing firing
6. `aws sns get-topic-attributes` · 11:06 · 2 confirmed, 0 pending
7. `aws sns list-subscriptions-by-topic` (protocols) · 11:07 · email, email
8. `aws cloudwatch get-metric-statistics` CPUUtilization · 11:08 · avg 35.6-40.4 %, max 50.4 %
9. `aws cloudwatch get-metric-statistics` MemoryUtilization · 11:09 · avg 50-54 %, max 64 %
10. `aws elbv2 describe-target-groups` · 11:10 · ALB paymentapi-alb-prod, `/healthz`
11. `aws elbv2 describe-target-health` · 11:11 · 3 targets, all healthy
12. `aws cloudwatch get-metric-statistics` HTTPCode_Target_5XX_Count · 11:12 · Sum 0 in all 12 periods
13. `aws cloudwatch get-metric-statistics` TargetResponseTime · 11:13 · avg 36-40 ms, max 140 ms
14. `aws cloudwatch get-metric-statistics` RequestCount (last hour) · 11:14 · 41,442
15. `aws cloudwatch get-metric-statistics` RequestCount (same hour last week) · 11:15 · 41,442
16. `aws pricing get-products` (CloudWatch standard alarm, ap-southeast-1) · 10:39 (region-wide, from staging's turn) · USD 0.10 per alarm metric month
17. `terraform plan -refresh-only -var-file=envs/prod.tfvars` · 11:16 · No changes
18. Target check, `aws sts get-caller-identity` (pre-flight's own, no stop) · 11:22 · 333333333333, equals the caller's `Target:`
