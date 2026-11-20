# Pre-flight records written by the inline runs (two: one per phase)

Both ran inline for iac-change-execution; neither is a reuse (no earlier record; phase 2 has `Plan hash: none`). Not committed.

---

## Record 1 — phase 1 (apply)

Path: `.culiops/pre-flight/paymentapi-raise-max-connections-20261109-1118.md`

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Terraform apply: `max_connections` 100 → 200 on the parameter group (static, applied at the next reboot) and the connections alarm threshold 80 → 160
**Date:** `2026-11-09 11:18` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `123456789012 / ap-southeast-1` | n/a | default workspace · `-var-file=envs/prod.tfvars` · no backend declared in the code
**Plan hash:** `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** direct apply from the operator's workstation, not through CI/CD (`operator-stated`, first message; UNVERIFIED in the repo: no CI config, `gh run list` → `[]`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's results)`
**App source:** `local ../paymentapi @ c0a7e93 (v2.4.1, the deployed ref; the checkout's HEAD 5d1c8e4 differs and was read without checkout)`

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | two resources, one a parameter group of the shared database; no disruption at apply time | `plan: aws_db_parameter_group.paymentapi update in-place`, `plan: aws_cloudwatch_metric_alarm.paymentapi_db_connections update in-place`, `docs: USER_WorkingWithParamGroups.html (read 2026-11-09)`, `live: describe-db-parameters 10:21` | the reboot is scored by phase 2's own pre-flight |
| 2 | Reversibility | 🟢 | in place; reverting a parameter restores it; alarm update is in place; recovery points exist | `plan:`, `docs: USER_WorkingWithParamGroups.html`, `docs: API_PutMetricAlarm.html`, `live: describe-db-snapshots 10:22` | — |
| 3 | Change velocity | 🟢 | 0 commits to the changed paths in 7 days; nothing stacked; automation lag `UNVERIFIED` | `git: log --since=7.days (11:12)`, `live: gh run list 10:33` | — |
| 4 | Dependency impact | 🟡 | the ECS service depends on the database; one consumer in the catalog, confirmed by code and live | `catalog: paymentapi-prod.md:41`, `code: main.tf:94`, `live: describe-services 10:28` | S2 reads the service, ALB and targets after the apply; `[H10]` on a regression |
| 5 | Timing context | 🟢 | no firing alarm, no declared incident, no freeze, not peak (1.02×); the operator applies it himself | `live: describe-alarms 11:06`, `live: get-metric-data 11:07`, `operator` | — |
| 6 | Operator familiarity | 🟢 | many times, experienced | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟡 | both DB alarms exist, are enabled and notify; static thresholds; the connections alarm (160) sits above the live limit (100) until the reboot | `live: describe-alarms-for-metric 10:23, 10:24`, `code: main.tf:116-156` | do the reboot straight after, or keep the alarm at 80 until then (operator action) |
| 8 | Cost impact | 🟢 | no new resource, no size change | `plan: 0 to add, 2 to change, 0 to destroy` | — |
| 9 | Security posture | 🟢 | no IAM, network, encryption, public-access or logging change | `plan:`, `code: diff` | — |
| 10 | Resource health | 🟡 | no alarm, no errors, CPU 33.8%; connection saturation 78% of the limit (max 78 of 100), above 70% | `live: get-metric-data 11:07`, `live: describe-db-parameters 10:21` | the change exists to relieve this; apply in the maintenance window |
| 11 | Application compatibility | 🟢 | the pool (20 + 5 per process by default) fits inside 100 and 200; the alarm change is notify-only | `app:paymentapi@c0a7e93:app/config.py:6-7`, `app:paymentapi@c0a7e93:app/db.py:11-13`, `live: SNS protocols 10:27` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| `max_connections` | `code: main.tf:14-15` 100; `plan-prod.txt:28-37` → 200 | `live:` 100, static, 10:21 | ✓ |
| connections alarm | `code: main.tf:148-149`; `plan:` 80 → 160 | `live:` 80, enabled, OK, 10:23 | ✓ |
| drift | no "Objects have changed outside of Terraform" block | `terraform plan -refresh-only` 10:19: no changes | none |
| delivery model | none in the repo | `gh run list` → `[]` | UNVERIFIED (operator-stated) |

## Verification
- Citations checked: 9 (the Greens on 2, 9 and 11; the premises of each mitigation; the `docs` entries) (fixed: category 3 — the unread automation lag was moved to Not verified instead of being assumed)
- Verdict working: Red = none; Yellow + ⚪ = 4 (1, 4, 7, 10); hard blocks checked: irreversible data change (2), incident + freeze (5), public exposure / encryption / secrets (9), exhausted error budget (10) → none → RED — soft block (3 or more Yellow)
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model (`operator-stated`); `Q1(declared)` and `Q2` (`operator`, no objection); last apply of the stack; the task definition's pool variables and the process count per task; the running value inside PostgreSQL; other consumers of the database (catalog lead)

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]` 11:23 (inline: pre-flight's GATE 2), each of categories 1, 4, 7, 10, reason word for word: "maintenance window approved, DBA on call, the failover is expected" (operator, 11:23). Carried to `[F4]` 11:28.

## Mitigations Committed
S2 and `[H10]` after the apply; keep the reboot close behind the apply (the connections alarm is above the live limit until then).

## Context Provided (L2)
- Q1: `Q1(alarms)=no` (`live: describe-alarms --state-value ALARM`, 11:06, 0 firing); `Q1(declared)=no` (`operator (no objection at [F2], 10:50)`)
- Q2: no (`operator (no objection at [F2], 10:50)`; no freeze calendar in the repo)
- Q3: no (`live: get-metric-data`, 11:07: 690.7/min vs 680.3/min, 1.02×)
- Q4: many times (`operator (profile, 2026-10-19)`); Q5: experienced (`operator (profile, 2026-10-19)`)
- Q6: scored from the plan (no new resource)
- Q7: none (`operator (no objection at [F2], 10:50)`)
- Q8: `../paymentapi @ v2.4.1` (`app:`; operator confirmed the checkout at `[F2]`)
- iac-change.1: yes (`plan:`); .2: direct apply (`operator-stated`); .3: no (`plan:` command, default workspace); .4: unsure (`UNVERIFIED — no state backend in the code, no CI history`)

## L1 Analysis Detail
Plan text: two in-place updates (parameter block replaced, alarm threshold and description). Catalog `.culiops/service-discovery/paymentapi-prod.md` used. Git history: no commit to `main.tf` or `envs/prod.tfvars` in 7 days. `max_connections` marked app-facing; alarm attributes not-app-facing (notify-only).

## L3 Queries Run
The caller's results, each `live: <cmd> (caller, <time>)`: `terraform plan -refresh-only` 10:19; `describe-db-instances` 10:20; `describe-db-parameters` 10:21; `describe-db-snapshots` 10:22; `describe-alarms-for-metric` ×2 10:23-10:24; `describe-alarms --alarm-name-prefix paymentapi` 10:25; `describe-alarm-history` 10:26; SNS protocols 10:27; `describe-services` 10:28; `describe-target-health` 10:29; `describe-target-groups` / `describe-load-balancers` 10:30-10:31; `describe-task-definition` (images) 10:32; `gh run list` 10:33; sibling reads 10:34-10:37; S0 10:38-10:39; S1 11:06-11:10. Pre-flight's own: `aws sts get-caller-identity` 11:11 (target matches); local `git log` 11:12; app-source reads 11:13-11:18 (`status`, `describe`, `rev-parse v2.4.1`, `grep` and `show` at `v2.4.1`).

---

## Record 2 — phase 2 (reboot)

Path: `.culiops/pre-flight/paymentapi-reboot-max-connections-20261109-1151.md`

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** operational command: reboot `paymentapi-db-prod` in place so the static `max_connections` = 200 takes effect
**Date:** `2026-11-09 11:51` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`, this change's own phase-1 edit, already applied)
**Target:** `123456789012 / ap-southeast-1` | n/a | default workspace · `-var-file=envs/prod.tfvars`
**Plan hash:** `none — not reusable` (operational command)
**Plan source:** `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` (the command text)
**Delivery model:** direct apply from the operator's workstation, not through CI/CD (`operator-stated`; UNVERIFIED in the repo)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's results)`
**App source:** `local ../paymentapi @ c0a7e93 (v2.4.1, read in phase 1 and reused)`

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | the shared database behind the payment API restarts in place; every connection is interrupted briefly; Multi-AZ exists but is not used (no `--force-failover`) | `docs: USER_RebootInstance.html (read 2026-11-09)`, `live: describe-db-instances 11:49`, `live: describe-services 11:47` | run in the maintenance window with the DBA on call; S2 and `[H10]` after |
| 2 | Reversibility | 🟡 | no data change, but a reboot cannot be undone; the way back is the parameter revert plus a second reboot, untested | `docs: USER_WorkingWithParamGroups.html (read 2026-11-09)`, `live: describe-db-snapshots 10:22` | recovery point exists (newest 2026-11-09 02:05Z); revert plan is the phase-1 rollback |
| 3 | Change velocity | 🟢 | no commit to the changed paths in 7 days; the only recent change is this change's own phase 1 (11:29), excluded as its own | `git: log --since=7.days (11:51)`, `live: terraform apply 11:29` | — |
| 4 | Dependency impact | 🟡 | the ECS service (3 tasks) is the consumer; no other in the catalog (a lead) | `catalog: paymentapi-prod.md:41`, `live: describe-services 11:47` | S2 on the service and targets |
| 5 | Timing context | 🟢 | no firing alarm, no declared incident, no freeze, not peak; operator applies it himself | `live: describe-alarms 11:45`, `live: get-metric-data 11:46`, `operator` | — |
| 6 | Operator familiarity | 🟢 | many times, experienced | `operator (profile, 2026-10-19)` | — |
| 7 | Observability readiness | 🟡 | DB alarms exist, enabled, notify; static thresholds; after the reboot the connections alarm (160) matches the limit (200) | `live: describe-alarms 11:33`, `code: main.tf:116-156` | confirm the alarm stays `OK` after the reboot (success criteria) |
| 8 | Cost impact | 🟢 | the command adds no resource and changes no size | `code: the command text` | — |
| 9 | Security posture | 🟢 | no security-relevant change | `code: the command text` | — |
| 10 | Resource health | 🟡 | no alarm, no errors; connection saturation 78% of the live limit 100 until the reboot | `live: get-metric-data 11:46`, `live: describe-db-parameters 11:31` | the reboot is what lifts the limit |
| 11 | Application compatibility | 🟡 | the reboot interrupts the app's connections; `pool_pre_ping` replaces dead connections on checkout, so the app recovers, but requests during the outage fail and no retry was found in the two files read | `app:paymentapi@c0a7e93:app/db.py:10-13` | S2 after the reboot (5xx and target health) |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| parameter applied, pending the reboot | `code: main.tf` (after phase 1) | `live: describe-db-parameters 11:31` 200; `describe-db-instances 11:49` `pending-reboot` | ✓ |
| Multi-AZ | `code: main.tf:62` | `live: describe-db-instances 11:49` true | ✓ |
| delivery model | none in the repo | `gh run list` → `[]` | UNVERIFIED (operator-stated) |

## Verification
- Citations checked: 8 (the Greens on 9; the reboot behaviour claims against `docs`; the `app:` lines; the mitigations) (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 6 (1, 2, 4, 7, 10, 11); hard blocks checked: 2, 5, 9, 10 → none → RED — soft block (3 or more Yellow)
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model; `Q1(declared)` and `Q2` (`operator`, no objection); the task definition's pool variables; retry behaviour beyond the two files read; the running value inside PostgreSQL after the reboot

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]` 11:56, each of categories 1, 2, 4, 7, 10, 11, reason word for word: "maintenance window approved, DBA on call, the failover is expected" (operator, 11:56). Carried to `[F4]` 12:01.

## Mitigations Committed
S2 and `[H10]` after the reboot; the revert plan (parameter back to 100, then a second reboot) is the rollback, untested.

## Context Provided (L2)
- Q1: `Q1(alarms)=no` (`live: describe-alarms --state-value ALARM`, 11:45); `Q1(declared)=no` (`operator (no objection at [F2], 10:50)`, re-asked at `[F4]`, unchanged)
- Q2: no (`operator (no objection at [F2], 10:50)`); Q3: no (`live: get-metric-data`, 11:46: 1.02×)
- Q4: many times, Q5: experienced (`operator (profile, 2026-10-19)`); Q6: scored from the command (no cost); Q7: none (`operator (no objection at [F2], 10:50)`)
- Q8: `../paymentapi @ v2.4.1` (`app:`)
- iac-change.1: yes; .2: direct apply (`operator-stated`); .3: no (no plan for this phase); .4: recent (`live: this run's phase-1 apply, 11:29`)

## L1 Analysis Detail
The command text is the plan text. Catalog used. Git history: no commit in 7 days; `main.tf` carries this change's own applied, uncommitted edit.

## L3 Queries Run
The caller's results as in record 1, plus `describe-db-parameters` 11:31, `describe-alarms --alarm-names` 11:33, `terraform apply` 11:29, `terraform plan` 11:30, S1 of phase 2 (11:45-11:49). Pre-flight's own: `aws sts get-caller-identity` 11:50 (target matches); local `git log` 11:51. App source reused from phase 1.
