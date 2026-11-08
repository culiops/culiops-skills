<!-- Execution record the skill would write to .culiops/iac-change-execution/paymentapi-max-connections-20261109-1142.md (dry run; not written into the fixture) -->

**IaC change execution for:** `paymentapi` / `prod`
**Change:** Increase `max_connections` to 200 on the paymentapi prod RDS instance (`paymentapi-db-prod`), then reboot so it takes effect. Also raised the connections alarm threshold 80 -> 160 (flagged at `[F2]`, not in the request, approved). Direct apply, no PR.
**Date:** `2026-11-09 11:42` (+07:00)
**Commit:** `a1b2c3d` (origin/main at the time the change branch `iac-change/paymentapi-max-connections-200` was created) + uncommitted changes: the direct apply path commits nothing, so the phase-1 code is still uncommitted in the working tree
**IaC tool(s):** Terraform v1.9.8 (hashicorp/aws v5.74.0) · AWS CLI v2 (aws-cli/2.17.21) for the reboot and the reads
**Prerequisites (examples/aws.md):** AWS CLI v2 >= 2.x (2.17.21 found); authentication: assumed role `paymentapi-operator` in account 123456789012 (identity read, no opt-in); read tier: `Describe*`, `List*`, `Get*` plus `cloudwatch:GetMetricStatistics` (Steps 1 and 5); mutation tier: the role must allow `rds:ModifyDBParameterGroup`, `cloudwatch:PutMetricAlarm` (the Terraform apply) and `rds:RebootDBInstance`, assumed only for the mutation; cost awareness: CloudWatch `GetMetric*` reads are billed per call.
**Execution path:** Direct apply (operator choice, from the operator's workstation, no PR)
**Pre-flight record:** invoked inline, two runs. Phase 1: `.culiops/pre-flight/paymentapi-max-connections-200-20261109-1109.md` (verdict: RED — soft block, acknowledged at `[H5]`). Phase 2: `.culiops/pre-flight/paymentapi-rds-reboot-20261109-1131.md` (verdict: RED — soft block, acknowledged at `[H5]`).
**Lane:** full — the parameter-group update and the alarm update (threshold, description) are off the light-lane allowlist (`lanes.md` > Light-lane allowlist, L2 fails); targets are not proven dev (prod, unproven). Confirmed from the plan output at 4a.
**Escalations:** none
**Environment tier:** prod=prod (operator-stated at `[F1]`; no pin in the repo — no `allowed_account_ids`, no `assume_role`, no account variable (`code: main.tf`, `variables.tf`, `envs/prod.tfvars`); identity read `live: aws sts get-caller-identity` 10:00 -> account 123456789012; unproven, so prod gate levels)
**Staging-first:** n/a — no staging env (code: `envs/prod.tfvars` is the only var-file; no staging directory, workspace or overlay in the repo)
**Waived:** none

## Research Summary
- **Catalog used:** `.culiops/service-discovery/paymentapi-prod.md` (a lead). Names the one downstream consumer (ECS `paymentapi-svc-prod`, line 41) and says the connections alarm "fires frequently" against the current limit (lines 49, 53).
- **Duplicate check:** not done. `code: main.tf:15` was "100" and `code: main.tf:148` was 80; `git log --all -S'max_connections'`, `git branch -a --list '*max*conn*'` and `gh pr list --state open --search 'max_connections'` returned nothing (10:02-10:04).
- **Delivery model:** `UNVERIFIED` in the repo (no CI, GitOps or PR-automation config); operator-stated at `[F2]`: direct apply from the operator's workstation, no PR. **Env selection:** `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars`), default workspace (operator-stated, `iac-change.3`).
- **Target check:** `aws sts get-caller-identity` at 10:00, 10:55, 10:59, 11:21 and 11:22 -> account 123456789012, role `paymentapi-operator`, region ap-southeast-1 (`code: envs/prod.tfvars:2`). Always matched; no `[H1]`.
- **Read batch:** 22 read-only commands approved at `[F1]` (10:05); run 10:10-10:31. Terraform drift check: No changes.
- **Operator-stated (unverified):** tier prod, delivery model, default workspace, Q3 (not peak), Q6 (negligible cost), `iac-change.4` (applied recently).
- **Gaps:** application source not available (Q8 = c); last successful apply (no backend block, no state read); effect of 200 connections on instance memory (no documentation read); ECS cluster name inferred from the naming pattern (it answered); the ECS task security group `sg-0c9d8e7f6a5b43210` (live) differs from the app security group the DB ingress rule allows, `sg-0a1b2c3d4e5f6a7b8` (`code: envs/prod.tfvars:5`): not a fact this plan changes or relies on, not a drift row, unresolved.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| `max_connections` | `code: main.tf:14-15` -> "100" | `live: aws rds describe-db-parameters ... (10:15)` -> 100, user, static, pending-reboot | match |
| Parameter group in use | `code: main.tf:9` name_prefix `paymentapi-${var.env}-` | `live: aws rds describe-db-instances (10:14)` -> `paymentapi-prod-20250617043012345600000001`, in-sync | match |
| Instance class | `code: envs/prod.tfvars:6` -> db.r6g.large | `live: (10:14)` -> db.r6g.large | match |
| Multi-AZ | `code: main.tf:62` -> true for prod | `live: (10:14)` -> true | match |
| Pending instance changes | none | `live: (10:14)` {}; `live: aws rds describe-pending-maintenance-actions (10:18)` none | match |
| Connections alarm | `code: main.tf:148-149` -> 80, "(limit: 100)" | `live: aws cloudwatch describe-alarms --alarm-names ... (10:26)` -> 80, same text, enabled | match |
| Alarm actions | `code: main.tf:155-156`, `envs/prod.tfvars:9` | `live: (10:26)` same SNS topic; `live: aws sns list-subscriptions-by-topic ... Protocol (10:31)` email, email | match (notify-only) |
| Drift | n/a | `live: terraform plan -refresh-only (10:13)` -> No changes | none |
| Recovery points | `code: main.tf:63` retention 7; `:67` deletion protection | `live: aws rds describe-db-snapshots (10:16)` 3 automated, newest 2026-11-09 02:05Z; restorable to 02:55Z | match |
| Consumer | `catalog: ...:41` ECS `paymentapi-svc-prod` | `live: aws ecs describe-services (10:23)` 3/3 running; `live: aws elbv2 describe-target-health (10:24)` 3 healthy | confirmed for this consumer; others not visible |
| Health | n/a | `live: (10:19-10:22, 10:29)` connections avg 50-53 / max 76-78 (limit 100); CPU avg 31-37 %, max 46.8 %; FreeableMemory min 6.10 GB; FreeStorage min 82 GB; no alarm firing | within the catalog envelope |
| Alarm flapping | `catalog: ...:49,53` | `live: aws cloudwatch describe-alarm-history (10:30)` 3 ALARM episodes in 7 days (8-12 min each) | consistent |

Drift rows: 0. Unverified rows: 2 (last successful apply; effect of 200 connections on instance memory).

## Change Plan

**Phase 1 of 2: raise max_connections to 200 and move the connections alarm with it (Terraform apply)**
- Files: `main.tf`
- Resources affected: `aws_db_parameter_group.paymentapi` (change, in place: `max_connections` 100 -> 200, `apply_method` pending-reboot); `aws_cloudwatch_metric_alarm.paymentapi_db_connections` (change, in place: threshold 80 -> 160, description "(limit: 100)" -> "(limit: 200)"). 0 to add, 0 to destroy. The alarm change was flagged at `[F2]` as outside the request and kept.
- Blast radius: the parameter group backs the one prod payments database used by `paymentapi-svc-prod` (3 tasks); the alarm notifies an email-only SNS topic.
- Disruption: none from this apply. In place; `max_connections` is static and stays `pending-reboot` until the reboot (`docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html`, read 2026-11-09: a static parameter takes effect only after a reboot); alarm updated in place (`docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html`, read 2026-11-09: PutMetricAlarm on an existing alarm updates it); confirmed by `plan:` (both `~ update in-place`).
- Rollback path: reversible in principle, untested. `git revert` -> plan -> apply restores 100 and 80 (previous values: `live:` 10:15, 10:26). No documentation was found that re-applying the old parameter value restores the prior state (lookup 11:03: no canned output): `untested`. After the reboot the old value also needs a second reboot.
- Success criteria: re-plan No changes; `max_connections` 200 pending-reboot; instance available with parameter group pending-reboot; alarm threshold 160 and OK; both alarms OK; no alarm in ALARM.

**Phase 2 of 2: reboot `paymentapi-db-prod` so the static parameter takes effect (operational command, no code change, no `[F3]`)**
- Command: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` (no `--force-failover`)
- Resources affected: instance `paymentapi-db-prod` (restart, no configuration change).
- Blast radius: every request of `paymentapi-svc-prod` that needs the database.
- Disruption: brief unavailability. A reboot restarts the engine and briefly interrupts connections; without `--force-failover` a Multi-AZ instance reboots in place (`docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html`, read 2026-11-09); Multi-AZ true (`live:` 10:14). Duration `UNVERIFIED`.
- Rollback path: a reboot cannot be undone; to return to 100, revert phase 1, apply, reboot again (untested). Recovery points: 3 automated snapshots, newest 2026-11-09 02:05Z, restorable to 02:55Z (`live:` 10:14, 10:16); a restore is a new instance and endpoint.
- Success criteria: instance available with parameter group in-sync; ECS running = desired = 3; all target-group targets healthy; no alarm in ALARM. No re-plan (no IaC change).

**Execution path:** Direct apply · **Staging-first (H7):** (a) no staging env — `envs/prod.tfvars` is the only var-file · **Branch:** `main` -> `iac-change/paymentapi-max-connections-200` from `origin/main` @ `a1b2c3d` · **Self-check:** 8/8 (item 6 carried the alarm flag) · **Drift (H4):** none

## Execution Log
### Phase 1: raise max_connections to 200 and move the connections alarm (prod)
- Files changed: `main.tf` (2 hunks: parameter group lines 13-17; alarm lines 148-149)
- Self-check: plan 8/8 · diff 6/6, no accepted failures
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 2 to change, 0 to destroy (both `update in-place`)
- Plan hash: `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` (`terraform show -no-color tfplan`)
- Parity check: n/a
- Pre-flight verdict: RED — soft block (6 of 11 Yellow or unknown: Yellow 1 Blast radius, 2 Reversibility, 4 Dependency impact, 7 Observability readiness, 10 Resource health; unknown 11 Application compatibility). Acknowledged at `[H5]`, 11:09, operator reason: "maintenance window approved, DBA on call, the failover is expected". Mitigations committed: none stated beyond the acknowledgement (mitigations offered: reboot in the approved window; confirm or take a snapshot; tell the app-tier owners; reboot right after the apply or move the alarm change after the reboot; check the connection-pool size; provide the application source).
- Execution: `terraform apply tfplan` at 11:14, approved at `[F4]` (11:09-11:14) -> `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` Direct apply from the operator's workstation, not through CI/CD.
- Verification (11:15-11:20): re-plan `terraform plan -var-file=envs/prod.tfvars` -> No changes; `describe-db-parameters max_connections` -> ParameterValue 200, ApplyMethod pending-reboot; `describe-db-instances` -> status available, ParameterApplyStatus pending-reboot; `describe-alarms --alarm-names paymentapi-db-connections-high-prod` -> Threshold 160, "(limit: 200)", ActionsEnabled true, OK; `describe-alarms --alarm-name-prefix paymentapi` -> both alarms OK; `describe-alarms --state-value ALARM` -> none. All six pass. (The canned alarm file carries its own update time, 2026-11-09T03:21:40Z, earlier than this run's apply.)

### Phase 2: reboot paymentapi-db-prod (prod)
- Files changed: none (operational command)
- Self-check: plan 8/8 · diff n/a (no code change)
- Fresh eyes: skipped — no diff (operational phase); the pre-flight did not need it (verdict RED — soft block)
- Plan output summary: none — no plan run (operational command; target re-check 11:21 matched)
- Plan hash: none — operational command (`aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`)
- Parity check: n/a
- Pre-flight verdict: RED — soft block (Red 1 Blast radius; Yellow 2 Reversibility, 3 Change velocity, 4 Dependency impact, 7 Observability readiness, 10 Resource health; unknown 11 Application compatibility). Acknowledged at `[H5]`, 11:31, operator reason: "maintenance window approved, DBA on call, the failover is expected". Mitigations committed: none stated beyond the acknowledgement.
- Execution: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` at 11:36, approved at `[F4]` (11:31-11:36; Q1-Q3 re-asked, unchanged) -> `DBInstanceStatus: rebooting`.
- Verification (11:37-11:41): `describe-db-instances` -> `rebooting` (11:37), then `available` with ParameterApplyStatus `in-sync` (11:38); `ecs describe-services` -> running 3 = desired 3; `elbv2 describe-target-health` -> 3 healthy; `describe-alarms --state-value ALARM` -> none. All pass. The effective `max_connections` inside PostgreSQL was not read (no database command is run); `in-sync` on the parameter group is the evidence.

## Outcome
completed

**Applied:** yes — verified (phase 1: re-plan No changes, `max_connections` 200 and alarm threshold 160 read back at 11:15-11:19, parameter group `pending-reboot`; phase 2: instance `available` with parameter group `in-sync` at 11:38, ECS 3/3, 3 healthy targets, no alarm firing at 11:39-11:41)

## Ticket Reference
none
