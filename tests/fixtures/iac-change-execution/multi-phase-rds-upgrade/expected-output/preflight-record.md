<!-- Two pre-flight records, one per phase, as pre-flight (inline mode, caller: iac-change-execution) would write them. Dry run: not written into the fixture.
     Record 1: .culiops/pre-flight/paymentapi-max-connections-200-20261109-1109.md
     Record 2: .culiops/pre-flight/paymentapi-rds-reboot-20261109-1131.md -->

# Record 1 of 2 — `.culiops/pre-flight/paymentapi-max-connections-200-20261109-1109.md`

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Phase 1: raise `max_connections` 100 -> 200 (parameter group, `apply_method` pending-reboot) and move the connections alarm threshold 80 -> 160, by Terraform apply
**Date:** `2026-11-09 11:09` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes)
**Target:** `123456789012 / ap-southeast-1` | `-var-file=envs/prod.tfvars, default workspace`
**Plan hash:** `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d`
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** `direct apply from the operator's workstation, no PR — local workstation apply, not going through CI/CD pipeline` (`UNVERIFIED in the repo — operator-stated at [F2]`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (the caller's 22 reads)`
**App source:** `not available — category 11 unknown (Q8 = c)`

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | 2 resources; the parameter group backs the one prod payments database used by `paymentapi-svc-prod` (3 tasks). Disruption of this apply: none (in place; takes effect at the reboot) | `plan: 0 to add, 2 to change`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html (2026-11-09)`; `live: describe-db-instances, ecs describe-services (caller, 10:14, 10:23)` | The reboot is phase 2: do it in the approved window with the DBA present; watch target health |
| 2 | Reversibility | 🟡 | Old values known and revert is plan and apply, but the parameter revert needs a second reboot and no documentation shows that re-applying the old value restores the prior state: manual, untested. No data change; 3 automated snapshots, restorable to 02:55Z | `live: describe-db-parameters, describe-db-snapshots, describe-db-instances (caller, 10:15, 10:16, 10:14)`; `docs: D1 (above), https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html (2026-11-09)`; docs lookup 11:03 `no canned output` | Operator action: confirm the 02:05Z snapshot is recent enough or take a manual one before the reboot; keep the revert ready |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` / `envs/prod.tfvars` in 7 days; no stacked work (only this change's own diff); no open PR | `git: log --since=7.days origin/main empty (11:00)`; `git: status --short -> M main.tf (11:01)`; `gh: pr list empty (11:02)` | — |
| 4 | Dependency impact | 🟡 | Downstream consumer: ECS `paymentapi-svc-prod` (3 of 3 running, 3 healthy targets). One consumer found; others not visible. No output or export changes | `catalog: .culiops/service-discovery/paymentapi-prod.md:41`; `live: ecs describe-services, elbv2 describe-target-health (caller, 10:23, 10:24)`; `plan: no outputs changed` | Tell the app-tier owners about the reboot; watch the ECS service and the 3 targets |
| 5 | Timing context | 🟢 | No incident (Q1), no freeze (Q2), someone on hand (Q7). Q3 "not peak" operator-stated; live connections avg 50-53 are at the catalog baseline ~50 | `operator: Q1, Q2, Q7`; `operator-stated: Q3`; `live: DatabaseConnections (caller, 10:19)`; `catalog: ...:49` | — |
| 6 | Operator familiarity | 🟢 | many times on this service; experienced with Terraform | `operator: Q4, Q5` | — |
| 7 | Observability readiness | 🟡 | Alarms on the changed resource exist and are enabled (connections, CPU; email subscribers), both static thresholds. The connections alarm moves to 160 while the effective limit stays 100 until the reboot, so between the phases it cannot fire even if connections hit the limit | `live: describe-alarms, describe-alarms-for-metric, sns protocols (caller, 10:25-10:28, 10:31)`; `plan: threshold 80 -> 160`; `docs: D1` | Reboot right after the apply, or strike the alarm hunk and apply the threshold after the reboot; after the apply confirm the alarm stays OK and does not enter INSUFFICIENT_DATA |
| 8 | Cost impact | 🟢 | 0 to add, 2 to change; no class, storage or count attribute changes. Q6 negligible (operator-stated) | `plan: 0 to add, 2 to change`; `operator-stated: Q6` | — |
| 9 | Security posture | 🟢 | No IAM, security-group, encryption, public-access or audit-logging change | `plan: only parameter-group and alarm attributes change` | — |
| 10 | Resource health | 🟡 | DB available, no pending maintenance, no alarm firing, 3 of 3 targets healthy, CPU max 46.8 %, FreeableMemory min 6.10 GB, FreeStorage min 82 GB. Connection saturation peak 78 of 100 = 78 % (default threshold 70 %); 3 ALARM episodes of the connections alarm in 7 days. Error rate and latency not read | `live: describe-db-instances, describe-pending-maintenance-actions, metrics, ecs, elbv2, alarms (caller, 10:14-10:30)` | Check the connection-pool size against the new limit; watch FreeableMemory once the limit is real (effect of 200 connections `UNVERIFIED`) |
| 11 | Application compatibility | ⚪ | `max_connections` is app-facing (assessor: limits the app must fit inside) and the application source is not available: fail-closed. The alarm hunks are not app-facing (notify-only: subscriber protocols email, email) | `assessor: app-facing table`; `operator: Q8=(c)`; `live: sns protocols (caller, 10:31)` | Provide the application source (Q8 (a) or (b)) or confirm the pool maximum and reconnect behaviour by hand |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| `max_connections` | `code: main.tf:14-15` 100 -> `plan:` 200 | `live: describe-db-parameters (caller, 10:15)` 100, static, pending-reboot | ✓ |
| Parameter group | `code: main.tf:9` name_prefix | `live: describe-db-instances (caller, 10:14)` `paymentapi-prod-20250617043012345600000001` in-sync | ✓ |
| Multi-AZ | `code: main.tf:62` true for prod | `live: (caller, 10:14)` true | ✓ |
| Connections alarm | `code: main.tf:148-149` 80 -> `plan:` 160 | `live: describe-alarms (caller, 10:26)` 80, enabled, OK | ✓ |
| Alarm actions | `code: main.tf:155-156` SNS topic | `live: (caller, 10:26, 10:31)` same topic, protocols email, email | ✓ |
| Drift | n/a | `live: terraform plan -refresh-only (caller, 10:13)` No changes | ✓ none |
| Last successful apply | n/a | not read (no backend block) | UNVERIFIED (operator-stated recent) |

No drift rows. Unverified: last successful apply; effect of 200 connections on instance memory.

## Verification
- Citations checked: 12 (fixed: none). Every Green on categories 1, 2, 4, 7, 9, 10, 11 re-checked: category 9 only, and its plan citation says what the finding says. `docs:` pages read this session (2026-11-09): USER_WorkingWithParamGroups.html, API_PutMetricAlarm.html.
- Verdict working: Red = none; Yellow + ⚪ = 6 (1, 2, 4, 7, 10, 11) -> 3 or more escalates to RED — soft block; hard blocks checked: irreversible data change (no), incident with freeze (no), public exposure / encryption removal / secrets (no), error budget exhausted (no SLO declared, no alarm firing) -> none triggered.
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q3 and Q6 (operator-stated); `iac-change.4` (operator-stated, no state-object read); error rate and latency (not read); effect of 200 connections on instance memory; other consumers of the database; that re-applying the old parameter value restores the prior state (docs lookup 11:03 returned no canned output).

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]`, 11:09, one reason for all: "maintenance window approved, DBA on call, the failover is expected". Items: 1 Blast radius (Yellow), 2 Reversibility (Yellow), 4 Dependency impact (Yellow), 7 Observability readiness (Yellow), 10 Resource health (Yellow), 11 Application compatibility (unknown), and the multi-Yellow escalation.

## Mitigations Committed
none stated by the operator beyond the acknowledgement (the mitigations in the scorecard were offered, not committed).

## Context Provided (L2)
From the caller block (`[F2]` answers, 10:44): Q1 no (operator); Q2 no, "the maintenance window is approved and there is no freeze" (operator); Q3 no, off-peak (operator-stated); Q4 many times (operator); Q5 experienced (operator); Q6 negligible (operator-stated); Q7 "DBA on the maintenance window and #payments-oncall told about the reboot" (operator); Q8 (c) application source not available (operator); `iac-change.4` recent (operator-stated). Also volunteered: `iac-change.1` yes, `iac-change.2` direct apply from the workstation, no PR, `iac-change.3` no (default workspace; the env's own var-file). Nothing was asked by pre-flight.

## L1 Analysis Detail
Plan: 0 to add, 2 to change, 0 to destroy; both updates in place (hash above). Plan hygiene: made with `-out` and the env's var-file only; no `-target`, no `-refresh=false`; refresh-only shows no drift; no unexpected resources. Git: no commit to the changed paths in 7 days; working tree has only this change's diff; no open PR. Catalog `.culiops/service-discovery/paymentapi-prod.md` read (a lead, not evidence). Changed attributes: `max_connections` app-facing; alarm threshold and description not app-facing.

## L3 Queries Run
Target check by pre-flight: `aws sts get-caller-identity` (10:59) -> account 123456789012, matches the caller's Target. The caller's results, cited as `live: <cmd> (caller, <time>)`: `aws --version` 10:10; `terraform version` 10:11; `terraform plan -refresh-only` 10:13; `aws rds describe-db-instances` 10:14; `describe-db-parameters` 10:15; `describe-db-snapshots` 10:16; `describe-events` 10:17; `describe-pending-maintenance-actions` 10:18; CloudWatch `DatabaseConnections` 10:19, `CPUUtilization` 10:20, `FreeableMemory` 10:21, `FreeStorageSpace` 10:22; `aws ecs describe-services` 10:23; `aws elbv2 describe-target-health` 10:24; `describe-alarms` (prefix) 10:25 and (connections alarm) 10:26; `describe-alarms-for-metric` 10:27, 10:28; `describe-alarms --state-value ALARM` 10:29; `describe-alarm-history` 10:30; `aws sns list-subscriptions-by-topic` (Protocol only) 10:31. No extra batch was needed.

Inline mode: verdict RED, so GATE 2 ran as the caller's `[H5]`; the report, the verdict and the operator's acknowledgement were returned to iac-change-execution.

---

# Record 2 of 2 — `.culiops/pre-flight/paymentapi-rds-reboot-20261109-1131.md`

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Phase 2: reboot RDS instance `paymentapi-db-prod` in place so the pending static `max_connections = 200` takes effect
**Date:** `2026-11-09 11:31` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: phase 1's applied code)
**Target:** `123456789012 / ap-southeast-1` | `RDS instance paymentapi-db-prod`
**Plan hash:** `none — not reusable` (operational command: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`)
**Plan source:** `the command text`
**Delivery model:** `direct apply from the operator's workstation, no PR — local workstation apply, not going through CI/CD pipeline` (`UNVERIFIED in the repo — operator-stated at [F2]`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (the caller's reads, before and after the phase-1 apply)`
**App source:** `not available — category 11 unknown (Q8 = c)`

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | Every request of `paymentapi-svc-prod` that needs the database (3 tasks) is on the data path. The reboot restarts the engine and briefly interrupts connections; without `--force-failover` a Multi-AZ instance reboots in place, so Multi-AZ does not keep it up. Duration `UNVERIFIED` | `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html (2026-11-09)`; `live: describe-db-instances, ecs describe-services, elbv2 describe-target-health (caller, 10:14, 10:23, 10:24)`; `catalog: ...:41` | Tell the app-tier owners; watch ECS and the target group through the reboot; keep the DBA on the instance status until `available` |
| 2 | Reversibility | 🟡 | A reboot cannot be undone and loses no data. Going back to 100 means reverting phase 1 and rebooting again: untested. Recovery points exist (3 snapshots, newest 02:05Z; restorable to 02:55Z); a restore is a new instance and endpoint | `docs: USER_WorkingWithParamGroups.html (2026-11-09)`; `live: describe-db-snapshots, describe-db-instances (caller, 10:16, 10:14)` | Confirm the 02:05Z snapshot is recent enough or take a manual one first |
| 3 | Change velocity | 🟡 | 0 commits in 7 days, but this phase stacks on phase 1: applied at 11:14 and still uncommitted (`git status`: M `main.tf`), so live is ahead of `main`. Scored conservatively; the exclusion of "this change's own commits" is not clearly meant for uncommitted, applied work | `git: log --since=7.days empty (11:23)`; `git: status --short (11:24)`; `live: terraform apply 11:14 (caller)` | Commit or merge the phase-1 code so `main` matches live |
| 4 | Dependency impact | 🟡 | The consumer (ECS `paymentapi-svc-prod`, 3 of 3 running) feels the interruption; other consumers not visible | `catalog: ...:41`; `live: (caller, 10:23, 10:24)` | As category 1 |
| 5 | Timing context | 🟢 | Q1 no, Q2 no, someone on hand (DBA, #payments-oncall told). Q3 "not peak" operator-stated; live connections avg 50-53 at the catalog baseline. Q1-Q3 re-asked at the caller's `[F4]` | `operator: Q1, Q2, Q7`; `operator-stated: Q3`; `live: DatabaseConnections (caller, 10:19)` | — |
| 6 | Operator familiarity | 🟢 | many times, experienced | `operator: Q4, Q5` | — |
| 7 | Observability readiness | 🟡 | The alarms that exist watch CPU and connections only, static thresholds. Nothing alarms when the instance fails to return to `available`, or on target health. The connections alarm sits at 160, above the effective limit 100 until the reboot completes | `live: describe-alarms (caller, 10:25, 10:26, 11:18, 11:19)`; `docs: USER_WorkingWithParamGroups.html` | Watch the instance status by hand for this reboot |
| 8 | Cost impact | 🟢 | The command creates nothing and changes no size, class or count (operator-stated negligible) | `plan: the command text (reboot-db-instance)`; `operator-stated: Q6` | — |
| 9 | Security posture | 🟢 | No security-relevant change | `plan: the command text (reboot-db-instance)` | — |
| 10 | Resource health | 🟡 | Instance available with parameter group `pending-reboot` (11:17); no alarm firing (11:20); connection saturation peak 78 of 100 = 78 % (default threshold 70 %); the metric reads are about an hour old and predate the phase-1 apply | `live: describe-db-instances (caller, 11:17); describe-alarms --state-value ALARM (caller, 11:20); metrics (caller, 10:19-10:22)` | Re-read the instance status during the reboot (the success criteria do) |
| 11 | Application compatibility | ⚪ | The reboot makes the new `max_connections` real (app-facing); application source not available | `assessor: app-facing table`; `operator: Q8=(c)` | Provide the application source or confirm the pool maximum and reconnect behaviour by hand |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| `max_connections` | `code: main.tf:14-15` (working tree: 200) | `live: describe-db-parameters (caller, 11:16)` 200, pending-reboot | ✓ |
| Parameter group status | n/a | `live: describe-db-instances (caller, 11:17)` available, `pending-reboot` | ✓ expected before the reboot |
| Connections alarm | working tree: 160 | `live: describe-alarms (caller, 11:18)` 160, OK, enabled | ✓ |
| Drift | n/a | `live: terraform plan (caller, 11:15)` No changes | ✓ none |
| Multi-AZ, consumers, recovery points | as record 1 | `live: (caller, 10:14, 10:23, 10:24, 10:16)` | ✓ |

## Verification
- Citations checked: 11 (fixed: none). Every Red and every Green on categories 1, 2, 4, 7, 9, 10, 11 re-checked: category 1 (Red) cites D3, which says what the finding claims about the reboot; category 9 cites the command text.
- Verdict working: Red = category 1; Yellow + ⚪ = 6 (2, 3, 4, 7, 10, 11) -> RED — soft block (a Red category, and the multi-Yellow escalation); hard blocks checked: irreversible data change (no), incident with freeze (no), public exposure / encryption removal / secrets (no), error budget exhausted (no) -> none triggered.
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q3 and Q6 (operator-stated); `iac-change.4` (operator-stated); how long the interruption lasts; whether a forced failover would be shorter (not in the documentation read); metric reads that predate the apply; other consumers of the database.

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]`, 11:31, one reason for all: "maintenance window approved, DBA on call, the failover is expected". Items: 1 Blast radius (Red), 2 Reversibility, 3 Change velocity, 4 Dependency impact, 7 Observability readiness, 10 Resource health (Yellow), 11 Application compatibility (unknown).

## Mitigations Committed
none stated by the operator beyond the acknowledgement.

## Context Provided (L2)
From the caller block (`[F2]` answers, 10:44; Q1-Q3 re-asked at the caller's `[F4]`, 11:31, unchanged): Q1 no (operator); Q2 no (operator); Q3 no (operator-stated); Q4 many times (operator); Q5 experienced (operator); Q6 negligible (operator-stated); Q7 "DBA on the maintenance window and #payments-oncall told about the reboot" (operator); Q8 (c) (operator); `iac-change.4` recent (operator-stated).

## L1 Analysis Detail
No plan text: the command is the plan text, so the plan hash is `none` and this record is not reusable. Git: `git log --since=7.days origin/main -- main.tf envs/prod.tfvars` empty (11:23); `git status --short` shows M `main.tf` (phase 1's applied, uncommitted code, 11:24); `gh pr list --state open` empty (11:25). Catalog read (a lead). The reboot applies the static `max_connections` (app-facing).

## L3 Queries Run
Target check by pre-flight: `aws sts get-caller-identity` (11:22) -> account 123456789012, matches the caller's Target. The caller's results, cited as `live: <cmd> (caller, <time>)`: the 22 reads of 10:10-10:31 (as record 1) and, after the phase-1 apply, `terraform plan` 11:15 (No changes), `describe-db-parameters` 11:16 (200, pending-reboot), `describe-db-instances` 11:17 (available, pending-reboot), `describe-alarms` 11:18 (threshold 160) and 11:19 (both OK), `describe-alarms --state-value ALARM` 11:20 (none). No extra batch was needed.

Inline mode: verdict RED, so GATE 2 ran as the caller's `[H5]`; the report, the verdict and the operator's acknowledgement were returned to iac-change-execution.
