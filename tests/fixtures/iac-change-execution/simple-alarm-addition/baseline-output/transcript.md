# Dry-run transcript: simple-alarm-addition, baseline (old v0.17.0 skill)

- Skill text: `git show origin/main:` for `skills/iac-change-execution/SKILL.md`, `skills/iac-change-execution/examples/aws.md`, `skills/pre-flight/SKILL.md`, `skills/pre-flight/assessors/iac-change.md`, `skills/pre-flight/assessors/README.md`, `skills/pre-flight/examples/aws.md`. Line references below are lines of those files as read from `origin/main`. `SKILL.md:<n>` is `iac-change-execution`; `pre-flight SKILL.md:<n>` is pre-flight.
- Dry-run clock: starts 2026-11-09 10:00 +07:00. One minute per command (`git grep` counted as a command), five minutes per operator answer.
- Environment rule (protocol rule 1b): the fixture has one env file, `envs/prod.tfvars`, so every read and plan is for prod. For reads that carry no environment in the command (`aws sts get-caller-identity`, `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi`) the environment taken is prod, the one the skill is working on.
- Operator answers come from `operator-script.md`, "Answers by meaning" (old skill, no stop IDs).
- No `.culiops/` records exist in the fixture (no service-discovery catalog, no earlier pre-flight record). No CI config, no `Application` objects, no Atlantis/Spacelift files in the fixture.
- Fresh eyes: not run — dry run (iac-change-execution Step 3 skipped by its own rule, see Step 3; pre-flight Step 5b required it for a GREEN verdict).

## Ambiguities hit in the skill text (reading taken, line relied on)

1. Delivery model question: the text says "ask the operator" when nothing in the repo shows it (`SKILL.md:156`). Taken as its own stop, before the read batch (`SKILL.md:153-156` come before `SKILL.md:165`).
2. Read batch contents: "from `examples/aws.md` ... plus the tool's own drift check" (`SKILL.md:165`). Composed from `examples/aws.md` (ECS service state, alarm states by prefix, CPU utilization from the post-apply health list, used as the before-value) plus `aws sts get-caller-identity` (the research summary needs "Target ... from `<command>`", `SKILL.md:176`) plus `terraform init` (the refresh-only plan cannot run without it) plus `terraform plan -refresh-only`. `examples/aws.md` has no SNS read, so the SNS topic's live state is listed as a gap (`SKILL.md:167`).
3. Output root "shown to the operator at the first gate" (`SKILL.md:35`): taken as GATE 1 (the plan), and as pre-flight GATE 1 for pre-flight (pre-flight `SKILL.md:42`). `CULIOPS_HOME` is not set in the dry run, so the root is `.culiops/` at the repo root.
4. `git branch --show-current` after the simulated `git switch -c`: `canned/INDEX.md` says "always (the repo is on main)", but the skill requires the change's branch to be checked out before writing (`SKILL.md:250`). Used the state after the switch (the new branch name), the way `git-switch.txt`, `git-commit.txt` and `git-push.txt` are filled in. The literal canned `main` would trip the Red Flag at `SKILL.md:64` and no run could continue.
5. Formatter "shown before running" (`SKILL.md:287`): taken as shown, not a stop. Constraint 3 (`SKILL.md:25`) lists only live queries and apply commands as needing approval.
6. `terraform init` in 4a "if needed" (`SKILL.md:307`): not re-run, it already ran in the Step 1 batch and nothing changed (canned output says the lock file was reused).
7. Fresh eyes in Step 3: skipped by the skill's own rule (`SKILL.md:268`: add-only, touches no access control, network, DNS, data store, secrets or lifecycle settings, and an alarm is the named example). Nothing is dispatched, so the record says "skipped", not "not run — dry run".
8. GATE 3 on a GREEN verdict (`SKILL.md:324-325`: "Green/Yellow: Proceed."): taken as a stop. The gate has an "abort / modify" edge (`SKILL.md:117-118`) and an abort rule (`SKILL.md:328`), and every other GATE is an operator decision. The operator already acknowledged the same verdict at pre-flight GATE 2, so the same GREEN verdict is asked twice.
9. "`git status` after staging" appears in the text shown before GATE 4 (`SKILL.md:342`), while staging is listed after GATE 4 (`SKILL.md:346`). Taken as: stage `main.tf` by explicit path first (local, nothing committed or pushed), show the status, then ask.
10. PR "will include ... execution record link" (`SKILL.md:343`): the record is written in 5b, after the PR exists. The PR body names the record path the skill will write and says the record is not committed yet.
11. Pre-flight category 11 at L1: the alarm's action is an SNS topic whose subscription protocols have not been read, and the assessor says unchecked protocols mean app-facing (assessor `iac-change.md:215`; pre-flight `SKILL.md:68`, `SKILL.md:257`). So L1 marks the alarm app-facing and L2 asks Q8 (pre-flight `SKILL.md:106`). L3 later reads the protocols, shows notify-only, and category 11 is Green anyway.
12. Pre-flight assessor L2 questions (`iac-change.md:244-249`): asked after the standard seven in the same message. Questions 1 to 3 are answered by L1 evidence (the plan hash and plan command the caller passed, the caller's delivery model), so skipped per pre-flight `SKILL.md:104` and `SKILL.md:263`. Question 4 (applied recently?) has no L1 evidence, so it is asked.
13. Pre-flight target record (pre-flight `SKILL.md:238`): the repo has no `backend` block, so the backend key is unknown. "Asked, not guessed" is folded into the pre-flight GATE 1 confirmation, not a separate stop.
14. 5a (`SKILL.md:382`): "once the apply has landed, offer to run the phase success criteria" is conditional on a merge that never happens in this run, so that second offer is not made.
15. The two closing offers (`SKILL.md:442-445`): commit the record (GATE 5) and the `change-comms` result / ticket-closing draft are separate offers, so two stops. The script's "Optional offers ... no" covers both by meaning.
16. Header comment of `main.tf` (lines 1-4) says the CPU alarm "is intentionally absent". It is code-comment text (data, `SKILL.md:34`) and outside the approved file edit, so it is left unchanged and is stale after the change.

---

## Step 1 — Research

**Operator first message:** "Add a CloudWatch CPU utilization alarm for paymentapi in prod."

Skill detects the stack: Terraform on AWS (`main.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`). Supported. Output root: `CULIOPS_HOME` unset, so `.culiops/` at the repo root.

Catalog: `.culiops/service-discovery/paymentapi.md` does not exist. Skill notes "consider running service-discovery first for a more complete picture" and proceeds.

IaC code read (working tree, current branch is `main`): `main.tf` (181 lines), `variables.tf`, `outputs.tf`, `envs/prod.tfvars`. Ticket: none.

### Duplicate check (all local, read-only)

Identifiers from the request: alarm name form `paymentapi-cpu-high`, resource type `aws_cloudwatch_metric_alarm`, metric `CPUUtilization`. No ticket key, so no `--grep`.

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| 1 | 10:01 | `git branch --show-current` | `git-branch.txt` | `main` |
| 2 | 10:02 | `git grep -n -F 'paymentapi-cpu-high'` | (grep over input files) | no hits |
| 3 | 10:03 | `git grep -n -F 'aws_cloudwatch_metric_alarm'` | (grep over input files) | no hits |
| 4 | 10:04 | `git grep -n -F 'CPUUtilization'` | (grep over input files) | no hits |
| 5 | 10:05 | `git log --all --oneline -S'paymentapi-cpu-high'` | `empty.txt` | (none) |
| 6 | 10:06 | `git log --all --oneline -S'aws_cloudwatch_metric_alarm'` | `empty.txt` | (none) |
| 7 | 10:07 | `git branch -a --list '*cpu*'` | `empty.txt` | (none) |
| 8 | 10:08 | `gh pr list --state open --search 'cpu alarm'` | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

Verdict: **not done**. `code:` no alarm of any kind in the repo, every environment; `git:` no commit ever added or removed these identifiers; no in-flight branch or PR.

### Delivery model and environment selection

- Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1` sets `env = "prod"`, the only env file in `envs/`).
- Delivery model: no CI config, `Application` / `Kustomization` object, Atlantis or Spacelift file, or backend block in the repo. It is `UNVERIFIED`.

**Skill message to the operator (STOP 1):**

> I could not find how changes reach prod after merge: no CI config, GitOps object, Atlantis / Terraform Cloud / Spacelift config, or Makefile in this repo. The delivery model is UNVERIFIED. How do changes get applied after merge: CI applies on merge, GitOps controller, PR-driven plan/apply automation, or applied by hand?

**Operator (script: "Delivery-model question (UNVERIFIED in the repo)")** [clock 10:13]: "A CI pipeline applies on merge."

Recorded as `operator-stated`. CI-applies-on-merge means PR path only.

### Live verification batch

Evidence table (draft, before live reads) and gaps built from the code. Skill proposes the batch.

**Skill message to the operator (STOP 2):**

> **Live verification batch** (read-only; approve the batch, pick a subset, or decline). Target for all: account `123456789012`, region `ap-southeast-1`, var-file `envs/prod.tfvars`.
> 1. `aws sts get-caller-identity`
> 2. `terraform init` (downloads nothing new if the lock file is satisfied; it may update `.terraform.lock.hcl`; needed before step 3)
> 3. `terraform plan -refresh-only -var-file=envs/prod.tfvars` (drift check, never applied)
> 4. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{name:serviceName,cluster:clusterArn,status:status,desired:desiredCount,running:runningCount}'`
> 5. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}'`
> 6. `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --start-time <T-1h> --end-time <now> --period 300 --statistics Average Maximum --region ap-southeast-1` (before-value for the alarm threshold and for Step 5)
>
> Approve all six?

**Operator (script: "Step 1 read batch: approve every command shown")** [clock 10:18]: "Approve all."

| # | Time | Command | Canned file | Result |
|---|---|---|---|---|
| B1 | 10:19 | `aws sts get-caller-identity` | `identity-prod.json` | account `123456789012`, role `arn:aws:sts::123456789012:assumed-role/paymentapi-operator/operator` |
| B2 | 10:20 | `terraform init` | `terraform-init.txt` | initialized, lock file reused, aws provider v5.74.0 |
| B3 | 10:21 | `terraform plan -refresh-only -var-file=envs/prod.tfvars` | `plan-refresh-only-prod.txt` | `No changes.` no drift |
| B4 | 10:22 | `aws ecs describe-services ... --query ...` | `ecs-describe-services-prod.json` (query applied) | `[{name: paymentapi-svc-prod, cluster: .../cluster/paymentapi-cluster-prod, status: ACTIVE, desired: 3, running: 3}]` |
| B5 | 10:23 | `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi ...` | `alarms-prefix-prod.json` (before the alarm exists) | `[]` no alarm on the service |
| B6 | 10:24 | `aws cloudwatch get-metric-statistics ... CPUUtilization ...` | `metric-cpu-prod.json` | 12 points, Average 34.8 to 41.2, Maximum up to 51.2 |

### Evidence table

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| ECS cluster name | `code: main.tf:9` `paymentapi-cluster-${var.env}`, `envs/prod.tfvars:1` env = prod, so `paymentapi-cluster-prod` | `live: B4` clusterArn ends `cluster/paymentapi-cluster-prod` (10:22) | ok |
| ECS service name and state | `code: main.tf:72` `paymentapi-svc-${var.env}` | `live: B4` `paymentapi-svc-prod` ACTIVE, 3 of 3 running (10:22) | ok |
| SNS alert topic | `code: main.tf:175` `paymentapi-alerts-${var.env}` | not read (no SNS read in `examples/aws.md`) | UNVERIFIED live |
| Existing CPU alarm on the service | `code: none` | `live: B5` no alarm with prefix `paymentapi` (10:23) | ok (absent in both) |
| Drift on the stack | n/a | `live: B3` refresh-only plan `No changes` (10:21) | no drift |
| Service CPU before the change | n/a | `live: B6` Average 34.8 to 41.2, Maximum up to 51.2 over the last hour (10:24) | baseline for the threshold |

Drift rows: 0. Unverified rows: 1 (SNS topic live state; resolving command `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --query 'Subscriptions[].Protocol'`).

### Research summary (informational, not a gate)

> **Change requested:** Add a CloudWatch CPU utilization alarm for paymentapi in prod
> **Service:** `paymentapi` / **Instance:** `prod`
> **IaC tool(s):** Terraform (AWS provider) · **Delivery model:** CI applies on merge (`operator-stated`) · **Env selection:** `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1`)
> **Target:** account `123456789012` / region `ap-southeast-1` (from `aws sts get-caller-identity`, region from `envs/prod.tfvars:2`)
> **Catalog used:** none — proceeding without catalog (consider running service-discovery first for a more complete picture)
> **Duplicate check:** not done — `code:` no hit for the alarm name, resource type or metric in any file; `git:` `-S` finds no commit; no in-flight branch or PR
> **Evidence table:** (above) — drift rows: 0, unverified rows: 1
> **Gaps remaining:** SNS topic `paymentapi-alerts-prod` live state and subscribers (UNVERIFIED)

No drift row, so nothing to acknowledge. Skill continues to Step 2.

---

## Step 2 — Plan

Scope: single phase (adding an alarm is the text's own single-phase example, `SKILL.md:191`).

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| P1 | 10:25 | `git branch --show-current` | `git-branch.txt` | `main` |
| P2 | 10:26 | `git status --short` | `git-status-clean.txt` | (prints nothing, tree clean) |
| P3 | 10:27 | `git branch -a` | `git-branches.txt` | `* main`, `remotes/origin/HEAD -> origin/main`, `remotes/origin/main` (default branch is `main`) |
| P4 | 10:28 | `git rev-parse --short origin/main` | `git-rev-parse.txt` | `a1b2c3d` |

Branch is not this change's own branch, so the plan proposes `git fetch origin main` then `git switch -c iac-change/paymentapi-cpu-high-alarm origin/main` (no ticket and no branch pattern in `git branch -a`, so the fallback name `iac-change/<service>-<short-description>`).

Execution path: CI-applies-on-merge, so the PR path only is offered (`SKILL.md:208`).

Plan self-check: 6 of 6 pass (item 4 holds because there are no drift rows; item 1 holds because the only UNVERIFIED row is not a destroy, replace or resize).

**Skill message to the operator (STOP 3, GATE 1):**

> **Change plan for `paymentapi` / `prod`:**
>
> **Phase 1 of 1: Add CPU utilization alarm for `paymentapi-svc-prod`**
> - Files: `main.tf` (modify: new section "CloudWatch alarm (CPU)" at the end, after the SNS topic, as the repo keeps one section per resource group)
> - Resources affected: add 1: `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (name `paymentapi-cpu-high-${var.env}`, namespace `AWS/ECS`, metric `CPUUtilization`, dimensions `ClusterName` and `ServiceName` from the existing cluster and service resources, `Average` greater than 80 for 3 periods of 300 s, `treat_missing_data = "missing"`, alarm and OK actions to the existing SNS topic `paymentapi_alerts`, repo tags `Service` and `Environment`). The threshold, period count and statistic are my proposal: the request does not give them. Live CPU over the last hour is Average 34.8 to 41.2 and Maximum up to 51.2 (`live: B6`), so 80 sits well above the baseline. Tell me if you want other values.
> - Blast radius: one new resource. No existing resource is edited. It reads the cluster name, service name and topic ARN by reference (`code: main.tf:9`, `main.tf:72`, `main.tf:175`).
> - Disruption: none — `code:` add-only, no existing resource changes; Step 4a will confirm with `plan:` (expect 1 to add, 0 to change, 0 to destroy)
> - Rollback path: reversible. Revert the PR, then plan and apply the revert through the same path; this deletes only the alarm and its state history. Untested.
> - Evidence: rows ECS cluster name, ECS service name and state, existing CPU alarm (absent), drift (none), CPU baseline. SNS topic live state is UNVERIFIED (not a destroy, replace or resize).
> - Success criteria:
>   1. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{n:AlarmName,s:StateValue,a:ActionsEnabled}'` → one alarm, `n = paymentapi-cpu-high-prod`, `a = true`, `s` is `OK` or `INSUFFICIENT_DATA`
>   2. `terraform plan -var-file=envs/prod.tfvars` → `No changes.`
>
> **Execution path:** PR (default). After merge it is applied by the CI pipeline (`operator-stated`). Direct apply is not offered because CI applies on merge.
> **Branch:** current `main` → `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d` (fetch + create)
> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` is unset)
> **Self-check:** 6/6 pass
>
> **Approve this plan?**

**Operator (script: "GATE 1 (the plan): approve. Execution path: PR.")** [clock 10:33]: "Approve. PR."

---

## Step 3 — Implement

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| I1 | 10:34 | `git fetch origin main` | `empty.txt` | (none) |
| I2 | 10:35 | `git switch -c iac-change/paymentapi-cpu-high-alarm origin/main` | `git-switch.txt` | `Switched to a new branch 'iac-change/paymentapi-cpu-high-alarm'` |
| I3 | 10:36 | `git branch --show-current` | `git-branch.txt` (state follows the switch, see ambiguity 4) | `iac-change/paymentapi-cpu-high-alarm` |

Conventions read from adjacent code: section header comment line, one blank line, resource, `paymentapi_<role>` resource labels (`code: main.tf:174` `paymentapi_alerts`), `${var.env}` in names (`code: main.tf:72`), the `tags` block with `Service` and `Environment` (`code: main.tf:177-180`), `jsonencode`-free HCL with aligned `=`.

Code written to `main.tf` (appended after line 181):

```diff
--- a/main.tf
+++ b/main.tf
@@ -179,3 +179,31 @@
     Environment = var.env
   }
 }
+
+# ── CloudWatch alarm (CPU) ────────────────────────────────────────────────────
+
+resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_high" {
+  alarm_name          = "paymentapi-cpu-high-${var.env}"
+  alarm_description   = "CPU utilization above 80% for paymentapi ${var.env}"
+  namespace           = "AWS/ECS"
+  metric_name         = "CPUUtilization"
+  statistic           = "Average"
+  period              = 300
+  evaluation_periods  = 3
+  threshold           = 80
+  comparison_operator = "GreaterThanThreshold"
+  treat_missing_data  = "missing"
+
+  dimensions = {
+    ClusterName = aws_ecs_cluster.paymentapi.name
+    ServiceName = aws_ecs_service.paymentapi.name
+  }
+
+  alarm_actions = [aws_sns_topic.paymentapi_alerts.arn]
+  ok_actions    = [aws_sns_topic.paymentapi_alerts.arn]
+
+  tags = {
+    Service     = "paymentapi"
+    Environment = var.env
+  }
+}
```

Skill shows the formatter before running it (`terraform fmt main.tf`, local, changed file only).

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| I4 | 10:37 | `terraform fmt main.tf` | `empty.txt` | (nothing printed: already formatted) |
| I5 | 10:38 | `git status --short` | answered from the diff | ` M main.tf` |
| I6 | 10:39 | `git diff` | answered from the diff | the diff above |

Diff self-check (6 of 6): (1) scope: only `main.tf`, which is the one file in the plan; (2) plan to hunk: the one added resource maps to the one hunk; (3) conventions: names and tags follow `code: main.tf:174-180` (SNS topic) and `main.tf:72`; (4) no silent safety changes: none of `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `force_destroy`, `ignore_changes`, `0.0.0.0/0` or `*` in IAM appears; (5) no secrets, no `tfplan` / state / `.terraform/` in the working-tree changes shown by `git status --short`; (6) formatter ran clean.

Fresh eyes: skipped — add-only, no sensitive types (alarm add, `SKILL.md:268`). Nothing dispatched.

Note: the stale header comment in `main.tf` lines 1-4 is left alone (ambiguity 16).

**Skill message to the operator (STOP 4, GATE 2):**

> **Code changes for Phase 1 of 1:**
>
> **Modified:** `main.tf` — new "CloudWatch alarm (CPU)" section with `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (+28 lines, 0 removed)
>
> **Plan ↔ hunk:** add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` → `main.tf` hunk `@@ -179,3 +179,31 @@`
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped — add-only, no sensitive types
>
> Full diff is in your working tree (`git diff` to review).
> **Approve these changes?**

**Operator (script: "GATE 2 (the code): approve.")** [clock 10:44]: "Approve."

---

## Step 4a — Generate plan output

Skill runs the target check command (read-only, same command as batch item 1).

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| T1 | 10:45 | `aws sts get-caller-identity` | `identity-prod.json` | account `123456789012`, role `arn:aws:sts::123456789012:assumed-role/paymentapi-operator/operator` |

The plan's target is the account named by the role ARNs and ECR repo in `envs/prod.tfvars` (123456789012) and region `ap-southeast-1` (`envs/prod.tfvars:2`): match yes. Mode (1): the skill runs the plan (Step 1 recorded no "never run Terraform").

**Skill message to the operator (STOP 5):**

> **Target check:** `aws sts get-caller-identity` → account `123456789012`, role `arn:aws:sts::123456789012:assumed-role/paymentapi-operator/operator` · region `ap-southeast-1` · Terraform var-file `envs/prod.tfvars`
> **Plan is for:** prod — **match: yes**
> About to run: `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above; `terraform init` already ran in the Step 1 batch and changed nothing). **Proceed?**

**Operator (script: "4a target check (Proceed?): yes")** [clock 10:50]: "Yes."

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| T2 | 10:51 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | `plan-prod.txt` (before any apply) | `Plan: 1 to add, 0 to change, 0 to destroy.` (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high will be created`) |

**Canned plan versus code:** the plan carries `alarm_name = "paymentapi-cpu-high-prod"`, `alarm_description = "CPU utilization above 80% for paymentapi prod"`, namespace `AWS/ECS`, metric `CPUUtilization`, `Average`, period 300, 3 evaluation periods, threshold 80, `GreaterThanThreshold`, `treat_missing_data = "missing"`, dimensions `paymentapi-cluster-prod` and `paymentapi-svc-prod`, alarm and OK actions to `arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod`, tags `Service` and `Environment`. Every attribute matches what the code above produces. No difference.

Cross-check against the evidence table: the plan touches one resource, it is in the approved phase, and its action (create) matches disruption `none`. Nothing unexpected. `tfplan` stays local.

Skill shows the plan output to the operator (informational, no stop): the plan text above.

---

## Step 4b — Pre-flight gate

Plan hash for the match rule: the skill shows the plan text it will hash, then hashes it.

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| T3 | 10:52 | `terraform show -no-color tfplan > <scratch file outside the repo>` | `plan-prod.txt` | (written to the scratch file) |
| T4 | 10:53 | `sha256sum <scratch file>` | `INDEX.md` Plan hashes | `30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` |
| T5 | 10:54 | `rm <scratch file>` | (none needed) | (none) |

Reusable record check in `.culiops/pre-flight/`: the directory does not exist. No match, so pre-flight is invoked inline with: the plan output, the target check, the delivery model (CI applies on merge, `operator-stated`), the evidence table (one UNVERIFIED row, no drift rows, no `code-only` rows) and the plan hash `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89`.

### Pre-flight Step 1 — detect

- Input: Terraform plan text (`Plan:` summary line). Unsupported-stack check: not CloudFormation, Serverless, CDK, Pulumi, Bicep, GCP or Azure.
- Assessors loaded: `README.md` (template, not an assessor) and `iac-change.md`. `iac-change` matches (Terraform plan).
- Target: AWS account `123456789012`, region `ap-southeast-1`, var-file `envs/prod.tfvars`, default workspace, no backend block in the repo (backend key unknown).
- Delivery model: CI applies on merge (kept from the caller, `operator-stated`).
- Plan hash: passed by the caller, `sha256:30f4...0a89`, source `terraform show -no-color tfplan`.

**Skill message to the operator (STOP 6, pre-flight GATE 1):**

> I detected this as a **Terraform IaC change** adding **1 resource** (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`) in **account 123456789012 / ap-southeast-1, var-file `envs/prod.tfvars`**, delivered by **CI after merge** (operator-stated). Assessor: `iac-change`. Plan hash `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89`. I found no Terraform backend block, so I recorded the default workspace and no backend key; tell me if that is wrong. Output root: `.culiops/` at the repo root. Is this correct?

**Operator (script: "Pre-flight GATE 1 (scope and target): confirm.")** [clock 10:59]: "Confirm."

### Pre-flight Step 2 — L1 static analysis

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| F1 | 11:00 | `git log --since=7.days --oneline origin/main -- main.tf` | `empty.txt` | (none: no commit to the changed path in the last 7 days; the last three commits in the repo, `c4d8e21`, `9a07b3f`, `5e1c0d8`, are all older than 30 days) |
| F2 | 11:01 | `gh pr list --state open` | `gh-pr-list-empty.txt` | no open PRs |
| F3 | 11:02 | `git status` | answered from the diff | `On branch iac-change/paymentapi-cpu-high-alarm`, `Changes not staged for commit: modified: main.tf` (this change's own edit) |
| F4 | 11:03 | `git rev-parse --short HEAD` | `git-rev-parse.txt` | `a1b2c3d` |

Preliminary scores: 1 blast radius Green (`plan: Plan: 1 to add`, single region, addition only); 2 reversibility Green (pure addition, no in-place attribute change, rollback = revert, plan, apply); 3 change velocity Green so far (0 commits in 7 days, no open PR; the only uncommitted change is this change's own); 4 dependency impact: no catalog, so ⚪ unless every changed resource is not-app-facing; 7 observability: add-only monitoring; 8 cost: alarm add, price still to look up; 9 security Green (`plan:` no IAM, network, encryption or public-access change). Drift rows: none.

Application compatibility: the changed resource is an alarm. An alarm is not-app-facing only if its actions only notify. Its action is an SNS topic and the subscription protocols have not been read, so by the assessor (`iac-change.md:215`) it is treated as app-facing for now: category 11 is triggered and needs Q8. Categories 5, 6 and 10 stay pending.

### Pre-flight Step 3 — L2

**Skill message to the operator (STOP 7):**

> **Pre-flight context check:**
> 1. Is there an active incident affecting this service or its dependencies? (yes/no)
> 2. Is there a deploy freeze or change window restriction? (yes/no)
> 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure — with CI delivery the apply happens at merge, not now)
> 4. Have you changed this service before? (many times / a few times / first time)
> 5. Have you used this IaC tool before? (experienced / some experience / first time)
> 6. What's the expected cost impact? (negligible / moderate / significant / unknown)
> 7. Any other context I should know? (free text, optional)
> 8. This change touches what the app may depend on: the alarm's SNS action (its subscribers are not checked yet). Where is the application source? (a) a local checkout, give the path; (b) a GitHub repo through `gh`, give `owner/repo` and the deployed ref; (c) not available.
>
> IaC-specific: 9. Has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
> (Skipped, answered by L1 evidence: whether the plan was run and reviewed, how the change is delivered, and whether the plan used `-target` / `-refresh=false` / a non-default workspace.)

**Operator (script: "Pre-flight L2 questions: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none.")** [clock 11:08]:
- Q1 no, Q2 no, Q3 no, Q4 many times, Q5 experienced, Q6 negligible, Q7 none (all from the script entry).
- Q8: **unscripted**. The script has no entry. Default rule applied: answered "(c) not available" (the only option that does not invent a path or repo).
- IaC question 9 (applied recently): **unscripted**. Default rule applied: "recent".

Tagging: Q1, Q2, Q4, Q5 `operator`; Q3, Q6 and the "recent" answer `operator-stated`.

Category 5 and 6 filled: timing (no incident, no freeze, not peak, pending the live request-rate check); familiarity Green (many times, experienced). Q6 recorded as `operator-stated` input to category 8. Step 3b (app source scan) is not run: Q8 is (c), so category 11 would be ⚪ unless L3 settles it.

### Pre-flight Step 4 — L3

**Skill message to the operator (STOP 8):**

> I can check live system health with read-only queries. Without it, resource health stays ⚪ and the best verdict is YELLOW. Commands I'd run (target check first; I left out what the evidence table already answers: ECS state, existing alarms, CPU, drift):
> 1. `aws sts get-caller-identity` (target check)
> 2. `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --region ap-southeast-1 --query 'Subscriptions[].Protocol'` (protocols only, never endpoints)
> 3. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].deployments[].{status:status,rollout:rolloutState,taskDef:taskDefinition,created:createdAt}'`
> 4. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].events[:10].{at:createdAt,msg:message}'`
> 5. `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --start-time <T-1h> --end-time <now> --period 300 --statistics Average Maximum --region ap-southeast-1`
> 6. `aws elbv2 describe-target-groups --names paymentapi-tg-prod --region ap-southeast-1`
> 7. `aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 --region ap-southeast-1`
> 8. `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count --dimensions Name=LoadBalancer,Value=app/paymentapi-alb-prod/50dc6c495c0c9188 --start-time <T-1h> --end-time <now> --period 300 --statistics Sum --region ap-southeast-1`
> 9. `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime --dimensions Name=LoadBalancer,Value=app/paymentapi-alb-prod/50dc6c495c0c9188 --start-time <T-1h> --end-time <now> --period 300 --statistics Average --region ap-southeast-1`
> 10. `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name RequestCount --dimensions Name=LoadBalancer,Value=app/paymentapi-alb-prod/50dc6c495c0c9188 --start-time <T-1h> --end-time <now> --period 300 --statistics Sum --region ap-southeast-1`
> 11. the same RequestCount call for `<T-7d>` to `<T-7d+1h>` (same hour last week, the traffic baseline)
> 12. `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,ns:Namespace,metric:MetricName,dims:Dimensions},composite:CompositeAlarms[].AlarmName}'`
> 13. `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> 14. `aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1`
>
> Run them? (yes/no)

**Operator (script: "Pre-flight L3 opt-in: yes.")** [clock 11:13]: "Yes."

| # | Time | Command | Canned file | Result (summarized, no secret values) |
|---|---|---|---|---|
| 1 | 11:14 | `aws sts get-caller-identity` | `identity-prod.json` | account `123456789012`, matches the recorded target. L3 continues. |
| 2 | 11:15 | `aws sns list-subscriptions-by-topic ... --query 'Subscriptions[].Protocol'` | `sns-subscriptions-prod.json` (query applied) | `["email", "email"]` |
| 3 | 11:16 | `aws ecs describe-services ... deployments` | `ecs-describe-services-prod.json` (query applied) | 1 deployment, PRIMARY, rollout COMPLETED, created 2026-10-12T14:02:11Z (28 days ago), task definition `paymentapi-prod:12` |
| 4 | 11:17 | `aws ecs describe-services ... events[:10]` | `ecs-describe-services-prod.json` (query applied) | 1 event, 2026-11-09T01:12:40Z, "has reached a steady state" |
| 5 | 11:18 | `aws cloudwatch get-metric-statistics ... MemoryUtilization` | `metric-memory-prod.json` | 12 points, Average 49.8 to 54.2, Maximum up to 64.2 |
| 6 | 11:19 | `aws elbv2 describe-target-groups --names paymentapi-tg-prod` | `tg-describe-prod.json` | target group `paymentapi-tg-prod`, behind load balancer `app/paymentapi-alb-prod/50dc6c495c0c9188` (internal) |
| 7 | 11:20 | `aws elbv2 describe-target-health ...` | `tg-health-prod.json` | 3 targets, all `healthy` |
| 8 | 11:21 | `aws cloudwatch get-metric-statistics ... HTTPCode_Target_5XX_Count` | `metric-alb-5xx-prod.json` | Sum 0 in all 12 periods |
| 9 | 11:22 | `aws cloudwatch get-metric-statistics ... TargetResponseTime` | `metric-alb-latency-prod.json` | Average 0.036 to 0.040 s |
| 10 | 11:23 | `aws cloudwatch get-metric-statistics ... RequestCount` (last hour) | `metric-alb-requests-prod.json` | Sum 3,400 to 3,511 per 5 min |
| 11 | 11:24 | `aws cloudwatch get-metric-statistics ... RequestCount` (same hour 7 days ago) | `metric-alb-requests-prod.json` | same values, ratio 1.00 times the last hour |
| 12 | 11:25 | `aws cloudwatch describe-alarms --state-value ALARM ...` | `alarms-firing-prod.json` | no metric alarms and no composite alarms in ALARM |
| 13 | 11:26 | `aws cloudwatch describe-alarms-for-metric ... CPUUtilization ...` | `alarms-for-metric-cpu-prod.json` (before the alarm exists) | `[]` |
| 14 | 11:27 | `aws pricing get-products ...` | `pricing-cloudwatch-alarm.json` | standard alarm, `$0.10 per alarm metric month`, ap-southeast-1, publication 2026-10-07, looked up 2026-11-09 |

Environment rule: commands 1 and 12 read the same in every environment; prod taken.

`live:<n>` in the records is the number in the first column of the table above.

### Pre-flight Step 5 — score

Subscriber protocols are `email` and `email`, so the alarm only notifies. It is on the assessor's not-app-facing list, nothing else the plan changes is app-facing, and `outputs.tf` is untouched, so no output or export changes. Category 11 is not triggered: Green, evidence `plan: only not-app-facing attributes changed (alarm, notify-only per live:2)`. Q8's (c) answer no longer matters.

| # | Category | Score | Finding | Evidence |
|---|---|---|---|---|
| 1 | Blast radius | Green | One new resource, one region, nothing existing edited | `plan: Plan: 1 to add, 0 to change, 0 to destroy`; pure addition of an alarm needs no behaviour claim |
| 2 | Reversibility | Green | Pure addition, no in-place attribute change. Rollback is revert, plan, apply and removes only the alarm | `plan:`, assessor rollback list |
| 3 | Change velocity | Green | 0 commits to `main.tf` in 7 days, no open PR, last deploy 28 days ago (inside the 90 day lag threshold) | `git: F1`, `live:3`, `operator-stated` (IaC Q recent) |
| 4 | Dependency impact | Green | No catalog; every changed resource not-app-facing and no output or export changes | `plan:`, `live:2`, `code: outputs.tf` unchanged |
| 5 | Timing context | Green | No incident, no freeze, not peak: request rate 1.00 times the same hour last week | `operator` Q1 Q2, `operator-stated` Q3, `live:10` `live:11` |
| 6 | Operator familiarity | Green | Changed this service many times, experienced with Terraform | `operator` Q4 Q5 |
| 7 | Observability readiness | Green | The change only adds not-app-facing monitoring; no alarm exists on this metric today | `plan:`, `live:13` |
| 8 | Cost impact | Green | One standard alarm, `$0.10` per alarm metric month, price looked up 2026-11-09 | `live:14`, `operator-stated` Q6 |
| 9 | Security posture | Green | No IAM, network, encryption, public-access or audit-logging change | `plan:` |
| 10 | Resource health | Green | 3 of 3 tasks running and healthy, no alarm firing, CPU Average up to 41.2 and memory Average up to 54.2 (under 70 percent), 5xx 0, latency 36 to 40 ms | `live:3` to `live:12`, `live: B6` |
| 11 | Application compatibility | Green | Only not-app-facing attributes changed | `plan:`, `live:2` |

Counts: Red 0, Yellow 0, ⚪ 0. Verdict: **GREEN — proceed**.

### Pre-flight Step 5b — verify

- Citations re-opened: Greens on 1, 2, 4, 7, 9, 10, 11. Cited lines say what the findings claim: `plan:` has "Plan: 1 to add, 0 to change, 0 to destroy" and no IAM, network or output attribute; `live:2` returns `email`, `email`; `live:13` returns no alarm on the metric. Fixed: none.
- Source conflicts: none.
- Verdict working: Red = none; Yellow + ⚪ = 0; hard-block conditions checked (irreversible data change, active incident with freeze, public exposure, encryption removal, secrets, exhausted error budget) → none → GREEN.
- Fresh eyes: **not run — dry run** (required for GREEN, `pre-flight SKILL.md:315`).
- Not verified: delivery model (`operator-stated`); Q3 peak and Q6 cost (`operator-stated`, both also backed by live reads); Q1, Q2 (`operator` only); who is on hand at merge time, because merge time is not asked; "recent apply" (`operator-stated`, `live:3` shows a deployment 28 days ago, not a Terraform apply); SNS endpoint contents (only protocols were read, by design); latency and error rate have no separate week-ago baseline (last hour only).

### Pre-flight Step 6 — report

**Skill message to the operator (STOP 9, pre-flight GATE 2):**

> **Pre-flight report for `paymentapi` / `prod` — Verdict: GREEN — proceed**
>
> | # | Category | Score | Evidence |
> |---|---|---|---|
> | 1 | Blast radius | Green | `plan:` 1 to add |
> | 2 | Reversibility | Green | `plan:`, revert path |
> | 3 | Change velocity | Green | `git: F1`, `live:3` |
> | 4 | Dependency impact | Green | `plan:`, `live:2` |
> | 5 | Timing context | Green | `operator` Q1 Q2, `live:10` `live:11` |
> | 6 | Operator familiarity | Green | `operator` Q4 Q5 |
> | 7 | Observability readiness | Green | `plan:`, `live:13` |
> | 8 | Cost impact | Green | `live:14` `$0.10` per alarm metric month |
> | 9 | Security posture | Green | `plan:` |
> | 10 | Resource health | Green | `live:3` to `live:12` |
> | 11 | Application compatibility | Green | `plan:`, `live:2` |
>
> Drift rows: none. Verification: 7 Green citations checked, none fixed; verdict working Red none, Yellow + ⚪ 0, hard blocks none; fresh eyes not run — dry run. Not verified: delivery model, merge time and who is on hand, SNS endpoints (protocols only), a week-ago baseline for latency and errors.
>
> Green: acknowledge and proceed, or abort?

**Operator (script: "Pre-flight GATE 2 (risk decision): acknowledge and proceed.")** [clock 11:32]: "Acknowledged, proceed."

### Pre-flight Step 7 — record

Record written (see `preflight-record.md`): `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1132.md`. Re-read for secret values: none (no env values, no endpoints, no plan text). Invoked by `iac-change-execution`, so the record is left uncommitted and no commit is offered.

### Back in iac-change-execution — GATE 3

**Skill message to the operator (STOP 10):**

> **GATE 3 — pre-flight clearance.** Pre-flight verdict: **GREEN — proceed** (record `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1132.md`, plan hash `sha256:30f4...0a89`, target account `123456789012` / `ap-southeast-1`). No Red findings, no hard blocks. Clear to move on to execution (PR path)?

**Operator (script: "GATE 3 (clearance) and GATE 4 (execution): approve.")** [clock 11:37]: "Approved."

---

## Step 4c — Execute (PR path)

**Skill message to the operator (STOP 11):**

> Before I open the PR: do you want me to draft a heads-up for the people affected (service owners, reviewers, on-call) with `change-comms`? It is draft-only; you send it.

**Operator (script: "Optional offers ... no")** [clock 11:42]: "No."

Skill works on the branch created before Step 3 (`iac-change/paymentapi-cpu-high-alarm`). Repo commit style from `git log`: `paymentapi: <what> (#<n>)`. No PR template in the repo. Skill stages by explicit path first, to show the status (ambiguity 9).

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| E1 | 11:43 | `git add main.tf` | `empty.txt` | (none) |
| E2 | 11:44 | `git status` | answered from the diff, staged | `On branch iac-change/paymentapi-cpu-high-alarm`, `Changes to be committed: modified: main.tf` |

The status shows only the change from the diff, as the protocol answers it. A real working tree would also hold the local `tfplan` file and `.terraform/` directory from the plan; they are not staged (nothing but `main.tf` was added), and `.gitignore` handling is not visible in this fixture.

**Skill message to the operator (STOP 12, GATE 4):**

> On branch `iac-change/paymentapi-cpu-high-alarm` (from `origin/main`), about to stage **only** `main.tf`, commit, push, and open a PR.
> `git status` after staging: `Changes to be committed: modified: main.tf`. No `tfplan` / state / `.terraform/` / unrelated files.
> PR will include: change summary, evidence table, pre-flight verdict (GREEN), execution record link (`.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1157.md`, written after the PR, not committed yet).
> Commit subject: `paymentapi: add CPU utilization alarm`
> **Proceed?**

**Operator (script: "GATE 3 (clearance) and GATE 4 (execution): approve.")** [clock 11:49]: "Approved."

| # | Time | Command | Canned file | Output |
|---|---|---|---|---|
| E3 | 11:50 | `git commit -m "paymentapi: add CPU utilization alarm"` | `git-commit.txt` | `[iac-change/paymentapi-cpu-high-alarm 7f3a9c1] paymentapi: add CPU utilization alarm` / ` 1 file changed, 28 insertions(+), 0 deletions(-)` |
| E4 | 11:51 | `git push -u origin iac-change/paymentapi-cpu-high-alarm` | `git-push.txt` | `* [new branch] iac-change/paymentapi-cpu-high-alarm -> iac-change/paymentapi-cpu-high-alarm` |
| E5 | 11:52 | `gh pr create --title "paymentapi: add CPU utilization alarm" --body <summary, evidence table, pre-flight verdict GREEN, record path>` | `gh-pr-create.txt` | `https://github.com/acme/paymentapi-infra/pull/142` |

Skill reports the PR URL.

---

## Step 5a — Verify (PR path, CI applies on merge)

**Skill message to the operator (STOP 13):**

> PR https://github.com/acme/paymentapi-infra/pull/142 created. After merge, the CI pipeline applies it (`operator-stated`). Want me to poll the PR's checks or the pipeline status (with your approval)? Once the apply has landed, I can also run the phase success criteria (read-only). Without their output the record says `Applied: yes — not verified` at most.

**Operator (script: "Optional offers (... polling the PR checks or the sync status ...): no")** [clock 11:57]: "No."

Nothing is merged in this run, so no apply has landed and the success-criteria offer does not come up (ambiguity 14). Applied state for the record: `no — PR open`.

## Step 5b — Execution record

Record written (see `record.md`): `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1157.md` (clock 11:57). Not committed.

**Skill message to the operator (STOP 14, GATE 5):**

> Execution record written to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1157.md`. Commit it?

**Operator (script: "committing the record at GATE 5: no")** [clock 12:02]: "No."

**Skill message to the operator (STOP 15):**

> Want me to draft the result message and the ticket-closing comment (with the PR URL) with `change-comms`? Draft-only; you send them.

**Operator (script: "Optional offers ... no")** [clock 12:07]: "No."

## End of run

Skill final state: PR #142 open, not merged, nothing applied by the skill. `tfplan` stays local. Clock at end: 2026-11-09 12:07 +07:00. 15 stops; one carries unscripted sub-answers (STOP 7: Q8 and IaC question 9).
