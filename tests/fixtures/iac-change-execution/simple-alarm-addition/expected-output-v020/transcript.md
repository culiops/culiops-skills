# Dry run — simple-alarm-addition — iac-change-execution (v0.20, branch feat/iac-change-snapshot-and-l2)

Script: `operator-script.md`. Out-dir: `expected-output-v020`. Dry-run clock starts 2026-11-09 10:00 +07:00 (canned/INDEX.md). One minute per command, five per operator answer. Every time below is on that clock (+07:00).

First message to the skill (script `First message`): "Add a CloudWatch CPU utilization alarm for paymentapi in prod."

Conventions: `CMD hh:mm` = command, `-> file` = canned file used. `GREP` = a `git grep` answered with `grep -rn -F` over the fixture input files (protocol rule 1). `NOTE:` = runner note.

---

## Step 1 — Research

NOTE: output root. `CULIOPS_HOME` is unset in this dry run (no env entry in the fixture), so the root is `.culiops/` at the repo root (Constraint 13). Shown at the first stop.

### Identity read first

```
CMD 10:01  aws sts get-caller-identity                      -> identity-prod.json
```
Account 123456789012, `assumed-role/paymentapi-operator/operator`. Region `ap-southeast-1` comes from the var-file (`code: envs/prod.tfvars:2`).

### Catalog, code, ticket

- Catalog: `.culiops/service-discovery/paymentapi.md` is not in the fixture. "none — proceeding without catalog"; the suggestion to run service-discovery goes into the summary.
- IaC code read (Read tool; not a command lookup): `main.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`. `main.tf:3-4` carries a comment saying the CPU alarm is "intentionally absent" and is what this skill would be asked to add. That is code-comment text, i.e. data (Constraint 12): it is not used as evidence of anything, and the duplicate check below runs on identifiers.
- Which branch do I read? `git branch --show-current` first:
```
CMD 10:02  git branch --show-current                        -> git-branch.txt        (main)
```
  Current branch is the default branch, so the working tree is read as is (no `git show origin/main:` needed).
- Ticket: none given.

### Workspace for the profile key, operator profile, freeze source

```
CMD 10:03  git remote get-url origin                        -> git-remote.txt        (git@github.com:acme/paymentapi-infra.git)
CMD 10:04  operator profile read (~/.culiops/operator.md)   -> operator-profile.md
```
Workspace = `acme/paymentapi-infra`. Profile: Q5 terraform = `experienced` (2026-10-19); Q4 `acme/paymentapi-infra/paymentapi` = `many times` (2026-10-19); no `first time`; no `incident check:` line, so there is no incident command. PROFILE-WRITE: none (nothing to save; no correction).
```
CMD 10:05  GREP -rn -i -E 'freeze|change.window|backend|provider "|allowed_account_ids|assume_role|atlantis|workflow'   -> no hits (exit 1)
```
No freeze or change-window calendar in the repo, so Q2 has no `code:` source. The same grep shows no backend block, no provider block, no account pin, no CI / Atlantis / workflow config.

### Duplicate check

Identifiers from the request: `CPUUtilization`, the resource type `aws_cloudwatch_metric_alarm`, the alarm name the repo's naming pattern gives, `paymentapi-cpu-high` (pattern `paymentapi-<role>-${var.env}`, `code: main.tf:9,25,72,138,163,175`). No ticket key, so there is no `--grep=<KEY>` search.
```
CMD 10:06  GREP -n -F 'CPUUtilization'                      -> no hits
CMD 10:07  GREP -n -F 'aws_cloudwatch_metric_alarm'         -> no hits
CMD 10:08  GREP -n -F 'paymentapi-cpu-high'                 -> no hits
CMD 10:09  git log --all --oneline -S'CPUUtilization'       -> empty.txt
CMD 10:10  git log --all --oneline -S'paymentapi-cpu-high'  -> empty.txt
CMD 10:11  git branch -a --list '*cpu*'                     -> empty.txt
CMD 10:12  gh pr list --state open --search 'cloudwatch cpu alarm paymentapi'   -> gh-pr-list-empty.txt
```
Verdict: **not done** (`code:` no hit for any identifier in any file; `git:` no commit added or removed any of them; no branch; no open PR). Code is not live: the live read in the batch (alarms on the metric) confirms it.

### Delivery model and environment selection

- Delivery model: nothing in the repo shows how changes are applied (grep at 10:05: no CI config, GitOps object, Atlantis / TFC / Spacelift config, README). `UNVERIFIED`: asked inside `[A]`, not as a stop of its own.
- Environment selection: `-var-file=envs/prod.tfvars`, default workspace; `envs/` holds one file, `prod.tfvars` (`code: envs/prod.tfvars:1` `env = "prod"`).

### Tier

Mapped environments: `prod` only. Pin: none (no `allowed_account_ids`, no provider `assume_role`, no account variable; the account ID appears only inside role and ECR ARNs, `code: envs/prod.tfvars:6-8`, which are not an account pin). Unproven, so prod gate levels. No positive evidence that the target differs, so no `[H1]`. The operator may state the tier at the first stop.

### Predict the lane

Targets: the prod account/region only (single environment; no shared module consumed by another environment; no aliased provider). Not every target proven dev. Light-lane conditions, predicted from the request and the code:
- L1: one create (the alarm). Predicted `plan:` create, 0 change, 0 destroy.
- L2: `aws_cloudwatch_metric_alarm` + create is allowlist row 1 (`lanes.md` › Light-lane allowlist).
- L3: one phase, one environment, no drift row known yet (refresh-only runs in the batch), duplicate check not done.
- L4: E1-E3 on the request and the code:
  - E1: the only SNS topic in code is `aws_sns_topic.paymentapi_alerts` (`code: main.tf:174`); the alarm's actions will be that topic's `.arn`. Pass (re-run on the diff and on the plan).
  - E2: predicted tag keys follow the repo's tag block (`code: main.tf:177-180`): `Service`, `Environment`.
```
CMD 10:13  GREP -n -E 'aws:(ResourceTag|RequestTag)/Service|aws:TagKeys'         -> no hits
CMD 10:14  GREP -n -F 'Service'                                                   -> main.tf:17,64,98,126,155,167,178 (each `Service     = "paymentapi"`, the line that sets the tag)
CMD 10:15  GREP -n -E 'aws:(ResourceTag|RequestTag)/Environment|aws:TagKeys'      -> no hits
CMD 10:16  GREP -n -F 'Environment'                                               -> main.tf:18,65,99,127,156,168,179 (lines that set the tag); variables.tf:2 (`description = "Environment name (e.g. prod, staging)"`)
```
  Every hit read: tag-setting lines and one variable description. None is an IAM condition, SCP, backup selection, scheduler or other automation. Clear. (The commands see only this repo.)
  - E3: on the diff, below.
Predicted lane: **light**, no escalation.

### Snapshot set, profile and freeze, app source

- Not-app-facing change predicted (a new alarm, `snapshot.md` › Not-app-facing changes; the SNS-only action is predicted from E1, the batch's subscriber-protocol read settles it). So: set = the service's workload plus its front door; no dependents or dependencies; no S2 two-period wait.
- App-source search (Q8): only for an app-facing change. Not predicted, so nothing is searched, no `App source:` line, no Q8.
- Incident command: none in the profile. Freeze source: none in the repo.

Snapshot set (cap 10; 3 members):
1. `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (new; changed resource): `n/a — no health signals of its own` (a new alarm has no before state; judged by the success criteria).
2. ECS service `paymentapi-svc-prod` in `paymentapi-cluster-prod` — the workload the alarm watches. Source `code: main.tf:71,8` + the alarm's dimensions. Signals: firing alarms, running vs desired and deployments, CPU, memory.
3. ALB `paymentapi-alb-prod` — the front door. Source: `code: main.tf:84-85,137-138` (service → target group `paymentapi-tg-prod`); the load balancer itself is not in this repo, so its identity comes from the batch (`live:` `describe-target-groups`). Signals: request count, target 5xx, ELB 5xx, p95 latency, healthy / unhealthy hosts, target health.

`Snapshot coverage: code + live reads of the service's front door; not covered: dependents and dependencies (skipped, not-app-facing change), callers in other repos, no catalog and no runtime profile.`

### Evidence table (before the batch)

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| CPU alarm for the service | `code: none` (3 greps, no hit) | read #8 `describe-alarms-for-metric`, #9 `describe-alarms --alarm-name-prefix` (in the batch) | pending |
| Alarm action target: SNS topic `paymentapi-alerts-prod` | `code: main.tf:174-175` | read #6 `sns get-topic-attributes` (in the batch) | pending |
| What the topic notifies | `code: none` — no `aws_sns_topic_subscription` in the repo (grep at 10:29) | read #7 subscription protocols (in the batch) | pending |
| Service the alarm watches: `paymentapi-svc-prod` / `paymentapi-cluster-prod`, 3 tasks | `code: main.tf:8-9,71-73`, `envs/prod.tfvars:1,10` | read #3 `ecs describe-services` (in the batch) | pending |
| Front door of the service | `code: none` (ALB not in this repo; `code: envs/prod.tfvars:5` has only its SG id) | read #4 `describe-target-groups` (in the batch) | pending |
| Delivery model | `UNVERIFIED` (nothing in the repo) | read #12 CI history (in the batch) | asked at `[A]` |

Drift rows: 0 known (refresh-only runs in the batch). Unverified rows: 1 (delivery model).

---

## Step 2 — Plan (single phase)

### Branch (light lane: run now, without a stop, only on an empty `git status --short`)
```
CMD 10:17  git status --short                               -> git-status-clean.txt (prints nothing)
CMD 10:18  git fetch origin main                            -> empty.txt
CMD 10:19  git rev-parse --short origin/main                -> git-rev-parse.txt    (a1b2c3d)
CMD 10:20  git switch -c iac-change/paymentapi-cpu-high-alarm origin/main   -> git-switch.txt   (Switched to a new branch 'iac-change/paymentapi-cpu-high-alarm')
```
NOTE: no branch naming pattern is visible in the repo (`git-log-recent.txt` was not needed; commit subjects are `paymentapi: <what> (#n)` but name no branches), so the skill's fallback `iac-change/<service>-<short-description>` is used.

### Plan content

- Phase 1 of 1: add the alarm. Files: `main.tf` (append a section after the SNS topic). Resources: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`.
- Values the request does not give (threshold, periods, statistic) are written as proposals and shown to the operator at `[A]`: Average CPU > 80 % for 3 consecutive 5-minute periods. Basis: guess (no existing alarm in the repo to copy from).
- Disruption: `none` — `plan:` is expected to be create-only (1 add, 0 change, 0 destroy); no existing resource changes (a pure addition of an alarm needs no behaviour claim).
- Rollback: revert the PR, CI plans and applies the destroy of the alarm. Reversible; untested.
- Execution path: PR (default). Delivery model unknown, asked at `[A]`.
- Staging-first (H7): exception (a), automatic: the repo maps one environment, prod (`code: envs/prod.tfvars` is the only environment file; no staging var-file, workspace or overlay found by the grep at 10:05). Observation window: n/a.
- Plan self-check: 1 evidence on every item (disruption: `plan:` expected; rollback: stated); 2 no delete; 3 rollback and success criteria present; 4 no drift row known; 5 PR path fits (model unknown, PR is the default); 6 every implied file/resource is in the phase (the alarm; nothing extra); 7 lane basis cited (L1-L4, E1-E3); 8 exception (a) with evidence. **8/8 pass.**
- Success criteria (commands with expected output):
  1. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,enabled:ActionsEnabled,actions:AlarmActions}'` -> one alarm, `enabled: true`, `actions: [arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod]`, state `OK` (`INSUFFICIENT_DATA` is acceptable for the first 3 x 300 s, not `ALARM`).
  2. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod --region ap-southeast-1` -> a `ConfigurationUpdate` item "created".
  3. S2 on the snapshot set (not-app-facing: alarms + point-in-time state, no metrics call): `aws cloudwatch describe-alarms --state-value ALARM ...`, `aws ecs describe-services ...`, `aws elbv2 describe-target-health ...` -> nothing firing on the set, 3/3 running, 3 healthy targets.

---

## Step 3 — Implement

```
CMD 10:21  git branch --show-current                        -> git-branch-after-switch.txt   (iac-change/paymentapi-cpu-high-alarm)
```
On the change's branch; writing the code (light lane, clean tree, before `[A]`).

Shown before running (formatter on the changed file only):
```
CMD 10:22  terraform fmt main.tf                            -> empty.txt (nothing printed)
CMD 10:23  git status --short                               -> answered from the diff:   M main.tf
CMD 10:24  git diff                                         -> answered from the diff below
```

### Code diff (appended to `main.tf`)

```diff
diff --git a/main.tf b/main.tf
--- a/main.tf
+++ b/main.tf
@@ -179,3 +179,30 @@ resource "aws_sns_topic" "paymentapi_alerts" {
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
(New lines 182-208 of `main.tf`; 27 added, 0 removed.)

NOTE: canned plan vs code. The canned plan (`plan-prod.txt`) shows `alarm_name = paymentapi-cpu-high-prod`, threshold 80, 3 x 300 s Average, dimensions `paymentapi-cluster-prod` / `paymentapi-svc-prod`, both action lists = the topic ARN, tags Service / Environment, and defaults `treat_missing_data = "missing"` and `actions_enabled = true`. The code above plans the same. No difference.

### Diff self-check

1. Scope: only `main.tf`, which is the plan's file list. Nothing else touched. Pass.
2. Plan <-> hunk: `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create -> `main.tf` hunk `@@ -179,3 +179,30 @@`; the hunk maps to that one plan item. Pass.
3. Conventions: section header style `code: main.tf:172`; underscore resource label like `aws_sns_topic.paymentapi_alerts` `code: main.tf:174`; name pattern `paymentapi-...-${var.env}` `code: main.tf:9,72`; tag block `code: main.tf:177-180`; attribute alignment as `terraform fmt` leaves it. Pass.
4. No silent safety changes: no `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `force_destroy`, `ignore_changes`, `0.0.0.0/0` or `*` in IAM. Pass.
5. No secrets: no literal credential; no `tfplan`, state or `.terraform/` in the working-tree changes. Pass.
6. Formatted: `terraform fmt main.tf` printed nothing. Pass. **6/6 pass.**

### Light lane: E1-E3 on the diff
- E1: `alarm_actions` -> `aws_sns_topic.paymentapi_alerts.arn` (`code: main.tf:201` -> `main.tf:174`); `ok_actions` -> same (`code: main.tf:202`); `insufficient_data_actions` not set. All SNS topic ARNs. Pass.
```
CMD 10:25  GREP -n -E 'aws:(ResourceTag|RequestTag)/Service|aws:TagKeys'         -> no hits
CMD 10:26  GREP -n -F 'Service'                                                   -> same seven tag-setting lines as 10:14
CMD 10:27  GREP -n -E 'aws:(ResourceTag|RequestTag)/Environment|aws:TagKeys'      -> no hits
CMD 10:28  GREP -n -F 'Environment'                                               -> same seven tag lines + variables.tf:2 as 10:16
```
- E2: keys added by the diff: `Service`, `Environment` (`code: main.tf:205-206`). Each hit read and cleared as at 10:13-10:16 (they set the tag or describe a variable). Pass.
```
CMD 10:29  GREP -n -F 'aws_sns_topic_subscription'          -> no hits
```
- E3 (written): "does this change trigger an automated action, or does anything read this value?" For `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`: no. Checked: its only actions are SNS publishes to the existing topic (E1); nothing in the repo references the alarm name or resource (`GREP` at 10:08, no hits); no output changes (`code: outputs.tf:1-19` untouched). What subscribes to the topic is not in the code (no `aws_sns_topic_subscription`, 10:29), so it is settled by the subscriber-protocol read in the batch and E3 is run again on the plan at 4a. No outputs change.
AMBIGUITY: E3 runs "once the diff exists, before the stop that approves it", but the SNS subscriber-protocol read that settles what the topic triggers is in the batch, which runs after `[A]` — reading taken: answer E3 "no" now with what was checked and the open point named, and re-run it at 4a after the read; "unsure -> hit" is applied there if the read shows a non-notify subscriber.

No hit: lane stays **light**, `Escalations: none`.

### Fresh eyes

Skip rule: phase is add-only (1 create, 0 change, 0 destroy expected) and touches none of access control, network exposure, DNS, data stores, secrets / KMS, deletion-protection / lifecycle (an alarm is the skill's own example). `Fresh eyes: skipped — add-only, no sensitive types`.

### Read batch for `[A]`

Built per `lanes.md` › Stops per lane (Read batch) and `examples/aws.md`. All read-only; prod; every command goes through the profile chain the identity read used (no `assume_role` pin). Commands that need an identifier from an earlier read are shown with `<from #n>` and run on this same approval.

```
 1  terraform init -input=false                                  (downloads providers / modules; may update .terraform.lock.hcl)
 2  terraform plan -refresh-only -var-file=envs/prod.tfvars     (drift check; never applied)
 3  aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,taskDef:taskDefinition,tg:loadBalancers[].targetGroupArn,deploy:deploymentConfiguration,deployments:deployments[].{status:status,rollout:rolloutState,created:createdAt,failed:failedTasks},events:events[:5].{at:createdAt,msg:message}}'
 4  aws elbv2 describe-target-groups --names paymentapi-tg-prod --region ap-southeast-1 --query 'TargetGroups[].{arn:TargetGroupArn,lbs:LoadBalancerArns,hc:HealthCheckPath}'
 5  aws elbv2 describe-target-health --target-group-arn <from #3> --region ap-southeast-1
 6  aws sns get-topic-attributes --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --region ap-southeast-1 --query 'Attributes.{arn:TopicArn,confirmed:SubscriptionsConfirmed,pending:SubscriptionsPending}'
 7  aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --region ap-southeast-1 --query 'Subscriptions[].Protocol'      (protocols only, never endpoints)
 8  aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'
 9  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue}'
10  [S0] aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,ns:Namespace,metric:MetricName,dims:Dimensions,math:Metrics[].MetricStat.Metric.Dimensions},composite:CompositeAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,rule:AlarmRule}}'
11  [S0] aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-prod.json --start-time {T-7d-1h} --end-time {now} --scan-by TimestampAscending --query "{summary:MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]},hourly:MetricDataResults[?starts_with(Id, 'req_')].{id:Id,t:Timestamps,v:Values}}"
      (query file written under the output root, ten queries: ALB RequestCount, target 5xx, ELB 5xx, p95, healthy / unhealthy hosts; service CPU and memory; the ALB and target-group dimension values come from #4. The `hourly` key is there because Q3 needs peak hours on the PR path.)
12  gh run list --limit 5 --json databaseId,workflowName,displayTitle,event,headBranch,status,conclusion,createdAt          (CI history, automation lag)
13  aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1      (price of the new alarm, lookup date recorded)
Plan command (4a, run after this batch): terraform plan -out=tfplan -var-file=envs/prod.tfvars
Success-criteria reads (after the apply lands; S2 included): the three commands of the plan's success criteria above.
```
Not in the batch, with the reason: the Terraform state object `head-object` (the code declares no backend block, so there is no bucket or key; see AMBIGUITY below); the sibling app-source search (not an app-facing change); an incident command (none in the profile).
AMBIGUITY: `examples/aws.md` › Automation lag gives `aws s3api head-object --bucket {state-bucket} --key {state-key}` and `gh run list --workflow {workflow-file}`, but this repo declares no backend block and has no CI workflow file name — reading taken: do not invent a bucket, key or workflow name; skip the `head-object` read and run `gh run list` with no `--workflow` filter.
AMBIGUITY: batch commands that need an ID returned by an earlier read (#5 from #3, the ALB dimension in #11 from #4) cannot show it before they run — reading taken: show them with `<from #n>`; the single approval covers the substituted command.

### Message shown to the operator (stop 1)

> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` is not set).
> **Identity (read at 10:01):** account `123456789012`, `assumed-role/paymentapi-operator`, region `ap-southeast-1` (var-file).
>
> **Change requested:** Add a CloudWatch CPU utilization alarm for paymentapi in prod.
> **Service:** `paymentapi` / **Instance:** none (one environment)
> **IaC tool(s):** Terraform · **Delivery model:** `UNVERIFIED` (nothing in the repo shows how changes are applied) · **Env selection:** `-var-file=envs/prod.tfvars`, default workspace (`code: envs/prod.tfvars:1`)
> **Target:** account `123456789012` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:01)
> **Environment tier:** `prod=prod` gate levels, unproven: the repo pins no account (no `allowed_account_ids`, `assume_role` or account variable). You may state the tier here; it is recorded `operator-stated` and stays unproven. · **Lane (predicted):** `light` — L1 create only, L2 `aws_cloudwatch_metric_alarm` create is on the allowlist, L3 one phase / one environment / no drift row known / duplicate check not done, L4 E1 SNS topic only, E2 keys `Service` `Environment` cleared, E3 no (open point: topic subscribers, re-run at 4a). Escalations: none.
> **Catalog used:** none — proceeding without catalog (consider running service-discovery first).
> **Duplicate check:** not done — `code:` no hit for `CPUUtilization`, `aws_cloudwatch_metric_alarm`, `paymentapi-cpu-high`; `git:` no commit added or removed them; no branch; no open PR.
> **Evidence table:** (as above) — drift rows: 0 known, unverified rows: 1 (delivery model)
> **Snapshot set:** new alarm (n/a — no health signals of its own) · ECS service `paymentapi-svc-prod` (`code: main.tf:71`) · ALB `paymentapi-alb-prod` (via `live:` read #4) · `Snapshot coverage: code + live reads of the service's front door; not covered: dependents and dependencies (skipped, not-app-facing change), callers in other repos, no catalog or runtime profile`
> **Gaps remaining:** delivery model; topic subscribers (read #7); front door identity (read #4); apply time of the last change (read #12; no state bucket in code).
>
> **Change plan for `paymentapi`:**
> **Phase 1 of 1: add the CPU alarm**
> - Files: `main.tf`
> - Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`)
> - Blast radius: the snapshot set above
> - Disruption: `none` — `plan:` create only, no existing resource changes (to be confirmed by the 4a plan)
> - Rollback path: revert the PR, CI destroys the alarm — reversible, untested
> - Evidence: rows above
> - Success criteria: the three commands listed above + S2 on the set
> **Execution path:** PR (default). After merge it is applied by `<the pipeline — see the question below>`. Direct apply is the escape hatch with elevated risk (A4); say so if you want it.
> **Staging-first (H7):** (a) no staging env — `code: envs/prod.tfvars` is the only environment file · **Observation window:** n/a
> **Branch:** current `main` -> `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d` (fetch + create — done, clean tree)
> **Self-check:** 8/8 pass
> **Drift (H4):** none known
> **Values I chose that your request did not give:** threshold 80 %, Average, 3 x 5 min — change them now if you want others.
> **Delivery model:** how does this change reach prod? (nothing in the repo shows it)
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
>
> **Code changes for Phase 1 of 1:**
> **Modified:** `main.tf` — append the alarm section (27 lines added, 0 removed)
> **Plan <-> hunk:** `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create -> `main.tf` `@@ -179,3 +179,30 @@`
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped — add-only, no sensitive types
> **Target:** account `123456789012` / role `paymentapi-operator` / `ap-southeast-1` (10:01) · `-var-file=envs/prod.tfvars`, default workspace · tier `prod=prod`
> **Plan command (4a):** `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (`terraform init` runs in the batch)
> Full diff is in your working tree (`git diff`).
>
> **Read batch** (each command shown above, #1-#13, plus the plan command and the success-criteria reads): S0 is #3, #5, #10, #11 (and #4 for the front door). S1 runs on the same approval.
>
> **[A] Approve the plan, the code and these reads?**

NOTE: at `[A]` the `**Checked for you:**` block is not shown: S0 has not run (light lane, it moves to `[B]`). Q4 / Q5 are in the profile, so they are not asked. No Q8, no `App source:` line (not app-facing predicted). Both a freeze source and an incident command would be needed to drop the operator line; neither exists, so the line is shown.

STOP 1: `A`. Clock 10:29.

### Operator answer (script entry 1, `[A]`)

"Approve. Tier: prod (operator-stated). Delivery model: a CI pipeline applies on merge (operator-stated). Read batch: approve every command shown." Operator line: no reply (script: `Operator line: no reply`; nothing said about it, nothing logged as L2).
Items in the entry marked `if asked` (Q1-Q8, iac-change.1-4): the skill asked none of them at this stop, so none was said and nothing is logged `L2-ASKED` (with its colon).
Clock 10:34.

Recorded now: tier `prod=prod (operator-stated — no account pin in code; unproven, prod gate levels)`. Delivery model `UNVERIFIED — operator-stated: a CI pipeline applies on merge`; PR path only. Operator line: `Q1(declared)=no, Q2=no — operator (no objection at [A], 10:34)` and `Q7=none`.

---

## After `[A]` — the batch

```
CMD 10:35  terraform init -input=false                                          -> terraform-init.txt
```
(Reusing provider hashicorp/aws v5.74.0 from the lock file; may touch `.terraform.lock.hcl`, which is not in the approved file list and will not be staged.)
```
CMD 10:36  terraform plan -refresh-only -var-file=envs/prod.tfvars              -> plan-refresh-only-prod.txt   ("No changes. Your infrastructure still matches the configuration.")
```
Drift: none. `[H4]` not raised.
```
CMD 10:37  aws ecs describe-services ... (#3, projected)                        -> ecs-describe-services-prod.json
```
`status ACTIVE · desired 3 · running 3 · pending 0 · taskDef paymentapi-prod:12 · tg .../targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 · circuitBreaker enable=false · min healthy 100 / max 200 · deployments [PRIMARY, rollout COMPLETED, created 2026-10-12T14:02:11Z, failed 0] · events [2026-11-09T01:12:40Z "has reached a steady state"]` (`live`, 10:37).
```
CMD 10:38  aws elbv2 describe-target-groups --names paymentapi-tg-prod (#4)     -> tg-describe-prod.json
```
`arn .../targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 · lbs [.../loadbalancer/app/paymentapi-alb-prod/50dc6c495c0c9188] · hc /healthz` (`live`, 10:38). Member 3 confirmed: ALB `paymentapi-alb-prod`, `LoadBalancer` dimension `app/paymentapi-alb-prod/50dc6c495c0c9188`, `TargetGroup` dimension `targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`.
```
CMD 10:39  aws elbv2 describe-target-health --target-group-arn <from #3> (#5)   -> tg-health-prod.json
```
3 targets, all `healthy` (`live`, 10:39).
```
CMD 10:40  aws sns get-topic-attributes --topic-arn ...paymentapi-alerts-prod (#6)  -> sns-attributes-prod.json
```
Topic exists; confirmed subscriptions 2, pending 0 (`live`, 10:40).
```
CMD 10:41  aws sns list-subscriptions-by-topic ... --query 'Subscriptions[].Protocol' (#7)  -> sns-subscriptions-prod.json
```
Protocols `["email","email"]` (the file also carries endpoints; the `--query` returns protocols only) (`live`, 10:41). All notify-only: the alarm is not-app-facing, confirmed.
```
CMD 10:42  aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization ... (#8)  -> alarms-for-metric-cpu-prod.json
CMD 10:43  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi ... (#9)                                -> alarms-prefix-prod.json
```
No alarm on the service's CPU, none with the prefix (`live`, 10:42 / 10:43). Code and live agree: the alarm is not in code and not live.
```
CMD 10:44  [S0] aws cloudwatch describe-alarms --state-value ALARM --alarm-types ... (#10)   -> alarms-firing-prod.json
```
Nothing firing in `ap-southeast-1` (so 0 on the set) (`live`, 10:44).

Query file written (not made in the dry run) `.culiops/iac-change-execution/snapshot-queries-prod.json`: ten queries, `Period` 3600, Ids `m_5xx_alb` (`ReturnData` false) + `err_alb` = `FILL(m_5xx_alb, 0)`, `m_elb5xx_alb` + `errelb_alb` = `FILL(m_elb5xx_alb, 0)`, `req_alb` (`RequestCount` Sum, unfilled), `p95_alb` (`TargetResponseTime` p95), `healthy_alb` and `unhealthy_alb` (`HealthyHostCount`, `UnHealthyHostCount`, Minimum, `LoadBalancer` + `TargetGroup` dimensions), `cpu_svc` and `mem_svc` (`AWS/ECS` `CPUUtilization` / `MemoryUtilization`, Average, `ClusterName` + `ServiceName`). Labels are `<member> <metric>`.
```
CMD 10:45  [S0] aws cloudwatch get-metric-data --start-time 2026-11-02T02:45:00Z --end-time 2026-11-09T03:45:00Z ... (#11)  -> metric-data-7d-prod.json
```
NOTE (protocol, Notes › `get-metric-data` files): the file's results are matched by `Label` to the signals asked for and given my `Id`s; values are oldest first and dated from the end of the window I asked for. Window 7 d 1 h ending 10:45 +07: 169 hourly buckets; first bucket starts 2026-11-02 09:45 +07, last (`t_now`) starts 2026-11-09 09:45 +07. The 7-day file is the one for a window longer than a day.

S0 values (`live`, 10:45; now / same hour a week earlier):
- ALB `RequestCount`: 41,442 / 40,827 (1.02x) · target 5xx 0 / 0 · ELB 5xx 0 / 0 · p95 0.114 s / 0.116 s · healthy hosts 3 / 3 · unhealthy hosts 0 / 0.
- Service CPU 38.0 % / 37.4 % · memory 52.0 % / 51.5 %.
- Peak hours from the `hourly` series (`req_alb`): bucket start times carry `:45`, so each bucket is mapped to the clock hour that holds most of it (09:45-10:45 -> 10). Weekday averages by clock hour (+07): 14 -> 58.2k, 15 -> 61.2k, 16 -> 60.2k, 17 -> 57.2k, 18 -> 44.2k, 13 -> 47.2k. AMBIGUITY: the text says "the busiest hours of the last 7 days" with no cut-off — reading taken: the clock hours whose weekday average is within 10 % of the busiest hour, i.e. 14-17, shown as `peak hours: 14–18 (+07; 07–11 UTC)`. Also AMBIGUITY: INDEX describes the last point as "the hour ending at the clock start (10:00)" while the protocol dates values from the end of the window asked (10:45) — reading taken: the protocol (window end 10:45), which is why the mapping above applies.
- Q3 (PR path, CI applies at merge): `unsure (apply at merge; peak hours 14–18 +07 (07–11 UTC), live)`. Context: now 41,442 vs 40,827 a week ago = 1.02x, not above 1.5x.
```
CMD 10:46  gh run list --limit 5 --json ...  (#12)                              -> gh-run-list.json
```
One run: workflow `terraform-apply`, event `push` on `main`, "paymentapi: bump image to v2.4.1 (#118)", `completed` / `success`, created 2026-11-06T04:31:02Z = 2026-11-06 11:31 +07 (`live`, 10:46). About 3 days before the clock. This also corroborates the operator's statement that a CI pipeline applies on merge (a push-triggered `terraform-apply` run on `main`); the delivery model stays `operator-stated`. `iac-change.4 = recent`.
```
CMD 10:47  aws pricing get-products --service-code AmazonCloudWatch ... (#13)   -> pricing-cloudwatch-alarm.json
```
Standard alarm, `ap-southeast-1`: USD 0.10 per alarm metric month, price list publication 2026-10-07; looked up 2026-11-09 (`live`, 10:47).

Snapshot S0 is complete: reads 10:37-10:45.

### Evidence table (after the batch)

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| CPU alarm for the service | `code: none` | `live: describe-alarms-for-metric` -> none (10:42); `--alarm-name-prefix paymentapi` -> none (10:43) | ✅ absent in both |
| SNS topic `paymentapi-alerts-prod` | `code: main.tf:174-175` | `live: get-topic-attributes` -> exists, 2 confirmed (10:40) | ✅ |
| Topic subscribers | `code: none` | `live: list-subscriptions-by-topic` -> protocols email, email (10:41) | ✅ notify-only |
| Service `paymentapi-svc-prod`, desired 3 | `code: envs/prod.tfvars:10` (desired_count; `ignore_changes = [desired_count]`, `main.tf:94`) | `live: ecs describe-services` -> desired 3, running 3 (10:37) | ✅ |
| Front door | `code: none` (not in this repo) | `live: describe-target-groups` -> `paymentapi-alb-prod` (10:38) | live only (not drift: not managed here) |
| Last apply | `code: none` (no backend) | `live: gh run list` -> `terraform-apply` success 2026-11-06 11:31 (10:46) | — |
| Delivery model | `UNVERIFIED` | `live: gh run list` shows a push-triggered apply on `main` (10:46) | `operator-stated` at `[A]`, corroborated |

Drift rows: 0. Unverified rows: 0 after `[A]` (delivery model `operator-stated`).

---

## Step 4a — plan output

```
CMD 10:48  aws sts get-caller-identity   (target re-check)                      -> identity-prod.json
```
Account `123456789012`, role `paymentapi-operator`. NOTE: environment taken = prod (rule 1(b): the only environment). Matches the Step 1 read; no pin to compare with, so tier stays `operator-stated`. No `[H1]`.
`terraform init`: already run in the batch at 10:35, so it is not run again ("if needed").
```
CMD 10:49  terraform plan -out=tfplan -var-file=envs/prod.tfvars                -> plan-prod.txt
```
`Plan: 1 to add, 0 to change, 0 to destroy.` — `aws_cloudwatch_metric_alarm.paymentapi_cpu_high will be created` (`plan:6-7`, `plan:42`). The canned plan matches the code (see the NOTE at the diff).

Cross-check against the evidence table: the one planned resource is the approved phase's resource; action `create` matches disruption `none`; no destroy or replace; no drift; no other change. Resources outside the snapshot set: none.

Lane confirmation (light): L1 1 create, 0 change, 0 destroy (`plan:42`); L2 `aws_cloudwatch_metric_alarm` create (allowlist row 1); L3 one phase, one environment, drift none, duplicate check not done; L4:
- E1: plan `alarm_actions` and `ok_actions` are `arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod` (`plan:9-11,25-27`), a literal SNS ARN in the `aws` partition. Pass.
```
CMD 10:50  GREP -n -E 'aws:(ResourceTag|RequestTag)/Service|aws:TagKeys'         -> no hits
CMD 10:51  GREP -n -F 'Service'                                                   -> same tag-setting lines (cleared)
CMD 10:52  GREP -n -E 'aws:(ResourceTag|RequestTag)/Environment|aws:TagKeys'      -> no hits
CMD 10:53  GREP -n -F 'Environment'                                               -> same tag lines + variables.tf:2 (cleared)
```
- E2: plan tags `Environment`, `Service` (`plan:30-37`), same two keys as the diff. Pass.
- E3: now the subscribers are known: protocols email, email (`live`, 10:41). The new alarm triggers no automated action (notify-only) and nothing reads it. Answer: no, cited. Pass.
Lane **light** confirmed. No `plan-confirm`. Parity check: n/a (no staging phase; exception (a)). Dev checks: n/a.

## Step 4b — S1, then pre-flight

S1 for prod: the latest snapshot is S0, whose reads ran 10:37-10:45. AMBIGUITY: "reuse its latest snapshot when 15 minutes old or less" — a snapshot made of several reads has no single age. Reading taken: the age of its oldest read; the 10:37 read is 17 minutes old at 10:54, so S0 is not reused and S1 is read again (four commands; the same ones as S0 minus the lookups). Approved with the batch, no stop.
```
CMD 10:54  [S1] aws ecs describe-services ... (as #3)                           -> ecs-describe-services-prod.json
CMD 10:55  [S1] aws elbv2 describe-target-health --target-group-arn ... (as #5) -> tg-health-prod.json
CMD 10:56  [S1] aws cloudwatch describe-alarms --state-value ALARM ... (as #10) -> alarms-firing-prod.json
CMD 10:57  [S1] aws cloudwatch get-metric-data ... --end-time 2026-11-09T03:57:00Z (as #11)   -> metric-data-7d-prod.json
```
S1 values (`live`, 10:54-10:57; now / same hour a week earlier; last bucket starts 09:57 +07, mapped to clock hour 10): ECS desired 3 / running 3 / pending 0, one PRIMARY deployment COMPLETED, no new events; 3 healthy targets; nothing firing; ALB requests 41,442 / 40,827, target 5xx 0 / 0, ELB 5xx 0 / 0, p95 0.114 / 0.116, healthy 3 / 3, unhealthy 0 / 0; CPU 38.0 / 37.4; memory 52.0 / 51.5. Peak hours unchanged: 14–18 (+07). `Q1(alarms)` and Q3 from S1 equal S0's.

### Plan hash and reuse check
```
CMD 10:58  terraform show -no-color tfplan                                      -> plan-prod.txt
CMD 10:59  sha256sum <scratch file holding the plan text>                       -> INDEX Plan hashes: sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89
```
(scratch file outside the repo, deleted after). Reusable record in `.culiops/pre-flight/`: the directory is not in the fixture, so no record: **No match**. Pre-flight is invoked in inline mode.

### Caller block passed to pre-flight

```
### Caller context (iac-change-execution)
Target: account 123456789012 / ap-southeast-1 · Terraform default workspace · -var-file=envs/prod.tfvars (no backend declared in code)
Delivery model: UNVERIFIED — operator-stated: a CI pipeline applies on merge (live: gh run list shows a push-triggered terraform-apply run on main, 10:46)
Lane: light — L1 plan 1 add / 0 change / 0 destroy; L2 aws_cloudwatch_metric_alarm create is on the allowlist; L3 one phase, one environment, no drift, duplicate check not done; L4 E1 SNS ARN, E2 Service / Environment cleared, E3 no
Plan hash: sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89 (terraform show -no-color tfplan)
L2 answers: Q1(alarms)=no (live: aws cloudwatch describe-alarms --state-value ALARM, 10:56: 0 firing on the snapshot set) Q1(declared)=no (operator (no objection at [A], 10:34)) Q2=no (operator (no objection at [A], 10:34)) Q3=unsure (apply at merge; peak hours 14–18 +07, live: get-metric-data, 10:57) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator (no objection at [A], 10:34)) iac-change.4=recent (live: gh run list, 10:46: last terraform-apply run succeeded 2026-11-06 11:31 +07)
Live results:
  aws sts get-caller-identity · 10:48 · account 123456789012, assumed-role/paymentapi-operator
  terraform plan -refresh-only -var-file=envs/prod.tfvars · 10:36 · no drift
  aws ecs describe-services (service) · 10:54 (S1) · ACTIVE, 3/3 running, one PRIMARY deployment COMPLETED, circuit breaker off, min healthy 100 / max 200, no warning events
  aws elbv2 describe-target-groups --names paymentapi-tg-prod · 10:38 · behind ALB paymentapi-alb-prod, health check /healthz
  aws elbv2 describe-target-health · 10:55 (S1) · 3 of 3 healthy
  aws sns get-topic-attributes · 10:40 · topic exists, 2 confirmed subscriptions
  aws sns list-subscriptions-by-topic (protocols) · 10:41 · email, email
  aws cloudwatch describe-alarms-for-metric (CPUUtilization of the service) · 10:42 · none
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi · 10:43 · none
  aws cloudwatch describe-alarms --state-value ALARM · 10:56 (S1) · none firing
  aws cloudwatch get-metric-data (7 d hourly, 8 series) · 10:57 (S1) · req 41,442 (1w ago 40,827); target 5xx 0; ELB 5xx 0; p95 0.114 s (0.116); CPU 38.0 % (37.4); memory 52.0 % (51.5); healthy 3; unhealthy 0; peak hours 14–18 +07
  gh run list · 10:46 · last terraform-apply run success, 2026-11-06 11:31 +07
  aws pricing get-products (CloudWatch standard alarm, ap-southeast-1) · 10:47 · USD 0.10 per alarm metric month, publication 2026-10-07
Evidence table: the table above; drift rows 0; unverified rows 0 (delivery model operator-stated); no code-only rows; no catalog
```

## Pre-flight (inline mode) — run in this session

Step 1 (no GATE 1, inline): assessor `iac-change` (Terraform plan, `Plan:` line present). Detected: a Terraform change adding `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` in account `123456789012` / `ap-southeast-1`, delivered by CI on merge (operator-stated). Target equals the caller's `Target:`. Plan hash from the caller. Output root `.culiops/` (named in the report; the caller showed it at `[A]`).

Target check, no stop (Constraint 2, inline):
```
CMD 11:00  aws sts get-caller-identity                                          -> identity-prod.json
```
Account `123456789012`, role `paymentapi-operator`: equals `Target:`. Continue.

Step 2 (L1): the plan (`plan:6-42`), `main.tf` / `outputs.tf`, git history, the caller's evidence table.
```
CMD 11:01  git log --since=7.days --oneline origin/main -- main.tf              -> empty.txt
```
NOTE: pre-flight would also exclude this change's own commits (`git log origin/main..HEAD`). The change is uncommitted, so there are none; that command is not run (INDEX would answer any other `git log` with the three-commit history, which is the history of `main`, not of this branch, and would be a wrong answer for a range read).
Changed attributes marked: new alarm (not-app-facing: alarm whose actions are all SNS topics with only `email` subscribers, `live` 10:41), no output / export changes: all not-app-facing, so category 11 is Green now.

Step 3 (L2): the caller's `L2 answers:` are the operator's answers. Nothing is missing: Q1 has both parts; Q2, Q3, Q4, Q5, Q7 given; Q6 is scored from the plan (L1 prices a new alarm), not asked; Q8 not needed (not-app-facing); the Incident Context follow-up is not asked (Q1 is no); assessor questions: iac-change.1 answered by `Plan hash:` with its plan command, .2 by `Delivery model:`, .3 by `Target:` plus the plan command (var-file, default workspace, no `-target`, no `-refresh=false`), .4 by `iac-change.4=recent`. **No L2 question asked, no stop.** Typed L2: 0.

Step 3b: not needed (nothing app-facing). Step 4 (L3): every category's read is covered by the caller's `Live results:` (health: S1 reads; blast-radius softeners: ECS deployment settings; dependents: protocols and the plan; observability: alarms-for-metric; timing: request rate + peak hours; velocity: gh run list + git log; cost: price lookup). Nothing missing: **no L3 batch, no stop.**

Step 5 (score), citations in the record `preflight-record.md`:

| # | Category | Score | Finding |
|---|---|---|---|
| 1 | Blast radius | 🟢 | one resource added, one region, monitoring only, no existing resource touched (`plan:42`, `plan:6`) |
| 2 | Reversibility | 🟢 | create only, no in-place change; rollback = revert + CI apply (`plan:42`) |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days (`git log`, 11:01); last apply 2026-11-06 (3 days); no open PR |
| 4 | Dependency impact | 🟢 | alarm not-app-facing, no output or export changes; nothing consumes it |
| 5 | Timing context | ⚪ | Q1 no, Q2 no; Q3 `unsure` (apply at merge): peak hours 14–18 +07 (live); nobody-on-hand at merge time is not established |
| 6 | Operator familiarity | 🟢 | many times / experienced (profile, 2026-10-19) |
| 7 | Observability readiness | 🟢 | the change adds not-app-facing monitoring only (assessor L1 rule); no CPU alarm exists live (10:42) |
| 8 | Cost impact | 🟢 | alarms only; USD 0.10 per alarm metric month, looked up 2026-11-09 for `ap-southeast-1` |
| 9 | Security posture | 🟢 | no IAM, network, encryption, public-access or logging change (`plan:8-40`) |
| 10 | Resource health | 🟢 | 0 firing, target 5xx 0, p95 0.114 s vs 0.116 s, CPU 38.0 %, memory 52.0 %, 3/3 healthy, ECS steady (S1, 10:54-10:57) |
| 11 | Application compatibility | 🟢 | only not-app-facing attributes changed |

AMBIGUITY: pre-flight Constraint 8 asks for `live` confirmation that alarms exist and are enabled before category 7 is Green, but the iac-change assessor says a change that only adds not-app-facing monitoring is Green — reading taken: the assessor's specific rule governs; Green cites `plan:` and `live: describe-alarms-for-metric` (no existing alarm), with the post-apply "leaves INSUFFICIENT_DATA" check as the mitigation.
AMBIGUITY: `Q3=unsure` "scores as unsure: ⚪ unknown or Yellow" — reading taken: ⚪ (the peak window is known, but the apply time, and so who is on hand and whether it falls in the window, is not). The verdict is the same either way.

Hard blocks checked: category 2 (nothing irreversible), 5 (no active incident and no freeze: Q1 no, Q2 no), 9 (no public exposure, encryption or secrets), 10 (no SLO, no error budget exhausted). None triggered. Yellow + ⚪ = 1 (category 5), no Red -> **YELLOW — proceed with caution**.

Step 5b: citation check (12 re-opened: Greens 1, 2, 4, 7, 9, 10, 11; the four hard-block conditions; the mitigation's peak-hours premise): none fixed. No source conflicts. Verdict arithmetic written. Fresh eyes: required (verdict is not RED soft); no separate reviewer in this dry run: `fresh-eyes: not run — dry run`. Not verified: Q1(declared) / Q2 / Q7 rest on "no objection"; delivery model and tier are operator-stated; Q3 unsure; no catalog (callers in other repos unknown); who receives the two `email` subscriptions.

Step 6 (report): inline on YELLOW, no GATE 2; the report and the verdict go back to the caller with the ⚪ finding and its mitigation (merge outside 14–18 +07, or with the on-call on hand; then timing is known). Step 7: record written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1101.md` (see `preflight-record.md`). Not committed.

Back in iac-change-execution, verdict handling: YELLOW — no stop here; carried to `[B]`. No `target mismatch`.

---

## Step 4c — execution stop `[B]`

H7 check before `[B]` (the mutation reaches prod): exception (a) recorded (no staging env, with evidence). No `[H7]`.

PR path: work on the branch from Step 2. Stage exactly the approved file by explicit path, then present.
```
CMD 11:02  git add main.tf                                                      -> empty.txt
CMD 11:03  git status                                                           -> answered from the diff:
```
```
On branch iac-change/paymentapi-cpu-high-alarm
Changes to be committed:
	modified:   main.tf
```
No `tfplan`, state, `.terraform/` or unrelated file staged (`tfplan` and `.terraform/` are untracked and stay unstaged; a changed `.terraform.lock.hcl`, if any, is not staged).

> **[B] Open the PR?** On branch `iac-change/paymentapi-cpu-high-alarm` (from `origin/main`), staged **only** these files: `main.tf`. On approval: commit, push, and open a PR.
> `git status` after staging: `modified: main.tf` — no `tfplan` / state / `.terraform/` / unrelated files.
> Target: account `123456789012` / role `paymentapi-operator` / `ap-southeast-1` (re-checked at 10:48) · `-var-file=envs/prod.tfvars` · tier `prod=prod` (operator-stated) · plan: 1 to add, 0 to change, 0 to destroy (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`) · **Pre-flight verdict:** YELLOW — proceed with caution. One finding: category 5 timing is unknown (⚪): the apply happens at merge, and the busiest hours of the last 7 days are 14–18 +07. Mitigation: merge outside that window, or with the on-call on hand. Approving here acknowledges it.
> S1 (prod, 10:54-10:57): nothing firing on the set, 3/3 running and healthy, target 5xx 0, p95 0.114 s, CPU 38.0 %.
> **Checked for you:** (correct anything that's wrong)
> - Health: `paymentapi-svc-prod` + `paymentapi-alb-prod` — 0 alarms firing, target 5xx 0 (same hour last week 0), p95 0.114 s (0.116 s), CPU 38.0 % (37.4 %), 3/3 healthy · live 10:54-10:57 (S1)
> - Peak: unsure — apply at merge; peak hours 14–18 +07 (07–11 UTC); now 41,442 req/h vs 40,827 same hour last week (1.02x) · live 10:57
> - Last apply: about 3 days ago, `terraform-apply` run succeeded 2026-11-06 11:31 +07 · live 10:46 (state object not read: no backend in code)
> - Experience: many times (this service) / experienced (Terraform) · operator (profile, 2026-10-19)
> - Incident and freeze: none declared, no freeze calendar in the repo · operator (no objection at [A], 10:34)
> Snapshot coverage: code + live reads of the service's front door; not covered: dependents and dependencies (skipped, not-app-facing change), callers in other repos, no catalog or runtime profile
> PR will include: change summary, evidence table, pre-flight verdict, the `Staging-first:` line, execution record link.
> *Heads-up: say so and I draft one for the owners / reviewers / on-call with `change-comms` (draft-only; you send it).*
> **[B] Open the PR?**

STOP 2: `B`. Clock 11:03.

### Operator answer (script entry 2, `[B]`)

"Approve: open the PR. Skip the optional heads-up line." Clock 11:08. A correction at `[B]` that changes an answer would re-run pre-flight: there is none, so `[B]` does not repeat.

### PR path

Repo commit style: `paymentapi: <what> (#n)` (`git: c4d8e21 "paymentapi: bump image to v2.4.1 (#118)"`, `9a07b3f`, `5e1c0d8`). The PR number is added by the host.
```
CMD 11:09  git commit -m "paymentapi: add CPU utilization alarm (prod)"          -> git-commit.txt
```
`[iac-change/paymentapi-cpu-high-alarm 7f3a9c1] paymentapi: add CPU utilization alarm (prod)` / `1 file changed, 27 insertions(+), 0 deletions(-)`
```
CMD 11:10  git push -u origin iac-change/paymentapi-cpu-high-alarm               -> git-push.txt
CMD 11:11  gh pr create --title "paymentapi: add CPU utilization alarm (prod)" --body-file <PR body>   -> gh-pr-create.txt
```
PR URL: `https://github.com/acme/paymentapi-infra/pull/142`.

PR body (written to a scratch file outside the repo):
```
Add a CloudWatch CPU utilization alarm for paymentapi in prod.

Change: aws_cloudwatch_metric_alarm.paymentapi_cpu_high (paymentapi-cpu-high-prod): ECS CPUUtilization (Average, 3 x 300 s) above 80 % notifies the existing SNS topic paymentapi-alerts-prod (alarm and ok actions). 1 file changed (main.tf), 27 lines added.
Plan (prod, -var-file=envs/prod.tfvars): 1 to add, 0 to change, 0 to destroy. Plan hash sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89.
Evidence: no CPU alarm in code or live (code grep; describe-alarms-for-metric 10:42); topic exists with 2 confirmed email subscriptions (10:40-10:41); service 3/3 running, nothing firing, target 5xx 0 (S1 10:54-10:57); drift none (refresh-only 10:36).
Pre-flight verdict: YELLOW — proceed with caution. Timing unknown (apply at merge); busiest hours 14-18 +07. Merge outside that window or with the on-call on hand.
Staging-first: n/a — no staging env (envs/prod.tfvars is the only environment file)
Execution record: .culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1112.md (not committed; commit it if your team keeps records in the repo)
```
Reported to the operator: PR `https://github.com/acme/paymentapi-infra/pull/142` created.

---

## Step 5 — Verify and record

### 5a

PR path, delivery model "CI applies on merge" (operator-stated): "PR `https://github.com/acme/paymentapi-infra/pull/142` created. After merge, the CI pipeline applies it." The skill waits for the operator to say the apply has landed (the "tell me when the apply lands" re-entry). The operator script has no such message, so the run ends at the final message: the phase success criteria and S2 are not run. No S2 jump (`S2 ready at HH:MM`) occurs: it is only stated when the skill is about to wait for an S2 it will read, and none is read here. Record: S0 and S1 only, no after value claimed; `Applied: no — PR open`.

### 5b

Record written to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1112.md` — see `record.md`. Pre-flight record: see `preflight-record.md`.

### Final message to the operator

> The PR is open: `https://github.com/acme/paymentapi-infra/pull/142` (branch `iac-change/paymentapi-cpu-high-alarm`, commit `7f3a9c1`, `main.tf` only). Outcome: completed. Applied: no — PR open; the CI pipeline applies it on merge. Pre-flight YELLOW, acknowledged at `[B]`. The execution record is `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1112.md` (uncommitted); the pre-flight record is `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1101.md`.
> Next: commit the record (`.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1112.md`) · draft the result or ticket-close message with change-comms · tell me when the apply lands and I run the success criteria

---

## Summary of the run (runner's tally)

- Stops: 2 (`[A]`, `[B]`), none unscripted.
- L2 questions asked of the operator: 0 (`L2-ASKED` (with its colon) lines: none).
- Commands with `no canned output`: none.
- Snapshot commands added to the batch for prod: 4 (S0: `ecs describe-services`, `describe-target-health`, `describe-alarms --state-value ALARM`, `get-metric-data`). S1 re-ran the same 4 on the same approval (8 snapshot reads run in all). The front-door lookup (`describe-target-groups`) is a Step 1 read that names the load balancer; the other batch reads (drift, topic, alarms on the metric, CI history, price) answer L2 and the assessor's L3 and are not snapshot reads.
