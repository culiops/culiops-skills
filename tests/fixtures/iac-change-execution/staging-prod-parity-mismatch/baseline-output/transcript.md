# Dry-run transcript: staging-prod-parity-mismatch, baseline run of the old skill

- Fixture: `tests/fixtures/iac-change-execution/staging-prod-parity-mismatch`
- Operator script: `operator-script.md`, section "Answers by meaning" (old skill, no stop IDs)
- Skill source: `origin/main` (commit `0f3a2ef09291`), read with `git show origin/main:<path>`:
  `skills/iac-change-execution/SKILL.md`, `skills/iac-change-execution/examples/aws.md`, `skills/pre-flight/SKILL.md`, `skills/pre-flight/assessors/README.md`, `skills/pre-flight/assessors/iac-change.md`, `skills/pre-flight/examples/aws.md`, head of `skills/pre-flight/examples/app-source.md` (not used: Q8 answered (c)). The Kubernetes examples files were not read (AWS and Terraform only).
- Dry-run clock: starts 2026-11-09 10:00 +07:00. +1 minute per command (a documentation lookup counts as a command), +5 minutes per operator answer. The staging apply carries its own time (11m24s, from `canned/apply-staging.txt`).
- Skill line references are `SKILL.md:<line>` for iac-change-execution and `pre-flight SKILL.md:<line>` for pre-flight, as numbered in the `git show` output.
- Run note: `CULIOPS_HOME` is not mentioned by the fixture. Treated as unset, so the output root is `.culiops/` at the repo root (Constraint 13, SKILL.md:35).

First message (operator-script.md): "Upgrade the paymentapi RDS PostgreSQL engine to 15.7: staging first, then prod. I apply with terraform by hand from my workstation, no CI."

---

## Step 1 — Research

Local reads (not commands): `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `envs/staging.tfvars`, `envs/prod.tfvars`. There is no `.culiops/` directory in the fixture, so there is no service-discovery catalog and no earlier pre-flight or execution record.

Current branch and default branch (SKILL.md:141):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:01 | `git branch --show-current` | `git-branch.txt` | `main` |
| 10:02 | `git branch -a` | `git-branches.txt` | `* main`, `remotes/origin/HEAD -> origin/main`. Default branch is `main` and it is checked out, so the code is read from the working tree. |

Duplicate check (SKILL.md:145-151). Identifiers: `15.7` (target version), `engine_version`, `paymentapi-db-staging`, `paymentapi-db-prod`. No ticket key was given.

| Time | Command | Canned file / source | Result |
|---|---|---|---|
| (local) | `git grep -n -F '15.7'` | `grep -rn -F` over the fixture input files | no hits (exit 1) |
| (local) | `git grep -n -F 'engine_version'` | same | `main.tf:7,38,48,82`, `variables.tf:51`, `envs/staging.tfvars:11` (`15.4`), `envs/prod.tfvars:11` (`14.9`) |
| 10:03 | `git log --all --oneline -S'15.7'` | `empty.txt` (row `git log * -S*`) | no output |
| 10:04 | `git log --all --oneline -i --grep='15.7'` | `empty.txt` (row `git log * --grep=*`) | no output |
| 10:05 | `git branch -a --list '*15.7*'` | `empty.txt` | no output |
| 10:06 | `gh pr list --state open --search '15.7'` | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

Duplicate-check verdict: **not done**. Evidence: `code: no 15.7 anywhere in the repo`, `git: no commit, branch or open PR for it`.

Delivery model and environment selection (SKILL.md:153-156):
- Delivery model: applied by hand from the operator's workstation, no CI. Source: `operator-stated` in the first message. Nothing in the repo shows a CI pipeline, GitOps object or PR automation (`providers.tf:1-17` has no `cloud {}` or `backend "remote"`; no workflow files). So the delivery model is not UNVERIFIED and the skill does not ask the delivery-model question again (ambiguity 1 below).
- Environment selection: `-var-file=envs/<env>.tfvars`. `code: envs/staging.tfvars:3` sets `aws_account_id = "222222222222"`, `code: envs/prod.tfvars:3` sets `333333333333`, and `code: providers.tf:14-17` pins the provider to that account with `allowed_account_ids`.

Evidence table facts the plan will rely on come from code now and are completed by the live batch below.

Constraint 13 output root: `.culiops/` at the repo root.

### Message shown to the operator (read batch)

> **Research so far (local reads only)**
> **Change requested:** Upgrade the paymentapi RDS PostgreSQL engine to 15.7, staging first, then prod.
> **IaC tool:** Terraform (aws provider `~> 5.0`, `providers.tf:4-9`) · **Delivery model:** applied by hand from your workstation (`operator-stated`) · **Env selection:** `-var-file=envs/<env>.tfvars` (`code: envs/staging.tfvars`, `envs/prod.tfvars`; account pinned in `providers.tf:14-17`)
> **Catalog used:** none, proceeding without catalog (consider running service-discovery first for a more complete picture)
> **Output root:** `.culiops/` at the repo root
> **Duplicate check:** not done (`code:` no `15.7` in the repo, `git:` nothing in history, no branch, no open PR)
> **What the code says:** staging `db_engine_version = "15.4"` (`envs/staging.tfvars:11`), prod `"14.9"` (`envs/prod.tfvars:11`). The parameter-group family is derived from the engine major version (`main.tf:3-4`, `main.tf:7`, `main.tf:14`).
>
> **Live verification batch.** All commands are read-only. The two `sts` calls are the target checks. Credentials switch from the staging account to the prod account at command 7. Approve the batch, pick a subset, or decline?
>
> Staging account (222222222222)
> 1. `terraform init -input=false` (downloads nothing new if the lock file is satisfied; may update `.terraform.lock.hcl`; needed for the drift checks)
> 2. `aws sts get-caller-identity` (target check, expect account 222222222222)
> 3. `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging --region ap-southeast-1`
> 4. `aws rds describe-db-parameter-groups --db-parameter-group-name <name from command 3, DBParameterGroups> --region ap-southeast-1`
> 5. `aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-staging --region ap-southeast-1`
> 6. `terraform plan -refresh-only -input=false -var-file=envs/staging.tfvars` (drift check, never applied)
>
> Prod account (333333333333)
> 7. `aws sts get-caller-identity` (target check, expect account 333333333333)
> 8. `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`
> 9. `aws rds describe-db-parameter-groups --db-parameter-group-name <name from command 8, DBParameterGroups> --region ap-southeast-1`
> 10. `aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`
> 11. `terraform plan -refresh-only -input=false -var-file=envs/prod.tfvars` (drift check, never applied)

**STOP 1 — read batch.**

Operator answer (10:11), from "Answers by meaning" → "Step 1 read batch (the live verification batch): approve every command shown": approve every command shown, both environments, the target checks included. (Same direction as the `[F1]` entry.)

### Commands run

For `sts` and for the refresh-only plans the environment comes from the group the command sits in (protocol rule 1(b)): commands 1-6 are staging, 7-11 are prod. Commands 3-5 and 8-10 carry the environment in the resource name (rule 1(a)).

| Time | Command | Canned file | Result (as used) |
|---|---|---|---|
| 10:12 | `terraform init -input=false` | `terraform-init.txt` | initialized, provider `hashicorp/aws v5.74.0` reused from the lock file |
| 10:13 | `aws sts get-caller-identity` (group: staging) | `identity-staging.json` | account `222222222222`, role `arn:aws:sts::222222222222:assumed-role/paymentapi-operator/operator`. Matches `envs/staging.tfvars:3`. |
| 10:14 | `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging` | `rds-instance-staging.json` | `EngineVersion 15.4`, `db.t4g.medium`, `available`, `MultiAZ false`, `AllocatedStorage 20`, `PendingModifiedValues {}`, `BackupRetentionPeriod 7`, `DeletionProtection true`, `DBParameterGroups paymentapi-staging-20250920071544123400000001 in-sync`, `LatestRestorableTime 2026-11-09T02:55:00Z` |
| 10:15 | `aws rds describe-db-parameter-groups --db-parameter-group-name paymentapi-staging-20250920071544123400000001` | `rds-parameter-group-staging.json` | `DBParameterGroupFamily postgres15` |
| 10:16 | `aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-staging` | `rds-snapshots-staging.json` | 3 automated snapshots, newest `rds:paymentapi-db-staging-2026-11-09-02-05` (2026-11-09 02:05Z), all `available`, encrypted |
| 10:17 | `terraform plan -refresh-only -input=false -var-file=envs/staging.tfvars` | `plan-refresh-only-staging.txt` | `No changes. Your infrastructure still matches the configuration.` |
| 10:18 | `aws sts get-caller-identity` (group: prod) | `identity-prod.json` | account `333333333333`, role `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator`. Matches `envs/prod.tfvars:3`. |
| 10:19 | `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod` | `rds-instance-prod.json` | `EngineVersion 14.9`, `db.r6g.large`, `available`, `MultiAZ true`, `AllocatedStorage 100`, `PendingModifiedValues {}`, `BackupRetentionPeriod 7`, `DeletionProtection true`, `DBParameterGroups paymentapi-prod-20250617043012345600000001 in-sync`, `LatestRestorableTime 2026-11-09T02:55:00Z` |
| 10:20 | `aws rds describe-db-parameter-groups --db-parameter-group-name paymentapi-prod-20250617043012345600000001` | `rds-parameter-group-prod.json` | `DBParameterGroupFamily postgres14` |
| 10:21 | `aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod` | `rds-snapshots-prod.json` | 3 automated snapshots, newest `rds:paymentapi-db-prod-2026-11-09-02-05` (02:05Z), all `available`, encrypted |
| 10:22 | `terraform plan -refresh-only -input=false -var-file=envs/prod.tfvars` | `plan-refresh-only-prod.txt` | `No changes. Your infrastructure still matches the configuration.` |

### Message shown to the operator (research summary, informational)

> **Change requested:** Upgrade the paymentapi RDS PostgreSQL engine to 15.7, staging first, then prod.
> **Service:** `paymentapi` / **Instance:** none (two environments)
> **IaC tool(s):** Terraform · **Delivery model:** manual, by hand from the workstation (`operator-stated`) · **Env selection:** `-var-file=envs/<env>.tfvars` (`code: envs/staging.tfvars:3`, `envs/prod.tfvars:3`, `providers.tf:14-17`)
> **Target:** staging = account `222222222222` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:13); prod = account `333333333333` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:18)
> **Catalog used:** none, proceeding without catalog
> **Duplicate check:** not done (`code:` no `15.7`, `git:` nothing in history, no branch, no PR)
> **Evidence table:** drift rows: 0, unverified rows: 1
>
> | # | Fact | Code evidence | Live evidence | Match? |
> |---|------|---------------|---------------|--------|
> | E1 | staging `engine_version` | `code: envs/staging.tfvars:11` → `15.4` | `live: describe-db-instances` (10:14) → `15.4` | ✅ |
> | E2 | prod `engine_version` | `code: envs/prod.tfvars:11` → `14.9` | `live: describe-db-instances` (10:19) → `14.9` | ✅ |
> | E3 | instance class (staging / prod) | `code: envs/staging.tfvars:7` → `db.t4g.medium` / `envs/prod.tfvars:7` → `db.r6g.large` | `live:` (10:14 / 10:19) → same | ✅ |
> | E4 | Multi-AZ (staging / prod) | `code: envs/staging.tfvars:10` → `false` / `envs/prod.tfvars:10` → `true` | `live:` → `false` / `true` | ✅ |
> | E5 | parameter-group family | `code: main.tf:14` `postgres${local.engine_major}`, `main.tf:7` major = first segment of the version → staging `postgres15`, prod `postgres14` | `live: describe-db-parameter-groups` (10:15 / 10:20) → `postgres15` / `postgres14` | ✅ |
> | E6 | queued modifications | `code: none` | `live: PendingModifiedValues` → `{}` on both | ✅ |
> | E7 | recovery points | `code: main.tf:66` retention 7, `main.tf:70-72` deletion protection and final snapshot | `live: describe-db-snapshots` (10:16 / 10:21) → 3 automated snapshots each, newest 2026-11-09 02:05Z; `LatestRestorableTime` 02:55Z | ✅ |
> | E8 | drift | n/a | `live: terraform plan -refresh-only` (10:17 staging, 10:22 prod) → `No changes` | ✅ |
> | E9 | app tier uses the DB | `code: main.tf:94-99` (ingress 5432 from `var.app_security_group_id`) | not read | code only |
> | E10 | consumers of outputs `db_identifier`, `parameter_group_name` | `code: outputs.tf:1-9`; nothing in this repo references them | not read | UNVERIFIED |
>
> **Gaps remaining:** E10 (consumers outside this repo; resolving command: a service-discovery catalog or the operator's list of consumer stacks); whether Multi-AZ shortens engine-upgrade downtime (UNVERIFIED, no documentation read yet); application compatibility with PostgreSQL 15 (application source not read; pre-flight asks for it).

No drift row, no already-done or in-flight verdict, no correction from the operator, so the skill continues to Step 2 (SKILL.md:182).

---

## Step 2 — Plan

Scope analysis: two ordered steps with verification between them (staging, then prod), so the plan is **multi-phase** (SKILL.md:190-193, Constraint 5). The operator asked for the order.

Documentation lookups (Constraint 9, SKILL.md:31) for claims that drive the plan:

| Time | Lookup | Canned entry (`docs.md`) | Used for |
|---|---|---|---|
| 10:23 | what an RDS PostgreSQL major version upgrade needs and does | "An RDS for PostgreSQL major version upgrade needs a parameter group of the new family". URL `https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html`, read 2026-11-09. A major upgrade needs a DB parameter group of the target major version's family. The instance is unavailable while an engine version upgrade runs. | Disruption of both phases; the family requirement in Phase 2 |
| 10:24 | what changing the `family` of an `aws_db_parameter_group` does | "The family of a DB parameter group cannot change in place". URL `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group`, read 2026-11-09. Changing `family` replaces the group. | Phase 2: replace of the parameter group |
| 10:25 | whether an RDS engine version upgrade can be reversed | "An RDS engine version upgrade cannot be reversed in place". Same AWS URL, read 2026-11-09. After the upgrade you cannot move back; going back means restoring a snapshot taken before it. | Rollback class of both phases |

How the plan items were derived (no step outside the skill text): the disruption claim for Phase 2 (a 14.9 → 15.7 move) needed a `docs:` source, and the page read at 10:23 says a major upgrade needs a parameter group of the target family. `main.tf:7` and `main.tf:14` make the family follow the engine major version, and E5 shows prod is on `postgres14`. A 14 → 15 move therefore changes the family, and the registry page (10:24) says that replaces the group. Staging is 15.4 → 15.7, the same major, so its family stays `postgres15` and nothing is replaced there. The old text has no step that compares the two environments; the Phase 2 item exists only because Constraint 9 and Step 2 require disruption evidence for each phase.

Branch read (SKILL.md:210):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:26 | `git branch --show-current` | `git-branch.txt` | `main` |
| 10:27 | `git status --short` | `git-status-clean.txt` | no output (clean) |
| 10:28 | `git rev-parse --short origin/main` | `git-rev-parse.txt` | `a1b2c3d` |

The current branch is not this change's branch, so the plan proposes the fetch and `git switch -c` from `origin/main`. Name: no ticket and no branch pattern in the history, so the fallback `iac-change/<service>-<short-description>` is used: `iac-change/paymentapi-rds-engine-15-7`.

Plan self-check (SKILL.md:212-218): 1 pass (every item cites code, live or docs; the replace rests on code plus docs, the Multi-AZ effect is labelled UNVERIFIED and does not justify a destroy, replace or resize); 2 pass (no deletes); 3 pass; 4 pass (0 drift rows); 5 pass (manual delivery, PR default offered, direct apply available); 6 pass. Result 6/6.

### Message shown to the operator (plan)

> **Change plan for `paymentapi`:**
>
> **Phase 1 of 2: Upgrade staging RDS engine 15.4 → 15.7**
> - Files: `envs/staging.tfvars` (line 11: `db_engine_version` `"15.4"` → `"15.7"`)
> - Resources affected: change `aws_db_instance.paymentapi` (`engine_version`, tags `EngineVersion`), change `aws_db_parameter_group.paymentapi` (tag only; the family stays `postgres15` because the major version stays 15). Expected: 0 to add, 2 to change, 0 to destroy.
> - Blast radius: one staging database `paymentapi-db-staging` (`db.t4g.medium`, single-AZ) read and written by the staging app tier (`code: main.tf:94-99`). Outputs `db_identifier` and `parameter_group_name` keep their values. Consumers of those outputs outside this repo: UNVERIFIED (E10).
> - Disruption: `aws_db_instance`: restart-class unavailability while the engine upgrade runs, with no standby to take over (`live: MultiAZ false`, E4; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html`, read 2026-11-09, "the instance is unavailable while an engine version upgrade runs"). `aws_db_parameter_group`: none (tag-only, in place).
> - Rollback path: **one-way** (`docs:` same page, read 2026-11-09, you cannot move the instance back to the older version; going back means restoring a snapshot taken before the upgrade). `git revert` plus apply does not downgrade. Recovery points: `live:` 3 automated snapshots, newest `rds:paymentapi-db-staging-2026-11-09-02-05`, point-in-time restore to 02:55Z (E7). Restore is `untested`.
> - Evidence: E1, E3, E4, E5, E6, E7, E8, E10
> - Success criteria: `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging --query 'DBInstances[].{EngineVersion:EngineVersion,Status:DBInstanceStatus}'` → `EngineVersion 15.7`, `Status available`; `terraform plan -var-file=envs/staging.tfvars` → `No changes`
>
> **Phase 2 of 2: Upgrade prod RDS engine 14.9 → 15.7** (starts only after Phase 1's success criteria are confirmed)
> - Files: `envs/prod.tfvars` (line 11: `db_engine_version` `"14.9"` → `"15.7"`)
> - Resources affected: change `aws_db_instance.paymentapi` (`engine_version`, tags; `parameter_group_name` moves to the new group), **replace** `aws_db_parameter_group.paymentapi` (the family follows the major version, `postgres14` → `postgres15`, `code: main.tf:7,14`; `docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group`, read 2026-11-09, changing `family` replaces the group). Expected: 1 to add, 1 to change, 1 to destroy. Output `parameter_group_name` (`outputs.tf:6-9`) changes value.
> - Blast radius: the prod database `paymentapi-db-prod` (`db.r6g.large`, Multi-AZ) read and written by the prod app tier (`code: main.tf:94-99`). Consumers of the changed output outside this repo: UNVERIFIED (E10).
> - Disruption: `aws_db_instance`: unavailable while the upgrade runs (`docs:` AWS page above, read 2026-11-09); whether Multi-AZ shortens it: UNVERIFIED (no documentation read). `aws_db_parameter_group`: **replace** (new group of family `postgres15`; `docs:` AWS page above: a major upgrade needs a group of the target family).
> - Rollback path: **one-way** (`docs:` AWS page above, read 2026-11-09). Recovery points: `live:` 3 automated snapshots, newest `rds:paymentapi-db-prod-2026-11-09-02-05`, point-in-time restore to 02:55Z (E7). Restore is `untested`. Application compatibility with PostgreSQL 15: UNVERIFIED (application source not read).
> - Evidence: E2, E3, E4, E5, E6, E7, E8, E9, E10
> - Success criteria: `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{EngineVersion:EngineVersion,Status:DBInstanceStatus,PG:DBParameterGroups[].DBParameterGroupName}'` → `EngineVersion 15.7`, `Status available`, the new group name; `aws rds describe-db-parameter-groups` on that group → `postgres15`; `terraform plan -var-file=envs/prod.tfvars` → `No changes`
>
> **Execution path:** PR (default). Default: I'll create a PR. After merge it is applied by you, by hand (`operator-stated`). If you want me to apply directly, say so; this will escalate the pre-flight assessment (anti-pattern A4: local workstation apply).
> **Branch:** current `main` → `iac-change/paymentapi-rds-engine-15-7` from `origin/main` @ `a1b2c3d` (`git fetch origin main`, then `git switch -c iac-change/paymentapi-rds-engine-15-7 origin/main`)
> **Self-check:** 6/6 pass
>
> **Approve this plan?**

**STOP 2 — GATE 1.**

Operator answer (10:33), from "Answers by meaning" → "GATE 1 (the plan): approve. Execution path: direct apply.": approve the plan; execution path is direct apply. (Same direction as `[F2]`; its L2 answers and delivery-model words are used later where the old skill asks.) The path choice is taken inside this answer, with no second GATE 1 (ambiguity 2 below). The plan now reads "Execution path: Direct apply (operator-chosen)" and pre-flight gets the flag "local workstation apply, not going through CI/CD pipeline" (SKILL.md:330).

---

## Step 3 — Implement, Phase 1 of 2 (staging)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:34 | `git fetch origin main` | `empty.txt` | no output |
| 10:35 | `git switch -c iac-change/paymentapi-rds-engine-15-7 origin/main` | `git-switch.txt` | `Switched to a new branch 'iac-change/paymentapi-rds-engine-15-7'` |
| 10:36 | `git branch --show-current` | `git-branch.txt` says `main` "always" | The switch at 10:35 has happened, so the state rule is applied (protocol rule 1, State) and the answer is `iac-change/paymentapi-rds-engine-15-7`. Using the file's literal `main` would make the skill stop on "a branch other than this change's is checked out" (SKILL.md:64), which the run has not caused. Noted as ambiguity 12. |

Code written (working tree only):

```diff
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

Formatter and diff read (SKILL.md:287, 257):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:37 | `terraform fmt envs/staging.tfvars` (shown before running) | `empty.txt` | no output, already formatted |
| 10:38 | `git status --short` | answered from the diff above | ` M envs/staging.tfvars` |
| 10:39 | `git diff` | answered from the diff above | the diff above |

Canned plan versus code: the staging code change produces exactly the canned `plan-staging.txt` (engine_version and tags only, family unchanged). No difference.

Diff self-check (SKILL.md:257-265): 1 scope pass (only `envs/staging.tfvars`, the one file Phase 1 lists); 2 plan↔hunk pass (the `engine_version` change on the instance and the tag changes on instance and parameter group all follow from the one hunk, via `main.tf:38,48,82`); 3 conventions pass (same `key = "value"` alignment as `code: envs/staging.tfvars:7-11`); 4 no silent safety changes pass; 5 no secrets pass (`db_password` still comes from `TF_VAR_db_password`); 6 formatted pass (`terraform fmt` printed nothing). Result 6/6.

Fresh eyes: required here (a data store changes, SKILL.md:267-268). `fresh-eyes: not run — dry run`.

### Message shown to the operator (code, Phase 1)

> **Code changes for Phase 1 of 2:**
>
> **Modified:** `envs/staging.tfvars` — `db_engine_version` `"15.4"` → `"15.7"` (the staging engine target)
>
> **Plan ↔ hunk:** change `aws_db_instance.paymentapi` (engine + tags) → `envs/staging.tfvars:11`; change `aws_db_parameter_group.paymentapi` (tag only) → `envs/staging.tfvars:11` via `main.tf:38`
> **Self-check:** 6/6 pass · **Fresh eyes:** not run — dry run
>
> Full diff is in your working tree (`git diff` to review).
> **Approve these changes?**

**STOP 3 — GATE 2 (Phase 1).**

Operator answer (10:44), from "Answers by meaning" → "GATE 2 (the code): approve": approve the code.

---

## Step 4a — Generate plan output, Phase 1 (staging)

Target check. The identity read is run before the prompt so that its result can be shown (ambiguity 6 below):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:45 | `aws sts get-caller-identity` (the skill is working on staging) | `identity-staging.json` | account `222222222222`, role `arn:aws:sts::222222222222:assumed-role/paymentapi-operator/operator` |

> **Target check:** `aws sts get-caller-identity` → account `222222222222`, role `arn:aws:sts::222222222222:assumed-role/paymentapi-operator/operator` · region `ap-southeast-1` (`envs/staging.tfvars:2`) · `kubectl config current-context` not applicable · Terraform var-file `envs/staging.tfvars`, no workspace, local backend
> **Plan is for:** staging (`aws_account_id = "222222222222"`, `envs/staging.tfvars:3`) — **match: yes**
> About to run: `terraform plan -out=tfplan -var-file=envs/staging.tfvars` (read-only against the cloud, uses the credentials above). `terraform init` already ran at 10:12 with the same lock file and is not repeated. **Proceed?**

**STOP 4 — 4a target check (Phase 1).**

Operator answer (10:50), from "Answers by meaning" → "4a target check (`Proceed?`): yes": yes.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:51 | `terraform plan -out=tfplan -var-file=envs/staging.tfvars` (staging, before the staging apply) | `plan-staging.txt` | `Plan: 0 to add, 2 to change, 0 to destroy.` |

Plan output shown to the operator (informational, SKILL.md:315):

```text
  # aws_db_instance.paymentapi will be updated in-place
  ~ engine_version = "15.4" -> "15.7"
  ~ tags / tags_all: "EngineVersion" = "15.4" -> "15.7"
  # (62 unchanged attributes hidden)

  # aws_db_parameter_group.paymentapi will be updated in-place
  ~ tags / tags_all: "EngineVersion" = "15.4" -> "15.7"

Plan: 0 to add, 2 to change, 0 to destroy.
```

Cross-check against the evidence table (SKILL.md:313): both resources are in the approved Phase 1; both actions are in-place, which matches the approved disruption (instance: restart-class unavailability, parameter group: none). No replace, no unexpected resource, no drift picked up by refresh. Nothing goes back to the operator.

## Step 4b — Pre-flight gate, Phase 1

Reusable record check (SKILL.md:319-322): `.culiops/pre-flight/` does not exist, so there is no record whose plan hash matches. No match, so pre-flight runs inline with the plan output, the target check, the delivery model (manual, `operator-stated`), the evidence table (0 drift rows, 1 UNVERIFIED row, E10) and the plan hash (SKILL.md:332). The direct-apply flag from GATE 1 goes with it.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:52 | `terraform show -no-color tfplan` (last plan run was for staging) | `plan-staging.txt` | the plan text above, written to a scratch file outside the repo |
| 10:53 | `sha256sum /tmp/iac-plan-staging.txt` | plan hash from `canned/INDEX.md` | `sha256:acc80673cf21bccf4fee77d25b0dd403690555b3bfb36bdd5407d6499858a1dd`. The scratch file is deleted after the hash. |

### Pre-flight, Phase 1, Step 1

Pre-flight loads `assessors/*.md` (`README.md` is the template, `iac-change.md` is the only assessor) and matches the input: a Terraform plan with a `Plan:` summary line. Matched assessor: `iac-change`. Unsupported-stack check passes (Terraform on AWS). Target recorded: account `222222222222`, region `ap-southeast-1`, var-file `envs/staging.tfvars`, local state (no backend block). Delivery model: manual apply, from the caller (`operator-stated`). Plan hash: from the caller.

> **Pre-flight, Step 1.** I detected this as a **Terraform in-place change** affecting `aws_db_instance.paymentapi` (engine 15.4 → 15.7) and `aws_db_parameter_group.paymentapi` (tag only) in **account 222222222222 / ap-southeast-1 / `envs/staging.tfvars`**, delivered by **manual apply from your workstation** (direct apply, local workstation apply flag set). Matched assessor: `iac-change`. Plan hash: `sha256:acc80673…a1dd`. Is this correct?

**STOP 5 — pre-flight GATE 1 (Phase 1).**

Operator answer (10:58), from "Answers by meaning" → "Pre-flight GATE 1 (scope and target): confirm": confirm.

### Pre-flight, Phase 1, Step 2 (L1)

Plan hygiene (assessor `iac-change.md` L1): no "Objects have changed outside of Terraform" block (no drift); the plan was made without `-target` and without `-refresh=false` (the 4a command is `terraform plan -out=tfplan -var-file=envs/staging.tfvars`); "No changes" was not returned; no unexpected resources.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:59 | `git log --oneline --since=7.days main -- main.tf variables.tf outputs.tf envs/staging.tfvars` | `empty.txt` (row `git log * --since=*`) | no commits in 7 days |
| 11:00 | `gh pr list --state open --search 'envs/staging.tfvars'` | `gh-pr-list-empty.txt` | no open PR |
| 11:01 | `git status` | answered from the diff (the skill has written code) | on branch `iac-change/paymentapi-rds-engine-15-7`, `modified: envs/staging.tfvars` (this change's own file) |

Preliminary L1 scores (all cite the plan or code): 1 blast radius Yellow; 2 reversibility Yellow; 3 change velocity Green; 4 dependency impact ⚪ (no catalog, app-facing change); 7 observability Yellow; 8 cost Green; 9 security posture Yellow (direct-apply flag). Changed attributes: `engine_version` is app-facing (not on the assessor's not-app-facing list, so category 11 is triggered); the tags are not-app-facing. Drift rows: 0.

### Pre-flight, Phase 1, Step 3 (L2)

Assessor questions A1 (plan run and reviewed), A2 (delivery model) and A3 (`-target` / `-refresh=false` / non-default var-file) are skipped because L1 holds the answer: the skill ran and showed the plan, the caller passed the delivery model, and the command is shown above (pre-flight SKILL.md:104; assessor L2 :244-249). A4 (applied recently) has no L1 evidence (local state, no CI history), so it is asked after the standard questions.

> **Pre-flight context check:**
> 1. Is there an active incident affecting this service or its dependencies? (yes/no)
> 2. Is there a deploy freeze or change window restriction? (yes/no)
> 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure)
> 4. Have you changed this service before? (many times / a few times / first time)
> 5. Have you used this IaC tool before? (experienced / some experience / first time)
> 6. What's the expected cost impact? (negligible / moderate / significant / unknown)
> 7. Any other context I should know? (free text, optional)
> 8. This change touches what the app depends on: `engine_version`. Where is the application source? (a) a local checkout, give the path; (b) a GitHub repo through `gh`, give `owner/repo` and the deployed ref; (c) not available.
> 9. (IaC-specific) Has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)

**STOP 6 — pre-flight L2 (Phase 1).**

Operator answer (11:06), from "Answers by meaning" → "Pre-flight L2 questions": Q1 = no, Q2 = no, Q3 = no, Q4 = many times, Q5 = experienced, Q6 = negligible, Q7 = none, Q8 = (c) the application source is not available. The script has no answer for item 9 (applied recently), so none is given; it is recorded as `operator: not answered` and the automation-lag signal stays unverified (ambiguity 10 below). The stop itself is covered by the script, so it is not logged as an unscripted stop.

Step 3b (app source scan) is skipped: Q8 = (c), so category 11 is ⚪ with the reason "source not available".

### Pre-flight, Phase 1, Step 4 (L3 opt-in)

Queries left out because the caller's evidence table already answers them: instance status, Multi-AZ and queued changes (E1, E4, E6), snapshots (E7), parameter group (E5).

> **Pre-flight, live signals.** I can check live system health with read-only queries. Without it, resource health stays ⚪ and the best possible verdict is YELLOW. Target check first, then the rest:
> 1. `aws sts get-caller-identity --query Account --output text` (must equal 222222222222)
> 2. `aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging` (last 1h, 300s, Average and Maximum)
> 3. same with `FreeableMemory` (Minimum)
> 4. same with `FreeStorageSpace` (Minimum)
> 5. same with `DatabaseConnections` (Maximum)
> 6. `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-staging`
> 7. `aws cloudwatch describe-alarms --state-value ALARM`
> 8. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi`
> 9. `aws rds describe-events --source-identifier paymentapi-db-staging --source-type db-instance --duration 1440`
> 10. `aws rds describe-pending-maintenance-actions`
>
> Run them? (yes/no)

**STOP 7 — pre-flight L3 opt-in (Phase 1).**

Operator answer (11:11), from "Answers by meaning" → "Pre-flight L3 opt-in: yes": yes.

| Time | Command | Canned file | Result (as used) |
|---|---|---|---|
| 11:12 | `aws sts get-caller-identity --query Account --output text` | `identity-staging.json`, JMESPath applied | `222222222222`, equals the recorded target |
| 11:13 | CPUUtilization, `paymentapi-db-staging` | `metric-rds-cpu-staging.json` | average 8.2-13.8%, maximum 23.8% |
| 11:14 | FreeableMemory | `metric-rds-freeable-memory-staging.json` | average 1.7 GB, minimum 1.40 GB |
| 11:15 | FreeStorageSpace | `metric-rds-free-storage-staging.json` | 14-15 GB free of 20 GB (the maximum is 100 GB with autoscaling) |
| 11:16 | DatabaseConnections | `metric-rds-connections-staging.json` | average 9-12, maximum 31 |
| 11:17 | describe-alarms-for-metric CPU | `alarms-for-metric-cpu-staging.json` | `paymentapi-db-cpu-high-staging`, `ActionsEnabled true`, state `OK`, threshold 80, 3 × 300 s |
| 11:18 | `describe-alarms --state-value ALARM` | `alarms-firing-staging.json` | none firing |
| 11:19 | `describe-alarms --alarm-name-prefix paymentapi` | `alarms-prefix-staging.json` | the same single CPU alarm |
| 11:20 | `describe-events` for the instance, last 24h | `rds-events-staging.json` | two backup events only |
| 11:21 | `describe-pending-maintenance-actions` | `rds-pending-maintenance-staging.json` | none |

Environment was taken as staging for the commands without an environment in the arguments (rule 1(b)). The canned metric datapoints are stamped 02:00-02:55Z, not the requested last hour; the files are used as given ("any window").

### Pre-flight, Phase 1, Steps 5, 5b and 6

Scores (every Green carries the evidence kind Constraint 8 names):

| # | Category | Score | Basis |
|---|---|---|---|
| 1 | Blast radius | Yellow | 2 resources, a database is shared infrastructure, single-AZ so the upgrade is an outage for staging (`live: MultiAZ false`, `docs:` unavailable during an engine upgrade), local workstation apply flag |
| 2 | Reversibility | Yellow | one-way engine upgrade without data loss (`docs:` cannot be reversed in place); rollback = snapshot restore, untested; recovery points exist (`live:` 3 snapshots) |
| 3 | Change velocity | Green | 0 commits to the changed paths in 7 days (`git:` 10:59), no open PR (11:00) |
| 4 | Dependency impact | ⚪ | no catalog; app-facing change; no consumer evidence in code or live |
| 5 | Timing context | Green | Q1, Q2 = no (`operator`); Q3 = no (`operator-stated`), connections flat at 9-12 (`live:` 11:16); the operator applies by hand and is present |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced (`operator`) |
| 7 | Observability readiness | Yellow | one static-threshold CPU alarm, live and enabled; nothing watches storage, connections or the upgrade itself |
| 8 | Cost impact | Green | `plan:` no new resource, no size change; Q6 negligible (`operator-stated`) |
| 9 | Security posture | Yellow | no security attribute changes (`plan:`), raised by the direct-apply flag (local workstation apply, not through CI/CD) |
| 10 | Resource health | Green | `live:` no alarm firing, CPU far below 70%, memory and storage ample, instance `available`, no pending maintenance |
| 11 | Application compatibility | ⚪ | `engine_version` is app-facing; Q8 = (c), no source |

Verdict arithmetic: Red = none; Yellow + ⚪ = 6 (1, 2, 4, 7, 9, 11), which is 3 or more, so escalation applies. Hard-block conditions checked: category 2 (no data loss, snapshots exist, not a listed hard-block row), category 5 (no incident, no freeze), category 9 (no public exposure, encryption or secrets change), category 10 (no SLO, no firing alarm). Verdict: **RED — soft block** (multi-Yellow escalation).

Step 5b: citations re-opened: the Green on category 10 (1), the four hard-block conditions (4), the factual premise of each of the six mitigations (6) = 11, fixes none; source conflicts none; not verified: Q3 and Q6 (`operator-stated`), the cause of "applied recently" (not answered), consumers, application compatibility. Fresh eyes: not required (the verdict is RED — soft block, pre-flight SKILL.md:315).

### Message shown to the operator (pre-flight report, Phase 1)

> **Pre-flight report: paymentapi staging engine 15.4 → 15.7** — Verdict: **RED — SOFT BLOCK** (3+ Yellow/⚪ categories escalate)
>
> Scorecard: 1 Yellow · 2 Yellow · 3 Green · 4 ⚪ · 5 Green · 6 Green · 7 Yellow · 8 Green · 9 Yellow · 10 Green · 11 ⚪ (full scorecard with evidence is in the pre-flight record)
> Drift rows: 0. Verification: citations checked 11, fixes none; verdict working above; fresh eyes not required (RED — soft block).
>
> **Findings**
> - 1 Blast radius, Yellow. Found: 2 resources, shared database, single-AZ (`plan:` lines 6-20, `live: MultiAZ false`). Matters: staging is unavailable while the upgrade runs. Mitigation: announce the window to staging consumers.
> - 2 Reversibility, Yellow. Found: the engine upgrade is one-way (`docs:` read 2026-11-09). Matters: going back means a snapshot restore nobody has tried. Mitigation (operator action): take a manual snapshot right before the apply; pre-flight never runs it.
> - 4 Dependency impact, ⚪. Found: no catalog, no consumer evidence. Matters: unknown consumers of the instance and outputs. Mitigation: run service-discovery or list the consumers.
> - 7 Observability, Yellow. Found: one static CPU alarm (`live: ActionsEnabled true`). Matters: a failed upgrade shows up in no alarm. Mitigation: watch RDS events and the exported `upgrade` log during the apply.
> - 9 Security posture, Yellow. Found: local workstation apply (A4 flag). Matters: no CI review or audit trail. Mitigation: the execution record is the audit trail.
> - 11 Application compatibility, ⚪. Found: `engine_version` is app-facing, no source. Matters: a version change can break a driver silently. Mitigation: give the application source at the deployed ref.
>
> **GATE 2:** Red soft block. Acknowledge each finding with a stated reason, or abort.

**STOP 8 — pre-flight GATE 2 (Phase 1).**

Operator answer (11:26), from "Answers by meaning" → "Pre-flight GATE 2 (risk decision): acknowledge and proceed", with the stated reason from the `[H5]` entry because the verdict is RED: acknowledge every finding, reason "staging, minor engine upgrade, a restart is expected". No mitigation is committed to.

### Pre-flight, Phase 1, Step 7

Pre-flight record written to `.culiops/pre-flight/paymentapi-rds-engine-upgrade-staging-20261109-1126.md` (content in `preflight-record.md`, record 1). Invoked by another skill, so it is left uncommitted.

## GATE 3 — Pre-flight clearance, Phase 1

Verdict RED soft block, so the operator must acknowledge each Red finding (SKILL.md:324-326). The skill shows: "Pre-flight verdict: RED — soft block (escalation from 6 Yellow/⚪ categories); acknowledged at pre-flight GATE 2 with the reason above. Acknowledge and continue to execution?"

**STOP 9 — GATE 3 (Phase 1).**

Operator answer (11:31), from "Answers by meaning" → "GATE 3 (clearance) and GATE 4 (execution): approve": approve.

## Step 4c — Execute, Phase 1 (direct apply)

Offer (SKILL.md:336): "Draft a heads-up for the people affected (service owners, reviewers, on-call) with `change-comms` before the apply? It is draft-only; you send it."

**STOP 10 — change-comms offer (Phase 1).**

Operator answer (11:36), from "Answers by meaning" → "Optional offers (a change-comms heads-up, …): no": no.

> About to run: `terraform apply tfplan`
> This will: change `aws_db_instance.paymentapi` (engine 15.4 → 15.7, tags) and `aws_db_parameter_group.paymentapi` (tags); 0 add, 2 change, 0 destroy
> Target check, re-shown: account `222222222222` (`arn:aws:sts::222222222222:assumed-role/paymentapi-operator/operator`) · `ap-southeast-1` · `envs/staging.tfvars` — plan is for staging, match: yes
> **Proceed?**

**STOP 11 — GATE 4 (Phase 1).**

Operator answer (11:41), from "Answers by meaning" → "GATE 4 (the apply command): approve for staging": approve. (Same direction as `[F4]` staging; the old skill has no YELLOW-acknowledgement wording.)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:42 | `terraform apply tfplan` (staging; run in the background with a timeout well above the expected duration, never interrupted) | `apply-staging.txt` | `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` The instance modification completed after 11m24s (11:42 → 11:53). |

## Step 5a — Verification, Phase 1 (direct apply path)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:54 | `terraform plan -var-file=envs/staging.tfvars` (re-plan, staging, after the staging apply) | `plan-after-staging.txt` | `No changes. Your infrastructure matches the configuration.` |

The re-plan is run without an approval prompt (ambiguity 8 below).

> "Apply completed. I can run read-only health checks to verify the change is working. Want me to try? (yes/no)"

**STOP 12 — health checks offer (Phase 1).**

Operator answer (11:59), from "Answers by meaning" → "Optional offers … : no": no. The health-check offer is not in the script's list of examples; it is treated as part of that class (ambiguity 9 below).

> **Verification for Phase 1:** Re-plan: clean. Health checks: not requested.

### Multi-phase handling (SKILL.md:363-370)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:00 | `aws rds describe-db-instances --db-instance-identifier paymentapi-db-staging --query 'DBInstances[].{EngineVersion:EngineVersion,Status:DBInstanceStatus}'` (Phase 1 success criterion, run after the staging apply) | `rds-instance-after-staging.json`, JMESPath applied | `EngineVersion 15.7`, `Status available` |

This command was approved as part of the plan at GATE 1 (ambiguity 11 below).

> "Phase 1 complete. Success criteria: `describe-db-instances` → `EngineVersion 15.7`, `Status available`, and re-plan `No changes` — **pass**.
> Ready to proceed to Phase 2: Upgrade prod RDS engine 14.9 → 15.7?"

**STOP 13 — phase gate (Phase 1 to Phase 2).**

The script has no entry for the phase gate. Answered "approve / yes / as proposed" and logged as unscripted: yes (12:05). The old text asks for nothing else between the phases: no observation window, no comparison of what staging exercised with what prod will do (SKILL.md:368).

---

## Step 3 — Implement, Phase 2 of 2 (prod)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:06 | `git branch --show-current` | state rule applied (see ambiguity 12) | `iac-change/paymentapi-rds-engine-15-7`, the change's branch from Phase 1; direct apply path, no merge between phases |

Code written:

```diff
--- a/envs/prod.tfvars
+++ b/envs/prod.tfvars
@@ -8,5 +8,5 @@
 db_storage_gb         = 100
 db_max_storage_gb     = 500
 db_multi_az           = true
-db_engine_version     = "14.9"
+db_engine_version     = "15.7"
 # db_password comes from TF_VAR_db_password
```

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:07 | `terraform fmt envs/prod.tfvars` | `empty.txt` | no output |
| 12:08 | `git status --short` | answered from the diffs | ` M envs/prod.tfvars` and ` M envs/staging.tfvars` (the second is Phase 1's change, still uncommitted on the direct-apply path) |
| 12:09 | `git diff` | answered from the diffs | the prod hunk above, plus Phase 1's staging hunk |

Canned plan versus code: the prod code change produces the canned `plan-prod.txt`: `engine_version` 14.9 → 15.7, `parameter_group_name` known after apply, family `postgres14` → `postgres15` forces the replacement. No difference between what the code does and the canned plan.

Diff self-check: 1 scope pass, with a note: `envs/staging.tfvars` is also modified in the working tree. It is Phase 1's approved and already applied change, not part of Phase 2's file list; the literal text of item 1 ("this phase's approved file list … nothing else is touched") does not say how to treat a carried-over earlier phase (ambiguity 13). Taken as a carried-over approved change, not a scope failure. 2 plan↔hunk pass (all three Phase 2 resource actions follow from the one hunk; the replace via `main.tf:7,14`); 3 conventions pass; 4 no silent safety changes pass; 5 no secrets pass; 6 formatted pass. Result 6/6.

Fresh eyes: `fresh-eyes: not run — dry run`.

### Message shown to the operator (code, Phase 2)

> **Code changes for Phase 2 of 2:**
>
> **Modified:** `envs/prod.tfvars` — `db_engine_version` `"14.9"` → `"15.7"` (the prod engine target)
>
> **Plan ↔ hunk:** change `aws_db_instance.paymentapi` (engine, `parameter_group_name`, tags) → `envs/prod.tfvars:11`; replace `aws_db_parameter_group.paymentapi` (family `postgres14` → `postgres15`) → `envs/prod.tfvars:11` via `main.tf:7,14`
> **Self-check:** 6/6 pass · **Fresh eyes:** not run — dry run
>
> Full diff is in your working tree (`git diff` to review).
> **Approve these changes?**

**STOP 14 — GATE 2 (Phase 2).**

Operator answer (12:14), from "Answers by meaning" → "GATE 2 (the code): approve": approve. The same mapping entry covers both phases' GATE 2 (the script's `[F3]` says "both var-files" for the new skill; the old skill shows one phase at a time).

---

## Step 4a — Generate plan output, Phase 2 (prod)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:15 | `aws sts get-caller-identity` (the skill is working on prod; credentials switched, not a stop) | `identity-prod.json` | account `333333333333`, role `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` |

> **Target check:** `aws sts get-caller-identity` → account `333333333333`, role `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` · region `ap-southeast-1` (`envs/prod.tfvars:2`) · Terraform var-file `envs/prod.tfvars`, no workspace, local backend
> **Plan is for:** prod (`aws_account_id = "333333333333"`, `envs/prod.tfvars:3`) — **match: yes**
> About to run: `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above). `terraform init` already ran at 10:12 and is not repeated. **Proceed?**

**STOP 15 — 4a target check (Phase 2).**

Operator answer (12:20), from "Answers by meaning" → "4a target check (`Proceed?`): yes": yes.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:21 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | `plan-prod.txt` | `Plan: 1 to add, 1 to change, 1 to destroy.` |

Plan output shown to the operator:

```text
  # aws_db_instance.paymentapi will be updated in-place
  ~ engine_version        = "14.9" -> "15.7"
  ~ parameter_group_name  = "paymentapi-prod-20250617043012345600000001" -> (known after apply)
  ~ tags / tags_all: "EngineVersion" = "14.9" -> "15.7"

  # aws_db_parameter_group.paymentapi must be replaced
-/+ ~ family = "postgres14" -> "postgres15" # forces replacement
    ~ arn, id, name -> (known after apply)
    ~ tags / tags_all: "EngineVersion" = "14.9" -> "15.7"

Plan: 1 to add, 1 to change, 1 to destroy.
```

Cross-check against the evidence table (SKILL.md:313): `aws_db_instance.paymentapi` (in place) and `aws_db_parameter_group.paymentapi` (replace) are both in the approved Phase 2. The replace is the action the approved plan named, with disruption "replace", so it does not go back to the operator as an unexpected replace. The `parameter_group_name` change on the instance and the `parameter_group_name` output change are both in the approved Phase 2. No unexpected resource, no drift. Nothing goes back to the operator, so there is no stop here and the operator script's abort for "a replace the approved plan did not name" (`[H3]`) does not apply: that replace was named at GATE 1.

## Step 4b — Pre-flight gate, Phase 2

Reusable record check: the only record in `.culiops/pre-flight/` is Phase 1's, whose plan hash (`sha256:acc80673…`), target (account 222222222222) and var-file differ. No match, so pre-flight runs inline again, with the direct-apply flag.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:22 | `terraform show -no-color tfplan` (last plan run was for prod) | `plan-prod.txt` | the prod plan text, written to a scratch file outside the repo |
| 12:23 | `sha256sum /tmp/iac-plan-prod.txt` | plan hash from `canned/INDEX.md` | `sha256:25ca45650f7c2067c858c5cc4507499de09f9a762e9bce363c94b594c05177c9`; scratch file deleted |

> **Pre-flight, Step 1.** I detected this as a **Terraform change with a replacement** affecting `aws_db_instance.paymentapi` (engine 14.9 → 15.7, in place), and `aws_db_parameter_group.paymentapi` (**replace**, family `postgres14` → `postgres15`) in **account 333333333333 / ap-southeast-1 / `envs/prod.tfvars`**, delivered by **manual apply from your workstation** (direct apply, local workstation apply flag set). Matched assessor: `iac-change`. Plan hash: `sha256:25ca4565…77c9`. Is this correct?

**STOP 16 — pre-flight GATE 1 (Phase 2).**

Operator answer (12:28), from "Answers by meaning" → "Pre-flight GATE 1 (scope and target): confirm": confirm.

### Pre-flight, Phase 2, Step 2 (L1)

Plan hygiene: no drift block; no `-target` or `-refresh=false`; the plan is not "No changes"; the replace was named at GATE 1, so it is not an unexpected resource. Output `parameter_group_name` changes (`outputs.tf:6-9`, plan line 12).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:29 | `git log --oneline --since=7.days main -- main.tf variables.tf outputs.tf envs/prod.tfvars` | `empty.txt` | no commits in 7 days |
| 12:30 | `gh pr list --state open --search 'envs/prod.tfvars'` | `gh-pr-list-empty.txt` | no open PR |
| 12:31 | `git status` | answered from the diffs | modified `envs/prod.tfvars` (this change) and `envs/staging.tfvars` (this change's Phase 1, already applied, a different file) |

Preliminary L1 scores: 1 blast radius Red; 2 reversibility Red; 3 change velocity Green; 4 dependency impact ⚪; 7 observability Yellow; 8 cost Green; 9 security posture Yellow (direct-apply flag). Changed attributes: `engine_version` (major, app-facing, `assessor:` lists "incompatible engine or runtime version"), `parameter_group_name` and the replaced group (app-facing, not on the not-app-facing list), tags (not-app-facing). Category 11 is triggered.

### Pre-flight, Phase 2, Step 3 (L2)

Same questions as in Phase 1 (a new pre-flight run asks again). A1-A3 skipped on L1 evidence; A4 asked.

**STOP 17 — pre-flight L2 (Phase 2).**

Operator answer (12:36), from "Answers by meaning" → "Pre-flight L2 questions … give the same L2 answers": Q1 = no, Q2 = no, Q3 = no, Q4 = many times, Q5 = experienced, Q6 = negligible, Q7 = none, Q8 = (c). No answer for item 9, recorded as `operator: not answered`.

Step 3b skipped (Q8 = (c)); category 11 is ⚪.

### Pre-flight, Phase 2, Step 4 (L3 opt-in)

Same ten-item list as Phase 1 with the prod resources: item 1 `aws sts get-caller-identity --query Account --output text` (must equal 333333333333), items 2-5 the four RDS metrics for `paymentapi-db-prod`, item 6 `describe-alarms-for-metric` for `paymentapi-db-prod`, items 7-8 the two `describe-alarms` calls, item 9 `describe-events` for `paymentapi-db-prod`, item 10 `describe-pending-maintenance-actions`. Run them? (yes/no)

**STOP 18 — pre-flight L3 opt-in (Phase 2).**

Operator answer (12:41), from "Answers by meaning" → "Pre-flight L3 opt-in: yes": yes.

| Time | Command | Canned file | Result (as used) |
|---|---|---|---|
| 12:42 | `aws sts get-caller-identity --query Account --output text` | `identity-prod.json`, JMESPath applied | `333333333333`, equals the recorded target |
| 12:43 | CPUUtilization, `paymentapi-db-prod` | `metric-rds-cpu-prod.json` | average 31.2-36.8%, maximum 46.8% |
| 12:44 | FreeableMemory | `metric-rds-freeable-memory-prod.json` | average 6.4 GB, minimum 6.10 GB |
| 12:45 | FreeStorageSpace | `metric-rds-free-storage-prod.json` | 82-83 GB free of 100 GB |
| 12:46 | DatabaseConnections | `metric-rds-connections-prod.json` | average 52-55, maximum 78 (`max_connections` 200 in `main.tf:19`) |
| 12:47 | describe-alarms-for-metric CPU | `alarms-for-metric-cpu-prod.json` | `paymentapi-db-cpu-high-prod`, `ActionsEnabled true`, state `OK` |
| 12:48 | `describe-alarms --state-value ALARM` | `alarms-firing-prod.json` | none firing |
| 12:49 | `describe-alarms --alarm-name-prefix paymentapi` | `alarms-prefix-prod.json` | the same single CPU alarm |
| 12:50 | `describe-events` for the instance, last 24h | `rds-events-prod.json` | two backup events only |
| 12:51 | `describe-pending-maintenance-actions` | `rds-pending-maintenance-prod.json` | none |

Environment taken as prod for the commands without an environment in the arguments (rule 1(b)).

### Pre-flight, Phase 2, Steps 5, 5b and 6

| # | Category | Score | Basis |
|---|---|---|---|
| 1 | Blast radius | Red | prod database of the payments service on the app's data path (`code: main.tf:94-99`), unavailable while a major upgrade runs (`docs:`), a destroy and a create in the plan (`plan:` lines 24-27, 43), Multi-AZ softening not documented (UNVERIFIED), local workstation apply flag |
| 2 | Reversibility | Red | `assessor:` one-way table, RDS `engine_version` major upgrade is Red (no in-place downgrade, rollback = restore from snapshot); `docs:` cannot be reversed in place; recovery points exist (`live:` 3 snapshots, PITR to 02:55Z), restore untested. Not a listed hard-block row. |
| 3 | Change velocity | Green | 0 commits in 7 days (`git:` 12:29), no open PR (12:30), no uncommitted change to the same files |
| 4 | Dependency impact | ⚪ | no catalog; app-facing; output `parameter_group_name` changes (`plan:` line 12) and no consumer evidence |
| 5 | Timing context | Green | Q1, Q2 = no (`operator`); Q3 = no (`operator-stated`), connections flat 52-55 (`live:` 12:46); the operator applies by hand and is present |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced (`operator`) |
| 7 | Observability readiness | Yellow | one static-threshold CPU alarm, live and enabled; nothing watches storage, connections, or the upgrade |
| 8 | Cost impact | Green | `plan:` one resource replaced (net zero), no size change; Q6 negligible (`operator-stated`) |
| 9 | Security posture | Yellow | no security attribute changes (`plan:`), raised by the direct-apply flag |
| 10 | Resource health | Green | `live:` no alarm firing, CPU below 47%, memory and storage ample, instance `available`, no pending maintenance |
| 11 | Application compatibility | ⚪ | the major engine version change is app-facing and is the assessor's "incompatible engine or runtime version" example; Q8 = (c), no source. Silent breakage: health, error-rate and alarm signals will not show a driver incompatibility |

Verdict arithmetic: Red = 1, 2; Yellow + ⚪ = 4 (4, 7, 9, 11). Hard-block conditions checked: category 2 (the assessor lists a major upgrade as Red, not as a hard block), 5 (no incident or freeze), 9, 10 (no SLO, nothing firing). Verdict: **RED — soft block**. Fresh eyes: not required (RED — soft block).

### Message shown to the operator (pre-flight report, Phase 2)

> **Pre-flight report: paymentapi prod engine 14.9 → 15.7** — Verdict: **RED — SOFT BLOCK**
>
> Scorecard: 1 Red · 2 Red · 3 Green · 4 ⚪ · 5 Green · 6 Green · 7 Yellow · 8 Green · 9 Yellow · 10 Green · 11 ⚪ (full scorecard in the pre-flight record)
> Drift rows: 0. Verification: citations checked 13 (the two Reds, the Green on category 10, four hard-block conditions, six mitigation premises), fixes none; verdict working above; fresh eyes not required.
>
> **Findings**
> - 1 Blast radius, Red. Found: major upgrade on the prod database plus a parameter-group replace (`plan:` lines 24-27). Matters: the payments data store is unavailable while the upgrade runs and Multi-AZ's effect is undocumented. Mitigation: schedule a window and tell the app owners.
> - 2 Reversibility, Red. Found: one-way major upgrade. Matters: rollback is a snapshot restore nobody has tried, and writes after the snapshot are lost. Mitigation (operator action): take a manual snapshot right before the apply and rehearse the restore.
> - 4 Dependency impact, ⚪. Found: no catalog; the `parameter_group_name` output changes. Mitigation: list consumers of the instance and the output.
> - 7 Observability, Yellow. Found: one static CPU alarm. Mitigation: watch RDS events and the `upgrade` log.
> - 9 Security posture, Yellow. Found: local workstation apply. Mitigation: the execution record is the audit trail.
> - 11 Application compatibility, ⚪. Found: a major engine change with no application source. Matters: a driver or query incompatible with PostgreSQL 15 breaks silently. Mitigation: the application source at the deployed ref, and the driver's support matrix for PostgreSQL 15.
>
> **GATE 2:** Red soft block. Acknowledge each Red finding with a stated reason, or abort.

**STOP 19 — pre-flight GATE 2 (Phase 2).**

Operator answer (12:56), from "Answers by meaning" → "Pre-flight GATE 2 (risk decision): acknowledge and proceed", with the stated reason from the `[H5]` entry: "staging, minor engine upgrade, a restart is expected". That reason describes staging, not this prod change (a major upgrade with a replace). The runner says what the script says and does not edit it. No mitigation is committed to.

Pre-flight record written to `.culiops/pre-flight/paymentapi-rds-engine-upgrade-prod-20261109-1256.md` (content in `preflight-record.md`, record 2), left uncommitted.

## GATE 3 — Pre-flight clearance, Phase 2

Verdict RED soft block: the operator must acknowledge each Red finding (categories 1 and 2).

**STOP 20 — GATE 3 (Phase 2).**

Operator answer (13:01), from "Answers by meaning" → "GATE 3 (clearance) and GATE 4 (execution): approve": approve.

## Step 4c — Execute, Phase 2 (direct apply)

Offer: draft a heads-up with `change-comms` before the apply?

**STOP 21 — change-comms offer (Phase 2).**

Operator answer (13:06), from "Answers by meaning" → "Optional offers … : no": no.

> About to run: `terraform apply tfplan`
> This will: change `aws_db_instance.paymentapi` (engine 14.9 → 15.7, new parameter group, tags) and **replace** `aws_db_parameter_group.paymentapi` (`postgres14` → `postgres15`); 1 add, 1 change, 1 destroy
> Target check, re-shown: account `333333333333` (`arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator`) · `ap-southeast-1` · `envs/prod.tfvars` — plan is for prod, match: yes
> **Proceed?**

**STOP 22 — GATE 4 (Phase 2, prod).**

Operator answer (13:11), from the `[F4]` (prod) entry (reached because `[H3]` did not fire; the script marks this as a MUST failure): abort. "Stop. I won't take an unrehearsed replace to prod."

The skill stops. Nothing was applied to prod: `terraform apply tfplan` for prod was not run, and there is no canned output for it. `tfplan` stays local and is not staged (Constraint 11). The skill writes the partial execution record with outcome ABORTED (SKILL.md:328), to `.culiops/iac-change-execution/paymentapi-rds-engine-upgrade-20261109-1311.md` (content in `record.md`). No GATE 5 commit offer follows an abort (ambiguity 14).

> Execution aborted at GATE 4 (Phase 2, prod). Phase 1 (staging) was applied and verified. Phase 2 was not applied. Execution record: `.culiops/iac-change-execution/paymentapi-rds-engine-upgrade-20261109-1311.md`.

End of run.

---

## Ambiguities and readings taken

1. **Delivery-model question not asked** (SKILL.md:154-156, script "Delivery-model question"). The first message already says "applied by hand, no CI", so the delivery model is `operator-stated` and not UNVERIFIED; the skill asks only when nothing in the repo or the request shows it.
2. **Execution path chosen inside the GATE 1 answer** (SKILL.md:206, 242). The plan prompt says "If you want me to apply directly, say so", so the path choice is part of the one GATE 1 stop. The text does not say whether a path change needs a second approval; none was taken.
3. **Two phases** (SKILL.md:27, 190-193). "Staging first, then prod" is read as an ordered two-phase change with verification between, each phase on its own var-file and its own target.
4. **Per-phase GATE 2** (SKILL.md:246-284). The code is shown phase by phase, so there are two GATE 2 stops. The script's "GATE 2 (the code): approve" entry is applied to each.
5. **GATE 3 on a RED verdict** (SKILL.md:324-328). For GREEN/YELLOW the text says "Proceed", with no stop. For a RED soft block it says the operator must acknowledge each Red finding, so GATE 3 is a stop, even though pre-flight's own GATE 2 just collected the same acknowledgement.
6. **Target check is run before it is shown** (SKILL.md:298-302). The prompt contains the identity output, so `aws sts get-caller-identity` runs first; it was in the approved Step 1 batch as the target check.
7. **Order after the apply** (SKILL.md:357-370, 385-396, diagram lines 120-124). Taken as: apply, then 5a (re-plan, health-check offer, report), then the multi-phase success-criteria check and phase gate, then Step 3 of the next phase.
8. **Re-plan in 5a runs without an approval prompt** (SKILL.md:386 says "Run"; Constraint 3, SKILL.md:25, names the Step 4a plan command, not the 5a re-plan).
9. **Health-check offer** (SKILL.md:388-390). The script's list of optional offers does not name it; it is answered "no" as part of that class, not logged as unscripted.
10. **Pre-flight assessor L2 questions** (pre-flight SKILL.md:104, 108; `iac-change.md` L2 :244-249). Questions answered by L1 evidence are skipped. The one that is not (applied recently) is asked in the same L2 message; the script has no answer for it, so it is recorded as not answered.
11. **Success-criteria command run without a separate approval** (SKILL.md:25, 363-364). It is part of the plan approved at GATE 1.
12. **`git branch --show-current` after the switch.** `canned/INDEX.md` says `main` "always". After the simulated `git switch -c`, the state rule is applied and the new branch name is returned.
13. **Phase 2 diff scope check** (SKILL.md:259). Phase 1's uncommitted `envs/staging.tfvars` change is in the working tree on the direct-apply path. The text speaks of "this phase's approved file list" only.
14. **Abort path** (SKILL.md:328 against 442-443). The abort writes a partial record and stops; no GATE 5 commit offer is made.
15. **The `[H5]` reason at prod.** The script's only Red-acknowledgement reason is the staging reason. It is used at prod's pre-flight GATE 2 as scripted.
16. **Canned metric windows.** The metric files hold datapoints for 02:00-02:55Z whatever window is requested ("any window").
17. **Two pre-flight records.** The protocol names one `preflight-record.md`. Both records (staging, prod) are in that file under separate headings.
18. **No unnamed replace.** The approved plan named the prod parameter-group replace (derived from `main.tf:7,14` and the `docs:` lookups that Constraint 9 requires for the disruption claim). The 4a cross-check therefore found nothing unexpected and the script's `[H3]` condition ("a replace the approved plan did not name") never occurred. The operator abort happened at the last gate, GATE 4 for prod.
19. **No staging-first rule and no parity check in the old text.** Staging was applied first only because the operator asked for it. Nothing in the old skill or pre-flight compares what the staging apply exercises (no parameter-group replace, same major version) with what prod will do, or asks the operator whether prod's 14 → 15 move is intended; the phase gate asks only whether to continue.
20. **No `no canned output` lookups.** Every command found a canned row. A parameter-group name was filled in from the earlier `describe-db-instances` output.
