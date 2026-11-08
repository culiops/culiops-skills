Intended path: `.culiops/iac-change-execution/paymentapi-rds-engine-15-7-20261110-1153.md`

**IaC change execution for:** `paymentapi` / `paymentapi-db-staging`, `paymentapi-db-prod`
**Change:** `Upgrade the paymentapi RDS PostgreSQL engine to 15.7: staging first, then prod (operator applies by hand from a workstation, no CI)`
**Date:** `2026-11-10 11:53`
**Commit:** `a1b2c3d` (+ uncommitted changes: envs/staging.tfvars, envs/prod.tfvars on branch `iac-change/paymentapi-rds-engine-15-7`)
**IaC tool(s):** `Terraform v1.9.8, hashicorp/aws v5.74.0`
**Execution path:** Direct apply (operator-stated, confirmed at [F2])
**Pre-flight record:** staging: `.culiops/pre-flight/paymentapi-rds-engine-15-7-staging-20261109-1119.md` (invoked inline — verdict: RED — soft block, acknowledged at [H5]); prod: not run, aborted at [H3] before pre-flight
**Lane:** full — `engine_version` is not on the light-lane allowlist (L2); prod's plan replaces `aws_db_parameter_group.paymentapi` (L1). Confirmed from the plan output at both 4a runs.
**Escalations:** none
**Environment tier:** staging=staging (live: `aws sts get-caller-identity` 2026-11-09 10:00 -> 222222222222; code: `envs/staging.tfvars:3`, `providers.tf:16`), prod=prod (live: 2026-11-09 10:01 -> 333333333333; code: `envs/prod.tfvars:3`, `providers.tf:16`)
**Staging-first:** applied — staging 2026-11-09 11:35
**Waived:** none
**Prerequisites (examples files used):** `skills/iac-change-execution/examples/aws.md` and `skills/pre-flight/examples/aws.md`: AWS CLI v2 (aws-cli/2.17.21); authentication by the `paymentapi-operator` role, one credential per environment; Tier 1 read-only rights for Steps 1 and 5, Tier 2 rights for the RDS and parameter-group changes of the apply, held only around the apply (the operator's role setup, not verified by the skill); CloudWatch `GetMetricStatistics` calls carry a small per-call charge

## Research Summary
- Catalog: none (`.culiops/service-discovery/paymentapi.md` not found).
- Duplicate check: **not done.** `git grep -F '15.7'` no hits; `git log --all -S'15.7'` none; no branch; no open PR (`gh pr list --search '15.7'`). `code: envs/staging.tfvars:11` = 15.4, `code: envs/prod.tfvars:11` = 14.9.
- Delivery model: `UNVERIFIED` in the repo (no CI, Atlantis, Terraform Cloud, Spacelift or GitOps file); `operator-stated`: terraform applied by hand from a workstation, no CI, and a direct apply is fine. Environment selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/*.tfvars`, `providers.tf:12-17`; no backend declared).
- Target checks: staging 222222222222 and prod 333333333333, both `assumed-role/paymentapi-operator`, both matching the repo pin; re-checked at each 4a (staging 2026-11-09 11:07, prod 2026-11-10 11:44).
- Key findings: the family of the parameter group follows the engine major version (`code: main.tf:7`, `:14`). Staging moves 15.4 -> 15.7 (same major), prod moves 14.9 -> 15.7 (major, confirmed intended at [F2]). `allow_major_version_upgrade = true` (`code: main.tf:49`). No drift in either environment (`terraform plan -refresh-only`: No changes).

## Evidence

| Fact | Code evidence | Live evidence | Match |
|---|---|---|---|
| staging engine version | `code: envs/staging.tfvars:11` "15.4" | `live: aws rds describe-db-instances paymentapi-db-staging (2026-11-09 10:16)` 15.4 | match |
| prod engine version | `code: envs/prod.tfvars:11` "14.9" | `live: ... paymentapi-db-prod (10:30)` 14.9 | match |
| staging parameter group family | `code: main.tf:14` + `envs/staging.tfvars:11` -> postgres15 | `live: describe-db-parameter-groups (10:17)` postgres15 | match |
| prod parameter group family | `code: main.tf:14` + `envs/prod.tfvars:11` -> postgres14 | `live: describe-db-parameter-groups (10:31)` postgres14 | match |
| Multi-AZ, staging / prod | `code: envs/staging.tfvars:10` false / `envs/prod.tfvars:10` true | `live: (10:16, 10:30)` false / true | match |
| instance class, staging / prod | `code: envs/*.tfvars:7` db.t4g.medium / db.r6g.large | `live: (10:16, 10:30)` same | match |
| deletion protection, backups | `code: main.tf:70`, `main.tf:66` true, 7 days | `live: (10:16, 10:30)` true, 7 | match |
| recovery points | none in code | `live: describe-db-snapshots (10:19, 10:33)` 3 automated each, newest 2026-11-09 02:05Z | live only |
| CPU alarm | `code: main.tf:129-151` | `live: describe-alarms-for-metric (10:28, 10:42)` exists, enabled, OK | match |
| drift | n/a | `live: terraform plan -refresh-only (10:18, 10:32)` No changes | no drift |
| consumers of the database | `code: main.tf:98` ingress from the app tier security group | `live: DatabaseConnections (10:25, 10:39)` in use | consistent; other consumers UNVERIFIED |

Drift rows: 0. Unverified rows: 2.
- apply timing: `main.tf` has no `apply_immediately`; the docs lookup returned no canned output, so whether 15.7 applies at apply time or in the maintenance window (`code: main.tf:68`) is `UNVERIFIED`. Staging's post-apply read showed `EngineVersion` 15.7 and no pending values (`live: 2026-11-09 11:37`).
- other consumers of the databases (no catalog).

Docs read (dry-run date 2026-11-09): `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group` (a changed `family` forces a new resource); `https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html` (a major upgrade needs a parameter group of the target family; the instance is unavailable while an engine version upgrade runs; after an engine version upgrade you cannot move back, going back means restoring a snapshot taken before it).

## Change Plan

**Phase 1 of 1: Raise the RDS PostgreSQL engine to 15.7, staging first, then prod** (approved at [F2], 2026-11-09 10:56)
- Files: `envs/staging.tfvars` (`db_engine_version` "15.4" -> "15.7"), `envs/prod.tfvars` ("14.9" -> "15.7"). `main.tf` not touched.
- Resources affected: staging `aws_db_instance.paymentapi` change (engine_version, tags), `aws_db_parameter_group.paymentapi` change (tags). Prod `aws_db_instance.paymentapi` change (engine_version 14.9 -> 15.7, major; `parameter_group_name` re-pointed; tags), `aws_db_parameter_group.paymentapi` replace (family postgres14 -> postgres15), output `parameter_group_name` changes.
- Blast radius: the payments database of each environment; the app tier consumes it (`code: main.tf:98`); prod is Multi-AZ, staging single-AZ.
- Disruption: outage while the engine upgrade runs in both environments (docs, 2026-11-09). Whether Multi-AZ softens prod's major upgrade is UNVERIFIED. Prod also replaces its parameter group.
- Parity expectation noted in the plan: staging keeps the family at postgres15, so it will not exercise prod's replace or the 14 -> 15 major step.
- Rollback path: one-way; restore from a snapshot taken before the upgrade (docs); `git revert` does not downgrade the engine; recovery points exist (`live: 10:19, 10:33`); restore untested.
- Success criteria per environment: (1) `aws rds describe-db-instances --db-instance-identifier paymentapi-db-<env> --query 'DBInstances[].{status:DBInstanceStatus,version:EngineVersion,pending:PendingModifiedValues,pg:DBParameterGroups[].ParameterApplyStatus}'` -> available, 15.7, {}, [in-sync]; (2) `aws cloudwatch describe-alarms --state-value ALARM` -> no alarm on the instance; (3) CPUUtilization last 15 min inside the pre-change band; (4) DatabaseConnections last 15 min inside the pre-change band; re-plan -> No changes.

**Execution path:** Direct apply · **Staging-first (H7):** staging, then prod, direct apply per environment · **Observation window:** 24 h from staging's success criteria passing (reason, inferred: one automated backup, `code: main.tf:67`, and a business day of traffic on 15.7) · **Branch:** `iac-change/paymentapi-rds-engine-15-7` from `origin/main` @ `a1b2c3d` · **Self-check:** 8/8 · **Drift (H4):** none · **L2 (answers at [F2]):** Q1=no Q2=no Q3=no Q4=many times Q5=experienced Q6=negligible Q7=none Q8=(c) iac-change.1=yes iac-change.2=terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated) iac-change.3=no (default workspace; the env's own var-file) iac-change.4=recent · **Delivery model:** operator-stated, by hand from a workstation, direct apply fine · **Prod 14.9 -> 15.7 intended:** yes (operator, [F2])

## Execution Log

### Phase 1: Raise the engine to 15.7 — staging
- Files changed: `envs/staging.tfvars` (line 11, "15.4" -> "15.7"; uncommitted)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 2 to change, 0 to destroy (`aws_db_instance.paymentapi` update in-place; `aws_db_parameter_group.paymentapi` update in-place, tags)
- Plan hash: `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd`
- Parity check: n/a
- Pre-flight verdict: RED — soft block (multi-Yellow escalation: categories 1, 2, 4, 7, 9 Yellow, 11 unknown). Acknowledged at [H5], 2026-11-09 11:19, operator: "staging, minor engine upgrade, a restart is expected". Mitigations committed: none stated. Record: `.culiops/pre-flight/paymentapi-rds-engine-15-7-staging-20261109-1119.md`
- Execution: `terraform apply tfplan` against account 222222222222 / ap-southeast-1 (var-file `envs/staging.tfvars`), approved at [F4] 2026-11-09 11:24. `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` The instance modification took 11m24s (`live: terraform apply tfplan, staging, 11:24 to 11:35`).
- Verification: re-plan 11:36 -> `No changes. Your infrastructure matches the configuration.` SC1 11:37 -> status available, version 15.7 (before: 15.4, `live: 10:16`), pending {}, pg [in-sync]. SC2 11:38 -> no alarm in ALARM. SC3 11:39 -> CPU average 8.2 to 13.8 % (before: 8.2 to 13.8 %). SC4 11:40 -> connections average 9 to 12 (before: 9 to 12). The canned CloudWatch files do not change with the apply, so SC3 and SC4 repeat the pre-change values. Observation window 2026-11-09 11:40 to 2026-11-10 11:40; staging's success criteria re-run 2026-11-10 11:40 to 11:43: all pass.

### Phase 1: Raise the engine to 15.7 — prod
- Files changed: `envs/prod.tfvars` (line 11, "14.9" -> "15.7"; uncommitted, edited, not applied)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 1 to add, 1 to change, 1 to destroy (`aws_db_instance.paymentapi` update in-place; `aws_db_parameter_group.paymentapi` must be replaced, family postgres14 -> postgres15), planned 2026-11-10 11:45, not applied
- Plan hash: `sha256:25ca45650f7c2067c858c5cc4507499de09f9a762e9bce363c94b594c05177c9`
- Parity check: untested in staging: aws_db_parameter_group.paymentapi replace
- Pre-flight verdict: not run — aborted at [H3] before prod's pre-flight
- Execution: not applied — aborted at [H3], 2026-11-10 11:51, operator: "Stop. I won't take an unrehearsed replace to prod." Offered: abort, add a staging rehearsal, accept with a written reason.
- Verification: none (prod not applied). Target re-check 2026-11-10 11:44: account 333333333333, matches the pin.

## Outcome
aborted at [H3] (prod). Staging completed and verified; prod not applied.

**Applied:** staging yes — verified (re-plan `No changes` 2026-11-09 11:36; `EngineVersion` 15.7, `available`, pending {}, parameter group in-sync at 11:37; no alarm in ALARM at 11:38; re-run 2026-11-10 11:40 to 11:43); prod no — not applied (aborted at [H3])

Working tree after the run: branch `iac-change/paymentapi-rds-engine-15-7`, `envs/staging.tfvars` and `envs/prod.tfvars` modified and uncommitted (prod's var-file still says 15.7). Nothing committed, pushed or opened as a PR. `tfplan` (prod's plan) is local, a secret, never committed or pasted.

## Ticket Reference
none
