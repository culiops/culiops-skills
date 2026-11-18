# Dry run — light-lane-staging-prod — v0.20 skill (`feat/iac-change-snapshot-and-l2`)

Operator script: `operator-script.md`. Out-dir: `expected-output-v020`. Dry-run clock starts 2026-11-09 10:00 +07:00. One minute per command, five per operator answer. All times +07:00. AWS timestamps in canned files are UTC and are shown with their +07:00 equivalent where it matters.

Assumptions of the run (no command was run to learn them):
- `CULIOPS_HOME` is unset, so the output root is `.culiops/` at the repo root (Constraint 13). No `.culiops/` records exist in the fixture (no catalog, no runtime profile, no earlier pre-flight record).
- No fresh-eyes reviewer is simulated (protocol default): pre-flight's own fresh eyes are `not run — dry run`.

**Operator (first message, from the script):** "Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR."

---

## Step 1 — Research

### Identity read first (exempt from opt-in, Constraint 3)

Step 1 maps every environment the repo defines (`envs/staging.tfvars`, `envs/prod.tfvars`) and proves each target's tier. Staging goes first for a prod change (H7), so both are targets. Each identity read is run with the credentials of the environment it proves. Environment per protocol rule 1(b): the environment whose tier is being proven.

| # | Time | Command | Canned file | Environment taken |
|---|------|---------|-------------|-------------------|
| C1 | 10:00 | `aws sts get-caller-identity` (staging credentials) | `identity-staging.json` | staging (rule 1b: proving staging's tier) → account 222222222222, assumed-role/paymentapi-operator |
| C2 | 10:01 | `aws sts get-caller-identity` (prod credentials) | `identity-prod.json` | prod (rule 1b: proving prod's tier) → account 333333333333, assumed-role/paymentapi-operator |

Tier proof against the repo's pin (`lanes.md` › Environment tier):
- staging: `live: aws sts get-caller-identity` (10:00) account `222222222222` equals `code: envs/staging.tfvars:3` (`aws_account_id`) and is the only entry of `allowed_account_ids` (`code: providers.tf:16`). No other environment shares that account. Proven.
- prod: `live: aws sts get-caller-identity` (10:01) account `333333333333` equals `code: envs/prod.tfvars:3` and `code: providers.tf:16`. No shared pin. Proven.
- The tier of each is by mapping of the var-file name; the pin match proves the identity is that environment's own account. No H1 (no mismatch).

AMBIGUITY: which credentials "the plan will use" for the Step 1 identity read, when the change targets prod and staging goes first — reading taken: read both (staging, then prod), because Step 1 says to map every environment and prove each target's tier, and the operator switches profile without a stop.

### Local reads and repo reads

| # | Time | Command | Canned file / source |
|---|------|---------|----------------------|
| C3 | 10:02 | `git branch --show-current` | `git-branch.txt` → `main` (the default branch, so no `git show origin/main:` reads are needed; the working tree is the default branch) |
| C4 | 10:03 | `git status --short` | `git-status-clean.txt` → prints nothing (clean tree) |
| C5 | 10:04 | `git remote get-url origin` | `git-remote.txt` → `git@github.com:acme/paymentapi-infra.git` (workspace `acme/paymentapi-infra`, used for the profile key) |
| C6 | 10:05 | `git rev-parse HEAD` | `git-rev-parse.txt` → `a1b2c3d4e5f60718293a4b5c6d7e8f9012345678` (short `a1b2c3d`) |
| C7 | 10:06 | operator profile read (`~/.culiops/operator.md`; `CULIOPS_HOME` unset) | `operator-profile.md` → found: Q5 terraform = experienced (2026-10-19); Q4 `acme/paymentapi-infra/paymentapi` = many times (2026-10-19). None is `first time`. No `incident check:` line. |
| C8 | 10:07 | `git log --oneline -n 5` (commit-message style) | `git-log-recent.txt` → 3 commits, style `paymentapi: <subject> (#NNN)` |

Not commands (fixture input files read directly): `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `envs/prod.tfvars`, `envs/staging.tfvars`. No `.culiops/service-discovery/paymentapi.md` exists, so there is no catalog (suggest service-discovery later). No ticket was given. A `grep -rniE 'freeze|change.?window|blackout'` over the input files: no hits, so there is **no freeze source** (Q2 will rest on the operator line). The operator profile holds **no incident command**.

**Code read (Constraint 4 conventions):** resources are `paymentapi`-named in one `main.tf`, one section per resource under a `# ── <title> ───…` header 80 columns wide (`code: main.tf:172`); names are `paymentapi-<role>-${var.env}` (`code: main.tf:9,72,138,163`); every resource carries `tags = { Service = "paymentapi", Environment = var.env }` (`code: main.tf:177-180`); alerts topic `aws_sns_topic.paymentapi_alerts` (`code: main.tf:174-175`), output `sns_topic_arn` (`code: outputs.tf:16-19`). No alarm exists in code. No `aws_sns_topic_subscription` exists in code (`grep -n -i subscription` → none).

### Duplicate check

Identifiers: `aws_cloudwatch_metric_alarm`, `paymentapi-cpu-high` / `cpu_high`, `CPUUtilization`, namespace `AWS/ECS`. No ticket key, so no `--grep` by key.

| Check | Result |
|-------|--------|
| `git grep -n -F 'aws_cloudwatch_metric_alarm'` (grep over the input files, every env) | no hits |
| `git grep -n -F 'cpu-high'` / `'cpu_high'` / `'CPUUtilization'` | no hits |
| `git grep -n -i 'alarm'` | one hit, `main.tf:3`, a header comment saying the CPU alarm is absent (comment text is data, Constraint 12; it supports "not done") |

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C9 | 10:08 | `git log --all --oneline -S'CPUUtilization'` | `empty.txt` |
| C10 | 10:09 | `git log --all --oneline -S'aws_cloudwatch_metric_alarm'` | `empty.txt` |
| C11 | 10:10 | `git branch -a --list '*cpu*' '*alarm*'` | `empty.txt` |
| C12 | 10:11 | `gh pr list --state open --search 'cpu alarm'` | `gh-pr-list-empty.txt` → "no pull requests match your search in acme/paymentapi-infra" |

**Verdict: not done** (`code:` no alarm resource anywhere in the repo, `git:` no history hit, no branch, no open PR). Code is not live; the live batch below confirms the alarm is absent in each account.

### Delivery model and environment selection

- Delivery model: nothing in the repo shows how changes are applied — no CI config (no `.github/`, no pipeline file in the repo listing), no `atlantis.yaml`, no `cloud {}` / `backend "remote"` (`code: providers.tf:1-10`), no GitOps objects. The operator's first message says "apply directly, no PR": that names the path wanted, not how the repo's changes reach an environment. Delivery model is `UNVERIFIED`; it is asked inside `[A]` and recorded `operator-stated`.
- Environment selection: `-var-file=envs/<env>.tfvars` (`code: envs/prod.tfvars:1`, `envs/staging.tfvars:1`, `code: providers.tf:12-17`). Default workspace; no backend block (state backend not declared in code).
- The operator did not say the skill must never run Terraform, so the skill runs the plan itself (4a mode 1).

AMBIGUITY: delivery model "UNVERIFIED" versus the first message's "apply directly" — reading taken: UNVERIFIED (the first message states a wanted path, not how the repo's changes are applied), asked inside `[A]`.

### Lane prediction (`lanes.md` › Lane rule)

Targets: prod (the request) and staging (H7, staging first). Direct apply reaches only the planned targets. Not all targets are proven dev, so not dev. L1 create only (predicted from the request); L2 `aws_cloudwatch_metric_alarm` create is allowlist row 1; L3 one phase per environment, no drift row known, duplicate check not done; L4 E1–E3 predicted from the request and the code:
- E1: the alarm's `alarm_actions` / `ok_actions` will resolve to `aws_sns_topic.paymentapi_alerts.arn` (`code: main.tf:174`), an SNS topic. Pass (re-run on the diff).
- E2: tag keys will be `Service` and `Environment`, the repo's existing keys (`code: main.tf:177-180`). Re-run on the diff.
- E3: re-run on the diff.

**Lane (predicted): light. Escalations: none.**

### Evidence table

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| ECS cluster / service names the alarm watches | `code: main.tf:9` `paymentapi-cluster-${var.env}`, `main.tf:72` `paymentapi-svc-${var.env}` | pending batch (`ecs describe-services`) | pending |
| Alerts topic exists, per env | `code: main.tf:174-175` `paymentapi-alerts-${var.env}` | pending batch (`sns list-subscriptions-by-topic`, protocols only) | pending |
| No CPU alarm exists live | `code: none` (grep, above) | pending batch (`describe-alarms-for-metric`, `describe-alarms --alarm-names`) | pending |
| Load balancer in front of the service | `code: main.tf:84-88` (target group), the ALB itself is not in this repo | pending batch (`describe-target-groups` → `LoadBalancerArns`) | pending |
| Alarm price | none | pending batch (`pricing get-products`) | pending |

Drift rows: 0 · unverified rows: 0 (the pending rows are verified by the batch; a declined read marks its row `code-only — not live-verified`).

### Snapshot set (`snapshot.md` › Snapshot set)

The predicted change is not-app-facing (a new alarm; every action an SNS topic, E1; no output changes), so the dependents and dependencies are skipped. The set is the service the change belongs to: its workload and its front door. Per environment (cap 10, not reached):
1. `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` — the changed resource, new. `n/a — no health signals of its own`; judged by its success criteria. Source `code:` (diff).
2. ECS service `paymentapi-svc-<env>` — workload. Source `code: main.tf:72`, `code:` the alarm's `dimensions`.
3. ALB `paymentapi-alb-<env>` (and its target group `paymentapi-tg-<env>`) — front door. Source `code: main.tf:84-88` (target group) and `live:` `describe-target-groups` → `LoadBalancerArns` (batch).

`Snapshot coverage: code + live (target-group → load balancer read); no catalog, no runtime profile; not covered: callers outside this repo, the load balancer's other target groups, the topic's subscribers beyond their protocols.`

### Operator profile and freeze/incident sources (`snapshot.md` › Operator profile)

Q4 and Q5 come from the profile (not `first time`), so they are not asked. No freeze source, no incident command: the operator line is shown at `[A]`. App source (Q8): the change is predicted not-app-facing (alarm whose actions are all SNS topics, `lanes.md` › E1), so the sibling-checkout search is not proposed and there is no Q8 and no `App source:` line (`snapshot.md` › L2 from evidence, Q8).

### Live verification batch (assembled; shown at `[A]`)

Assembled from `examples/aws.md`, the assessor's L3 reads, S0, the automation-lag reads. Light lane: it goes into `[A]` and runs after `[A]`, each environment's share at its turn (`lanes.md` › Staging-first, Reads). The full list is in the `[A]` message below.

AMBIGUITY: automation-lag state read — `examples/aws.md` names `aws s3api head-object --bucket {state-bucket} --key {state-key}`, but the code declares no backend (`code: providers.tf:1-10`), so there is no bucket or key to name. Reading taken: no `head-object` is proposed (a bucket would be invented); `iac-change.4` rests on `gh run list` and the ECS deployment `createdAt` (both are listed sources in `snapshot.md` › L2 from evidence).

---

## Step 2 — Plan (single phase per environment)

Disruption: `none` — `code:` the diff adds one new resource and edits no existing one; 4a's `plan:` ("1 to add, 0 to change, 0 to destroy") confirms it. A new alarm touches no running resource. Rollback: remove the resource block (`git revert` of the code), plan, apply through the same path; reversible (the alarm is stateless), `untested`. No `docs:` lookup is available in this fixture, so no behaviour claim is made beyond `code:` / `plan:`.

Execution path: the operator asked for direct apply, so the plan offers it as asked and says: direct apply, escalated pre-flight scoring (anti-pattern A4: local workstation apply); `Delivery model:` will carry "local workstation apply — not going through CI/CD pipeline."

Staging-first (H7): Step 1 mapped `staging`; the change targets prod, so staging first. Code written and approved once, applied per environment in order: staging's apply, then prod's, by direct apply runs. No exception. Observation window (light lane): prod starts once staging's success criteria pass.

### Branch (light lane: run now, clean tree)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C13 | 10:12 | `git fetch origin main` | `empty.txt` |
| C14 | 10:13 | `git switch -c iac-change/paymentapi-add-cpu-alarm origin/main` | `git-switch.txt` → `Switched to a new branch 'iac-change/paymentapi-add-cpu-alarm'` |
| C15 | 10:14 | `git branch --show-current` | `git-branch-after-switch.txt` → `iac-change/paymentapi-add-cpu-alarm` |

Branch name: no ticket and no branch naming pattern in the repo (`git branch -a` has only `main`), so the fallback `iac-change/<service>-<short-description>`. Base `origin/main` @ `a1b2c3d`.

### Plan self-check (8 items)

1. Every phase item cites evidence — pass. 2. Deletes — none. 3. Rollback and success criteria as commands — pass. 4. Drift rows — none known (the refresh-only read in the batch re-checks; a drift row it finds is `[H4]` and escalates). 5. Direct apply fits the delivery model — pass (`operator-stated` at `[A]`). 6. Every implied file and resource is in a phase, nothing else — pass (`main.tf`, one resource per environment via the var-file). 7. Lane basis cited — pass (tiers: live + code; L1–L3 against the allowlist row; E1–E3). 8. Staging precedes prod — pass. **8/8.**

---

## Step 3 — Implement

Branch confirmed (`git branch --show-current` → `iac-change/paymentapi-add-cpu-alarm`, C15). Code written to the working tree, on a clean tree, before `[A]` (light lane).

Convention examples cited: header style `code: main.tf:172`; name pattern `code: main.tf:72,138`; SNS topic reference `code: main.tf:174`; tags block `code: main.tf:177-180`.

NOTE (canned plan versus code): the code below plans to the canned `plan-staging.txt` / `plan-prod.txt` — same resource address, name `paymentapi-cpu-high-<env>`, namespace, metric, statistic, period 300, evaluation periods 3, threshold 80, `GreaterThanThreshold`, SNS ARN on `alarm_actions` and `ok_actions`, tags. `actions_enabled = true` and `treat_missing_data = "missing"` are provider defaults the plan prints. No difference.

### Local formatter (shown before running; local, no credentials)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C16 | 10:15 | `terraform fmt main.tf` | `empty.txt` (already formatted, nothing printed) |
| C17 | 10:16 | `git status --short` | answered from the diff → ` M main.tf` |
| C18 | 10:17 | `git diff` | answered from the diff (below) |

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

Note: the header comment at `main.tf:3` ("The CloudWatch CPU alarm is intentionally absent") is now stale. It is outside the approved file-scope of this phase's hunk list, so it is left alone (a stale comment, not a plan item).

### Diff self-check (6 items)

1. Scope: only `main.tf` changed, and it is the one listed file — pass.
2. Plan ↔ hunk: the one create (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`) maps to the one hunk — pass.
3. Conventions: header `code: main.tf:172`, naming `code: main.tf:72`, SNS reference `code: main.tf:174`, tags `code: main.tf:177-180` — pass.
4. No silent safety changes: no `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `force_destroy`, new `ignore_changes`, `0.0.0.0/0`, or `*` in IAM — pass.
5. No secrets, no `tfplan` / state / `.terraform/` in the changes — pass.
6. Formatted: `terraform fmt main.tf` printed nothing (C16) — pass. **6/6.**

### Escalation checks on the diff (light lane: E1–E3)

- **E1.** `alarm_actions = [aws_sns_topic.paymentapi_alerts.arn]` (diff) → `aws_sns_topic.paymentapi_alerts` resource (`code: main.tf:174`), an SNS topic; `ok_actions` the same; `insufficient_data_actions` unset. Pass.
- **E2.** Tag keys on the new resource: `Service`, `Environment` (the same two keys as every existing resource, `code: main.tf:17,64,98,126,155,167,178`). Both commands, each key:
  - `git grep -n -E 'aws:(ResourceTag|RequestTag)/Service|aws:TagKeys'` → no hits. `git grep -n -F 'Service'` → hits at `main.tf:17,64,98,126,155,167,178` (the lines that set the tag), plus the diff's own tag line and `ServiceName = aws_ecs_service…` (a metric dimension key, not a tag). Each hit read: none is an IAM condition, SCP, backup selection, scheduler or other tag-driven automation. Cleared.
  - `git grep -n -E 'aws:(ResourceTag|RequestTag)/Environment|aws:TagKeys'` → no hits. `git grep -n -F 'Environment'` → `main.tf:18,65,99,127,156,168,179` (lines that set the tag), `variables.tf:2` (a variable description, "Environment name"), plus the diff's tag line. Each read: none is automation. Cleared.
  - The commands see only this repo: other repos or org policies (SCPs, backup plans) could act on `Service` / `Environment`. They are the repo's existing keys on every resource already, and the change adds no new key and no new value; nothing in the diff changes what any existing tag-driven rule sees. Not unsure. Pass.
- **E3.** Per resource action: the create of `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` triggers no automated action by itself (creating an alarm executes nothing). Its actions publish to `paymentapi-alerts-<env>`; the repo defines no subscription (`grep -n -i subscription` → none), so what listens on the topic is read by the batch's protocol read and re-checked at 4a. Changed outputs: none, so nothing reads a changed value. Answer: no, citing `code:` (diff, `main.tf`, `outputs.tf` unchanged) and the grep.

AMBIGUITY: E3 "unsure → hit" before the batch has read the topic's subscriber protocols — reading taken: E3 asks about this change; creating an alarm triggers no automated action, so "no", with the subscriber question settled at 4a from the protocol read (any non-email protocol there is a hit).

All pass → the lane stays light.

### Fresh eyes (Step 3)

Skip rule: the phase is add-only (no change, replace or destroy) and touches no access control, network exposure, DNS, data store, secrets/KMS, or deletion-protection/lifecycle setting (an alarm). **`Fresh eyes: skipped — add-only, no sensitive types`.**

---

## STOP 1 — `[A]` (light lane)

One message: research summary (Step 1, above), plan, code summary, read batch, operator line, delivery-model question. S0 runs after `[A]`, so `**Checked for you:**` is not in this message (it moves to `[B]`).

> **Change requested:** Add a CloudWatch CPU utilization alarm for paymentapi in prod; apply it directly, no PR.
> **Service:** `paymentapi` / **Instance:** none (environments `staging`, `prod`)
> **IaC tool(s):** Terraform (`hashicorp/aws ~> 5.0`, `code: providers.tf:4-9`) · **Delivery model:** `UNVERIFIED` — see the question below · **Env selection:** `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/prod.tfvars:1`, `providers.tf:12-17`)
> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset); records are written there.
> **Target (identity reads, no opt-in):** staging — account `222222222222` / `ap-southeast-1` / assumed-role `paymentapi-operator` (`aws sts get-caller-identity`, 10:00); prod — account `333333333333` / `ap-southeast-1` / assumed-role `paymentapi-operator` (`aws sts get-caller-identity`, 10:01)
> **Environment tier:** staging=staging (proven: live sts `222222222222` = `code: envs/staging.tfvars:3`, `providers.tf:16`); prod=prod (proven: live sts `333333333333` = `code: envs/prod.tfvars:3`, `providers.tf:16`) · **Lane (predicted):** `light` — L1 create only, L2 allowlist row `aws_cloudwatch_metric_alarm` create, L3 one phase per env / no drift row / duplicate check not done, L4 E1 (actions → `aws_sns_topic.paymentapi_alerts.arn`, `code: main.tf:174`), E2 (`Service`, `Environment`: no IAM condition / automation hit), E3 (no) all pass; escalations: none
> **Catalog used:** none — proceeding without catalog (consider running service-discovery for a more complete picture)
> **Duplicate check:** not done — `code:` no `aws_cloudwatch_metric_alarm` in the repo (only the `main.tf:3` comment that says it is absent); `git:` `log --all -S` for `CPUUtilization` and `aws_cloudwatch_metric_alarm` → no hits; no branch `*cpu*` / `*alarm*`; no open PR
> **Evidence table:** (Step 1, above) — drift rows: 0, unverified rows: 0; live column pending the batch
> **Snapshot set:** per env: new alarm (n/a — no health signals of its own), ECS service `paymentapi-svc-<env>` (`code: main.tf:72`), ALB `paymentapi-alb-<env>` + target group (`code: main.tf:84-88`, `live:` target-group read) · `Snapshot coverage: code + live (target-group → load balancer read); no catalog, no runtime profile; not covered: callers outside this repo, the load balancer's other target groups, the topic's subscribers beyond their protocols`
> **Gaps remaining:** delivery model (asked below); live absence of the alarm, topic subscriber protocols and the Terraform workspace are not yet read (the batch reads the first two; the workspace is not read — the environment is selected by var-file)
>
> **Change plan for `paymentapi`:**
>
> **Phase 1 of 1: add the CPU alarm** (once in code, applied per environment: staging, then prod)
> - Files: `main.tf` (modified: one new `aws_cloudwatch_metric_alarm` block)
> - Resources affected: add `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` per environment (`paymentapi-cpu-high-staging`, `paymentapi-cpu-high-prod`); change 0, destroy 0
> - Blast radius: the snapshot set above, with its coverage line
> - Disruption: `none` — `code:` the diff adds one resource and edits none; confirmed at 4a by `plan:`
> - Rollback path: remove the resource block (`git revert`), plan, apply the same way; reversible (stateless alarm), `untested`
> - Evidence: the five evidence-table rows
> - Success criteria (per env): `terraform plan -var-file=envs/<env>.tfvars` → `No changes.`; `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-<env>` → the alarm exists, `ActionsEnabled` true, `AlarmActions` = the topic ARN; S2 on the snapshot set (alarms firing, ECS running vs desired, target health)
>
> **Execution path:** Direct apply, as you asked — one `terraform apply tfplan` per environment, each with its own approval at `[B]`. This escalates the pre-flight assessment (anti-pattern A4: local workstation apply). Note: the code is not committed on the direct-apply path.
> **Staging-first (H7):** staging, then prod — direct apply runs, staging's first · **Observation window:** until staging's success criteria pass
> **Branch:** current `main` → `iac-change/paymentapi-add-cpu-alarm` from `origin/main` @ `a1b2c3d` (created, `git fetch origin main` + `git switch -c`; tree was clean)
> **Self-check:** 8/8 pass
> **Drift (H4):** none known — the refresh-only plan in the batch re-checks; a drift row it finds is `[H4]` and escalates
>
> **Delivery model:** `UNVERIFIED` — nothing in the repo shows how a change reaches an environment (no CI config, no Atlantis / Terraform Cloud, no GitOps objects). How does this change reach the environment: is Terraform applied by hand from your workstation, or does CI / automation apply it?
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
>
> **Code changes for Phase 1 of 1:**
> **Modified:** `main.tf` — adds the `paymentapi_cpu_high` alarm (CPU > 80% average over 3 × 5 min on the service, notifies the existing alerts topic on ALARM and OK)
> **Plan ↔ hunk:** create `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` → `main.tf` hunk `@@ -179,3 +179,30 @@`
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped — add-only, no sensitive types · **E1–E3:** pass (E1 SNS topic; E2 tag keys `Service`/`Environment` read, no automation; E3 no)
> **Target:** staging `222222222222` / `ap-southeast-1` (10:00), prod `333333333333` / `ap-southeast-1` (10:01) · var-file `envs/<env>.tfvars` · tiers staging=staging, prod=prod
> **Plan command (4a), one per environment:** `terraform init` (downloads providers and modules; may update `.terraform.lock.hcl`) then `terraform plan -out=tfplan -var-file=envs/staging.tfvars`; prod's run at prod's 4a, on this approval: `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, with each environment's own credentials)
>
> Full diff is in your working tree (`git diff` to review).
>
> **Read batch** (each environment's share runs at its turn — prod's only after staging verifies; read-only; no secret values are retrieved; every read goes through the environment's own credentials, `ap-southeast-1`). Approving `[A]` approves all of it, S0 and S1 and S2 and the success-criteria reads included:
>
> *Both environments (once)*
> - `aws pricing get-products --service-code AmazonCloudWatch --region us-east-1 --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard` — alarm price for category 8 (so cost is scored from the plan and a lookup, not asked)
> - `gh run list --limit 5 --json databaseId,status,conclusion,createdAt,updatedAt,headSha,url` — automation lag (CI history)
>
> *Per environment `<env>` ∈ staging, prod (`<tg>` = the `paymentapi-tg-<env>` target group ARN from the service read; `<lb>` = the load balancer id from the target-group read)*
> - `terraform init` (staging's share only; may update `.terraform.lock.hcl`)
> - `terraform plan -refresh-only -var-file=envs/<env>.tfvars` — drift check, never applied
> - `aws ecs describe-services --cluster paymentapi-cluster-<env> --services paymentapi-svc-<env> --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,lb:loadBalancers,deploy:deploymentConfiguration,deployments:deployments[].{status:status,rollout:rolloutState,created:createdAt,taskDef:taskDefinition},events:events[:10].{at:createdAt,msg:message}}'` — service state, deployment time (automation lag), snapshot point-in-time state
> - `aws elbv2 describe-target-groups --names paymentapi-tg-<env> --region ap-southeast-1 --query 'TargetGroups[].{arn:TargetGroupArn,lbs:LoadBalancerArns}'` — names the load balancer (snapshot member)
> - `aws elbv2 describe-target-health --target-group-arn <tg> --region ap-southeast-1` — snapshot point-in-time state
> - `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:<account>:paymentapi-alerts-<env> --region ap-southeast-1 --query 'Subscriptions[].Protocol'` — protocols only, never endpoints (settles not-app-facing)
> - `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-<env> Name=ServiceName,Value=paymentapi-svc-<env> --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'` — no existing alarm on this metric
> - `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-<env> --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled,actions:AlarmActions}'` — the alarm does not exist yet (the same read is the post-apply success criterion)
> - S0: `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,ns:Namespace,metric:MetricName,dims:Dimensions,math:Metrics[].MetricStat.Metric.Dimensions},composite:CompositeAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,rule:AlarmRule}}'`
> - S0: `aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-<env>.json --start-time <T-7d-1h> --end-time <now> --scan-by TimestampAscending --query 'MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]}'` — one call; the query file holds identifiers only (ALB requests, target 5xx, ELB 5xx, p95, healthy/unhealthy hosts; ECS CPU, memory)
> - S1 (before each apply): the S0 reads again only if S0 is older than 15 minutes, otherwise S0 is reused with its age
> - S2 and success criteria (after each apply, same approval): `terraform plan -var-file=envs/<env>.tfvars` (re-plan); the alarm-names read above; `describe-alarms --state-value ALARM …`, `ecs describe-services …`, `describe-target-health …` as above. A not-app-facing change has no metrics call at S2.
>
> **[A] Approve the plan, the code and these reads?**

### Skill's stop prompt recorded

`STOP 1: A` (see `stops.md`).

### Operator answer (script entry 1, `[A]`; clock 10:18 → 10:23)

Items said, in the order the script lists them for this stop:
- approve.
- Operator line: no reply (nothing said about it — protocol rule 2, `Operator line`).
- Delivery model (asked): "terraform is applied by hand from my workstation, and a direct apply is fine." Recorded `operator-stated`.
- Read batch: approve every command shown, for both environments.
- Not said (the skill did not ask them): every L2 item (`Q1`–`Q8`, `iac-change.1`–`4`) and "Plan order" (the plan states staging first, no exception to justify). No typed-L2 log line is written.

Recorded: Q1(declared)=no, Q2=no — `operator (no objection at [A], 10:23)`; Q7=none — `operator`. Delivery model `operator-stated`: terraform applied by hand from the operator's workstation; direct apply accepted.

---

## Staging turn (light lane: staging's share of the `[A]` batch, then 4a, 4b, `[B]`)

Environment taken for every staging command: (a) the command itself (`-var-file=envs/staging.tfvars`, `paymentapi-cluster-staging`, a `paymentapi-…-staging` name or ARN) or, where the command carries none (`aws sts get-caller-identity`, `describe-alarms --state-value ALARM`, `get-metric-data`, `gh run list`, `aws pricing get-products`), (b) the environment the skill is working on: staging.

### Step 1 batch, staging share (after `[A]`)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C19 | 10:23 | `terraform init` (staging's share; may update `.terraform.lock.hcl` — it did not) | `terraform-init.txt` → "Terraform has been successfully initialized!" |
| C20 | 10:24 | `terraform plan -refresh-only -var-file=envs/staging.tfvars` | `plan-refresh-only-staging.txt` → `No changes.` — **no drift** |
| C21 | 10:25 | `aws ecs describe-services --cluster paymentapi-cluster-staging --services paymentapi-svc-staging … --query '…'` | `ecs-describe-services-staging.json`, `--query` applied by the runner |
| C22 | 10:26 | `aws elbv2 describe-target-groups --names paymentapi-tg-staging … --query '…'` | `tg-describe-staging.json` |
| C23 | 10:27 | `aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09 …` | `tg-health-staging.json` |
| C24 | 10:28 | `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging … --query 'Subscriptions[].Protocol'` | `sns-subscriptions-staging.json`, `--query` applied → `["email","email"]` (endpoints not shown or recorded) |
| C25 | 10:29 | `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-staging Name=ServiceName,Value=paymentapi-svc-staging … --query '…'` | `alarms-for-metric-cpu-staging.json` (before: no alarm on this metric) → `[]` |
| C26 | 10:30 | `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging … --query '…'` | `alarm-cpu-high-before-staging.json` (before) → `[]` |
| C27 | 10:31 | `aws pricing get-products --service-code AmazonCloudWatch …` | `pricing-cloudwatch-alarm.json` → standard alarm, `$0.10 per alarm metric month`, region `ap-southeast-1`, publication 2026-10-07 |
| C28 | 10:32 | `gh run list --limit 5 --json …` | `gh-run-list-empty.json` → `[]` (no CI run) |
| C29 | 10:33 | S0 alarms: `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm … --query '…'` | `alarms-firing-staging.json` (S0/S1 of staging, before apply; this script is not `operator-script-alarm-firing.md`) → no metric or composite alarm firing |
| C30 | 10:34 | S0 metrics: `aws cloudwatch get-metric-data … file://.culiops/iac-change-execution/snapshot-queries-staging.json …` | `metric-data-s0-staging.json` (S0/S1 of staging) |

Reads from C21–C24 (summaries):
- Service `paymentapi-svc-staging`: `ACTIVE`, desired 1, running 1, pending 0. `deploy`: min healthy 100, max 200, circuit breaker off. One deployment `PRIMARY`, `COMPLETED`, created `2026-11-04T08:20:41Z` (15:20 +07:00, five days before the clock date), task definition `paymentapi-staging:8`. Latest event: steady state (`2026-11-09T01:12:40Z`).
- Target group `paymentapi-tg-staging` → load balancer `paymentapi-alb-staging` (`app/paymentapi-alb-staging/50dc6c495c0c9188`). Target health: 1 target, `healthy`.
- Evidence rows now settled: service/cluster names match code (ECS names `paymentapi-cluster-staging`, `paymentapi-svc-staging` = `main.tf:9,72`) ✅; topic exists with email-only subscribers (the read returned protocols `email`, `email`) ✅; no existing CPU alarm live (`code: none` ↔ `live: []`) ✅; load balancer confirmed live (`live:` target-group read) ✅. **Drift rows: 0.**

Because the topic's subscriber protocols are all `email`, the alarm is notify-only: the change is not-app-facing (`skills/pre-flight/assessors/iac-change.md` › Application compatibility), as predicted. E3's open question (what listens on the topic) is closed: no non-email subscriber (`live: sns list-subscriptions-by-topic`, 10:28).

**Query file written** (under the output root; identifiers only; shown here, not written into the fixture). `Period` 3600 (S0 / S1 form); staging values, prod's file is the same with `staging` → `prod`, `LoadBalancer` `app/paymentapi-alb-prod/50dc6c495c0c9188`, `TargetGroup` `targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`, `ClusterName` `paymentapi-cluster-prod`, `ServiceName` `paymentapi-svc-prod`:

```json
[
  {"Id": "req_alb",  "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "RequestCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "Sum"}, "Label": "paymentapi-alb-staging RequestCount"},
  {"Id": "m_5xx_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HTTPCode_Target_5XX_Count", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "err_alb",  "Expression": "FILL(m_5xx_alb, 0)", "Label": "paymentapi-alb-staging HTTPCode_Target_5XX_Count"},
  {"Id": "m_elb5xx_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HTTPCode_ELB_5XX_Count", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "errelb_alb", "Expression": "FILL(m_elb5xx_alb, 0)", "Label": "paymentapi-alb-staging HTTPCode_ELB_5XX_Count"},
  {"Id": "p95_alb",  "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "TargetResponseTime", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}]}, "Period": 3600, "Stat": "p95"}, "Label": "paymentapi-alb-staging TargetResponseTime p95"},
  {"Id": "hh_alb",   "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HealthyHostCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}, {"Name": "TargetGroup", "Value": "targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09"}]}, "Period": 3600, "Stat": "Minimum"}, "Label": "paymentapi-alb-staging HealthyHostCount"},
  {"Id": "uh_alb",   "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "UnHealthyHostCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "app/paymentapi-alb-staging/50dc6c495c0c9188"}, {"Name": "TargetGroup", "Value": "targetgroup/paymentapi-tg-staging/6d0ecf831eec9f09"}]}, "Period": 3600, "Stat": "Minimum"}, "Label": "paymentapi-alb-staging UnHealthyHostCount"},
  {"Id": "cpu_svc",  "MetricStat": {"Metric": {"Namespace": "AWS/ECS", "MetricName": "CPUUtilization", "Dimensions": [{"Name": "ClusterName", "Value": "paymentapi-cluster-staging"}, {"Name": "ServiceName", "Value": "paymentapi-svc-staging"}]}, "Period": 3600, "Stat": "Average"}, "Label": "paymentapi-svc-staging CPUUtilization"},
  {"Id": "mem_svc",  "MetricStat": {"Metric": {"Namespace": "AWS/ECS", "MetricName": "MemoryUtilization", "Dimensions": [{"Name": "ClusterName", "Value": "paymentapi-cluster-staging"}, {"Name": "ServiceName", "Value": "paymentapi-svc-staging"}]}, "Period": 3600, "Stat": "Average"}, "Label": "paymentapi-svc-staging MemoryUtilization"}
]
```

Runner note on the answer: the canned `get-metric-data` files hold 12 points per signal at 300 s (one hour) and the same 12 for the same hour a week earlier, `(1w ago)`. The skill's S0 file uses `Period` 3600, which would give one hourly point per window. The runner returns the results whose `Label` matches and aggregates the 12 canned points into the one hourly bucket (counts summed; gauges shown as the min–max and mean of the 5-minute points; a p95 cannot be re-aggregated, so the 5-minute p95 range and mean are shown and labelled approximate). The `Timestamps` are dated from the end of the window the skill asked for (hour ending 10:34).

S0 result (staging, `live: get-metric-data`, 10:34):

| Series (query Id) | Hour ending 10:34 | Same hour last week |
|---|---|---|
| ALB `RequestCount` (`req_alb`) | 2562 (≈ 0.71 req/s) | 2523 |
| ALB target 5xx (`err_alb`) | 0 | 0 |
| ALB ELB 5xx (`errelb_alb`) | 0 | 0 |
| ALB `TargetResponseTime` p95 (`p95_alb`) | 0.108–0.120 s (mean 0.114) | 0.110–0.122 s (mean 0.116) |
| ALB `HealthyHostCount` min (`hh_alb`) | 1 | 1 |
| ALB `UnHealthyHostCount` min (`uh_alb`) | 0 | 0 |
| ECS CPU avg (`cpu_svc`) | 9.6–14.4 % (mean 11.8) | — |
| ECS memory avg (`mem_svc`) | 26–30 % (mean 27.8) | — |

Q3 from this read: request count 2562 against 2523 last week = 1.02×, under 1.5×, so not peak (`live:`). `Q1(alarms)`: none of the alarms in `ALARM` is on the snapshot set (the alarm read returned none at all).

### 4a — Plan output (staging)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C31 | 10:35 | `aws sts get-caller-identity` (target re-check, staging credentials) | `identity-staging.json` — account `222222222222`, assumed-role/paymentapi-operator. Matches the target the plan is for (pin `envs/staging.tfvars:3`). Var-file read: `envs/staging.tfvars` (`env = "staging"`, account `222222222222`). No `[H1]`. |
| C32 | 10:36 | `terraform plan -out=tfplan -var-file=envs/staging.tfvars` (the `init` already ran at C19) | `plan-staging.txt` → `Plan: 1 to add, 0 to change, 0 to destroy.` |

AMBIGUITY: 4a says to "read the workspace / var-file" — reading taken: the environment is selected by var-file (Step 1), so the var-file is what is read (a fixture input); no `terraform workspace show` is run, and "default workspace" rests on `code:` (no backend, no `terraform.workspace` reference), not on a live read.

Plan output (summary, no plan text copied into the record, `tfplan` stays local): `+ aws_cloudwatch_metric_alarm.paymentapi_cpu_high` will be created — `paymentapi-cpu-high-staging`, `AWS/ECS` `CPUUtilization`, `Average`, period 300 × 3, threshold 80, `GreaterThanThreshold`, `alarm_actions` and `ok_actions` = `arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging`, tags `Environment=staging`, `Service=paymentapi`. Plan: 1 to add, 0 to change, 0 to destroy.

**Cross-check:** the one planned resource is in the approved phase; the action (create) matches the approved disruption `none`; no unnamed destroy or replace (`[H3]` no); no drift picked up by refresh (`[H4]` no). Nothing is outside the snapshot set. The code plans to this plan with no difference (stated in Step 3).

**Lane confirmed from the plan (light):** L1 — one create, nothing deleted or replaced (`plan:` `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create); L2 — allowlist row 1 (create, none condition); L3 — one phase, no drift row, duplicate check not done; L4 — E1: the plan's known `alarm_actions` / `ok_actions` value is an SNS ARN; E2: the plan's tags are `Environment`, `Service` — the greps re-run with the same result as at Step 3 (no automation hit); E3: no, and the topic's subscribers are email-only (`live: C24`). No escalation. Lane stays light.

**Parity check:** staging is the first environment, so none (`n/a` for staging).

### 4b — S1, then pre-flight

**S1 (staging):** the latest staging snapshot is S0 (alarms read 10:33, metrics read 10:34), 3 minutes old at 10:36, under 15, so it is **reused**: `S1 reused — S0 of 10:33–10:34, age 3 min`. It is the "before" of this apply. No stop.

Reusable record? `.culiops/pre-flight/` does not exist in the fixture, so no record: **no match** (the match rule would need plan hash, target and a 24 h window).

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C33 | 10:37 | `terraform show -no-color tfplan` (plan text to hash; last plan was staging's) | `plan-staging.txt` |
| C34 | 10:38 | `sha256sum <scratch file holding the plan text>` | INDEX › Plan hashes → `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962` (scratch file deleted) |

Pre-flight is invoked inline with the plan text and the caller block (every field filled, nothing `unknown`):

```
### Caller context (iac-change-execution)
Target: account 222222222222 / ap-southeast-1 · var-file envs/staging.tfvars · default workspace (no backend block, no workspace reference in code) — identity re-checked 10:35, assumed-role/paymentapi-operator
Delivery model: local workstation apply — not going through CI/CD pipeline. Terraform is applied by hand from the operator's workstation (operator-stated at [A], 10:23); the repo shows no CI, Atlantis, Terraform Cloud or GitOps (code: providers.tf:1-10)
Lane: light — L1 one create (plan: 1 to add, 0 to change, 0 to destroy); L2 allowlist row aws_cloudwatch_metric_alarm create; L3 one phase, no drift (live: terraform plan -refresh-only, 10:24, No changes), duplicate check not done; L4 E1–E3 pass on the diff and the plan
Plan hash: sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962 (terraform show -no-color tfplan)
L2 answers: Q1(alarms)=no (live: describe-alarms --state-value ALARM, 10:33: 0 firing on the snapshot set) Q1(declared)=no (operator (no objection at [A], 10:23)) Q2=no (operator (no objection at [A], 10:23); no freeze source in the repo) Q3=no (live: get-metric-data, 10:34: ALB 2562 requests/h vs 2523 same hour last week, 1.02x, under 1.5x) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator) iac-change.4=recent (live: ECS PRIMARY deployment createdAt 2026-11-04T08:20:41Z = 5 days before, 10:25; gh run list [] 10:32; Terraform state object not read, no backend block)
Live results:
  terraform plan -refresh-only -var-file=envs/staging.tfvars · 10:24 · No changes (no drift)
  aws ecs describe-services paymentapi-svc-staging · 10:25 · ACTIVE, desired 1 / running 1, one PRIMARY deployment COMPLETED created 2026-11-04T08:20:41Z, steady state
  aws elbv2 describe-target-groups paymentapi-tg-staging · 10:26 · front door paymentapi-alb-staging
  aws elbv2 describe-target-health paymentapi-tg-staging · 10:27 · 1 target, healthy
  aws sns list-subscriptions-by-topic paymentapi-alerts-staging (protocols) · 10:28 · email, email
  aws cloudwatch describe-alarms-for-metric AWS/ECS CPUUtilization paymentapi-svc-staging · 10:29 · no alarm on the metric
  aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging · 10:30 · not found (does not exist yet)
  aws pricing get-products AmazonCloudWatch ap-southeast-1 · 10:31 · standard alarm $0.10 per alarm metric month (publication 2026-10-07)
  gh run list --limit 5 · 10:32 · [] (no CI run)
  aws cloudwatch describe-alarms --state-value ALARM (S0) · 10:33 · 0 firing
  aws cloudwatch get-metric-data snapshot-queries-staging.json (S0 = S1, reused, age 3 min) · 10:34 · ALB 2562 req/h (2523 last week), target 5xx 0, ELB 5xx 0, p95 0.108–0.120 s (0.110–0.122 last week), healthy hosts 1, unhealthy 0; ECS CPU 9.6–14.4 %, memory 26–30 %
Evidence table: service/cluster names code = live; topic exists, subscriber protocols email only; no CPU alarm in code or live; front door paymentapi-alb-staging live; alarm price live-looked-up. Drift rows 0, unverified rows 0, code-only rows 0.
```

Pre-flight (inline) then runs, in this order. The full report and record are in `preflight-record.md` (staging section).

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C35 | 10:39 | `aws sts get-caller-identity` (pre-flight's inline target check, through the caller's staging credentials, no stop) | `identity-staging.json` — account `222222222222`, matches `Target:` |
| C36 | 10:40 | `git log --since=7.days --oneline main -- main.tf` (change velocity, base `main`) | `empty.txt` → 0 commits in 7 days (the three repo commits are older than 30 days) |

Pre-flight Step 1: GATE 1 skipped (inline; scope and target from the caller; assessor `iac-change` matched; plan's target equals `Target:`). Step 2 L1: plan hygiene — no `-target`, no `-refresh=false`, own var-file, no drift, no unexpected resources; change velocity — nothing in 7 days (and the change's only uncommitted edit is this change's own `main.tf` hunk; the open-PR check from the duplicate check found none); every changed attribute is on the not-app-facing list (an alarm whose actions are SNS topics with email-only subscribers, `live: C24`) and no output changes. Step 3 L2: all answers come from the caller block, so **no L2 question is asked** (nothing to log as typed L2); Q6 is not asked because L1 scores cost from the plan and the pricing lookup (`live: C27`); Q8 is not asked (nothing app-facing). Step 4 L3: every read the assessor lists for this change is in `Live results:`; nothing is missing, so **no L3 batch and no stop**. Step 5/5b: scored, citations re-opened, verdict arithmetic (below), fresh eyes `not run — dry run`. Step 6: report shown, **no GATE 2 on GREEN**. Step 7: record written (not committed).

**Pre-flight verdict (staging): GREEN — proceed.** All 11 categories Green.

| # | Category | Score | Finding | Evidence |
|---|----------|-------|---------|----------|
| 1 | Blast radius | Green | one resource added, one account and region; a monitoring resource; local workstation apply noted (A4) but the plan is a single add | `plan:` 1 to add; `code:` main.tf diff |
| 2 | Reversibility | Green | create only, no in-place attribute change; rollback = revert + apply, stateless alarm | `plan:` create; `code:` no lifecycle settings |
| 3 | Change velocity | Green | 0 commits to `main.tf` in 7 days; last service deployment 5 days ago | `live: C36`, `live: C21` |
| 4 | Dependency impact | Green | every changed resource is not-app-facing and no output changes: nothing can depend on an alarm | `plan:` no output change; `live: C24` email-only |
| 5 | Timing context | Green | no declared incident, no freeze, no alarm firing, request rate 1.02× last week, operator on hand at the apply | `live: C29`, `live: C30`, `operator` |
| 6 | Operator familiarity | Green | many times on this service; experienced with Terraform | `operator (profile, 2026-10-19)` |
| 7 | Observability readiness | Green | the change only adds not-app-facing monitoring; no alarm on this metric exists yet | assessor rule; `live: C25`, `live: C26` |
| 8 | Cost impact | Green | one standard alarm, $0.10 per month, looked up for `ap-southeast-1` (publication 2026-10-07) | `live: C27` |
| 9 | Security posture | Green | no IAM, network, encryption or logging change | `plan:` |
| 10 | Resource health | Green | 0 alarms firing, 5xx 0, p95 within last week's range, CPU 9.6–14.4 %, memory 26–30 %, 1/1 healthy | `live: C29`, `live: C30`, `live: C21`, `live: C23` |
| 11 | Application compatibility | Green | only not-app-facing attributes changed (alarm, SNS actions, email-only subscribers) | `plan:`, `live: C24` |

Verdict working: Red = none; Yellow + ⚪ = 0; hard blocks checked: 2 (no irreversible change), 5 (no incident, no freeze), 9 (nothing public / no encryption removed), 10 (no error budget exhausted) → GREEN. Fresh eyes: not run — dry run. Not verified: the incident and freeze answers (`operator`, no objection); the delivery model (`operator-stated`); `iac-change.4` rests on the ECS deployment time, a proxy for the last stack apply (the Terraform state object was not read — no backend block); rollback `untested`; the topic's subscribers are email addresses whose forwarding is not visible.

AMBIGUITY: category 7 — Constraint 8 asks for `live` confirmation that alarms exist and are enabled, while the assessor says a change that only adds not-app-facing monitoring is Green and that the mitigation is to confirm after apply that the new alarm leaves `INSUFFICIENT_DATA`. Reading taken: the assessor's specific rule, Green, with the post-apply read as the check.

AMBIGUITY: the delivery-model note "surfaces as elevated risk in blast radius and security posture categories" for a direct apply — reading taken: surfaced as a note in the findings of categories 1 and 9 (and in `Delivery model:`); the scores stay on the traffic-light rules, which a single alarm add does not trip.

Verdict handling: GREEN → no stop here. The verdict line goes to `[B]`.

---

## STOP 2 — `[B]` (staging)

> **[B] Run this apply? (staging)**
> About to run: `terraform apply tfplan` against account `222222222222` / `ap-southeast-1` (identity re-checked in 4a at 10:35, assumed-role/paymentapi-operator), var-file `envs/staging.tfvars`, default workspace — tier staging.
> This will: create `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-staging`) — Plan: 1 to add, 0 to change, 0 to destroy (plan hash `sha256:d316b334…a64962`). Lane confirmed from the plan: light (L1–L4, E1–E3 pass). Parity check: n/a (staging is first). Delivery: local workstation apply — not going through CI/CD pipeline.
> **Pre-flight verdict:** GREEN — 11/11 Green, no Yellow or ⚪ findings, nothing to mitigate. Record: `.culiops/pre-flight/paymentapi-add-cpu-alarm-staging-20261109-1040.md` (invoked inline, not committed). Approving here is the acknowledgement.
> **S1:** reused S0 (alarms 10:33, metrics 10:34), age 3 min — 0 alarms firing on the set, ALB 2562 req/h, 1 healthy target, ECS 1/1.
>
> **Checked for you:** (correct anything that's wrong)
> - Health: `paymentapi-svc-staging` + `paymentapi-alb-staging` — 0 alarms firing, target 5xx 0 (same hour last week 0), p95 0.108–0.120 s (last week 0.110–0.122) · live 10:33–10:34
> - Peak: no — 2562 requests in the hour (≈ 0.71 req/s), same hour last week 2523 (1.02×) · live 10:34
> - Last apply: the service's last deployment 5 days ago (`2026-11-04T08:20:41Z`), no CI run on record · live 10:25, 10:32
> - Cost: one standard alarm, $0.10 per month (`ap-southeast-1`, publication 2026-10-07) · live 10:31
> - Subscribers of `paymentapi-alerts-staging`: email, email (protocols only) · live 10:28
> - Experience: operator (profile, 2026-10-19) — many times on this service, experienced with Terraform
> - Incident / freeze: no declared incident and no freeze — operator (no objection at `[A]`, 10:23); no freeze source in the repo and no incident command in the profile
> Snapshot coverage: code + live (target-group → load balancer read); no catalog, no runtime profile; not covered: callers outside this repo, the load balancer's other target groups, the topic's subscribers beyond their protocols
>
> *Heads-up: say so and I draft one for the service owners, reviewers or on-call with `change-comms` (draft-only; you send it).*

`STOP 2: B` (see `stops.md`).

### Operator answer (script entry 2, `[B]` staging; clock 10:41 → 10:46)

"Approve the apply command shown for staging." Approving also acknowledges a YELLOW verdict, if shown: the verdict is GREEN, nothing to acknowledge. No heads-up requested.

### 4c — Direct apply (staging)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C37 | 10:46 | `terraform apply tfplan` (staging; the approved command) | `apply-staging.txt` → `Creation complete after 1s [id=paymentapi-cpu-high-staging]` · `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` |

The apply is short, no long-running handling needed. Not interrupted, no lock held.

### 5a — Verification (staging; approved at `[A]`, no new stop)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C38 | 10:47 | re-plan: `terraform plan -var-file=envs/staging.tfvars` | `plan-after-staging.txt` → `No changes.` (state "after the staging apply") |
| C39 | 10:48 | `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging … --query '…'` | `alarm-cpu-high-after-staging.json` (after) |
| C40 | 10:49 | S2 alarms: `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm … --query '…'` | `alarms-firing-after-staging.json` (S2 of staging) → none firing; the new alarm exists and is not in `ALARM` |
| C41 | 10:50 | S2 state: `aws ecs describe-services --cluster paymentapi-cluster-staging --services paymentapi-svc-staging … --query '…'` | `ecs-describe-services-staging.json` |
| C42 | 10:51 | S2 state: `aws elbv2 describe-target-health --target-group-arn …paymentapi-tg-staging/6d0ecf831eec9f09 …` | `tg-health-staging.json` |

Notes:
- S2 clock jump: not applicable. The change is not-app-facing, so S2 has no two-period wait and no metrics call (`snapshot.md` › When snapshots run, Not-app-facing change): it reads the alarms and the point-in-time state once, with the success criteria. No `S2 ready at HH:MM`. The canned `metric-data-s2-staging.json` is therefore not used (its metric signals are left out of the counts and the no-data list).
- Canned timestamps versus the clock: the canned alarm files carry `AlarmConfigurationUpdatedTimestamp` `2026-11-09T03:17:44Z` (10:17:44 +07:00), earlier than this run's apply time (10:46) because the clock rule advanced the time through the stops. They are quoted as returned; the clock is not changed.

**Verification for Phase 1 (staging):**
- Re-plan: clean (`No changes.`).
- Success criteria:
  - `terraform plan -var-file=envs/staging.tfvars` → `No changes.` — pass.
  - `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-staging` → exists; `ActionsEnabled` true; `AlarmActions` = `arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging`; `StateValue` `OK` ("3 datapoints [12.4, 11.8, 13.1] were not greater than the threshold (80.0)"); `Threshold` 80, period 300 × 3, `AWS/ECS` `CPUUtilization` on `paymentapi-cluster-staging` / `paymentapi-svc-staging` — pass.
- Snapshot (S1 = reused S0 vs S2, 10:49–10:51): **4 ok · 0 regressed · 0 no data** (alarms firing on the ECS service 0 → 0; ECS running vs desired 1/1 → 1/1; alarms firing on the load balancer 0 → 0; healthy targets 1 → 1; both deployments and target states unchanged). The new alarm is judged by its success criteria (exists, `OK`). The metric signals have no after-read and are not counted.

Phase 1 in staging verified. Light lane: prod's turn starts now (observation window: until staging's success criteria pass).

---

## Prod turn (staging verified; prod's share of the `[A]` batch, 4a, parity, 4b, H7, `[B]`)

Environment taken for every prod command: (a) the command itself (`-var-file=envs/prod.tfvars`, `paymentapi-cluster-prod`, a `paymentapi-…-prod` name or ARN) or, for commands that carry none (`aws sts get-caller-identity`, `describe-alarms --state-value ALARM`, `get-metric-data`), (b) the environment the skill is working on: prod. The operator switches the shell profile to prod's credentials without a stop (script).

Staging verified (success criteria pass, `Snapshot: 4 ok · 0 regressed · 0 no data`, no `[H10]`), so no prod read other than the identity read ran before this point (`lanes.md` › Staging-first, Reads).

### Step 1 batch, prod share

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C43 | 10:52 | `aws sts get-caller-identity` (prod credentials; runs first, no opt-in) | `identity-prod.json` — account `333333333333`, matches the pin (`envs/prod.tfvars:3`) |
| C44 | 10:53 | `terraform plan -refresh-only -var-file=envs/prod.tfvars` | `plan-refresh-only-prod.txt` → `No changes.` — **no drift** |
| C45 | 10:54 | `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod … --query '…'` | `ecs-describe-services-prod.json` |
| C46 | 10:55 | `aws elbv2 describe-target-groups --names paymentapi-tg-prod … --query '…'` | `tg-describe-prod.json` |
| C47 | 10:56 | `aws elbv2 describe-target-health --target-group-arn …:targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 …` | `tg-health-prod.json` |
| C48 | 10:57 | `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod … --query 'Subscriptions[].Protocol'` | `sns-subscriptions-prod.json` → `["email","email"]` |
| C49 | 10:58 | `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod … --query '…'` | `alarms-for-metric-cpu-prod.json` (before) → `[]` |
| C50 | 10:59 | `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod … --query '…'` | `alarm-cpu-high-before-prod.json` (before) → `[]` |
| C51 | 11:00 | S0 alarms (prod): `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm … --query '…'` | `alarms-firing-prod.json` → none firing |
| C52 | 11:01 | S0 metrics (prod): `aws cloudwatch get-metric-data … file://.culiops/iac-change-execution/snapshot-queries-prod.json …` | `metric-data-s0-prod.json` |

(`aws pricing get-products` and `gh run list` ran once, at 10:31 and 10:32, and are not repeated: neither depends on the environment.)

Reads (summaries): service `paymentapi-svc-prod` `ACTIVE`, desired 3, running 3, one PRIMARY deployment `COMPLETED`, created `2026-10-12T14:02:11Z` (21:02 +07:00, 28 days before the clock date), task definition `paymentapi-prod:12`; load balancer `paymentapi-alb-prod` (`app/paymentapi-alb-prod/50dc6c495c0c9188`); target health 3 targets `healthy`; topic subscribers `email`, `email`; no alarm on the metric, no `paymentapi-cpu-high-prod`. **Drift rows: 0.**

S0 result (prod, `live: get-metric-data`, 11:01; the same aggregation of the 12 canned five-minute points as for staging):

| Series | Hour ending 11:01 | Same hour last week |
|---|---|---|
| ALB `RequestCount` | 41442 (≈ 11.5 req/s) | 40820 |
| ALB target 5xx / ELB 5xx | 0 / 0 | 0 / 0 |
| ALB `TargetResponseTime` p95 | 0.108–0.120 s (mean 0.114) | 0.110–0.122 s (mean 0.116) |
| ALB `HealthyHostCount` min / `UnHealthyHostCount` min | 3 / 0 | 3 / 0 |
| ECS CPU avg | 35.6–40.4 % (mean 37.8) | — |
| ECS memory avg | 50–54 % (mean 51.8) | — |

Q3: 41442 against 40820 = 1.02×, under 1.5×: not peak. `Q1(alarms)`: none firing.

### 4a — Plan output (prod)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C53 | 11:02 | `aws sts get-caller-identity` (target re-check, prod credentials) | `identity-prod.json` — account `333333333333`, assumed-role/paymentapi-operator; matches the target the plan is for (pin `envs/prod.tfvars:3`). Var-file read: `envs/prod.tfvars` (`env = "prod"`). No `[H1]`. |
| C54 | 11:03 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | `plan-prod.txt` → `Plan: 1 to add, 0 to change, 0 to destroy.` |

Plan output: `+ aws_cloudwatch_metric_alarm.paymentapi_cpu_high` created — `paymentapi-cpu-high-prod`, dimensions `paymentapi-cluster-prod` / `paymentapi-svc-prod`, `alarm_actions` and `ok_actions` = `arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod`, tags `Environment=prod`, `Service=paymentapi`. The code plans to it with no difference (same names via `var.env`).

**Cross-check:** one resource, in the approved phase, create matches disruption `none`; no unnamed destroy or replace; no drift. **Lane confirmed (light):** L1 one create; L2 allowlist row 1; L3 one phase per environment, no drift, duplicate check not done; L4 E1 (`plan:` known ARN is an SNS ARN), E2 (greps unchanged, no automation hit), E3 (no; subscribers email-only, `live: C48`). No escalation.

**Parity check (H3, prod after staging):** staging's applied plan for the same phase: `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create (`plan:` `plan-staging.txt`, C32). Prod's: the same normalised address (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`; the environment appears only in attribute values, not in the address), the same action, create. No untested action: **`Parity check: pass`.**

### 4b — S1, then pre-flight (prod)

**S1 (prod):** the latest prod snapshot is S0 (alarms 11:00, metrics 11:01), 3 minutes old at 11:03 — **reused** (`S1 reused — S0 of 11:00–11:01, age 3 min`). Its answers equal what pre-flight gets: `Q1(alarms)=no`, `Q3=no`.

Reusable record? Staging's pre-flight record never matches (different plan hash and target, rule (b)). No other record. **No match** → pre-flight is invoked inline, as its own run.

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C55 | 11:04 | `terraform show -no-color tfplan` (last plan was prod's) | `plan-prod.txt` |
| C56 | 11:05 | `sha256sum <scratch file holding the plan text>` | INDEX › Plan hashes → `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` |

```
### Caller context (iac-change-execution)
Target: account 333333333333 / ap-southeast-1 · var-file envs/prod.tfvars · default workspace (no backend block, no workspace reference in code) — identity re-checked 11:02, assumed-role/paymentapi-operator
Delivery model: local workstation apply — not going through CI/CD pipeline. Terraform is applied by hand from the operator's workstation (operator-stated at [A], 10:23); the repo shows no CI, Atlantis, Terraform Cloud or GitOps (code: providers.tf:1-10)
Lane: light — L1 one create (plan: 1 to add, 0 to change, 0 to destroy); L2 allowlist row aws_cloudwatch_metric_alarm create; L3 one phase, no drift (live: terraform plan -refresh-only, 10:53, No changes), duplicate check not done; L4 E1–E3 pass on the diff and the plan; parity with staging: pass
Plan hash: sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8 (terraform show -no-color tfplan)
L2 answers: Q1(alarms)=no (live: describe-alarms --state-value ALARM, 11:00: 0 firing on the snapshot set) Q1(declared)=no (operator (no objection at [A], 10:23)) Q2=no (operator (no objection at [A], 10:23); no freeze source in the repo) Q3=no (live: get-metric-data, 11:01: ALB 41442 requests/h vs 40820 same hour last week, 1.02x, under 1.5x) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator) iac-change.4=recent (live: ECS PRIMARY deployment createdAt 2026-10-12T14:02:11Z = 28 days before, 10:54; gh run list [] 10:32; Terraform state object not read, no backend block)
Live results:
  terraform plan -refresh-only -var-file=envs/prod.tfvars · 10:53 · No changes (no drift)
  aws ecs describe-services paymentapi-svc-prod · 10:54 · ACTIVE, desired 3 / running 3, one PRIMARY deployment COMPLETED created 2026-10-12T14:02:11Z
  aws elbv2 describe-target-groups paymentapi-tg-prod · 10:55 · front door paymentapi-alb-prod
  aws elbv2 describe-target-health paymentapi-tg-prod · 10:56 · 3 targets, all healthy
  aws sns list-subscriptions-by-topic paymentapi-alerts-prod (protocols) · 10:57 · email, email
  aws cloudwatch describe-alarms-for-metric AWS/ECS CPUUtilization paymentapi-svc-prod · 10:58 · no alarm on the metric
  aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod · 10:59 · not found (does not exist yet)
  aws pricing get-products AmazonCloudWatch ap-southeast-1 · 10:31 · standard alarm $0.10 per alarm metric month (publication 2026-10-07)
  gh run list --limit 5 · 10:32 · [] (no CI run)
  aws cloudwatch describe-alarms --state-value ALARM (S0) · 11:00 · 0 firing
  aws cloudwatch get-metric-data snapshot-queries-prod.json (S0 = S1, reused, age 3 min) · 11:01 · ALB 41442 req/h (40820 last week), target 5xx 0, ELB 5xx 0, p95 0.108–0.120 s (0.110–0.122 last week), healthy hosts 3, unhealthy 0; ECS CPU 35.6–40.4 %, memory 50–54 %
Evidence table: service/cluster names code = live; topic exists, subscriber protocols email only; no CPU alarm in code or live; front door paymentapi-alb-prod live; alarm price live-looked-up. Drift rows 0, unverified rows 0, code-only rows 0.
  Staging evidence (evidence, not proof):
  - Measured disruption during staging's apply (10:46): none — apply complete after 1 s, 1 added 0 changed 0 destroyed; ECS service 1/1 running, same PRIMARY deployment, target 1/1 healthy after (live: ecs describe-services, describe-target-health (staging, 10:50–10:51))
  - Staging success criteria (live: terraform plan -var-file=envs/staging.tfvars (staging, 10:47): No changes; live: describe-alarms --alarm-names paymentapi-cpu-high-staging (staging, 10:48): exists, ActionsEnabled true, state OK, AlarmActions = the staging topic)
  - Staging S1 (reused S0, live: describe-alarms --state-value ALARM and get-metric-data (staging, 10:33–10:34)): 0 alarms firing, 2562 req/h, 5xx 0, ECS CPU 9.6–14.4 %; staging S2 (live: describe-alarms --state-value ALARM, ecs describe-services, describe-target-health (staging, 10:49–10:51)): 0 alarms firing, ECS 1/1, 1 healthy target; Snapshot: 4 ok · 0 regressed · 0 no data; no regressed value, no override
  - Size differences between the var-files: desired_count 1 → 3 (code: envs/staging.tfvars:11 vs envs/prod.tfvars:11); task_cpu 256 → 512 (:12); task_memory 512 → 1024 (:13); image_tag v2.5.0-rc2 → v2.4.1 (:10)
```

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C57 | 11:06 | `aws sts get-caller-identity` (pre-flight's inline target check, prod credentials, no stop) | `identity-prod.json` — account `333333333333`, matches `Target:` |
| C58 | 11:07 | `git log --since=7.days --oneline main -- main.tf` | `empty.txt` → 0 commits in 7 days |

Pre-flight runs as for staging: GATE 1 skipped, L1 from the plan and code, **no L2 question asked** (every answer comes from the block; nothing logged as typed L2), **no L3 stop** (every needed read is in `Live results:`), scored from prod's own evidence (staging evidence raises no category to Green by itself). The report and record are in `preflight-record.md` (prod section).

**Pre-flight verdict (prod): GREEN — proceed.** 11/11 Green. Differences from staging: category 5 and 10 use prod's S0 (request rate 1.02× last week, CPU 35.6–40.4 %, memory 50–54 %, 3/3 healthy, 0 alarms firing); category 3 notes the last service deployment 28 days ago; category 1 notes this is prod and a local workstation apply (A4) with a single add. Verdict working: Red = none; Yellow + ⚪ = 0; hard blocks checked 2, 5, 9, 10 → GREEN. Fresh eyes: not run — dry run.

**H7 before this `[B]` (it reaches prod):** staging applied (10:46) with its success criteria passed and no regression — satisfied.

---

## STOP 3 — `[B]` (prod)

First stop of a later environment: it carries staging's result, the Snapshot line, and the operator line (`lanes.md` › Timing re-ask; this stop comes after pre-flight, so an unchanged answer proceeds and only a changed one would re-run pre-flight).

> **[B] Run this apply? (prod)**
> **Phase 1 (staging) success criteria:** `terraform plan -var-file=envs/staging.tfvars` → `No changes.` — pass; `describe-alarms --alarm-names paymentapi-cpu-high-staging` → exists, `ActionsEnabled` true, `OK` — pass. **Snapshot (staging):** 4 ok · 0 regressed · 0 no data. **Staging-first (H7):** applied — staging 10:46; observation window (light lane) ended when staging's criteria passed. **Parity check:** pass (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high` create in both).
> About to run: `terraform apply tfplan` against account `333333333333` / `ap-southeast-1` (identity re-checked in 4a at 11:02, assumed-role/paymentapi-operator), var-file `envs/prod.tfvars`, default workspace — tier prod.
> This will: create `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (`paymentapi-cpu-high-prod`) — Plan: 1 to add, 0 to change, 0 to destroy (plan hash `sha256:1e420453…763fc8`). Lane: light (confirmed from the plan). Delivery: local workstation apply — not going through CI/CD pipeline.
> **Pre-flight verdict:** GREEN — 11/11 Green, no Yellow or ⚪ findings. Record: `.culiops/pre-flight/paymentapi-add-cpu-alarm-prod-20261109-1107.md` (inline, not committed). Approving here is the acknowledgement.
> **S1:** reused S0 (alarms 11:00, metrics 11:01), age 3 min — 0 alarms firing on the set, ALB 41442 req/h, 3 healthy targets, ECS 3/3.
>
> **Checked for you:** (correct anything that's wrong)
> - Health: `paymentapi-svc-prod` + `paymentapi-alb-prod` — 0 alarms firing, target 5xx 0 (same hour last week 0), p95 0.108–0.120 s (last week 0.110–0.122) · live 11:00–11:01
> - Peak: no — 41442 requests in the hour (≈ 11.5 req/s), same hour last week 40820 (1.02×) · live 11:01
> - Last apply: the service's last deployment 28 days ago (`2026-10-12T14:02:11Z`), no CI run on record · live 10:54, 10:32
> - Cost: one standard alarm, $0.10 per month · live 10:31
> - Subscribers of `paymentapi-alerts-prod`: email, email (protocols only) · live 10:57
> - Experience: operator (profile, 2026-10-19)
> - Incident / freeze: operator (no objection at `[A]`, 10:23); no freeze source in the repo, no incident command in the profile
> Snapshot coverage: code + live (target-group → load balancer read); no catalog, no runtime profile; not covered: callers outside this repo, the load balancer's other target groups, the topic's subscribers beyond their protocols
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
>
> *Heads-up: say so and I draft one for the service owners, reviewers or on-call with `change-comms` (draft-only; you send it).*

`STOP 3: B` (see `stops.md`).

### Operator answer (script entry 3, `[B]` prod; clock 11:08 → 11:13)

"Approve the apply command shown for prod." Nothing is said about the operator line (no reply, protocol rule 2). The script's "if asked again whether the incident, freeze and peak answers still hold" is not used: the skill does not ask that question (it shows the operator line). The incident, freeze and peak answers are unchanged, so pre-flight is not re-run. Recorded: `Q1(declared)=no, Q2=no — operator (no objection at [B], 11:13)`, `Q7=none`.

AMBIGUITY: the operator line and `Q1(declared)` / `Q2` for prod — `lanes.md` › Timing re-ask says the first stop of a later environment carries the operator line and passes its answers to pre-flight, but in the light lane that stop (`[B]`) comes after pre-flight. Reading taken: prod's pre-flight gets the `[A]` operator-line answers plus prod's own S1 answers; the line is shown again at prod's `[B]`; no reply means unchanged, so no re-run.

### 4c — Direct apply (prod)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C59 | 11:13 | `terraform apply tfplan` (prod; the approved command) | `apply-prod.txt` → `Creation complete after 1s [id=paymentapi-cpu-high-prod]` · `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` |

### 5a — Verification (prod)

| # | Time | Command | Canned file |
|---|------|---------|-------------|
| C60 | 11:14 | re-plan: `terraform plan -var-file=envs/prod.tfvars` | `plan-after-prod.txt` → `No changes.` |
| C61 | 11:15 | `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod … --query '…'` | `alarm-cpu-high-after-prod.json` |
| C62 | 11:16 | S2 alarms: `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm … --query '…'` | `alarms-firing-after-prod.json` → none firing; the new alarm exists and is not in `ALARM` |
| C63 | 11:17 | S2 state: `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod … --query '…'` | `ecs-describe-services-prod.json` → 3/3 |
| C64 | 11:18 | S2 state: `aws elbv2 describe-target-health --target-group-arn …paymentapi-tg-prod/6d0ecf831eec9f09 …` | `tg-health-prod.json` → 3 healthy |

As in staging: not-app-facing, so no two-period wait, no metrics call at S2, no `S2 ready at` clock jump; the canned `metric-data-s2-prod.json` is not used. The canned alarm timestamp (`2026-11-09T03:42:13Z` = 10:42:13 +07:00) is earlier than the clock's apply time (11:13); it is quoted as returned.

**Verification for Phase 1 (prod):**
- Re-plan: clean (`No changes.`).
- Success criteria:
  - `terraform plan -var-file=envs/prod.tfvars` → `No changes.` — pass.
  - `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` → exists; `ActionsEnabled` true; `AlarmActions` = `arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod`; `StateValue` `OK` ("3 datapoints [38.4, 39.8, 36.9] were not greater than the threshold (80.0)") — pass.
- Snapshot (S1 = reused S0 vs S2, 11:16–11:18): **4 ok · 0 regressed · 0 no data** (alarms on the service 0 → 0; ECS 3/3 → 3/3; alarms on the load balancer 0 → 0; healthy targets 3 → 3). The new alarm is judged by its success criteria (exists, `OK`). Metric signals have no after-read and are not counted.

---

## Step 5b — Record and final message

Execution record written to `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1119.md` (content in `record.md`); pre-flight records for staging and prod in `.culiops/pre-flight/` (content in `preflight-record.md`). Under `.culiops/` at the repo root: no `CULIOPS_HOME`, so the commit offer applies in the `Next:` line.

Final message to the operator:

> **Outcome: completed.** The CPU alarm `paymentapi-cpu-high-<env>` was created in staging (10:46) and prod (11:13) by direct apply, one `[B]` each. Staging first: success criteria passed, health snapshot 4 ok · 0 regressed · 0 no data; prod: success criteria passed, 4 ok · 0 regressed · 0 no data. **Applied:** staging yes — verified (re-plan `No changes.`; alarm exists, `OK`; snapshot 4 ok); prod yes — verified (re-plan `No changes.`; alarm exists, `OK`; snapshot 4 ok). The code (`main.tf`) is on branch `iac-change/paymentapi-add-cpu-alarm`, uncommitted; nothing was pushed. Records: `.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1119.md`.
>
> Next: commit the record (.culiops/iac-change-execution/paymentapi-add-cpu-alarm-20261109-1119.md) · draft the result or ticket-close message with change-comms

AMBIGUITY: the direct-apply path never commits or pushes the IaC code, and the skill text says nothing about it after the apply — reading taken: the code stays uncommitted on the change branch, the record's `Commit:` says so, and the final message states it as a fact and makes no offer ("make no other offer").

---

## Tallies

- Stops: 3 (`[A]`, `[B]` staging, `[B]` prod). No hard-gate stop (`[H1]`, `[H3]`–`[H10]` none fired). No `unscripted` stop. No `[H4]`.
- Typed L2 (the count of lines the protocol logs for an L2 item said by the operator): 0. Every L2 item was answered from a read, the profile, the operator line (no reply) or the caller block; the operator said no L2 item.
- `no canned output`: none (no command hit a missing row). The only "no canned output" candidate, the documentation lookup, was never needed (no behaviour claim rests on `docs:`).
- `PROFILE-WRITE`: none. Nothing was asked that the profile saves (Q4/Q5 came from the profile; no incident command offered).
