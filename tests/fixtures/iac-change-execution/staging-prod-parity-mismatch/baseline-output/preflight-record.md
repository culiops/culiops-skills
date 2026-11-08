The run wrote two pre-flight records, one per phase, each invoked inline from iac-change-execution Step 4b. Both are kept here under separate headings. Record 1 would be `.culiops/pre-flight/paymentapi-rds-engine-upgrade-staging-20261109-1126.md`, record 2 `.culiops/pre-flight/paymentapi-rds-engine-upgrade-prod-20261109-1256.md`. Neither was reused: record 2 has a different plan hash, target and var-file from record 1.

# Record 1 — Phase 1, staging

**Pre-flight assessment for:** `paymentapi` / `staging`
**Action:** Upgrade RDS PostgreSQL engine 15.4 → 15.7 (Terraform, `envs/staging.tfvars`)
**Date:** `2026-11-09 11:26` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `envs/staging.tfvars`, this change's own edit)
**Target:** `222222222222 / ap-southeast-1` | n/a (no Kubernetes) | `var-file envs/staging.tfvars, no workspace, local state (no backend block)`
**Plan hash:** `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** manual apply from the operator's workstation, direct apply (`operator-stated`, first message; no CI, GitOps or PR automation found in the repo). Flag from iac-change-execution: local workstation apply, not through CI/CD.
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** not available — category 11 ⚪

## Verdict: RED — SOFT BLOCK

(3 or more Yellow / ⚪ categories escalate: 6 of 11. No category is Red on its own.)

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | 2 resources changed in place; a database is shared infrastructure; single-AZ, so the upgrade is an outage for staging; local workstation apply | `plan:8,22-23,39`, `live: MultiAZ false (E4)`, `code: main.tf:94-99`, `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html` (read 2026-11-09, "the instance is unavailable while an engine version upgrade runs") | Announce the window to staging consumers |
| 2 | Reversibility | 🟡 | One-way engine upgrade, no data loss; rollback is a snapshot restore, untested; recovery points exist | `plan:8`, `docs:` same page (read 2026-11-09, "you cannot move the instance back to the older version"), `live: describe-db-snapshots (E7)` | Operator action: take a manual snapshot right before the apply |
| 3 | Change velocity | 🟢 | 0 commits to the changed paths in 7 days; no open PR | `git: log --since=7.days` (10:59) empty, `gh pr list` (11:00) empty | — |
| 4 | Dependency impact | ⚪ | No catalog; app-facing change; no consumer evidence in code or live | `code: outputs.tf:1-9`, `UNVERIFIED` | Run service-discovery or list the consumers of the instance and its outputs |
| 5 | Timing context | 🟢 | No incident, no freeze, not peak; operator present | `operator` (Q1, Q2), `operator-stated` (Q3), `live:5` connections 9-12 average | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | One static-threshold CPU alarm (80%, 3 x 300 s), live and enabled; nothing watches storage, connections or the upgrade | `live:6`, `live:8`, `code: main.tf:129-151` | Watch RDS events and the exported `upgrade` log during the apply |
| 8 | Cost impact | 🟢 | No new resource, no size change | `plan:39`, `plan:8`, `operator-stated` (Q6 negligible) | — |
| 9 | Security posture | 🟡 | No security attribute changes; raised by the local workstation apply flag | `plan:8-19`, `iac-change-execution` direct-apply flag | The execution record is the audit trail |
| 10 | Resource health | 🟢 | Nothing firing; CPU 8-14% average, memory about 1.7 GB, 14-15 GB free of 20 GB, connections 9-12; instance `available`; no pending maintenance | `live:2-5`, `live:7`, `live:10`, `live: describe-db-instances (E1)` | — |
| 11 | Application compatibility | ⚪ | `engine_version` is app-facing; no application source | `plan:8`, `operator` (Q8 = (c)) | Provide the application source at the deployed ref |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| engine version | `envs/staging.tfvars:11` → `15.4`; `plan:8` → `15.7` | `describe-db-instances` (10:14) → `15.4` | ✓ |
| Multi-AZ | `envs/staging.tfvars:10` → `false` | `false` | ✓ |
| parameter-group family | `main.tf:14` → `postgres15` | `describe-db-parameter-groups` (10:15) → `postgres15` | ✓ |
| recovery points | `main.tf:66,70-72` | 3 automated snapshots, newest 2026-11-09 02:05Z | ✓ |
| drift | no "Objects have changed" block | `terraform plan -refresh-only` (10:17) → `No changes` | ✓ |
| consumers of outputs | `outputs.tf:1-9` | not read | UNVERIFIED |

Drift rows: none. Unverified: consumers of the instance and outputs; application compatibility.

## Verification
- Citations checked: 11 (the Green on category 10, the four hard-block conditions, the six mitigation premises); fixed: none
- Verdict working: Red = none; Yellow + ⚪ = 6 (1, 2, 4, 7, 9, 11); hard blocks checked: category 2 (no data loss, snapshots exist, not a listed hard-block row), category 5 (no incident, no freeze), category 9 (no public exposure, encryption or secrets change), category 10 (no SLO, nothing firing) → RED — soft block by escalation
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q3 and Q6 (`operator-stated`); whether the stack was applied recently (asked, not answered); consumers of the instance and outputs; application compatibility (no source)

## Hard Blocks
none

## Acknowledged Risks
All findings (1, 2, 4, 7, 9, 11) acknowledged by the operator at pre-flight GATE 2 (11:26). Reason: "staging, minor engine upgrade, a restart is expected".

## Mitigations Committed
none stated (the operator acknowledged and proceeded)

## Context Provided (L2)
- Q1 active incident: no (`operator`)
- Q2 deploy freeze: no (`operator`)
- Q3 peak traffic at apply time: no (`operator-stated`)
- Q4 changed this service before: many times (`operator`)
- Q5 used Terraform before: experienced (`operator`)
- Q6 expected cost impact: negligible (`operator-stated`)
- Q7 other context: none
- Q8 application source: (c) not available
- Assessor questions: plan run and reviewed, delivery model, and `-target` / `-refresh=false` / var-file answered by L1 and skipped; "applied recently?" asked, no answer given

## L1 Analysis Detail
Plan hygiene: no drift block, no `-target` or `-refresh=false`, not "No changes", no unexpected resources. Catalog: none. Git: no commit to `main.tf`, `variables.tf`, `outputs.tf`, `envs/staging.tfvars` in 7 days; no open PR for them; the working tree holds only this change's edit. Changed attributes: `engine_version` (app-facing), tags (not app-facing). No remote backend, so last-apply time could not be read.

## L3 Queries Run
1. `aws sts get-caller-identity --query Account --output text` → `222222222222` (matches the recorded target)
2. `get-metric-statistics` `AWS/RDS` `CPUUtilization`, `paymentapi-db-staging` → average 8.2-13.8%, maximum 23.8%
3. same, `FreeableMemory` → average 1.7 GB, minimum 1.40 GB
4. same, `FreeStorageSpace` → 14-15 GB free
5. same, `DatabaseConnections` → average 9-12, maximum 31
6. `describe-alarms-for-metric` CPU → `paymentapi-db-cpu-high-staging`, enabled, `OK`
7. `describe-alarms --state-value ALARM` → none firing
8. `describe-alarms --alarm-name-prefix paymentapi` → the same single alarm
9. `describe-events` for the instance, last 24h → two backup events
10. `describe-pending-maintenance-actions` → none

---

# Record 2 — Phase 2, prod

**Pre-flight assessment for:** `paymentapi` / `prod`
**Action:** Upgrade RDS PostgreSQL engine 14.9 → 15.7 with a parameter-group replace (Terraform, `envs/prod.tfvars`)
**Date:** `2026-11-09 12:56` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `envs/prod.tfvars` (this change) and `envs/staging.tfvars` (this change's Phase 1, already applied))
**Target:** `333333333333 / ap-southeast-1` | n/a (no Kubernetes) | `var-file envs/prod.tfvars, no workspace, local state (no backend block)`
**Plan hash:** `sha256:25ca45650f7c2067c858c5cc4507499de09f9a762e9bce363c94b594c05177c9` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** manual apply from the operator's workstation, direct apply (`operator-stated`; no CI, GitOps or PR automation found in the repo). Flag from iac-change-execution: local workstation apply, not through CI/CD.
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** not available — category 11 ⚪

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | Prod database of the payments service on the app's data path; unavailable while a major upgrade runs; a destroy and a create in the plan; Multi-AZ effect on the downtime not documented; local workstation apply | `plan:9,24-27,43`, `code: main.tf:94-99`, `live: MultiAZ true (E4)`, `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html` (read 2026-11-09), `UNVERIFIED` (Multi-AZ effect) | Schedule a window and tell the app owners |
| 2 | Reversibility | 🔴 | Major engine upgrade is one-way; rollback is a snapshot restore, untested; writes after the snapshot are lost. Recovery points exist. Not a listed hard-block row | `plan:9`, `assessor: iac-change one-way table, RDS engine_version major upgrade`, `docs:` same page (read 2026-11-09, you cannot move the instance back), `live: describe-db-snapshots (E7)` | Operator action: take a manual snapshot right before the apply and rehearse the restore |
| 3 | Change velocity | 🟢 | 0 commits to the changed paths in 7 days; no open PR; no uncommitted change to the same files | `git: log --since=7.days` (12:29) empty, `gh pr list` (12:30) empty | — |
| 4 | Dependency impact | ⚪ | No catalog; app-facing; output `parameter_group_name` changes; no consumer evidence | `plan:12`, `code: outputs.tf:6-9`, `UNVERIFIED` | List the consumers of the instance and of the output |
| 5 | Timing context | 🟢 | No incident, no freeze, not peak; operator present | `operator` (Q1, Q2), `operator-stated` (Q3), `live:5` connections 52-55 average | — |
| 6 | Operator familiarity | 🟢 | Many times, experienced | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | One static-threshold CPU alarm, live and enabled; nothing watches storage, connections or the upgrade | `live:6`, `live:8`, `code: main.tf:129-151` | Watch RDS events and the exported `upgrade` log during the apply |
| 8 | Cost impact | 🟢 | One resource replaced (net zero), no size change | `plan:43`, `operator-stated` (Q6 negligible) | — |
| 9 | Security posture | 🟡 | No security attribute changes; raised by the local workstation apply flag | `plan:9-21`, direct-apply flag | The execution record is the audit trail |
| 10 | Resource health | 🟢 | Nothing firing; CPU 31-37% average, maximum 47%; memory about 6.4 GB; 82-83 GB free of 100 GB; connections 52-55; instance `available`; no pending maintenance | `live:2-5`, `live:7`, `live:10`, `live: describe-db-instances (E2)` | — |
| 11 | Application compatibility | ⚪ | A major engine change is app-facing (the assessor's "incompatible engine or runtime version" example); no application source. Silent breakage: health, error-rate and alarm signals will not show a driver incompatibility | `plan:9`, `operator` (Q8 = (c)) | The application source at the deployed ref and the driver's support matrix for PostgreSQL 15 |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| engine version | `envs/prod.tfvars:11` → `14.9`; `plan:9` → `15.7` | `describe-db-instances` (10:19) → `14.9` | ✓ |
| Multi-AZ | `envs/prod.tfvars:10` → `true` | `true` | ✓ |
| parameter-group family | `main.tf:14` → `postgres14`; `plan:27` → `postgres15`, forces replacement | `describe-db-parameter-groups` (10:20) → `postgres14` | ✓ |
| recovery points | `main.tf:66,70-72` | 3 automated snapshots, newest 2026-11-09 02:05Z | ✓ |
| drift | no "Objects have changed" block | `terraform plan -refresh-only` (10:22) → `No changes` | ✓ |
| consumers of outputs | `outputs.tf:1-9`; `plan:12` | not read | UNVERIFIED |

Drift rows: none. Unverified: consumers of the instance and the changed output; Multi-AZ effect on the upgrade downtime; application compatibility.

## Verification
- Citations checked: 13 (the two Reds, the Green on category 10, the four hard-block conditions, the six mitigation premises); fixed: none
- Verdict working: Red = 1, 2; Yellow + ⚪ = 4 (4, 7, 9, 11); hard blocks checked: category 2 (the assessor lists a major upgrade as Red, not as a hard block), category 5 (no incident, no freeze), category 9 (none), category 10 (no SLO, nothing firing) → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q3 and Q6 (`operator-stated`); whether the stack was applied recently (asked, not answered); consumers; Multi-AZ effect; application compatibility (no source)

## Hard Blocks
none

## Acknowledged Risks
All findings (1, 2, 4, 7, 9, 11) acknowledged by the operator at pre-flight GATE 2 (12:56). Reason as given by the operator script: "staging, minor engine upgrade, a restart is expected". That reason describes the staging change, not this prod change; it is recorded as given.

## Mitigations Committed
none stated (the operator acknowledged and proceeded; the operator later aborted at GATE 4, see the execution record)

## Context Provided (L2)
- Q1 active incident: no (`operator`)
- Q2 deploy freeze: no (`operator`)
- Q3 peak traffic at apply time: no (`operator-stated`)
- Q4 changed this service before: many times (`operator`)
- Q5 used Terraform before: experienced (`operator`)
- Q6 expected cost impact: negligible (`operator-stated`)
- Q7 other context: none
- Q8 application source: (c) not available
- Assessor questions: three answered by L1 and skipped; "applied recently?" asked, no answer given

## L1 Analysis Detail
Plan hygiene: no drift block, no `-target` or `-refresh=false`, not "No changes". The replace of `aws_db_parameter_group.paymentapi` was named in the approved plan at GATE 1, so it is not an unexpected resource. Catalog: none. Git: no commit to the changed paths in 7 days; no open PR. Changed attributes: `engine_version` (major, app-facing), `parameter_group_name` and the replaced group (app-facing), tags (not app-facing). Output `parameter_group_name` changes value.

## L3 Queries Run
1. `aws sts get-caller-identity --query Account --output text` → `333333333333` (matches the recorded target)
2. `get-metric-statistics` `AWS/RDS` `CPUUtilization`, `paymentapi-db-prod` → average 31.2-36.8%, maximum 46.8%
3. same, `FreeableMemory` → average 6.4 GB, minimum 6.10 GB
4. same, `FreeStorageSpace` → 82-83 GB free
5. same, `DatabaseConnections` → average 52-55, maximum 78
6. `describe-alarms-for-metric` CPU → `paymentapi-db-cpu-high-prod`, enabled, `OK`
7. `describe-alarms --state-value ALARM` → none firing
8. `describe-alarms --alarm-name-prefix paymentapi` → the same single alarm
9. `describe-events` for the instance, last 24h → two backup events
10. `describe-pending-maintenance-actions` → none
