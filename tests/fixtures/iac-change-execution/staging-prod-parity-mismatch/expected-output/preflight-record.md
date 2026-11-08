Intended path: `.culiops/pre-flight/paymentapi-rds-engine-15-7-staging-20261109-1119.md` (staging only; prod's pre-flight was never reached, the run aborted at [H3]).

**Pre-flight assessment for:** `paymentapi` / `staging`
**Action:** `Raise RDS PostgreSQL engine_version 15.4 -> 15.7 on aws_db_instance.paymentapi (aws_db_parameter_group.paymentapi: tag only), terraform apply tfplan, direct apply`
**Date:** `2026-11-09 11:19` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: envs/staging.tfvars, envs/prod.tfvars)
**Target:** `account 222222222222 / ap-southeast-1` | `Terraform default workspace / var-file envs/staging.tfvars / backend key: none declared in code`
**Plan hash:** `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (from `terraform plan -out=tfplan -var-file=envs/staging.tfvars`, 11:08)
**Delivery model:** `manual apply by the operator from a workstation, no CI — local workstation apply — not going through CI/CD pipeline` (`UNVERIFIED in the repo (no CI, Atlantis, Terraform Cloud, Spacelift or GitOps file); operator-stated in the first message and at [F2]`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, taken from the caller block) + L3 (live, the caller's approved reads)`
**App source:** `not available — category 11 ⚪` (Q8 = (c))

## Verdict: RED — SOFT BLOCK

Multi-Yellow escalation: Yellow + ⚪ = 6 (categories 1, 2, 4, 7, 9, 11), threshold is 3. No category is Red on its own and no hard block applies.

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | 2 resources change (`aws_db_instance.paymentapi` engine, `aws_db_parameter_group.paymentapi` tag). The database is a shared component. Disruption: the instance is unavailable while the engine upgrade runs. Staging is single-AZ, so nothing softens it. The direct-apply note adds elevation. | `plan: aws_db_instance.paymentapi update in-place; aws_db_parameter_group.paymentapi update in-place (Plan: 0 to add, 2 to change, 0 to destroy)`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html (2026-11-09): the instance is unavailable while an engine version upgrade runs`; `live: describe-db-instances (caller, 10:16): MultiAZ false` | Operator action: apply when staging consumers can take an outage; after apply confirm DatabaseConnections returns to its 9-12 average |
| 2 | Reversibility | 🟡 | One-way in-place change without data loss: no in-place downgrade, rollback is a restore from a pre-upgrade snapshot, untested. Tag change is reversible. Recovery points exist. | `plan: aws_db_instance.paymentapi engine_version "15.4" -> "15.7"`; `docs: .../USER_UpgradeDBInstance.PostgreSQL.html (2026-11-09): after an engine version upgrade you cannot move back to the older version; going back means restoring a snapshot taken before it`; `live: describe-db-snapshots (caller, 10:19)`: 3 automated, newest 2026-11-09 02:05 +00:00; `live: describe-db-instances (caller, 10:16)`: BackupRetentionPeriod 7, LatestRestorableTime 2026-11-09 02:55 +00:00, DeletionProtection true; `assessor: one-way table lists a MAJOR upgrade as Red; 15.4 -> 15.7 is minor, so the row does not apply` | Operator action: take a manual snapshot just before the apply; pre-flight never runs it. Try the restore path only if the operator wants it rehearsed |
| 3 | Change velocity | 🟢 | No commit to `envs/` or `main.tf` in the last 7 days. The repo's three recent commits are older than 30 days. No other uncommitted work. No open PR for this change. Last apply about 26 days ago (inferred from the alarm's last config update). Only backup events in the last 24 h. | `git: git log --since=7.days origin/main -- envs/ main.tf (11:12)`: none; `git: c4d8e21 "paymentapi: bump image to v2.4.1 (#118)"` (newest, older than 30 days); `git status --short (11:13)`: only this change's two var-files; `live: gh pr list --search 15.7 (10:07)`: none; `live: describe-alarms-for-metric (caller, 10:28)`: AlarmConfigurationUpdatedTimestamp 2026-10-14T05:21Z; `live: describe-events (caller, 10:20)`: backup events only; `operator-stated: iac-change.4=recent` | — |
| 4 | Dependency impact | 🟡 | The app tier consumes the database (security group ingress on 5432, live connections). No catalog, so other consumers are not known. No output value changes on staging (`parameter_group_name` keeps its name). | `code: main.tf:98` (ingress from `var.app_security_group_id`); `live: describe-metric DatabaseConnections (caller, 10:25)`: average 9-12, maximum 29-31; `plan: outputs unchanged (parameter group is updated in place)`; `catalog: none` | Operator action: list consumers of `paymentapi-db-staging` beyond the app tier security group and confirm they tolerate a restart |
| 5 | Timing context | 🟢 | No incident, no freeze, not peak. The operator applies by hand at the keyboard, so someone who can respond is on hand. Connections are flat over the hour, with the same-hour-last-week read showing the same level (ratio 1.0, canned window-invariant). | `operator: Q1=no, Q2=no`; `operator-stated: Q3=no`; `live: describe-metric DatabaseConnections (caller, 10:25 and 10:26)`; `live: describe-alarms --state-value ALARM (caller, 10:27)`: none firing | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform. | `operator: Q4=many times, Q5=experienced` | — |
| 7 | Observability readiness | 🟡 | One alarm watches the database: a static CPU threshold (`> 80`, 3 x 300 s). It exists, is enabled and is OK. Nothing watches storage, connections or events. No SLO or dashboard in code. | `code: main.tf:129-151`; `live: describe-alarms-for-metric (caller, 10:28)`: `paymentapi-db-cpu-high-staging`, ActionsEnabled true, OK; `live: describe-alarms --alarm-name-prefix paymentapi (caller, 10:29)`: that alarm only; `assessor: static threshold alerting scores Yellow` | Operator action: after apply confirm the CPU alarm stays OK; consider alarms on FreeStorageSpace and DatabaseConnections |
| 8 | Cost impact | 🟢 | No new resources, no size increase, no replace. | `plan: Plan: 0 to add, 2 to change, 0 to destroy; no instance_class or storage attribute changes`; `operator-stated: Q6=negligible` | — |
| 9 | Security posture | 🟡 | The plan changes no IAM, network, encryption, public-access or audit-log setting. Elevated one step because the apply is a local workstation apply, outside CI/CD (the caller's direct-apply note). | `plan: changed attributes are engine_version, tags, tags_all only`; `operator-stated: delivery model, local workstation apply` | Operator action: apply only the approved plan file (`terraform apply tfplan`); no `-target`, no `-lock=false` |
| 10 | Resource health | 🟢 | Instance `available`, no pending maintenance, no alarm in ALARM. CPU average 8.2-13.8 % (maximum 23.8 %). FreeableMemory minimum 1.40 GB. FreeStorageSpace minimum 14 GB of 20 GB allocated. Connections average 9-12. | `live: describe-db-instances (caller, 10:16)`; `live: describe-pending-maintenance-actions (caller, 10:21)`: none; `live: describe-alarms --state-value ALARM (caller, 10:27)`: none; `live: describe-metric CPUUtilization (10:22), FreeableMemory (10:23), FreeStorageSpace (10:24), DatabaseConnections (10:25)` | — |
| 11 | Application compatibility | ⚪ | `engine_version` is app-facing (engine version). No application source is available, so the driver / client compatibility with PostgreSQL 15.7 is unchecked. Silent breakage is possible: health, error-rate and alarm signals can stay green. | `assessor: application compatibility table, engine or runtime version`; `operator: Q8=(c) source not available`; `plan: aws_db_instance.paymentapi engine_version` | Evidence that would resolve it: the application source (Q8 a or b), checked against the DB driver or client library version and its PostgreSQL 15 support (`docs:` the driver's support matrix) |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Engine version | `code: envs/staging.tfvars:11` "15.4" | `live: describe-db-instances (caller, 10:16)` 15.4 | ✓ |
| Parameter group family | `code: main.tf:14` + `envs/staging.tfvars:11` -> postgres15 | `live: describe-db-parameter-groups (caller, 10:17)` postgres15 | ✓ |
| Multi-AZ | `code: envs/staging.tfvars:10` false | `live: describe-db-instances (caller, 10:16)` false | ✓ |
| Deletion protection, backups | `code: main.tf:70, :66` true, 7 days | `live: describe-db-instances (caller, 10:16)` true, 7 | ✓ |
| Drift | `terraform plan -refresh-only` | `live: (caller, 10:18)` No changes | ✓ no drift |
| CPU alarm | `code: main.tf:129-151` | `live: describe-alarms-for-metric (caller, 10:28)` exists, enabled, OK | ✓ |
| Apply timing | `code: main.tf` has no `apply_immediately` | none | UNVERIFIED: whether 15.7 applies at apply time or in the maintenance window (`code: main.tf:68`, Mon 18:00-19:00 UTC). No docs read; the post-apply read of `PendingModifiedValues` and `EngineVersion` shows it |
| Other consumers of the database | `code: main.tf:98` (one security group) | `live: DatabaseConnections` shows use | UNVERIFIED: no catalog |

No drift rows. Unverified: apply timing, other consumers.

## Verification
- Citations checked: 13 (cat 10 Green: 7 live sources; hard-block conditions for categories 2, 5, 9 and 10: 4; mitigation premises, snapshot exists and alarm exists: 2) (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 6 (1, 2, 4, 7, 9, 11) which is 3 or more, so multi-Yellow escalation gives RED — soft block; hard blocks checked: cat 2 irreversible data change (no: one-way upgrade, no data loss, snapshots exist), cat 5 incident + freeze (no), cat 9 public exposure / encryption removal / secrets (no), cat 10 error budget exhausted (no SLO declared, so none) → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q1-Q3 and Q6 are `operator` / `operator-stated`; delivery model is `operator-stated`; apply timing (`apply_immediately`) is UNVERIFIED; latency and error rate were not read (not in the approved batch); memory saturation was not computed (instance memory was not read); other consumers of the database (no catalog); the application's compatibility with 15.7 (⚪)

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at [H5], 2026-11-09 11:19, operator: each of the six findings (categories 1, 2, 4, 7, 9 Yellow and 11 ⚪, the multi-Yellow escalation). Reason, word for word: "staging, minor engine upgrade, a restart is expected".

## Mitigations Committed
none stated at [H5]. The operator acknowledged the findings with the reason above and committed to no mitigation; the mitigations in the scorecard stay recommendations.

## Context Provided (L2)
All answers taken from the caller block (`[F2]` answer, 2026-11-09 10:56).
- Q1 no (`operator`), Q2 no (`operator`), Q3 no (`operator-stated`)
- Q4 many times (`operator`), Q5 experienced (`operator`)
- Q6 negligible (`operator-stated`), Q7 none
- Q8 (c) the application source is not available
- iac-change.1 yes; iac-change.2 terraform is applied by hand from my workstation, and a direct apply is fine (`operator-stated`); iac-change.3 no (default workspace; the env's own var-file); iac-change.4 recent (`operator-stated`; the alarm's last config update 2026-10-14 agrees)

## L1 Analysis Detail
- Catalog: none (`.culiops/service-discovery/paymentapi.md` not found).
- Plan: `aws_db_instance.paymentapi` update in-place (`engine_version` 15.4 -> 15.7, `tags`, `tags_all`); `aws_db_parameter_group.paymentapi` update in-place (`tags`, `tags_all`). The family stays postgres15 because the major version (15) does not change (`code: main.tf:7`, `main.tf:14`).
- Plan hygiene: not made with `-target` or `-refresh=false`; var-file `envs/staging.tfvars`, default workspace.
- Git history: no commit in the last 7 days to the changed paths; three older commits.
- Changed attributes marked app-facing: `engine_version` (engine or runtime version). `tags` / `tags_all` are not-app-facing.
- Delivery: direct apply from a workstation raises blast radius and security posture one step (caller's note).

## L3 Queries Run
Caller's results, cited as `live: <cmd> (caller, <time>)`, run after [F1] (staging credentials):
1. `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging` (10:16): available, db.t4g.medium, 15.4, MultiAZ false, no pending values, parameter group in-sync, retention 7, deletion protection true, latest restorable 2026-11-09 02:55 +00:00
2. `aws rds describe-db-parameter-groups ...paymentapi-staging-20250920071544123400000001` (10:17): family postgres15
3. `terraform plan -refresh-only -var-file=envs/staging.tfvars` (10:18): No changes
4. `aws rds describe-db-snapshots` (10:19): three automated snapshots, newest 2026-11-09 02:05 +00:00
5. `aws rds describe-events` (10:20): two backup events in the last 24 h
6. `aws rds describe-pending-maintenance-actions` (10:21): none
7. CloudWatch `CPUUtilization` (10:22): average 8.2-13.8 %, maximum 23.8 %
8. CloudWatch `FreeableMemory` (10:23): average 1.70 GB, minimum 1.40 GB
9. CloudWatch `FreeStorageSpace` (10:24): average 15 GB, minimum 14 GB
10. CloudWatch `DatabaseConnections`, last hour (10:25): average 9-12, maximum 29-31
11. CloudWatch `DatabaseConnections`, same hour last week (10:26): same values (canned file is window-invariant)
12. `aws cloudwatch describe-alarms --state-value ALARM` (10:27): none
13. `aws cloudwatch describe-alarms-for-metric ... CPUUtilization` (10:28): `paymentapi-db-cpu-high-staging`, enabled, OK, updated 2026-10-14T05:21Z
14. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (10:29): the same single alarm

Pre-flight's own reads:
15. `aws sts get-caller-identity` (11:11, inline target check): account 222222222222, matches the caller's `Target:`
16. `git log --since=7.days --oneline origin/main -- envs/ main.tf` (11:12): no commits
17. `git status --short` (11:13): modified `envs/prod.tfvars`, `envs/staging.tfvars` (this change)
