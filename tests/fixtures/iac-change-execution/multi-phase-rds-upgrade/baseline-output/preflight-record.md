This run wrote two pre-flight records, one per phase (the old skill runs pre-flight inline for each apply, and the reboot has no plan hash, so the first record cannot be reused). They are shown one after the other. Each is the content the skill would write to its own file under `.culiops/pre-flight/`.

---

# Record 1 of 2 — `.culiops/pre-flight/paymentapi-max-connections-200-20261109-1122.md`

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Phase 1 of 2: raise `max_connections` 100 -> 200 in the parameter group (`apply_method = pending-reboot`) and align the connections alarm (threshold 80 -> 160, description). The reboot is phase 2 and is assessed in record 2.
**Date:** `2026-11-09 11:22` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf` on branch `iac-change/paymentapi-max-connections-200`)
**Target:** `123456789012 / ap-southeast-1` | n/a (no Kubernetes) | `Terraform var-file envs/prod.tfvars; workspace not read; backend key: no backend block in main.tf`
**Plan hash:** `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` (SHA-256 of the exact plan text assessed; passed by the caller)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** applied by hand from the operator's workstation (`operator-stated`: first message "Apply directly, no PR"; no CI / GitOps / Atlantis config found in the repo files). Caller flag: local workstation apply, not CI/CD.
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** `not available — category 11 ⚪` (Q8 = c)

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | 2 in-place updates: the parameter group of the prod payments DB (shared data-tier component) and its connections alarm. The apply itself restarts nothing: the static parameter stays `pending-reboot` until the reboot. The direct-apply flag (workstation, no CI gate) elevates the category; it is already Yellow | `plan:` `Plan: 0 to add, 2 to change, 0 to destroy`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html` (read 2026-11-09: a static parameter takes effect only after a reboot); `live:` caller E3 (`MultiAZ true`); `assessor:` database config change = elevated | Run phase 2 without `--force-failover`, inside the approved window, with #payments-oncall watching |
| 2 | Reversibility | 🟡 | Both attributes are reversible, but the rollback (revert, plan, apply) returns the old `max_connections` only after another reboot: manual and untested. No data loss | `plan:` in-place updates; `code: main.tf:14-15`; `docs:` USER_WorkingWithParamGroups (2026-11-09); `live:11` newest automated snapshot 2026-11-09 02:05Z | Keep the revert path ready: `git revert` the `main.tf` change, plan, apply, reboot |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; no open PR; the only uncommitted edit is this change's own | `git: git log --since=7.days --oneline origin/main -- main.tf` -> empty (10:51); `gh pr list --state open` -> none (10:52); `git status --short` -> ` M main.tf` (10:30) | — (last successful apply of the stack: see Not verified) |
| 4 | Dependency impact | 🟡 | The catalog lists one consumer, ECS `paymentapi-svc-prod`. A catalog is a lead: code shows the 5432 ingress from the app security group, live shows the service running; that no other service connects is not provable | `catalog: .culiops/service-discovery/paymentapi-prod.md:40-42`; `code: main.tf:89-95`; `live:` caller E7 (ECS 3/3), `live:10` (3 targets healthy) | Confirm no other service uses `paymentapi-db-prod` |
| 5 | Timing context | 🟢 | No incident, no freeze, DBA on the approved window with #payments-oncall told. Off-peak is operator-stated; the connection average (50-53) equals the catalog baseline (~50), not 1.5x | `operator` (Q1, Q2, Q7); `operator-stated` (Q3); `live:6` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | Two live alarms, enabled, `OK`: connections and CPU. Both are static-threshold alarms; no SLO or burn-rate alerting, no dashboard in code, no alarm on `FreeableMemory` although more connections use more memory | `live:2`, `live:3`; `code: main.tf:116-162` | Add a `FreeableMemory` alarm; after the reboot confirm the new connections alarm leaves `INSUFFICIENT_DATA` |
| 8 | Cost impact | 🟢 | No new resource, no size change (0 add, 0 destroy) | `plan: 0 to add, 2 to change, 0 to destroy`; `operator-stated` (Q6 negligible) | — |
| 9 | Security posture | 🟡 | Nothing security-relevant in the plan (no IAM, security group, encryption or public-access change). Elevated by the caller flag: the apply runs from a workstation with an elevated role, outside CI | `plan:`; `code: git diff` (two hunks); `operator-stated` (workstation apply) | Use the least role that permits the change; drop the elevated session afterwards |
| 10 | Resource health | 🟡 | Nothing firing; CPU max 46.8%; freeable memory >= 6.1 GB; free storage >= 82 GB; 3/3 targets healthy. Connection peak 78 of the current limit 100 = 78%, above the 70% saturation line; the connections alarm had 3 ALARM episodes in 5 days | `live:4` (none firing), `live:5` (episodes 11-04, 11-06, 11-08), `live:6` (max 78), `live:7` (CPU), `live:8`, `live:9`, `live:10` | Expected to improve once the limit is 200; watch `DatabaseConnections` after the reboot |
| 11 | Application compatibility | ⚪ | `max_connections` is app-facing (assessor: "limits the app must fit inside"). No application source (Q8 = c), so what the app does with 200 connections and with a restart is unknown. The alarm threshold and description are not-app-facing: the topic's subscribers are `email` only | `assessor:` app-facing table row "DB `max_connections`"; `live:14` (protocols `email`, `email`); `operator` (Q8 = c) | Provide the app source (re-run with Q8 a or b), or confirm by hand that the pool size and reconnect logic fit 200 connections and a restart |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| `max_connections` 100 -> 200, `pending-reboot` | `plan:` `aws_db_parameter_group.paymentapi` update in-place; `code: main.tf:14-17` | caller E1: `describe-db-parameters` (10:13) -> `100`, `static` | ✓ |
| Connections alarm threshold 80 -> 160 | `plan:` `aws_cloudwatch_metric_alarm.paymentapi_db_connections` update in-place; `code: main.tf:148-149` | `live:2` (11:04): Threshold 80.0, `OK`, ActionsEnabled true | ✓ |
| Instance is Multi-AZ, class `db.r6g.large` | `code: main.tf:62`, `code: envs/prod.tfvars:6` | caller E3 (10:12) | ✓ |
| Consumers of the DB | `catalog: …:40-42`; `code: main.tf:89-95` | caller E7 (10:15); `live:10` | ✓ (catalog is a lead; other consumers `UNVERIFIED`) |
| No drift | plan has no "Objects have changed outside of Terraform" block | `terraform plan -refresh-only` (10:11) -> `No changes.` | ✓ |

Drift rows: none. Unverified facts: last successful apply of the stack (not answered); the app's behaviour with 200 connections and on reconnect (no source); the effective runtime `max_connections` after the reboot.

## Verification
- Citations checked: 6 (fixed: none). Re-opened: the `docs:` page behind categories 1 and 2 (entry read 2026-11-09, says what the finding claims); the `live:5` and `live:6` rows behind category 10; `live:14` behind the not-app-facing alarm call; `live:11` behind the recovery point in category 2; `git diff` behind the two-hunk claim in category 9; the catalog lines behind category 4.
- Verdict working: Red = none; Yellow + ⚪ = 7 (1, 2, 4, 7, 9, 10, 11) >= 3 -> multi-Yellow escalation -> RED — soft block; hard blocks checked: category 2 irreversible data change (no), category 5 active incident + freeze (no), category 9 public exposure / encryption removal / secrets (no), category 10 error budget exhausted (no SLO declared) -> none -> RED — soft block.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: Q3 off-peak (`operator-stated`; the connection average equals the catalog baseline but no request-rate baseline was read); last successful apply of the stack (the assessor question went unanswered; no backend or CI history to read); application behaviour (no source); effective runtime `max_connections`.

## Hard Blocks
none

## Acknowledged Risks
Multi-Yellow escalation (categories 1, 2, 4, 7, 9, 10 Yellow; 11 ⚪). Operator reason: "maintenance window approved, DBA on call, the failover is expected."

## Mitigations Committed
none stated. The operator acknowledged the risks and proceeded; no mitigation was committed to or declined by name.

## Context Provided (L2)
1. Active incident: no (`operator`)
2. Deploy freeze or change window restriction: no — the maintenance window is approved and there is no freeze (`operator`)
3. Peak traffic at the expected apply time: no — off-peak window (`operator-stated`)
4. Changed this service before: many times (`operator`)
5. Used this IaC tool before: experienced (`operator`)
6. Expected cost impact: negligible (`operator-stated`)
7. Other context: DBA on the maintenance window; #payments-oncall told about the reboot (`operator`)
8. Application source: (c) not available (`operator`)
Assessor question, last successful apply of the stack: no answer given (`UNVERIFIED`).

## L1 Analysis Detail
Scanned the Terraform plan (2 in-place updates), `main.tf` and `envs/prod.tfvars`, the diff of this phase, git history for `main.tf` on `origin/main` (7 days: none), open PRs (none), the catalog `.culiops/service-discovery/paymentapi-prod.md` (resource inventory, dependency graph, signal envelopes). Assessor questions 1-3 skipped: the plan was run and shown, the delivery model is the caller's, the plan command had `-var-file=envs/prod.tfvars` with no `-target` or `-refresh=false`. Changed attributes marked: `max_connections` and `apply_method` app-facing; `threshold` and `alarm_description` not-app-facing (subscribers are `email` only, `live:14`). Caller evidence table used (E1-E7); L3 skipped what it already answers.

## L3 Queries Run
1. `aws sts get-caller-identity` -> account 123456789012, equals the target
2. `aws cloudwatch describe-alarms-for-metric … DatabaseConnections` -> `paymentapi-db-connections-high-prod`, `OK`, actions enabled, threshold 80 (pre-apply)
3. `aws cloudwatch describe-alarms-for-metric … CPUUtilization` -> `paymentapi-db-cpu-high-prod`, `OK`, actions enabled, threshold 80
4. `aws cloudwatch describe-alarms --state-value ALARM` -> none firing
5. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod` -> ALARM episodes 2026-11-04 12:20Z, 11-06 09:02Z, 11-08 21:39Z; currently `OK`
6. `get-metric-statistics … DatabaseConnections` -> average 50-53, max 76-78 (datapoints 02:00Z-02:55Z)
7. `get-metric-statistics … CPUUtilization` -> average 31.2-36.8%, max 46.8%
8. `get-metric-statistics … FreeableMemory` -> average ~6.4 GB, minimum 6.10-6.12 GB
9. `get-metric-statistics … FreeStorageSpace` -> average ~83 GB, minimum ~82 GB
10. `aws elbv2 describe-target-health … paymentapi-tg-prod` -> 3 targets, all `healthy`
11. `aws rds describe-db-snapshots … paymentapi-db-prod` -> 3 automated snapshots, newest 2026-11-09 02:05Z, `available`, encrypted
12. `aws rds describe-events … paymentapi-db-prod` -> backup events only
13. `aws rds describe-pending-maintenance-actions …` -> none
14. `aws sns list-subscriptions-by-topic … --query 'Subscriptions[].Protocol'` -> `email`, `email` (endpoints not read)

Left uncommitted: invoked by another skill (`iac-change-execution` decides).

---

# Record 2 of 2 — `.culiops/pre-flight/paymentapi-rds-reboot-20261109-1237.md`

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Phase 2 of 2: reboot `paymentapi-db-prod` in place (`aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`, no `--force-failover`) so `max_connections = 200` takes effect
**Date:** `2026-11-09 12:37` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf` on branch `iac-change/paymentapi-max-connections-200`, already applied in phase 1)
**Target:** `123456789012 / ap-southeast-1` | n/a (no Kubernetes) | `Terraform var-file envs/prod.tfvars; workspace not read; backend key: no backend block in main.tf`
**Plan hash:** `none — not reusable` (a reboot has no plan or diff text)
**Plan source:** `the CLI command above; no plan output reviewed — L1 analysis is partial`
**Delivery model:** applied by hand from the operator's workstation (`operator-stated`). Caller flag: local workstation action, not CI/CD.
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static, partial) + L2 (human) + L3 (live)`
**App source:** `not available — category 11 ⚪` (Q8 = c)

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | The reboot restarts the engine of the only prod payments DB and briefly interrupts every connection. Without `--force-failover` it is in place, so Multi-AZ does not avoid the interruption. The DB serves the app tier (3 ECS tasks behind `paymentapi-tg-prod`): a user-facing data path. Direct-apply flag elevates | `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html` (read 2026-11-09: a reboot restarts the engine and briefly interrupts connections; on Multi-AZ it fails over only with `--force-failover`); `live:2` (`MultiAZ true`); `live:6` (3 targets), `live:7` (ECS 3/3); `assessor:` user-facing data path | Run inside the approved window with #payments-oncall watching; do not add `--force-failover`; confirm the app reconnects (category 11) |
| 2 | Reversibility | 🟡 | A reboot cannot be undone and loses no data. The old `max_connections` returns only by revert, apply and another reboot: manual, untested | `docs:` USER_WorkingWithParamGroups (2026-11-09); `live:2` (`LatestRestorableTime 2026-11-09T02:55Z`), `live:8` (snapshot 02:05Z) | Keep the revert path ready |
| 3 | Change velocity | 🟢 | 0 commits to the repo files (phase-1 read, 10:51); the only recent action is phase 1's apply at 11:37, which belongs to this change | `git:` phase-1 `git log … --since=7.days` -> empty; `git status --short` (11:54) -> ` M main.tf` (this change's own) | — |
| 4 | Dependency impact | 🟡 | One consumer in the catalog (ECS, 3 tasks); the reboot drops its connections. Other consumers not provable | `catalog: …:40-42`; `live:6`, `live:7` | Confirm no other service uses the DB |
| 5 | Timing context | 🟢 | No incident, no freeze; DBA on the approved window, #payments-oncall told about the reboot; off-peak operator-stated | `operator` (Q1, Q2, Q7); `operator-stated` (Q3); `live:4` | — |
| 6 | Operator familiarity | 🟢 | Many times / experienced | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | Static-threshold alarms only. A fall to 0 connections does not trip an upper-bound alarm and no app-error alarm lives in this repo: a failed reconnect would show only through target health | `code: main.tf:116-162`; caller E5; `live:3` (nothing firing) | Watch target health and `DatabaseConnections` through the reboot |
| 8 | Cost impact | 🟢 | No resource or size change | `code:` no file changes in this phase; `operator-stated` (Q6 negligible) | — |
| 9 | Security posture | 🟡 | No security change (`PubliclyAccessible false`, `StorageEncrypted true`); elevated by the caller flag (workstation action) | `live:2`; `operator-stated` | Drop the elevated session after the reboot |
| 10 | Resource health | 🟡 | Nothing firing; CPU max 46.8%; 3/3 targets healthy; ECS 3/3. Connection peak 78 of the current limit 100 = 78%, above 70% | `live:3`, `live:4` (max 78), `live:5` (CPU), `live:6`, `live:7` | Expected to improve once the limit is 200 |
| 11 | Application compatibility | ⚪ | The reboot drops all connections and the connection limit changes: app-facing. No application source (Q8 = c): pool size and reconnect behaviour unknown, and a swallowed failure would leave health signals green (silent breakage) | `assessor:` app-facing rows (DB `max_connections`, endpoint availability); `operator` (Q8 = c) | Provide the app source, or confirm the pool and reconnect logic by hand |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Parameter is `pending-reboot` after phase 1 | none (no plan for this phase) | `live:2` (12:23): `ParameterApplyStatus pending-reboot` | ✓ |
| Instance is Multi-AZ, `available` | `code: main.tf:62` | `live:2` | ✓ |
| App tier healthy before the reboot | — | `live:6` (3/3 healthy), `live:7` (3/3 running) | ✓ |
| Reboot behaviour on Multi-AZ | — | `docs:` USER_RebootInstance (2026-11-09) | ✓ |

Drift rows: none. Unverified facts: reboot duration; app reconnect behaviour; last successful apply of the stack.

## Verification
- Citations checked: 7 (fixed: none). Re-opened: the `docs:` page behind the Red in category 1 (says what the finding claims about the reboot); `live:2`, `live:6`, `live:7` behind it; `live:2` behind category 9; `live:8` behind the recovery point; the catalog lines behind category 4; `live:4`/`live:5` behind category 10.
- Verdict working: Red = 1; Yellow + ⚪ = 6 (2, 4, 7, 9, 10, 11) -> RED — soft block (a Red finding, plus escalation); hard blocks checked: category 2 irreversible data change (no), category 5 active incident + freeze (no), category 9 public exposure / encryption removal / secrets (no), category 10 error budget exhausted (no SLO declared) -> none.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: Q3 off-peak (`operator-stated`); reboot duration (not in the docs entry); app reconnect behaviour (no source); last successful apply of the stack (unanswered).

## Hard Blocks
none

## Acknowledged Risks
Category 1 (Red) and the multi-Yellow escalation (2, 4, 7, 9, 10 Yellow; 11 ⚪). Operator reason: "maintenance window approved, DBA on call, the failover is expected."

## Mitigations Committed
none stated.

## Context Provided (L2)
1. Active incident: no (`operator`)
2. Deploy freeze or change window restriction: no — the maintenance window is approved and there is no freeze (`operator`)
3. Peak traffic at the expected apply time: no — off-peak window (`operator-stated`)
4. Changed this service before: many times (`operator`)
5. Used this IaC tool before: experienced (`operator`)
6. Expected cost impact: negligible (`operator-stated`)
7. Other context: DBA on the maintenance window; #payments-oncall told about the reboot (`operator`)
8. Application source: (c) not available (`operator`)
Assessor question, last successful apply of the stack: no answer given (`UNVERIFIED`).

## L1 Analysis Detail
A CLI command with no plan output (Constraint 5): partial L1. No files change in this phase. Git: no commit of this change; the working tree still holds phase 1's applied edit. Catalog used for the dependency graph. The reboot is app-facing, so category 11 is triggered and needs the app source (none given).

## L3 Queries Run
1. `aws sts get-caller-identity` -> account 123456789012, equals the target
2. `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod` -> `available`, `MultiAZ true`, `ParameterApplyStatus pending-reboot`, `PubliclyAccessible false`, `StorageEncrypted true`, `LatestRestorableTime 2026-11-09T02:55Z`
3. `aws cloudwatch describe-alarms --state-value ALARM` -> none firing
4. `get-metric-statistics … DatabaseConnections` -> average 50-53, max 76-78
5. `get-metric-statistics … CPUUtilization` -> average 31.2-36.8%, max 46.8%
6. `aws elbv2 describe-target-health … paymentapi-tg-prod` -> 3/3 `healthy`
7. `aws ecs describe-services … paymentapi-svc-prod` -> 3 desired, 3 running, deployment `PRIMARY` `COMPLETED`, circuit breaker disabled
8. `aws rds describe-db-snapshots … paymentapi-db-prod` -> newest automated snapshot 2026-11-09 02:05Z
9. `aws rds describe-pending-maintenance-actions …` -> none
10. `aws rds describe-events … paymentapi-db-prod` -> backup events only

Left uncommitted: invoked by another skill.
