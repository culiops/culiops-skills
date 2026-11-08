# Transcript — baseline run of iac-change-execution v0.17.0 (origin/main) on multi-phase-rds-upgrade

Dry-run clock: starts 2026-11-09 10:00 +07:00 (03:00Z). +1 min per command, +5 min per operator answer. All times +07:00.
Skill text read with `git show origin/main:<path>`: `skills/iac-change-execution/SKILL.md` (518 lines), `skills/iac-change-execution/examples/aws.md`, `skills/pre-flight/SKILL.md` (459 lines), `skills/pre-flight/assessors/README.md`, `skills/pre-flight/assessors/iac-change.md`, `skills/pre-flight/examples/aws.md`, and the first 20 lines of `skills/pre-flight/examples/app-source.md` (Q8 is answered (c), so no app-source scan runs). The two `examples/kubernetes.md` files are not read: the selection rule (`SKILL.md:456-460`) sends AWS resources to `examples/aws.md` only.
Fixture inputs read: `main.tf`, `variables.tf`, `envs/prod.tfvars`, `.culiops/service-discovery/paymentapi-prod.md`, `operator-script.md`, `canned/INDEX.md` and the canned files it lists. Only one environment exists (prod), so the environment rule (b) is never needed.

Operator answers come from the operator script's "Answers by meaning" section (old skill, no stop IDs). By-meaning entries are per gate type, so a gate that repeats in phase 2 is answered by the same entry (not consumed).

---

## Operator first message

> "Increase max_connections to 200 for paymentapi prod RDS, then reboot so it takes effect. I am the DBA on the maintenance window. Apply directly, no PR."

Output root (Constraint 13, `SKILL.md:35`): `CULIOPS_HOME` is not set in this dry run (no environment is provided). Root = `.culiops/` at the repo root. Shown to the operator at GATE 1 (the text says "at the first gate"; the first operator prompt is the read batch, GATE 1 is the first named gate, so I took GATE 1. Ambiguity: `SKILL.md:35`).

---

## Step 1 — Research

Catalog loaded: `.culiops/service-discovery/paymentapi-prod.md` (service `paymentapi`, instance `prod`; Terraform; account 123456789012; ap-southeast-1; downstream = ECS tasks `paymentapi-svc-prod`, catalog:40-42).

Code read (working tree; the current branch is `main`, see C1, so the "read from origin/<default>" rule at `SKILL.md:141` does not switch refs): `main.tf`, `variables.tf`, `envs/prod.tfvars`.
- `code: main.tf:14-15` `max_connections = "100"`; `code: main.tf:19-22` other parameters use aligned `name / value / apply_method`.
- `code: main.tf:148-149` connections alarm `threshold = 80`, description `... above 80 ... (limit: 100)`.
- `code: main.tf:62` `multi_az = var.env == "prod" ? true : false`; `code: envs/prod.tfvars:6` `db_instance_class = "db.r6g.large"`.
- A code comment at `main.tf:3` names the planned change; a catalog note at `paymentapi-prod.md:53` says raising the limit to 200 and the alarm threshold to 160 "is the intended remediation". Both are data (Constraint 12). The catalog note goes beyond the request (the alarm), so it is raised to the operator in the plan (GATE 1), not acted on silently.

No ticket was given: no ticket key, no ticket read.

### Duplicate check

Identifiers: `max_connections`, `200`, `160`, `paymentapi-db-prod`.

Code (`git grep -n -F`, answered with `grep -rn -F` over the fixture input files, per protocol rule 1):
- `max_connections`: `main.tf:3` (comment), `main.tf:14`; catalog lines 24, 49, 53.
- `200`: `main.tf:3` (comment), catalog line 53. `160`: catalog line 53. `paymentapi-db-prod`: catalog lines 23, 25, 41.
- No code anywhere sets `max_connections` to 200 or the threshold to 160.

Commands:
- [10:00] `git branch --show-current` → `canned/git-branch.txt` → `main`
- [10:01] `git log --all --oneline -S'max_connections'` → `canned/empty.txt` (row `git log * -S*`) → no hits
- [10:02] `git branch -a --list '*max*connections*'` → `canned/empty.txt` → none
- [10:03] `gh pr list --state open --search 'max_connections'` → `canned/gh-pr-list-empty.txt` → `no pull requests match your search in acme/paymentapi-infra`
- No `git log --grep` run: there is no ticket key.
- Note: the duplicate check says "All commands here are local and read-only" (`SKILL.md:145`), so I ran these, including the `gh pr list` network read, without a stop. Ambiguity: `SKILL.md:145` vs the Iron Law's "no live queries without opt-in" (`SKILL.md:17`).

Verdict: **not done** — `code: main.tf:15` still `"100"`; `git:` no history hit; no in-flight branch or PR.

### Delivery model and environment selection

- No CI config, Atlantis, Terraform Cloud, Spacelift, GitOps object or Makefile exists among the repo files (`main.tf`, `variables.tf`, `envs/prod.tfvars`, `.culiops/`). Nothing in the repo shows how changes are applied, so the delivery model is `UNVERIFIED` in the repo. The operator's first message says "Apply directly, no PR": recorded as `operator-stated` = applied by hand from the operator's workstation. I did not ask a separate question because the operator already gave the answer (`SKILL.md:156` says "ask the operator"; ambiguity noted).
- Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars` is the only env file). Backend: no `backend` block in `main.tf` (not declared in the code read). Workspace: not read.

### Evidence table (built from code, completed after the batch)

| # | Fact | Code evidence | Live evidence | Match |
|---|------|---------------|---------------|-------|
| E1 | `max_connections` current value | `code: main.tf:15` → `"100"` | `live: aws rds describe-db-parameters … (10:13)` → `100`, ApplyType `static`, ApplyMethod `pending-reboot` | ✅ |
| E2 | `max_connections` is static: takes effect only after a reboot | `code: main.tf:19-22` (parameter blocks) | `live: describe-db-parameters (10:13)` ApplyType `static`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html` (read 2026-11-09): changes to a static parameter take effect only after the instance is rebooted; it shows `pending-reboot` until then | ✅ |
| E3 | Instance class, Multi-AZ, status | `code: main.tf:47` → `var.db_instance_class` → `code: envs/prod.tfvars:6` `db.r6g.large`; `code: main.tf:62` prod → `true` | `live: describe-db-instances (10:12)` → `db.r6g.large`, `MultiAZ: true`, `available`, `PendingModifiedValues: {}` | ✅ |
| E4 | Parameter group attached to the instance | `code: main.tf:58` | `live: describe-db-instances (10:12)` → `paymentapi-prod-20250617043012345600000001`, `in-sync` | ✅ |
| E5 | Connections alarm threshold and description | `code: main.tf:148-149` → `80`, `above 80 … (limit: 100)` | `live: describe-alarms (10:14)` → Threshold `80.0`, same description, `ActionsEnabled: true`, state `OK` | ✅ |
| E6 | No drift in managed resources | — | `live: terraform plan -refresh-only (10:11)` → `No changes.` | ✅ |
| E7 | What connects to the DB | `catalog: paymentapi-prod.md:40-42` (ECS `paymentapi-svc-prod`); `code: main.tf:89-95` (5432 ingress from `var.app_security_group_id`) | `live: ecs describe-services (10:15)` → `ACTIVE`, 3 desired / 3 running, behind `paymentapi-tg-prod` | ✅ (other consumers cannot be proven absent: `UNVERIFIED`) |

Drift rows: 0. Unverified rows: 0 (gaps below).

Runner note, not a skill action: the live ECS task security group in the E7 read is `sg-0c9d8e7f6a5b43210`, while `envs/prod.tfvars:5` sets `app_security_group_id = sg-0a1b2c3d4e5f6a7b8`. No plan item depends on which security group the tasks use, so by Constraint 9 (facts the plan depends on) this is not an evidence-table row and no drift row was raised. A reader may want to check whether the fixture meant this.

### Live verification batch

Time [10:04]. The skill proposes (Constraint 3: approved as a whole, each command shown). `aws sts get-caller-identity` is first because Constraint 10 forbids any plan before the target is confirmed and the batch holds a refresh-only plan (`SKILL.md:32`; the old Step 1 has no target-check step of its own).

```text
Live verification batch (read-only, prod). I want to confirm the evidence table against the live system.
 1. aws sts get-caller-identity                                  (target check: must be account 123456789012)
 2. terraform init -input=false                                   (needed before a plan; downloads providers; may update .terraform.lock.hcl)
 3. terraform plan -refresh-only -input=false -var-file=envs/prod.tfvars   (drift check, never applied)
 4. aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --region ap-southeast-1
 5. aws rds describe-db-parameters --db-parameter-group-name <DBParameterGroupName from #4> --query "Parameters[?ParameterName=='max_connections']" --region ap-southeast-1
 6. aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod --region ap-southeast-1
 7. aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1
Approve the batch, pick a subset, or decline?
```

**STOP 1** (`read batch`). Time [10:04] → answer at [10:09].
OPERATOR (script: "Step 1 read batch (the live verification batch): approve every command shown."): "Approved, every command." The tier statement in the new-skill entry (`[F1]` "Tier: prod") has no counterpart in the by-meaning list and is not said.

Batch run:
- [10:09] `aws sts get-caller-identity --region ap-southeast-1` → `canned/identity-prod.json` → account `123456789012`, role `arn:aws:sts::123456789012:assumed-role/paymentapi-operator/operator`. Matches the account in the catalog and in `sns_topic_arn` (`envs/prod.tfvars:9`): **match yes**.
- [10:10] `terraform init -input=false` → `canned/terraform-init.txt` → success; the lock file is reused, not changed.
- [10:11] `terraform plan -refresh-only -input=false -var-file=envs/prod.tfvars` → `canned/plan-refresh-only-prod.txt` → `No changes.`
- [10:12] `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod …` → `canned/rds-instance-prod.json` (before state): `db.r6g.large`, `available`, `MultiAZ true`, parameter group `paymentapi-prod-20250617043012345600000001` `in-sync`, `PendingModifiedValues {}`.
- [10:13] `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"` → `canned/rds-parameters-max-connections-before.json` → `100`, `static`, `pending-reboot`.
- [10:14] `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod` → `canned/alarm-connections-before-prod.json` → Threshold 80.0, `OK`, `ActionsEnabled true`.
- [10:15] `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod` → `canned/ecs-describe-services-prod.json` → `ACTIVE`, desired 3, running 3, load balancer `paymentapi-tg-prod`, deployment `PRIMARY` `COMPLETED`.

### Documentation lookups (claims that drive a decision, `SKILL.md:31`)

- [10:16] docs: a static RDS parameter needs a reboot → `canned/docs.md` entry 1 (read 2026-11-09).
- [10:17] docs: what a reboot does on a Multi-AZ instance → `canned/docs.md` entry 2 (read 2026-11-09).
- [10:18] `git status --short` (Step 2 branch check, `SKILL.md:210`) → `canned/git-status-clean.txt` → prints nothing: clean tree. (The `canned/docs.md` entry on `max_connections` being static is not needed: the live ApplyType in E2 and docs entry 1 already carry that claim.)
- [10:19] docs: a CloudWatch alarm threshold update is applied in place → `no canned output`. The alarm item's disruption therefore stays `UNVERIFIED` until the 4a plan shows an in-place update (a disruption that is `UNVERIFIED` may not be presented as `none`, `SKILL.md:200`).
- [10:20] `git rev-parse --short origin/main` → `canned/git-rev-parse.txt` → `a1b2c3d`.

Gaps remaining: last successful apply of this stack (no backend declared, no CI history); the effective runtime value of `max_connections` after the reboot (needs a DB session, not a skill command); alarm-update disruption (docs lookup returned `no canned output`); whether other services connect to the DB.

### Research summary shown to the operator (informational, not a gate)

```text
Change requested: raise max_connections to 200 on paymentapi prod RDS, then reboot so it takes effect
Service: paymentapi / Instance: prod
IaC tool(s): Terraform (hashicorp/aws v5.74.0 per terraform init) · Delivery model: applied by hand from the operator's workstation (operator-stated; no CI/GitOps config in the repo) · Env selection: -var-file=envs/prod.tfvars (code: envs/prod.tfvars)
Target: account 123456789012 / region ap-southeast-1 (from aws sts get-caller-identity, 10:09; region from envs/prod.tfvars:2)
Catalog used: .culiops/service-discovery/paymentapi-prod.md
Duplicate check: not done — code: main.tf:15 still "100"; git: no hit for max_connections; no in-flight branch or PR
Evidence table: E1-E7 all match — drift rows: 0, unverified rows: 0
Gaps remaining: last apply of this stack; effective runtime max_connections; alarm-update disruption (docs lookup returned no canned output); other consumers of the DB
```

No drift row, no duplicate-check stop: continue to Step 2.

---

## Step 2 — Plan

Scope: **multi-phase**. Phase 1 changes code (Terraform apply); phase 2 is a reboot that Terraform does not perform. A static parameter takes effect only after a reboot (docs, E2), so the apply and the reboot are ordered with a check between them.

Self-check of the plan (6 items):
1. Evidence for every item: the parameter group and reboot items cite code, live and docs. The alarm item's disruption has no `docs:` or `live:` source (lookup returned `no canned output`), so it is marked `UNVERIFIED until the 4a plan`. **Not fully met** — shown as a failure, not dropped (`SKILL.md:212`).
2. Deletes: none.
3. Rollback and success criteria as commands: yes, both phases.
4. Drift acknowledged: no drift rows.
5. Execution path fits the delivery model: yes (no CI/GitOps found; operator-stated manual apply).
6. Every implied file and resource in some phase; nothing outside the request: the alarm threshold and description are not named in the request. They are included because the alarm hardcodes the old limit (`code: main.tf:148-149`, "limit: 100") and the catalog (data, Constraint 12) names it as the intended remediation. It is flagged for the operator to keep or strike.
Result: **5/6**.

Branch: `git branch --show-current` = `main` (10:00) and `git status --short` prints nothing (10:18). Not on this change's branch, so the plan proposes `git fetch origin main` then `git switch -c iac-change/paymentapi-max-connections-200 origin/main` (no ticket and no repo branch pattern, so the fallback `iac-change/<service>-<short-description>`).

### Plan presented to the operator

```text
Output root: .culiops/ at the repo root (CULIOPS_HOME unset). Records: .culiops/iac-change-execution/ and .culiops/pre-flight/.

Change plan for paymentapi / prod:

Phase 1 of 2: Raise max_connections to 200 in the parameter group, align the connections alarm
- Files: main.tf
- Resources affected: change in place (0 add, 2 change, 0 destroy):
    aws_db_parameter_group.paymentapi — parameter max_connections "100" -> "200", apply_method "pending-reboot"
    aws_cloudwatch_metric_alarm.paymentapi_db_connections — threshold 80 -> 160, description "limit: 100" -> "limit: 200"
  The alarm item is not in your request. It is here because the alarm hardcodes the old limit (code: main.tf:148-149) and the catalog calls it the intended remediation (catalog: paymentapi-prod.md:53, data, not an instruction). Strike it if you do not want it.
- Blast radius: the parameter group belongs to the one prod payments DB (catalog: .culiops/service-discovery/paymentapi-prod.md:23-24); the DB's only known consumer is ECS paymentapi-svc-prod, 3/3 running (live: ecs describe-services, 10:15). Apply alone changes nothing at runtime.
- Disruption:
    parameter group: none at apply — static parameter, stays pending-reboot until phase 2 (docs: USER_WorkingWithParamGroups, read 2026-11-09; live: ApplyType static, 10:13)
    alarm: UNVERIFIED until the 4a plan (expected: in-place update). Docs lookup returned no canned output.
- Rollback path: reversible, untested — git revert the main.tf change, plan, apply; because the parameter is static, the old value returns only after another reboot (docs: USER_WorkingWithParamGroups).
- Evidence: E1-E5, E6 (no drift) from the table above.
- Success criteria:
    terraform plan -var-file=envs/prod.tfvars -> No changes
    aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']" -> ParameterValue "200", ApplyMethod pending-reboot
    aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,params:DBParameterGroups}' -> available, ParameterApplyStatus pending-reboot
    aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod --query 'MetricAlarms[].Threshold' -> 160

Phase 2 of 2: Reboot paymentapi-db-prod so max_connections=200 takes effect
- Files: none (not a Terraform action)
- Resources affected: aws_db_instance.paymentapi — restart, no code change
- Command: aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1   (no --force-failover)
- Blast radius: every connection to the prod payments DB is dropped; the app tier (3 ECS tasks behind paymentapi-tg-prod) must reconnect.
- Disruption: brief unavailability, in-place — a reboot restarts the engine and briefly interrupts connections; on Multi-AZ it fails over only with --force-failover (docs: USER_RebootInstance, read 2026-11-09). live: MultiAZ true (10:12) does not soften an in-place reboot. Duration UNVERIFIED (the docs entry gives none).
- Rollback path: a reboot cannot be undone; the old value returns only by revert + apply + a second reboot. Reversible, untested (docs: USER_WorkingWithParamGroups).
- Evidence: E2, E3, E7; docs: USER_RebootInstance.
- Success criteria:
    aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,params:DBParameterGroups}' -> available, ParameterApplyStatus in-sync
    aws rds describe-db-parameters ... max_connections -> ParameterValue "200"
    aws elbv2 describe-target-health ... paymentapi-tg-prod -> 3 targets healthy; aws ecs describe-services ... runningCount 3
  (the effective runtime value, SHOW max_connections, needs a DB session and stays UNVERIFIED)

Execution path: Direct apply (you asked for it; no PR). Direct apply escalates the pre-flight assessment (A4: local workstation apply).
Branch: current main -> iac-change/paymentapi-max-connections-200 from origin/main @ a1b2c3d (git fetch origin main, then git switch -c iac-change/paymentapi-max-connections-200 origin/main)
Self-check: 5/6 — item 1 not fully met: the alarm item's disruption has no docs: or live: source yet; the 4a plan confirms it.

Approve this plan?
```

**STOP 2** (`GATE 1`). Time [10:21] → answer at [10:26].
OPERATOR (script: "GATE 1 (the plan): approve. Execution path: direct apply."): "Approved. Direct apply." (The alarm item is kept: the operator approves the plan as presented.)

---

## Step 3 — Implement, Phase 1

- [10:26] `git fetch origin main` → `canned/empty.txt` (no output)
- [10:27] `git switch -c iac-change/paymentapi-max-connections-200 origin/main` → `canned/git-switch.txt` → `Switched to a new branch 'iac-change/paymentapi-max-connections-200'`
- [10:28] `git branch --show-current` → **deviation**: `canned/git-branch.txt` says `main` "always", but the simulated switch has just happened, so I printed `iac-change/paymentapi-max-connections-200` (protocol rule 1, State: follow what already happened). Answering `main` would make the skill's own check at `SKILL.md:250` fail and end the run. Noted.

Code written (shown as a unified diff, applied only inside this transcript):

```diff
--- a/main.tf
+++ b/main.tf
@@ -11,8 +11,9 @@ resource "aws_db_parameter_group" "paymentapi" {
   description = "paymentapi ${var.env} PostgreSQL 15 parameter group"
 
   parameter {
-    name  = "max_connections"
-    value = "100"
+    name         = "max_connections"
+    value        = "200"
+    apply_method = "pending-reboot"
   }
 
   parameter {
@@ -145,8 +146,8 @@ resource "aws_cloudwatch_metric_alarm" "paymentapi_db_connections" {
   namespace           = "AWS/RDS"
   period              = 60
   statistic           = "Average"
-  threshold           = 80
-  alarm_description   = "RDS connections above 80 for paymentapi ${var.env} (limit: 100)"
+  threshold           = 160
+  alarm_description   = "RDS connections above 160 for paymentapi ${var.env} (limit: 200)"
 
   dimensions = {
     DBInstanceIdentifier = aws_db_instance.paymentapi.identifier
```

`apply_method = "pending-reboot"` is required for a static parameter (E2) and is what the canned plan shows.

Formatter (shown before running, `SKILL.md:287`; no approval stop is described for it):
- [10:29] `terraform fmt main.tf` → `canned/empty.txt` → nothing printed, file already formatted.

Diff self-check:
- [10:30] `git status --short` → answered from the diff → ` M main.tf`
- [10:31] `git diff` → answered from the diff above.
1. Scope: only `main.tf`, the one file in the phase list ✅
2. Plan ↔ hunk: parameter group item → hunk 1; alarm item → hunk 2; no extra hunk ✅
3. Conventions: parameter block follows `code: main.tf:19-22` (aligned `name / value / apply_method`); alarm text follows `code: main.tf:148-149` ✅
4. No silent safety change: no `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `ignore_changes`, `0.0.0.0/0`, or IAM `*` touched ✅
5. No secrets: none in the diff; no `tfplan`, state or `.terraform/` in the working-tree changes (`git status --short` shows only `main.tf`) ✅
6. Formatted: `terraform fmt main.tf` printed nothing ✅
Self-check: 6/6.

Fresh eyes: the phase changes a data-store setting (not add-only), so it is not excluded — `fresh-eyes: not run — dry run`.

```text
Code changes for Phase 1 of 2:

Modified: main.tf — max_connections 100 -> 200 with apply_method pending-reboot; connections alarm threshold 80 -> 160 and description updated to the new limit.

Plan <-> hunk: aws_db_parameter_group.paymentapi (max_connections) -> main.tf hunk 1 (lines 14-17); aws_cloudwatch_metric_alarm.paymentapi_db_connections -> main.tf hunk 2 (lines 148-149)
Self-check: 6/6 pass · Fresh eyes: not run — dry run

Full diff is in your working tree (git diff to review).
Approve these changes?
```

**STOP 3** (`GATE 2 (phase 1)`). Time [10:32] → answer at [10:37].
OPERATOR (script: "GATE 2 (the code): approve."): "Approved."

---

## Step 4 — Execute, Phase 1

### 4a — target check and plan

- [10:37] `aws sts get-caller-identity` → `canned/identity-prod.json` → account `123456789012`, role `paymentapi-operator`.

```text
Target check: aws sts get-caller-identity -> account 123456789012, role arn:aws:sts::123456789012:assumed-role/paymentapi-operator/operator · region ap-southeast-1 · Terraform var-file envs/prod.tfvars (workspace not read; no backend block in the code)
Plan is for: prod — match: yes (account matches the catalog and the sns_topic_arn in envs/prod.tfvars)
About to run: terraform plan -out=tfplan -var-file=envs/prod.tfvars (read-only against the cloud, uses the credentials above). terraform init already ran in the Step 1 batch (10:10), so it is not repeated. Proceed?
```

**STOP 4** (`4a target check (phase 1)`). Time [10:38] → answer at [10:43].
OPERATOR (script: "4a target check (`Proceed?`): yes."): "Yes."

- [10:43] `terraform plan -out=tfplan -var-file=envs/prod.tfvars` → `canned/plan-prod.txt`:

```text
Terraform will perform the following actions:
  # aws_cloudwatch_metric_alarm.paymentapi_db_connections will be updated in-place
      ~ alarm_description = "RDS connections above 80 for paymentapi prod (limit: 100)" -> "RDS connections above 160 for paymentapi prod (limit: 200)"
      ~ threshold         = 80 -> 160
  # aws_db_parameter_group.paymentapi will be updated in-place
      - parameter { apply_method = "immediate" -> null, name = "max_connections" -> null, value = "100" -> null }
      + parameter { apply_method = "pending-reboot", name = "max_connections", value = "200" }
Plan: 0 to add, 2 to change, 0 to destroy.
```

Canned plan versus code: matches the diff (same two resources, same values, `pending-reboot`).

Cross-check against the evidence table: both resources are in the approved phase; both actions are `update in-place`, so no replace where the plan said `restart`/`none`. This confirms the alarm item's disruption (`plan: aws_cloudwatch_metric_alarm.paymentapi_db_connections update in-place`) and the parameter group's (`plan: aws_db_parameter_group.paymentapi update in-place`). No unexpected resource, no drift picked up by refresh. `tfplan` stays local (Constraint 11). The plan output is shown to the operator (informational).

### 4b — pre-flight gate

Reuse check: no `.culiops/pre-flight/` directory exists in the fixture, so no record can match.
- [10:44] `terraform show -no-color tfplan` → `canned/plan-prod.txt`
- [10:45] `sha256sum <scratch file holding the plan text>` → INDEX Plan hashes → `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` (scratch file outside the repo, deleted; I also checked the hash against `canned/plan-prod.txt`: equal).

No match: pre-flight is invoked inline with the plan output, the target check, the delivery model (operator-stated manual apply), the evidence table (no drift, no unverified, no `code-only` rows), the plan hash, and the direct-apply flag: "local workstation apply — not going through CI/CD pipeline" (`SKILL.md:330`).

#### Pre-flight (phase 1)

Step 1: assessors loaded (`iac-change`), input is a Terraform plan (`Plan: 0 to add, 2 to change, 0 to destroy.`), matched assessor `iac-change`. Not an unsupported stack. Target: `123456789012 / ap-southeast-1 / var-file envs/prod.tfvars`. Delivery model: manual apply (caller's citation: operator-stated). Plan hash from the caller.

```text
I detected this as a Terraform plan change (assessor: iac-change) affecting 2 resources (aws_db_parameter_group.paymentapi, aws_cloudwatch_metric_alarm.paymentapi_db_connections) in account 123456789012 / ap-southeast-1 / var-file envs/prod.tfvars, delivered by hand from the operator's workstation (operator-stated; flagged: local workstation apply, not CI/CD). Plan hash sha256:779dc062…1619d. Is this correct?
```

**STOP 5** (`pre-flight GATE 1 (phase 1)`). Time [10:46] → answer at [10:51].
OPERATOR (script: "Pre-flight GATE 1 (scope and target): confirm."): "Confirmed."

Step 2 (L1):
- [10:51] `git log --since=7.days --oneline origin/main -- main.tf` → `canned/empty.txt` (row `git log * --since=*`) → no commit in 7 days. No commit of this change exists, so there is nothing to exclude (`git log origin/main..HEAD` not run).
- [10:52] `gh pr list --state open` → `canned/gh-pr-list-empty.txt` → none open that touch the files.
- Uncommitted changes to the same file: only this change's own ` M main.tf` (from `git status --short`, 10:30).
- Automation lag: no CI history and no S3 backend declared in the code, so there is nothing to read. Left for the assessor question below.
- Drift: no "Objects have changed outside of Terraform" block in the plan; refresh-only plan was clean.
- Preliminary scores: 1, 2, 3, 4, 7, 8, 9 (final in Step 5). All changed attributes marked: `max_connections` app-facing (assessor table: "Limits the app must fit inside"), `apply_method` app-facing (part of the same parameter), alarm `threshold` / `alarm_description` not-app-facing only if SNS subscribers are notify-only (to be read in L3).

Step 3 (L2) asks the 7 questions, Q8 (L1 found an app-facing change), and the assessor question that L1 cannot answer. Assessor questions 1-3 are skipped because L1 holds the evidence: the plan was run and shown by the skill (1), the delivery model is the caller's (2), the plan command used `-var-file=envs/prod.tfvars` with no `-target` or `-refresh=false` (3). Question 4 (last successful apply) has no L1 evidence, so it is asked.

```text
Pre-flight context check:
1. Is there an active incident affecting this service or its dependencies? (yes/no)
2. Is there a deploy freeze or change window restriction? (yes/no)
3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure)
4. Have you changed this service before? (many times / a few times / first time)
5. Have you used this IaC tool before? (experienced / some experience / first time)
6. What's the expected cost impact? (negligible / moderate / significant / unknown)
7. Any other context I should know? (free text, optional)
8. This change touches what the app depends on: max_connections (the DB connection limit the app must fit inside). Where is the application source? (a) a local checkout — give the path; (b) a GitHub repo through gh — give owner/repo and the deployed ref; (c) not available.
IaC-specific: has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
```

**STOP 6** (`pre-flight L2 (phase 1)`). Time [10:53] → answer at [10:58].
OPERATOR (script: "Pre-flight L2 questions: Q1=no, Q2=no (the maintenance window is approved and there is no freeze), Q3=no (off-peak window), Q4=many times, Q5=experienced, Q6=negligible, Q7=DBA on the maintenance window and #payments-oncall told about the reboot, Q8=(c) the application source is not available."): "1 no. 2 no — the maintenance window is approved and there is no freeze. 3 no — off-peak window. 4 many times. 5 experienced. 6 negligible. 7 I am the DBA on the maintenance window and #payments-oncall is told about the reboot. 8 (c) the application source is not available."
The script has no answer for the IaC-specific question (last successful apply); the operator says nothing on it (protocol rule 2: "The runner says nothing else"). The skill records it as unanswered → `UNVERIFIED`; it does not re-ask (no text says to). Ambiguity: `pre-flight SKILL.md:265` (assessor questions) vs a script that only covers Q1-Q8.
Recorded: Q1, Q2, Q4, Q5, Q7 = `operator`; Q3, Q6 = `operator-stated`; Q8 (c) → category 11 ⚪. Step 3b (app source scan) does not run.

Step 4 (L3). The target check goes first; commands left out where the caller's evidence table already answers them (describe-db-instances, ECS service, the connections alarm by name).

```text
I can check live system health with read-only queries if you have CLI access. Without it, resource health stays ⚪ and the best possible verdict is YELLOW. Here are the commands I'd run:
 1. aws sts get-caller-identity   (target check: must equal account 123456789012)
 2. aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name DatabaseConnections --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-prod
 3. aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-prod
 4. aws cloudwatch describe-alarms --state-value ALARM
 5. aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod --history-item-type StateUpdate
 6. aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name DatabaseConnections --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-prod --period 300 --statistics Average Maximum (last 1h)
 7. aws cloudwatch get-metric-statistics ... --metric-name CPUUtilization ... (last 1h)
 8. aws cloudwatch get-metric-statistics ... --metric-name FreeableMemory --statistics Minimum (last 1h)
 9. aws cloudwatch get-metric-statistics ... --metric-name FreeStorageSpace --statistics Minimum (last 1h)
10. aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod ARN from the ECS read>
11. aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod (latest 3)
12. aws rds describe-events --source-identifier paymentapi-db-prod --source-type db-instance --duration 1440
13. aws rds describe-pending-maintenance-actions --resource-identifier arn:aws:rds:ap-southeast-1:123456789012:db:paymentapi-db-prod
14. aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --query 'Subscriptions[].Protocol'   (protocols only, never endpoints)
Run them? (yes/no)
```

**STOP 7** (`pre-flight L3 opt-in (phase 1)`). Time [10:58] → answer at [11:03].
OPERATOR (script: "Pre-flight L3 opt-in: yes."): "Yes."

L3 run (each `--region ap-southeast-1`; metric reads use any window per the INDEX; the canned datapoints are timestamped 02:00Z-02:55Z whatever window was asked, used as returned):
- [11:03] #1 `aws sts get-caller-identity` → `canned/identity-prod.json` → account 123456789012 = target ✅
- [11:04] #2 `describe-alarms-for-metric … DatabaseConnections` → `canned/alarms-for-metric-connections-prod.json` → 1 alarm `paymentapi-db-connections-high-prod`, `OK`, ActionsEnabled true, Threshold 80 (the pre-apply state)
- [11:05] #3 `describe-alarms-for-metric … CPUUtilization` → `canned/alarms-for-metric-cpu-prod.json` → `paymentapi-db-cpu-high-prod`, `OK`, ActionsEnabled true, Threshold 80
- [11:06] #4 `describe-alarms --state-value ALARM` → `canned/alarms-firing-prod.json` → none firing
- [11:07] #5 `describe-alarm-history --alarm-name paymentapi-db-connections-high-prod` → `canned/alarm-history-connections-prod.json` → 3 ALARM episodes in the last 5 days: 2026-11-04 12:20Z→12:31Z, 2026-11-06 09:02Z→09:14Z, 2026-11-08 21:39Z→21:47Z; currently OK
- [11:08] #6 `get-metric-statistics … DatabaseConnections` → `canned/metric-rds-connections-prod.json` → average 50-53, maximum 76-78 over 12 five-minute points (02:00Z-02:55Z). Peak 78 of the current limit 100 = 78%
- [11:09] #7 `get-metric-statistics … CPUUtilization` → `canned/metric-rds-cpu-prod.json` → average 31.2-36.8%, maximum 46.8%
- [11:10] #8 `get-metric-statistics … FreeableMemory` → `canned/metric-rds-freeable-memory-prod.json` → average ~6.4 GB, minimum 6.10-6.12 GB
- [11:11] #9 `get-metric-statistics … FreeStorageSpace` → `canned/metric-rds-free-storage-prod.json` → average ~83 GB, minimum ~82 GB (allocated 100 GB, autoscaling to 500 GB)
- [11:12] #10 `describe-target-health` → `canned/tg-health-prod.json` → 3 targets, all `healthy`
- [11:13] #11 `describe-db-snapshots` → `canned/rds-snapshots-prod.json` → 3 automated snapshots, newest `rds:paymentapi-db-prod-2026-11-09-02-05` (2026-11-09 02:05Z, available, encrypted)
- [11:14] #12 `describe-events` → `canned/rds-events-prod.json` → two backup events (02:05Z, 02:11Z); no reboot, failover or maintenance event
- [11:15] #13 `describe-pending-maintenance-actions` → `canned/rds-pending-maintenance-prod.json` → none
- [11:16] #14 `sns list-subscriptions-by-topic` → `canned/sns-subscriptions-prod.json` → protocols `[email, email]` (endpoints not read) → the alarm only notifies, so the alarm change is not-app-facing.

Step 5 (score), Step 5b (verify), Step 6: the scorecard, with the verdict arithmetic and the verification section, is in `preflight-record.md` (Record 1). Verdict: **RED — soft block** (multi-Yellow escalation: Yellow + ⚪ = 7, no individual Red, no hard block). Fresh eyes: `not required (verdict RED — soft block)`.

```text
Pre-flight verdict: RED — SOFT BLOCK (phase 1, plan hash sha256:779dc062…1619d)
 1 Blast radius          YELLOW  2 resources, shared DB component; apply itself causes no restart (static param pending-reboot); direct-apply flag elevates
 2 Reversibility         YELLOW  reversible attributes; rollback = revert + apply + a second reboot (manual, untested)
 3 Change velocity       GREEN   0 commits to main.tf in 7 days; no open PR; only this change's own uncommitted edit
 4 Dependency impact     YELLOW  catalog lists 1 consumer (ECS paymentapi-svc-prod); catalog is a lead, other consumers not provable
 5 Timing context        GREEN   Q1 no, Q2 no, DBA on the window with on-call told; Q3 off-peak (operator-stated), connections avg 50-53 = catalog baseline
 6 Operator familiarity  GREEN   many times / experienced
 7 Observability         YELLOW  two static-threshold alarms, enabled; no SLO, no FreeableMemory alarm
 8 Cost impact           GREEN   0 add, 0 destroy, no size change
 9 Security posture      YELLOW  nothing security-relevant in the plan; elevated because the apply runs from a workstation (caller flag)
10 Resource health       YELLOW  nothing firing, CPU max 46.8%, memory and storage ample, 3/3 targets healthy; connection peak 78 of 100 (78% > 70%); 3 ALARM episodes in 5 days
11 Application compat.   ⚪      max_connections is app-facing; no application source (Q8 = c)
Drift rows: none.
Verification: citations checked 6 (fixed: none) · Verdict working: Red = none; Yellow + ⚪ = 7 (1, 2, 4, 7, 9, 10, 11) ≥ 3 → RED soft block; hard blocks checked (2 irreversible data change: no; 5 incident + freeze: no; 9 public exposure/encryption/secrets: no; 10 error budget: no SLO) → none · Fresh eyes: not required (verdict RED — soft block) · Not verified: Q3 off-peak (operator-stated); last apply of the stack (unanswered); app behaviour on reconnect and pool size vs 200 (no source); effective runtime max_connections after reboot.
Mitigations (operator actions):
 - 1, 2: run phase 2 without --force-failover inside the approved window with #payments-oncall watching; keep the revert path (git revert main.tf, plan, apply, reboot).
 - 4: confirm no other service connects to paymentapi-db-prod.
 - 7: add an alarm on FreeableMemory; after the reboot confirm the new connections alarm leaves INSUFFICIENT_DATA.
 - 9: apply from a session with the least role that permits the change; drop the elevated session after.
 - 10: expected to improve once max_connections is 200; watch DatabaseConnections after the reboot.
 - 11: provide the app source (re-run with Q8 a or b) or confirm by hand that the app pool and reconnect logic fit 200 connections and a restart.
Risk decision: the multi-Yellow escalation is the Red. Acknowledge it with a stated reason, commit to any mitigations, or abort.
```

**STOP 8** (`pre-flight GATE 2 (phase 1)`). Time [11:17] → answer at [11:22].
OPERATOR (script: "Pre-flight GATE 2 (risk decision): acknowledge and proceed." + entry 6 `[H5]` reason): "Acknowledged, proceed. Reason: maintenance window approved, DBA on call, the failover is expected." No mitigation is committed to (the script does not say so).

Step 7: pre-flight record written to `.culiops/pre-flight/paymentapi-max-connections-200-20261109-1122.md` (content in `preflight-record.md`, Record 1). Invoked by another skill: left uncommitted.

#### GATE 3 (phase 1)

```text
Pre-flight clearance (phase 1): verdict RED — soft block, recorded at .culiops/pre-flight/paymentapi-max-connections-200-20261109-1122.md.
Red finding to acknowledge: multi-Yellow escalation (7 categories), acknowledged at the pre-flight risk decision with the reason "maintenance window approved, DBA on call, the failover is expected". Direct-apply flag (local workstation apply) passed to pre-flight and reflected in categories 1 and 9.
Clear for execution, or abort?
```

**STOP 9** (`GATE 3 (phase 1)`). Time [11:22] → answer at [11:27].
OPERATOR (script: "GATE 3 (clearance) and GATE 4 (execution): approve."): "Approved." (Doubled stop: the same acknowledgement was asked for at the pre-flight risk decision, `SKILL.md:324-328`.)

### 4c — Execute (direct apply path)

```text
Before the apply: I can draft a heads-up for the people affected (service owners, on-call) with change-comms (draft-only; you send it). Want it? (yes/no)
```

**STOP 10** (`change-comms heads-up offer (phase 1)`). Time [11:27] → answer at [11:32].
OPERATOR (script: "Optional offers (a change-comms heads-up, …): no."): "No." (Asked per phase: 4c runs once per phase, `SKILL.md:336`; ambiguity whether the offer repeats.)

```text
About to run: terraform apply tfplan
This will: update in place the parameter group paymentapi-prod-20250617043012345600000001 (max_connections 100 -> 200, applied after the reboot) and the alarm paymentapi-db-connections-high-prod (threshold 80 -> 160). Plan: 0 to add, 2 to change, 0 to destroy. No restart.
Target check (re-shown, from 10:37 and the pre-flight target check at 11:03): account 123456789012, role paymentapi-operator, ap-southeast-1, var-file envs/prod.tfvars — plan is for prod, match yes.
Proceed?
```

**STOP 11** (`GATE 4 (phase 1)`). Time [11:32] → answer at [11:37].
OPERATOR (script: "GATE 3 (clearance) and GATE 4 (execution): approve." / "Direct-apply escalation and the per-apply target check: approve."): "Approved."

- [11:37] `terraform apply tfplan` → `canned/apply-prod.txt` →
  ```text
  aws_cloudwatch_metric_alarm.paymentapi_db_connections: Modifications complete after 0s [id=paymentapi-db-connections-high-prod]
  aws_db_parameter_group.paymentapi: Modifications complete after 1s [id=paymentapi-prod-20250617043012345600000001]
  Apply complete! Resources: 0 added, 2 changed, 0 destroyed.
  ```
  Quick apply, no background run needed. State from here: *after phase 1*.

Note: the direct-apply path has no commit step (`SKILL.md:346` commits only on the PR path; Step 3 says commit "happens in Step 4 depending on execution path"). The applied change stays an uncommitted edit of `main.tf` on branch `iac-change/paymentapi-max-connections-200`.

### 5a — Verification, Phase 1

- [11:38] re-plan `terraform plan -out=tfplan -var-file=envs/prod.tfvars` → `canned/plan-after-prod.txt` (state: after phase 1) → `No changes. Your infrastructure matches the configuration.` The re-plan has no separate approval stop in the text (`SKILL.md:386`); the plan command was approved at 4a.

```text
Apply completed. I can run read-only health checks to verify the change is working:
  aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pending:PendingModifiedValues,params:DBParameterGroups}'
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Threshold:Threshold}'
Want me to try? (yes/no)
```

**STOP 12** (`unscripted`). Time [11:39] → answer at [11:44]. The script's optional-offer list names the change-comms heads-up, polling PR checks or sync status, and committing the record; it does not name this health-check offer.
OPERATOR (protocol rule 2: no script entry → "approve / yes / as proposed", logged `unscripted`): "Yes, as proposed."

- [11:44] `aws rds describe-db-instances … --query …` → `canned/rds-instance-pending-reboot-prod.json` (state: after phase 1, before the reboot) → status `available`; `PendingModifiedValues {}`; parameter group `paymentapi-prod-20250617043012345600000001` `pending-reboot`.
- [11:45] `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --query …` → `canned/alarms-prefix-after-prod.json` → both alarms `OK`; connections alarm Threshold 160.0.

Phase 1 success criteria (the plan's commands):
- [11:46] `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"` → `canned/rds-parameters-max-connections-after.json` → `ParameterValue "200"`, `ApplyMethod pending-reboot` → pass
- [11:47] `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod --query 'MetricAlarms[].Threshold'` → `canned/alarm-connections-after-prod.json` → `160.0` → pass
- Re-plan `No changes` → pass (11:38)
- `describe-db-instances` → `available`, `pending-reboot` → pass (11:44)

```text
Verification for Phase 1:
Re-plan: clean (No changes).
Health checks (before -> after): instance status available (10:12) -> available (11:44); parameter group status in-sync -> pending-reboot (expected until the reboot); PendingModifiedValues {} -> {}; connections alarm threshold 80 -> 160, state OK -> OK; CPU alarm OK -> OK.

Phase 1 complete. Success criteria: re-plan No changes — pass; max_connections 200, pending-reboot — pass; instance available, ParameterApplyStatus pending-reboot — pass; alarm threshold 160 — pass.
Ready to proceed to Phase 2: Reboot paymentapi-db-prod so max_connections=200 takes effect?
```

**STOP 13** (`phase gate`). Time [11:48] → answer at [11:53].
OPERATOR (script: "Phase gate (`Ready to proceed to Phase 2?`): yes."): "Yes."

---

## Phase 2 — loops back to Step 3 (`SKILL.md:123`, `SKILL.md:368`)

The text sends phase 2 through the whole pipeline again (Step 3, 4a, 4b, GATE 3, 4c); nothing in it carves out a phase with no file or no plan command. I followed it. Ambiguities noted where it bites.

### Step 3 — Implement, Phase 2

- [11:53] `git branch --show-current` → on the change's branch (state; canned file says `main`, same deviation as at 10:28) → `iac-change/paymentapi-max-connections-200`.
- Files in this phase: none. No code is written, no formatter runs.
- [11:54] `git status --short` → answered from the phase-1 diff, which is still uncommitted (the direct-apply path never commits it) → ` M main.tf`
- [11:55] `git diff` → the same phase-1 diff as above.
Diff self-check: 1. Scope: `main.tf` is changed, but it is not in phase 2's file list (the phase has none). It is phase 1's applied change carried in the working tree; it cannot be "fixed" without a commit the skill does not make on this path. Shown as a failure. 2-6 pass (no new hunk; no safety change; no secrets; nothing to format). Self-check: **5/6**. (Ambiguity: `SKILL.md:258` scope item for a phase with no files.)
Fresh eyes: `fresh-eyes: not run — dry run` (no diff for this phase; the text has no exclusion for a no-diff phase, and the target is a data store).

```text
Code changes for Phase 2 of 2:

Modified: none. Created: none. Deleted: none. (This phase runs a command: aws rds reboot-db-instance …. The working tree still carries phase 1's applied diff in main.tf.)

Plan <-> hunk: reboot of aws_db_instance.paymentapi -> no hunk (no file)
Self-check: 5/6 — item 1 (scope): main.tf is changed but is phase 1's already-applied edit, uncommitted · Fresh eyes: not run — dry run

Full diff is in your working tree (git diff to review).
Approve these changes?
```

**STOP 14** (`GATE 2 (phase 2)`). Time [11:56] → answer at [12:01].
OPERATOR (script: "GATE 2 (the code): approve."): "Approved." (Ambiguity: whether GATE 2 stops when a phase writes no file — `SKILL.md:84` "no shortcuts", `SKILL.md:284`.)

### 4a — target check (phase 2)

- [12:01] `aws sts get-caller-identity` → `canned/identity-prod.json` → account 123456789012.

```text
Target check: aws sts get-caller-identity -> account 123456789012, role paymentapi-operator · region ap-southeast-1 · Terraform var-file envs/prod.tfvars
Plan is for: prod — match: yes
About to run: no plan or diff command exists for aws rds reboot-db-instance (the examples list none), so there is no plan output and no plan hash for this phase. Proceed?
```

**STOP 15** (`4a target check (phase 2)`). Time [12:02] → answer at [12:07].
OPERATOR (script: "4a target check (`Proceed?`): yes." / "per-apply target check: approve."): "Yes." (Ambiguity: `SKILL.md:296-315` assumes a plan command; `examples/aws.md` has no reboot command.)

### 4b — pre-flight gate (phase 2)

Reuse check: the phase-1 record exists (11:22) but its plan hash can only equal the SHA-256 of a current plan/diff text, and this phase has none (`SKILL.md:320`, `SKILL.md:485`). No match → pre-flight inline, input is the CLI command, plan hash `none — record not reusable`. Flags passed: target check, delivery model (operator-stated manual), evidence table (E2, E3, E7 plus the phase-1 results), direct-apply flag.

Step 1: assessor `iac-change` (the reboot is a phase of an IaC change run by this skill; a CLI command is a valid input, `pre-flight SKILL.md:225-228`). Constraint 5 flag: `no plan output reviewed — L1 analysis is partial`.

```text
I detected this as a CLI action (assessor: iac-change) — aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod, no --force-failover — affecting aws_db_instance.paymentapi in account 123456789012 / ap-southeast-1 / var-file envs/prod.tfvars, delivered by hand from the operator's workstation (operator-stated; flagged: local workstation action). No plan hash: a reboot has no plan text, so no plan output reviewed and L1 is partial. Is this correct?
```

**STOP 16** (`pre-flight GATE 1 (phase 2)`). Time [12:07] → answer at [12:12].
OPERATOR (script: "Pre-flight GATE 1 (scope and target): confirm."): "Confirmed."

Step 2 (L1): no changed files in this phase, so there is no `git log` over changed paths. This change has no commit; the working tree still holds phase 1's applied edit (` M main.tf`, `git status --short` at 11:54); no open PR (10:52 read: none; not re-run). The reboot is app-facing (restarts the engine, drops every connection, the new `max_connections` takes effect): category 11 triggered.

Step 3 (L2): the same questions are asked again (L1 holds no evidence that answers them; the earlier answers are not L1 evidence). Assessor question on the last apply is asked again too; its status is unchanged (unanswered).

```text
Pre-flight context check (reboot):
1. Active incident? 2. Deploy freeze or change window restriction? 3. Peak traffic at the expected apply time? 4. Changed this service before? 5. Used this IaC tool before? 6. Expected cost impact? 7. Other context?
8. This action touches what the app depends on: every connection to the DB is dropped and max_connections changes. Where is the application source? (a) local checkout (b) gh owner/repo + deployed ref (c) not available
IaC-specific: has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
```

**STOP 17** (`pre-flight L2 (phase 2)`). Time [12:12] → answer at [12:17].
OPERATOR (script, same by-meaning entry as STOP 6: "give the same L2 answers"): "1 no. 2 no — the maintenance window is approved and there is no freeze. 3 no — off-peak window. 4 many times. 5 experienced. 6 negligible. 7 I am the DBA on the maintenance window and #payments-oncall is told about the reboot. 8 (c) the application source is not available." Nothing on the last-apply question.

Step 4 (L3): the caller's evidence table is stale for the instance (it was read before the phase-1 apply), so `describe-db-instances` is read again.

```text
I can check live system health with read-only queries … Here are the commands I'd run:
 1. aws sts get-caller-identity   (target check)
 2. aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod   (status, Multi-AZ, ParameterApplyStatus, recovery time)
 3. aws cloudwatch describe-alarms --state-value ALARM
 4. aws cloudwatch get-metric-statistics … DatabaseConnections (last 1h)
 5. aws cloudwatch get-metric-statistics … CPUUtilization (last 1h)
 6. aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod>
 7. aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod
 8. aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod
 9. aws rds describe-pending-maintenance-actions --resource-identifier arn:aws:rds:ap-southeast-1:123456789012:db:paymentapi-db-prod
10. aws rds describe-events --source-identifier paymentapi-db-prod --source-type db-instance --duration 1440
Run them? (yes/no)
```

**STOP 18** (`pre-flight L3 opt-in (phase 2)`). Time [12:17] → answer at [12:22].
OPERATOR (script: "Pre-flight L3 opt-in: yes."): "Yes."

- [12:22] #1 `aws sts get-caller-identity` → `canned/identity-prod.json` → account 123456789012 = target ✅
- [12:23] #2 `aws rds describe-db-instances …` → `canned/rds-instance-pending-reboot-prod.json` (after phase 1, before the reboot) → `available`, `MultiAZ true`, `ParameterApplyStatus pending-reboot`, `PubliclyAccessible false`, `StorageEncrypted true`, `LatestRestorableTime 2026-11-09T02:55Z`
- [12:24] #3 `describe-alarms --state-value ALARM` → `canned/alarms-firing-prod.json` → none firing
- [12:25] #4 `get-metric-statistics … DatabaseConnections` → `canned/metric-rds-connections-prod.json` → average 50-53, maximum 76-78 (peak 78% of the current limit 100)
- [12:26] #5 `get-metric-statistics … CPUUtilization` → `canned/metric-rds-cpu-prod.json` → average 31.2-36.8%, max 46.8%
- [12:27] #6 `describe-target-health` → `canned/tg-health-prod.json` → 3/3 `healthy`
- [12:28] #7 `ecs describe-services …` → `canned/ecs-describe-services-prod.json` → 3 desired, 3 running, deployment `PRIMARY` `COMPLETED`; `deploymentCircuitBreaker` disabled
- [12:29] #8 `describe-db-snapshots` → `canned/rds-snapshots-prod.json` → newest automated snapshot 2026-11-09 02:05Z
- [12:30] #9 `describe-pending-maintenance-actions` → `canned/rds-pending-maintenance-prod.json` → none
- [12:31] #10 `describe-events` → `canned/rds-events-prod.json` → backup events only

Step 5/5b/6: scorecard and verification in `preflight-record.md` (Record 2). Verdict: **RED — soft block** (Red: category 1; Yellow + ⚪ = 6; no hard block). Fresh eyes: `not required (verdict RED — soft block)`.

```text
Pre-flight verdict: RED — SOFT BLOCK (phase 2, reboot, plan hash none — record not reusable)
 1 Blast radius          RED     reboot of the only prod payments DB drops every connection; in place (no failover without --force-failover); user-facing data path behind the ALB target group; direct-apply flag elevates
 2 Reversibility         YELLOW  data-safe, but the old value returns only by revert + apply + another reboot (manual, untested); recovery point exists (snapshot 02:05Z, restorable to 02:55Z)
 3 Change velocity       GREEN   0 commits to the repo files; phase 1 applied 11:37 is this change's own
 4 Dependency impact     YELLOW  catalog lists 1 consumer (ECS, 3 tasks); other consumers not provable
 5 Timing context        GREEN   Q1 no, Q2 no, DBA on the window with on-call told; Q3 off-peak (operator-stated)
 6 Operator familiarity  GREEN   many times / experienced
 7 Observability         YELLOW  static-threshold alarms only; a drop to 0 connections does not alarm; no app-error alarm in this repo
 8 Cost impact           GREEN   no resource or size change
 9 Security posture      YELLOW  no security change (PubliclyAccessible false, StorageEncrypted true); elevated by the workstation flag
10 Resource health       YELLOW  nothing firing, CPU max 46.8%, 3/3 targets healthy, ECS 3/3; connection peak 78 of 100 (78%)
11 Application compat.   ⚪      app-facing; no application source (Q8 = c); reconnect behaviour unknown
Verification: citations checked 7 (fixed: none) · Verdict working: Red = 1; Yellow + ⚪ = 6 (2, 4, 7, 9, 10, 11); hard blocks checked: none triggered → RED soft block · Fresh eyes: not required (verdict RED — soft block) · Not verified: Q3 off-peak; reboot duration; app reconnect behaviour; last apply of the stack.
Risk decision: acknowledge the Red (category 1) and the escalation with a stated reason, commit to mitigations, or abort.
```

**STOP 19** (`pre-flight GATE 2 (phase 2)`). Time [12:32] → answer at [12:37].
OPERATOR (script: "Pre-flight GATE 2 (risk decision): acknowledge and proceed." + entry 6 `[H5]` reason): "Acknowledged, proceed. Reason: maintenance window approved, DBA on call, the failover is expected." No mitigation committed.

Pre-flight record written to `.culiops/pre-flight/paymentapi-rds-reboot-20261109-1237.md` (`preflight-record.md`, Record 2); left uncommitted.

```text
Pre-flight clearance (phase 2): verdict RED — soft block, recorded at .culiops/pre-flight/paymentapi-rds-reboot-20261109-1237.md.
Red finding to acknowledge: category 1 (reboot interrupts the prod payments DB) and the multi-Yellow escalation, acknowledged at the pre-flight risk decision with the reason "maintenance window approved, DBA on call, the failover is expected". Direct-apply flag passed to pre-flight.
Clear for execution, or abort?
```

**STOP 20** (`GATE 3 (phase 2)`). Time [12:37] → answer at [12:42].
OPERATOR (script: "GATE 3 (clearance) and GATE 4 (execution): approve."): "Approved."

### 4c — Execute, Phase 2 (direct apply path)

```text
Before the reboot: I can draft a heads-up for the people affected (service owners, on-call) with change-comms (draft-only; you send it). Want it? (yes/no)
```

**STOP 21** (`change-comms heads-up offer (phase 2)`). Time [12:42] → answer at [12:47].
OPERATOR (script: "Optional offers (a change-comms heads-up, …): no."): "No."

```text
About to run: aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1
This will: restart the engine of paymentapi-db-prod in place (no --force-failover), briefly interrupting every connection; the app tier must reconnect. The pending max_connections=200 takes effect when it is back.
Target check (re-shown, from 12:01 and the pre-flight target check at 12:22): account 123456789012, role paymentapi-operator, ap-southeast-1 — plan is for prod, match yes.
Proceed?
```

**STOP 22** (`GATE 4 (phase 2)`). Time [12:47] → answer at [12:52].
OPERATOR (script: "GATE 4 for phase 2 (the reboot command): approve."): "Approved."

- [12:52] `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` → `canned/rds-reboot-prod.json` → `DBInstanceStatus: "rebooting"`. State from here: *rebooting*. The skill monitors the long-running operation and does not interrupt it (`SKILL.md:355`).
- [12:53] `aws rds describe-db-instances … --query 'DBInstances[].DBInstanceStatus'` → first read after the reboot → `canned/rds-instance-rebooting-prod.json` → `rebooting`
- [12:54] same command → `canned/rds-instance-after-reboot-prod.json` → `available`. State from here: *after reboot*.

### 5a — Verification, Phase 2

- [12:55] re-plan `terraform plan -out=tfplan -var-file=envs/prod.tfvars` → `canned/plan-after-prod.txt` → `No changes. Your infrastructure matches the configuration.` (5a says "run the tool's plan command again"; the reboot is not a Terraform action, so "No changes" is the expected result.)

```text
Apply completed. I can run read-only health checks to verify the change is working:
  aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pending:PendingModifiedValues,params:DBParameterGroups}'
  aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}'
  aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod>
  aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --query 'services[].{desired:desiredCount,running:runningCount}'
  aws cloudwatch get-metric-statistics … DatabaseConnections (last 15m)
Want me to try? (yes/no)
```

**STOP 23** (`unscripted`). Time [12:56] → answer at [13:01]. Same reason as STOP 12: the script has no entry for the health-check offer.
OPERATOR (protocol rule 2): "Yes, as proposed."

- [13:01] `aws rds describe-db-instances … --query …` → `canned/rds-instance-after-reboot-prod.json` → `available`, `PendingModifiedValues {}`, `ParameterApplyStatus in-sync`
- [13:02] `aws rds describe-db-parameters … max_connections` → `canned/rds-parameters-max-connections-after.json` → `200`
- [13:03] `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --query …` → `canned/alarms-prefix-after-prod.json` → both alarms `OK`
- [13:04] `aws elbv2 describe-target-health …` → `canned/tg-health-prod.json` → 3/3 `healthy`
- [13:05] `aws ecs describe-services … --query …` → `canned/ecs-describe-services-prod.json` → desired 3, running 3
- [13:06] `aws cloudwatch get-metric-statistics … DatabaseConnections` → `canned/metric-rds-connections-prod.json` → the same file as at 11:08: average 50-53, max 76-78. The canned read does not vary by window, so it carries no post-reboot datapoints: connection recovery after the reboot is **not shown** by this read (`UNVERIFIED`).

Phase 2 success criteria: instance `available`, `ParameterApplyStatus in-sync` — pass (13:01); `max_connections` `"200"` — pass (13:02); 3/3 targets healthy and ECS 3/3 — pass (13:04, 13:05). Effective runtime value (`SHOW max_connections`) not read: `UNVERIFIED`.

```text
Verification for Phase 2:
Re-plan: clean (No changes).
Health checks (before -> after): DBInstanceStatus available (12:23) -> rebooting (12:53) -> available (12:54); ParameterApplyStatus pending-reboot (12:23) -> in-sync (13:01); max_connections 200 -> 200 in the group (13:02); alarms OK -> OK; targets 3/3 healthy -> 3/3 healthy; ECS 3/3 -> 3/3; DatabaseConnections avg 50-53 -> same canned read, not a post-reboot reading.
Success criteria: instance available and in-sync — pass; max_connections 200 — pass; app tier 3/3 healthy — pass.
```

No further phase: Step 5b.

---

## Step 5b — Execution record

Written to `.culiops/iac-change-execution/paymentapi-max-connections-200-20261109-1307.md` (content in `record.md`). The preamble lists the `examples/aws.md` prerequisites (AWS CLI v2; named profile / SSO / assumed role confirmed by `aws sts get-caller-identity`; Tier 1 read-only for Steps 1 and 5, Tier 2 elevated for Step 4; CloudWatch `GetMetric*` cost awareness). The record holds no plan text or `tfplan` content (Constraint 11).

```text
Execution record written to .culiops/iac-change-execution/paymentapi-max-connections-200-20261109-1307.md. Commit it?
```

**STOP 24** (`GATE 5 commit offer`). Time [13:07] → answer at [13:12].
OPERATOR (script: "Optional offers (… committing the record at GATE 5): no."): "No."

```text
I can draft the result message and the ticket-closing comment (there is no PR URL on this path) with change-comms (draft-only; you send them). Want them? (yes/no)
```

**STOP 25** (`change-comms result offer`). Time [13:12] → answer at [13:17].
OPERATOR (script: "Optional offers (a change-comms heads-up, …): no." — I read this as covering any change-comms offer): "No."

Run ends at [13:17] with the skill's final message: record path, outcome `completed (2 of 2 phases)`, `Applied: yes — verified`.

---

## Notes for the reader

- **Stops: 25** (2 `unscripted`: the two health-check offers). Phase 1 has 12 (STOPS 1-12), the phase gate is 1 (STOP 13), phase 2 has 10 (STOPS 14-23: GATE 2, 4a target check, four pre-flight stops, GATE 3, heads-up offer, GATE 4, health-check offer), and the GATE 5 offers are 2 (STOPS 24-25).
- **Ambiguities taken, with the line relied on:** phase 2 runs every gate again (`SKILL.md:84`, `123`, `368`); pre-flight is not reusable for the reboot because there is no plan hash (`SKILL.md:320`, `485`); GATE 2 and 4a still stop for a phase with no file and no plan command (`SKILL.md:284`, `296-315`); the heads-up offer repeats at each 4c (`SKILL.md:336`); the GATE 5 commit offer and the result-message offer are two prompts (`SKILL.md:442-445`); output root shown at GATE 1 (`SKILL.md:35`); delivery model taken from the first message instead of asking (`SKILL.md:156`); duplicate-check `gh pr list` run without a stop (`SKILL.md:145`); assessor question on the last apply went unanswered (`pre-flight SKILL.md:265`).
- **Doubled stops the text forces:** pre-flight GATE 2 and iac GATE 3 both ask for the acknowledgement of the same RED soft block (`SKILL.md:324-328`, `pre-flight SKILL.md:327-330`).
- **`no canned output`:** one lookup — the `docs:` claim that an alarm threshold update is applied in place (10:19). Deviation: `git branch --show-current` after the simulated `git switch -c` returns the new branch name instead of the canned `main` (10:28, 11:53).
- **Clock:** the canned post-apply alarm files carry `AlarmConfigurationUpdatedTimestamp 2026-11-09T03:21:40Z` (10:21 +07). The dry-run clock reaches the apply at 11:37, so that timestamp is earlier than the apply it describes. Not reconciled; the fixture timing seems to assume a shorter flow.
