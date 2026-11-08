**IaC change execution for:** `paymentapi` / `prod`
**Change:** Increase `max_connections` to 200 on `paymentapi-db-prod` and reboot so it takes effect (operator request); the connections alarm threshold and description were aligned to the new limit (alarm item shown at GATE 1, kept by the operator)
**Date:** `2026-11-09 13:07`
**Commit:** `a1b2c3d` (HEAD of `origin/main`; the change itself is an uncommitted edit of `main.tf` on branch `iac-change/paymentapi-max-connections-200`: the direct-apply path has no commit step)
**IaC tool(s):** Terraform (`hashicorp/aws` v5.74.0 per `terraform init`); AWS CLI for the phase-2 reboot
**Execution path:** Direct apply (operator-requested, from the operator's workstation, no PR)
**Pre-flight record:** phase 1: `.culiops/pre-flight/paymentapi-max-connections-200-20261109-1122.md` (RED — soft block); phase 2: `.culiops/pre-flight/paymentapi-rds-reboot-20261109-1237.md` (RED — soft block). Both invoked inline.
**Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset)
**Prerequisites (`examples/aws.md`):** AWS CLI v2 (`aws --version` >= 2.x); authentication by an assumed role (`paymentapi-operator`), identity confirmed with `aws sts get-caller-identity` (account 123456789012); Tier 1 read-only permissions for Steps 1 and 5, Tier 2 elevated permissions only for the apply and the reboot; CloudWatch `GetMetric*` calls carry a small per-call cost.

## Research Summary
- Catalog used: `.culiops/service-discovery/paymentapi-prod.md` (downstream: ECS `paymentapi-svc-prod`).
- Duplicate check: **not done** — `code: main.tf:15` still `"100"`; `git: git log --all -S'max_connections'` no hit; no in-flight branch or PR (`gh pr list`).
- Delivery model: applied by hand from the operator's workstation (`operator-stated`; no CI, GitOps or PR automation found in the repo files). Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars`). No `backend` block in `main.tf`; workspace not read.
- Target check: `aws sts get-caller-identity` -> account 123456789012, role `paymentapi-operator`; plan is for prod; match yes (checked in the Step 1 batch 10:09, at each 4a, in each pre-flight L3, and re-shown at each GATE 4).
- Key findings: `max_connections` is a static parameter, so the new value needs a reboot (`docs:` USER_WorkingWithParamGroups); the instance is Multi-AZ and the reboot is in place (`docs:` USER_RebootInstance); the connections alarm hardcodes the old limit (`code: main.tf:148-149`).
- Gaps remaining at the end: last successful apply of the stack; effective runtime `max_connections` (needs a DB session); app behaviour on reconnect (no application source, Q8 = c); other consumers of the DB. The `docs:` lookup for an in-place alarm update returned `no canned output`; the 4a plan settled that item.

## Evidence
| Fact | Code evidence | Live evidence | Match |
|------|---------------|---------------|-------|
| `max_connections` current value | `code: main.tf:15` -> `"100"` | `live: describe-db-parameters (10:13)` -> `100`, `static`, `pending-reboot` | ✅ |
| `max_connections` is static: effective only after a reboot | `code: main.tf:19-22` | `live: ApplyType static (10:13)`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html` (2026-11-09) | ✅ |
| Instance class, Multi-AZ, status | `code: main.tf:47`, `code: envs/prod.tfvars:6`, `code: main.tf:62` | `live: describe-db-instances (10:12)` -> `db.r6g.large`, `MultiAZ true`, `available` | ✅ |
| Parameter group attached | `code: main.tf:58` | `live: describe-db-instances (10:12)` -> `paymentapi-prod-20250617043012345600000001`, `in-sync` | ✅ |
| Connections alarm threshold and description | `code: main.tf:148-149` -> `80`, `limit: 100` | `live: describe-alarms (10:14)` -> `80.0`, same description, actions enabled, `OK` | ✅ |
| No drift in managed resources | — | `live: terraform plan -refresh-only (10:11)` -> `No changes.` | ✅ |
| What connects to the DB | `catalog: paymentapi-prod.md:40-42`; `code: main.tf:89-95` | `live: ecs describe-services (10:15)` -> 3/3 running behind `paymentapi-tg-prod` | ✅ (other consumers `UNVERIFIED`) |
| Reboot behaviour on Multi-AZ | — | `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html` (2026-11-09): engine restarts, connections briefly interrupted; failover only with `--force-failover` | ✅ |

Drift rows: 0. Unverified rows: 0. Runner note kept out of the table: the ECS task security group read at 10:15 differs from `app_security_group_id` in `envs/prod.tfvars:5`; no plan item depends on it, so no drift row was raised.

## Change Plan
**Phase 1 of 2: Raise `max_connections` to 200 in the parameter group, align the connections alarm**
- Files: `main.tf`
- Resources affected: change in place — `aws_db_parameter_group.paymentapi` (`max_connections` 100 -> 200, `apply_method pending-reboot`), `aws_cloudwatch_metric_alarm.paymentapi_db_connections` (threshold 80 -> 160, description). 0 add, 2 change, 0 destroy.
- Blast radius: the parameter group of the one prod payments DB; apply alone changes nothing at runtime.
- Disruption: parameter group none at apply (`docs:` USER_WorkingWithParamGroups; `live:` ApplyType static); alarm `UNVERIFIED` until the 4a plan (confirmed `update in-place`).
- Rollback path: reversible, untested — git revert, plan, apply; the old value returns only after another reboot.
- Success criteria: re-plan -> `No changes`; `describe-db-parameters … max_connections` -> `200`, `pending-reboot`; `describe-db-instances` -> `available`, `ParameterApplyStatus pending-reboot`; `describe-alarms --alarm-names paymentapi-db-connections-high-prod` -> Threshold `160`.

**Phase 2 of 2: Reboot `paymentapi-db-prod` so `max_connections=200` takes effect**
- Files: none (`aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`, no `--force-failover`)
- Resources affected: `aws_db_instance.paymentapi` — restart, no code change.
- Blast radius: every connection to the prod payments DB is dropped; the app tier (3 ECS tasks) reconnects.
- Disruption: brief unavailability, in place (`docs:` USER_RebootInstance; `live:` `MultiAZ true` does not soften an in-place reboot). Duration `UNVERIFIED`.
- Rollback path: a reboot cannot be undone; revert + apply + a second reboot restores the old value. Reversible, untested.
- Success criteria: `describe-db-instances` -> `available`, `ParameterApplyStatus in-sync`; `describe-db-parameters … max_connections` -> `200`; `describe-target-health` -> 3 `healthy`; ECS `runningCount` 3.

Execution path: Direct apply. Branch: `main` -> `iac-change/paymentapi-max-connections-200` from `origin/main` @ `a1b2c3d`. Plan self-check: 5/6 (item 1: alarm disruption without a `docs:` or `live:` source until the 4a plan).

## Execution Log
### Phase 1: Raise `max_connections` to 200, align the connections alarm
- Files changed: `main.tf` (two hunks; left uncommitted on the change branch)
- Self-check: plan 5/6 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 2 to change, 0 to destroy (both `update in-place`)
- Plan hash: `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d`
- Pre-flight verdict: RED — soft block (multi-Yellow escalation: 1, 2, 4, 7, 9, 10 Yellow; 11 ⚪). Acknowledged at the pre-flight risk decision and at GATE 3, reason: "maintenance window approved, DBA on call, the failover is expected." No mitigation committed.
- Execution: `terraform apply tfplan` (11:37) -> `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.`
- Verification (after the apply, 11:38-11:47):
  - re-plan `terraform plan -out=tfplan -var-file=envs/prod.tfvars` -> `No changes. Your infrastructure matches the configuration.`
  - `aws rds describe-db-parameters … --query "Parameters[?ParameterName=='max_connections']"` -> `ParameterValue "200"`, `ApplyMethod pending-reboot`
  - `aws rds describe-db-instances … --query 'DBInstances[].{status:DBInstanceStatus,pending:PendingModifiedValues,params:DBParameterGroups}'` -> `available`, `PendingModifiedValues {}`, `ParameterApplyStatus pending-reboot` (was `in-sync` at 10:12; expected until the reboot)
  - `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod` -> Threshold `160.0`, `OK` (was `80.0`)
  - `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` -> both alarms `OK`

### Phase 2: Reboot `paymentapi-db-prod` so `max_connections=200` takes effect
- Files changed: none (the working tree still carries phase 1's applied edit of `main.tf`)
- Self-check: diff 5/6 (item 1, scope: `main.tf` changed but outside this phase's empty file list; it is phase 1's applied edit, uncommitted)
- Fresh eyes: not run — dry run
- Plan output summary: none — no plan or diff command exists for a reboot
- Plan hash: none (pre-flight record not reusable)
- Pre-flight verdict: RED — soft block (category 1 Red; 2, 4, 7, 9, 10 Yellow; 11 ⚪). Acknowledged at the pre-flight risk decision and at GATE 3, reason: "maintenance window approved, DBA on call, the failover is expected." No mitigation committed.
- Execution: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` (12:52) -> `DBInstanceStatus rebooting`; monitored until `available` (12:54).
- Verification (after the reboot, 12:55-13:06):
  - re-plan -> `No changes. Your infrastructure matches the configuration.`
  - `aws rds describe-db-instances …` -> `available`, `PendingModifiedValues {}`, `ParameterApplyStatus in-sync` (was `pending-reboot` at 12:23)
  - `aws rds describe-db-parameters … max_connections` -> `ParameterValue "200"`
  - `aws elbv2 describe-target-health …` -> 3 targets `healthy` (3 before)
  - `aws ecs describe-services …` -> desired 3, running 3 (3 before)
  - `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` -> both alarms `OK`
  - `aws cloudwatch get-metric-statistics … DatabaseConnections` -> average 50-53, max 76-78: the same canned read as before the reboot, so it shows no post-reboot datapoints; connection recovery is `UNVERIFIED`.
  - Not read: the effective runtime value (`SHOW max_connections`).

## Outcome
completed (2 of 2 phases)

**Applied:** yes — verified (parameter group `in-sync` and `max_connections` 200 after the reboot, alarm threshold 160, re-plan clean, app tier 3/3 healthy; the effective runtime value and the connection count after the reboot were not read)

## Ticket Reference
none
