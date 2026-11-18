**IaC change execution for:** `paymentapi` / none (environments `staging`, `prod`)
**Change:** Add a CloudWatch CPU utilization alarm for paymentapi in prod; apply directly, no PR (staging first, H7)
**Date:** `2026-11-09 11:19` (+07:00)
**Commit:** `a1b2c3d` (HEAD of `origin/main`; the change is uncommitted on branch `iac-change/paymentapi-add-cpu-alarm` — direct apply, nothing committed or pushed)
**IaC tool(s):** Terraform (`hashicorp/aws ~> 5.0`)
**Execution path:** Direct apply (operator-requested in the first message; `Delivery model:` carried "local workstation apply — not going through CI/CD pipeline")
**Pre-flight record:** invoked inline — verdict: GREEN (staging, `.culiops/pre-flight/paymentapi-add-cpu-alarm-staging-20261109-1040.md`); invoked inline — verdict: GREEN (prod, `.culiops/pre-flight/paymentapi-add-cpu-alarm-prod-20261109-1107.md`)
**Lane:** light — L1 one create per environment (`plan:` 1 to add, 0 to change, 0 to destroy, staging and prod); L2 allowlist row `aws_cloudwatch_metric_alarm` create; L3 one phase per environment, no drift row (`live: terraform plan -refresh-only`, staging 10:24, prod 10:53, No changes), duplicate check not done; L4 E1–E3 pass on the diff and on both plans
**Escalations:** none
**Environment tier:** staging=staging (proven: `live: aws sts get-caller-identity` 10:00 account 222222222222 = `code: envs/staging.tfvars:3`, `code: providers.tf:16`), prod=prod (proven: `live: aws sts get-caller-identity` 10:01 account 333333333333 = `code: envs/prod.tfvars:3`, `code: providers.tf:16`)
**Staging-first:** applied — staging 10:46
**Waived:** none

## Research Summary
- Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset). Catalog: none — proceeding without catalog (service-discovery suggested). Ticket: none.
- Duplicate check: **not done** — `code:` no `aws_cloudwatch_metric_alarm` anywhere in the repo (only the `main.tf:3` comment that says it is absent); `git:` `git log --all --oneline -S'CPUUtilization'` and `-S'aws_cloudwatch_metric_alarm'` → no hits; `git branch -a --list '*cpu*' '*alarm*'` → none; `gh pr list --state open --search 'cpu alarm'` → none.
- Delivery model: `UNVERIFIED` in the repo (no CI config, no Atlantis / Terraform Cloud, no backend block, no GitOps); recorded `operator-stated` at `[A]` (10:23): Terraform is applied by hand from the operator's workstation, a direct apply is fine. Env selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/*.tfvars:1`, `providers.tf:12-17`).
- Target check: staging account 222222222222 / ap-southeast-1 (10:00, re-checked 10:35 and 10:39); prod account 333333333333 / ap-southeast-1 (10:01, re-checked 10:52, 11:02 and 11:06). No `[H1]`.
- Drift: none (`terraform plan -refresh-only`: staging 10:24, prod 10:53, both `No changes.`). Live batch: services `ACTIVE` (staging 1/1, prod 3/3), topics `paymentapi-alerts-<env>` exist with email-only subscribers (protocols `email`, `email`), no CPU alarm existed live, no CI runs (`gh run list` → `[]`), alarm price $0.10 per alarm-month (`ap-southeast-1`, publication 2026-10-07).
- L2 from evidence (no L2 question was typed): `Q1(alarms)=no` (`live`, staging 10:33, prod 11:00); `Q1(declared)=no`, `Q2=no` (`operator (no objection at [A], 10:23)`; at prod's `[B]`, `operator (no objection at [B], 11:13)`; no freeze source, no incident command); `Q3=no` (`live`: request count 1.02× the same hour last week in both, staging 10:34, prod 11:01); `Q4=many times`, `Q5=experienced` (`operator (profile, 2026-10-19)`); `Q7=none` (`operator`); `iac-change.4=recent` (`live`: ECS deployment 5 days ago in staging, 28 days in prod; no CI run; Terraform state object not read — no backend block); Q6 not asked (cost scored from the plan and the pricing lookup); Q8 not applicable (change is not-app-facing: alarm, SNS actions, email-only subscribers).
- Operator line shown at `[A]` and at prod's `[B]`: no reply both times.

## Evidence
| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| ECS cluster / service names the alarm watches | `code: main.tf:9` `paymentapi-cluster-${var.env}`, `main.tf:72` `paymentapi-svc-${var.env}` | `live: aws ecs describe-services …` staging 10:25 → `paymentapi-svc-staging` ACTIVE; prod 10:54 → `paymentapi-svc-prod` ACTIVE | ✅ |
| Alerts topic exists, per env, notify-only | `code: main.tf:174-175` `paymentapi-alerts-${var.env}` | `live: aws sns list-subscriptions-by-topic … Protocol` staging 10:28, prod 10:57 → `email`, `email` | ✅ |
| No CPU alarm exists | `code: none` | `live: describe-alarms-for-metric` staging 10:29, prod 10:58 → `[]`; `describe-alarms --alarm-names paymentapi-cpu-high-<env>` staging 10:30, prod 10:59 → `[]` | ✅ |
| Load balancer in front of the service | `code: main.tf:84-88` (target group; the ALB is not in this repo) | `live: aws elbv2 describe-target-groups` staging 10:26, prod 10:55 → `paymentapi-alb-<env>` | ✅ |
| Alarm price | none | `live: aws pricing get-products` 10:31 → `$0.10 per alarm metric month` | ✅ |

Drift rows: 0. Unverified rows: 0. Code-only rows: 0.

## Change Plan
**Phase 1 of 1: add the CPU alarm** (code written once; applied per environment, staging then prod, by direct apply)
- Files: `main.tf` (one new `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` block after the SNS topic).
- Resources affected: add `paymentapi-cpu-high-staging` and `paymentapi-cpu-high-prod`; change 0, destroy 0.
- Blast radius: the snapshot set (per env: the new alarm, ECS service `paymentapi-svc-<env>`, ALB `paymentapi-alb-<env>` with its target group). `Snapshot coverage: code + live (target-group → load balancer read); no catalog, no runtime profile; not covered: callers outside this repo, the load balancer's other target groups, the topic's subscribers beyond their protocols`.
- Disruption: `none` — `code:` the diff adds one resource and edits none; `plan:` 1 to add, 0 to change in both environments.
- Rollback path: remove the resource block (`git revert`), plan, apply the same way; reversible (stateless alarm); `untested`.
- Success criteria: `terraform plan -var-file=envs/<env>.tfvars` → `No changes.`; `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-<env>` → exists, `ActionsEnabled` true, `AlarmActions` = the env's topic ARN; S2 (alarms firing, ECS running vs desired, target health).
- Execution path: Direct apply, one `terraform apply tfplan` per environment (each with its own `[B]`). Staging-first (H7): staging, then prod; observation window: until staging's success criteria pass.
- Branch: `main` → `iac-change/paymentapi-add-cpu-alarm` from `origin/main` @ `a1b2c3d`.
- Plan self-check 8/8. Approved at `[A]` 10:23.

## Execution Log
### Phase 1: add the CPU alarm — staging
- Files changed: `main.tf`
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`, `paymentapi-cpu-high-staging`)
- Plan hash: `sha256:d316b334fda5d81e64ba26cb6ff87d37650bc43d7ac9b13d5badf2325ea64962`
- Parity check: n/a
- Pre-flight verdict: GREEN, 11/11 Green, no Yellow or ⚪ findings, no mitigations; verdict returned to caller and acknowledged by approving `[B]` (staging) at 10:46
- Execution: `terraform apply tfplan` (staging, account 222222222222) at 10:46 → `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` (`paymentapi-cpu-high-staging`)
- Verification: `terraform plan -var-file=envs/staging.tfvars` → `No changes.` (10:47); `describe-alarms --alarm-names paymentapi-cpu-high-staging` → exists, `ActionsEnabled` true, `AlarmActions` = `arn:aws:sns:ap-southeast-1:222222222222:paymentapi-alerts-staging`, `StateValue` `OK` (10:48); S2 alarms → none firing (10:49) — pass
- Snapshot: before 10:33–10:34 (S0, reused as S1) · after 10:49–10:51 · 4 ok / 0 regressed / 0 no data

### Phase 1: add the CPU alarm — prod
- Files changed: `main.tf` (the same code, approved once at `[A]`; prod's 4a ran from it)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high`, `paymentapi-cpu-high-prod`)
- Plan hash: `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8`
- Parity check: pass
- Pre-flight verdict: GREEN, 11/11 Green, no Yellow or ⚪ findings, no mitigations; verdict returned to caller and acknowledged by approving `[B]` (prod) at 11:13; staging evidence passed to it, not used to raise any category
- Execution: `terraform apply tfplan` (prod, account 333333333333) at 11:13 → `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` (`paymentapi-cpu-high-prod`)
- Verification: `terraform plan -var-file=envs/prod.tfvars` → `No changes.` (11:14); `describe-alarms --alarm-names paymentapi-cpu-high-prod` → exists, `ActionsEnabled` true, `AlarmActions` = `arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod`, `StateValue` `OK` (11:15); S2 alarms → none firing (11:16) — pass
- Snapshot: before 11:00–11:01 (S0, reused as S1) · after 11:16–11:18 · 4 ok / 0 regressed / 0 no data

## Health Snapshot
`Snapshot coverage: code + live (target-group → load balancer read); no catalog, no runtime profile; not covered: callers outside this repo, the load balancer's other target groups, the topic's subscribers beyond their protocols`

Members (per environment; the change is not-app-facing, so no dependents or dependencies are in the set):
- `aws_cloudwatch_metric_alarm.paymentapi_cpu_high` — the changed resource (new); `n/a — no health signals of its own`; judged by its success criteria. Source: `code:` (diff).
- ECS service `paymentapi-svc-<env>` — workload. Source: `code: main.tf:72`.
- ALB `paymentapi-alb-<env>` with target group `paymentapi-tg-<env>` — front door. Source: `code: main.tf:84-88`, `live:` `describe-target-groups`.

Metric signals have no after-read for this change (not-app-facing: no two-period wait, no S2 metrics call), so they are left out of the counts and the no-data list.

### staging
**S0 (before apply, 10:33–10:34)**

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| ECS `paymentapi-svc-staging` | alarms firing on member | 0 | — | — | `describe-alarms --state-value ALARM` | 10:33 |
| ECS `paymentapi-svc-staging` | running vs desired | 1 / 1, pending 0 | — | — | `ecs describe-services` | 10:25 |
| ECS `paymentapi-svc-staging` | deployments | 1 PRIMARY COMPLETED, created 2026-11-04T08:20:41Z | — | — | `ecs describe-services` | 10:25 |
| ECS `paymentapi-svc-staging` | CPU avg | 9.6–14.4 % (mean 11.8) | — | — | `get-metric-data` | 10:34 |
| ECS `paymentapi-svc-staging` | memory avg | 26–30 % (mean 27.8) | — | — | `get-metric-data` | 10:34 |
| ALB `paymentapi-alb-staging` | alarms firing on member | 0 | — | — | `describe-alarms --state-value ALARM` | 10:33 |
| ALB `paymentapi-alb-staging` | target health | 1 healthy, 0 unhealthy | — | — | `elbv2 describe-target-health` | 10:27 |
| ALB `paymentapi-alb-staging` | request count (hour; last week) | 2562 (2523) | — | — | `get-metric-data` | 10:34 |
| ALB `paymentapi-alb-staging` | target 5xx / ELB 5xx (hour; last week) | 0 / 0 (0 / 0) | — | — | `get-metric-data` | 10:34 |
| ALB `paymentapi-alb-staging` | p95 target response time (5-min p95s; last week) | 0.108–0.120 s (0.110–0.122 s), approximate | — | — | `get-metric-data` | 10:34 |
| ALB `paymentapi-alb-staging` | healthy / unhealthy host count, min | 1 / 0 | — | — | `get-metric-data` | 10:34 |
| `paymentapi_cpu_high` | — | n/a — no health signals of its own (new) | — | — | — | — |

**S1 (staging):** reused S0 (alarms 10:33, metrics 10:34), age 3 min at 10:36.

**S2 (after apply, 10:49–10:51)**

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| ECS `paymentapi-svc-staging` | alarms firing on member | 0 | 0 | ok | `describe-alarms --state-value ALARM` | 10:49 |
| ECS `paymentapi-svc-staging` | running vs desired | 1 / 1 | 1 / 1 | ok | `ecs describe-services` | 10:50 |
| ALB `paymentapi-alb-staging` | alarms firing on member | 0 | 0 | ok | `describe-alarms --state-value ALARM` | 10:49 |
| ALB `paymentapi-alb-staging` | healthy targets | 1 | 1 | ok | `elbv2 describe-target-health` | 10:51 |
| `paymentapi_cpu_high` | exists, enabled, state | absent | exists, `ActionsEnabled` true, `OK` | judged by success criteria (pass) | `describe-alarms --alarm-names` | 10:48 |
| ECS / ALB metric signals | CPU, memory, requests, 5xx, p95, host counts | see S0 | not read — not-app-facing, no after-read | left out of counts | — | — |

### prod
**S0 (before apply, 11:00–11:01)**

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| ECS `paymentapi-svc-prod` | alarms firing on member | 0 | — | — | `describe-alarms --state-value ALARM` | 11:00 |
| ECS `paymentapi-svc-prod` | running vs desired | 3 / 3, pending 0 | — | — | `ecs describe-services` | 10:54 |
| ECS `paymentapi-svc-prod` | deployments | 1 PRIMARY COMPLETED, created 2026-10-12T14:02:11Z | — | — | `ecs describe-services` | 10:54 |
| ECS `paymentapi-svc-prod` | CPU avg | 35.6–40.4 % (mean 37.8) | — | — | `get-metric-data` | 11:01 |
| ECS `paymentapi-svc-prod` | memory avg | 50–54 % (mean 51.8) | — | — | `get-metric-data` | 11:01 |
| ALB `paymentapi-alb-prod` | alarms firing on member | 0 | — | — | `describe-alarms --state-value ALARM` | 11:00 |
| ALB `paymentapi-alb-prod` | target health | 3 healthy, 0 unhealthy | — | — | `elbv2 describe-target-health` | 10:56 |
| ALB `paymentapi-alb-prod` | request count (hour; last week) | 41442 (40820) | — | — | `get-metric-data` | 11:01 |
| ALB `paymentapi-alb-prod` | target 5xx / ELB 5xx (hour; last week) | 0 / 0 (0 / 0) | — | — | `get-metric-data` | 11:01 |
| ALB `paymentapi-alb-prod` | p95 target response time (5-min p95s; last week) | 0.108–0.120 s (0.110–0.122 s), approximate | — | — | `get-metric-data` | 11:01 |
| ALB `paymentapi-alb-prod` | healthy / unhealthy host count, min | 3 / 0 | — | — | `get-metric-data` | 11:01 |
| `paymentapi_cpu_high` | — | n/a — no health signals of its own (new) | — | — | — | — |

**S1 (prod):** reused S0 (alarms 11:00, metrics 11:01), age 3 min at 11:03.

**S2 (after apply, 11:16–11:18)**

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| ECS `paymentapi-svc-prod` | alarms firing on member | 0 | 0 | ok | `describe-alarms --state-value ALARM` | 11:16 |
| ECS `paymentapi-svc-prod` | running vs desired | 3 / 3 | 3 / 3 | ok | `ecs describe-services` | 11:17 |
| ALB `paymentapi-alb-prod` | alarms firing on member | 0 | 0 | ok | `describe-alarms --state-value ALARM` | 11:16 |
| ALB `paymentapi-alb-prod` | healthy targets | 3 | 3 | ok | `elbv2 describe-target-health` | 11:18 |
| `paymentapi_cpu_high` | exists, enabled, state | absent | exists, `ActionsEnabled` true, `OK` | judged by success criteria (pass) | `describe-alarms --alarm-names` | 11:15 |
| ECS / ALB metric signals | CPU, memory, requests, 5xx, p95, host counts | see S0 | not read — not-app-facing, no after-read | left out of counts | — | — |

## Outcome
completed

**Applied:** staging yes — verified (re-plan `No changes.`; `paymentapi-cpu-high-staging` exists, `ActionsEnabled` true, `OK`; snapshot 4 ok · 0 regressed · 0 no data; no `no data` members); prod yes — verified (re-plan `No changes.`; `paymentapi-cpu-high-prod` exists, `ActionsEnabled` true, `OK`; snapshot 4 ok · 0 regressed · 0 no data; no `no data` members)

## Ticket Reference
none
