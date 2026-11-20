# Pre-flight records (inline, written by pre-flight during the run; not committed)

Two inline runs, one per environment: pre-flight clears before every staging or prod apply (H9), and prod's is its own run (a staging record never matches). Both are GREEN, so neither asked a question or a GATE 2.

## Pre-flight record — staging

Path: `.culiops/pre-flight/paymentapi-add-cpu-alarm-staging-20261109-1040.md`

**Pre-flight assessment for:** `paymentapi` / none (staging)
**Action:** Add CloudWatch alarm `paymentapi-cpu-high-staging` (CPU utilization above 80 %, `AWS/ECS`, 3 × 5 min) by direct apply
**Date:** `2026-11-09 10:40` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf` on `iac-change/paymentapi-add-cpu-alarm`)
**Target:** account 222222222222 / ap-southeast-1 · var-file envs/staging.tfvars · default workspace — identity re-checked 10:35 and by pre-flight at 10:39; backend: none declared
**Plan hash:** `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** local workstation apply — not going through CI/CD pipeline; Terraform is applied by hand from the operator's workstation (`operator-stated` at `[A]`, 10:23); the repo shows no CI, Atlantis, Terraform Cloud or GitOps (`code: providers.tf:1-10`)
**Invoked by:** iac-change-execution
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads)`
**App source:** not needed — only not-app-facing attributes changed

### Verdict: GREEN

### Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One resource added in one account and region; a monitoring resource. The local workstation apply (A4) is noted; with a single add it does not change the score. | `plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_high create, 1 to add, 0 to change, 0 to destroy` | — |
| 2 | Reversibility | 🟢 | Create only, no in-place attribute change; rollback is revert, plan, apply; the alarm is stateless | `plan:` create; `code:` diff has no lifecycle setting | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in the last 7 days; last service deployment 5 days ago (2026-11-04T08:20:41Z); no CI run on record | live: git log --since=7.days (10:40); live: ecs describe-services (caller, 10:25) | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing and no output or export changes: nothing can depend on an alarm | `plan:` no output change; live: sns list-subscriptions-by-topic (caller, 10:28) | — |
| 5 | Timing context | 🟢 | No firing alarm on the set, no declared incident, no freeze, request rate 2562 vs 2523 the same hour last week (1.02×, under 1.5×); the operator is at the apply | live: describe-alarms --state-value ALARM (caller, 10:33); live: get-metric-data (caller, 10:34); `operator` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟢 | The change only adds not-app-facing monitoring; no alarm on this metric existed | assessor rule (add-only monitoring); live: describe-alarms-for-metric (caller, 10:29); live: describe-alarms --alarm-names (caller, 10:30) | After apply, confirm the new alarm leaves `INSUFFICIENT_DATA` (the caller's success criteria read it) |
| 8 | Cost impact | 🟢 | One standard alarm at $0.10 per alarm metric month, looked up for `ap-southeast-1` (publication 2026-10-07) | live: pricing get-products (caller, 10:31) | — |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access or audit-logging change; the direct local apply is noted, no score effect | `plan:` | — |
| 10 | Resource health | 🟢 | 0 alarms firing, target 5xx 0, p95 0.108–0.120 s (last week 0.110–0.122 s), ECS CPU 9.6–14.4 %, memory 26–30 %, 1/1 targets healthy: all within the service's own baseline and under 70 % | live: describe-alarms --state-value ALARM (caller, 10:33); live: get-metric-data (caller, 10:34); live: ecs describe-services (caller, 10:25); live: describe-target-health (caller, 10:27) | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: an alarm whose actions are an SNS topic with email-only subscribers | `plan: only not-app-facing attributes changed (alarm, SNS actions)`; live: sns list-subscriptions-by-topic (caller, 10:28) | — |

### Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| ECS service the alarm watches | `code: main.tf:72` | live: ecs describe-services (caller, 10:25) | ✓ |
| Topic and its subscribers | `code: main.tf:174` | live: sns list-subscriptions-by-topic (caller, 10:28) → `email`, `email` | ✓ |
| No existing alarm | `code: none` | live: describe-alarms-for-metric (caller, 10:29), live: describe-alarms --alarm-names (caller, 10:30) → none | ✓ |
| Drift | `plan:` refresh-only | `live: terraform plan -refresh-only` → No changes | ✓ |

No drift rows and no unverified facts called out.

### Verification
- Citations checked: 11 (every Green on categories 1, 2, 4, 7, 9, 10 and 11 re-opened against its source; fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 0; hard blocks checked: 2 (nothing irreversible), 5 (no incident, no freeze), 9 (nothing public, no encryption removed), 10 (no error budget exhausted) → GREEN
- Fresh eyes: not run — dry run
- Not verified: `Q1(declared)`, `Q2` rest on the operator line (`operator`, no objection); the delivery model is `operator-stated`; `iac-change.4` rests on the ECS deployment time as a proxy for the last stack apply (the Terraform state object was not read, no backend block); rollback `untested`; the topic's subscribers are email addresses, protocols read only, any forwarding is not visible; the default workspace is not read live

### Hard Blocks
none

### Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, staging)

### Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, staging)

### Context Provided (L2)
- Q1: `Q1(alarms)=no` (live: describe-alarms --state-value ALARM, 10:33: 0 firing on the snapshot set); `Q1(declared)=no` (operator (no objection at [A], 10:23))
- Q2: no (operator (no objection at [A], 10:23); no freeze source in the repo)
- Q3: no (live: get-metric-data, 10:34: ALB 2562 requests/h vs 2523 the same hour last week, 1.02×)
- Q4: many times (operator (profile, 2026-10-19)); Q5: experienced (operator (profile, 2026-10-19))
- Q6: not asked — L1 scores cost from the plan and the pricing lookup
- Q7: none (operator)
- Q8: not applicable — nothing app-facing
- iac-change.1–3: answered by `Plan hash:` with its plan command, `Delivery model:` and `Target:` (no `-target`, no `-refresh=false`, the environment's own var-file); iac-change.4: recent (live: ECS PRIMARY deployment createdAt 2026-11-04T08:20:41Z, 5 days before; gh run list []; Terraform state object not read, no backend block)
- No L2 question was put to the operator by pre-flight.

### L1 Analysis Detail
Plan hygiene: no `-target`, no `-refresh=false`, own var-file, no drift, no unexpected resources. One create, 1 resource (low count). No catalog (none exists). Git history: nothing touching `main.tf` in 7 days; the three older commits are over 30 days old. Every changed attribute is on the not-app-facing list.

### L3 Queries Run
Target check by pre-flight (no stop): `aws sts get-caller-identity` through the caller's staging credentials → account 222222222222, matches `Target:`.
The caller's results (each cited as `live: <cmd> (caller, <time>)`):
1. `terraform plan -refresh-only -var-file=envs/staging.tfvars` · 10:24 · No changes (no drift)
2. `aws ecs describe-services paymentapi-svc-staging` · 10:25 · ACTIVE, desired 1 / running 1, one PRIMARY deployment COMPLETED created 2026-11-04T08:20:41Z
3. `aws elbv2 describe-target-groups paymentapi-tg-staging` · 10:26 · front door paymentapi-alb-staging
4. `aws elbv2 describe-target-health paymentapi-tg-staging` · 10:27 · 1 target, healthy
5. `aws sns list-subscriptions-by-topic paymentapi-alerts-staging (protocols)` · 10:28 · email, email
6. `aws cloudwatch describe-alarms-for-metric AWS/ECS CPUUtilization paymentapi-svc-staging` · 10:29 · no alarm on the metric
7. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging` · 10:30 · not found (does not exist yet)
8. `aws pricing get-products AmazonCloudWatch ap-southeast-1` · 10:31 · standard alarm $0.10 per alarm metric month (publication 2026-10-07)
9. `gh run list --limit 5` · 10:32 · [] (no CI run)
10. `aws cloudwatch describe-alarms --state-value ALARM (S0)` · 10:33 · 0 firing
11. `aws cloudwatch get-metric-data snapshot-queries-staging.json (S0 = S1, reused, age 3 min)` · 10:34 · ALB 2562 req/h (2523 last week), target 5xx 0, ELB 5xx 0, p95 0.108–0.120 s, healthy hosts 1, unhealthy 0; ECS CPU 9.6–14.4 %, memory 26–30 %
12. `terraform show -no-color tfplan | sha256sum` · 10:37–10:38 · sha256:d316b3…a64962
13. `git log --since=7.days --oneline main -- main.tf` · 10:40 · 0 commits

---

## Pre-flight record — prod

Path: `.culiops/pre-flight/paymentapi-add-cpu-alarm-prod-20261109-1107.md`

**Pre-flight assessment for:** `paymentapi` / none (prod)
**Action:** Add CloudWatch alarm `paymentapi-cpu-high-prod` (CPU utilization above 80 %, `AWS/ECS`, 3 × 5 min) by direct apply
**Date:** `2026-11-09 11:07` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf` on `iac-change/paymentapi-add-cpu-alarm`)
**Target:** account 333333333333 / ap-southeast-1 · var-file envs/prod.tfvars · default workspace — identity re-checked 11:02 and by pre-flight at 11:06; backend: none declared
**Plan hash:** `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** local workstation apply — not going through CI/CD pipeline; Terraform is applied by hand from the operator's workstation (`operator-stated` at `[A]`, 10:23); the repo shows no CI, Atlantis, Terraform Cloud or GitOps (`code: providers.tf:1-10`)
**Invoked by:** iac-change-execution
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads)`
**App source:** not needed — only not-app-facing attributes changed

### Verdict: GREEN

### Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One resource added in one account and region; a monitoring resource. This is prod: the local workstation apply (A4) is noted; with a single add it does not change the score. | `plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_high create, 1 to add, 0 to change, 0 to destroy` | — |
| 2 | Reversibility | 🟢 | Create only, no in-place attribute change; rollback is revert, plan, apply; the alarm is stateless | `plan:` create; `code:` diff has no lifecycle setting | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in the last 7 days; last service deployment 28 days ago (2026-10-12T14:02:11Z); no CI run on record | live: git log --since=7.days (11:07); live: ecs describe-services (caller, 10:54) | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing and no output or export changes: nothing can depend on an alarm | `plan:` no output change; live: sns list-subscriptions-by-topic (caller, 10:57) | — |
| 5 | Timing context | 🟢 | No firing alarm on the set, no declared incident, no freeze, request rate 41442 vs 40820 the same hour last week (1.02×, under 1.5×); the operator is at the apply | live: describe-alarms --state-value ALARM (caller, 11:00); live: get-metric-data (caller, 11:01); `operator` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟢 | The change only adds not-app-facing monitoring; no alarm on this metric existed | assessor rule (add-only monitoring); live: describe-alarms-for-metric (caller, 10:58); live: describe-alarms --alarm-names (caller, 10:59) | After apply, confirm the new alarm leaves `INSUFFICIENT_DATA` (the caller's success criteria read it) |
| 8 | Cost impact | 🟢 | One standard alarm at $0.10 per alarm metric month, looked up for `ap-southeast-1` (publication 2026-10-07) | live: pricing get-products (caller, 10:31) | — |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access or audit-logging change; the direct local apply is noted, no score effect | `plan:` | — |
| 10 | Resource health | 🟢 | 0 alarms firing, target 5xx 0, p95 0.108–0.120 s (last week 0.110–0.122 s), ECS CPU 35.6–40.4 %, memory 50–54 %, 3/3 targets healthy: all within the service's own baseline and under 70 % | live: describe-alarms --state-value ALARM (caller, 11:00); live: get-metric-data (caller, 11:01); live: ecs describe-services (caller, 10:54); live: describe-target-health (caller, 10:56) | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: an alarm whose actions are an SNS topic with email-only subscribers | `plan: only not-app-facing attributes changed (alarm, SNS actions)`; live: sns list-subscriptions-by-topic (caller, 10:57) | — |

### Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| ECS service the alarm watches | `code: main.tf:72` | live: ecs describe-services (caller, 10:54) | ✓ |
| Topic and its subscribers | `code: main.tf:174` | live: sns list-subscriptions-by-topic (caller, 10:57) → `email`, `email` | ✓ |
| No existing alarm | `code: none` | live: describe-alarms-for-metric (caller, 10:58), live: describe-alarms --alarm-names (caller, 10:59) → none | ✓ |
| Drift | `plan:` refresh-only | `live: terraform plan -refresh-only` → No changes | ✓ |

No drift rows and no unverified facts called out.

Staging evidence passed by the caller (evidence, not proof; it raises no category to Green by itself): staging's apply caused no disruption (apply 1 s, ECS 1/1 and target 1/1 healthy after); staging success criteria passed (re-plan No changes, alarm exists and `OK`); staging S1 and S2 (0 alarms firing; ECS 1/1; 1 healthy target; Snapshot 4 ok · 0 regressed · 0 no data); var-file size differences desired_count 1 → 3, task_cpu 256 → 512, task_memory 512 → 1024, image_tag v2.5.0-rc2 → v2.4.1 (`code: envs/staging.tfvars:10-13` vs `envs/prod.tfvars:10-13`).

### Verification
- Citations checked: 11 (every Green on categories 1, 2, 4, 7, 9, 10 and 11 re-opened against its source; fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 0; hard blocks checked: 2 (nothing irreversible), 5 (no incident, no freeze), 9 (nothing public, no encryption removed), 10 (no error budget exhausted) → GREEN
- Fresh eyes: not run — dry run
- Not verified: `Q1(declared)`, `Q2` rest on the operator line (`operator`, no objection); the delivery model is `operator-stated`; `iac-change.4` rests on the ECS deployment time as a proxy for the last stack apply (the Terraform state object was not read, no backend block); rollback `untested`; the topic's subscribers are email addresses, protocols read only, any forwarding is not visible; the default workspace is not read live

### Hard Blocks
none

### Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, prod)

### Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`, prod)

### Context Provided (L2)
- Q1: `Q1(alarms)=no` (live: describe-alarms --state-value ALARM, 11:00: 0 firing on the snapshot set); `Q1(declared)=no` (operator (no objection at [A], 10:23) (re-shown at [B], no reply))
- Q2: no (operator (no objection at [A], 10:23); no freeze source in the repo)
- Q3: no (live: get-metric-data, 11:01: ALB 41442 requests/h vs 40820 the same hour last week, 1.02×)
- Q4: many times (operator (profile, 2026-10-19)); Q5: experienced (operator (profile, 2026-10-19))
- Q6: not asked — L1 scores cost from the plan and the pricing lookup
- Q7: none (operator)
- Q8: not applicable — nothing app-facing
- iac-change.1–3: answered by `Plan hash:` with its plan command, `Delivery model:` and `Target:` (no `-target`, no `-refresh=false`, the environment's own var-file); iac-change.4: recent (live: ECS PRIMARY deployment createdAt 2026-10-12T14:02:11Z, 28 days before; gh run list []; Terraform state object not read, no backend block)
- No L2 question was put to the operator by pre-flight.

### L1 Analysis Detail
Plan hygiene: no `-target`, no `-refresh=false`, own var-file, no drift, no unexpected resources. One create, 1 resource (low count). No catalog (none exists). Git history: nothing touching `main.tf` in 7 days; the three older commits are over 30 days old. Every changed attribute is on the not-app-facing list.

### L3 Queries Run
Target check by pre-flight (no stop): `aws sts get-caller-identity` through the caller's prod credentials → account 333333333333, matches `Target:`.
The caller's results (each cited as `live: <cmd> (caller, <time>)`):
1. `terraform plan -refresh-only -var-file=envs/prod.tfvars` · 10:53 · No changes (no drift)
2. `aws ecs describe-services paymentapi-svc-prod` · 10:54 · ACTIVE, desired 3 / running 3, one PRIMARY deployment COMPLETED created 2026-10-12T14:02:11Z
3. `aws elbv2 describe-target-groups paymentapi-tg-prod` · 10:55 · front door paymentapi-alb-prod
4. `aws elbv2 describe-target-health paymentapi-tg-prod` · 10:56 · 3 targets, all healthy
5. `aws sns list-subscriptions-by-topic paymentapi-alerts-prod (protocols)` · 10:57 · email, email
6. `aws cloudwatch describe-alarms-for-metric AWS/ECS CPUUtilization paymentapi-svc-prod` · 10:58 · no alarm on the metric
7. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` · 10:59 · not found (does not exist yet)
8. `aws pricing get-products AmazonCloudWatch ap-southeast-1` · 10:31 · standard alarm $0.10 per alarm metric month (publication 2026-10-07)
9. `gh run list --limit 5` · 10:32 · [] (no CI run)
10. `aws cloudwatch describe-alarms --state-value ALARM (S0)` · 11:00 · 0 firing
11. `aws cloudwatch get-metric-data snapshot-queries-prod.json (S0 = S1, reused, age 3 min)` · 11:01 · ALB 41442 req/h (40820 last week), target 5xx 0, ELB 5xx 0, p95 0.108–0.120 s, healthy hosts 3, unhealthy 0; ECS CPU 35.6–40.4 %, memory 50–54 %
12. `terraform show -no-color tfplan | sha256sum` · 11:04–11:05 · sha256:1e4204…763fc8
13. `git log --since=7.days --oneline main -- main.tf` · 11:07 · 0 commits
