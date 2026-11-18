# Dry run — light-lane-staging-prod — operator-script-alarm-firing.md — out-dir expected-output-v020-alarm-firing

Skill under test: `skills/iac-change-execution/SKILL.md` on branch `feat/iac-change-snapshot-and-l2` (v0.20), with `lanes.md`, `snapshot.md`, `examples/aws.md`, `skills/pre-flight/SKILL.md`, `assessors/iac-change.md`, `examples/aws.md`.
Dry-run clock starts 2026-11-09 10:00 +07:00. Commands advance it 1 minute each, operator answers 5 minutes, file reads (Read) nothing. Times are +07:00.

**First message to the skill:** "Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR."

Notation: `[hh:mm] $ command` then `canned: <file>` and a short result. "(b)" = environment taken from the skill's current work (protocol rule 1, order b).

---

## Step 1 — Research

AMBIGUITY: Step 1 says "the identity read" (singular) but staging-first makes both staging and prod targets of this change, and each tier is proven by its own identity read — read both at Step 1 (identity reads are exempt, run first), staging first, the operator switches the shell profile between them with no stop.
AMBIGUITY: `CULIOPS_HOME` is not readable through any canned row — assumed unset, so the output root is `.culiops/` at the repo root and the operator profile is `~/.culiops/operator.md`.

Identity reads, before any other command:

[10:01] $ aws sts get-caller-identity          (shell profile: staging credentials)
canned: identity-staging.json — environment taken (b): staging is the first target. Account 222222222222, `assumed-role/paymentapi-operator/operator`.
[10:02] $ aws sts get-caller-identity          (shell profile: prod credentials; operator switches, no stop)
canned: identity-prod.json — environment taken (b): prod. Account 333333333333, `assumed-role/paymentapi-operator/operator`.

Local reads (not live):

[10:03] $ git branch --show-current
canned: git-branch.txt → `main`
[10:04] $ git status
canned: git-status-clean.txt → clean tree on `main`, up to date with origin/main
[10:05] $ cat ~/.culiops/operator.md          (operator profile read — protocol rule 1)
canned: operator-profile.md → Q5 terraform = experienced (2026-10-19); Q4 `acme/paymentapi-infra/paymentapi` = many times (2026-10-19). No `first time`, no `incident check:` line.
[10:06] $ git remote get-url origin
canned: git-remote.txt → `git@github.com:acme/paymentapi-infra.git` → workspace `acme/paymentapi-infra` (Constraint 13), so the Q4 key is `acme/paymentapi-infra/paymentapi`.

Catalog: `.culiops/service-discovery/paymentapi.md` — file not found (fixture input read). No runtime profile either. Suggest service-discovery; proceed without it.
Freeze source: no file in the repo is a change-freeze or change-window calendar (`grep -rn -i freeze` over the input files: no hits). Incident command: the profile has none.

IaC code read (current branch is `main`, the default, so read directly): `main.tf` (cluster :8, task def :24, service :71, SG :105, target group :137, log group :162, SNS topic :174), `outputs.tf`, `providers.tf` (`allowed_account_ids = [var.aws_account_id]` :16), `variables.tf`, `envs/staging.tfvars`, `envs/prod.tfvars`. No alarm exists in the code. Naming pattern: `paymentapi-<role>-${var.env}` (main.tf:9, :72, :138, :175), snake_case resource labels prefixed `paymentapi_` (main.tf:8, :162, :174), a two-key `tags` block `Service` / `Environment` on every resource (main.tf:177-180), one `# ── <name> ──` section comment per resource.

Delivery model and env selection: no CI workflow, Atlantis, Terraform Cloud, Spacelift or GitOps object in the repo (`grep -rn -i -E 'backend|workflow|atlantis|freeze'` over input files: no hits). Env selection = `-var-file=envs/<env>.tfvars`, default workspace (code: providers.tf:12-17, envs/staging.tfvars, envs/prod.tfvars). Delivery model = UNVERIFIED, asked inside `[A]`.
AMBIGUITY: the first message says "apply it directly, no PR" but the repo shows nothing about how changes reach the environment — read that as the operator's execution-path request, not as the delivery-model answer: the delivery model stays UNVERIFIED and is asked inside `[A]`.

Duplicate check (all local, read-only):
[10:07] $ git grep -n -F 'paymentapi-cpu-high'
answered by grep over the fixture input files → no hits.
[10:08] $ git grep -n -F 'paymentapi_cpu_high'      (the form the repo's labels use) → no hits.
[10:09] $ git grep -n -F 'CPUUtilization' → no hits.
[10:10] $ git grep -n -F 'aws_cloudwatch_metric_alarm' → no hits (no alarm resource anywhere, so no existing alarm to copy parameters from).
[10:11] $ git log --all --oneline -S'paymentapi-cpu-high'
canned: empty.txt (INDEX `git log * -S*`)
[10:12] $ git log --all --oneline -S'CPUUtilization'
canned: empty.txt
[10:13] $ git log --all --oneline -i --grep='cpu'      (no ticket key was given, so a keyword)
canned: empty.txt (INDEX `git log * --grep=*`)
[10:14] $ git branch -a --list '*cpu*'
canned: empty.txt
[10:15] $ gh pr list --state open --search 'cpu alarm'
canned: gh-pr-list-empty.txt → `no pull requests match your search in acme/paymentapi-infra`
[10:16] $ git branch -a
canned: git-branches.txt → `* main`, `remotes/origin/HEAD -> origin/main`, `remotes/origin/main` (no branch pattern to follow → fallback `iac-change/<service>-<short-description>`)
Verdict: **not done** (code: no hits for the identifiers; git: no history hit; no in-flight branch or PR). Code is not live, so the live batch (alarm-names read) confirms the alarm is absent.

Targets and tiers: targets of this change are staging (account 222222222222) and prod (333333333333). Staging-first (H7) applies: staging exists, the request targets prod.
- staging=staging — proven: `live: aws sts get-caller-identity 10:01` → 222222222222 = `code: envs/staging.tfvars:3` (`aws_account_id`) and the provider pin `code: providers.tf:16`. No other environment shares that account.
- prod=prod — proven: `live: aws sts get-caller-identity 10:02` → 333333333333 = `code: envs/prod.tfvars:3`, `providers.tf:16`.

Lane prediction: no environment is proven dev. L1 (create only — predicted from the request and code), L2 (`aws_cloudwatch_metric_alarm` create is on the allowlist, `lanes.md` › Light-lane allowlist), L3 (one phase per environment, no drift row yet, duplicate check not done), L4 (E1–E3 run on the diff in Step 3). Prediction: **light**. No escalation so far.

App-facing prediction (for Q8): an alarm whose actions are all SNS topics (E1) is predicted not-app-facing (`snapshot.md` › L2 from evidence, Q8). So no app-source search, no `App source:` line, no Q8. The sibling-checkout `ls` is therefore not run.

Snapshot set (not-app-facing change: workload plus front door, no dependents or dependencies, `snapshot.md` › Snapshot set):
- `paymentapi-svc-<env>` ECS service, source `code: main.tf:71-72` (the workload the alarm watches)
- `paymentapi-alb-<env>` load balancer in front of it, source `code: main.tf:84-88, :137` (service → target group) + `live:` target-group read (the load balancer itself is not in the code; the batch names it)
- `paymentapi-cpu-high-<env>` the new alarm — a changed resource with no before state; judged by its success criteria, no health rows
Not snapshotted: the database `paymentapi-<env>-db` and other dependents (not-app-facing change skips them).
`Snapshot coverage: code + live target-group read; no catalog, no runtime profile; not covered: dependents and dependencies (not-app-facing change), callers in other repos.`

Evidence table (live column filled for the first two rows only — the batch runs after `[A]`):

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| staging account / region | `code: envs/staging.tfvars:2-3`, `providers.tf:16` | `live: sts get-caller-identity 10:01` → 222222222222 | ✅ |
| prod account / region | `code: envs/prod.tfvars:2-3`, `providers.tf:16` | `live: sts get-caller-identity 10:02` → 333333333333 | ✅ |
| ECS cluster / service names | `code: main.tf:9`, `main.tf:72` | batch R1 (pending) | pending |
| alarm `paymentapi-cpu-high-<env>` absent | `code: none` (greps 10:07-10:10) | batch R7 (pending) | pending |
| SNS topic `paymentapi-alerts-<env>` and its subscriber protocols | `code: main.tf:174-175` | batch R9 (pending) | pending |
| other alarms on the service | `code: none` | batch R8 (pending) | pending |
| load balancer in front of the service | `code: main.tf:84-88` (target group only) | batch R2 (pending) | pending |
| delivery model | `code: none` | — | UNVERIFIED — asked at `[A]` |
Drift rows: 0. Unverified rows: 1 (delivery model). Gaps: terraform state location (no backend block in code, providers.tf:1-10).

---

## Step 2 — Plan

Single phase per environment (one atomic change: add one alarm). Execution path: direct apply, as the operator asked (elevates pre-flight scoring; the delivery model line passed to pre-flight says so). Staging first, then prod (H7); light lane observation window: prod starts once staging's success criteria pass.

Alarm parameters are not in the request and the repo has no alarm to copy: proposed defaults, corrected at `[A]` if wrong — Average CPUUtilization of the ECS service, > 80 for 3 periods of 300 s, notify `aws_sns_topic.paymentapi_alerts` on ALARM and OK (`UNVERIFIED` defaults, no repo precedent).

Plan self-check (8/8): 1 evidence cited, no destroy/replace/resize; 2 no deletes; 3 rollback + success criteria as commands; 4 no drift rows; 5 path fits (delivery model UNVERIFIED, asked at `[A]`); 6 the one file/resource the request implies is in the phase; 7 lane basis cited; 8 staging precedes prod, observation window named.

Branch (light lane: run now, only because `git status --short` is empty):
[10:17] $ git fetch origin main
canned: empty.txt
[10:18] $ git rev-parse --short origin/main
canned: git-rev-parse.txt → `a1b2c3d` (first 7 characters)
[10:19] $ git switch -c iac-change/paymentapi-cpu-high-alarm origin/main
canned: git-switch.txt → `Switched to a new branch 'iac-change/paymentapi-cpu-high-alarm'`
[10:20] $ git branch --show-current
canned: git-branch-after-switch.txt → `iac-change/paymentapi-cpu-high-alarm`

---

## Step 3 — Implement

Code written to the working tree (light lane: before `[A]`, tree was clean). Diff of the one file:

```diff
diff --git a/main.tf b/main.tf
--- a/main.tf
+++ b/main.tf
@@ -179,3 +179,30 @@ resource "aws_sns_topic" "paymentapi_alerts" {
     Environment = var.env
   }
 }
+
+# ── CloudWatch alarm (ECS CPU) ────────────────────────────────────────────────
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

Formatter (local, shown before running):
[10:21] $ terraform fmt main.tf
canned: empty.txt → no output, already formatted.
Self-check of the diff:
[10:22] $ git status --short
answered from the diff above → ` M main.tf`
[10:23] $ git diff
answered from the diff above.

Diff self-check (6/6): 1 scope — only `main.tf`, the file listed in the plan; 2 plan ↔ hunk — `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create ↔ the one hunk; 3 conventions — name pattern `code: main.tf:175`, snake_case label `main.tf:174`, tags block `main.tf:177-180`, section comment `main.tf:172`; 4 no safety setting weakened (no `prevent_destroy`, `deletion_protection`, `0.0.0.0/0`, `*` in IAM); 5 no secrets, no `tfplan` / state / `.terraform/` in `git status`; 6 formatted (fmt printed nothing).

Note — canned plan vs code: the canned plans show `treat_missing_data = "missing"` and `actions_enabled = true`, which are the provider defaults for the attributes the code leaves out; the plan matches the code. No difference.

Light lane: E1–E3 on the diff.
- E1: `alarm_actions` and `ok_actions` both = `aws_sns_topic.paymentapi_alerts.arn` (code: diff, resource defined `main.tf:174`) → an SNS topic. `insufficient_data_actions` not set. Pass.
- E2: tag keys the diff adds (on a new resource): `Service`, `Environment`. For each, both commands:
[10:24] $ git grep -n -E 'aws:(ResourceTag|RequestTag)/Service|aws:TagKeys'
grep over input files (plus the new hunk) → no hits.
[10:25] $ git grep -n -F 'Service'
→ 7 hits, all `Service     = "paymentapi"` tag-setting lines (main.tf:17, 64, 98, 126, 155, 167, 178) plus the two lines in the new hunk (the tag line; `ServiceName` is a metric dimension key, not a tag). Read each: none is an IAM condition, SCP, backup selection or scheduler; they only set the tag. Cleared.
[10:26] $ git grep -n -E 'aws:(ResourceTag|RequestTag)/Environment|aws:TagKeys' → no hits.
[10:27] $ git grep -n -F 'Environment'
→ `variables.tf:2` (description of `env`) and the tag-setting lines `main.tf:18, 65, 99, 127, 156, 168, 179` (plus the new hunk's). Read each: all set the tag or describe a variable; none reads it as automation. Cleared. Other repos / org SCPs are not visible to these commands (stated).
- E3, written: new alarm — "does this trigger an automated action, or does anything read this value?" No: the only action is the SNS notification, which E1 covers; nothing in the repo reads the alarm (`git grep` 10:07, 10:08: no hits; `outputs.tf` unchanged, no output added). The topic's subscriber protocols are not in the code, so they are read in the batch (R9) and E3 is re-run on that result at 4a.
AMBIGUITY: E3 says "yes or unsure → hit", and the SNS topic's subscribers are not known before the batch runs after `[A]` — read as: E1 owns the question of what an alarm action reaches (SNS topic = pass), E3 answers "no" with its citations, and the live subscriber-protocol read is re-checked at 4a on the plan output.
Fresh eyes: skipped — add-only, no sensitive types (alarm add; touches no IAM, network, DNS, data store, secret/KMS, deletion-protection or lifecycle setting).
E1–E3 on the diff: no hit. Lane stays light.

---

## `[A]` (shown 10:27)

Output root: `.culiops/` at the repo root (CULIOPS_HOME unset): execution record, pre-flight records and the snapshot query files go there.

> **Change requested:** Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR.
> **Service:** `paymentapi` / **Instance:** none
> **IaC tool(s):** Terraform, hashicorp/aws ~> 5.0 (`code: providers.tf:4-9`) · **Delivery model:** UNVERIFIED (no CI / Atlantis / GitOps config in the repo) — asked below · **Env selection:** `-var-file=envs/<env>.tfvars`, default workspace, no backend block (`code: providers.tf:12-17`, `envs/*.tfvars`)
> **Target:** staging — account 222222222222 / ap-southeast-1 (`aws sts get-caller-identity` 10:01); prod — account 333333333333 / ap-southeast-1 (10:02)
> **Environment tier:** staging=staging (proven: `live:` 222222222222 = `code: envs/staging.tfvars:3`, `providers.tf:16`), prod=prod (proven: `live:` 333333333333 = `code: envs/prod.tfvars:3`) · **Lane (predicted):** light — create-only, `aws_cloudwatch_metric_alarm` create is on the allowlist, one phase per environment, no drift row, duplicate check not done; E1 alarm actions = `aws_sns_topic.paymentapi_alerts.arn` (`code: main.tf:174`), E2 tags `Service` / `Environment` set on a new resource and no automation reads them, E3 no; escalations: none
> **Catalog used:** none — proceeding without catalog (consider running service-discovery first)
> **Duplicate check:** not done — `code:` no hit for `paymentapi-cpu-high`, `paymentapi_cpu_high`, `CPUUtilization`, `aws_cloudwatch_metric_alarm`; `git:` no history hit; no in-flight branch or PR
> **Evidence table:** (above) — drift rows: 0, unverified rows: 1
> **Snapshot set:** `paymentapi-svc-<env>` (`code: main.tf:71-72`), `paymentapi-alb-<env>` (`code: main.tf:84-88` + live target-group read), `paymentapi-cpu-high-<env>` (new; judged by its success criteria) · `Snapshot coverage: code + live target-group read; no catalog, no runtime profile; not covered: dependents and dependencies (not-app-facing change), callers in other repos`
> **Gaps remaining:** terraform state location (no backend block), delivery model

> **Change plan for `paymentapi`:**
>
> **Phase 1 of 1: add the CPU alarm — staging, then prod**
> - Files: `main.tf` (add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`)
> - Resources affected: 1 add, 0 change, 0 destroy per environment (`code:` diff; `plan:` confirms at 4a). Alarm name `paymentapi-cpu-high-${var.env}`; proposed parameters (not in your request, no alarm in the repo to copy): Average `AWS/ECS` `CPUUtilization` of the service, > 80 for 3 × 300 s; notify `paymentapi-alerts-<env>` on ALARM and OK — correct them here if wrong
> - Blast radius: the snapshot set above · `Snapshot coverage: …` (as above)
> - Disruption: none — a new alarm touches no running resource (`code:` the diff only adds a resource; `plan:` at 4a)
> - Rollback path: `git revert`, then plan and apply the reverted code per environment (removes only the alarm) — reversible, `untested` (`code:` pure addition, no in-place attribute change)
> - Evidence: the evidence-table rows above
> - Success criteria (per environment, run after its apply; approving `[A]` approves these reads, S2 included):
>   1. `terraform plan -var-file=envs/<env>.tfvars` → `No changes.`
>   2. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-<env> --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,enabled:ActionsEnabled,actions:AlarmActions}'` → one alarm, `state` not `INSUFFICIENT_DATA`, `enabled` true, `actions` = the topic ARN
>   3. `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-<env> Name=ServiceName,Value=paymentapi-svc-<env> --region ap-southeast-1 --query 'MetricAlarms[].AlarmName'` → includes `paymentapi-cpu-high-<env>`
>   4. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-<env> --history-item-type StateUpdate --region ap-southeast-1` → the alarm left `INSUFFICIENT_DATA`
>   5. S2 on the snapshot set: firing alarms (`describe-alarms --state-value ALARM`), ECS running vs desired (`ecs describe-services`), ALB target health (`elbv2 describe-target-health`); no metrics call and no two-period wait (not-app-facing change, `snapshot.md` › When snapshots run)
>
> **Execution path:** direct apply (as you asked; elevates the pre-flight assessment: local workstation apply)
> **Staging-first (H7):** staging, then prod — one `terraform apply tfplan` per environment, staging's first · **Observation window:** prod starts once staging's success criteria pass
> **Branch:** `main` → `iac-change/paymentapi-cpu-high-alarm` from `origin/main` @ `a1b2c3d` (fetched, created, clean tree)
> **Self-check:** 8/8 pass
> **Drift (H4):** none
> **Delivery model:** UNVERIFIED — how does this change reach staging and prod? (you asked for a direct apply; please confirm it is applied by hand from your workstation)
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.

> **Code changes for Phase 1 of 1:**
>
> **Modified:** `main.tf` — adds the CPU alarm (the diff above)
> **Plan ↔ hunk:** `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create → `main.tf` hunk `@@ -179`
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped — add-only, no sensitive types
> **Target:** staging `aws sts get-caller-identity` → 222222222222 / `assumed-role/paymentapi-operator` / ap-southeast-1 (10:01), `envs/staging.tfvars`, tier staging; prod → 333333333333 / same role / ap-southeast-1 (10:02), `envs/prod.tfvars`, tier prod
> **Plan command (4a):** `terraform init` (once; downloads providers and may update `.terraform.lock.hcl`), then `terraform plan -out=tfplan -var-file=envs/staging.tfvars` (read-only against the cloud, staging credentials), and at prod's turn `terraform plan -out=tfplan -var-file=envs/prod.tfvars`
>
> Full diff is in your working tree (`git diff`).

> **Read batch** (each command shown; staging's share runs now, prod's share at prod's turn once staging verifies; `{tg-arn}` and `{lb-id}` come from R2's output and are filled in before the command runs). Region `ap-southeast-1` (`code: envs/*.tfvars:2`). `<env>` = `staging` or `prod`, `<acct>` = 222222222222 / 333333333333.
> Step 1 live reads and drift check:
> - R1 `aws ecs describe-services --cluster paymentapi-cluster-<env> --services paymentapi-svc-<env> --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,taskDef:taskDefinition,targetGroups:loadBalancers[].targetGroupArn,deployCfg:deploymentConfiguration,deployments:deployments[].{status:status,rollout:rolloutState,created:createdAt}}'` (names, running vs desired, deployment time for `iac-change.4`)
> - R2 `aws elbv2 describe-target-groups --names paymentapi-tg-<env> --region ap-southeast-1 --query 'TargetGroups[].{arn:TargetGroupArn,lbs:LoadBalancerArns}'` (names the load balancer in front of the service)
> - R3 `aws elbv2 describe-target-health --target-group-arn {tg-arn} --region ap-southeast-1`
> - R6 `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-<env> Name=ServiceName,Value=paymentapi-svc-<env> --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> - R7 `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-<env> --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue}'` (the alarm must not exist yet)
> - R8 `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> - R9 `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:<acct>:paymentapi-alerts-<env> --region ap-southeast-1 --query 'Subscriptions[].Protocol'` (protocols only, never endpoints)
> - R11 `terraform plan -refresh-only -var-file=envs/<env>.tfvars` (drift check, never applied)
> Assessor L3 reads not listed above: category 10 and 5 are the S0 reads below; category 7 is R6-R8; category 8 is R13; change velocity is R1 + R10; blast radius softeners are in R1 (`deployCfg`); reversibility and dependency reads do not apply to an alarm add.
> - R10 (once) `gh run list --limit 5 --json databaseId,status,conclusion,createdAt,updatedAt,headSha,url` (automation lag, `iac-change.4`)
> - R13 (once) `aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1` (alarm price, lookup date recorded)
> S0 (health snapshot, before; S1 runs on the same approval):
> - R4 `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,ns:Namespace,metric:MetricName,dims:Dimensions,math:Metrics[].MetricStat.Metric.Dimensions},composite:CompositeAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,rule:AlarmRule}}'`
> - R5 `aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-<env>.json --start-time {T-7d-1h} --end-time {now} --scan-by TimestampAscending --query 'MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]}'` (query file: ALB RequestCount, HTTPCode_Target_5XX_Count, HTTPCode_ELB_5XX_Count, TargetResponseTime p95, HealthyHostCount, UnHealthyHostCount; ECS CPUUtilization, MemoryUtilization; one file per environment, metric identifiers only)
> Plan command (4a), per environment: `terraform plan -out=tfplan -var-file=envs/<env>.tfvars`, then `terraform show -no-color tfplan` for the plan hash.
> Post-apply success-criteria reads and S2: as listed in the plan (items 1-5).
> App-source search: not run (not-app-facing change predicted). Incident command: none in the profile.
> The apply commands are not part of this approval: each gets its own `[B]`.
>
> **[A] Approve the plan, the code and these reads?**

query file written by the skill before R5 (staging; prod's is the same with `-prod` names and ids), under the output root, not in the repo tree:
```json
[
  {"Id": "req_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "RequestCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "Sum"}, "Label": "paymentapi-alb-staging RequestCount"},
  {"Id": "m_t5xx_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HTTPCode_Target_5XX_Count", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "err_t5xx_alb", "Expression": "FILL(m_t5xx_alb, 0)", "Label": "paymentapi-alb-staging HTTPCode_Target_5XX_Count"},
  {"Id": "m_e5xx_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HTTPCode_ELB_5XX_Count", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "err_e5xx_alb", "Expression": "FILL(m_e5xx_alb, 0)", "Label": "paymentapi-alb-staging HTTPCode_ELB_5XX_Count"},
  {"Id": "p95_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "TargetResponseTime", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "p95"}, "Label": "paymentapi-alb-staging TargetResponseTime p95"},
  {"Id": "healthy_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HealthyHostCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}, {"Name": "TargetGroup", "Value": "targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09"}]}, "Period": 3600, "Stat": "Minimum"}, "Label": "paymentapi-alb-staging HealthyHostCount"},
  {"Id": "unhealthy_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "UnHealthyHostCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}, {"Name": "TargetGroup", "Value": "targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09"}]}, "Period": 3600, "Stat": "Minimum"}, "Label": "paymentapi-alb-staging UnHealthyHostCount"},
  {"Id": "cpu_ecs", "MetricStat": {"Metric": {"Namespace": "AWS/ECS", "MetricName": "CPUUtilization", "Dimensions": [{"Name": "ClusterName", "Value": "paymentapi-cluster-staging"}, {"Name": "ServiceName", "Value": "paymentapi-svc-staging"}]}, "Period": 3600, "Stat": "Average"}, "Label": "paymentapi-svc-staging CPUUtilization"},
  {"Id": "mem_ecs", "MetricStat": {"Metric": {"Namespace": "AWS/ECS", "MetricName": "MemoryUtilization", "Dimensions": [{"Name": "ClusterName", "Value": "paymentapi-cluster-staging"}, {"Name": "ServiceName", "Value": "paymentapi-svc-staging"}]}, "Period": 3600, "Stat": "Average"}, "Label": "paymentapi-svc-staging MemoryUtilization"}
]
```
(The ALB id and target-group id in the file come from R2's output, so the file is written after R2 runs at 10:41; the batch text above names the file, not its contents. The file is shown here once, in the form it takes.)

STOP 1 id `A`.

### Operator answer to `[A]` (script entry 1, `[A]`) — 10:32 (+5 min)
- approve
- Operator line: no reply (nothing said about it)
- Delivery model: "terraform is applied by hand from my workstation, and a direct apply is fine" — `operator-stated`
- Read batch: approve every command shown, for both environments
- No L2 item was asked at this stop, so none was said. L2 items asked this run: none.

Recorded: `Q1(declared)=no, Q2=no, Q7=none — operator (no objection at [A], 10:32)`. Delivery model = `manual apply from the operator's workstation, direct apply (local workstation apply — not going through CI/CD pipeline) (operator-stated)`. Q4 / Q5 are from the profile (`operator (profile, 2026-10-19)`), nothing to save: no `PROFILE-WRITE`.

---

## After `[A]` — staging's share of the batch (environment taken (b): staging, the plan and reads in progress are for staging; operator holds staging credentials)

[10:33] $ terraform init
canned: terraform-init.txt → providers reused from the lock file, `hashicorp/aws v5.74.0`; initialized. (No change to `.terraform.lock.hcl` reported.)
[10:34] $ terraform plan -refresh-only -var-file=envs/staging.tfvars
canned: plan-refresh-only-staging.txt → `No changes.` No drift for staging.
[10:35] $ R6 aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-staging Name=ServiceName,Value=paymentapi-svc-staging --region ap-southeast-1 --query '…'
canned: alarms-for-metric-cpu-staging.json → `[]` (no alarm on this metric yet).
[10:36] $ R7 aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging --region ap-southeast-1 --query '…'
canned: alarm-cpu-high-before-staging.json → `[]` (the alarm does not exist; duplicate check confirmed live).
[10:37] $ R8 aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query '…'
canned: alarms-prefix-staging-alarm.json (INDEX, `operator-script-alarm-firing.md` row) → one alarm: `paymentapi-alb-elb5xx-staging`, `ALARM` since 2026-11-09 09:56 (StateUpdatedTimestamp 02:56:12Z), `HTTPCode_ELB_5XX_Count` > 5 per 5 min, 2 evaluation periods, actions enabled, action = `paymentapi-alerts-staging`.
[10:38] $ R9 aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging --region ap-southeast-1 --query 'Subscriptions[].Protocol'
canned: sns-subscriptions-staging.json, projected → `["email", "email"]`. (Endpoints not read, not shown.)
[10:39] $ R10 gh run list --limit 5 --json databaseId,status,conclusion,createdAt,updatedAt,headSha,url
canned: gh-run-list-empty.json → `[]` (no CI history).
AMBIGUITY: the automation-lag read of the Terraform state object (`aws s3api head-object --bucket {state-bucket} --key {state-key}`) needs a bucket and key, and the code has no backend block (providers.tf:1-10, `grep backend`: none) — read as: not run, no bucket or key guessed; `iac-change.4` is answered from the ECS deployment time (R1) with the empty CI history stated beside it, and the unread state object goes to pre-flight's "Not verified".
[10:40] $ R13 aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1
canned: pricing-cloudwatch-alarm.json → `$0.10 per alarm metric month (standard resolution)`, ap-southeast-1, publication 2026-10-07; lookup 2026-11-09.
[10:41] $ R2 aws elbv2 describe-target-groups --names paymentapi-tg-staging --region ap-southeast-1 --query 'TargetGroups[].{arn:TargetGroupArn,lbs:LoadBalancerArns}'
canned: tg-describe-staging.json → target group `…:targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09`, load balancer `…:loadbalancer/app/paymentapi-alb-staging/50dc6c495c0c9188` → `{lb-id}` = `app/paymentapi-alb-staging/50dc6c495c0c9188`, `{tg-dim}` = `targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09`. Snapshot member `paymentapi-alb-staging` confirmed (`live:`).
AMBIGUITY: R3 and the query file need values (target-group ARN, load-balancer id) that only R2's output gives, so the batch shows them as `{tg-arn}` / `{lb-id}` placeholders — read as: the approval at `[A]` covers the command with the placeholder filled from R2's output, no new stop.
(query file `.culiops/iac-change-execution/snapshot-queries-staging.json` written now, form shown at `[A]`.)
[10:42] $ R1 aws ecs describe-services --cluster paymentapi-cluster-staging --services paymentapi-svc-staging --region ap-southeast-1 --query 'services[].{…}'
canned: ecs-describe-services-staging.json, projected → status ACTIVE, desired 1, running 1, pending 0, taskDef `paymentapi-staging:8`, targetGroups [`…paymentapi-tg-staging/6d0ecf831eec9f09`], deployCfg {min healthy 100, max 200, circuit breaker off}, deployments [PRIMARY, COMPLETED, createdAt 2026-11-04T08:20:41Z = 2026-11-04 15:20 +07]. Names match `code: main.tf:9, 72`; desired 1 = `envs/staging.tfvars:11`.
[10:43] $ R3 aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09 --region ap-southeast-1
canned: tg-health-staging.json → 1 target, `healthy`.
[10:44] $ R4 aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '…'
canned: alarms-firing-staging-alarm.json (INDEX, `operator-script-alarm-firing.md`: S0/S1 of staging) → `paymentapi-alb-elb5xx-staging` in `ALARM`, dimension `LoadBalancer=app/paymentapi-alb-staging/50dc6c495c0c9188` → on a snapshot-set member (the load balancer). No composite alarms.
[10:45] $ R5 aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-02T02:45:00Z --end-time 2026-11-09T03:45:00Z --scan-by TimestampAscending --query '…'
canned: metric-data-s0-staging-alarm.json (INDEX, S0/S1 of staging) — results matched by `Label` to the skill's labels, given the skill's Ids (`req_alb`, `err_t5xx_alb`, `err_e5xx_alb`, `p95_alb`, `healthy_alb`, `unhealthy_alb`, `cpu_ecs`, `mem_ecs`); the `(1w ago)` labels are the same hour a week earlier. The hour ending now is 09:45-10:45 +07 = 02:45-03:45Z; the canned file carries no timestamps, so values are dated from the end of the window asked.
AMBIGUITY: the S0 query file uses `Period` 3600 (`examples/aws.md` › Reads) but the canned file holds 12 five-minute values per label — read as: the 12 values are the one hourly bucket; count series are summed, gauge averages are the mean of the 12, p95 is the highest of the 12 (an upper bound), and the same for the `(1w ago)` labels.

S0 staging values (hour ending now; same hour last week in brackets):
- `paymentapi-alb-staging` RequestCount 2562 (42.7 per minute) [2523, 42.1 per minute] — ratio 1.02
- target 5xx 0 [0]; **ELB-generated 5xx 127 (2.1 per minute; 4.96% of requests) [0]**; p95 0.120 s [0.122 s]; HealthyHostCount min 1 [1]; UnHealthyHostCount 0 [0]; target health 1/1 healthy
- `paymentapi-svc-staging` CPU mean 11.8% (highest 5-min mean 14.4%); memory mean 27.8%; running 1 / desired 1

Q3 (peak) from S0: 2562 vs 2523 → ratio 1.02, not above 1.5× → `no` (live).
`Q1(alarms)` from S0: **yes** — `paymentapi-alb-elb5xx-staging` firing on the load balancer in the set (live 10:44; other firing alarms: none).
`iac-change.4`: staging's last ECS deployment 2026-11-04 15:20 +07 (5 days ago, live 10:42); no CI history (`gh run list` → `[]`, 10:39); state object not read (above).

Cross-check of the evidence table with the batch: ECS names, running vs desired, target group and load balancer match the code; no alarm exists; SNS subscribers = `email`, `email`; no drift row (refresh-only plan: no changes). The batch found a live alarm, `paymentapi-alb-elb5xx-staging`, that no code in this repo defines (R8 returned it).
AMBIGUITY: Constraint 9 calls code and live disagreeing "drift" (which would be `[H4]` and a light-lane escalation), but this alarm sits on a load balancer the repo does not define and the code makes no claim about it — read as: not drift, no `[H4]`; it is health context (S0, `Q1(alarms)`), kept as a note in the evidence table, not a drift row.
Nothing found that changes the lane or the plan.

### 4a — staging
[10:46] $ aws sts get-caller-identity        (re-check, credentials the plan will use)
canned: identity-staging.json — environment taken (b): staging. Account 222222222222 = pin `code: envs/staging.tfvars:3`. Match; no `[H1]`.
[10:47] $ terraform plan -out=tfplan -var-file=envs/staging.tfvars
canned: plan-staging.txt (before the staging apply) → `Plan: 1 to add, 0 to change, 0 to destroy.` — `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` will be created; `alarm_actions` and `ok_actions` = `arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging` (plan:9-10, 25-26); `alarm_name` `paymentapi-cpu-high-staging`; threshold 80, 3 × 300 s, Average; tags `Environment` / `Service`.
Plan vs code: the canned plan matches what the diff produces (names, values, actions, tags); no difference to note.
Cross-check: the one planned resource is the approved one; action `create` = approved Disruption `none`; no destroy / replace (no `[H3]`); no drift (no `[H4]`); no resource outside the snapshot set.
Confirm the lane from the plan output: L1 create only (`plan: 1 to add, 0 to change, 0 to destroy`), L2 `aws_cloudwatch_metric_alarm` create on the allowlist, L3 one phase / no drift / duplicate check not done, L4: E1 plan value of `alarm_actions` / `ok_actions` is an SNS topic ARN (plan:10, 26); E2 same tag keys `Environment` / `Service`, results as at 10:24-10:27 (tree unchanged since), cleared; E3 re-run with the live subscriber protocols (`email`, `email`, 10:38): the alarm only notifies humans, nothing reads it → no. **Lane confirmed: light. No `plan-confirm`.**
Parity check: n/a (staging).
[10:48] $ terraform show -no-color tfplan
canned: plan-staging.txt (the last plan was for staging)
[10:49] $ sha256sum <scratch file holding the plan text>          (scratch file outside the repo, deleted after)
canned: INDEX › Plan hashes → `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962`

### 4b — S1 and pre-flight (staging)
S1: reuse S0 — its reads ran 10:41-10:45, so at 10:49 it is at most 8 minutes old (4 since the last read), inside 15 minutes. Recorded as `S1 reused, age 4 min`. S1 gives the same `Q1(alarms)` (yes) and Q3 (no) that go to pre-flight.
Reusable pre-flight record: none in `.culiops/pre-flight/` (the fixture has no `.culiops/`). No match → invoke pre-flight in inline mode.

Caller block passed:
```
### Caller context (iac-change-execution)
Target: account 222222222222 / ap-southeast-1 / var-file envs/staging.tfvars, default workspace (no backend block) — aws sts get-caller-identity 10:46 → assumed-role/paymentapi-operator, matches code: envs/staging.tfvars:3
Delivery model: manual apply from the operator's workstation, direct apply — local workstation apply — not going through CI/CD pipeline (operator-stated at [A], 10:32; no CI config in the repo, code: none)
Lane: light — create-only (plan: 1 to add, 0 to change, 0 to destroy), allowlist row aws_cloudwatch_metric_alarm create, one phase per environment, no drift row, duplicate check not done, E1 SNS topic / E2 no automation / E3 no
Plan hash: sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962 (terraform show -no-color tfplan)
L2 answers: Q1(alarms)=yes (live: describe-alarms --state-value ALARM, 10:44: paymentapi-alb-elb5xx-staging in ALARM since 09:56 on the load balancer in the snapshot set) Q1(declared)=no (operator (no objection at [A], 10:32)) Q2=no (operator (no objection at [A], 10:32); no freeze calendar in the repo) Q3=no (live: get-metric-data 10:45, 2562 vs 2523 requests, ratio 1.02) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator (no objection at [A], 10:32)) iac-change.4=recent (live: ecs describe-services 10:42, last deployment 5 days ago; gh run list 10:39 → [] ; state object not read — no backend block)
Live results:
  aws sts get-caller-identity · 10:46 · 222222222222 assumed-role/paymentapi-operator
  terraform plan -refresh-only -var-file=envs/staging.tfvars · 10:34 · no changes
  aws cloudwatch describe-alarms-for-metric (ECS CPUUtilization, staging) · 10:35 · no alarm on the metric
  aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging · 10:36 · none
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi · 10:37 · 1 alarm, paymentapi-alb-elb5xx-staging, ALARM
  aws sns list-subscriptions-by-topic (protocols) · 10:38 · email, email
  gh run list · 10:39 · []
  aws pricing get-products (CloudWatch standard alarm, ap-southeast-1) · 10:40 · $0.10 per alarm metric month, published 2026-10-07
  aws elbv2 describe-target-groups · 10:41 · load balancer app/paymentapi-alb-staging/50dc6c495c0c9188
  aws ecs describe-services · 10:42 · 1/1 running, PRIMARY COMPLETED, deployed 2026-11-04 15:20 +07
  aws elbv2 describe-target-health · 10:43 · 1 healthy
  aws cloudwatch describe-alarms --state-value ALARM (S0) · 10:44 · paymentapi-alb-elb5xx-staging firing (set member: load balancer)
  aws cloudwatch get-metric-data (S0) · 10:45 · request 2562/h, ELB 5xx 127/h (1w ago 0), target 5xx 0, p95 0.120 s (1w 0.122 s), healthy 1, CPU 11.8%, memory 27.8%
Evidence table: staging/prod accounts match pins (code+live); names match (code+live); alarm absent (code none, live none); SNS topic code main.tf:174, live subscribers email ×2; no drift rows; unverified: terraform state location (no backend block), alarm parameters are proposed defaults (operator can correct at [A], approved)
```
Staging evidence section: none (staging is the first environment).

### Pre-flight (inline), staging

Step 1 (inline, no GATE 1): action type Terraform plan, assessor `iac-change`; target, delivery model and plan hash taken from the caller block; output root `.culiops/`.
[10:50] $ aws sts get-caller-identity       (pre-flight target check, inline, no stop)
canned: identity-staging.json — environment taken (b): staging. 222222222222 = caller `Target:`. No mismatch.
Step 2 L1: plan primary (1 create); git history:
[10:51] $ git log --since=7.days --oneline main -- main.tf
canned: empty.txt (INDEX `git log * --since=*`) → 0 commits in 7 days; this change's own edit is uncommitted (excluded).
Step 3 L2: from the caller block — nothing missing: Q1 both parts, Q2, Q3, Q4, Q5, Q7, `iac-change.1-4`. Q6 not asked (L1 scores cost from the plan, priced at 10:40). Q8 not asked: every changed attribute is on the not-app-facing list (a new alarm whose action is an SNS topic whose subscriber protocols are all `email`). The `Q1(alarms)=yes` with `Q1(declared)=no` means no Incident Context follow-up is asked: category 5 stays Red and `[H5]` carries the operator's justification (pre-flight Layer 2, Inline mode). No question asked, so no L2 item said by the operator.
Step 3b: skipped (nothing app-facing). Step 4: caller's results cover every category; no extra batch.

Step 5 — scorecard (staging):

| # | Category | Score | Finding | Evidence |
|---|---|---|---|---|
| 1 | Blast radius | 🟡 | One new alarm, one region (`Plan: 1 to add, 0 to change, 0 to destroy`), Disruption none; raised one notch because the apply runs from a local workstation outside CI/CD (caller `Delivery model:`, SKILL.md 4b) | `plan:42`, `operator-stated` |
| 2 | Reversibility | 🟢 | Pure addition, no in-place attribute change; rollback `git revert` → plan → apply removes the alarm only | `plan:6`, `plan:42` |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; last ECS deployment 5 days ago (limit 90); no CI history; state object not read | `live: git log 10:51`, `live: ecs describe-services 10:42 (caller)` |
| 4 | Dependency impact | 🟢 | Only a not-app-facing alarm is added; no output / export changes (`outputs.tf` untouched) | `plan:6`, `plan:42`, `code: outputs.tf` |
| 5 | Timing context | 🔴 | `Q1(alarms)=yes`: `paymentapi-alb-elb5xx-staging` firing on the load balancer in the set since 09:56. Q1(declared)=no, Q2=no, Q3=no (1.02×). Active incident → Red; no freeze, so not a hard block | `live: describe-alarms --state-value ALARM 10:44 (caller)`, `operator` |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator (profile, 2026-10-19)` |
| 7 | Observability readiness | 🟢 | The change only adds a not-app-facing alarm; no alarm on this metric exists yet (R6 `[]`); mitigation: confirm after apply the new alarm leaves `INSUFFICIENT_DATA` | `plan:6`, `live: describe-alarms-for-metric 10:35 (caller)` |
| 8 | Cost impact | 🟢 | One standard alarm, $0.10 per alarm metric month in ap-southeast-1, price list published 2026-10-07, looked up 2026-11-09 | `live: pricing get-products 10:40 (caller)` |
| 9 | Security posture | 🟡 | No IAM, network, encryption, public-access or secret change; raised one notch for the same workstation-apply reason as category 1 | `plan:6-42`, `operator-stated` |
| 10 | Resource health | 🔴 | Alarm firing on the load balancer: ELB-generated 5xx 127 in the hour (4.96% of requests) against 0 the same hour last week; targets healthy 1/1, target 5xx 0, p95 0.120 s vs 0.122 s, CPU 11.8%, memory 27.8% | `live: describe-alarms 10:44, get-metric-data 10:45, describe-target-health 10:43 (caller)` |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: a new alarm whose action is SNS topic `paymentapi-alerts-staging`, subscriber protocols `email`, `email` | `plan:9-10, 25-26`, `live: sns list-subscriptions 10:38 (caller)` |

AMBIGUITY: SKILL.md 4b says a direct apply "surfaces as elevated risk in blast radius and security posture categories" but pre-flight has no rule for it — read as: both categories are scored Yellow, with the workstation apply as the finding and the provider's account pin (`code: providers.tf:16`) as the mitigation; the verdict for prod depends on this reading (two Yellows, YELLOW) and for staging does not (Red anyway).

Verdict working: Red = categories 5, 10; Yellow + ⚪ = 2 (1, 9); hard blocks checked: category 2 (no irreversible change), 5 (active incident yes, deploy freeze no → no hard block), 9 (no public exposure, encryption removal or secrets), 10 (no SLO declared, no error-budget exhaustion) → **RED — soft block**.
Step 5b: citations re-opened for each Red, each Green on 1/2/4/7/9/10/11 equivalents and the mitigation premises: 14 citations checked, none fixed. Fresh eyes: not required (verdict RED — soft block). Not verified: Q1(declared), Q2, Q7 rest on the operator line (`operator`); terraform state location and last Terraform apply not read (no backend block, no CI); alarm parameters are proposed defaults.

Pre-flight record written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-staging-20261109-1056.md` (content in `preflight-record.md`).

Pre-flight returns RED, so its GATE 2 is the caller's `[H5]`, shown now (10:51):

> **[H5] Staging pre-flight is RED — soft block. Acknowledge each Red finding with a reason, or abort?**
> Verdict: RED — SOFT BLOCK. Scorecard as above; 🔴 category 5 (timing: an alarm is firing on the load balancer in the snapshot set) and 🔴 category 10 (resource health: ELB-generated 5xx 127 in the hour vs 0 a week ago, alarm `paymentapi-alb-elb5xx-staging` in `ALARM` since 09:56). 🟡 categories 1 and 9 (local workstation apply). Everything else green.
> Finding 5: `paymentapi-alb-elb5xx-staging` (`live: describe-alarms --state-value ALARM 10:44`); why it matters: an alarm already firing means the service's front door is misbehaving now, and a new alarm on the same service starts life next to it; mitigation: confirm the alarm is unrelated, or hold the apply until it clears. The new alarm cannot worsen it (`plan:` create only).
> Finding 10: same alarm and the ELB-generated 5xx count (`live: get-metric-data 10:45`); mitigation: S2 will compare the same signals after the apply.
> Not verified: Q1(declared), Q2, Q7 (operator line, no reply), the unread state object, the alarm parameters.

STOP 2 id `H5`.

### Operator answer to `[H5]` (script entry 2, `[H5]` staging) — 10:56 (+5 min)
Acknowledges both Red findings, reason: "known flaky alarm, it has fired and cleared on its own for weeks, unrelated to the CPU alarm".
Recorded in pre-flight's `## Acknowledged Risks`: category 5 and 10 Red, acknowledged `operator` 10:56 with that reason (never rewritten as evidence). Mitigations committed: confirm after apply that the new alarm leaves `INSUFFICIENT_DATA` (this is success criterion 4); S2 compares the firing alarm before and after. Hard blocks: none.

Pre-flight returns to the caller: verdict RED — soft block, acknowledged at `[H5]`.

### `[B]` staging (shown 10:56)

> **[B] Run this apply?** About to run: `terraform apply tfplan` against **staging** — account 222222222222 / `assumed-role/paymentapi-operator` / ap-southeast-1, `envs/staging.tfvars`, default workspace (re-checked 10:46, matches the pin `code: envs/staging.tfvars:3`).
> This will: create `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-staging`) — `Plan: 1 to add, 0 to change, 0 to destroy` (plan hash `sha256:d316b334…4962`). Nothing else changes.
> **Pre-flight verdict:** RED — soft block, acknowledged at `[H5]` 10:56 ("known flaky alarm … unrelated to the CPU alarm"): 🔴 timing and 🔴 resource health (alarm firing on the load balancer), 🟡 blast radius and security posture (local workstation apply). Mitigations committed: confirm the new alarm leaves `INSUFFICIENT_DATA`; S2 compares the firing alarm before and after.
> **S1:** reused, age 4 min (S0 10:41-10:45): 1 alarm firing on the set (`paymentapi-alb-elb5xx-staging`), ELB 5xx 127/h, target health 1/1, CPU 11.8%, memory 27.8%.
> **Staging-first (H7):** this is staging, the first environment — nothing to check. Parity check: n/a.
> **Checked for you:** (correct anything that's wrong)
> - Health: `paymentapi-svc-staging` + `paymentapi-alb-staging` — 1 alarm firing (`paymentapi-alb-elb5xx-staging`, ELB-generated 5xx, since 09:56), target 5xx 0, p95 0.120 s (same hour last week 0.122 s), CPU 11.8%, memory 27.8%, 1 of 1 target healthy · live 10:43-10:45
> - Peak: no — 42.7 requests/min, same hour last week 42.1 · live 10:45
> - Last apply: last ECS deployment 5 days ago (2026-11-04 15:20 +07); no CI history; state object not read (no backend block) · live 10:39-10:42
> - Incident / freeze / other: none — operator (no objection at [A], 10:32); no freeze calendar in the repo, no incident command in the profile
> - Experience: Q4 many times, Q5 experienced — operator (profile, 2026-10-19)
> - Cost: one standard alarm, $0.10 per alarm metric month (price list 2026-10-07) · live 10:40
> Snapshot coverage: code + live target-group read; no catalog, no runtime profile; not covered: dependents and dependencies (not-app-facing change), callers in other repos
> *Heads-up: say so and I draft one for the service owners / on-call with `change-comms` (draft-only; you send it).*

STOP 3 id `B` (staging).

### Operator answer to `[B]` (script entry 3, `[B]` staging) — 11:01 (+5 min)
Approves the apply command shown for staging. (Also acknowledges a YELLOW verdict if one is shown; the verdict is RED and went through `[H5]`.)

### 4c — staging apply
[11:02] $ terraform apply tfplan          (staging; `tfplan` stays local, Constraint 11)
canned: apply-staging.txt → `Creation complete after 1s [id=paymentapi-cpu-high-staging]`, `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
No commit is made on the direct-apply path.
AMBIGUITY: the direct-apply path in Step 4c has no commit step (commit belongs to the PR path) — read as: the approved code stays uncommitted in the working tree of `iac-change/paymentapi-cpu-high-alarm`; the record says `Commit: a1b2c3d (HEAD; change applied, uncommitted)`.

### 5a — staging verification (reads approved at `[A]`)
Re-plan and success criteria:
[11:03] $ terraform plan -var-file=envs/staging.tfvars
canned: plan-after-staging.txt → `No changes. Your infrastructure matches the configuration.` — criterion 1 pass.
[11:04] $ aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,enabled:ActionsEnabled,actions:AlarmActions}'
canned: alarm-cpu-high-after-staging.json → `paymentapi-cpu-high-staging`, `OK`, `true`, actions `[arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging]` — criterion 2 pass.
[11:05] $ aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions … --region ap-southeast-1 --query 'MetricAlarms[].AlarmName'
canned: alarms-for-metric-cpu-after-staging.json → `["paymentapi-cpu-high-staging"]` — criterion 3 pass.
[11:06] $ aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-staging --history-item-type StateUpdate --region ap-southeast-1
canned: alarm-history-after-staging.json, filtered to `StateUpdate` → 1 item, "Alarm updated from INSUFFICIENT_DATA to OK", 2026-11-09T03:17:44Z — criterion 4 pass. (Time note below.)
TIME CONFLICT (not a skill finding): the canned alarm files carry their own times (created 03:17:44Z = 10:17:44 +07 for staging, 03:42:13Z = 10:42:13 +07 for prod), which fall before the dry-run clock at the apply (11:02, 11:31). The protocol says a canned file's own time wins, so the values are quoted as the files give them; the clock is not moved backward, and every skill event keeps the clock time.

S2 for staging — a not-app-facing change: no two-period wait, no ECS rollout to wait for, no metrics call; alarms and point-in-time state once (`snapshot.md` › When snapshots run, Not-app-facing change):
[11:07] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '…'
canned: alarms-firing-after-staging-alarm.json (INDEX, `operator-script-alarm-firing.md`, S2 of staging) → `paymentapi-alb-elb5xx-staging` still in `ALARM` (StateUpdatedTimestamp 02:56:12Z, unchanged: it was firing before the apply); the new `paymentapi-cpu-high-staging` is not in `ALARM`.
[11:08] $ aws ecs describe-services --cluster paymentapi-cluster-staging --services paymentapi-svc-staging --region ap-southeast-1 --query '…'
canned: ecs-describe-services-staging.json → desired 1, running 1, PRIMARY COMPLETED (unchanged).
[11:09] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09 --region ap-southeast-1
canned: tg-health-staging.json → 1 target `healthy`.
AMBIGUITY: `canned/INDEX.md` lists `metric-data-s2-staging-alarm.json` for S2, but v0.20's not-app-facing rule says S2 makes no metrics call and drops metric signals from the counts — read as: the metrics call is not made; the S2 tables hold alarm and point-in-time rows only, and the metric signals are not counted as `no data`.

Comparison (staging, S1 reused vs S2):
- `paymentapi-svc-staging` alarms firing: none → none — ok
- `paymentapi-svc-staging` running vs desired: 1/1 → 1/1 — ok
- `paymentapi-alb-staging` alarms firing: 1 (`paymentapi-alb-elb5xx-staging`, ALARM since 09:56) → 1 (the same alarm, unchanged) — ok: it was already firing before the apply, so it is not newly firing and not `regressed`
- `paymentapi-alb-staging` healthy targets: 1 → 1 — ok
- `paymentapi-cpu-high-staging` (new): no before state, judged by the success criteria (criteria 2-4 pass)
Result: `Snapshot: 4 ok · 0 regressed · 0 no data`. No `[H10]`.

> **Verification for Phase 1 (staging):**
> Re-plan: clean
> Success criteria: re-plan → `No changes.` — pass; `describe-alarms --alarm-names paymentapi-cpu-high-staging` → `OK`, enabled, topic action — pass; `describe-alarms-for-metric` → includes the new alarm — pass; `describe-alarm-history` → left `INSUFFICIENT_DATA` — pass
> Snapshot: 4 ok · 0 regressed · 0 no data — none regressed (the pre-existing `paymentapi-alb-elb5xx-staging` alarm was firing before and is still firing)

Staging verified. Light lane: prod's turn starts now (no stop; observation window = success criteria passed).

---

## Prod — the operator switches the shell profile to prod credentials (no stop). Environment taken (b): prod, for every command below until the prod apply is verified.

Prod's share of the `[A]` batch (approved at `[A]`, run at prod's turn; no prod read other than the identity read ran before staging verified):
[11:10] $ R6 aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query '…'
canned: alarms-for-metric-cpu-prod.json → `[]`.
[11:11] $ R7 aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query '…'
canned: alarm-cpu-high-before-prod.json → `[]` (alarm absent).
[11:12] $ R8 aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query '…'
canned: alarms-prefix-prod.json → `[]` (no alarm on the prod service yet).
[11:13] $ R9 aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod --region ap-southeast-1 --query 'Subscriptions[].Protocol'
canned: sns-subscriptions-prod.json, projected → `["email", "email"]`.
[11:14] $ R2 aws elbv2 describe-target-groups --names paymentapi-tg-prod --region ap-southeast-1 --query '…'
canned: tg-describe-prod.json → target group `…:targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`, load balancer `app/paymentapi-alb-prod/50dc6c495c0c9188`. (query file `snapshot-queries-prod.json` written, prod ids.)
[11:15] $ R1 aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query '…'
canned: ecs-describe-services-prod.json, projected → ACTIVE, desired 3, running 3, pending 0, taskDef `paymentapi-prod:12`, deployments [PRIMARY, COMPLETED, createdAt 2026-10-12T14:02:11Z = 2026-10-12 21:02 +07, 28 days ago]. Names match `code: main.tf:9, 72`; desired 3 = `envs/prod.tfvars:11`.
[11:16] $ R3 aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:333333333333:targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 --region ap-southeast-1
canned: tg-health-prod.json → 3 targets, all `healthy`.
[11:17] $ R4 aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '…'
canned: alarms-firing-prod.json → no firing alarms.
[11:18] $ R5 aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-prod.json --start-time 2026-11-02T03:18:00Z --end-time 2026-11-09T04:18:00Z --scan-by TimestampAscending --query '…'
canned: metric-data-s0-prod.json (S0/S1 of prod; same label matching and aggregation reading as staging)
S0 prod values (hour ending now 10:18-11:18 +07; same hour last week in brackets): `paymentapi-alb-prod` RequestCount 41442 (690.7/min) [40820, 680.3/min], ratio 1.02; target 5xx 0 [0]; ELB 5xx 0 [0]; p95 0.120 s [0.122 s]; HealthyHostCount min 3 [3]; UnHealthyHostCount 0 [0]; target health 3/3 healthy. `paymentapi-svc-prod` CPU mean 37.8% (highest 5-min mean 40.4%), memory mean 51.8%, running 3 / desired 3.
`Q1(alarms)` prod: no (live 11:17, none firing on the set; none firing in the region read). Q3: 41442 vs 40820 → 1.02 → no. `iac-change.4`: last ECS deployment 28 days ago.
[11:19] $ R11 terraform plan -refresh-only -var-file=envs/prod.tfvars
canned: plan-refresh-only-prod.txt → `No changes.` No drift for prod. (`terraform init` ran at 10:33 and is not repeated: same directory, no backend, same providers.)
Cross-check of the prod evidence-table rows: names, counts, target group and load balancer match the code and tfvars; alarm absent; SNS subscribers `email`, `email`; no drift row.

### 4a — prod
[11:20] $ aws sts get-caller-identity
canned: identity-prod.json — environment taken (b): prod. 333333333333 = pin `code: envs/prod.tfvars:3`. Match; no `[H1]`.
[11:21] $ terraform plan -out=tfplan -var-file=envs/prod.tfvars
canned: plan-prod.txt (before the prod apply) → `Plan: 1 to add, 0 to change, 0 to destroy.` — `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` will be created; `alarm_actions` / `ok_actions` = `arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod`; `alarm_name` `paymentapi-cpu-high-prod`.
Plan vs code: matches. Cross-check: only the approved resource, action `create`, no destroy / replace, no drift. Lane re-confirmed: L1-L4 hold, E1 SNS topic ARN in the plan, E2 same keys (cleared 10:24-10:27), E3 no (subscribers `email` ×2, 11:13) → **light, no `plan-confirm`**.
Parity check (H3): staging's plan applied for the same phase: `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create (plan-staging.txt:6). Prod's action, normalised the same way (the address carries no environment name): same address, same action `create` → **pass**.
[11:22] $ terraform show -no-color tfplan
canned: plan-prod.txt (the last plan was for prod)
[11:23] $ sha256sum <scratch file holding the plan text>
canned: INDEX › Plan hashes → `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8`

### 4b — S1 and pre-flight (prod)
S1: reuse prod's S0 (reads 11:14-11:18, age 5 min at 11:23 since the last read). `Q1(alarms)`=no and Q3=no, as S0. Timing re-ask: staging's answers do not carry over; prod's S1 answers go to pre-flight, together with the operator-line answers given at `[A]`.
No reusable pre-flight record (a staging record never matches: other plan hash and target). Invoke inline.

Caller block (prod):
```
### Caller context (iac-change-execution)
Target: account 333333333333 / ap-southeast-1 / var-file envs/prod.tfvars, default workspace (no backend block) — aws sts get-caller-identity 11:20 → assumed-role/paymentapi-operator, matches code: envs/prod.tfvars:3
Delivery model: manual apply from the operator's workstation, direct apply — local workstation apply — not going through CI/CD pipeline (operator-stated at [A], 10:32; no CI config in the repo, code: none)
Lane: light — create-only (plan: 1 to add, 0 to change, 0 to destroy), allowlist row aws_cloudwatch_metric_alarm create, one phase per environment, no drift row, E1 SNS topic / E2 no automation / E3 no
Plan hash: sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8 (terraform show -no-color tfplan)
L2 answers: Q1(alarms)=no (live: describe-alarms --state-value ALARM, 11:17: 0 firing on the snapshot set) Q1(declared)=no (operator (no objection at [A], 10:32)) Q2=no (operator (no objection at [A], 10:32); no freeze calendar in the repo) Q3=no (live: get-metric-data 11:18, 41442 vs 40820 requests, ratio 1.02) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator (no objection at [A], 10:32)) iac-change.4=recent (live: ecs describe-services 11:15, last deployment 28 days ago; gh run list 10:39 → []; state object not read — no backend block)
Live results:
  aws sts get-caller-identity · 11:20 · 333333333333 assumed-role/paymentapi-operator
  terraform plan -refresh-only -var-file=envs/prod.tfvars · 11:19 · no changes
  aws cloudwatch describe-alarms-for-metric (ECS CPUUtilization, prod) · 11:10 · no alarm on the metric
  aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod · 11:11 · none
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi · 11:12 · none
  aws sns list-subscriptions-by-topic (protocols) · 11:13 · email, email
  aws pricing get-products (CloudWatch standard alarm, ap-southeast-1) · 10:40 · $0.10 per alarm metric month, published 2026-10-07
  aws elbv2 describe-target-groups · 11:14 · load balancer app/paymentapi-alb-prod/50dc6c495c0c9188
  aws ecs describe-services · 11:15 · 3/3 running, PRIMARY COMPLETED, deployed 2026-10-12 21:02 +07
  aws elbv2 describe-target-health · 11:16 · 3 healthy
  aws cloudwatch describe-alarms --state-value ALARM (S0) · 11:17 · none firing
  aws cloudwatch get-metric-data (S0) · 11:18 · request 41442/h, target 5xx 0, ELB 5xx 0, p95 0.120 s (1w 0.122 s), healthy 3, CPU 37.8%, memory 51.8%
Evidence table: prod account matches pin (code+live); names and counts match (code+live); alarm absent (code none, live none); SNS topic code main.tf:174, live subscribers email ×2; no drift rows; unverified: terraform state location (no backend block), alarm parameters are proposed defaults (approved at [A])
Staging evidence (evidence, not proof):
  Measured disruption during staging's apply: none — apply took 1 s, 1 resource added (apply-staging.txt), ECS 1/1 running before and after (live: aws ecs describe-services (staging, 11:08))
  Staging success criteria: re-plan No changes (live: terraform plan (staging, 11:03)); alarm paymentapi-cpu-high-staging OK, enabled, topic action (live: describe-alarms (staging, 11:04)); alarm listed on the metric (live: describe-alarms-for-metric (staging, 11:05)); alarm left INSUFFICIENT_DATA (live: describe-alarm-history (staging, 11:06))
  Staging S1 (reused S0, 10:41-10:45) and S2 (11:07-11:09): 4 ok · 0 regressed · 0 no data; paymentapi-alb-elb5xx-staging was firing before and after (live: describe-alarms --state-value ALARM (staging, 10:44 and 11:07)); no regressed value, no override
  Size differences between the var-files: desired_count 1 vs 3 (code: envs/staging.tfvars:11 vs envs/prod.tfvars:11); task_cpu 256 vs 512 (:12); task_memory 512 vs 1024 (:13); image_tag v2.5.0-rc2 vs v2.4.1 (:10)
```

Pre-flight (inline), prod:
[11:24] $ aws sts get-caller-identity       (pre-flight target check)
canned: identity-prod.json — environment taken (b): prod. = caller `Target:`.
[11:25] $ git log --since=7.days --oneline main -- main.tf
canned: empty.txt → 0 commits in 7 days (this change's own edit is uncommitted, excluded).
L2: nothing missing, nothing asked (same reasoning as staging; `Q1(alarms)=no` so no Incident Context follow-up question). Step 3b skipped (not-app-facing: new alarm, SNS action, subscribers `email` ×2).

Scorecard (prod):

| # | Category | Score | Finding | Evidence |
|---|---|---|---|---|
| 1 | Blast radius | 🟡 | One new alarm, one region (`Plan: 1 to add, 0 to change, 0 to destroy`), Disruption none; raised one notch because the apply runs from a local workstation outside CI/CD | `plan:42`, `operator-stated` |
| 2 | Reversibility | 🟢 | Pure addition; rollback `git revert` → plan → apply removes only the alarm | `plan:6`, `plan:42` |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in 7 days; last ECS deployment 28 days ago (limit 90); the uncommitted edit is this change itself, not a prior change | `live: git log 11:25`, `live: ecs describe-services 11:15 (caller)` |
| 4 | Dependency impact | 🟢 | Only a not-app-facing alarm is added; no output / export change | `plan:6`, `plan:42`, `code: outputs.tf` |
| 5 | Timing context | 🟢 | `Q1(alarms)=no` (none firing on the set), Q1(declared)=no, Q2=no, Q3=no (1.02×); the operator is applying live. Staging's firing alarm is staging's only (staging evidence, not proof) | `live: describe-alarms 11:17 (caller)`, `live: get-metric-data 11:18 (caller)`, `operator` |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator (profile, 2026-10-19)` |
| 7 | Observability readiness | 🟢 | Only adds a not-app-facing alarm; no alarm on this metric yet (R6 `[]`); mitigation: confirm after apply the alarm leaves `INSUFFICIENT_DATA` | `plan:6`, `live: describe-alarms-for-metric 11:10 (caller)` |
| 8 | Cost impact | 🟢 | One standard alarm, $0.10 per alarm metric month, ap-southeast-1, price list 2026-10-07, looked up 2026-11-09 | `live: pricing get-products 10:40 (caller)` |
| 9 | Security posture | 🟡 | No IAM, network, encryption, public-access or secret change; raised one notch for the workstation apply | `plan:6-42`, `operator-stated` |
| 10 | Resource health | 🟢 | No alarm firing; target 5xx 0 and ELB 5xx 0 of 41442 requests; p95 0.120 s vs 0.122 s a week ago; CPU 37.8%, memory 51.8% (< 70%); 3 of 3 targets healthy | `live: describe-alarms 11:17, get-metric-data 11:18, describe-target-health 11:16 (caller)` |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: new alarm, SNS topic `paymentapi-alerts-prod`, subscriber protocols `email`, `email` | `plan:9-10, 25-26`, `live: sns list-subscriptions 11:13 (caller)` |

Verdict working: Red = none; Yellow + ⚪ = 2 (1, 9); hard blocks checked: 2, 5, 9, 10 → none → **YELLOW — proceed with caution**. Step 5b: citations re-opened (15 checked, none fixed). Fresh eyes: required for YELLOW — `fresh-eyes: not run — dry run`. Not verified: Q1(declared), Q2, Q7 (operator line); the unread state object and last Terraform apply; the alarm parameters; staging evidence is evidence, not proof.
Mitigations (Yellow 1, 9): apply only the approved `tfplan` of this working tree; the provider pins the account (`code: providers.tf:16`) and the 4a re-check matched 333333333333 at 11:20.
Pre-flight record written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-prod-20261109-1125.md` (in `preflight-record.md`). Inline, GREEN / YELLOW: no GATE 2; the verdict goes to the caller and the operator acknowledges it at `[B]`. No `[H5]` for prod.

### `[B]` prod (shown 11:25)

H7 check before this `[B]` (its mutation applies prod): staging applied 11:02 with its success criteria passed and no regression → satisfied.

> **[B] Run this apply?** About to run: `terraform apply tfplan` against **prod** — account 333333333333 / `assumed-role/paymentapi-operator` / ap-southeast-1, `envs/prod.tfvars`, default workspace (re-checked 11:20, matches the pin `code: envs/prod.tfvars:3`).
> This will: create `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`) — `Plan: 1 to add, 0 to change, 0 to destroy` (plan hash `sha256:1e420453…3fc8`). Nothing else changes.
> **Phase 1 success criteria (staging):** re-plan `No changes` — pass; alarm `paymentapi-cpu-high-staging` `OK`, enabled, topic action — pass; listed on the metric — pass; left `INSUFFICIENT_DATA` — pass. **Snapshot (staging):** 4 ok · 0 regressed · 0 no data (the pre-existing `paymentapi-alb-elb5xx-staging` alarm was firing before and after).
> **Staging-first (H7):** applied — staging 11:02. **Parity check:** pass (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create in both plans).
> **Pre-flight verdict:** YELLOW — proceed with caution. 🟡 blast radius and 🟡 security posture: local workstation apply, outside CI/CD. Mitigation: apply only this approved `tfplan`; the provider pins account 333333333333 and the target re-check matched at 11:20. All other categories green. Approving here acknowledges the Yellow findings.
> **S1:** reused, age 5 min (S0 11:14-11:18): 0 alarms firing on the set, target 5xx 0, ELB 5xx 0, p95 0.120 s, 3 of 3 targets healthy, CPU 37.8%, memory 51.8%.
> **Checked for you:** (correct anything that's wrong)
> - Health: `paymentapi-svc-prod` + `paymentapi-alb-prod` — 0 alarms firing, target 5xx 0 and ELB 5xx 0, p95 0.120 s (same hour last week 0.122 s), CPU 37.8%, memory 51.8%, 3 of 3 targets healthy · live 11:16-11:18
> - Peak: no — 690.7 requests/min, same hour last week 680.3 · live 11:18
> - Last apply: last ECS deployment 28 days ago (2026-10-12 21:02 +07); no CI history; state object not read (no backend block) · live 10:39, 11:15
> - Incident / freeze / other: none — operator (no objection at [A], 10:32); no freeze calendar in the repo, no incident command in the profile
> - Experience: Q4 many times, Q5 experienced — operator (profile, 2026-10-19)
> - Cost: one standard alarm, $0.10 per alarm metric month (price list 2026-10-07) · live 10:40
> Snapshot coverage: code + live target-group read; no catalog, no runtime profile; not covered: dependents and dependencies (not-app-facing change), callers in other repos
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
> *Heads-up: say so and I draft one for the service owners / on-call with `change-comms` (draft-only; you send it).*

(First stop of prod, after pre-flight: the Timing re-ask puts the operator line here. The S1 answers equal those pre-flight got, so an unchanged answer proceeds.)

STOP 4 id `B` (prod).

### Operator answer to `[B]` (script entry 4, `[B]` prod) — 11:30 (+5 min)
Approves the apply command shown for prod; that also acknowledges the Yellow verdict. Operator line: no reply (nothing said). "If asked again whether the incident, freeze and peak answers still hold: yes, unchanged" — not asked as a separate question; the operator line is the re-ask. Recorded: `Q1(declared)=no, Q2=no, Q7=none — operator (no objection at [B], 11:30)`. The answers are unchanged, so pre-flight is not re-run and no new `[B]` is shown.

### 4c — prod apply
[11:31] $ terraform apply tfplan          (prod)
canned: apply-prod.txt → `Creation complete after 1s [id=paymentapi-cpu-high-prod]`, `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

### 5a — prod verification
[11:32] $ terraform plan -var-file=envs/prod.tfvars
canned: plan-after-prod.txt → `No changes. Your infrastructure matches the configuration.` — criterion 1 pass.
[11:33] $ aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query '…'
canned: alarm-cpu-high-after-prod.json → `paymentapi-cpu-high-prod`, `OK`, enabled `true`, actions `[arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod]` — criterion 2 pass.
[11:34] $ aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].AlarmName'
canned: alarms-for-metric-cpu-after-prod.json → `["paymentapi-cpu-high-prod"]` — criterion 3 pass.
[11:35] $ aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod --history-item-type StateUpdate --region ap-southeast-1
canned: alarm-history-after-prod.json, filtered → "Alarm updated from INSUFFICIENT_DATA to OK", 2026-11-09T03:42:13Z — criterion 4 pass (canned time precedes the clock, see the time note above).
S2 for prod (alarms and point-in-time state once; no metrics call, no two-period wait):
[11:36] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '…'
canned: alarms-firing-after-prod.json → none firing; the new alarm exists and is not in `ALARM`.
[11:37] $ aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query '…'
canned: ecs-describe-services-prod.json → desired 3, running 3, PRIMARY COMPLETED.
[11:38] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:333333333333:targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 --region ap-southeast-1
canned: tg-health-prod.json → 3 targets `healthy`.

Comparison (prod, S1 reused vs S2): svc alarms none → none ok; svc running vs desired 3/3 → 3/3 ok; alb alarms none → none ok; alb healthy targets 3 → 3 ok; `paymentapi-cpu-high-prod` (new) judged by the success criteria (2-4 pass). `Snapshot: 4 ok · 0 regressed · 0 no data`. No `[H10]`.

> **Verification for Phase 1 (prod):**
> Re-plan: clean
> Success criteria: re-plan → `No changes.` — pass; alarm `OK`, enabled, topic action — pass; listed on the metric — pass; left `INSUFFICIENT_DATA` — pass
> Snapshot: 4 ok · 0 regressed · 0 no data — none regressed

### 5b — record
Execution record written to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1139.md` (content in `record.md`). Not committed (it sits at the repo's `.culiops/`; commit is offered in the `Next:` line).

### Final message (11:39)
> **Outcome:** completed — the CPU alarm `paymentapi-cpu-high-<env>` is applied and verified in staging (11:02) and prod (11:31); no snapshot member regressed. The `paymentapi-alb-elb5xx-staging` alarm was already firing in staging before the apply and still is (acknowledged at `[H5]`).
> **Record:** `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1139.md`
> Next: commit the record (.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1139.md) · draft the result or ticket-close message with change-comms

End of run. Stops: 4 (`A`, `H5`, `B` staging, `B` prod), none unscripted. No `no canned output` command. Operator-line replies: none. Pre-flight L2 items asked of the operator: none.
