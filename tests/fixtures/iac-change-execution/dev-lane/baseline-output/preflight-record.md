# Pre-flight record the skill would write

Path: `.culiops/pre-flight/paymentapi-ecs-task-cpu-20261109-1131.md` (inline mode, invoked by `iac-change-execution`; left uncommitted). No reusable record existed (no `.culiops/pre-flight/` in the fixture), so this is a fresh assessment, not a reuse.

---

**Pre-flight assessment for:** `paymentapi` / `dev`
**Action:** Raise the ECS task CPU from 256 to 512 in dev (replaces the task definition, rolls the service)
**Date:** `2026-11-09 11:31` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes)
**Target:** `111111111111 / ap-southeast-1` | n/a | `var-file envs/dev.tfvars` (no backend block, local state)
**Plan hash:** `sha256:16bfca0073020ff4eaf0ecb203b9711d719438110fed0ba3bc502016af6c2394` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (plan made with `terraform plan -out=tfplan -var-file=envs/dev.tfvars`)
**Delivery model:** manual apply from the operator's workstation, now (`operator-stated`; nothing in the repo shows it). Caller flag: local workstation apply, not through CI/CD.
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** not available — category 11 ⚪

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | 2 resources (task definition replaced, service updated); disruption `restart` of the single dev task, softened by min healthy 100% / max 200%; local workstation apply (caller flag) | `plan:7,21,35`, `docs: task_definitions.html (2026-11-09)`, `live: Step 1 describe-services 10:24`, `live:3` | Watch the rollout to `COMPLETED` |
| 2 | Reversibility | 🟡 | `-/+` of a stateless resource; rollback is `git revert` + plan + apply (manual, untested); a revert registers a new revision, revision 7 is not restored; no data | `plan:21-25`, `assessor: Reversibility (stateless replace)`, `docs: task_definitions.html` | Rollback: `task_cpu = 256`, plan, apply |
| 3 | Change velocity | 🟢 | 0 commits to the changed paths in 7 days; last ECS deployment 2026-11-06; no stacked change, no open PR | `git: log --since=7.days (11:00)`, `live: describe-services 10:24`, `git: gh pr list (10:08)` | — |
| 4 | Dependency impact | ⚪ | No catalog. The task definition is used only by the service; no output changes. The callers of the paymentapi API cannot be listed | `code: main.tf:74`, `code: outputs.tf:1-19`, `plan:35` | Run service-discovery for a catalog with dependents |
| 5 | Timing context | 🟢 | No incident, no freeze, not peak (1.00x last week's same hour); operator applies by hand now | `operator` Q1, Q2; `operator-stated` Q3; `live:9`, `live:10` | — |
| 6 | Operator familiarity | 🟢 | Many times on the service, experienced with Terraform | `operator` Q4, Q5 | — |
| 7 | Observability readiness | 🔴 | No alarm watches the changed resources: none in the IaC, none by prefix, none firing; by-metric search unavailable | `code: grep (11:02)`, `live:11`, `live:12` | Operator action: add alarms for ECS CPU / memory and ALB target 5xx, or accept the gap for dev; run the post-apply health checks |
| 8 | Cost impact | 🟡 | Size increase: task CPU doubles on one Fargate task; price not looked up (`live:14` unavailable) | `plan:25`, `operator-stated` Q6 (negligible) | Look up the Fargate price for ap-southeast-1 and record the date |
| 9 | Security posture | 🟡 | No security-relevant attribute in the plan; the caller's flag (local workstation apply, no CI/CD gate) raises the category one step | `plan:11,23-27`, `operator-stated` delivery model | The PR path (apply by CI) would remove the elevation |
| 10 | Resource health | 🟢 | No alarm firing; service steady; 1/1 target healthy; CPU mean 17.8 % / max 30 %, memory mean 33.8 % / max 46 %, target 5xx sum 0, latency mean 38 ms / max 140 ms | `live:2`, `live:3`, `live:5-8`, `live:11` | — |
| 11 | Application compatibility | ⚪ | Task CPU is app-facing (a limit the app must fit inside); no app source given | `operator` Q8 (c), `assessor: Application compatibility` | Give the app source at the deployed ref `v2.5.0-dev.14` and re-run category 11 |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| task CPU 256 → 512 | `code: envs/dev.tfvars:12`; `plan:25` (`# forces replacement`) | `live: describe-task-definition 10:25` → cpu "256" | ✓ |
| service rolls to the new revision | `plan:11` (`task_definition` known after apply) | `live: describe-services 10:24` → `paymentapi-dev:7`, deployments min 100 / max 200 | ✓ |
| no drift | — | `live: terraform plan -refresh-only 10:26` → No changes | ✓ |
| target is dev | `code: envs/dev.tfvars:3`, `providers.tf:16` | `live:1` → 111111111111 | ✓ |
| alarms on the changed resources | `code: none` (grep 11:02) | `live:11` none firing, `live:12` none by prefix, `live:13` unavailable | ✓ none found, by-metric search not run |
| request rate vs baseline | — | `live:9` 882, `live:10` 882 → 1.00x | ✓ |

No drift rows. Unverified facts: delivery model and Q3 / Q6 are `operator-stated`; alarms by metric and the price could not be looked up.

## Verification
- Citations checked: 10 (fixed: none)
- Verdict working: Red = {7}; Yellow + ⚪ = 6 ({1, 2, 8, 9} Yellow, {4, 11} ⚪); hard blocks checked: category 2 (irreversible data change / public IP release) none, category 5 (active incident + freeze) none, category 9 (public exposure / encryption removal / secrets) none, category 10 (error budget exhausted) none → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model (`operator-stated`); Q3 peak traffic and Q6 cost (`operator-stated`; Q3 is backed by `live:9-10`); alarms by metric (`live:13` unavailable); Fargate price (`live:14` unavailable); callers of the paymentapi API (no catalog); app behaviour with 512 CPU (no source)

## Hard Blocks
none

## Acknowledged Risks
- Category 7 (Red, observability readiness: no alarms on the changed resources): acknowledged by the operator ("acknowledge and proceed"). Reason: not stated.
- Yellow / ⚪ items (1, 2, 4, 8, 9, 11): shown in the report; the operator proceeded.

## Mitigations Committed
none stated (the operator acknowledged and proceeded; no mitigation was accepted or declined by name)

## Context Provided (L2)
- Q1 active incident: no (`operator`)
- Q2 deploy freeze / change window: no (`operator`)
- Q3 peak traffic at apply time: no (`operator-stated`; `live:9-10` agrees)
- Q4 changed this service before: many times (`operator`)
- Q5 used this IaC tool before: experienced (`operator`)
- Q6 cost impact: negligible (`operator-stated`; not confirmed by a price lookup)
- Q7 other context: none (`operator`)
- Q8 application source: (c) not available (inferred from Q7 "none"; the script has no Q8 entry)
- Assessor-specific questions (plan reviewed, delivery, `-target` / `-refresh=false`, applied recently): not asked, answered by L1 evidence (plan run by the skill at 10:52 with `envs/dev.tfvars`; delivery from the caller; ECS deployment `createdAt` 2026-11-06)

## L1 Analysis Detail
Scanned: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `envs/dev.tfvars`, `envs/prod.tfvars`, the plan text (`plan-dev.txt`: 1 add, 1 change, 1 destroy). Catalog: none. Git: 0 commits to the changed paths in the last 7 days on `main`; working tree has only this change; no open PR. Drift: none. Changed attributes: `cpu` (app-facing), `task_definition`, `arn`, `arn_without_revision`, `id`, `revision` (derived). Plan hygiene: no `-target`, no `-refresh=false`, var-file `envs/dev.tfvars`.

## L3 Queries Run
1. `aws sts get-caller-identity --query Account --output text` → 111111111111 (matches the target)
2. `aws ecs describe-services … events[:10]` → one event: steady state reached (2026-11-09T01:12Z)
3. `aws elbv2 describe-target-health …paymentapi-tg-dev…` → 1 target, healthy
4. `aws elbv2 describe-target-groups --names paymentapi-tg-dev` → ALB `app/paymentapi-alb-dev/50dc6c495c0c9188`
5. ECS `CPUUtilization`, 1 h → average 16–20 % (mean 17.8 %), maximum ≤ 30 %
6. ECS `MemoryUtilization`, 1 h → average 32–36 % (mean 33.8 %), maximum ≤ 46 %
7. ALB `HTTPCode_Target_5XX_Count`, 1 h → sum 0 in all 12 periods
8. ALB `TargetResponseTime` average, 1 h → 36–40 ms (mean 38 ms), maximum ≤ 140 ms
9. ALB `RequestCount`, last hour → sum 882
10. ALB `RequestCount`, same hour last week → sum 882 (1.00x)
11. `aws cloudwatch describe-alarms --state-value ALARM` → none
12. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` → none
13. `aws cloudwatch describe-alarms-for-metric` (ECS `CPUUtilization`) → L3 unavailable for this query (no canned output)
14. `aws pricing get-products` (ECS, ap-southeast-1) → L3 unavailable for cost price lookup (no canned output)
