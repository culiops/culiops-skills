# Transcript: baseline run of iac-change-execution v0.17.0 (origin/main) on light-lane-staging-prod

Skill text read with `git show origin/main:<path>`: `skills/iac-change-execution/SKILL.md`, `examples/aws.md`; `skills/pre-flight/SKILL.md`, `assessors/README.md`, `assessors/iac-change.md`, `examples/aws.md`. References `SKILL.md:<n>` are lines of `skills/iac-change-execution/SKILL.md`; `preflight:<n>` are lines of `skills/pre-flight/SKILL.md`; `assessor:<n>` are lines of `assessors/iac-change.md`.

Dry-run clock: starts 2026-11-09 10:00 +07:00. +1 min per command, +5 min per operator answer. Times are the clock reading when the command ran or the prompt was shown. Canned alarm files carry their own timestamps (prod alarm created 03:42:13Z = 10:42:13 +07:00); they are quoted as-is and are earlier than the clock at apply (11:40). The clock is used for every run time.

Environment note (applies to every lookup): the run is for prod only. The operator's first message names prod, the script says the old skill knows one environment, and the skill never asks for another. Every canned file picked below is the prod row, chosen by rule 1(a) where the command names prod (`paymentapi-svc-prod`, `-var-file=envs/prod.tfvars`, `paymentapi-tg-prod`, ...) and by rule 1(b) (the environment the skill is working on: prod) where the command carries no environment (`aws sts get-caller-identity`, `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi`, `aws cloudwatch describe-alarms --state-value ALARM`).

---

## Operator first message

> Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR.

Output root (Constraint 13, SKILL.md:35): `CULIOPS_HOME` is not set in the fixture environment (no value given anywhere in `canned/INDEX.md`), treated as unset. Root = `.culiops/` at the repo root. This is an environment read, not a lookup row, so it is not logged as `no canned output`.

---

## Step 1: Research

**Catalog.** `.culiops/service-discovery/paymentapi.md`: not present in the fixture. Skill text: suggest running service-discovery, proceed without it.

**Existing IaC code (read via Read, stands in for `git show origin/main:<path>`).** Files read: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `envs/prod.tfvars`, `envs/staging.tfvars`. Current branch is checked first because SKILL.md:141 reads the code from `origin/<default>` only when another branch is checked out.

**Ticket.** None given.

### Duplicate check (SKILL.md:145-151)

Identifiers (no ticket key): `aws_cloudwatch_metric_alarm`, `CPUUtilization`, `cpu-high` (the alarm name this repo's pattern would give). No ticket key, so no `--grep` search.

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:00 | `git branch --show-current` | `git-branch.txt` | `main` |
| 10:01 | `git grep -n -F 'aws_cloudwatch_metric_alarm'` | (grep over input files) | no matches |
| 10:02 | `git grep -n -F 'CPUUtilization'` | (grep over input files) | no matches |
| 10:03 | `git grep -n -F 'cpu-high'` | (grep over input files) | no matches |
| 10:04 | `git log --all --oneline -S'aws_cloudwatch_metric_alarm'` | `empty.txt` (row `git log * -S*`) | (no output) |
| 10:05 | `git log --all --oneline -S'CPUUtilization'` | `empty.txt` | (no output) |
| 10:06 | `git branch -a --list '*cpu*'` | `empty.txt` | (no output) |
| 10:07 | `gh pr list --state open --search 'cpu alarm paymentapi'` | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

Verdict: **not done** (`code:` no `aws_cloudwatch_metric_alarm` or `CPUUtilization` anywhere in the repo; `git:` no commit adds either; no unmerged branch, no open PR).

The current branch is `main`, so no `git fetch origin main` is needed to read the code (SKILL.md:141).

### Delivery model and environment selection (SKILL.md:153-156)

Searched the repo for CI config, GitOps objects, Atlantis / Terraform Cloud / Spacelift config, README, Makefile: the fixture has `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `envs/*.tfvars` only; `providers.tf:1-17` has no `backend "remote"` or `cloud {}` block. Nothing shows how changes are applied, so the delivery model is `UNVERIFIED` and the skill must ask (SKILL.md:156).

Environment selection is found in code: `-var-file=envs/<env>.tfvars`, one var-file per environment, each setting `aws_account_id` (`code: providers.tf:12-17`, `code: variables.tf:1-4`, `code: envs/prod.tfvars:1-3`).

**[10:08] Skill message to operator:**

> I could not find how changes reach prod: no CI workflow, GitOps object, Atlantis / Terraform Cloud / Spacelift config, README or Makefile in this repo. Environment selection is by var-file (`code: providers.tf:12`, `envs/prod.tfvars:1`).
> How is this stack applied: CI on merge, a GitOps controller, PR automation, or by hand? I will record your answer as `operator-stated`.

**STOP 1: delivery model (UNVERIFIED).**

**[10:08] Operator answer** (script: "Answers by meaning" > Delivery-model question): "Terraform is applied by hand from my workstation, and a direct apply is fine." Recorded `operator-stated`. Clock 10:13.

### Evidence table and live verification batch (SKILL.md:158-165)

Facts the plan relies on, code evidence filled in, live evidence proposed:

| Fact | Code evidence | Live evidence (proposed) |
|---|---|---|
| Target is prod, account 333333333333, ap-southeast-1 | `code: envs/prod.tfvars:2-3`, `code: providers.tf:16` | `aws sts get-caller-identity` |
| Cluster `paymentapi-cluster-prod`, service `paymentapi-svc-prod` exist (the alarm's dimensions) | `code: main.tf:9`, `main.tf:72`, `envs/prod.tfvars:1` | `aws ecs describe-services ...` |
| Service state and last deployment | `code: envs/prod.tfvars:11` (`desired_count = 3`), `main.tf:94` (`ignore_changes = [desired_count]`) | `aws ecs describe-services ... deployments` |
| SNS topic `paymentapi-alerts-prod` exists (alarm action target) | `code: main.tf:174-175`, `outputs.tf:16-19` | `aws sns get-topic-attributes ...` |
| No CPU alarm on the service yet | `code: none` (duplicate check, 10:01-10:03) | `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` |
| CPU baseline (to judge the threshold, and the "before" value for Step 5) | `code: none` | `aws cloudwatch get-metric-statistics ... CPUUtilization` |
| State matches code | n/a | `terraform plan -refresh-only` |

Reading note: SKILL.md:176 wants the research summary's Target line "from `<command>`", and Constraint 3 requires opt-in for live reads, so `aws sts get-caller-identity` goes into the batch. The SNS read is not a template in `examples/aws.md` (SKILL.md:165 says the batch comes "from examples/aws.md"); it is included because the plan depends on the topic existing.

**[10:13] Skill message to operator:**

> **Live verification batch (read-only; approve all, pick a subset, or decline):**
> 1. `aws sts get-caller-identity`
> 2. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount}'`
> 3. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].deployments[].{status:status,rollout:rolloutState,created:createdAt}'`
> 4. `aws sns get-topic-attributes --topic-arn arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod --region ap-southeast-1 --query 'Attributes.TopicArn'`
> 5. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}'`
> 6. `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --start-time 2026-11-09T02:23:00Z --end-time 2026-11-09T03:23:00Z --period 300 --statistics Average Maximum --region ap-southeast-1`
> 7. `terraform plan -refresh-only -var-file=envs/prod.tfvars` (drift check, never applied)
> If you decline, every row is marked `code-only: not live-verified` and that flag goes to pre-flight.

**STOP 2: read batch.**

**[10:13] Operator answer** (script: "Step 1 read batch: approve every command shown"): "Approve all." Clock 10:18.

| Time | Command | Canned file | Output used |
|---|---|---|---|
| 10:18 | `aws sts get-caller-identity` | `identity-prod.json` | Account `333333333333`, `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` (env: prod, rule 1(b)) |
| 10:19 | `aws ecs describe-services ... --query '...{status,desired,running,pending}'` | `ecs-describe-services-prod.json` | `[{"status":"ACTIVE","desired":3,"running":3,"pending":0}]` |
| 10:20 | `aws ecs describe-services ... --query '...deployments[].{status,rollout,created}'` | `ecs-describe-services-prod.json` | `[{"status":"PRIMARY","rollout":"COMPLETED","created":"2026-10-12T14:02:11.221000+00:00"}]` |
| 10:21 | `aws sns get-topic-attributes --topic-arn ...paymentapi-alerts-prod ... --query 'Attributes.TopicArn'` | `sns-attributes-prod.json` | `"arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod"` |
| 10:22 | `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi ... --query '...'` | `alarms-prefix-prod.json` (prod, before the alarm exists; env by rule 1(b)) | `[]` |
| 10:23 | `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization ... paymentapi-svc-prod` | `metric-cpu-prod.json` | 12 datapoints, timestamps 02:00Z-02:55Z in the file: Average 35.6-40.4 %, Maximum 50.4 % |
| 10:24 | `terraform plan -refresh-only -var-file=envs/prod.tfvars` | `plan-refresh-only-prod.txt` | `No changes. Your infrastructure still matches the configuration.` |

Ambiguity: SKILL.md:165 lists `terraform plan -refresh-only` in the batch but no `terraform init` before it; init is only mentioned in 4a (SKILL.md:307). The working directory was treated as already initialised (`terraform-init.txt` says providers are "previously-installed").

Gaps (SKILL.md:167): alarms on `CPUUtilization` of this service that do not start with `paymentapi` are not covered by the prefix read: `UNVERIFIED`, resolved by `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions ...`.

**[10:25] Skill message to operator (research summary, informational, no gate; SKILL.md:182):**

> **Change requested:** Add a CloudWatch CPU utilization alarm for paymentapi in prod, applied directly (no PR).
> **Service:** `paymentapi` / **Instance:** none
> **IaC tool(s):** Terraform (hashicorp/aws ~> 5.0, `providers.tf:4-9`) · **Delivery model:** applied by hand from the operator's workstation (`operator-stated`; nothing in the repo shows it) · **Env selection:** `-var-file=envs/prod.tfvars` (`code: providers.tf:12-17`, `envs/prod.tfvars:1`)
> **Target:** account `333333333333` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:18; region from `code: envs/prod.tfvars:2`) / no kube context
> **Catalog used:** none, proceeding without catalog (consider running service-discovery first for a more complete picture)
> **Duplicate check:** not done (`code:` no alarm resource and no `CPUUtilization` in the repo; `git:` no commit adds either; no branch or PR in flight)
> **Evidence table:** drift rows: 0, unverified rows: 0
>
> | Fact | Code evidence | Live evidence | Match? |
> |---|---|---|---|
> | Target prod = account 333333333333, ap-southeast-1 | `code: envs/prod.tfvars:2-3`, `providers.tf:16` | `live: aws sts get-caller-identity` 10:18 -> 333333333333 | yes |
> | Cluster/service names for the alarm dimensions | `code: main.tf:9`, `main.tf:72`, `envs/prod.tfvars:1` | `live: ecs describe-services` 10:19 -> `paymentapi-svc-prod` ACTIVE | yes |
> | Service capacity | `code: envs/prod.tfvars:11` -> 3 | `live: ecs describe-services` 10:19 -> desired 3, running 3, pending 0 | yes |
> | Last deployment | `code: n/a` | `live: ecs describe-services` 10:20 -> PRIMARY, COMPLETED, created 2026-10-12T14:02:11Z | n/a |
> | SNS topic `paymentapi-alerts-prod` | `code: main.tf:174-175`, `outputs.tf:16-19` | `live: sns get-topic-attributes` 10:21 -> topic exists | yes |
> | No CPU alarm on the service | `code: none` (`git grep`, 10:01-10:03) | `live: describe-alarms --alarm-name-prefix paymentapi` 10:22 -> `[]` | yes |
> | CPU baseline | `code: none` | `live: get-metric-statistics` 10:23 -> avg 35.6-40.4 %, max 50.4 % | informational |
> | State matches code | n/a | `live: terraform plan -refresh-only` 10:24 -> No changes | yes |
>
> **Gaps remaining:** alarms with another name on the same metric: `UNVERIFIED` (`aws cloudwatch describe-alarms-for-metric ...`).

---

## Step 2: Plan

Single-phase: adding one alarm is the skill's own example of a single-phase change (SKILL.md:191).

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:25 | `git branch --show-current` | `git-branch.txt` | `main` |
| 10:26 | `git status --short` | `git-status-clean.txt` (`--short` prints nothing) | (no output) |
| 10:27 | `git rev-parse --short origin/main` | `git-rev-parse.txt` | `a1b2c3d` |

Execution path (SKILL.md:204-208): the default message offers PR and flags direct apply as an option. The operator already asked for a direct apply in the first message and Constraint 6 (SKILL.md:28) needs that explicit request, so the plan shows direct apply and the A4 escalation instead of offering the default.

Threshold, period and actions are not in the request. The plan proposes the repo's own pattern and a threshold above the live baseline (max 50.4 %): 80 % average over 3 periods of 300 s, notifying the existing alerts topic on ALARM and OK.

Self-check (SKILL.md:212-218): 1 pass (every item cites `code:` / `live:`; no destroy, replace or resize; Disruption `none` rests on `code:` and is confirmed by `plan:` in 4a); 2 pass (no deletes); 3 pass (rollback and command-form success criteria present); 4 pass (0 drift rows); 5 pass (applied by hand, so direct apply fits); 6 pass (main.tf alarm is the only file the request implies). **6/6.**

**[10:28] Skill message to operator:**

> **Change plan for `paymentapi`:**
>
> **Phase 1 of 1: add CPU utilization alarm (prod)**
> - Files: `main.tf` (modify: add one resource block after the SNS topic, same section style)
> - Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-${var.env}`, AWS/ECS `CPUUtilization`, Average, 300 s x 3 periods > 80 %, `treat_missing_data = "missing"`, alarm and OK actions to `aws_sns_topic.paymentapi_alerts`)
> - Blast radius: one new resource, no change to existing resources, no output or export changes (`code: outputs.tf:1-19` unchanged); nothing depends on an alarm
> - Disruption: none (`code: main.tf` new standalone resource reading existing names and the topic ARN; confirmed by `plan:` in Step 4a)
> - Rollback path: `git revert`, then plan and apply (destroys the alarm); reversible, `untested`; the alarm's state history is lost on delete (`code:` inference)
> - Evidence: evidence-table rows 1, 2, 4, 5, 6 (live reads 10:18-10:24)
> - Success criteria:
>   - `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actions:ActionsEnabled}'` -> one alarm, `actions: true`, `state` OK or INSUFFICIENT_DATA for the first minutes
>   - `terraform plan -var-file=envs/prod.tfvars` -> `No changes`
>
> **Execution path:** Direct apply (you asked for it; applied by hand from your workstation, `operator-stated`). This escalates the pre-flight assessment (A4: local workstation apply).
> **Branch:** current `main` -> `iac-change/paymentapi-add-cpu-alarm` from `origin/main` @ `a1b2c3d` (`git fetch origin main`, then `git switch -c iac-change/paymentapi-add-cpu-alarm origin/main`)
> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset)
> **Self-check:** 6/6 pass
>
> **Approve this plan?**

**STOP 3: GATE 1.**

**[10:28] Operator answer** (script: "GATE 1 (the plan): approve. Execution path: direct apply"): "Approve. Direct apply." Clock 10:33.

---

## Step 3: Implement

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:33 | `git fetch origin main` | `empty.txt` | (no output) |
| 10:34 | `git switch -c iac-change/paymentapi-add-cpu-alarm origin/main` | `git-switch.txt` (runner fills the branch) | `Switched to a new branch 'iac-change/paymentapi-add-cpu-alarm'` |
| 10:35 | `git branch --show-current` | `git-branch.txt` says `main` "always" | printed `iac-change/paymentapi-add-cpu-alarm` (see note) |

Runner note: the INDEX row for `git branch --show-current` says `main` with `Use when: always (the repo is on main)`. Printing `main` after the simulated `git switch -c` would make the skill's own check ("confirm `git branch --show-current` shows the change's branch before writing any file", SKILL.md:250) fail. Protocol rule 1 "State" says the runner follows what has already happened in the run, so the change branch is printed.

Code written to `main.tf` (appended after the SNS topic; naming `<service>-<role>-${var.env}` follows `main.tf:9`, `:25`, `:72`, `:138`, `:174`; tags follow `main.tf:177-180`; section comment style follows `main.tf:172`):

```diff
--- a/main.tf
+++ b/main.tf
@@ -179,3 +179,31 @@ resource "aws_sns_topic" "paymentapi_alerts" {
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

The header comment at `main.tf:3-4` ("The CloudWatch CPU alarm is intentionally absent") is now stale. It is code-comment text, so it is data (Constraint 12). No plan item covers editing it, so the diff leaves it untouched (self-check item 2: each hunk maps to a plan item).

Canned plan versus code: the canned plan (`plan-prod.txt`) was written for the same alarm (name, threshold 80, 3 x 300 s, Average, `missing`, both actions to the prod topic, tags). The code above plans the same; no difference.

Formatter and diff self-check (SKILL.md:257-265, 287). `terraform fmt <file>` is shown before running (SKILL.md:287); the text does not make that a gate (Constraint 3 lists the approvals and the formatter is not among them), so no stop.

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:36 | `terraform fmt main.tf` | `empty.txt` | (no output: formatted) |
| 10:37 | `git status --short` | answered from the diff | ` M main.tf` |
| 10:38 | `git diff` | answered from the diff | the diff above |

Diff self-check: 1 scope pass (only `main.tf`, which is in the plan); 2 plan-hunk pass (one resource -> one hunk); 3 conventions pass (`code: main.tf:9`, `:174`, `:177-180`); 4 no silent safety changes pass; 5 no secrets pass (no `tfplan`, state or `.terraform/` in the changes); 6 formatted pass. **6/6.**

Fresh eyes (SKILL.md:267-268): the phase is add-only and touches none of the listed sensitive types (access control, network exposure, DNS, data stores, secrets / KMS, deletion-protection / lifecycle). Skip condition holds, so no reviewer is dispatched: `fresh-eyes: skipped, add-only, no sensitive types`.

**[10:39] Skill message to operator:**

> **Code changes for Phase 1 of 1:**
>
> **Modified:** `main.tf`: adds `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (28 lines) after the SNS topic.
>
> **Plan <-> hunk:** add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` -> `main.tf` one hunk at lines 182-209.
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped, add-only, no sensitive types
>
> Full diff is in your working tree (`git diff` to review).
> **Approve these changes?**

**STOP 4: GATE 2.**

**[10:39] Operator answer** (script: "GATE 2 (the code): approve"): "Approve." Clock 10:44.

---

## Step 4: Execute

### 4a: Generate plan output

The Target check block shows `aws sts get-caller-identity` output (SKILL.md:300), so the read runs before the prompt. It is in the batch the operator approved at 10:13 and repeats it for the display.

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:44 | `aws sts get-caller-identity` | `identity-prod.json` (prod, rule 1(b)) | Account `333333333333`, `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` |

No `terraform workspace show` is run: Step 1 found the environment is selected by var-file, not workspace (SKILL.md:155), and the INDEX has no row for it.

**[10:45] Skill message to operator:**

> **Target check:** `aws sts get-caller-identity` -> account `333333333333`, role `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` · region `ap-southeast-1` (`envs/prod.tfvars:2`) · no kube context · Terraform var-file `envs/prod.tfvars` (no workspace)
> **Plan is for:** `prod` (`aws_account_id = "333333333333"`, `envs/prod.tfvars:3`) — **match: yes**
> About to run: `terraform init` (may modify `.terraform.lock.hcl`) then `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above). **Proceed?**

**STOP 5: 4a target check.**

**[10:45] Operator answer** (script: "4a target check (Proceed?): yes"): "Yes." Clock 10:50.

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:50 | `terraform init` | `terraform-init.txt` | `Terraform has been successfully initialized!` (reuses lock file; `.terraform.lock.hcl` not modified) |
| 10:51 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | `plan-prod.txt` (prod, before the prod apply) | plan below |

```
Terraform will perform the following actions:

  # aws_cloudwatch_metric_alarm.paymentapi_cpu_high will be created
  + resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_high" {
      + actions_enabled                       = true
      + alarm_actions                         = [ + "arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod" ]
      + alarm_description                     = "CPU utilization above 80% for paymentapi prod"
      + alarm_name                            = "paymentapi-cpu-high-prod"
      + comparison_operator                   = "GreaterThanThreshold"
      + dimensions                            = { + "ClusterName" = "paymentapi-cluster-prod", + "ServiceName" = "paymentapi-svc-prod" }
      + evaluation_periods                    = 3
      + metric_name                           = "CPUUtilization"
      + namespace                             = "AWS/ECS"
      + ok_actions                            = [ + "arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod" ]
      + period                                = 300
      + statistic                             = "Average"
      + tags                                  = { + "Environment" = "prod", + "Service" = "paymentapi" }
      + threshold                             = 80
      + treat_missing_data                    = "missing"
      (attributes shown condensed; full text in canned/plan-prod.txt)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Cross-check (SKILL.md:313): the one resource is the approved phase item; action is `create`, matching Disruption `none` (now `plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_high create`). No unexpected changes, no drift. The plan output is shown to the operator (informational, no gate).

### 4b: Pre-flight gate

Reusable record check in `.culiops/pre-flight/`: directory not present in the fixture, so no record exists. The match rule needs the plan hash, so it is computed first:

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:52 | `terraform show -no-color tfplan` | `plan-prod.txt` (last plan was for prod) | the plan text |
| 10:53 | `sha256sum <scratch file holding the plan text>` (scratch outside the repo, deleted after) | INDEX "Plan hashes" | `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` |

No match, so pre-flight is invoked inline with: the plan output, the target check, the delivery model (applied by hand, `operator-stated`), the evidence table (0 drift, 0 unverified, 0 `code-only`), the plan hash, and the flag "local workstation apply, not going through CI/CD pipeline" (SKILL.md:330).

---

## Pre-flight (inline), v0.17.0

### Step 1: detect, target, plan hash, assessor

Unsupported-stack check: Terraform on AWS, supported. Assessors loaded: `assessors/iac-change.md` (README.md is the template doc, not an assessor). Trigger `Terraform plan` and the `Plan:` summary line match; selected `iac-change`.

Target recorded: AWS account `333333333333` / `ap-southeast-1` | no kube context | Terraform var-file `envs/prod.tfvars`, no workspace, no backend block (local state, `code: providers.tf:1-17`). Delivery model: manual apply by hand from a workstation, kept as the caller's `operator-stated` citation (preflight:240). Plan hash: passed by the caller, used as is (preflight:242).

**[10:54] Skill message to operator:**

> **Pre-flight, scope and target.**
> **Output root:** `.culiops/` (`CULIOPS_HOME` unset).
> Detected action type: Terraform plan (assessor `iac-change`). Scope: 1 resource to add (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`), 0 to change, 0 to destroy. Target: account `333333333333` / `ap-southeast-1` / var-file `envs/prod.tfvars`. Delivery model: manual apply from a workstation (`operator-stated`). Plan hash: `sha256:1e420453...763fc8`. Caller flag: local workstation apply, not CI/CD.
> I detected this as a Terraform add of one CloudWatch alarm in account `333333333333` / `ap-southeast-1`, delivered by manual apply. Is this correct?

**STOP 6: pre-flight GATE 1.**

**[10:54] Operator answer** (script: "Pre-flight GATE 1 (scope and target): confirm"): "Confirmed." Clock 10:59.

### Step 2: L1 static analysis

| Time | Command | Canned file | Output |
|---|---|---|---|
| 10:59 | `git log --since=7.days --oneline origin/main -- main.tf` | `empty.txt` (row `git log * --since=*`) | (no output) |
| 11:00 | `git status --short` | answered from the diff | ` M main.tf` (this change itself, no prior uncommitted work) |
| 11:01 | `gh pr list --state open --search 'main.tf paymentapi'` | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

Preliminary L1 results:
- Plan hygiene: no "Objects have changed outside of Terraform" block (`plan:`), refresh-only plan clean (`live:` from the caller's table); the plan was made with `-var-file=envs/prod.tfvars` and no `-target` / `-refresh=false`.
- Cat 1: 1 add, single region (`plan: Plan: 1 to add, 0 to change, 0 to destroy`). Cat 2: pure create, no in-place attribute change (`plan:`). Cat 3: 0 commits to `main.tf` in 7 days; the three older commits are outside 30 days (`git:`); no open PR. Cat 7, 8, 9 (preliminary): alarm added, nothing app-facing changes in the plan, no IAM / network / encryption change.
- Cat 4: no catalog. Cat 4 is `unknown` until the not-app-facing exception can be applied.
- Category 11 marking (assessor:211-221): the alarm's actions go to an SNS topic. An alarm is not-app-facing only if the topic's subscription protocols were checked and are all email / email-json / sms (assessor:215). The caller's evidence table has no protocols and L1 runs no live query, so the protocols are not checked. "If the subscriber protocols were not checked, treat the alarm as app-facing (unsure means triggered)." So at the end of L1 the change is app-facing, and Q8 applies (preflight:106, 263).
- Drift rows: none.

### Step 3: L2 human context

Standard Q1-Q7 are all asked: none can be answered from L1 (no freeze calendar in the repo; commit count is not familiarity, preflight:104).

Assessor-specific questions (assessor:244-249, asked after the standard 7, preflight:108) are skipped where L1 holds the answer (preflight:104, 263):
- A1 "plan run and reviewed?": the plan was run in this session by the caller and shown to the operator at 10:51.
- A2 delivery model: passed by the caller, `operator-stated`.
- A3 `-target` / `-refresh=false` / non-default var-file: the plan command is on record (`terraform plan -out=tfplan -var-file=envs/prod.tfvars`).
- A4 "applied recently?": the caller's evidence table has the last ECS deployment, `created 2026-10-12T14:02:11Z` (28 days), an evidence source the assessor names for last apply (assessor:128).

Ambiguity (preflight:104/108/263 and assessor:244-249): whether an assessor question that L1 can only partly answer must still be asked. I took "skip where L1 holds evidence that answers them". Had A4 been asked it would have been a separate or extra, unscripted question.

Q8 is asked in the same batch (preflight:106) because L1 left the alarm app-facing.

**[11:02] Skill message to operator:**

> **Pre-flight context check:**
> 1. Is there an active incident affecting this service or its dependencies? (yes/no)
> 2. Is there a deploy freeze or change window restriction? (yes/no)
> 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure)
> 4. Have you changed this service before? (many times / a few times / first time)
> 5. Have you used this IaC tool before? (experienced / some experience / first time)
> 6. What's the expected cost impact? (negligible / moderate / significant / unknown)
> 7. Any other context I should know? (free text, optional)
> 8. This change touches what the app depends on: an alarm whose actions go to SNS topic `paymentapi-alerts-prod` (subscriber types not yet checked). Where is the application source? (a) a local checkout: give the path; (b) a GitHub repo through `gh`: give `owner/repo` and the deployed ref; (c) not available.

**STOP 7: unscripted** (Q1-Q7 scripted, Q8 not in the script).

**[11:02] Operator answer.** Q1-Q7 from the script ("Pre-flight L2 questions: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none"): "1 no, 2 no, 3 no, 4 many times, 5 experienced, 6 negligible, 7 none." Q8: not covered by the script, so the runner's default applies (rule 2): "as proposed". Nothing was proposed (the question offers (a), (b), (c)), so no path or repo is given. Clock 11:07.

Q8 handling: no source location was given, which the skill treats as (c) not available (preflight:106): category 11 is `unknown` for now. Step 3b is not run (no source to read). L3 below reads the subscription protocols, which can move the alarm onto the not-app-facing list (preflight:286).

Ambiguity (preflight:106 vs 280-286): Q8 is asked at L2, before L3 reads the protocols that would make the question unnecessary. The text gives no way to skip it for an alarm.

Recorded: Q1 `operator`, Q2 `operator`, Q4 `operator`, Q5 `operator`; Q3 and Q6 `operator-stated`.

### Step 4: L3 live signals

L3 command list (target check first; anything the caller's table already answers is left out: ECS counts / deployments, CPU, SNS topic, alarms by prefix, refresh-only drift check):

**[11:07] Skill message to operator:**

> I can check live system health with read-only queries if you have CLI access. Without it, resource health stays unknown and the best possible verdict is YELLOW. Here are the commands I'd run:
> 1. `aws sts get-caller-identity --query Account --output text` (target check, must equal 333333333333)
> 2. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].events[:10].{at:createdAt,msg:message}'`
> 3. `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --start-time 2026-11-09T03:07:00Z --end-time 2026-11-09T04:07:00Z --period 300 --statistics Average Maximum --region ap-southeast-1`
> 4. `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,ns:Namespace,metric:MetricName,dims:Dimensions},composite:CompositeAlarms[].AlarmName}'`
> 5. `aws elbv2 describe-target-groups --names paymentapi-tg-prod --region ap-southeast-1` (names the load balancer)
> 6. `aws elbv2 describe-target-health --target-group-arn <ARN from 5> --region ap-southeast-1`
> 7. `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count --dimensions Name=LoadBalancer,Value=<LB from 5> --start-time ... --end-time ... --period 300 --statistics Sum --region ap-southeast-1`
> 8. same call with `--metric-name TargetResponseTime --statistics Average`
> 9. same call with `--metric-name RequestCount --statistics Sum` (last hour)
> 10. same call as 9 for the same hour 7 days ago (baseline)
> 11. `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> 12. `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod --region ap-southeast-1 --query 'Subscriptions[].Protocol'` (protocols only, never endpoints)
> 13. `aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1`
> Run them? (yes/no)

**STOP 8: pre-flight L3 opt-in.**

**[11:07] Operator answer** (script: "Pre-flight L3 opt-in: yes"): "Yes." Clock 11:12.

| # | Time | Command | Canned file | Result used |
|---|---|---|---|---|
| 1 | 11:12 | `aws sts get-caller-identity --query Account --output text` | `identity-prod.json` (prod, rule 1(b)) | `333333333333`: matches the target |
| 2 | 11:13 | `aws ecs describe-services ... --query 'services[].events[:10]...'` | `ecs-describe-services-prod.json` | 1 event: `2026-11-09T01:12:40Z` "has reached a steady state" |
| 3 | 11:14 | `aws cloudwatch get-metric-statistics ... MemoryUtilization ... paymentapi-svc-prod` | `metric-memory-prod.json` | avg 50-54 %, max 64 % |
| 4 | 11:15 | `aws cloudwatch describe-alarms --state-value ALARM ...` | `alarms-firing-prod.json` (prod, rule 1(b)) | none firing (`MetricAlarms: []`, `CompositeAlarms: []`) |
| 5 | 11:16 | `aws elbv2 describe-target-groups --names paymentapi-tg-prod ...` | `tg-describe-prod.json` | TG ARN `...targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`, LB `app/paymentapi-alb-prod/50dc6c495c0c9188` |
| 6 | 11:17 | `aws elbv2 describe-target-health --target-group-arn ...paymentapi-tg-prod/6d0ecf831eec9f09` | `tg-health-prod.json` | 3 targets, all `healthy` |
| 7 | 11:18 | `get-metric-statistics ... HTTPCode_Target_5XX_Count ... paymentapi-alb-prod` | `metric-alb-5xx-prod.json` | Sum 0 in all 12 periods |
| 8 | 11:19 | `get-metric-statistics ... TargetResponseTime ... paymentapi-alb-prod` | `metric-alb-latency-prod.json` | avg 36-40 ms, max 140 ms |
| 9 | 11:20 | `get-metric-statistics ... RequestCount (last hour)` | `metric-alb-requests-prod.json` | 3,400-3,511 per 5 min |
| 10 | 11:21 | `get-metric-statistics ... RequestCount (T-7d)` | `metric-alb-requests-prod.json` (same file for the same hour a week ago) | 3,400-3,511 per 5 min: ratio 1.0 |
| 11 | 11:22 | `aws cloudwatch describe-alarms-for-metric ... CPUUtilization ... paymentapi-svc-prod` | `alarms-for-metric-cpu-prod.json` (before the alarm exists) | `[]`: no alarm on the metric (closes the Step 1 gap) |
| 12 | 11:23 | `aws sns list-subscriptions-by-topic --topic-arn ...paymentapi-alerts-prod ... --query 'Subscriptions[].Protocol'` | `sns-subscriptions-prod.json` | `["email","email"]` (endpoints not read) |
| 13 | 11:24 | `aws pricing get-products ...` | `pricing-cloudwatch-alarm.json` | standard alarm 0.10 USD per alarm metric month, ap-southeast-1, publication 2026-10-07; looked up 2026-11-09 |

The canned metric files carry datapoint timestamps 02:00Z-02:55Z regardless of the window requested (INDEX: "any time window gives this file").

With result 12 every subscription is `email`, so the alarm is on the not-app-facing list (assessor:215): category 11 is Green from `plan:` (only a not-app-facing attribute changes) plus `live:12`. Category 4 is Green under the no-catalog exception (every changed resource not-app-facing, no output or export changes in the plan).

### Step 5: score

Direct-apply flag: the caller says it "surfaces as elevated risk in blast radius and security posture categories" (SKILL.md:330). Pre-flight has no rule of its own for this flag; I took the caller's sentence directly and raised categories 1 and 9 from Green to Yellow. Ambiguity noted: SKILL.md:330 against preflight:23, 62 (score from evidence; Green/Yellow thresholds).

Scorecard: 1 Yellow, 2 Green, 3 Green, 4 Green, 5 Green, 6 Green, 7 Green, 8 Green, 9 Yellow, 10 Green, 11 Green (full table in `preflight-record.md`). Hard-block conditions on 2, 5, 9, 10 checked: none. Verdict: **YELLOW, proceed with caution** (Yellow + unknown = 2, below the escalation threshold of 3).

### Step 5b: verify

Citation check: re-opened the cited source for every Green on categories 2, 4, 7, 10, 11 and for the two mitigation premises: 7 checked, 0 fixed. Source conflicts: none (operator Q3 "not peak" agrees with live:9/10; Q6 "negligible" agrees with live:13). Verdict arithmetic: Red = none; Yellow + unknown = 2 (cats 1, 9); hard blocks checked: irreversible data change, active incident + freeze, public exposure / encryption removal / secrets, error budget exhausted: none -> YELLOW.

`fresh-eyes: not run — dry run` (the verdict is YELLOW, so the text requires the second read, preflight:315; no reviewer is dispatched in a dry run).

Not verified: delivery model (`operator-stated`, no pipeline config in the repo); Q1, Q2, Q4, Q5 are operator-only facts; Q8 was not answered, no app source was read (not needed once the alarm is notify-only).

### Step 6: report and GATE 2

**[11:25] Skill message to operator (report summary):**

> **Pre-flight verdict: YELLOW, proceed with caution.** Plan hash `sha256:1e420453...763fc8`, target account `333333333333` / `ap-southeast-1` / `envs/prod.tfvars`.
> Green: 2 reversibility, 3 change velocity, 4 dependency impact, 5 timing, 6 familiarity, 7 observability, 8 cost, 10 resource health, 11 application compatibility (each with its evidence in the record).
> **Yellow 1 blast radius:** one resource added in one region (`plan:`), raised because the apply is a local workstation apply, not through CI/CD (`operator-stated`, caller flag). Why it matters: no pipeline log, branch protection or second reviewer sits between the change and prod. Mitigation (operator action): re-check the target check at the apply prompt; after apply confirm the alarm leaves INSUFFICIENT_DATA.
> **Yellow 9 security posture:** no IAM, network or encryption change (`plan:`); raised by the same flag. Mitigation (operator action): apply with the least-privilege write role for `cloudwatch:PutMetricAlarm` and drop it afterwards (`examples/aws.md` Tier 2).
> Drift: none. Not verified: delivery model, operator-only answers.
> Risk decision: acknowledge the two Yellow findings and proceed, or abort?

**STOP 9: pre-flight GATE 2.**

**[11:25] Operator answer** (script: "Pre-flight GATE 2 (risk decision): acknowledge and proceed"): "Acknowledged, proceed." Clock 11:30.

### Step 7: record

Pre-flight record written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1130.md` (content in `preflight-record.md`). Invoked by another skill, so it is left uncommitted and no commit is offered (preflight:341).

---

## Back in iac-change-execution

### GATE 3

Verdict YELLOW: "Green/Yellow: Proceed" (SKILL.md:325). The operator already acknowledged it at the pre-flight risk decision (STOP 9). The skill text gives no further prompt for Green / Yellow, so no extra stop is logged. Ambiguity: SKILL.md:324-326 versus the workflow diagram's diamond for GATE 3 (SKILL.md:99, 117) and the script's "GATE 3 (clearance) ... approve" line. I took the line the text supports most directly: proceed without a second prompt.

### 4c: Execute

**[11:30] Skill message to operator:**

> Pre-flight cleared with YELLOW (acknowledged). Before the apply: I can draft a heads-up for the people affected (service owners, reviewers, on-call) with `change-comms` (draft-only; you send it). Want that?

**STOP 10: 4c change-comms offer.**

**[11:30] Operator answer** (script: "Optional offers ...: no"): "No." Clock 11:35.

Direct apply path (SKILL.md:349-355). Re-showing the target check from 10:44-10:45 (SKILL.md:354 says "re-shown"; I did not re-run the identity read).

**[11:35] Skill message to operator:**

> **Target check (from 10:44):** account `333333333333`, role `paymentapi-operator`, region `ap-southeast-1`, var-file `envs/prod.tfvars`. Plan is for prod: match yes.
> About to run: `terraform apply tfplan`
> This will: create `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`, CPU > 80 % for 3 x 5 min, notifies `paymentapi-alerts-prod`). Plan: 1 to add, 0 to change, 0 to destroy. Nothing else is touched.
> Needs a role that can create CloudWatch alarms (`examples/aws.md` Tier 2: assume it just before and drop it after). Rollback: revert the commit, plan, apply (destroys the alarm).
> **Proceed?**

**STOP 11: GATE 4.**

**[11:35] Operator answer** (script: "GATE 3 and GATE 4: approve" / "GATE 4 (the apply command): approve"): "Approve." Clock 11:40.

| Time | Command | Canned file | Output |
|---|---|---|---|
| 11:40 | `terraform apply tfplan` | `apply-prod.txt` (apply is for prod) | `aws_cloudwatch_metric_alarm.paymentapi_cpu_high: Creation complete after 1s [id=paymentapi-cpu-high-prod]` / `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` |

Not long-running: no background run. The prod apply is now done (state: after prod apply).

### Success criteria and Step 5a

After Phase 1 completes the skill runs the phase's success criteria (SKILL.md:364). The commands were shown in the plan the operator approved at GATE 1, so they run without a separate prompt (Constraint 3, SKILL.md:25, lists the approvals required: batch, 4a plan command, Step 5 health checks, apply). Single-phase: no phase gate to Phase N+1.

| Time | Command | Canned file | Output |
|---|---|---|---|
| 11:41 | `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actions:ActionsEnabled}'` | `alarm-cpu-high-after-prod.json` (prod, after the prod apply) | `[{"name":"paymentapi-cpu-high-prod","state":"OK","actions":true}]` (file's own timestamps: `AlarmConfigurationUpdatedTimestamp` 2026-11-09T03:42:13Z) |
| 11:42 | `terraform plan -var-file=envs/prod.tfvars` (re-plan, SKILL.md:386) | `plan-after-prod.txt` (prod re-plan, after the prod apply) | `No changes. Your infrastructure matches the configuration.` |

Ambiguity (SKILL.md:25 versus 386): the re-plan is a live read that is not named as approved in Constraint 3 and has no prompt in 5a.1. I ran it on the 4a approval of the plan command (it is the same command), with no stop.

Success criteria: alarm exists, `ActionsEnabled: true`, state OK -> pass. Re-plan: `No changes` -> pass.

**[11:43] Skill message to operator:**

> Apply completed. I can run read-only health checks to verify the change is working. Want me to try? (yes/no)

**STOP 12: 5a health checks offer.**

**[11:43] Operator answer** (script: "Optional offers ...: no. They are not covered by the script's intent"): "No." Clock 11:48.

Note: the script's list of optional offers names the change-comms heads-up, polling PR checks / sync status and committing the record. The health-check offer is not in that list. I mapped it to the same entry (it is an optional offer the script's intent does not cover, "Answers by meaning"). It is not logged as `unscripted`.

**Skill message to operator (5a report):**

> **Verification for Phase 1:**
> Re-plan: clean (`No changes`)
> Success criteria: alarm `paymentapi-cpu-high-prod` exists, `ActionsEnabled: true`, state OK: pass
> Health checks: not requested

### 5b: Execution record

Written to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1148.md` (content in `record.md`). The code change stays uncommitted on branch `iac-change/paymentapi-add-cpu-alarm`: the direct apply path has no commit step (SKILL.md:288, 349-355), so the applied alarm exists in prod and in the working tree only, not in git. This is recorded under Outcome.

**[11:48] Skill message to operator:**

> Execution record written to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1148.md`. Commit it?
> I can also draft the result message and the ticket-closing comment with `change-comms` (draft-only; you send them).

**STOP 13: GATE 5.**

**[11:48] Operator answer** (script: "Optional offers (... committing the record at GATE 5): no"): "No to both." Clock 11:53.

**Final message:**

> Done. Alarm `paymentapi-cpu-high-prod` created in account `333333333333` (prod), verified OK with actions enabled, re-plan clean. Execution record: `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1148.md` (uncommitted). The code change is still uncommitted on `iac-change/paymentapi-add-cpu-alarm`. Staging was not part of this run.

---

## Lookups with no canned output

None. Every command matched a row. Not looked up, by choice of reading: documentation pages (a pure alarm addition needs no behaviour claim, preflight:32), `terraform workspace show`, `git remote get-url origin` (only needed when `CULIOPS_HOME` is set).
