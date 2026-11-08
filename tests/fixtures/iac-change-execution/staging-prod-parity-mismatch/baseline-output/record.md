Path the skill would write: `.culiops/iac-change-execution/paymentapi-rds-engine-upgrade-20261109-1311.md` (Constraint 7; output root `.culiops/` at the repo root, `CULIOPS_HOME` treated as unset)

**IaC change execution for:** `paymentapi` / `staging and prod` (no instance suffix; two environments)
**Change:** Upgrade the paymentapi RDS PostgreSQL engine to 15.7: staging first, then prod. Applied by hand from the operator's workstation, no CI.
**Date:** `2026-11-09 13:11` (+07:00)
**Commit:** `a1b2c3d` (branch `iac-change/paymentapi-rds-engine-15-7`; uncommitted changes: `envs/staging.tfvars`, `envs/prod.tfvars`)
**IaC tool(s):** Terraform (aws provider `~> 5.0`, v5.74.0 in the lock file)
**Execution path:** Direct apply (operator-chosen at GATE 1; local workstation apply flag passed to pre-flight)
**Pre-flight record:** Phase 1: `.culiops/pre-flight/paymentapi-rds-engine-upgrade-staging-20261109-1126.md` (invoked inline, verdict: RED — soft block). Phase 2: `.culiops/pre-flight/paymentapi-rds-engine-upgrade-prod-20261109-1256.md` (invoked inline, verdict: RED — soft block).

**Prerequisites (examples/aws.md):** AWS CLI v2 (`aws --version` >= 2.x; not run in this dry run). Authentication: assumed role `paymentapi-operator` in each account (`aws sts get-caller-identity`, staging 222222222222, prod 333333333333). Tier 1 read-only access (`Describe*`, `List*`, `Get*`, `cloudwatch:GetMetricStatistics`) for Steps 1 and 5; Tier 2 mutation role only for the apply. Cost awareness: CloudWatch `GetMetric*` calls are billed per call.

## Research Summary

- Catalog used: none (`.culiops/service-discovery/paymentapi.md` absent; service-discovery suggested).
- Duplicate check: **not done**. `code:` no `15.7` in the repo; `git:` `git log --all -S'15.7'` and `--grep='15.7'` empty; no branch matching `*15.7*`; `gh pr list --state open --search '15.7'` empty.
- Delivery model: applied by hand from the operator's workstation, no CI (`operator-stated`; nothing in the repo shows CI, GitOps or PR automation).
- Env selection: `-var-file=envs/<env>.tfvars` (`code: envs/staging.tfvars:3`, `envs/prod.tfvars:3`, `providers.tf:14-17`).
- Target check: staging account `222222222222`, prod account `333333333333`, region `ap-southeast-1` (`aws sts get-caller-identity`, staging 2026-11-09 10:13, prod 10:18; re-checked at 10:45 staging and 12:15 prod before each plan).
- Key findings: staging is on 15.4 (family `postgres15`, single-AZ, `db.t4g.medium`); prod is on 14.9 (family `postgres14`, Multi-AZ, `db.r6g.large`). The parameter-group family follows the engine major version (`main.tf:7,14`), so staging's move to 15.7 keeps the family and prod's move to 15.7 changes it. No drift (refresh-only plans clean in both environments).
- Read batch (11 commands, both environments) approved in full at STOP 1.

## Evidence

| # | Fact | Code evidence | Live evidence | Match |
|---|------|---------------|---------------|-------|
| E1 | staging `engine_version` | `code: envs/staging.tfvars:11` → `15.4` | `live: describe-db-instances` (10:14) → `15.4` | ✅ |
| E2 | prod `engine_version` | `code: envs/prod.tfvars:11` → `14.9` | `live: describe-db-instances` (10:19) → `14.9` | ✅ |
| E3 | instance class (staging / prod) | `envs/staging.tfvars:7` `db.t4g.medium` / `envs/prod.tfvars:7` `db.r6g.large` | same | ✅ |
| E4 | Multi-AZ (staging / prod) | `envs/staging.tfvars:10` `false` / `envs/prod.tfvars:10` `true` | `false` / `true` | ✅ |
| E5 | parameter-group family | `code: main.tf:14`, `main.tf:7` → staging `postgres15`, prod `postgres14` | `live: describe-db-parameter-groups` (10:15 / 10:20) → `postgres15` / `postgres14` | ✅ |
| E6 | queued modifications | none | `PendingModifiedValues {}` on both | ✅ |
| E7 | recovery points | `code: main.tf:66,70-72` | 3 automated snapshots each, newest 2026-11-09 02:05Z; `LatestRestorableTime` 02:55Z | ✅ |
| E8 | drift | n/a | refresh-only plans (10:17, 10:22) → `No changes` | ✅ |
| E9 | app tier uses the DB | `code: main.tf:94-99` | not read | code only |
| E10 | consumers of outputs `db_identifier`, `parameter_group_name` | `code: outputs.tf:1-9`, no reference in this repo | not read | UNVERIFIED |

Drift rows: 0. Unverified rows: 1 (E10). Also UNVERIFIED in the plan: whether Multi-AZ shortens the prod engine-upgrade downtime, and application compatibility with PostgreSQL 15 (application source not available).

## Change Plan

Approved at GATE 1 (10:33), execution path changed by the operator to direct apply.

**Phase 1 of 2: Upgrade staging RDS engine 15.4 → 15.7**
- Files: `envs/staging.tfvars` (line 11).
- Resources: change `aws_db_instance.paymentapi` (engine, tags), change `aws_db_parameter_group.paymentapi` (tag only). Expected 0 add, 2 change, 0 destroy.
- Blast radius: staging database `paymentapi-db-staging`, single-AZ, used by the staging app tier (`code: main.tf:94-99`).
- Disruption: instance: unavailable while the engine upgrade runs, no standby (`live: MultiAZ false`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html`, read 2026-11-09). Parameter group: none.
- Rollback: one-way (`docs:` same page, 2026-11-09); restore a pre-upgrade snapshot (`live:` 3 automated snapshots); untested.
- Success criteria: `describe-db-instances` → `EngineVersion 15.7`, `Status available`; `terraform plan -var-file=envs/staging.tfvars` → `No changes`.

**Phase 2 of 2: Upgrade prod RDS engine 14.9 → 15.7**
- Files: `envs/prod.tfvars` (line 11).
- Resources: change `aws_db_instance.paymentapi` (engine, `parameter_group_name`, tags), **replace** `aws_db_parameter_group.paymentapi` (family `postgres14` → `postgres15`; `code: main.tf:7,14`; `docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group`, read 2026-11-09). Expected 1 add, 1 change, 1 destroy. Output `parameter_group_name` changes value.
- Blast radius: prod database `paymentapi-db-prod`, Multi-AZ, used by the prod app tier (`code: main.tf:94-99`).
- Disruption: instance: unavailable while the upgrade runs (`docs:` AWS page, 2026-11-09), Multi-AZ effect UNVERIFIED. Parameter group: replace (`docs:` a major upgrade needs a group of the target family).
- Rollback: one-way (`docs:` AWS page, 2026-11-09); restore a pre-upgrade snapshot (`live:` 3 automated snapshots, newest 2026-11-09 02:05Z); untested. Application compatibility with PostgreSQL 15 UNVERIFIED.
- Success criteria: `describe-db-instances` → `EngineVersion 15.7`, `Status available`, new parameter group name; `describe-db-parameter-groups` on it → `postgres15`; `terraform plan -var-file=envs/prod.tfvars` → `No changes`.

Execution path: Direct apply. Branch: `iac-change/paymentapi-rds-engine-15-7` from `origin/main` @ `a1b2c3d`. Plan self-check: 6/6.

## Execution Log

### Phase 1: Upgrade staging RDS engine 15.4 → 15.7
- Files changed: `envs/staging.tfvars`
- Self-check: plan 6/6 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 2 to change, 0 to destroy (no replace, no drift)
- Plan hash: `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd`
- Pre-flight verdict: RED — soft block (escalation: Yellow + ⚪ = 6, categories 1, 2, 4, 7, 9, 11). Acknowledged by the operator at pre-flight GATE 2 (11:26) and at GATE 3 (11:31), reason: "staging, minor engine upgrade, a restart is expected". No mitigation committed.
- Execution: `terraform apply tfplan` for staging, approved 11:41, run 11:42: `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` The instance modification completed after 11m24s.
- Verification: re-plan `terraform plan -var-file=envs/staging.tfvars` (11:54) → `No changes`. Success criterion (12:00) `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging` → `EngineVersion 15.7`, `Status available` (pass). Health checks: not requested. The operator confirmed the move to Phase 2 at the phase gate (12:05) with no observation window.

### Phase 2: Upgrade prod RDS engine 14.9 → 15.7
- Files changed: `envs/prod.tfvars` (working tree only, never applied)
- Self-check: plan 6/6 · diff 6/6 (note: `envs/staging.tfvars`, Phase 1's applied change, was also modified in the working tree)
- Fresh eyes: not run — dry run
- Plan output summary: 1 to add, 1 to change, 1 to destroy (the destroy and add are the parameter-group replace named in the approved plan)
- Plan hash: `sha256:25ca45650f7c2067c858c5cc4507499de09f9a762e9bce363c94b594c05177c9`
- Pre-flight verdict: RED — soft block (Red: 1 blast radius, 2 reversibility; ⚪ 4, 11; Yellow 7, 9). Acknowledged by the operator at pre-flight GATE 2 (12:56) and at GATE 3 (13:01), reason as scripted: "staging, minor engine upgrade, a restart is expected" (a staging reason; recorded as given). No mitigation committed.
- Execution: **not run.** At GATE 4 (13:11) the operator aborted: "Stop. I won't take an unrehearsed replace to prod." `terraform apply tfplan` for prod was not executed.
- Verification: none (nothing applied to prod).

## Outcome

**aborted** — Phase 1 of 2 completed (staging applied and verified); Phase 2 (prod) aborted at GATE 4 before any apply.

**Applied:** yes — verified for Phase 1 (staging: `EngineVersion 15.7`, `Status available` at 12:00, re-plan `No changes` at 11:54). Phase 2 (prod): no — aborted at GATE 4, prod still on 14.9.

## Ticket Reference
none
