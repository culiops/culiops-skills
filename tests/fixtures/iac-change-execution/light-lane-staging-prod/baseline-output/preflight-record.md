Would be written to `.culiops/pre-flight/paymentapi-add-cpu-alarm-20261109-1130.md` (inline invocation by iac-change-execution; left uncommitted).

**Pre-flight assessment for:** `paymentapi` / none
**Action:** Add CloudWatch CPU utilization alarm `paymentapi-cpu-high-prod` (1 resource to add, 0 to change, 0 to destroy)
**Date:** 2026-11-09 11:30 (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf` modified on branch `iac-change/paymentapi-add-cpu-alarm`)
**Target:** `333333333333 / ap-southeast-1` | n/a (no kube context) | `Terraform var-file envs/prod.tfvars, no workspace, no backend block (local state)`
**Plan hash:** `sha256:1e420453c286b1fad946f06d7ef85ede4e4ffe073f31d8715c3c4fa2c9763fc8` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (after `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 10:51)
**Delivery model:** manual apply by hand from the operator's workstation, now; direct apply (`operator-stated`: no CI workflow, GitOps object, Atlantis / Terraform Cloud / Spacelift config, README or Makefile found in the repo; kept as the caller's citation). Caller flag: local workstation apply, not going through CI/CD pipeline.
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** not needed: only not-app-facing attributes changed (the alarm's actions go to an SNS topic whose subscriptions are all `email`, `live:12`). Q8 was not answered by the operator.

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One resource added in one region, so the change itself is small. Raised from Green because the apply is a local workstation apply, not through CI/CD (caller flag, iac-change-execution SKILL.md:330). | `plan: Plan: 1 to add, 0 to change, 0 to destroy`, `operator-stated` (delivery model), caller flag | Operator action: re-check the target check at the apply prompt (account 333333333333); after apply confirm the alarm leaves INSUFFICIENT_DATA |
| 2 | Reversibility | 🟢 | Pure create, no in-place attribute change. Rollback: `git revert`, plan, apply (destroys the alarm). | `plan: + create aws_cloudwatch_metric_alarm.paymentapi_cpu_high` (a pure addition of an alarm needs no behaviour claim, pre-flight SKILL.md:32) | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in the last 7 days (all 3 commits in the log are older than 30 days); no open PR; last ECS deployment 2026-10-12 (28 days, under the 90-day lag threshold). | `git: git log --since=7.days origin/main -- main.tf` (none), `git: gh pr list` (none), `live: ecs describe-services 10:20` (caller's table) | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing (alarm notifying email subscribers only) and the plan changes no output or export. No catalog exists. | `plan: no output / export change`, `code: outputs.tf:1-19 unchanged`, `live:12` | — (consider running service-discovery) |
| 5 | Timing context | 🟢 | No incident, no freeze, not peak traffic: request rate 3,400-3,511 per 5 min, same as the same hour a week ago (ratio 1.0, under 1.5x). The operator applies interactively from a workstation, so someone who can respond is on hand. | `operator` (Q1, Q2), `operator-stated` (Q3, delivery model), `live:9`, `live:10` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform. | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟢 | The change only adds a not-app-facing alarm and changes nothing app-facing. No other alarm exists on this metric today. | `plan: only an alarm is added`, `live:11` (none on `CPUUtilization`), `live:12` | Confirm after apply that the new alarm leaves INSUFFICIENT_DATA (covered by the execution success criteria) |
| 8 | Cost impact | 🟢 | One standard alarm, 0.10 USD per alarm metric month in ap-southeast-1 (price list publication 2026-10-07, looked up 2026-11-09). Operator said negligible, consistent. | `live:13`, `operator-stated` (Q6) | — |
| 9 | Security posture | 🟡 | No IAM, security group, encryption or public-access change; the alarm publishes to the existing alerts topic. Raised from Green by the same caller flag (workstation apply, not CI/CD). | `plan: no security-relevant resource`, `code: main.tf:174-175` (topic unchanged), caller flag | Operator action: apply with the least-privilege write role for creating CloudWatch alarms and drop it afterwards (`examples/aws.md` Tier 2) |
| 10 | Resource health | 🟢 | Nothing firing; service 3/3 running, targets 3/3 healthy, steady-state event; CPU avg 35.6-40.4 % (max 50.4 %) and memory avg 50-54 % (max 64 %), both under 70 %; target 5xx sum 0 in 12 periods; latency avg 36-40 ms. | `live:2`, `live:3`, `live:4`, `live:6`, `live:7`, `live:8`, caller's table (`ecs describe-services 10:19`, CPU 10:23) | — |
| 11 | Application compatibility | 🟢 | Only a not-app-facing attribute changes: an alarm whose SNS action reaches only `email` subscriptions (protocols read, endpoints not read). | `plan: only an alarm is added`, `live:12` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Target is prod, account 333333333333 | `envs/prod.tfvars:3`, `providers.tf:16` | `live:1`: 333333333333 | ✓ |
| Service exists and is healthy | `envs/prod.tfvars:11` (desired 3), `main.tf:72` | caller's table 10:19: ACTIVE 3/3; `live:6`: 3 healthy targets | ✓ |
| SNS topic for alarm actions | `main.tf:174-175` | caller's table 10:21: topic exists; `live:12`: subscriptions `email`, `email` | ✓ |
| No alarm on the metric yet | `git grep` (none) | caller's table 10:22 (`[]`); `live:11` (`[]`) | ✓ |
| No drift | plan has no "Objects have changed" block | caller's table 10:24: `terraform plan -refresh-only` -> No changes | ✓ |

Drift rows: none. UNVERIFIED facts: none after `live:11`.

## Verification
- Citations checked: 7 (fixed: none)
- Verdict working: Red = none; Yellow + unknown = 2 (categories 1, 9; below the escalation threshold of 3); hard blocks checked: irreversible data change (cat 2), active incident + freeze (cat 5), public exposure / encryption removal / secrets (cat 9), error budget exhausted (cat 10): none triggered -> YELLOW
- Fresh eyes: not run — dry run (verdict is YELLOW, so the text requires it; no reviewer is dispatched in a dry run)
- Not verified: delivery model (`operator-stated`, nothing in the repo); Q1, Q2, Q4, Q5 (operator-only facts); Q3 and Q6 are `operator-stated` but agree with `live:9`/`live:10` and `live:13`; Q8 unanswered (no app source read, not needed once the alarm is notify-only)

## Hard Blocks
none

## Acknowledged Risks
- Category 1 (Yellow) and category 9 (Yellow), both raised by the direct-apply flag. Acknowledged by the operator at the risk decision (11:25). Operator-stated basis: "terraform is applied by hand from my workstation, and a direct apply is fine".

## Mitigations Committed
None recorded. The operator acknowledged and proceeded; the pre-flight text has no separate prompt for committing to or declining a mitigation. Both mitigations are operator actions; the apply prompt re-shows the target check and the execution success criteria include the alarm-state check.

## Context Provided (L2)
1. Active incident: no (`operator`)
2. Deploy freeze or change window: no (`operator`)
3. Apply time in peak traffic: no (`operator-stated`; `live:9`, `live:10` agree)
4. Changed this service before: many times (`operator`)
5. Used this IaC tool before: experienced (`operator`)
6. Expected cost impact: negligible (`operator-stated`; `live:13` agrees)
7. Other context: none (`operator`)
8. Application source: no answer given (script has no entry; treated as not available), not needed after `live:12`
Assessor questions skipped because L1 held the answer: plan run and reviewed (plan run and shown this session), delivery model (caller's `operator-stated`), `-target` / `-refresh=false` / var-file (command on record), applied recently (ECS deployment 2026-10-12).

## L1 Analysis Detail
Scanned: the plan text (hash above), `main.tf`, `outputs.tf`, `providers.tf`, `envs/prod.tfvars`. Catalog: none (`.culiops/service-discovery/paymentapi.md` not present). Git history: `git log --since=7.days --oneline origin/main -- main.tf` -> no commits; the three commits in the log (#104, #111, #118) are older than 30 days. `git status --short` -> ` M main.tf` (this change only). Open PRs: none. Drift: none. Evidence table passed by the caller: used for ECS state, deployment time, topic existence, alarms by prefix and the CPU baseline; those reads were not repeated.

## L3 Queries Run
1. `aws sts get-caller-identity --query Account --output text` -> `333333333333` (matches the target)
2. `aws ecs describe-services ... --query 'services[].events[:10]...'` -> one event, "has reached a steady state" (2026-11-09T01:12:40Z)
3. `aws cloudwatch get-metric-statistics ... MemoryUtilization ...` -> avg 50-54 %, max 64 %
4. `aws cloudwatch describe-alarms --state-value ALARM ...` -> none firing
5. `aws elbv2 describe-target-groups --names paymentapi-tg-prod` -> target group and load balancer `paymentapi-alb-prod`
6. `aws elbv2 describe-target-health ...` -> 3 targets, all healthy
7. `aws cloudwatch get-metric-statistics ... HTTPCode_Target_5XX_Count ...` -> sum 0 in all 12 periods
8. `aws cloudwatch get-metric-statistics ... TargetResponseTime ...` -> avg 36-40 ms, max 140 ms
9. `aws cloudwatch get-metric-statistics ... RequestCount` (last hour) -> 3,400-3,511 per 5 min
10. `aws cloudwatch get-metric-statistics ... RequestCount` (same hour 7 days ago) -> 3,400-3,511 per 5 min
11. `aws cloudwatch describe-alarms-for-metric ... CPUUtilization ...` -> none
12. `aws sns list-subscriptions-by-topic ... --query 'Subscriptions[].Protocol'` -> `email`, `email` (endpoints not read)
13. `aws pricing get-products ... AmazonCloudWatch ...` -> standard alarm 0.10 USD per alarm metric month, ap-southeast-1, publication 2026-10-07
