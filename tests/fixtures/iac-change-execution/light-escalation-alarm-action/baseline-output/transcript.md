# Dry-run transcript: light-escalation-alarm-action, baseline (old skill, origin/main)

- Skill text: `git show origin/main:skills/iac-change-execution/SKILL.md`, `.../examples/aws.md`, `skills/pre-flight/SKILL.md`, `.../assessors/README.md`, `.../assessors/iac-change.md`, `.../examples/aws.md`, `.../examples/app-source.md`. The Kubernetes examples are not used (AWS and Terraform only, per the selection rule at SKILL.md:456-460). Line numbers below are `SKILL.md:<line>` of iac-change-execution unless prefixed `pre-flight`.
- Operator script: `operator-script.md`, section "Answers by meaning" (old skill has no stop IDs).
- Dry-run clock: 2026-11-09 10:00 +07:00 (03:00Z) at the first message. +1 minute per command, +5 minutes per operator answer. Times below are +07:00.
- Fixture input files read: `main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`. `README.md` and `DRY-RUN-NOTES.md` not read (protocol). No `.culiops/` directory exists in the fixture, so there is no catalog and no earlier pre-flight record.
- Output root (Constraint 13, SKILL.md:35): `CULIOPS_HOME` is not set anywhere in the fixture, so the root is `.culiops/` at the repo root. Not a skill command, so no lookup; assumed unset.
- Fresh eyes: no subagent was dispatched anywhere in this run.

---

## First message (10:00)

Operator: "Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one."

---

## Step 1 — Research

### Catalog

`.culiops/service-discovery/paymentapi.md`: not present. Skill: suggest "consider running service-discovery first for a more complete picture", proceed without it (SKILL.md:139).

### Existing IaC code (read from the working tree)

The current branch is `main` (command below), so the working tree is the default branch's code and no `git show origin/main:` is needed (SKILL.md:141).

```
$ git branch --show-current          [10:00]  canned/git-branch.txt
main
```

Code read: `main.tf` (resources, notably `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` at main.tf:234-260, `aws_appautoscaling_policy.paymentapi_scale_out` at main.tf:193-210, `aws_appautoscaling_policy.paymentapi_scale_in` at main.tf:212-230, `aws_appautoscaling_target.paymentapi` at main.tf:185-191, `aws_sns_topic.paymentapi_alerts` at main.tf:174-181), `providers.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`. The file header comment (main.tf:3-4) says the scale-in policy exists and no alarm drives it yet.

### Ticket

None given.

### Duplicate check (all local, read-only; SKILL.md:145-151)

Identifiers from the request: alarm `paymentapi-cpu-low-prod`, Terraform label `paymentapi_cpu_low`, the scale-in policy it hooks to. No ticket key, so the `--grep` history search is skipped.

```
$ git grep -n -F 'cpu-low'                           [10:01]  grep -rn -F over the fixture input files (protocol rule 1)
(no output)
$ git grep -n -F 'cpu_low'                           [10:02]  same
(no output)
$ git grep -n -F -e 'scale-in' -e 'scale_in'         [10:03]  same
main.tf:3:# The service scales out on a CPU-high alarm. The scale-in policy exists
main.tf:213:resource "aws_appautoscaling_policy" "paymentapi_scale_in" {
main.tf:214:  name               = "paymentapi-scale-in-${var.env}"
$ git log --all --oneline -S'cpu-low'                [10:04]  canned/empty.txt   (INDEX: git log * -S*)
(no output)
$ git log --all --oneline -S'cpu_low'                [10:05]  canned/empty.txt
(no output)
$ git branch -a --list '*cpu-low*'                   [10:06]  canned/empty.txt
(no output)
$ gh pr list --state open --search 'cpu-low'         [10:07]  canned/gh-pr-list-empty.txt
no pull requests match your search in acme/paymentapi-infra
```

Verdict: **not done**. `code:` no hit for the alarm name or label anywhere in the repo, every environment; the only `scale_in` hits are the policy itself, so nothing references it. `git:` no history hit. No branch, no open PR.

### Delivery model and environment selection

```
$ git grep -n -i -F -e atlantis -e spacelift -e argocd -e flux -e workflows -e pipeline -e backend -e 'cloud {' -e gitlab -e jenkins   [10:08]  grep over the fixture input files (protocol rule 1)
(no output, exit 1)
```

No CI config, no `Application` / `Kustomization` / `HelmRelease`, no Atlantis, Spacelift or Terraform Cloud config, no Makefile in the files read. (`README.md` exists in the fixture directory but the dry-run protocol bars reading it, so it counts as absent for this search.) The skill's own rule (SKILL.md:156): nothing in the repo shows how changes are applied, so the delivery model is `UNVERIFIED`: ask the operator and record the answer as `operator-stated`.

Environment selection: Terraform `-var-file`. Evidence: `code: envs/prod.tfvars:1-3` (`env = "prod"`, `region = "ap-southeast-1"`, `aws_account_id = "333333333333"`) and `code: providers.tf:12-13` ("Each environment's var-file sets aws_account_id"). No `backend` block and no workspace use in the code, so no backend key to cite.

**Skill message shown to the operator (10:09):**

> I could not find how changes reach the environment: no CI config, GitOps object, Plan/apply automation (Atlantis, Terraform Cloud, Spacelift) or Makefile in the repo. The delivery model is `UNVERIFIED`. How do changes reach prod after a merge: CI applies on merge, a GitOps controller, plan and apply run in the PR by automation, or applied by hand? I will record your answer as `operator-stated`.

**STOP 1 — delivery model.** Operator answer (10:14), from `operator-script.md` "Answers by meaning" entry "Delivery-model question (UNVERIFIED in the repo)": "A CI pipeline applies on merge."

Recorded: delivery model = CI applies on merge (`operator-stated`); env selection = `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1-3`, `code: providers.tf:12-13`). Consequence (SKILL.md:154): CI-applies means PR path only.

*Note (ambiguity).* The text does not say whether the delivery question may be folded into the read-batch prompt. Taken as its own prompt because it comes before the evidence table and the batch in the Step 1 order (SKILL.md:153-165).

### Evidence table, code side (drafted before the batch)

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| `paymentapi-cpu-high-prod` config (GreaterThanThreshold 70, 3 x 300 s, Average, AWS/ECS CPUUtilization, dims cluster and service, `alarm_actions` = SNS topic + scale-out policy, `ok_actions` = SNS topic) | `code: main.tf:234-260` | pending batch | pending |
| `paymentapi-cpu-low-prod` does not exist | `code: none` (git grep, 10:01-10:03) | pending batch | pending |
| Scale-in policy `paymentapi-scale-in-prod` (StepScaling, -1, cooldown 300, upper bound 0) and no alarm drives it | `code: main.tf:212-230` | pending batch | pending |
| Scale-out policy `paymentapi-scale-out-prod` (+1, cooldown 300) | `code: main.tf:193-210` | pending batch | pending |
| Scalable target min 2, max 6 | `code: main.tf:189-190` | pending batch | pending |
| Service desired count 3 (`ignore_changes = [desired_count]`) | `code: envs/prod.tfvars:11`, `code: main.tf:93-95` | pending batch | pending |
| Cluster and service names `paymentapi-cluster-prod`, `paymentapi-svc-prod` (the alarm's dimensions) | `code: main.tf:9,72` | pending batch | pending |
| SNS topic `paymentapi-alerts-prod` exists | `code: main.tf:174-175` | drift check (refresh-only) | pending |

### Live verification batch

**Skill message shown to the operator (10:14):**

> **Live verification batch (read-only, Step 1).** Target: AWS account from `envs/prod.tfvars` (333333333333), region `ap-southeast-1`. I will run these, each shown here:
> 1. `aws sts get-caller-identity` (target check, Constraint 10)
> 2. `terraform init -input=false` (needed before the drift plan; it may update `.terraform.lock.hcl`)
> 3. `terraform plan -refresh-only -var-file=envs/prod.tfvars` (drift check, never applied)
> 4. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{desired:desiredCount,running:runningCount,pending:pendingCount}'`
> 5. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,ActionsEnabled:ActionsEnabled,Cmp:ComparisonOperator,Threshold:Threshold,Period:Period,Eval:EvaluationPeriods,Stat:Statistic,Metric:MetricName,Dims:Dimensions,AlarmActions:AlarmActions,OKActions:OKActions}'`
> 6. `aws application-autoscaling describe-scalable-targets --service-namespace ecs --resource-ids service/paymentapi-cluster-prod/paymentapi-svc-prod --region ap-southeast-1 --query 'ScalableTargets[].{min:MinCapacity,max:MaxCapacity,scaleInSuspended:SuspendedState.DynamicScalingInSuspended}'`
> 7. `aws application-autoscaling describe-scaling-policies --service-namespace ecs --resource-id service/paymentapi-cluster-prod/paymentapi-svc-prod --region ap-southeast-1 --query 'ScalingPolicies[].{name:PolicyName,arn:PolicyARN,steps:StepScalingPolicyConfiguration.StepAdjustments,cooldown:StepScalingPolicyConfiguration.Cooldown,alarms:Alarms[].AlarmName}'`
> Approve the batch, pick a subset, or decline (declined rows become `code-only — not live-verified`).

*Note (ambiguity).* (a) SKILL.md:165 says the batch comes "from `examples/aws.md` / `examples/kubernetes.md`, plus the tool's own drift check". `examples/aws.md` has no Application Auto Scaling or SNS reads, and no Terraform init line for Step 1. Commands 6 and 7 are added because the evidence table needs the scale-in policy's live state (no alarm driving it) and the min/max floor. Command 2 is added because a refresh-only plan needs an initialised working directory; SKILL.md:307 puts `init` in 4a only. (b) No `kubectl`/Helm commands: not a Kubernetes change.

**STOP 2 — read batch.** Operator answer (10:19), from `operator-script.md` "Step 1 read batch (the live verification batch): approve every command shown."

```
$ aws sts get-caller-identity                                         [10:19]  canned/identity-prod.json
{"UserId": "AROAEXAMPLEPROOPR:operator", "Account": "333333333333",
 "Arn": "arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator"}
$ terraform init -input=false                                         [10:20]  canned/terraform-init.txt
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v5.74.0
Terraform has been successfully initialized!
$ terraform plan -refresh-only -var-file=envs/prod.tfvars             [10:21]  canned/plan-refresh-only-prod.txt
No changes. Your infrastructure still matches the configuration.
Terraform has checked that the real remote objects still match the result of your most recent changes, and found no differences.
$ aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --query '...'   [10:22]  canned/ecs-describe-services-prod.json (query applied)
[{"desired": 3, "running": 3, "pending": 0}]
$ aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --query '...'   [10:23]  canned/alarms-prefix-prod.json (INDEX: before the new alarm exists; query applied)
[{"Name": "paymentapi-cpu-high-prod", "State": "OK", "ActionsEnabled": true,
  "Cmp": "GreaterThanThreshold", "Threshold": 70.0, "Period": 300, "Eval": 3, "Stat": "Average",
  "Metric": "CPUUtilization",
  "Dims": [{"Name": "ClusterName", "Value": "paymentapi-cluster-prod"}, {"Name": "ServiceName", "Value": "paymentapi-svc-prod"}],
  "AlarmActions": ["arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod",
                   "arn:aws:autoscaling:ap-southeast-1:333333333333:scalingPolicy:5b1f6a1e-...:policyName/paymentapi-scale-out-prod"],
  "OKActions": ["arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod"]}]
$ aws application-autoscaling describe-scalable-targets --service-namespace ecs --resource-ids service/paymentapi-cluster-prod/paymentapi-svc-prod --query '...'   [10:24]  canned/appautoscaling-targets-prod.json (query applied)
[{"min": 2, "max": 6, "scaleInSuspended": false}]
$ aws application-autoscaling describe-scaling-policies --service-namespace ecs --resource-id service/paymentapi-cluster-prod/paymentapi-svc-prod --query '...'   [10:25]  canned/appautoscaling-policies-prod.json (query applied)
[{"name": "paymentapi-scale-out-prod", "arn": "arn:aws:autoscaling:...:scalingPolicy:5b1f6a1e-...:policyName/paymentapi-scale-out-prod",
  "steps": [{"MetricIntervalLowerBound": 0.0, "ScalingAdjustment": 1}], "cooldown": 300, "alarms": ["paymentapi-cpu-high-prod"]},
 {"name": "paymentapi-scale-in-prod", "arn": "arn:aws:autoscaling:ap-southeast-1:333333333333:scalingPolicy:7d3e5a90-4b1c-4f6e-8a2d-9c0b1e2f3a44:resource/ecs/service/paymentapi-cluster-prod/paymentapi-svc-prod:policyName/paymentapi-scale-in-prod",
  "steps": [{"MetricIntervalUpperBound": 0.0, "ScalingAdjustment": -1}], "cooldown": 300, "alarms": []}]
```

Batch queries are cited later as `live:S1-1` to `live:S1-7`. `terraform init` changed nothing (lock file reused).

### Evidence table, completed

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| `paymentapi-cpu-high-prod` config | `code: main.tf:234-260` | `live: S1-5 (10:23)` same threshold, periods, dims, actions; state OK, `ActionsEnabled` true | match |
| `paymentapi-cpu-low-prod` does not exist | `code: none` | `live: S1-5 (10:23)` lists only `paymentapi-cpu-high-prod` | match (nothing live either) |
| Scale-in policy: -1, cooldown 300, no alarm | `code: main.tf:212-230` | `live: S1-7 (10:25)` same step and cooldown, `alarms: []` | match |
| Scale-out policy: +1, cooldown 300 | `code: main.tf:193-210` | `live: S1-7 (10:25)` same; alarms `[paymentapi-cpu-high-prod]` | match |
| Scalable target min 2, max 6 | `code: main.tf:189-190` | `live: S1-6 (10:24)` min 2, max 6, scale-in not suspended | match |
| Desired count 3 | `code: envs/prod.tfvars:11` | `live: S1-4 (10:22)` desired 3, running 3, pending 0 | match |
| Cluster/service names | `code: main.tf:9,72` | `live: S1-4 (10:22)` the service `paymentapi-svc-prod` in `paymentapi-cluster-prod` was found (desired and running returned); the resource id read in `S1-6` / `S1-7` is the same | match |
| SNS topic exists | `code: main.tf:174-175` | `live: S1-3 (10:21)` refresh-only: no changes, so the topic in state matches the code | match |

Drift rows: 0. Unverified rows: 0. Gaps: the threshold value is not in the request (see plan). Resource ownership check: no `import`, so not applicable.

### Research summary (informational, not a gate; SKILL.md:171-182)

> **Change requested:** Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one.
> **Service:** `paymentapi` / **Instance:** none (one environment, prod)
> **IaC tool(s):** Terraform (`code: providers.tf:1-10`) · **Delivery model:** CI applies on merge (`operator-stated`, nothing in the repo) · **Env selection:** `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1-3`, `code: providers.tf:12-13`)
> **Target:** account `333333333333` / region `ap-southeast-1` (from `aws sts get-caller-identity` at 10:19 and `envs/prod.tfvars:2-3`) / no kube context
> **Catalog used:** none — proceeding without catalog (consider running service-discovery first for a more complete picture)
> **Duplicate check:** not done — `code:` no hit for `cpu-low` / `cpu_low`; `git:` no history hit; no branch, no open PR
> **Evidence table:** above — drift rows: 0, unverified rows: 0
> **Gaps remaining:** none besides the alarm threshold, which the request does not give

---

## Step 2 — Plan

```
$ git branch --show-current            [10:26]  canned/git-branch.txt
main
$ git status --short                   [10:27]  canned/git-status-clean.txt (short form prints nothing)
(no output)
$ git branch -a                        [10:28]  canned/git-branches.txt
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
$ git rev-parse --short origin/main    [10:29]  canned/git-rev-parse.txt
a1b2c3d
```

Default branch is `main` (`origin/HEAD -> origin/main`). Branch name: no ticket and no branch pattern in the repo (only `main`), so the fallback `iac-change/<service>-<short-description>` gives `iac-change/paymentapi-add-cpu-low-alarm`. Uncommitted changes outside the plan: none.

Documentation lookups for claims that drive the disruption and rollback fields (SKILL.md:31, 200):

```
docs lookup: "an alarm action can be an Application Auto Scaling policy"       [10:30]  canned/docs.md entry 1
  URL: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html
  date read: 2026-11-09
  sentence relied on (paraphrase): Step scaling policies are triggered by CloudWatch alarms: when the alarm breaches, Application Auto Scaling changes the scalable target's capacity by the policy's step adjustment, within the target's minimum and maximum capacity.
docs lookup: "cooldown on a step scaling policy"                                [10:31]  canned/docs.md entry 2
  same URL, date read: 2026-11-09
  sentence relied on (paraphrase): The cooldown period of a step scaling policy limits how soon the policy can scale again after a scaling activity.
```

Execution path: Step 1 found CI-applies-on-merge, so only the PR path is offered (SKILL.md:208).

Plan self-check (SKILL.md:212-218): 1 pass (every item cites evidence; the threshold is a design choice, marked as a proposal), 2 pass (no deletes), 3 pass, 4 pass (no drift rows), 5 pass (PR only), 6 pass. 6/6.

*Note (ambiguity).* The request gives no threshold. The old skill has no step that asks for missing alarm parameters, so the plan proposes the values (threshold 20, same periods as CPU-high) and the operator approves or corrects them at GATE 1. The script's "Alarm details, if asked" entry (threshold 20 percent, 3 periods of 5 minutes) was therefore not needed as a separate answer; its values are what the plan proposes and what the canned plan contains.

**Skill message shown to the operator (10:32):**

> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset). The execution record goes to `.culiops/iac-change-execution/`, the pre-flight record to `.culiops/pre-flight/`.
>
> **Change plan for `paymentapi` / (prod):**
>
> **Phase 1 of 1: Add the CPU-low alarm that drives the existing scale-in policy**
> - Files: `main.tf` (modify: new resource appended after `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`, which ends at main.tf:260)
> - Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` (alarm `paymentapi-cpu-low-prod`). 1 to add, 0 to change, 0 to destroy. No other file changes (`envs/prod.tfvars` untouched).
> - Alarm values, mirroring CPU-high (`code: main.tf:234-260`): metric `CPUUtilization`, namespace `AWS/ECS`, dims `ClusterName` and `ServiceName` of the cluster and service resources, statistic `Average`, period 300, evaluation periods 3, `LessThanThreshold`. **Threshold 20 is my proposal: the request gives no number.** `alarm_actions` = SNS alerts topic + `aws_appautoscaling_policy.paymentapi_scale_in.arn`; `ok_actions` = SNS alerts topic; tags as CPU-high.
> - Blast radius: the new alarm only. Once it fires it triggers the existing `paymentapi-scale-in-prod` (-1 task, cooldown 300 s; `code: main.tf:212-230`, `live: S1-7`). The scale-in cannot go below `min_capacity` 2 (`code: main.tf:189`, `live: S1-6`; `docs: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html`, read 2026-11-09). Live desired count is 3 (`live: S1-4`), so at most one task is removed. The scale-out policy and the CPU-high alarm are unchanged.
> - Disruption: **none at apply** (create only; Step 4a confirms with the plan). After the alarm fires, capacity drops by one task (3 to 2). Cooldown limits it to one step per 300 s (`docs:` same page, read 2026-11-09). What in-flight requests see when ECS stops a task is not established (no documentation read): `UNVERIFIED`.
> - Rollback path: reversible. `git revert` of the PR, then CI plans and applies, which deletes the alarm. Not undone by a revert: a scale-in that already happened (desired count is under `ignore_changes`, `code: main.tf:93-95`; the CPU-high alarm re-grows it). Untested.
> - Evidence: evidence-table rows 1-8 above.
> - Success criteria (run after CI applies): `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-low-prod --query 'MetricAlarms[].{n:AlarmName,s:StateValue,a:ActionsEnabled,act:AlarmActions}'` returns the alarm, `a` true, `act` containing the SNS topic and `...policyName/paymentapi-scale-in-prod`, `s` OK or INSUFFICIENT_DATA; `aws application-autoscaling describe-scaling-policies ... --query "ScalingPolicies[?PolicyName=='paymentapi-scale-in-prod'].Alarms[].AlarmName"` returns `["paymentapi-cpu-low-prod"]`; `terraform plan -var-file=envs/prod.tfvars` reports no changes.
>
> **Execution path:** PR. After merge the CI pipeline applies it (`operator-stated`). Direct apply is not offered: CI applies on merge.
> **Branch:** current `main` → `iac-change/paymentapi-add-cpu-low-alarm` from `origin/main` @ `a1b2c3d` (`git fetch origin main`, then `git switch -c`)
> **Self-check:** 6/6 pass
>
> **Approve this plan?**

**STOP 3 — GATE 1.** Operator answer (10:37), from `operator-script.md` "GATE 1 (the plan): approve. Execution path: PR." Operator approves the plan including threshold 20 and picks the PR path.

---

## Step 3 — Implement

Branch commands approved at GATE 1:

```
$ git fetch origin main                                                  [10:37]  canned/empty.txt
(no output)
$ git switch -c iac-change/paymentapi-add-cpu-low-alarm origin/main      [10:38]  canned/git-switch.txt
Switched to a new branch 'iac-change/paymentapi-add-cpu-low-alarm'
$ git branch --show-current                                              [10:39]  canned/git-branch.txt says `main` (INDEX: always)
iac-change/paymentapi-add-cpu-low-alarm
```

*Note.* `git-branch.txt` is `main` and the INDEX says "always". After the simulated `git switch -c` the protocol's State rule says to follow what has already happened, so the answer is the new branch. With a literal `main` the skill would hit its own red flag (SKILL.md:64) and the run could not continue.

Code written (the skill appends the resource after `paymentapi_cpu_high`, same layout, label and naming pattern as `code: main.tf:232-260`):

```diff
--- a/main.tf
+++ b/main.tf
@@ -258,3 +258,33 @@ resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_high" {
     Environment = var.env
   }
 }
+
+# ── CloudWatch alarm (CPU low, scales in) ─────────────────────────────────────
+
+resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_low" {
+  alarm_name          = "paymentapi-cpu-low-${var.env}"
+  comparison_operator = "LessThanThreshold"
+  evaluation_periods  = 3
+  metric_name         = "CPUUtilization"
+  namespace           = "AWS/ECS"
+  period              = 300
+  statistic           = "Average"
+  threshold           = 20
+  alarm_description   = "CPU utilization below 20% for paymentapi ${var.env}"
+
+  dimensions = {
+    ClusterName = aws_ecs_cluster.paymentapi.name
+    ServiceName = aws_ecs_service.paymentapi.name
+  }
+
+  alarm_actions = [
+    aws_sns_topic.paymentapi_alerts.arn,
+    aws_appautoscaling_policy.paymentapi_scale_in.arn,
+  ]
+  ok_actions = [aws_sns_topic.paymentapi_alerts.arn]
+
+  tags = {
+    Service     = "paymentapi"
+    Environment = var.env
+  }
+}
```

Canned plan versus code: the canned plan (`canned/plan-prod.txt:6-43`) matches this code (alarm name, `LessThanThreshold`, threshold 20, 3 x 300 s, both alarm actions, `ok_actions`, tags, description, default `treat_missing_data = "missing"`). The scale-in policy ARN in the plan (plan:11) equals the live ARN from `live: S1-7`. No difference to note.

Formatter (shown before running, local, on the changed file only; SKILL.md:287):

```
$ terraform fmt main.tf     [10:40]  canned/empty.txt
(no output: already formatted)
```

Self-check of the diff (SKILL.md:257-265), after `git status --short` and `git diff` answered from the diff above:

```
$ git status --short        [10:41]  derived from the diff (protocol rule 5)
 M main.tf
$ git diff                  [10:42]  the diff above
```

1. Scope: pass (`main.tf` only, which is the plan's file list). 2. Plan ↔ hunk: pass (add alarm → the one hunk). 3. Conventions: pass (names, tags and layout copy `code: main.tf:234-260`). 4. No silent safety changes: pass. 5. No secrets: pass (no `tfplan`, state or `.terraform/` in the working-tree changes; `git status --short` shows only `main.tf`). 6. Formatted: pass. 6/6.

Fresh eyes (SKILL.md:267-268): the skip rule holds. The phase is add-only, and it touches none of the listed types (access control, network exposure, DNS, data stores, secrets/KMS, deletion-protection or lifecycle). The skill names "adding an alarm" as its example. The alarm's action scales the service, but scaling is not on the skip rule's list. Result: `skipped — add-only, no sensitive types`. No reviewer dispatched.

**Skill message shown to the operator (10:43):**

> **Code changes for Phase 1 of 1:**
>
> **Modified:** `main.tf` — adds `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` (`paymentapi-cpu-low-prod`, below 20% for 3 x 5 min), actions: alerts topic + `paymentapi_scale_in`; same layout as CPU-high.
>
> **Plan ↔ hunk:** add alarm → `main.tf:261-290` (one hunk, 30 added lines, 0 removed)
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped — add-only, no sensitive types
>
> Full diff is in your working tree (`git diff` to review).
> **Approve these changes?**

**STOP 4 — GATE 2.** Operator answer (10:48), from `operator-script.md` "GATE 2 (the code): approve."

---

## Step 4 — Execute

### 4a: Generate plan output

Target re-read before the check (the same command as in the approved batch; the prompt shows its result):

```
$ aws sts get-caller-identity     [10:48]  canned/identity-prod.json
{"UserId": "AROAEXAMPLEPROOPR:operator", "Account": "333333333333",
 "Arn": "arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator"}
```

**Skill message shown to the operator (10:49):**

> **Target check:** `aws sts get-caller-identity` → account `333333333333`, role `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` · region `ap-southeast-1` (`envs/prod.tfvars:2`) · no kube context · Terraform var-file `envs/prod.tfvars` (no workspace, no backend key declared)
> **Plan is for:** `prod` — **match: yes** (account equals `aws_account_id` in `envs/prod.tfvars:3`; `providers.tf:16` also makes Terraform refuse another account)
> About to run: `terraform init` — already ran at 10:20 in the Step 1 batch, not repeated — then `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above; `tfplan` stays local). **Proceed?**

**STOP 5 — 4a target check.** Operator answer (10:54), from `operator-script.md` "4a target check (`Proceed?`): yes."

```
$ terraform plan -out=tfplan -var-file=envs/prod.tfvars     [10:54]  canned/plan-prod.txt   (INDEX: before the simulated apply)
```

Plan output as shown to the operator (informational; the same text as `canned/plan-prod.txt`): one resource, `aws_cloudwatch_metric_alarm.paymentapi_cpu_low will be created` (plan:6-41), ending `Plan: 1 to add, 0 to change, 0 to destroy.` (plan:43).

Cross-check against the evidence table (SKILL.md:313): the one resource is in the approved phase; action `create` matches disruption `none`; no replace, no destroy, no drift picked up by refresh. Nothing goes back to the operator. `tfplan` stays local (Constraint 11).

### 4b: Pre-flight gate

Reusable record check in `.culiops/pre-flight/`: the directory does not exist in the fixture, so no record matches.

```
$ terraform show -no-color tfplan                           [10:55]  canned/plan-prod.txt
(plan text as above, written to a scratch file outside the repo)
$ sha256sum <scratch file holding the plan text>            [10:56]  INDEX "Plan hashes": plan-prod.txt
b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0  <scratch file>
```

Plan hash: `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0`. No match, so pre-flight is invoked inline, passing: the plan output, the target check, the delivery model (CI applies on merge, `operator-stated`), the evidence table (no drift, no unverified, no `code-only` rows) and the plan hash (SKILL.md:332).

---

## Pre-flight (inline, old v0.17.0 text)

### Step 1 — detect, target, plan hash, assessor

Input is a Terraform plan (`Plan:` summary line present), not CloudFormation/Serverless/CDK/Pulumi/Bicep/GCP/Azure. Assessors loaded: `iac-change` only (`assessors/README.md` lists one). Matched: `iac-change`.

Target: AWS account 333333333333 / region ap-southeast-1; Terraform var-file `envs/prod.tfvars`; no workspace; no backend key declared. Delivery model: CI applies on merge (`operator-stated`, caller's citation kept). Plan hash: passed by the caller, `sha256:b59dde28...25116b0` (no re-hash). Output root `.culiops/` at the repo root.

**Skill message shown to the operator (10:57):**

> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset); the pre-flight record goes to `.culiops/pre-flight/`.
> I detected this as a **Terraform plan** change (assessor `iac-change`) affecting **1 resource** (create `aws_cloudwatch_metric_alarm.paymentapi_cpu_low`) in **account 333333333333 / ap-southeast-1 / var-file `envs/prod.tfvars`**, delivered by **CI after merge** (`operator-stated`). Plan hash `sha256:b59dde28...25116b0`. Is this correct?

**STOP 6 — pre-flight GATE 1.** Operator answer (11:02), from `operator-script.md` "Pre-flight GATE 1 (scope and target): confirm."

### Step 2 — L1 static analysis

Plan hygiene: plan made by the skill with `-var-file=envs/prod.tfvars` only, no `-target`, no `-refresh=false`; no "Objects have changed outside of Terraform" block; refresh-only at 10:21 found no drift; no unexpected resources.

```
$ git log --since=7.days --oneline origin/main -- main.tf     [11:02]  canned/empty.txt   (INDEX: git log * --since=*)
(no output: no commit touched main.tf in 7 days)
$ git status --short                                          [11:03]  derived from the diff
 M main.tf
$ gh pr list --state open                                     [11:04]  canned/gh-pr-list-empty.txt
no pull requests match your search in acme/paymentapi-infra
$ git rev-parse --short HEAD                                  [11:05]  canned/git-rev-parse.txt
a1b2c3d
```

Reading against `origin/main` excludes this change's own commits (none yet); the only uncommitted change is this change's own edit. Preliminary L1 scores: 1 Yellow (adds an automatic capacity-reducing trigger), 2 Green (create only), 3 Green, 4 ⚪ (no catalog; the alarm scales, so it is app-facing and the not-app-facing exception does not apply: assessor Dependency impact), 7 Yellow, 8 Green pending the price lookup, 9 Green. App-compatibility: `alarm_actions` carries an Application Auto Scaling policy ARN (plan:11), so the alarm is app-facing (assessor list: an alarm that scales is app-facing), category 11 triggered, Q8 needed.

### Step 3 — L2

**Skill message shown to the operator (11:06):**

> **Pre-flight context check:**
> 1. Is there an active incident affecting this service or its dependencies? (yes/no)
> 2. Is there a deploy freeze or change window restriction? (yes/no)
> 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure — with CI delivery the apply happens at merge, not now)
> 4. Have you changed this service before? (many times / a few times / first time)
> 5. Have you used this IaC tool before? (experienced / some experience / first time)
> 6. What's the expected cost impact? (negligible / moderate / significant / unknown)
> 7. Any other context I should know? (free text, optional)
> 8. This change touches what the app depends on: the alarm's action now drives an Application Auto Scaling policy (scale-in of the ECS service). Where is the application source? (a) a local checkout, give the path; (b) a GitHub repo through `gh`, give `owner/repo` and the deployed ref; (c) not available.

**STOP 7 — pre-flight L2.** Operator answer (11:11), from `operator-script.md` "Pre-flight L2 questions": Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8=(c) the application source is not available.

Recorded: Q1, Q2, Q4, Q5 as `operator`; Q3 and Q6 as `operator-stated` (L3 may corroborate); Q8 (c) → category 11 is ⚪. Step 3b (app-source scan) is skipped: no source.

**Skill message shown to the operator (11:11)**, the assessor-specific questions (`assessors/iac-change.md` `## L2 — Context Questions`, asked after the standard 7):

> **iac-change questions.** I filled in what the repo and this session already show; correct me if wrong.
> 1. Have you run the plan/diff command and reviewed the output? (yes/no) — proposed: yes, the skill ran it at 10:54 and showed it, hash `b59dde28...25116b0`.
> 2. How is this change delivered: CI/CD pipeline, GitOps controller, or manual apply? — proposed: CI pipeline applies on merge (your Step 1 answer, `operator-stated`).
> 3. Was the plan made with `-target`, `-refresh=false`, or a non-default workspace / var-file? (yes/no/unsure) — proposed: no (`terraform plan -out=tfplan -var-file=envs/prod.tfvars`, the repo's only var-file).
> 4. Has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure) — proposed: unsure (no CI history or backend config in the repo to check it against).

**STOP 8 — unscripted.** The script has no entry for these four questions, except that question 2 matches "Delivery-model question: a CI pipeline applies on merge". Operator answer (11:16), by the protocol's unscripted rule: "approve / yes / as proposed". Recorded: Q1 yes, Q2 CI applies on merge (`operator-stated`), Q3 no, Q4 unsure (`operator-stated`).

*Note (ambiguity).* pre-flight SKILL.md:108 ("Those are asked after the standard 7") and :265 ("Then ask any assessor-specific questions") read as a separate prompt after the standard batch; Q8 is the only item the text puts "in the same batch" (:106). Taken as a second prompt, so a second stop. The skip rule at :104 and :263 is stated for the standard questions; here the assessor questions are still asked, with pre-filled answers.

### Step 4 — L3 opt-in

**Skill message shown to the operator (11:16):**

> I can check live system health with read-only queries if you have CLI access. Without it, resource health stays ⚪ and the best possible verdict is YELLOW. Commands I'd run (the target check first; anything the iac-change-execution evidence table already answered is left out):
> 1. `aws sts get-caller-identity --query Account --output text` (target check, must equal 333333333333)
> 2. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].events[:10].{at:createdAt,msg:message}'`
> 3. `aws ecs describe-services ... --query 'services[].{deploy:deploymentConfiguration,deployments:deployments[].{status:status,rollout:rolloutState,created:createdAt}}'`
> 4. `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --start-time {T-1h} --end-time {now} --period 300 --statistics Average Maximum --region ap-southeast-1`
> 5. the same with `--metric-name MemoryUtilization`
> 6. `aws elbv2 describe-target-groups --names paymentapi-tg-prod --region ap-southeast-1` (names the load balancer)
> 7. `aws elbv2 describe-load-balancers --load-balancer-arns <ALB ARN from 6> --region ap-southeast-1`
> 8. `aws elbv2 describe-target-health --target-group-arn <TG ARN> --region ap-southeast-1`
> 9. `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count --dimensions Name=LoadBalancer,Value=app/paymentapi-alb-prod/50dc6c495c0c9188 --start-time {T-1h} --end-time {now} --period 300 --statistics Sum --region ap-southeast-1`
> 10. the same with `--metric-name TargetResponseTime --statistics Average`
> 11. the same with `--metric-name RequestCount --statistics Sum` (last hour)
> 12. the same `RequestCount` call for the same hour one week ago (`{T-7d}` window; the baseline)
> 13. `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,ns:Namespace,metric:MetricName,dims:Dimensions},composite:CompositeAlarms[].AlarmName}'`
> 14. `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> 15. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod --history-item-type StateUpdate --start-date {T-24h} --end-date {now} --region ap-southeast-1`
> 16. `aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/paymentapi-cluster-prod/paymentapi-svc-prod --region ap-southeast-1`
> 17. `aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1` (current alarm price, with the lookup date)
> Run them? (yes/no)

**STOP 9 — pre-flight L3 opt-in.** Operator answer (11:21), from `operator-script.md` "Pre-flight L3 opt-in: yes."

*Note.* Left out on purpose: `terraform state pull`, `aws ecs describe-task-definition` (returns environment values), and an S3 `head-object` for the last apply (no backend bucket or key in the repo, so no command can be built; the last-apply age stays unverified).

```
live:1   $ aws sts get-caller-identity --query Account --output text      [11:21]  canned/identity-prod.json (query applied)
333333333333                                  → equals the plan's account, L3 continues
live:2   $ aws ecs describe-services ... events[:10]                       [11:22]  canned/ecs-describe-services-prod.json
[[{"at": "2026-11-09T01:12:40.317000+00:00", "msg": "(service paymentapi-svc-prod) has reached a steady state."}]]
live:3   $ aws ecs describe-services ... deploy + deployments              [11:23]  canned/ecs-describe-services-prod.json
[{"deploy": {"deploymentCircuitBreaker": {"enable": false, "rollback": false}, "maximumPercent": 200, "minimumHealthyPercent": 100},
  "deployments": [{"status": "PRIMARY", "rollout": "COMPLETED", "created": "2026-10-12T14:02:11.221000+00:00"}]}]
live:4   $ aws cloudwatch get-metric-statistics ... CPUUtilization         [11:24]  canned/metric-cpu-prod.json
12 datapoints (5 min): Average 37.2 to 42.8 (mean 39.8), Maximum up to 52.8
live:5   $ aws cloudwatch get-metric-statistics ... MemoryUtilization      [11:25]  canned/metric-memory-prod.json
12 datapoints: Average 52 to 56 (mean 53.8), Maximum up to 66
live:6   $ aws elbv2 describe-target-groups --names paymentapi-tg-prod     [11:26]  canned/tg-describe-prod.json
TargetGroupArn ...targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09; LoadBalancerArns [...loadbalancer/app/paymentapi-alb-prod/50dc6c495c0c9188]; health check /healthz
live:7   $ aws elbv2 describe-load-balancers --load-balancer-arns ...paymentapi-alb-prod...   [11:27]  canned/lb-describe-prod.json
paymentapi-alb-prod, Scheme internal, State active, Type application
live:8   $ aws elbv2 describe-target-health --target-group-arn ...paymentapi-tg-prod...      [11:28]  canned/tg-health-prod.json
3 targets, all healthy (ap-southeast-1a x2, ap-southeast-1b x1)
live:9   $ aws cloudwatch get-metric-statistics ... HTTPCode_Target_5XX_Count (Sum)   [11:29]  canned/metric-alb-5xx-prod.json
12 datapoints, Sum 0 in every window
live:10  $ aws cloudwatch get-metric-statistics ... TargetResponseTime (Average)      [11:30]  canned/metric-alb-latency-prod.json
12 datapoints, Average 0.036 to 0.040 s
live:11  $ aws cloudwatch get-metric-statistics ... RequestCount, last hour           [11:31]  canned/metric-alb-requests-prod.json
12 datapoints, Sum total 41,442
live:12  $ aws cloudwatch get-metric-statistics ... RequestCount, same hour a week ago [11:32] canned/metric-alb-requests-prod.json (INDEX: the same file)
12 datapoints, Sum total 41,442  → ratio to last hour 1.00 (below the 1.5x peak threshold)
live:13  $ aws cloudwatch describe-alarms --state-value ALARM ...                   [11:33]  canned/alarms-firing-prod.json
{"metric": [], "composite": []}               → nothing firing
live:14  $ aws cloudwatch describe-alarms-for-metric ... CPUUtilization             [11:34]  canned/alarms-for-metric-cpu-prod.json (INDEX: before the new alarm exists)
[{"name": "paymentapi-cpu-high-prod", "state": "OK", "actionsEnabled": true}]
live:15  $ aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod ...   [11:35]  canned/alarm-history-prod.json
2026-11-08 09:03Z ALARM to OK; 2026-11-08 08:48Z OK to ALARM; 2026-11-05 05:17Z ALARM to OK; 2026-11-05 05:02Z OK to ALARM
live:16  $ aws application-autoscaling describe-scaling-activities ...              [11:36]  canned/appautoscaling-activities-prod.json
2026-11-08 08:49Z: set desired count to 3, caused by alarm paymentapi-cpu-high-prod via paymentapi-scale-out-prod, Successful
live:17  $ aws pricing get-products ... AmazonCloudWatch                             [11:37]  canned/pricing-cloudwatch-alarm.json
Standard alarm, ap-southeast-1: 0.10 USD per alarm metric month (standard resolution); price list publication 2026-10-07; looked up 2026-11-09
```

No query failed; no raw environment values or secrets were fetched.

### Step 5 and 5b — score and verify

Scorecard before presentation (full text is in `preflight-record.md`):

| # | Category | Score | Evidence |
|---|---|---|---|
| 1 | Blast radius | Yellow | plan:6-7,43; code:main.tf:212-230; live:S1-6,S1-7,3,8; docs: step scaling within min/max |
| 2 | Reversibility | Green | plan:6,43; code:main.tf:93-95 |
| 3 | Change velocity | Green | git log 0 commits in 7 days; no open PR; live:3 (last deployment 2026-10-12) |
| 4 | Dependency impact | ⚪ | no catalog; assessor Dependency impact (app-facing alarm, exception not met) |
| 5 | Timing context | Green | operator Q1-Q2; operator-stated Q3 corroborated by live:11-12 and live:13 |
| 6 | Operator familiarity | Green | operator Q4-Q5 |
| 7 | Observability readiness | Yellow | code:main.tf:234-260; live:14; static-threshold ladder |
| 8 | Cost impact | Green | live:17 (0.10 USD per alarm-month, looked up 2026-11-09); operator-stated Q6 |
| 9 | Security posture | Green | plan:6-41 |
| 10 | Resource health | Green | live:13,4,5,9,10,8,2; S1-4 |
| 11 | Application compatibility | ⚪ | plan:11; operator Q8 (c) |

Verdict arithmetic: Red = none; Yellow + ⚪ = 4 (categories 1, 4, 7, 11), at or above 3, so the multi-Yellow escalation applies: **RED — soft block**. Hard-block conditions checked: category 2 (irreversible data change: none), 5 (incident plus freeze: Q1 and Q2 are no), 9 (public exposure, encryption removal, secrets: none in plan:6-41), 10 (error budget exhausted: no SLO declared, nothing firing). No hard block.

Step 5b: citations re-opened for the Green categories 2, 9 and 10 and for each mitigation premise (min_capacity 2 at main.tf:189 and `live: S1-6`; the TG health result; the alarm's `ActionsEnabled`; the price). All say what the findings say; no fix needed. Source conflicts: none. Fresh eyes: **not required** (verdict RED — soft block; pre-flight SKILL.md:315), so no reviewer would be dispatched. Not verified: listed in the record.

### Step 6 — report and GATE 2

**Skill message shown to the operator (11:38):**

> **Pre-flight verdict: RED — soft block.** No single category is Red. The block is the multi-Yellow escalation: 4 of 11 categories are Yellow or unknown (3 or more escalates). Nothing is a hard block.
>
> | # | Category | Score | Finding | Evidence |
> |---|---|---|---|---|
> | 1 | Blast radius | Yellow | One resource added, but its action is the scale-in policy: once it fires, desired count drops from 3 to the floor of 2 (-33% capacity). Softened by min_capacity 2, 3 healthy targets in two AZs, 100% minimum healthy. | plan:6-7,43; code:main.tf:212-230; live:S1-6,S1-7,3,8; docs: step-scaling page, read 2026-11-09 |
> | 2 | Reversibility | Green | Create only; revert the PR and CI deletes the alarm. | plan:6,43; code:main.tf:93-95 |
> | 3 | Change velocity | Green | 0 commits to main.tf in 7 days; no open PR. | git log; gh pr list; live:3 |
> | 4 | Dependency impact | ⚪ | No catalog, and the alarm scales the service so the not-app-facing exception does not apply. | assessor: Dependency impact |
> | 5 | Timing context | Green | No incident, no freeze, not peak (41,442 requests/hour, 1.00x the same hour last week). | operator; live:11,12,13 |
> | 6 | Operator familiarity | Green | Many changes, experienced with Terraform. | operator |
> | 7 | Observability readiness | Yellow | The CPU-high alarm is live and enabled, but static CPU thresholds are the only alarm on the service; no SLO, no 5xx or healthy-host alarm. | code:main.tf:234-260; live:14 |
> | 8 | Cost impact | Green | One standard alarm, 0.10 USD per month (looked up 2026-11-09). | live:17 |
> | 9 | Security posture | Green | No IAM, network, encryption or public-access change. | plan:6-41 |
> | 10 | Resource health | Green | Nothing firing; CPU max 52.8%, memory max 66%; 3 of 3 targets healthy; 5xx sum 0; steady state. CPU-high fired 2026-11-08 08:48Z to 09:03Z and scaled out to 3, now OK. | live:13,4,5,8,9,10,2,15,16 |
> | 11 | Application compatibility | ⚪ | Triggered (the alarm's action scales the service); no app source (Q8 c). | plan:11; operator |
>
> **Drift:** none. **Not verified:** the threshold value 20 (a proposal approved at GATE 1); what in-flight requests see when ECS stops a task on scale-in (no documentation read); time of the merge and who is on hand then; last successful apply (no backend or CI history); delivery model and Q4 (`operator-stated`); how the app behaves with 2 tasks instead of 3 (no source).
> **Verification:** citations checked 12 in Green categories plus 4 mitigation premises, fixed: none · verdict working: Red = none, Yellow + ⚪ = 4 (1, 4, 7, 11), hard blocks checked: none → RED soft block · fresh eyes: not required (verdict RED — soft block).
>
> **Mitigations**
> - Cat 1: confirm that 2 tasks is an acceptable floor at peak (operator action); after the merge, watch `describe-scaling-activities` for the first scale-in.
> - Cat 4: evidence that would resolve it: run service-discovery to build a catalog, or confirm nothing (composite alarm, dashboard, automation) will reference `paymentapi-cpu-low-prod`.
> - Cat 7: after apply, confirm the new alarm leaves `INSUFFICIENT_DATA`; consider a 5xx or healthy-host alarm so a bad scale-in is seen.
> - Cat 11: evidence that would resolve it: give the application source (a local path, or `owner/repo` and the deployed ref) to check pool sizes and task-local state at 2 tasks.
>
> **Risk decision (GATE 2).** Red soft block: acknowledge each finding with a stated reason, say which mitigations you commit to, or abort.

**STOP 10 — pre-flight GATE 2.** Operator answer (11:43), from `operator-script.md` "Pre-flight GATE 2 (risk decision): acknowledge and proceed", and entry `[H5]` (the verdict is RED, so the stop's script applies): acknowledged findings 1, 4, 7, 11 and the escalation, reason "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged". The script names no committed mitigation, so none is recorded as committed.

*Note.* There is no single Red finding here; the RED comes from the escalation, so the operator acknowledges the four contributing findings.

### Step 7 — record

Pre-flight record written (11:43) to `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1143.md`: see `preflight-record.md`. Invoked by another skill, so the record is left uncommitted and no commit is offered (pre-flight SKILL.md:341-342). Pre-flight returns the verdict RED — soft block, acknowledged.

---

## Back in iac-change-execution

### GATE 3 (11:43)

Text at SKILL.md:324-328: Green/Yellow proceed; Red soft block: "Operator must acknowledge each Red finding". The verdict is RED — soft block, so the gate asks again, although pre-flight GATE 2 just collected the same acknowledgment.

**Skill message shown to the operator (11:43):**

> **GATE 3 — pre-flight clearance.** Verdict: **RED — soft block** (4 of 11 categories Yellow or unknown; no hard block). You acknowledged the four findings (1 blast radius, 4 dependency impact, 7 observability, 11 application compatibility) at pre-flight GATE 2, reason: "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged". Record: `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1143.md`. Acknowledge each Red finding to clear execution, or abort?

**STOP 11 — GATE 3.** Operator answer (11:48), from `operator-script.md` "GATE 3 (clearance) and GATE 4 (execution): approve."

*Note (ambiguity).* SKILL.md:324-328 lists the operator action per verdict. For GREEN and YELLOW the text says only "Proceed", which would not wait. For RED soft block it says the operator must acknowledge, so it waits, in addition to pre-flight's own GATE 2. If GATE 3 and pre-flight GATE 2 were treated as one acknowledgment, the run has one stop fewer.

### 4c: Execute

`SKILL.md:336`: "Offer: draft a heads-up for the people affected ... with `change-comms` before the apply or merge."

**Skill message shown to the operator (11:48):**

> Before the merge, I can draft a heads-up for the people affected (service owners, reviewers, on-call) with `change-comms`. It is a draft only; you send it. Want one?

**STOP 12 — change-comms heads-up offer.** Operator answer (11:53), from `operator-script.md` "Optional offers (a change-comms heads-up ...): no."

PR path (the delivery model is CI-applies, so it is the only path). Pre-staging read for the PR action:

```
$ git status --short     [11:53]  derived from the diff
 M main.tf
```

*Note (ambiguity).* SKILL.md:342 shows "`git status` after staging" in the prompt, but SKILL.md:346 stages only after GATE 4, and Constraint 1 says nothing is committed or pushed before approval. The skill shows the status as it is now (unstaged `main.tf`) and the explicit list it will stage. `tfplan`, `.terraform/` and `.terraform.lock.hcl` do not appear in the canned status (answered from the diff only); they are not staged either way (explicit path only). Also, the execution record does not exist yet at this point (SKILL.md:343 wants a "record link" in the PR body, SKILL.md:399 writes it in Step 5b), so the PR body names where the record will be.

Commit style from the repo's history (`canned/git-log-recent.txt`): `paymentapi: <lowercase summary> (#PR)`; no PR template in the repo.

**Skill message shown to the operator (11:54):**

> On branch `iac-change/paymentapi-add-cpu-low-alarm` (from `origin/main`), about to stage **only** this file: `main.tf`, commit, push, and open a PR.
> `git status` now: ` M main.tf` — no `tfplan` / state / `.terraform/` / unrelated files; after staging it will read `M  main.tf`.
> Commit: `paymentapi: add CPU-low alarm wired to scale-in policy`
> PR will include: change summary, evidence table, pre-flight verdict (RED — soft block, acknowledged, reason given), and a note on where the execution record will be (local `.culiops/iac-change-execution/`, uncommitted, written after the PR is opened). No plan text, no `tfplan`.
> **Proceed?**

**STOP 13 — GATE 4.** Operator answer (11:59), from `operator-script.md` "GATE 3 (clearance) and GATE 4 (execution): approve."

```
$ git add main.tf                                                   [11:59]  canned/empty.txt
(no output)
$ git commit -m "paymentapi: add CPU-low alarm wired to scale-in policy"   [12:00]  canned/git-commit.txt
[iac-change/paymentapi-add-cpu-low-alarm 7f3a9c1] paymentapi: add CPU-low alarm wired to scale-in policy
 1 file changed, 30 insertions(+)
$ git push -u origin iac-change/paymentapi-add-cpu-low-alarm        [12:01]  canned/git-push.txt
remote: Create a pull request for 'iac-change/paymentapi-add-cpu-low-alarm' on GitHub by visiting:
remote:   https://github.com/acme/paymentapi-infra/pull/new/iac-change/paymentapi-add-cpu-low-alarm
To github.com:acme/paymentapi-infra.git
 * [new branch]      iac-change/paymentapi-add-cpu-low-alarm -> iac-change/paymentapi-add-cpu-low-alarm
$ gh pr create --title "paymentapi: add CPU-low alarm wired to scale-in policy" --body "<summary, evidence table, pre-flight verdict, record note>"   [12:02]  canned/gh-pr-create.txt
https://github.com/acme/paymentapi-infra/pull/142
```

Reported to the operator: PR https://github.com/acme/paymentapi-infra/pull/142.

---

## Step 5 — Verify and record

### 5a: Verification (PR path, delivery model CI applies on merge)

> PR https://github.com/acme/paymentapi-infra/pull/142 created. After merge, the CI pipeline applies it (`operator-stated`). I can poll the PR's checks if you want (with your approval). The apply has not landed, so the success criteria cannot be run now.

(The offer to run the success criteria applies "once the apply has landed" (SKILL.md:382); it has not, so it is not made.)

**STOP 14 — PR checks polling offer** (prompt at 12:03). Operator answer (12:08), from `operator-script.md` "Optional offers (... polling the PR checks or the sync status ...): no."

Result: no polling, no run of the success criteria. The record says `Applied: no — PR open`.

### 5b: Execution record

Written (12:08) to `.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1208.md`: see `record.md`. Preamble lists the prerequisites of `examples/aws.md` (SKILL.md:462).

**Skill message shown to the operator (12:08):**

> Execution record written to `.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1208.md`. Commit it?

**STOP 15 — GATE 5.** Operator answer (12:13), from `operator-script.md` "Optional offers (... committing the record at GATE 5): no."

**Skill message shown to the operator (12:13):**

> I can also draft the result message and a ticket-closing comment (with the PR URL) with `change-comms`. Draft only; you send them. (No ticket was given, so only the result message applies.) Want a draft?

**STOP 16 — change-comms result message offer.** Operator answer (12:18), mapped by meaning to `operator-script.md` "Optional offers ...: no." (the script's list names the heads-up, polling and the record commit; the result-message offer is the same kind).

**End of run.** The skill's final state: PR open, nothing applied, record uncommitted. Total 16 stops, 1 unscripted.

---

## Notes for the reader

- **Staging.** One environment (prod), no staging in the repo or the request; the old skill has no staging step, so none was run.
- **Identity check.** Target checked three times: Step 1 batch (10:19), 4a (10:48, account 333333333333 equals `envs/prod.tfvars:3`, match yes), and the first L3 query (11:21). All equal.
- **`no canned output`:** none. No command went unanswered. `printenv CULIOPS_HOME` was not run (not a skill command; assumed unset).
- **Ambiguities relied on:** delivery question as its own stop (SKILL.md:156); Step 1 batch contents (SKILL.md:165); GATE 3 repeats pre-flight GATE 2 for RED (SKILL.md:324-328); assessor questions as a second prompt (pre-flight SKILL.md:108, 265); fresh-eyes skip for an alarm whose action scales (SKILL.md:267-268); status "after staging" shown before staging (SKILL.md:342, 346); record link in the PR body before the record exists (SKILL.md:343, 399); result-message offer as a separate stop from the GATE 5 commit offer (SKILL.md:442-445).
- **Judgment calls in pre-flight scoring.** Category 4 is ⚪ because the assessor says "no catalog → ⚪" with one exception (a not-app-facing change), and an alarm with a scaling action is app-facing. Category 11 is ⚪ because Q8 was (c). With those two and categories 1 and 7 at Yellow, the escalation rule gives RED — soft block.
