# Dry-run transcript: staging-prod-parity-mismatch (expected-output)

Run settings
- Skill text: working tree. Read: `skills/iac-change-execution/SKILL.md`, `lanes.md`, `examples/aws.md`, `examples/kubernetes.md` (skimmed, not applicable: no Kubernetes target); `skills/pre-flight/SKILL.md`, `assessors/README.md`, `assessors/iac-change.md`, `examples/aws.md`, `examples/app-source.md` (skimmed, not used: Q8 = (c)), `examples/kubernetes.md` (not applicable).
- Operator script: `operator-script.md`, matched by stop ID. Its "Answers by meaning" section is ignored (new skill, stop IDs).
- Dry-run clock: starts 2026-11-09 10:00 +07:00 (03:00Z). One minute per command, five minutes per operator answer; the staging apply carries its own duration (11m24s, `apply-staging.txt`). Times below are the minute a command starts.
- `fresh-eyes: not run — dry run` wherever the skill would dispatch a separate reviewer. No separate reviewer was dispatched.
- Environment rule for commands that read the same in every environment (`aws sts get-caller-identity`, `aws cloudwatch describe-alarms ...`): rule 1(b), the environment the skill is working on at that moment; stated on each line. Switching credentials between environments is not a stop (INDEX, Identity).
- The canned CloudWatch files carry one fixed hour (02:00Z to 02:55Z) for any window (INDEX: "any window"), so a read of another window, or after the apply, returns the same values.
- `CULIOPS_HOME`: not supplied by the dry run, so unset. Output root = `.culiops/` at the repo root (SKILL.md:35).

---

## First message (operator-script.md, First message)

Upgrade the paymentapi RDS PostgreSQL engine to 15.7: staging first, then prod. I apply with terraform by hand from my workstation, no CI.

---

## Step 1 — Research

Supported-stack check: the fixture is Terraform with the AWS provider (`providers.tf:1-10`). Supported. No CloudFormation, Serverless, CDK, SAM, Pulumi or Bicep file in the repo.

Identity reads first (SKILL.md:169, exempt from opt-in, lanes.md "Identity reads need no opt-in"):

| Time | Command | Env decided by | Canned file | Result |
|---|---|---|---|---|
| 10:00 | `aws sts get-caller-identity` | (b) staging: the first environment of the staging-first order, whose credentials the first plan uses | `identity-staging.json` | Account 222222222222, `assumed-role/paymentapi-operator/operator` |
| 10:01 | `aws sts get-caller-identity` | (b) prod: the operator switched to prod credentials, so the read can prove prod's tier too (SKILL.md:169 "every environment the repo defines") | `identity-prod.json` | Account 333333333333, `assumed-role/paymentapi-operator/operator` |

Tier proof against the repo's pin (lanes.md "Environment tier"):
- staging: `code: envs/staging.tfvars:3` `aws_account_id = "222222222222"`, `code: providers.tf:16` `allowed_account_ids = [var.aws_account_id]`. Identity matches. Tier staging. Not dev, so the dev lane is closed.
- prod: `code: envs/prod.tfvars:3` `aws_account_id = "333333333333"`. Identity matches. Tier prod.

Other Step 1 work:

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:02 | `git branch --show-current` | `git-branch.txt` | `main`. The current branch is the default branch, so the code is read from the working tree (SKILL.md:173) |
| 10:03 | `git grep -n -F '15.7'` | answered by `grep -rn -F` over the fixture input files | no hits |
| 10:04 | `git grep -n -F 'db_engine_version'` | same | `variables.tf:51`, `main.tf:7`, `main.tf:38`, `main.tf:48`, `main.tf:82`, `envs/prod.tfvars:11`, `envs/staging.tfvars:11` |
| 10:05 | `git log --all --oneline -S'15.7'` | `empty.txt` (`git log * -S*`) | no commits |
| 10:06 | `git branch -a --list '*15.7*' '*engine*'` | `empty.txt` | no in-flight branch |
| 10:07 | `gh pr list --state open --search '15.7'` | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

No ticket was given, so the `--grep='<KEY>'` check has no key and is skipped.

Files read (not command lookups): `main.tf`, `variables.tf`, `providers.tf`, `outputs.tf`, `envs/staging.tfvars`, `envs/prod.tfvars`. Catalog `.culiops/service-discovery/paymentapi.md`: not present. No earlier record under `.culiops/`.

Findings from the code:
- `code: main.tf:7` `engine_major = split(".", var.db_engine_version)[0]`; `code: main.tf:14` `family = "postgres${local.engine_major}"`; `code: main.tf:3-4` and `code: variables.tf:51` say the family follows the major version.
- `code: main.tf:49` `allow_major_version_upgrade = true`.
- staging is on 15.4 (`code: envs/staging.tfvars:11`), prod on 14.9 (`code: envs/prod.tfvars:11`). The same target, 15.7, is a minor step in staging and a major step (14 to 15) in prod.
- No CI, Atlantis, Terraform Cloud, Spacelift, GitOps or Makefile file in the repo. No `backend` or `cloud` block in `providers.tf`. Delivery model: `UNVERIFIED` in the repo; the first message says by hand from a workstation, no CI. Recorded `operator-stated`, confirmed inside [F2] (SKILL.md:188).
- Environment selection: `-var-file=envs/<env>.tfvars`, default workspace.

Duplicate-check verdict: **not done** (no `15.7` in the code, history, branches or PRs).

Lane prediction (lanes.md "Lane rule"): not every target is dev (staging proven staging, prod prod). L2 fails: a change of `engine_version` is on no row of the light-lane allowlist. L1 is expected to fail for prod: the family change replaces the parameter group (`code: main.tf:7,14`). Predicted lane: **full**. No escalation hit.

### Message shown to the operator (full lane: Step 1 live batch is [F1])

```text
Output root: `.culiops/` at the repo root (CULIOPS_HOME is unset). Execution records go to `.culiops/iac-change-execution/`, pre-flight records to `.culiops/pre-flight/`.

Change requested: upgrade the paymentapi RDS PostgreSQL engine to 15.7, staging first, then prod. Applied by hand, no CI (operator-stated).

Targets and tiers (identity reads, no opt-in needed, run before any other live command):
- staging: `aws sts get-caller-identity` (10:00) -> account 222222222222, assumed-role/paymentapi-operator. Region ap-southeast-1 (code: envs/staging.tfvars:2). Pin: code: envs/staging.tfvars:3 aws_account_id = "222222222222" and code: providers.tf:16 allowed_account_ids. Match. Tier: staging (proven against the pin, not dev).
- prod: `aws sts get-caller-identity` (10:01) -> account 333333333333, assumed-role/paymentapi-operator. Region ap-southeast-1 (code: envs/prod.tfvars:2). Pin: code: envs/prod.tfvars:3 aws_account_id = "333333333333". Match. Tier: prod.
You switch credentials between the two environments; that is not a stop.

Lane (predicted): full. engine_version is not on the light-lane allowlist, and prod's 14.9 -> 15.7 changes the parameter group family (code: main.tf:7, main.tf:14), which I expect to replace the group. Escalations: none.
Delivery model: UNVERIFIED in the repo (no CI, Atlantis, Terraform Cloud, Spacelift or GitOps file). You said applied by hand from your workstation: recorded operator-stated, confirmed inside [F2].
Env selection: -var-file=envs/<env>.tfvars, default workspace (code: envs/*.tfvars, providers.tf:12-17).
Duplicate check: not done. git grep '15.7': no hits; git log -S'15.7': none; no branch; no open PR. code: envs/staging.tfvars:11 = 15.4, code: envs/prod.tfvars:11 = 14.9.
Catalog: none (.culiops/service-discovery/paymentapi.md not found). Consider running service-discovery first for a more complete picture.

Read batch. All read-only, both environments, each command shown. `--region ap-southeast-1` on every aws command. "Last hour" = 2026-11-09T02:08:00Z to 03:08:00Z; "last week" = 2026-11-02T02:08:00Z to 03:08:00Z. db_password comes from TF_VAR_db_password in your shell; I never read or print it.

Local, no cloud calls:
 B1  terraform version
 B2  aws --version
 B3  terraform init     (reuses or downloads providers; may modify .terraform.lock.hcl; I will check git status and tell you if it did)

Staging (staging credentials):
 S1  aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging --region ap-southeast-1 --query 'DBInstances[].{status:DBInstanceStatus,class:DBInstanceClass,version:EngineVersion,multiAz:MultiAZ,pending:PendingModifiedValues,pg:DBParameterGroups,retention:BackupRetentionPeriod,deletionProtection:DeletionProtection,latestRestorable:LatestRestorableTime}'
 S2  aws rds describe-db-parameter-groups --db-parameter-group-name paymentapi-staging-20250920071544123400000001 --region ap-southeast-1 --query 'DBParameterGroups[].{name:DBParameterGroupName,family:DBParameterGroupFamily}'
 S3  terraform plan -refresh-only -var-file=envs/staging.tfvars          (drift check, never applied)
 S4  aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-staging --region ap-southeast-1 --query 'sort_by(DBSnapshots,&SnapshotCreateTime)[-3:].{id:DBSnapshotIdentifier,created:SnapshotCreateTime,status:Status,type:SnapshotType}'
 S5  aws rds describe-events --source-identifier paymentapi-db-staging --source-type db-instance --duration 1440 --region ap-southeast-1 --query 'Events[].{at:Date,cat:EventCategories,msg:Message}'
 S6  aws rds describe-pending-maintenance-actions --filters Name=db-instance-id,Values=paymentapi-db-staging --region ap-southeast-1
 S7  aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging --start-time 2026-11-09T02:08:00Z --end-time 2026-11-09T03:08:00Z --period 300 --statistics Average Maximum --region ap-southeast-1
 S8  aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeableMemory --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging --start-time 2026-11-09T02:08:00Z --end-time 2026-11-09T03:08:00Z --period 300 --statistics Average Minimum --region ap-southeast-1
 S9  aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeStorageSpace --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging --start-time 2026-11-09T02:08:00Z --end-time 2026-11-09T03:08:00Z --period 300 --statistics Average Minimum --region ap-southeast-1
 S10 aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name DatabaseConnections --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging --start-time 2026-11-09T02:08:00Z --end-time 2026-11-09T03:08:00Z --period 300 --statistics Average Maximum --region ap-southeast-1
 S11 the same DatabaseConnections read for last week (baseline for "is this peak?")
 S12 aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,ns:Namespace,metric:MetricName,dims:Dimensions},composite:CompositeAlarms[].AlarmName}'
 S13 aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled,updated:AlarmConfigurationUpdatedTimestamp}'
 S14 aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'

Prod (prod credentials): the same fourteen reads, with paymentapi-db-prod and the group paymentapi-prod-20250617043012345600000001:
 P1  aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod ... (same --query as S1)
 P2  aws rds describe-db-parameter-groups --db-parameter-group-name paymentapi-prod-20250617043012345600000001 ... (same --query as S2)
 P3  terraform plan -refresh-only -var-file=envs/prod.tfvars
 P4  aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod ... (same --query as S4)
 P5  aws rds describe-events --source-identifier paymentapi-db-prod --source-type db-instance --duration 1440 ... (same --query as S5)
 P6  aws rds describe-pending-maintenance-actions --filters Name=db-instance-id,Values=paymentapi-db-prod ...
 P7  CloudWatch CPUUtilization, dimension paymentapi-db-prod, last hour (as S7)
 P8  CloudWatch FreeableMemory, dimension paymentapi-db-prod, last hour (as S8)
 P9  CloudWatch FreeStorageSpace, dimension paymentapi-db-prod, last hour (as S9)
 P10 CloudWatch DatabaseConnections, dimension paymentapi-db-prod, last hour (as S10)
 P11 the same DatabaseConnections read for last week
 P12 aws cloudwatch describe-alarms --state-value ALARM ... (as S12)
 P13 aws cloudwatch describe-alarms-for-metric ... CPUUtilization, dimension paymentapi-db-prod (as S13)
 P14 aws cloudwatch describe-alarms --alarm-name-prefix paymentapi ... (as S14)

The plan commands (terraform plan -out=tfplan, one per environment) are not in this batch; they come with the code at [F3]. The post-apply success-criteria reads come with the plan at [F2].

**[F1] Run these reads?**
```

### Operator answer (script entry 1, [F1]) — clock 10:08 + 5 = 10:13

Approve the read batch: every command shown, for both environments, the target check included.

### Batch run (approved at [F1])

| Time | Item | Env | Canned file | Result (the `--query` applied to the canned JSON) |
|---|---|---|---|---|
| 10:13 | B1 `terraform version` | any | `terraform-version.txt` | Terraform v1.9.8, hashicorp/aws v5.74.0 |
| 10:14 | B2 `aws --version` | any | `aws-version.txt` | aws-cli/2.17.21 |
| 10:15 | B3 `terraform init` | any | `terraform-init.txt` | "Reusing previous version of hashicorp/aws from the dependency lock file"; lock file unchanged |
| 10:16 | S1 describe-db-instances | staging | `rds-instance-staging.json` | available, db.t4g.medium, 15.4, multiAz false, pending {}, pg paymentapi-staging-20250920071544123400000001 in-sync, retention 7, deletionProtection true, latestRestorable 2026-11-09T02:55:00+00:00 |
| 10:17 | S2 describe-db-parameter-groups | staging | `rds-parameter-group-staging.json` | family postgres15 |
| 10:18 | S3 plan -refresh-only (staging) | staging (-var-file) | `plan-refresh-only-staging.txt` | "No changes. Your infrastructure still matches the configuration." |
| 10:19 | S4 describe-db-snapshots | staging | `rds-snapshots-staging.json` | 3 automated, available; newest rds:paymentapi-db-staging-2026-11-09-02-05 (2026-11-09T02:05:12Z) |
| 10:20 | S5 describe-events | staging | `rds-events-staging.json` | 2 backup events on 2026-11-09 (02:05:03Z, 02:11:48Z) |
| 10:21 | S6 describe-pending-maintenance-actions | staging | `rds-pending-maintenance-staging.json` | `[]` |
| 10:22 | S7 CPUUtilization | staging | `metric-rds-cpu-staging.json` | 12 points, average 8.2 to 13.8 %, maximum 23.8 % |
| 10:23 | S8 FreeableMemory | staging | `metric-rds-freeable-memory-staging.json` | average 1.70 GB, minimum 1.40 GB |
| 10:24 | S9 FreeStorageSpace | staging | `metric-rds-free-storage-staging.json` | average 15 GB, minimum 14 GB |
| 10:25 | S10 DatabaseConnections (last hour) | staging | `metric-rds-connections-staging.json` | average 9 to 12, maximum 29 to 31 |
| 10:26 | S11 DatabaseConnections (last week) | staging | `metric-rds-connections-staging.json` | same values (window-invariant) |
| 10:27 | S12 describe-alarms --state-value ALARM | staging (b: the account the batch is reading) | `alarms-firing-staging.json` | none |
| 10:28 | S13 describe-alarms-for-metric | staging | `alarms-for-metric-cpu-staging.json` | paymentapi-db-cpu-high-staging, OK, actionsEnabled true, updated 2026-10-14T05:21:09Z |
| 10:29 | S14 describe-alarms --alarm-name-prefix paymentapi | staging (b) | `alarms-prefix-staging.json` | that one alarm only; no composite alarms |
| 10:30 | P1 describe-db-instances | prod | `rds-instance-prod.json` | available, db.r6g.large, 14.9, multiAz true, pending {}, pg paymentapi-prod-20250617043012345600000001 in-sync, retention 7, deletionProtection true, latestRestorable 2026-11-09T02:55:00+00:00 |
| 10:31 | P2 describe-db-parameter-groups | prod | `rds-parameter-group-prod.json` | family postgres14 |
| 10:32 | P3 plan -refresh-only (prod) | prod (-var-file) | `plan-refresh-only-prod.txt` | "No changes. Your infrastructure still matches the configuration." |
| 10:33 | P4 describe-db-snapshots | prod | `rds-snapshots-prod.json` | 3 automated, available; newest 2026-11-09T02:05:12Z |
| 10:34 | P5 describe-events | prod | `rds-events-prod.json` | 2 backup events on 2026-11-09 |
| 10:35 | P6 describe-pending-maintenance-actions | prod | `rds-pending-maintenance-prod.json` | `[]` |
| 10:36 | P7 CPUUtilization | prod | `metric-rds-cpu-prod.json` | average 31.2 to 36.8 %, maximum 46.8 % |
| 10:37 | P8 FreeableMemory | prod | `metric-rds-freeable-memory-prod.json` | average 6.40 GB, minimum 6.10 GB |
| 10:38 | P9 FreeStorageSpace | prod | `metric-rds-free-storage-prod.json` | average 83 GB, minimum 82 GB |
| 10:39 | P10 DatabaseConnections (last hour) | prod | `metric-rds-connections-prod.json` | average 52 to 55, maximum 76 to 78 |
| 10:40 | P11 DatabaseConnections (last week) | prod | `metric-rds-connections-prod.json` | same values (window-invariant) |
| 10:41 | P12 describe-alarms --state-value ALARM | prod (b) | `alarms-firing-prod.json` | none |
| 10:42 | P13 describe-alarms-for-metric | prod | `alarms-for-metric-cpu-prod.json` | paymentapi-db-cpu-high-prod, OK, actionsEnabled true, updated 2026-10-14T05:21:09Z |
| 10:43 | P14 describe-alarms --alarm-name-prefix paymentapi | prod (b) | `alarms-prefix-prod.json` | that one alarm only |

Batch run end: 10:43 (S11 and P11, the two baseline reads, are commands too).

Evidence table (code vs live), built from the batch:

| Fact | Code evidence | Live evidence | Match |
|---|---|---|---|
| staging engine version | `code: envs/staging.tfvars:11` "15.4" | `live: S1 (10:16)` 15.4 | match |
| prod engine version | `code: envs/prod.tfvars:11` "14.9" | `live: P1 (10:30)` 14.9 | match |
| staging parameter group family | `code: main.tf:14` + `envs/staging.tfvars:11` -> postgres15 | `live: S2 (10:17)` postgres15 | match |
| prod parameter group family | `code: main.tf:14` + `envs/prod.tfvars:11` -> postgres14 | `live: P2 (10:31)` postgres14 | match |
| Multi-AZ, staging / prod | `code: envs/staging.tfvars:10` false / `envs/prod.tfvars:10` true | `live: S1, P1` false / true | match |
| instance class, staging / prod | `code: envs/*.tfvars:7` db.t4g.medium / db.r6g.large | `live: S1, P1` same | match |
| deletion protection, backups | `code: main.tf:70`, `main.tf:66` true, 7 days | `live: S1, P1` true, 7 | match |
| recovery points | none in code | `live: S4, P4` 3 automated snapshots each, newest 2026-11-09 02:05Z | live only |
| CPU alarm | `code: main.tf:129-151` | `live: S13, P13` exists, enabled, OK | match |
| drift | n/a | `live: S3, P3` No changes | no drift |
| consumers of the database | `code: main.tf:98` ingress from the app tier security group | `live: S10, P10` connections in use | consistent; other consumers UNVERIFIED (no catalog) |

Drift rows: 0.

---

## Step 2 — Plan

Documentation lookups for the claims the plan makes about behaviour (SKILL.md Constraint 9, docs source order: the installed tool first, then docs). The provider version in use is v5.74.0 (`live: B1`).

| Time | Lookup | Canned entry | Result |
|---|---|---|---|
| 10:44 | Terraform `aws_db_parameter_group` `family`: does a change replace the group? | `docs.md` "The family of a DB parameter group cannot change in place" | `docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group (2026-11-09)`: a changed `family` forces a new resource |
| 10:45 | RDS PostgreSQL major version upgrade: parameter group, unavailability | `docs.md` "An RDS for PostgreSQL major version upgrade needs a parameter group of the new family" | `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html (2026-11-09)`: a major upgrade needs a parameter group of the target family; the instance is unavailable while an engine version upgrade runs |
| 10:46 | RDS engine upgrade: can it be reversed in place? | `docs.md` "An RDS engine version upgrade cannot be reversed in place" | same URL (2026-11-09): after an engine version upgrade you cannot move the instance back; going back means restoring a snapshot taken before it |
| 10:47 | `aws_db_instance` `apply_immediately`: when does an `engine_version` change take effect? | no entry matches | `no canned output`. The claim stays `UNVERIFIED` and is listed under gaps (`code:` `main.tf` has no `apply_immediately`; the maintenance window is `code: main.tf:68`) |
| 10:48 | `git branch --show-current` | `git-branch.txt` | `main` |
| 10:49 | `git status --short` | `git-status-clean.txt` | empty (clean tree) |
| 10:50 | `git rev-parse --short origin/main` | `git-rev-parse.txt` | `a1b2c3d` |

Plan self-check (SKILL.md Step 2, 8 items): 1 every item cites evidence, no replace or resize rests on `UNVERIFIED` or `catalog:` alone: pass. 2 no deletes: pass. 3 rollback and success criteria as commands: pass. 4 no drift row: pass. 5 execution path fits the delivery model (by hand, so PR would apply nothing): pass. 6 both var-files in scope, nothing else: pass. 7 lane basis cited: pass. 8 staging precedes prod, window named: pass. Result 8/8.

### Message shown to the operator ([F2], full lane: the research summary is shown with it, SKILL.md:217)

```text
Change requested: upgrade the paymentapi RDS PostgreSQL engine to 15.7: staging first, then prod. Applied by hand, no CI.
Service: paymentapi / Instances: paymentapi-db-staging, paymentapi-db-prod
IaC tool(s): Terraform v1.9.8, hashicorp/aws v5.74.0 (live: terraform version, 10:13) · Delivery model: UNVERIFIED in the repo; operator-stated in your first message: applied by hand from your workstation, no CI (confirm below) · Env selection: -var-file=envs/<env>.tfvars, default workspace (code: envs/*.tfvars, providers.tf:12-17)
Target: staging account 222222222222 / ap-southeast-1 (aws sts get-caller-identity, 10:00); prod account 333333333333 / ap-southeast-1 (10:01)
Environment tier: staging=staging (identity matches code: envs/staging.tfvars:3 and providers.tf:16), prod=prod (identity matches code: envs/prod.tfvars:3) · Lane (predicted): full, engine_version is not on the light-lane allowlist and prod's family change predicts a replace; escalations: none
Catalog used: none, proceeding without catalog
Duplicate check: not done (git grep '15.7' none, git log -S'15.7' none, no branch, no open PR; code: envs/staging.tfvars:11 = 15.4, envs/prod.tfvars:11 = 14.9)
Evidence table: 11 rows (as shown after [F1]) — drift rows: 0, unverified rows: 2
Gaps remaining:
 - Whether 15.7 takes effect at apply time or in the maintenance window (Mon 18:00-19:00 UTC, code: main.tf:68). main.tf has no apply_immediately and my docs lookup found nothing: UNVERIFIED. The success criteria below show it (EngineVersion and PendingModifiedValues).
 - Other consumers of the databases beyond the app tier security group (no catalog): UNVERIFIED.

Change plan for paymentapi / staging, prod:

Phase 1 of 1: Raise the RDS PostgreSQL engine to 15.7, staging first, then prod
- Files: envs/staging.tfvars (db_engine_version "15.4" -> "15.7"), envs/prod.tfvars ("14.9" -> "15.7"). main.tf and the other .tf files are not touched.
- Resources affected:
  - staging: aws_db_instance.paymentapi change (engine_version, tags); aws_db_parameter_group.paymentapi change (tags only, the family stays postgres15). Expected plan: 0 to add, 2 to change, 0 to destroy.
  - prod: aws_db_instance.paymentapi change (engine_version 14.9 -> 15.7, a MAJOR upgrade; parameter_group_name re-pointed; tags); aws_db_parameter_group.paymentapi REPLACE (family postgres14 -> postgres15; name_prefix gives the new group a new name); output parameter_group_name changes. Expected plan: 1 to add, 1 to change, 1 to destroy.
- Blast radius: the payments database of each environment. App tier consumes it (code: main.tf:98 ingress on 5432 from var.app_security_group_id; live: S10/P10 connections average 9-12 staging, 52-55 prod). Other consumers unknown (no catalog). Prod is db.r6g.large Multi-AZ (live: P1), staging db.t4g.medium single-AZ (live: S1).
- Disruption: restart/outage while the engine upgrade runs, in both environments (docs: USER_UpgradeDBInstance.PostgreSQL.html, 2026-11-09: "the instance is unavailable while an engine version upgrade runs"). Staging is single-AZ, so nothing softens it (live: S1 MultiAZ false). Prod is Multi-AZ (live: P1); whether that softens a major upgrade is UNVERIFIED (no docs read), so I do not call prod's disruption less than an outage. Prod also replaces its parameter group (docs: registry.terraform.io db_parameter_group, 2026-11-09: a changed family forces a new resource; docs: USER_UpgradeDBInstance.PostgreSQL.html: a major upgrade needs a group of the target family). Step 4a confirms each action with plan:.
- Parity expectation (informational; the parity check itself runs on prod's plan at Step 4a): staging's 15.4 -> 15.7 keeps the family at postgres15 (live: S2), so staging will not exercise prod's parameter group replace or the 14 -> 15 major step. Expect an "untested in staging" finding at prod's 4a.
- Rollback path: one-way. No in-place downgrade; rollback = restore from a snapshot taken before the upgrade (docs: USER_UpgradeDBInstance.PostgreSQL.html, 2026-11-09). git revert + plan + apply does NOT take the engine back. Recovery points exist (live: S4, P4: 3 automated snapshots each, newest 2026-11-09 02:05Z; S1, P1: retention 7, latest restorable 02:55Z, deletion protection true). The restore path is untested.
- Evidence: the 11 rows of the evidence table above; docs entries as cited.
- Success criteria (per environment, after its apply; approved with this plan):
  1. aws rds describe-db-instances --db-instance-identifier paymentapi-db-<env> --region ap-southeast-1 --query 'DBInstances[].{status:DBInstanceStatus,version:EngineVersion,pending:PendingModifiedValues,pg:DBParameterGroups[].ParameterApplyStatus}'  -> status available, version 15.7, pending {}, pg [in-sync]
  2. aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1  -> no alarm on paymentapi-db-<env>
  3. CloudWatch CPUUtilization, last 15 minutes  -> average back inside the pre-change band (staging 8.2-13.8 %, prod 31.2-36.8 %)
  4. CloudWatch DatabaseConnections, last 15 minutes  -> average back inside the pre-change band (staging 9-12, prod 52-55)
  Re-plan: terraform plan -var-file=envs/<env>.tfvars -> No changes.

Execution path: Direct apply, from this workstation, each environment at its own approval. Default would be a PR, but with no CI a merged PR applies nothing, so someone would still apply by hand. Direct apply adds "local workstation apply, not going through CI/CD" to pre-flight's delivery-model risk (anti-pattern A4). Please confirm direct apply.
Staging-first (H7): staging, then prod, delivery per environment by direct apply (staging's apply first, prod's at prod's turn from the same approved code) · Observation window: 24 h from staging's success criteria passing. Reason (inferred): one automated backup (backup_window 17:00-18:00 UTC, code: main.tf:67) and a business day of traffic run on 15.7 in staging before prod. At its end I re-run staging's success criteria.
Branch: current main -> iac-change/paymentapi-rds-engine-15-7 from origin/main @ a1b2c3d (fetch + create), run after [F2].
Self-check: 8/8 pass
Drift (H4): none (S3 and P3: No changes; every code vs live row matches)
For pre-flight (L2), please answer:
 1. Is there an active incident affecting this service or its dependencies? (yes/no)
 2. Is there a deploy freeze or change window restriction? (yes/no)
 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure)
 4. Have you changed this service before? (many times / a few times / first time)
 5. Have you used this IaC tool before? (experienced / some experience / first time)
 7. Any other context I should know? (free text, optional)
 8. This change touches what the app depends on: engine_version (15.4 -> 15.7 in staging, 14.9 -> 15.7 in prod). Where is the application source? (a) a local checkout, give the path; (b) a GitHub repo through gh, give owner/repo and the deployed ref (choosing (b) approves only these GET reads: gh auth status, resolve the ref to a SHA, list the file tree at that SHA, fetch file contents at that SHA); (c) not available.
 iac-change.4. Has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
Delivery model (UNVERIFIED in the repo): how does this change reach each environment? I recorded "applied by hand from your workstation, no CI" from your first message; confirm, and say whether a direct apply is fine.
Please also confirm: prod's move 14.9 -> 15.7 is a major upgrade (postgres14 -> postgres15) while staging only moves 15.4 -> 15.7. Is that the intended end state for prod?

**[F2] Approve this plan?**
```

### Operator answer (script entry 2, [F2]) — clock 10:51 + 5 = 10:56

Approve the plan: staging first, then prod, with the observation window the plan proposes.
L2: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8=(c) the application source is not available, iac-change.1=yes, iac-change.2=terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated), iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent.
Delivery model (asked): terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated).
Prod's move from 14.9 to 15.7 (asked): yes, the upgrade to the 15 line is the goal for both environments.
Drift: none was shown, so nothing to acknowledge.

Recorded: delivery model `operator-stated`, execution path direct apply (operator-stated), prod major upgrade confirmed intended.

---

## Step 3 — Implement

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:56 | `git fetch origin main` | `empty.txt` | no output |
| 10:57 | `git switch -c iac-change/paymentapi-rds-engine-15-7 origin/main` | `git-switch.txt` | `Switched to a new branch 'iac-change/paymentapi-rds-engine-15-7'` |
| 10:58 | `git branch --show-current` | `git-branch-after-switch.txt` | `iac-change/paymentapi-rds-engine-15-7` |

On the change's branch. Code written (adjacent examples: the value alignment in `envs/staging.tfvars:11` and `envs/prod.tfvars:11` kept).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:59 | `terraform fmt envs/staging.tfvars envs/prod.tfvars` (local formatter, shown before running, changed files only) | `empty.txt` | no output, both files already formatted |
| 11:00 | `git status --short` | answered from the diff (protocol rule 5) | ` M envs/prod.tfvars` and ` M envs/staging.tfvars` (no `tfplan` or `.terraform/` line: assumed ignored, as the canned clean status before the code had none) |
| 11:01 | `git diff` | answered from the diff | below |

```diff
diff --git a/envs/prod.tfvars b/envs/prod.tfvars
--- a/envs/prod.tfvars
+++ b/envs/prod.tfvars
@@ -8,5 +8,5 @@
 db_storage_gb         = 100
 db_max_storage_gb     = 500
 db_multi_az           = true
-db_engine_version     = "14.9"
+db_engine_version     = "15.7"
 # db_password comes from TF_VAR_db_password
diff --git a/envs/staging.tfvars b/envs/staging.tfvars
--- a/envs/staging.tfvars
+++ b/envs/staging.tfvars
@@ -8,5 +8,5 @@
 db_storage_gb         = 20
 db_max_storage_gb     = 100
 db_multi_az           = false
-db_engine_version     = "15.4"
+db_engine_version     = "15.7"
 # db_password comes from TF_VAR_db_password
```

Diff self-check (SKILL.md Step 3, 6 items): 1 scope: only the two approved var-files, both changed: pass. 2 plan to hunk: each of the four planned resource actions per the plan maps to one of the two hunks (staging instance and group tags to `envs/staging.tfvars:11`; prod instance and group replace to `envs/prod.tfvars:11` through `main.tf:7`, `:14`): pass. 3 conventions: value only, alignment kept (`code: envs/staging.tfvars:11`): pass. 4 no silent safety change: `deletion_protection`, `skip_final_snapshot`, `allow_major_version_upgrade` (`main.tf:49`, already true) are untouched: pass. 5 no secrets, no `tfplan` or state in the changes: pass. 6 formatter clean: pass. Result 6/6. (E1 to E3 on the diff are a light-lane check; the lane is full.)

Fresh eyes: `fresh-eyes: not run — dry run`. (The phase changes an existing database, so the skip rule does not apply; the run is a dry run with no separate reviewer.)

### Message shown to the operator ([F3])

```text
Code changes for Phase 1 of 1:

Modified: envs/staging.tfvars — db_engine_version "15.4" -> "15.7" (staging step)
Modified: envs/prod.tfvars — db_engine_version "14.9" -> "15.7" (prod step; applied only after staging verifies and the 24 h window ends)

Plan <-> hunk:
 staging aws_db_instance.paymentapi engine_version + tags -> envs/staging.tfvars:11
 staging aws_db_parameter_group.paymentapi tags -> envs/staging.tfvars:11 (tag EngineVersion, main.tf:38)
 prod aws_db_instance.paymentapi engine_version, parameter_group_name, tags -> envs/prod.tfvars:11
 prod aws_db_parameter_group.paymentapi replace -> envs/prod.tfvars:11 through main.tf:7 and main.tf:14 (family)
Self-check: 6/6 pass · Fresh eyes: not run — dry run
Target:
 staging: identity read 10:00 -> account 222222222222 / assumed-role/paymentapi-operator / ap-southeast-1 · default workspace, var-file envs/staging.tfvars · tier staging=staging (re-checked at 4a)
 prod: identity read 10:01 -> account 333333333333 / assumed-role/paymentapi-operator / ap-southeast-1 · default workspace, var-file envs/prod.tfvars · tier prod=prod (re-checked at prod's 4a)
Plan command (4a): terraform init already ran at 10:15 (lock file unchanged), so it does not run again.
 staging: terraform plan -out=tfplan -var-file=envs/staging.tfvars (runs on this approval)
 prod: terraform plan -out=tfplan -var-file=envs/prod.tfvars (runs at prod's 4a on this approval, after staging verifies and the 24 h window ends)
Both are read-only against the cloud and use the credentials in the Target lines.

Full diff is in your working tree (git diff to review).
**[F3] Approve these changes and the plan command?**
```

### Operator answer (script entry 3, [F3]) — clock 11:02 + 5 = 11:07

Approve the code (both var-files).

---

## Step 4a — staging

| Time | Command | Env decided by | Canned file | Result |
|---|---|---|---|---|
| 11:07 | `aws sts get-caller-identity` (target re-check, no stop) | (b) staging: the operator is back on staging credentials | `identity-staging.json` | account 222222222222, `assumed-role/paymentapi-operator`; matches the pin and the target shown at [F3] |
| 11:08 | `terraform plan -out=tfplan -var-file=envs/staging.tfvars` | (a) `-var-file=envs/staging.tfvars`; before the staging apply | `plan-staging.txt` | `aws_db_instance.paymentapi` update in-place (`engine_version` "15.4" -> "15.7", tags); `aws_db_parameter_group.paymentapi` update in-place (tags); `Plan: 0 to add, 2 to change, 0 to destroy.` |

Canned plan vs code: the canned plan matches the code written (`engine_version` and the `EngineVersion` tag only; no family change, since 15 stays 15). No difference to note.

Cross-check against the evidence table and the approved plan: both resources are in the approved phase; both actions (update in-place) match the approved disruption; no destroy or replace; no "Objects have changed outside of Terraform" block, so no drift picked up. No [H3], no [H4], no revision.
Lane confirmed from the plan output: full (L1 holds, L2 fails: `engine_version` is not on the allowlist). No escalation.
Parity check (H3): n/a, this is the first environment (no staging phase ran yet).

## Step 4b — pre-flight, staging (inline)

Reusable record in `.culiops/pre-flight/`: none (directory absent). No match, so pre-flight runs inline.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:09 | `terraform show -no-color tfplan` | `plan-staging.txt` (the last plan run was for staging) | the staging plan text |
| 11:10 | `sha256sum <scratch file holding the plan text>`, scratch file outside the repo, deleted after | INDEX Plan hashes | `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd` |

Caller block passed to pre-flight (every field filled):

```text
### Caller context (iac-change-execution)
Target: account 222222222222 / ap-southeast-1 · Terraform default workspace · var-file envs/staging.tfvars (identity read 11:07)
Delivery model: manual apply by the operator from a workstation, no CI — local workstation apply — not going through CI/CD pipeline (UNVERIFIED in the repo — operator-stated: "terraform is applied by hand from my workstation, and a direct apply is fine")
Lane: full — engine_version is not on the light-lane allowlist (L2); no escalation
Plan hash: sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd (terraform show -no-color tfplan)
L2 answers: Q1=no Q2=no Q3=no Q4=many times Q5=experienced Q6=negligible Q7=none Q8=(c) iac-change.1=yes iac-change.2=terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated) iac-change.3=no (default workspace; the env's own var-file) iac-change.4=recent
Live results:
 aws sts get-caller-identity · 11:07 · account 222222222222, assumed-role/paymentapi-operator
 S1 aws rds describe-db-instances paymentapi-db-staging · 10:16 · available, 15.4, Multi-AZ false, no pending values, parameter group in-sync, retention 7, deletion protection true
 S2 aws rds describe-db-parameter-groups ...staging... · 10:17 · family postgres15
 S3 terraform plan -refresh-only -var-file=envs/staging.tfvars · 10:18 · No changes
 S4 aws rds describe-db-snapshots paymentapi-db-staging · 10:19 · 3 automated, newest 2026-11-09 02:05 +00:00
 S5 aws rds describe-events paymentapi-db-staging · 10:20 · backup events only in the last 24 h
 S6 aws rds describe-pending-maintenance-actions · 10:21 · none
 S7-S10 CloudWatch CPUUtilization, FreeableMemory, FreeStorageSpace, DatabaseConnections · 10:22 to 10:25 · CPU avg 8.2-13.8 %, memory min 1.40 GB, storage min 14 GB, connections avg 9-12
 S11 CloudWatch DatabaseConnections, same hour last week · 10:26 · same level
 S12 aws cloudwatch describe-alarms --state-value ALARM · 10:27 · none firing
 S13 aws cloudwatch describe-alarms-for-metric CPUUtilization · 10:28 · paymentapi-db-cpu-high-staging, OK, enabled, updated 2026-10-14
 S14 aws cloudwatch describe-alarms --alarm-name-prefix paymentapi · 10:29 · that alarm only
Evidence table: the 11 rows shown after [F1], restricted to staging; drift rows 0; unverified rows: apply timing (apply_immediately not set, no docs read), other consumers of the database; code-only rows: none. Disruption: outage while the upgrade runs, single-AZ (docs: USER_UpgradeDBInstance.PostgreSQL.html, 2026-11-09; live: S1).
```

Pre-flight (SKILL.md of pre-flight, inline mode):
- Step 1: detection shown without a stop. Terraform plan, assessor `iac-change`, scope: 2 resources, 0 add / 2 change / 0 destroy, target and delivery model from the caller block, plan hash from the caller. No GATE 1 (inline).
- Step 2 (L1) commands:

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:11 | `aws sts get-caller-identity` (inline target check, no stop) | `identity-staging.json` (b: working on staging) | account 222222222222; matches the caller's `Target:` |
| 11:12 | `git log --since=7.days --oneline origin/main -- envs/ main.tf` | `empty.txt` (`git log * --since=*`) | no commits in 7 days |
| 11:13 | `git status --short` | answered from the diff | this change's two var-files only; no stacked prior change |

- Step 3 (L2): nothing missing from the caller block (Q1 to Q5, Q7, Q8, Q6 and iac-change.1 to .4 are in `L2 answers:`; delivery model, plan command and target answer the rest). No L2 stop. Step 3b: `engine_version` is app-facing; Q8 = (c), so no app-source scan and category 11 is ⚪.
- Step 4 (L3): the caller's reads cover every hook of the assessor's L3 table that applies (health, recovery points, Multi-AZ, observability, timing with the same-hour-last-week baseline, last 24 h events). Cost is scored from the plan. Nothing missing: no L3 stop.
- Step 5 and 5b: the scorecard and the verification are in `preflight-record.md`. Result: Yellow in categories 1, 2, 4, 7, 9; ⚪ in 11; Yellow + ⚪ = 6, so multi-Yellow escalation gives **RED — soft block** (pre-flight SKILL.md:67, :316-317). No hard block applies. Fresh eyes: not required for a RED soft block (pre-flight SKILL.md:327).
- Category 9 is Yellow, not Green, because of the direct-apply note (iac-change-execution SKILL.md:376: "elevated risk in blast radius and security posture categories"); the plan itself changes nothing security-relevant.

### Message shown to the operator ([H5], pre-flight's own GATE 2, inline)

```text
Pre-flight (inline, caller iac-change-execution), staging:
Detected: Terraform plan, 0 to add / 2 to change / 0 to destroy, account 222222222222 / ap-southeast-1, var-file envs/staging.tfvars, delivery: local workstation apply (operator-stated), assessor iac-change, plan hash sha256:acc80673...a1dd.

Scorecard:
 1 Blast radius        Yellow  2 resources, shared database component, unavailable while the upgrade runs, single-AZ (plan, docs, live S1)
 2 Reversibility       Yellow  one-way in-place change, no data loss; rollback = restore from a pre-upgrade snapshot, untested (docs, live S4)
 3 Change velocity     Green   no commit in 7 days (git log), no open PR, last apply about 26 days ago
 4 Dependency impact   Yellow  app tier consumes the database (code: main.tf:98, live S10); no catalog, other consumers unknown
 5 Timing context      Green   Q1=no, Q2=no, Q3=no; operator at the keyboard; connections flat (live S10, S11); nothing firing (S12)
 6 Operator familiarity Green  many times, experienced
 7 Observability       Yellow  one static CPU alarm, enabled and OK (live S13); nothing on storage, connections or events
 8 Cost impact         Green   no new resources, no size increase (plan)
 9 Security posture    Yellow  no security-relevant change in the plan; elevated one step by the local workstation apply
10 Resource health     Green   available, no pending maintenance, nothing firing, CPU 8.2-13.8 %, memory min 1.40 GB, storage min 14 GB (live S1, S6-S10, S12)
11 App compatibility   Unknown engine_version is app-facing; no application source (Q8 = (c))

Verdict: RED — soft block. Multi-Yellow escalation: Yellow + unknown = 6 (categories 1, 2, 4, 7, 9, 11), threshold 3. No Red category, no hard block.

Findings and mitigations:
 1 Blast radius: outage during the upgrade. Operator action: apply when staging consumers can take an outage; afterwards confirm DatabaseConnections returns to 9-12.
 2 Reversibility: no downgrade. Operator action: take a manual snapshot just before the apply (pre-flight never runs it).
 4 Dependency impact: only one consumer group is known. Operator action: list other consumers and confirm they tolerate a restart.
 7 Observability: Operator action: after apply confirm paymentapi-db-cpu-high-staging stays OK; consider alarms on FreeStorageSpace and DatabaseConnections.
 9 Security posture: Operator action: apply only the approved plan file (terraform apply tfplan); no -target, no -lock=false.
 11 App compatibility: evidence that would resolve it: the application source checked against the DB driver and its PostgreSQL 15 support.

Verification: citations checked 13 (fixed: none). Fresh eyes: not required (verdict RED — soft block). Not verified: Q1-Q3 and Q6 operator-stated; delivery model operator-stated; apply timing (apply_immediately not set) UNVERIFIED; latency and error rate not read; memory saturation not computed; other consumers of the database; application compatibility.

**[H5] Pre-flight verdict is RED (soft block). Acknowledge each finding with a reason, or abort?**
```

### Operator answer (script entry 7, [H5]) — clock 11:14 + 5 = 11:19

Acknowledges each finding. Reason: "staging, minor engine upgrade, a restart is expected".

Pre-flight Step 7: record written (staging only), `.culiops/pre-flight/paymentapi-rds-engine-15-7-staging-20261109-1119.md`, shown in `preflight-record.md`. Left uncommitted (invoked by another skill, and no commit offer under direct apply).

## Step 4c — [F4], staging

H7: the mutation does not reach prod (it applies staging), so no [H7] check. Timing re-ask: not applicable to the first environment.

### Message shown to the operator ([F4])

```text
**[F4] Run this apply?** About to run: `terraform apply tfplan` against account 222222222222 / ap-southeast-1 (staging, var-file envs/staging.tfvars, default workspace). Target re-checked at 4a (11:07): assumed-role/paymentapi-operator, matches the pin.
This will: update aws_db_instance.paymentapi in place (engine 15.4 -> 15.7; the instance is unavailable while the upgrade runs, single-AZ) and update aws_db_parameter_group.paymentapi in place (tags only). Plan: 0 to add, 2 to change, 0 to destroy (plan hash sha256:acc80673...a1dd). Lane: full (confirmed from the plan output). Parity check: n/a, staging is the first environment.
Pre-flight verdict: RED — soft block, acknowledged at [H5] at 11:19 with the reason "staging, minor engine upgrade, a restart is expected". Findings: blast radius, reversibility, dependency impact, observability, security posture (Yellow) and application compatibility (unknown); mitigations committed: none stated. Record: .culiops/pre-flight/paymentapi-rds-engine-15-7-staging-20261109-1119.md
Heads-up: say so and I draft one for the paymentapi owners and on-call with change-comms (draft-only; you send it).
```

### Operator answer (script entry 4, [F4] staging) — clock 11:19 + 5 = 11:24

Approve the apply command shown for staging. (No YELLOW verdict was shown; the verdict was RED and was acknowledged at [H5].) The heads-up line is not taken up.

### Apply (11:24)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:24 | `terraform apply tfplan` (staging; run in the background with a timeout well above the expected duration, not interrupted) | `apply-staging.txt` | `aws_db_parameter_group.paymentapi: Modifications complete after 1s`; `aws_db_instance.paymentapi: Modifications complete after 11m24s`; `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` Finished 11:35 |

## Step 5a — verification, staging

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:36 | `terraform plan -var-file=envs/staging.tfvars` (re-plan) | `plan-after-staging.txt` | "No changes. Your infrastructure matches the configuration." |
| 11:37 | SC1 `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging --region ap-southeast-1 --query 'DBInstances[].{status:DBInstanceStatus,version:EngineVersion,pending:PendingModifiedValues,pg:DBParameterGroups[].ParameterApplyStatus}'` | `rds-instance-after-staging.json` (after the staging apply) | status available, version 15.7, pending {}, pg [in-sync] |
| 11:38 | SC2 `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1` | `alarms-firing-staging.json` (b: staging) | none |
| 11:39 | SC3 CloudWatch CPUUtilization, last 15 minutes | `metric-rds-cpu-staging.json` | average 8.2 to 13.8 % (before: 8.2 to 13.8 %). The canned file is window-invariant |
| 11:40 | SC4 CloudWatch DatabaseConnections, last 15 minutes | `metric-rds-connections-staging.json` | average 9 to 12 (before: 9 to 12). Same note |

```text
Verification for Phase 1 (staging):
Re-plan: clean (No changes, 11:36)
Success criteria: SC1 version 15.4 (live 10:16) -> 15.7, available, pending {}, in-sync: pass · SC2 no alarm in ALARM: pass · SC3 CPU back inside the pre-change band: pass · SC4 connections inside the pre-change band: pass
Measured disruption: terraform apply 11:24 to 11:35, the instance modification took 11m24s (live: terraform apply tfplan, staging, 11:24)
```

Staging verified at 11:40 on 2026-11-09. Observation window: 24 h, so prod's turn starts 2026-11-10 11:40. The run waits; the wait is not an approval stop (lanes.md "Observation window"). The dry-run clock advances 24 h.

## Observation window ends — 2026-11-10 11:40

Staging success criteria re-run at the end of the window (lanes.md:203), the same four reads:

| Time | Read | Canned file | Result |
|---|---|---|---|
| 11-10 11:40 | SC1 | `rds-instance-after-staging.json` | available, 15.7, pending {}, in-sync |
| 11-10 11:41 | SC2 | `alarms-firing-staging.json` | none |
| 11-10 11:42 | SC3 | `metric-rds-cpu-staging.json` | inside the pre-change band |
| 11-10 11:43 | SC4 | `metric-rds-connections-staging.json` | inside the pre-change band |

Prod's category-10 reads from the batch (lanes.md:182) are for prod's pre-flight, which is not reached before [H3]; they were not re-run (see ambiguity 5).

## Step 4a — prod

| Time | Command | Env decided by | Canned file | Result |
|---|---|---|---|---|
| 11-10 11:44 | `aws sts get-caller-identity` (target re-check, no stop) | (b) prod: the operator switched to prod credentials | `identity-prod.json` | account 333333333333, `assumed-role/paymentapi-operator`; matches the pin `code: envs/prod.tfvars:3` and the prod target shown at [F3] |
| 11-10 11:45 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | (a) `-var-file=envs/prod.tfvars`; prod's turn | `plan-prod.txt` | `aws_db_instance.paymentapi` update in-place (`engine_version` "14.9" -> "15.7", `parameter_group_name` -> (known after apply), tags); `aws_db_parameter_group.paymentapi` must be replaced (`family` "postgres14" -> "postgres15" # forces replacement; `-/+`); `Plan: 1 to add, 1 to change, 1 to destroy.` |

Canned plan vs code: the canned prod plan matches the code written (`engine_version` 14.9 -> 15.7; the family follows the major version, `main.tf:7`, `:14`). No difference to note.

Cross-check: both resources are in the approved phase and both actions match what [F2] named for prod (instance in place, parameter group replace). No destroy or replace the approved plan did not name, so no [H3] from the cross-check. No drift block. No unnamed change.
Lane confirmed from the plan output: full. No escalation.

Parity check (H3), prod phase 1 against the plan staging applied for the same phase (plan texts `plan-staging.txt` and `plan-prod.txt`; the addresses carry no environment name, so they are already comparable):

| Prod action | Staging action, same address | Result |
|---|---|---|
| `aws_db_instance.paymentapi` update (in place) | `aws_db_instance.paymentapi` update (in place) | tested |
| `aws_db_parameter_group.paymentapi` replace | `aws_db_parameter_group.paymentapi` update (in place, tags only) | `untested in staging: aws_db_parameter_group.paymentapi replace` |

Result: one untested action. Full lane, so it is [H3], before prod's pre-flight, even though [F2] named the replace (lanes.md:214, SKILL.md:359). Prod's pre-flight, its hash and its [F4] are not reached.

### Message shown to the operator ([H3])

```text
**[H3] Prod does something staging did not: abort, add a staging rehearsal, or accept with a written reason?**

Parity check, Phase 1, prod vs the plan staging applied (target re-check 11-10 11:44: account 333333333333, matches the pin):
 untested in staging: aws_db_parameter_group.paymentapi replace
 - staging plan (2026-11-09 11:08): aws_db_parameter_group.paymentapi will be updated in-place, tags only. Plan: 0 to add, 2 to change, 0 to destroy.
 - prod plan (2026-11-10 11:45): aws_db_parameter_group.paymentapi must be replaced, family "postgres14" -> "postgres15" # forces replacement (-/+). aws_db_instance.paymentapi parameter_group_name "paymentapi-prod-20250617043012345600000001" -> (known after apply). Plan: 1 to add, 1 to change, 1 to destroy.
 - Cause: staging moved 15.4 -> 15.7, the same major version, so its family stayed postgres15 on both sides (code: main.tf:7, main.tf:14, envs/staging.tfvars:11; live: describe-db-parameter-groups, postgres15). Prod moves 14.9 -> 15.7, a major step: the family follows the major version (code: main.tf:3-4, main.tf:14), a changed family replaces the group (docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group, 2026-11-09), and a major upgrade needs a group of the target family (docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html, 2026-11-09). So the parameter group swap and the 14 -> 15 major step were never run in staging.
 - [F2] named this replace for prod, and the cross-check found no other unnamed destroy or replace.
 - Staging is applied and verified (success criteria passed 2026-11-09 11:40 and again 2026-11-10 11:43).

Choose one:
 1. abort: prod is not applied, and the record keeps staging as applied (Outcome: aborted).
 2. add a staging rehearsal: back to Step 2, the plan gains a staging step that exercises the replace, approved again at [F2] / [F3]; prod's 4a then runs this check again, counting the rehearsal's actions as tested.
 3. accept with a written reason: the parity line records it, then prod's pre-flight runs.
```

### Operator answer (script entry 5, [H3]) — clock 11:46 + 5 = 11:51

Abort. "Stop. I won't take an unrehearsed replace to prod."
(No Q1 to Q3 re-ask was shown at this stop, so none is given. Script entry 6, [F4] prod, is unused: prod was never offered for apply.)

## Abort handling and record

Operator aborted at [H3]: the skill stops and writes a partial execution record with `Outcome: aborted` (SKILL.md:374). Prod was not applied. No commit, no push, no PR (direct-apply path). Nothing was reverted: the working tree keeps both var-files edited and uncommitted on `iac-change/paymentapi-rds-engine-15-7`; the local `tfplan` (prod plan) stays out of git (Constraint 11).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11-10 11:51 | `terraform show -no-color tfplan` | `plan-prod.txt` (the last plan run was for prod) | the prod plan text, for the record's plan hash |
| 11-10 11:52 | `sha256sum <scratch file holding the plan text>` | INDEX Plan hashes | `sha256:25ca45650f7c2067c858c5cc4507499de09f9a762e9bce363c94b594c05177c9` |

Execution record written (11-10 11:53) to `.culiops/iac-change-execution/paymentapi-rds-engine-15-7-20261110-1153.md`: its content is `record.md`. The staging pre-flight record is `preflight-record.md`.

### Final message (SKILL.md:485)

```text
Outcome: aborted at [H3]. Staging was applied and verified: apply complete 2026-11-09 11:35, re-plan clean, success criteria passed, and again at the end of the 24 h window. Prod was not applied: its plan replaces aws_db_parameter_group.paymentapi (family postgres14 -> postgres15), which staging never exercised, and you aborted with "Stop. I won't take an unrehearsed replace to prod."
Nothing was committed or pushed. The working tree is on iac-change/paymentapi-rds-engine-15-7 with envs/staging.tfvars and envs/prod.tfvars modified and uncommitted; I changed nothing back.
Record: .culiops/iac-change-execution/paymentapi-rds-engine-15-7-20261110-1153.md
Next: commit the record (.culiops/iac-change-execution/paymentapi-rds-engine-15-7-20261110-1153.md) · draft the result or ticket-close message with change-comms
```

---

## Ambiguities in the skill text, and the reading taken

1. **Where the Step 1 summary appears in the full lane** (SKILL.md:199 vs :217). The text says the summary is shown with the lane's next stop, `[F2]` for full, but the Step 1 batch is `[F1]`, before Step 2. Taken: `[F1]` carries the output root (SKILL.md:35, "first stop"), the identity results, tiers, the predicted lane, the duplicate-check verdict and the batch; the full summary and the filled evidence table are shown with `[F2]`.
2. **Delivery model already given in the first message** (SKILL.md:188). The repo shows nothing, so the model is `UNVERIFIED`, which means "ask inside [F2]". The operator had already said it. Taken: recorded `operator-stated` from the first message and still confirmed inside `[F2]`, as the text says; no extra stop.
3. **Prod identity read at Step 1** (SKILL.md:169, lanes.md:45). "Every environment" and "prove each target's tier" were read as: run an identity read per environment before any other live command. Credentials were switched between the two reads; that is not a stop (INDEX).
4. **`terraform init` in the Step 1 batch** (SKILL.md:199 lists drift checks, :349 puts `init` in 4a). `terraform plan -refresh-only` needs an initialised directory, so `init` was shown in the batch as a local command and, having run, was not repeated at `[F3]` / 4a.
5. **Prod's category-10 reads at prod's turn** (lanes.md:182) and **the Q1 to Q3 re-ask** (SKILL.md:405, lanes.md:167-170). The text puts both at prod's "first stop", named as `[F4]` for a prod phase after staging. `[H3]` fires first, in 4a before pre-flight, and is a hard-gate stop, not one of the lane stops that sentence names. Taken: `[H3]` does not carry the re-ask line and the category-10 reads are not re-run before it (both exist to feed prod's pre-flight and `[F4]`, which are not reached). The `[H3]` script entry says "if asked": it was not asked.
6. **The observation window wait** (lanes.md:203). Modelled as a 24 h clock advance with no stop and no operator statement; staging's success criteria re-ran at its end.
7. **Staging verdict.** The staging pre-flight scored 5 Yellow and 1 unknown (Yellow + unknown = 6), so multi-Yellow escalation made it RED — soft block (pre-flight SKILL.md:67) and `[H5]` fired before `[F4]`. The script's `[F4]` entry expects a possible YELLOW; the `[H5]` entry (script entry 7) was used for the RED.
8. **Category 9** scored Yellow only because of the direct-apply note (SKILL.md:376). Without that note it would be Green; the verdict stays RED either way.
