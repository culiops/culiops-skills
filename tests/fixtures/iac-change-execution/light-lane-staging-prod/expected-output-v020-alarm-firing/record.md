**IaC change execution for:** `paymentapi` / `none` (no service-discovery instance)
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi in prod (staging first, H7). Apply directly, no PR.
**Date:** `2026-11-09 11:39`
**Commit:** `a1b2c3d` (HEAD of `iac-change/paymentapi-cpu-high-alarm`, created from `origin/main`; the change was applied from the working tree and is uncommitted — direct-apply path has no commit step)
**IaC tool(s):** Terraform (hashicorp/aws ~> 5.0; provider v5.74.0)
**Execution path:** Direct apply (operator-requested; delivery model `operator-stated`: terraform applied by hand from the operator's workstation)
**Pre-flight record:** invoked inline — staging: RED — soft block, acknowledged at `[H5]` 10:56 (`.culiops/pre-flight/paymentapi-add-cpu-alarm-staging-20261109-1056.md`); prod: YELLOW — proceed with caution, acknowledged at `[B]` 11:30 (`.culiops/pre-flight/paymentapi-add-cpu-alarm-prod-20261109-1125.md`)
**Lane:** light — L1 create only (`plan: 1 to add, 0 to change, 0 to destroy`, both environments); L2 `aws_cloudwatch_metric_alarm` create is on the allowlist; L3 one phase per environment, no drift row, duplicate check not done; L4 E1 `alarm_actions` / `ok_actions` = `aws_sns_topic.paymentapi_alerts.arn` (`code: main.tf:174`, plan lines 10 and 26), E2 tag keys `Service` / `Environment` set on a new resource, no tag-driven automation found (git grep 10:24-10:27), E3 no (nothing reads the alarm; subscribers `email` ×2). Confirmed from the plan output at 4a for both environments.
**Escalations:** none
**Environment tier:** staging=staging (`live: aws sts get-caller-identity 10:01` → 222222222222 = `code: envs/staging.tfvars:3`, `providers.tf:16`), prod=prod (`live: aws sts get-caller-identity 10:02` → 333333333333 = `code: envs/prod.tfvars:3`, `providers.tf:16`)
**Staging-first:** applied — staging 2026-11-09 11:02
**Waived:** none

## Research Summary
- Catalog: none (`.culiops/service-discovery/paymentapi.md` not found); no runtime profile. Proceeded from the code and live reads. Output root: `.culiops/` at the repo root (CULIOPS_HOME unset).
- Duplicate check: **not done** — `code:` no hit for `paymentapi-cpu-high`, `paymentapi_cpu_high`, `CPUUtilization`, `aws_cloudwatch_metric_alarm` (git grep 10:07-10:10); `git:` no history hit (`git log --all -S` 10:11, 10:12; `--grep='cpu'` 10:13); no in-flight branch (10:14) or PR (`gh pr list` 10:15). Live: the alarm does not exist in staging (10:36) or prod (11:11).
- Delivery model: UNVERIFIED in the repo (no CI, Atlantis, Terraform Cloud, Spacelift or GitOps config; no backend block) → asked inside `[A]`; answer `operator-stated` at 10:32: terraform applied by hand from the operator's workstation, a direct apply is fine. Pre-flight got `local workstation apply — not going through CI/CD pipeline`.
- Env selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: providers.tf:12-17`, `envs/*.tfvars`).
- Target check: staging account 222222222222 (10:01, re-checked 10:46, 10:50); prod account 333333333333 (10:02, re-checked 11:20, 11:24); role `assumed-role/paymentapi-operator`; region ap-southeast-1. No `[H1]`.
- Drift: none (`terraform plan -refresh-only`: staging 10:34, prod 11:19, both `No changes`).
- Alarm parameters (80% Average CPU, 3 × 300 s, notify the env's alerts topic on ALARM and OK) were not in the request and the repo has no alarm to copy: proposed defaults, shown and approved at `[A]`.
- Operator profile: `~/.culiops/operator.md` read; Q5 terraform = experienced, Q4 `acme/paymentapi-infra/paymentapi` = many times (both 2026-10-19). Nothing saved. No freeze calendar in the repo, no incident command in the profile, so the operator line was shown at `[A]` and at prod's `[B]`; no reply either time.
- Not-app-facing change: no app-source search, no Q8.
- Gaps: terraform state location and the last Terraform apply were not read (no backend block in code, no CI history); `iac-change.4` was answered from the ECS deployment time.
- Snapshot ambiguity notes: S0 `get-metric-data` canned values are 5-minute points; aggregated as the hour's bucket (counts summed, gauges averaged, p95 = highest of 12).

## Evidence
| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| staging account / region | `code: envs/staging.tfvars:2-3`, `providers.tf:16` | `live: aws sts get-caller-identity 10:01` → 222222222222 | ✅ |
| prod account / region | `code: envs/prod.tfvars:2-3`, `providers.tf:16` | `live: aws sts get-caller-identity 10:02` → 333333333333 | ✅ |
| ECS cluster / service names, running vs desired | `code: main.tf:9, 72`; `envs/staging.tfvars:11`, `envs/prod.tfvars:11` | `live: aws ecs describe-services (staging 10:42: 1/1; prod 11:15: 3/3)` | ✅ |
| alarm `paymentapi-cpu-high-<env>` absent | `code: none` | `live: describe-alarms --alarm-names (staging 10:36, prod 11:11)` → `[]` | ✅ |
| no alarm on the ECS CPU metric | `code: none` | `live: describe-alarms-for-metric (staging 10:35, prod 11:10)` → `[]` | ✅ |
| SNS topic and subscriber protocols | `code: main.tf:174-175` | `live: sns list-subscriptions-by-topic (staging 10:38, prod 11:13)` → `email`, `email` | ✅ |
| load balancer in front of the service | `code: main.tf:84-88` (target group only) | `live: describe-target-groups (staging 10:41, prod 11:14)` → `paymentapi-alb-<env>/50dc6c495c0c9188` | ✅ (ALB not in code, found live) |
| other alarms on the service | `code: none` | `live: describe-alarms --alarm-name-prefix paymentapi` staging 10:37: `paymentapi-alb-elb5xx-staging` in ALARM; prod 11:12: none | noted, not drift: the code makes no claim about alarms on the load balancer (the load balancer is not defined in this repo); staging's alarm is health context (S0, Q1(alarms)) |
| alarm price | — | `live: aws pricing get-products 10:40` → $0.10 per alarm metric month, published 2026-10-07 | ✅ |
| delivery model | `code: none` | — | `operator-stated` (10:32) |
| terraform state location / last apply | `code: none` (no backend block) | `live: gh run list 10:39` → `[]`; state object not read | UNVERIFIED |
Drift rows: 0 (the staging load-balancer alarm is context, see its row). Unverified rows: 2 (delivery model by operator statement, state location).

## Change Plan
**Phase 1 of 1: add the CPU alarm — staging, then prod**
- Files: `main.tf` (add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`, hunk `@@ -179`)
- Resources affected: 1 add, 0 change, 0 destroy per environment. Alarm `paymentapi-cpu-high-${var.env}`: Average `AWS/ECS` `CPUUtilization` of the service, > 80 for 3 × 300 s; `alarm_actions` and `ok_actions` = `aws_sns_topic.paymentapi_alerts.arn`.
- Blast radius: snapshot set per environment — `paymentapi-svc-<env>` (`code: main.tf:71-72`), `paymentapi-alb-<env>` (`code: main.tf:84-88` + `live:` target-group read), `paymentapi-cpu-high-<env>` (new; judged by its success criteria). `Snapshot coverage: code + live target-group read; no catalog, no runtime profile; not covered: dependents and dependencies (not-app-facing change), callers in other repos.`
- Disruption: none (`code:` the diff only adds a resource; `plan:` create, 1 to add, 0 to change, 0 to destroy)
- Rollback path: `git revert`, plan, apply per environment — removes only the alarm; reversible; `untested`
- Success criteria: (1) `terraform plan -var-file=envs/<env>.tfvars` → `No changes.`; (2) `describe-alarms --alarm-names paymentapi-cpu-high-<env>` → one alarm, state not `INSUFFICIENT_DATA`, enabled, topic action; (3) `describe-alarms-for-metric` lists it; (4) `describe-alarm-history --history-item-type StateUpdate` shows it left `INSUFFICIENT_DATA`; (5) S2 (alarms firing, ECS running vs desired, ALB target health; no metrics call — not-app-facing change)
- Execution path: direct apply · Staging-first (H7): staging, then prod, one `terraform apply tfplan` each · Observation window: prod starts once staging's success criteria pass · Branch: `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d`
- Self-check: 8/8 pass

## Execution Log
### Phase 1: add the CPU alarm — staging
- Files changed: `main.tf`
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962` (`terraform show -no-color tfplan`, staging, 10:48)
- Parity check: n/a
- Pre-flight verdict: RED — soft block (🔴 5 timing, 🔴 10 resource health: alarm `paymentapi-alb-elb5xx-staging` in `ALARM` since 09:56 on the load balancer in the snapshot set; 🟡 1 and 9: local workstation apply). Acknowledged at `[H5]` 10:56, reason: "known flaky alarm, it has fired and cleared on its own for weeks, unrelated to the CPU alarm" (operator, `operator`, not evidence). Mitigations committed: confirm the new alarm leaves `INSUFFICIENT_DATA`; S2 compares the firing alarm before and after. `[B]` approved 11:01.
- Execution: `terraform apply tfplan` (staging, 11:02) → `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
- Verification: re-plan → `No changes.` (11:03); `describe-alarms --alarm-names paymentapi-cpu-high-staging` → `OK`, `ActionsEnabled` true, action `arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging` (11:04); `describe-alarms-for-metric` → `["paymentapi-cpu-high-staging"]` (11:05); `describe-alarm-history --history-item-type StateUpdate` → "Alarm updated from INSUFFICIENT_DATA to OK" 2026-11-09T03:17:44Z (11:06; the canned time precedes the dry-run clock). All pass.
- Snapshot: before 10:45 (S0 10:41-10:45, reused as S1 at 10:49) · after 11:09 (S2 11:07-11:09) · 4 ok / 0 regressed / 0 no data

### Phase 1: add the CPU alarm — prod
- Files changed: `main.tf` (same approved diff; no new code)
- Self-check: plan 8/8 · diff 6/6 (same diff)
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` (`terraform show -no-color tfplan`, prod, 11:22)
- Parity check: pass (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create in both plans)
- Pre-flight verdict: YELLOW — proceed with caution (🟡 1 blast radius and 🟡 9 security posture: local workstation apply, outside CI/CD; all else green). Acknowledged at `[B]` 11:30. Mitigations committed: apply only the approved `tfplan`; the provider pins account 333333333333 (`code: providers.tf:16`) and the 4a re-check matched at 11:20; confirm the new alarm leaves `INSUFFICIENT_DATA`. Fresh eyes (pre-flight): not run — dry run.
- Execution: `terraform apply tfplan` (prod, 11:31) → `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
- Verification: re-plan → `No changes.` (11:32); `describe-alarms --alarm-names paymentapi-cpu-high-prod` → `OK`, `ActionsEnabled` true, action `arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod` (11:33); `describe-alarms-for-metric` → `["paymentapi-cpu-high-prod"]` (11:34); `describe-alarm-history` → left `INSUFFICIENT_DATA`, 2026-11-09T03:42:13Z (11:35). All pass.
- Snapshot: before 11:18 (S0 11:14-11:18, reused as S1 at 11:23) · after 11:38 (S2 11:36-11:38) · 4 ok / 0 regressed / 0 no data

## Health Snapshot
`Snapshot coverage: code + live target-group read; no catalog, no runtime profile; not covered: dependents and dependencies (not-app-facing change), callers in other repos.`

Members (per environment): `paymentapi-svc-<env>` (ECS service, `code: main.tf:71-72`); `paymentapi-alb-<env>` (load balancer, `code: main.tf:84-88` + `live: describe-target-groups`); `paymentapi-cpu-high-<env>` (new alarm: no before state, judged by its success criteria, no health rows). Over cap: none. Not-app-facing change: S2 has no metrics call, so the metric signals have no after-read and are left out of the counts (not counted as `no data`).

### staging

S0 — 10:41-10:45 (`get-metric-data` values aggregated per the note in the transcript; "1w" = same hour a week earlier)
| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| paymentapi-svc-staging | alarms firing | none | — | n/a (pre-apply) | `describe-alarms --state-value ALARM` | 10:44 |
| paymentapi-svc-staging | running vs desired | 1 / 1 | — | n/a | `ecs describe-services` | 10:42 |
| paymentapi-svc-staging | CPU (mean of the hour) | 11.8% | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-svc-staging | memory (mean of the hour) | 27.8% | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-alb-staging | alarms firing | 1 — `paymentapi-alb-elb5xx-staging` in ALARM since 09:56 | — | n/a | `describe-alarms --state-value ALARM` | 10:44 |
| paymentapi-alb-staging | RequestCount | 2562 (42.7/min); 1w 2523 | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-alb-staging | target 5xx | 0; 1w 0 | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-alb-staging | ELB-generated 5xx | 127 (2.1/min, 4.96% of requests); 1w 0 | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-alb-staging | p95 TargetResponseTime | 0.120 s; 1w 0.122 s | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-alb-staging | HealthyHostCount / UnHealthyHostCount | 1 / 0; 1w 1 / 0 | — | n/a | `get-metric-data` | 10:45 |
| paymentapi-alb-staging | targets healthy | 1 of 1 | — | n/a | `elbv2 describe-target-health` | 10:43 |

S1 — reused S0, age 4 min at 10:49 (S0 reads 10:41-10:45).

S2 — 11:07-11:09
| Member | Signal | Before (S1) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| paymentapi-svc-staging | alarms firing | none | none | ok | `describe-alarms --state-value ALARM` | 11:07 |
| paymentapi-svc-staging | running vs desired | 1 / 1 | 1 / 1 | ok | `ecs describe-services` | 11:08 |
| paymentapi-alb-staging | alarms firing | 1 — `paymentapi-alb-elb5xx-staging` (ALARM since 09:56) | 1 — the same alarm, unchanged | ok (already firing before the apply; not newly firing) | `describe-alarms --state-value ALARM` | 11:07 |
| paymentapi-alb-staging | targets healthy | 1 of 1 | 1 of 1 | ok | `elbv2 describe-target-health` | 11:09 |
| paymentapi-cpu-high-staging | exists, state | does not exist | `OK`, enabled | judged by success criteria (pass) | `describe-alarms --alarm-names` | 11:04 |
`Snapshot: 4 ok · 0 regressed · 0 no data`.

### prod

S0 — 11:14-11:18
| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| paymentapi-svc-prod | alarms firing | none | — | n/a (pre-apply) | `describe-alarms --state-value ALARM` | 11:17 |
| paymentapi-svc-prod | running vs desired | 3 / 3 | — | n/a | `ecs describe-services` | 11:15 |
| paymentapi-svc-prod | CPU (mean of the hour) | 37.8% | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-svc-prod | memory (mean of the hour) | 51.8% | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-alb-prod | alarms firing | none | — | n/a | `describe-alarms --state-value ALARM` | 11:17 |
| paymentapi-alb-prod | RequestCount | 41442 (690.7/min); 1w 40820 | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-alb-prod | target 5xx | 0; 1w 0 | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-alb-prod | ELB-generated 5xx | 0; 1w 0 | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-alb-prod | p95 TargetResponseTime | 0.120 s; 1w 0.122 s | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-alb-prod | HealthyHostCount / UnHealthyHostCount | 3 / 0; 1w 3 / 0 | — | n/a | `get-metric-data` | 11:18 |
| paymentapi-alb-prod | targets healthy | 3 of 3 | — | n/a | `elbv2 describe-target-health` | 11:16 |

S1 — reused S0, age 5 min at 11:23 (S0 reads 11:14-11:18).

S2 — 11:36-11:38
| Member | Signal | Before (S1) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| paymentapi-svc-prod | alarms firing | none | none | ok | `describe-alarms --state-value ALARM` | 11:36 |
| paymentapi-svc-prod | running vs desired | 3 / 3 | 3 / 3 | ok | `ecs describe-services` | 11:37 |
| paymentapi-alb-prod | alarms firing | none | none | ok | `describe-alarms --state-value ALARM` | 11:36 |
| paymentapi-alb-prod | targets healthy | 3 of 3 | 3 of 3 | ok | `elbv2 describe-target-health` | 11:38 |
| paymentapi-cpu-high-prod | exists, state | does not exist | `OK`, enabled | judged by success criteria (pass) | `describe-alarms --alarm-names` | 11:33 |
`Snapshot: 4 ok · 0 regressed · 0 no data`.

## Outcome
completed

**Applied:** staging yes — verified (success criteria captured after the apply: re-plan `No changes.` 11:03; alarm `paymentapi-cpu-high-staging` `OK`, enabled, topic action 11:04; listed on the metric 11:05; left `INSUFFICIENT_DATA` 11:06; no `regressed` member; no `no data` members); prod yes — verified (re-plan `No changes.` 11:32; alarm `paymentapi-cpu-high-prod` `OK`, enabled, topic action 11:33; listed on the metric 11:34; left `INSUFFICIENT_DATA` 11:35; no `regressed` member; no `no data` members)

## Ticket Reference
none
