**IaC change execution for:** `paymentapi` / `dev`
**Change:** Raise the ECS task CPU for paymentapi in dev from 256 to 512.
**Date:** 2026-11-09 10:53
**Commit:** none — direct apply; the change to `envs/dev.tfvars` is uncommitted on branch `iac-change/paymentapi-raise-dev-task-cpu` (from `origin/main` @ `a1b2c3d`)
**IaC tool(s):** Terraform v1.9.8 (aws provider v5.74.0)
**Prerequisites (`examples/aws.md`):** AWS CLI v2 — aws-cli/2.17.21 · authentication: assumed role `paymentapi-operator` in account 111111111111 · IAM: Tier 1 read-only for Steps 1 and 5, Tier 2 for the apply (the operator's session; not verified by the skill) · cost awareness: CloudWatch `GetMetric*` calls are billed per call
**Execution path:** Direct apply
**Pre-flight record:** skipped — dev lane
**Lane:** dev — every target proven dev: `live: aws sts get-caller-identity` → account 111111111111 (10:01, re-checked 10:37) equals `code: envs/dev.tfvars:3` `aws_account_id` and `code: providers.tf:16` `allowed_account_ids`; the plan touches only resources in that account; no escalation
**Escalations:** none
**Environment tier:** dev=dev (live: account 111111111111 = code: envs/dev.tfvars:3, providers.tf:16) · prod=prod (by name only, unproven; not a target; pin `code: envs/prod.tfvars:3` = 333333333333)
**Staging-first:** n/a — no staging env (code: `envs/` holds `dev.tfvars` and `prod.tfvars` only; the mutation does not reach prod)
**Waived:** none

## Research Summary
- Catalog used: none — `.culiops/service-discovery/paymentapi.md` not present; proceeded without it (suggested running service-discovery).
- Duplicate check: **not done**. `code: envs/dev.tfvars:12` is still `task_cpu = 256`; the only `512` for this key is `code: envs/prod.tfvars:12` (prod, not this change). `git log --all -S'task_cpu'` and `-S'512'`: no hits. `git branch -a --list '*task-cpu*'`: none. `gh pr list --state open --search 'paymentapi task CPU'`: none. No ticket key.
- Delivery model: `UNVERIFIED` from the repo (`code: none` — no CI config, `atlantis.yaml`, backend or `cloud {}` block; the repo holds `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `envs/`). Asked inside `[D1]`; answer: terraform is applied by hand — `operator-stated`. It holds for the direct-apply path.
- Env selection: `-var-file=envs/dev.tfvars`, default workspace (`code: envs/dev.tfvars`, `envs/prod.tfvars`; `providers.tf:12-16`).
- Target check: account 111111111111 / region ap-southeast-1 (`code: envs/dev.tfvars:2`) / role `assumed-role/paymentapi-operator` — `live: aws sts get-caller-identity` 10:01; re-checked before the plan, 10:37 — match.
- Drift check: `live: terraform plan -refresh-only -var-file=envs/dev.tfvars` (10:12) → No changes.
- Live context read (L3 reads, dev: no stop): ALB target `healthy` (1 of 1); no alarm exists or fires for the service; CPU Average 16–20 % / Maximum ≤ 30 % of 256 units; memory Average 32–36 % / Maximum ≤ 46 %; ALB `HTTPCode_Target_5XX_Count` Sum 0; latency Average 36–40 ms; request count 882 in the last hour, 1.0x the same hour a week ago.
- Cost: +0.25 vCPU × 0.05056 USD/h × 730 h ≈ 9.23 USD/month for one task (`pricing: aws pricing get-products`, 10:27, publication 2026-10-07, fixture values).

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| dev task CPU | `code: envs/dev.tfvars:12` → 256 (`main.tf:28` `cpu = var.task_cpu`) | `live: aws ecs describe-task-definition paymentapi-dev` (10:14) → revision 7, cpu "256" | ✅ |
| dev task memory | `code: envs/dev.tfvars:13` → 1024 | same read → "1024" | ✅ |
| service uses the task definition | `code: main.tf:74` (the only reference; `outputs.tf` exposes none) | `live: aws ecs describe-services …` (10:13) → `paymentapi-dev:7` | ✅ |
| desired count | `code: envs/dev.tfvars:11` → 1 | same read → desired 1, running 1 | ✅ |
| deployment settings | `code: main.tf:90-91` → min 100 / max 200 | same read → 100 / 200; circuit breaker disabled (code sets none: default) | ✅ |
| load balancer path | `code: main.tf:77-81` → `aws_lb_target_group.paymentapi` | `live: aws elbv2 describe-target-health …` (10:17) → 1 target healthy; in front of `paymentapi-alb-dev` (10:15, 10:16) | ✅ |
| alarms on the service | `code: none` | `live: aws cloudwatch describe-alarms …` (10:18, 10:19, 10:20) → none | ✅ (none both sides) |
| 512 CPU with 1024 MiB is a valid Fargate pair | `code: envs/prod.tfvars:12-13` runs 512 / 1024 | `docs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html` (read 2026-11-09): 512 CPU supports 1024–4096 MiB | ✅ |
| a CPU change registers a new revision and rolls the service | — | `docs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html` (read 2026-11-09): a revision is immutable; changing `cpu` registers a new revision; rolling deployment | ✅ |
| drift | — | `live: terraform plan -refresh-only -var-file=envs/dev.tfvars` (10:12) → No changes | ✅ |
| delivery model | `code: none` | — | UNVERIFIED → `operator-stated` at `[D1]` |

Drift rows: 0. Unverified rows: 1 (delivery model; answered at `[D1]`).

## Change Plan

**Phase 1 of 1: raise task CPU 256 to 512**
- Files: `envs/dev.tfvars` (line 12, `task_cpu` 256 → 512)
- Resources affected: `aws_ecs_task_definition.paymentapi` replace (new revision 8, revision 7 superseded); `aws_ecs_service.paymentapi` update in-place (`task_definition` follows the new revision)
- Blast radius: the one task of `paymentapi-svc-dev` (desired 1) and its target group `paymentapi-tg-dev` behind `paymentapi-alb-dev` (internal). Nothing else references the task definition (`code: main.tf:74`). Cost about +9.23 USD/month.
- Disruption: restart. New revision registered, service rolls to it (`docs: task_definitions.html`, 2026-11-09). minimumHealthyPercent 100 / maximumPercent 200 (`live: describe-services`, 10:13): the new task starts before the old one stops. Circuit breaker disabled (`live`, 10:13): a failing new task stalls the rollout, no auto-rollback. 512/1024 is a valid pair (`docs: AWS_Fargate.html`; `code: envs/prod.tfvars:12-13`).
- Rollback path: reversible — revert `envs/dev.tfvars` to 256, plan, apply (registers a new revision with cpu 256; `docs: task_definitions.html`). untested.
- Evidence: the 10 matching evidence rows above.
- Success criteria: (1) `aws ecs describe-services …` → `paymentapi-dev:8`, desired 1 = running 1, pending 0, one PRIMARY COMPLETED; (2) `aws ecs describe-task-definition …` → revision 8, cpu "512", memory "1024"; (3) `aws elbv2 describe-target-health …` → all healthy; (4) `aws cloudwatch describe-alarms --state-value ALARM --alarm-name-prefix paymentapi` → none; (5) `CPUUtilization` last 15 m → within baseline; (6) re-plan → No changes.

Execution path: PR (default), direct apply offered at `[D1]` and chosen by the operator. Staging-first: (a) no staging env. Observation window: n/a. Branch: `main` → `iac-change/paymentapi-raise-dev-task-cpu` from `origin/main` @ `a1b2c3d`. Self-check: 8/8 pass. Drift: none. For pre-flight (L2): n/a — dev lane.

## Execution Log
### Phase 1: raise task CPU 256 to 512
- Files changed: `envs/dev.tfvars`
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — dev lane
- Plan output summary: 3 resources — 1 to add, 1 to change, 1 to destroy (`aws_ecs_task_definition.paymentapi` replace, `aws_ecs_service.paymentapi` update in-place; both named in the plan)
- Plan hash: `sha256:16bfca0073020ff4eaf0ecb203b9711d719438110fed0ba3bc502016af6c2394` (`terraform show -no-color tfplan`, 10:39)
- Parity check: n/a
- Pre-flight verdict: skipped — dev lane (`live: aws sts get-caller-identity` → 111111111111, 10:37; `code: envs/dev.tfvars:3`, `providers.tf:16`)
- Execution: `terraform apply tfplan` against account 111111111111 / ap-southeast-1, approved at `[D1]` (operator, 10:45) → `Apply complete! Resources: 1 added, 1 changed, 1 destroyed.` (10:46)
- Verification:
  - Re-plan (10:47): `No changes. Your infrastructure matches the configuration.`
  - `aws ecs describe-services …` (10:48) → taskDefinition `paymentapi-dev:8`, desired 1, running 1, pending 0, one PRIMARY deployment `ecs-svc/441790225580173608` COMPLETED, failedTasks 0 — pass (before: `:7`)
  - `aws ecs describe-task-definition …` (10:49) → revision 8, cpu "512", memory "1024", ACTIVE — pass (before: revision 7, cpu "256")
  - `aws elbv2 describe-target-health …` (10:50) → 1 target `healthy` — pass (before: 1 healthy)
  - `aws cloudwatch describe-alarms --state-value ALARM --alarm-name-prefix paymentapi` (10:51) → none — pass (before: none)
  - `aws cloudwatch get-metric-statistics … CPUUtilization` window 03:37Z–03:52Z (10:52) → Average 16–20 %, Maximum ≤ 30 % (before: the same). The returned datapoints are stamped 02:00Z–02:55Z, before the apply, so this check is not independent post-apply evidence.

## Outcome
completed

**Applied:** yes — verified (re-plan clean at 10:47; `describe-services` shows `paymentapi-dev:8` running 1 of 1 and `describe-task-definition` shows cpu "512", 10:48–10:49; target `healthy` 10:50; no alarm in ALARM 10:51)

## Ticket Reference
none
