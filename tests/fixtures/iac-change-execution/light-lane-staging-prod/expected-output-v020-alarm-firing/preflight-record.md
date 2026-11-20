# Pre-flight records written by the inline runs (two records, one per environment; no reused record)

Record 1 of 2 — would be written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-staging-20261109-1056.md`

**Pre-flight assessment for:** `paymentapi` / `none`
**Action:** Add the CloudWatch CPU alarm `paymentapi-cpu-high-staging` (1 to add, 0 to change, 0 to destroy)
**Date:** `2026-11-09 10:56` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`, this change)
**Target:** `222222222222 / ap-southeast-1` | n/a | `workspace default / envs/staging.tfvars / no backend block`
**Plan hash:** `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** manual apply from the operator's workstation, direct apply — local workstation apply — not going through CI/CD pipeline (`operator-stated` at the caller's `[A]`, 10:32; no CI config in the repo)
**Invoked by:** iac-change-execution
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, answered from the caller's reads) + L3 (live, the caller's results)`
**App source:** not needed — only not-app-facing attributes changed

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One new alarm, one region; Disruption none; raised one notch for the local workstation apply (caller `Delivery model:`) | `plan:42`, `operator-stated` | Apply only the approved `tfplan`; the provider pins the account (`code: providers.tf:16`) and the target re-check matched at 10:46 and 10:50 |
| 2 | Reversibility | 🟢 | Pure addition; rollback `git revert` → plan → apply removes only the alarm | `plan:6`, `plan:42` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; last ECS deployment 5 days ago; no CI history | `live: git log --since=7.days 10:51`, `live: ecs describe-services 10:42 (caller)` | — |
| 4 | Dependency impact | 🟢 | Only a not-app-facing alarm added; no output / export change | `plan:6`, `plan:42`, `code: outputs.tf` | — |
| 5 | Timing context | 🔴 | `Q1(alarms)=yes`: `paymentapi-alb-elb5xx-staging` firing since 09:56 on the load balancer in the snapshot set; Q1(declared)=no, Q2=no (no freeze), Q3=no (1.02×). Active incident, no freeze: Red, not a hard block | `live: describe-alarms --state-value ALARM 10:44 (caller)`, `operator` | Operator action: confirm the alarm is unrelated, or hold the apply until it clears; the new alarm cannot worsen it |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟢 | Change only adds a not-app-facing alarm; none on this metric yet | `plan:6`, `live: describe-alarms-for-metric 10:35 (caller)` | Confirm after apply that the new alarm leaves `INSUFFICIENT_DATA` |
| 8 | Cost impact | 🟢 | One standard alarm, $0.10 per alarm metric month, ap-southeast-1, price list 2026-10-07, looked up 2026-11-09 | `live: pricing get-products 10:40 (caller)` | — |
| 9 | Security posture | 🟡 | No IAM, network, encryption, public-access or secret change; raised one notch for the workstation apply | `plan:6-42`, `operator-stated` | As category 1 |
| 10 | Resource health | 🔴 | Alarm firing on the load balancer: ELB-generated 5xx 127 in the hour (4.96% of requests) vs 0 a week ago; targets healthy 1/1, target 5xx 0, p95 0.120 s vs 0.122 s, CPU 11.8%, memory 27.8% | `live: describe-alarms 10:44`, `get-metric-data 10:45`, `describe-target-health 10:43` (all caller) | S2 compares the same signals after the apply |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: new alarm → SNS `paymentapi-alerts-staging`, subscriber protocols `email`, `email` | `plan:9-10, 25-26`, `live: sns list-subscriptions-by-topic 10:38 (caller)` | — |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| staging account | `code: envs/staging.tfvars:3`, `providers.tf:16` | `live: sts get-caller-identity 10:46, 10:50` → 222222222222 | ✓ |
| ECS service / counts | `code: main.tf:72`, `envs/staging.tfvars:11` | `live: ecs describe-services 10:42 (caller)` → 1/1 | ✓ |
| alarm absent | `code: none` | `live: describe-alarms --alarm-names 10:36 (caller)` → `[]` | ✓ |
| SNS subscribers | `code: main.tf:174` | `live: sns list-subscriptions-by-topic 10:38` → `email`, `email` | ✓ |
| other alarms on the service | `code: none` | `live: describe-alarm-name-prefix 10:37` → `paymentapi-alb-elb5xx-staging` in ALARM | context, not drift (code makes no claim) |
| terraform state / last apply | `code: none` | `gh run list 10:39` → `[]`; state object not read | UNVERIFIED |

## Verification
- Citations checked: 14 (fixed: none)
- Verdict working: Red = 5, 10; Yellow + ⚪ = 2 (1, 9); hard blocks checked: 2 (no irreversible change), 5 (incident yes, deploy freeze no), 9 (no public exposure / encryption removal / secrets), 10 (no SLO, no error budget) → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q1(declared), Q2, Q7 rest on the operator line (`operator`, no reply); terraform state location and last Terraform apply not read; alarm parameters are proposed defaults; `iac-change.4` rests on the ECS deployment time

## Hard Blocks
none

## Acknowledged Risks
- 🔴 category 5 (timing: alarm firing on the snapshot set) and 🔴 category 10 (resource health): acknowledged by the operator at `[H5]`, 10:56 — "known flaky alarm, it has fired and cleared on its own for weeks, unrelated to the CPU alarm" (`operator`; recorded as given, not evidence)
- 🟡 categories 1 and 9: shown at the caller's `[B]`; the operator acknowledges there

## Mitigations Committed
- Confirm after the apply that `paymentapi-cpu-high-staging` leaves `INSUFFICIENT_DATA` (caller's success criterion 4)
- S2 compares the firing alarm and the load-balancer signals before and after the apply

## Context Provided (L2)
- Q1(alarms)=yes — `live: describe-alarms --state-value ALARM 10:44 (caller)`; Q1(declared)=no — `operator (no objection at [A], 10:32)`
- Q2=no — `operator (no objection at [A], 10:32)`; no freeze calendar in the repo
- Q3=no — `live: get-metric-data 10:45 (caller)`, 2562 vs 2523 requests (1.02×)
- Q4=many times, Q5=experienced — `operator (profile, 2026-10-19)`
- Q6: not asked, cost scored from the plan and the price lookup
- Q7=none — `operator (no objection at [A], 10:32)`
- Q8: not asked (nothing app-facing)
- iac-change.1-3 answered by `Plan hash:`, `Delivery model:`, `Target:` and the plan command; iac-change.4=recent — `live: ecs describe-services 10:42 (caller)`
- No Incident Context follow-up (Q1 is yes only because of `Q1(alarms)`; `Q1(declared)=no`)

## L1 Analysis Detail
Plan text: 1 `aws_cloudwatch_metric_alarm` create, no change or destroy. `git log --since=7.days main -- main.tf` (10:51): empty. No catalog. Caller's evidence table cited; no drift rows.

## L3 Queries Run
All the caller's, cited `live: <cmd> (caller, <time>)`: sts get-caller-identity (10:46); `terraform plan -refresh-only` (10:34, no changes); describe-alarms-for-metric (10:35); describe-alarms --alarm-names (10:36); describe-alarms --alarm-name-prefix (10:37); sns list-subscriptions-by-topic, protocols (10:38); gh run list (10:39); pricing get-products (10:40); describe-target-groups (10:41); ecs describe-services (10:42); describe-target-health (10:43); describe-alarms --state-value ALARM (10:44); get-metric-data (10:45). Pre-flight's own: sts get-caller-identity (10:50, no stop), `git log` (10:51). No extra batch.

---

Record 2 of 2 — would be written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-prod-20261109-1125.md`

**Pre-flight assessment for:** `paymentapi` / `none`
**Action:** Add the CloudWatch CPU alarm `paymentapi-cpu-high-prod` (1 to add, 0 to change, 0 to destroy)
**Date:** `2026-11-09 11:25` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`, this change)
**Target:** `333333333333 / ap-southeast-1` | n/a | `workspace default / envs/prod.tfvars / no backend block`
**Plan hash:** `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8`
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** manual apply from the operator's workstation, direct apply — local workstation apply — not going through CI/CD pipeline (`operator-stated` at `[A]`, 10:32)
**Invoked by:** iac-change-execution
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, answered from the caller's reads) + L3 (live, the caller's results)`
**App source:** not needed — only not-app-facing attributes changed

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One new alarm, one region; Disruption none; raised one notch for the local workstation apply | `plan:42`, `operator-stated` | Apply only the approved `tfplan`; account pin `code: providers.tf:16`; target re-check matched at 11:20 and 11:24 |
| 2 | Reversibility | 🟢 | Pure addition; rollback `git revert` → plan → apply removes only the alarm | `plan:6`, `plan:42` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; last ECS deployment 28 days ago; the uncommitted edit is this change itself | `live: git log 11:25`, `live: ecs describe-services 11:15 (caller)` | — |
| 4 | Dependency impact | 🟢 | Only a not-app-facing alarm added; no output / export change | `plan:6`, `plan:42`, `code: outputs.tf` | — |
| 5 | Timing context | 🟢 | `Q1(alarms)=no`, Q1(declared)=no, Q2=no, Q3=no (1.02×); operator applying live | `live: describe-alarms 11:17`, `get-metric-data 11:18` (caller), `operator` | — |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟢 | Change only adds a not-app-facing alarm; none on this metric yet | `plan:6`, `live: describe-alarms-for-metric 11:10 (caller)` | Confirm after apply that the new alarm leaves `INSUFFICIENT_DATA` |
| 8 | Cost impact | 🟢 | One standard alarm, $0.10 per alarm metric month, looked up 2026-11-09 | `live: pricing get-products 10:40 (caller)` | — |
| 9 | Security posture | 🟡 | No IAM, network, encryption, public-access or secret change; raised one notch for the workstation apply | `plan:6-42`, `operator-stated` | As category 1 |
| 10 | Resource health | 🟢 | No alarm firing; target 5xx 0 and ELB 5xx 0 of 41442 requests; p95 0.120 s vs 0.122 s; CPU 37.8%, memory 51.8%; 3 of 3 targets healthy | `live: describe-alarms 11:17`, `get-metric-data 11:18`, `describe-target-health 11:16` (caller) | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: new alarm → SNS `paymentapi-alerts-prod`, subscribers `email`, `email` | `plan:9-10, 25-26`, `live: sns list-subscriptions-by-topic 11:13 (caller)` | — |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| prod account | `code: envs/prod.tfvars:3`, `providers.tf:16` | `live: sts get-caller-identity 11:20, 11:24` → 333333333333 | ✓ |
| ECS service / counts | `code: main.tf:72`, `envs/prod.tfvars:11` | `live: ecs describe-services 11:15 (caller)` → 3/3 | ✓ |
| alarm absent | `code: none` | `live: describe-alarms --alarm-names 11:11 (caller)` → `[]` | ✓ |
| SNS subscribers | `code: main.tf:174` | `live: sns list-subscriptions-by-topic 11:13` → `email`, `email` | ✓ |
| terraform state / last apply | `code: none` | `gh run list 10:39` → `[]`; state object not read | UNVERIFIED |
Staging evidence (evidence, not proof; it makes no category Green by itself): apply took 1 s, no disruption, ECS 1/1 after; staging success criteria pass; staging S1/S2 `4 ok · 0 regressed · 0 no data`, the unrelated `paymentapi-alb-elb5xx-staging` alarm firing before and after (`live: … (staging, 10:44 / 11:07)`); size differences `desired_count` 1 vs 3 (`code: envs/staging.tfvars:11` vs `envs/prod.tfvars:11`), `task_cpu` 256 vs 512, `task_memory` 512 vs 1024, `image_tag` v2.5.0-rc2 vs v2.4.1.

## Verification
- Citations checked: 15 (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 2 (1, 9); hard blocks checked: 2, 5, 9, 10 → none → YELLOW
- Fresh eyes: not run — dry run
- Not verified: Q1(declared), Q2, Q7 (`operator`, no reply); terraform state location and last Terraform apply not read; alarm parameters are proposed defaults; staging evidence is evidence, not proof

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, acknowledged 11:30)

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, acknowledged 11:30)

## Context Provided (L2)
- Q1(alarms)=no — `live: describe-alarms --state-value ALARM 11:17 (caller)`; Q1(declared)=no — `operator (no objection at [A], 10:32)`
- Q2=no — `operator (no objection at [A], 10:32)`; Q3=no — `live: get-metric-data 11:18 (caller)`, 41442 vs 40820 requests (1.02×)
- Q4=many times, Q5=experienced — `operator (profile, 2026-10-19)`; Q7=none — `operator (no objection at [A], 10:32)`
- Q6, Q8 not asked; iac-change.1-3 answered by the block; iac-change.4=recent — `live: ecs describe-services 11:15 (caller)`
- Re-asked at `[B]` 11:30: operator line, no reply → unchanged (`operator (no objection at [B], 11:30)`)

## L1 Analysis Detail
Plan text: 1 `aws_cloudwatch_metric_alarm` create. `git log --since=7.days main -- main.tf` (11:25): empty. No catalog. Parity with staging: pass (checked by the caller).

## L3 Queries Run
The caller's, cited `live: <cmd> (caller, <time>)`: terraform plan -refresh-only (11:19); describe-alarms-for-metric (11:10); describe-alarms --alarm-names (11:11); describe-alarms --alarm-name-prefix (11:12); sns list-subscriptions-by-topic (11:13); pricing get-products (10:40); describe-target-groups (11:14); ecs describe-services (11:15); describe-target-health (11:16); describe-alarms --state-value ALARM (11:17); get-metric-data (11:18); sts get-caller-identity (11:20). Pre-flight's own: sts get-caller-identity (11:24), `git log` (11:25). No extra batch.
