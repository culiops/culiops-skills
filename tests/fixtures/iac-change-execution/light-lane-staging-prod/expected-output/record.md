<!-- Execution record the skill would write (Step 5b) to .culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1136.md. Not committed. -->

**IaC change execution for:** `paymentapi` / no instance (staging, then prod)
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`): staging first, then prod. Operator's request: "Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR."
**Date:** `2026-11-09 11:36`
**Commit:** `a1b2c3d` (HEAD of branch `iac-change/paymentapi-cpu-high-alarm`, cut from `origin/main`; the code change in `main.tf` is uncommitted: direct apply path, nothing was committed or pushed)
**IaC tool(s):** Terraform v1.9.8 (hashicorp/aws v5.74.0)
**Execution path:** Direct apply
**Pre-flight record:** invoked inline — staging: YELLOW (`.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1048.md`); prod: YELLOW (`.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1123.md`)
**Lane:** light — L1 every action a create (`plan:` staging 10:42 and prod 11:18, line 42: 1 to add, 0 to change, 0 to destroy); L2 `aws_cloudwatch_metric_alarm` create is allowlist row 1; L3 one phase per environment, no drift row (`terraform plan -refresh-only` 10:40 and 11:16: No changes), duplicate check not done; L4 E1 alarm actions are `aws_sns_topic.paymentapi_alerts.arn` (`code: main.tf:201-202`), E2 tag keys `Service` / `Environment` with no automation hit, E3 no. Predicted in Step 1, confirmed at both 4a runs.
**Escalations:** none
**Environment tier:** staging=staging (proven: `live:` aws sts get-caller-identity 222222222222 at 10:01 and 10:41 = pin `code: envs/staging.tfvars:3`, `providers.tf:16`); prod=prod (proven: `live:` aws sts get-caller-identity 333333333333 at 11:17 = pin `code: envs/prod.tfvars:3`, `providers.tf:16`)
**Staging-first:** applied — staging 10:54
**Waived:** none
**Prerequisites** (`skills/iac-change-execution/examples/aws.md`): AWS CLI v2 (`aws-cli/2.17.21`); authentication by the operator's role `paymentapi-operator`, switched from staging to prod credentials by the operator between environments; read-only tier for Steps 1 and 5 (Describe*, List*, Get*, `cloudwatch:GetMetricStatistics`); mutation tier for Step 4 (create of one CloudWatch alarm in each account); CloudWatch `GetMetric*` calls carry a small per-call charge.

## Research Summary

- Catalog: none (`.culiops/service-discovery/paymentapi.md` does not exist); proceeded without it.
- Duplicate check: not done. `code:` no `aws_cloudwatch_metric_alarm`, `CPUUtilization` or `cpu-high` in the repo (only a comment at `main.tf:3-4` that says the alarm is absent); `git: git log --all -S` for `CPUUtilization` and `aws_cloudwatch_metric_alarm` printed nothing; no branch `*cpu*`; no open PR (`gh pr list`). Live reads R2-R4 confirm no alarm exists in either environment.
- Delivery model: `UNVERIFIED` in the repo (`code: none`). Answered at `[A]` (10:22), `operator-stated`: Terraform is applied by hand from the operator's workstation, and a direct apply is fine. Recorded to pre-flight as a local workstation apply, outside CI/CD.
- Environment selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/staging.tfvars`, `envs/prod.tfvars`, `providers.tf:12-17`); no `backend` block (`code: providers.tf:1-10`), so where state lives per environment is `UNVERIFIED`.
- Target checks: staging account 222222222222 (10:01, 10:41, 10:47), prod account 333333333333 (11:17, 11:22), region ap-southeast-1, role `paymentapi-operator`; each matched its pin.
- Plan self-check 8/8 (item 5, path fits the delivery model, closed by the operator's answer at `[A]`). Diff self-check 6/6. E1-E3 on the diff and again at each 4a: no hit. Fresh eyes: skipped — add-only, no sensitive types.
- Code written: `main.tf` lines 182-208 (one resource and its section comment), conventions from `code: main.tf:72`, `main.tf:138`, `main.tf:172-180`.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| Service `paymentapi-svc-<env>` exists, cluster `paymentapi-cluster-<env>` | `code: main.tf:72`, `main.tf:9`, `envs/staging.tfvars:11`, `envs/prod.tfvars:11` | `live: aws ecs describe-services (staging, 10:24)`: ACTIVE, desired 1, running 1; `(prod, 11:01)`: ACTIVE, desired 3, running 3 | ✅ |
| SNS topic `paymentapi-alerts-<env>` exists and is the alarm target | `code: main.tf:174-175`, `outputs.tf:16-18` | `live: aws sns get-topic-attributes (staging, 10:29; prod, 11:06)`: topic exists, 2 confirmed, 0 pending | ✅ |
| Topic subscribers are email only (alarm is notify-only) | `code: none` | `live: aws sns list-subscriptions-by-topic (staging, 10:30; prod, 11:07)`: `email`, `email` (protocols only) | ✅ |
| No alarm exists on the service CPU metric or under prefix `paymentapi` | `code: none` | `live: describe-alarms --alarm-name-prefix (staging, 10:25; prod, 11:02)`, `describe-alarms-for-metric (10:26; 11:03)`, `describe-alarm-history (10:27; 11:04)`: empty | ✅ |
| Environment to account pin | `code: envs/staging.tfvars:3` = 222222222222, `envs/prod.tfvars:3` = 333333333333, `providers.tf:16` | `live: aws sts get-caller-identity` 222222222222 (10:01, 10:41, 10:47) and 333333333333 (11:17, 11:22) | ✅ |
| No drift in either environment | n/a | `live: terraform plan -refresh-only (staging, 10:40; prod, 11:16)`: No changes | ✅ |
| Service health before the change | n/a | staging: 1 of 1 running, 1 target healthy, nothing firing, CPU avg 9.6-14.4 %; prod: 3 of 3 running, 3 targets healthy, nothing firing, CPU avg 35.6-40.4 % (max 50.4 %) | ✅ |
| Price of the new alarm | n/a | `live: aws pricing get-products (10:39)`: USD 0.10 per alarm metric month, standard, ap-southeast-1 (publication 2026-10-07) | ✅ |
| Where state lives per environment | `code: none` (no backend block) | none | UNVERIFIED |
| How the change is delivered | `code: none` | operator-stated at `[A]` | UNVERIFIED (operator-stated) |

Drift rows: 0. Unverified rows: 2 (state location, delivery model). Code-only rows: 0.

## Change Plan

**Phase 1 of 1: add the CPU alarm, once per environment (staging, then prod)**
- Files: `main.tf` (modify: one resource appended)
- Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-staging`, then `paymentapi-cpu-high-prod`); per environment 1 to add, 0 to change, 0 to destroy
- Alarm parameters (proposed in the plan, accepted at `[A]`): `AWS/ECS` `CPUUtilization`, dimensions ClusterName and ServiceName of the environment's service, `Average` > 80 for 3 periods of 300 s; alarm and OK actions to the existing SNS topic; tags `Service`, `Environment`
- Blast radius: one new alarm per environment; nothing consumes it; notifies email subscribers only (`live: R7`). `code: main.tf:185-208`
- Disruption: none. It adds a resource and edits no existing one (`code: main.tf:185-208`); confirmed by `plan:` (create only) at both 4a runs
- Rollback path: reversible. `git revert` of the change, then plan and apply (destroys the alarm; no data involved). Untested
- Evidence: the table above
- Success criteria (per environment): 1 `terraform plan -var-file=envs/<env>.tfvars` -> No changes · 2 `describe-alarms-for-metric` -> alarm `paymentapi-cpu-high-<env>`, ActionsEnabled true · 3 `describe-alarms --alarm-name-prefix paymentapi` -> alarm present, state `OK` or `INSUFFICIENT_DATA`, not `ALARM` · 4 `describe-alarm-history` -> created, state update away from `INSUFFICIENT_DATA` · 5 `describe-services` -> running = desired, no new deployment · 6 `describe-target-health` -> all `healthy`

**Execution path:** Direct apply (the operator's request), one apply per environment, each approved at its own `[B]`.
**Staging-first (H7):** staging, then prod; observation window: until staging's success criteria pass.

## Execution Log

### Phase 1: add the CPU alarm — staging
- Files changed: `main.tf` (appended `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` and its section comment, lines 182-208; uncommitted)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962` (`terraform show -no-color tfplan`, staging plan of 10:42)
- Parity check: n/a
- Pre-flight verdict: YELLOW — proceed with caution. Risks acknowledged: #1 Blast radius and #9 Security posture, both raised one step for the direct workstation apply. Mitigations committed: apply only the saved plan, re-plan must show No changes, open a PR from `iac-change/paymentapi-cpu-high-alarm` afterwards so `main` matches live, confirm the alarm leaves `INSUFFICIENT_DATA`. Acknowledged at `[B]` (staging), operator, 10:53.
- Execution: `terraform apply tfplan` (staging, 10:54): `Creation complete after 1s [id=paymentapi-cpu-high-staging]`; `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
- Verification (staging): 1 `terraform plan -var-file=envs/staging.tfvars` (10:55) -> `No changes. Your infrastructure matches the configuration.` · 2 `aws cloudwatch describe-alarms-for-metric` (10:56) -> before `[]`, after one alarm `paymentapi-cpu-high-staging`, state `OK`, ActionsEnabled `true` · 3 `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (10:57) -> before none, after `paymentapi-cpu-high-staging`, `StateValue` `OK` (datapoints 12.4, 11.8, 13.1, not above 80.0) · 4 `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-staging` (10:58) -> before none, after `ConfigurationUpdate` created and `StateUpdate` `INSUFFICIENT_DATA` to `OK` · 5 `aws ecs describe-services` (10:59) -> before and after desired 1, running 1, single `PRIMARY` deployment from 2026-11-04T08:20:41Z (no new deployment) · 6 `aws elbv2 describe-target-health` (11:00) -> before and after 1 `healthy`. All pass. The canned alarm timestamps (2026-11-09T03:17:44Z) are earlier than the run clock and are quoted as the output gave them.

### Phase 1: add the CPU alarm — prod
- Files changed: `main.tf` (same change as staging; no new code, prod planned and applied from the same approved diff)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` (`terraform show -no-color tfplan`, prod plan of 11:18)
- Parity check: pass (prod create of `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` matches staging's create of the same address, `plan:6` in both)
- Pre-flight verdict: YELLOW — proceed with caution (prod's own run, with staging's evidence added; evidence, not proof). Risks acknowledged: #1 Blast radius and #9 Security posture (direct workstation apply). Mitigations committed: as for staging. Acknowledged at `[B]` (prod), operator, 11:28, together with "Q1–Q3 still true: yes, unchanged" (no re-run of pre-flight).
- Execution: `terraform apply tfplan` (prod, 11:29): `Creation complete after 1s [id=paymentapi-cpu-high-prod]`; `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
- Verification (prod): 1 `terraform plan -var-file=envs/prod.tfvars` (11:30) -> `No changes. Your infrastructure matches the configuration.` · 2 `describe-alarms-for-metric` (11:31) -> before `[]`, after one alarm `paymentapi-cpu-high-prod`, state `OK`, ActionsEnabled `true` · 3 `describe-alarms --alarm-name-prefix paymentapi` (11:32) -> before none, after `paymentapi-cpu-high-prod`, `StateValue` `OK` (datapoints 38.4, 39.8, 36.9, not above 80.0) · 4 `describe-alarm-history --alarm-name paymentapi-cpu-high-prod` (11:33) -> before none, after `ConfigurationUpdate` created and `StateUpdate` `INSUFFICIENT_DATA` to `OK` · 5 `describe-services` (11:34) -> before and after desired 3, running 3, single `PRIMARY` deployment from 2026-10-12T14:02:11Z · 6 `describe-target-health` (11:35) -> before and after 3 `healthy`. All pass. Canned alarm timestamps (2026-11-09T03:42:13Z) quoted as given.

## Outcome
completed

**Applied:** staging yes — verified (success criteria 1-6 at 10:55-11:00, outputs above); prod yes — verified (success criteria 1-6 at 11:30-11:35, outputs above)

## Ticket Reference
none
