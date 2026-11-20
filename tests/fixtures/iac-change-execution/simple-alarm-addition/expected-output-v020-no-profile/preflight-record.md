**Pre-flight assessment for:** `paymentapi` / none
**Action:** Add CloudWatch alarm `paymentapi-cpu-high-prod` (Average CPUUtilization of `paymentapi-svc-prod` > 80 for 3 x 300 s, actions to the alerts SNS topic)
**Date:** `2026-11-09 11:00` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `123456789012 / ap-southeast-1` | none (no Kubernetes) | `default workspace / var-file envs/prod.tfvars / no backend block in code`
**Plan hash:** `sha256:30f496228b0721c60508346a6e04217f8204b5b39ffbefe041e6c6ebf7070a89` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** `CI applies on merge` — UNVERIFIED — operator-stated: "a CI pipeline applies on merge" (`[A]`, 10:34); no CI config in the repo (`code:` grep 10:13)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's results)`
**App source:** `not needed — only not-app-facing attributes changed`

## Verdict: YELLOW — PROCEED WITH CAUTION

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | Single resource, single region; 1 add, 0 change, 0 destroy; not app-facing, so no disruption claim is needed | `plan: plan-prod.txt:42` | — |
| 2 | Reversibility | 🟢 | Pure addition; rollback is `git revert`, plan, apply; no attribute changes in place | `plan: plan-prod.txt:6` (create), `code: main.tf:185-208` | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in the last 7 days; no open PR; last successful apply 3 days ago | `live: git log --since=7.days` (10:59), `live: gh pr list` (10:12, caller), `live: gh run list` (caller, 10:43) | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing and no output or export changes; nothing can consume an alarm | `plan: plan-prod.txt:6-42`, `code: outputs.tf:1-19` (untouched) | — |
| 5 | Timing context | ⚪ | `Q1(alarms)=no` (live), `Q1(declared)=no`, `Q2=no` (both `operator`, no freeze calendar in the repo); `Q3=unsure`: the apply happens at merge and peak hours are 14-18 +07:00 | `live: get-metric-data (caller, 10:39)`, `operator (no objection at [A], 10:34)`, `UNVERIFIED — apply at merge` | Merge outside 14-18 +07:00, or with the service owner on hand |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator` (this run, `[A]` 10:34) | — |
| 7 | Observability readiness | 🟢 | The change only adds a not-app-facing alarm and changes nothing app-facing | `plan: plan-prod.txt:6-42`, `live: sns list-subscriptions-by-topic (caller, 10:42)` | After the apply, confirm the alarm leaves `INSUFFICIENT_DATA` |
| 8 | Cost impact | 🟢 | Only new resource is a standard alarm: USD 0.10 per alarm metric month in ap-southeast-1 (price publication 2026-10-07, looked up 2026-11-09) | `live: aws pricing get-products (caller, 10:44)` | — |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access, audit or secret change | `plan: plan-prod.txt:6-42` | — |
| 10 | Resource health | 🟢 | 0 alarms firing; target 5xx 0 (1w ago 0); p95 0.114 s (1w 0.116 s); CPU 38.0 % (1w 37.4 %) and memory 52.0 % (1w 51.5 %), both under 70 %; ECS 3/3 running; 3/3 targets healthy | `live: describe-alarms`, `describe-services`, `describe-target-health`, `get-metric-data` (caller, 10:55-10:58) | — |
| 11 | Application compatibility | 🟢 | Only not-app-facing attributes changed: an alarm whose actions go to an SNS topic with email-only subscribers | `plan: only not-app-facing attributes changed (aws_cloudwatch_metric_alarm create; actions notify-only)`, `live: sns list-subscriptions-by-topic (caller, 10:42)` | — |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Alarm `paymentapi-cpu-high-prod` does not exist | `code: none` | `live: describe-alarms --alarm-names` (caller, 10:40): none | ✓ |
| No alarm on the service's CPU metric | `code: none` | `live: describe-alarms-for-metric` (caller, 10:41): none | ✓ |
| ECS service desired 3 | `code: envs/prod.tfvars:10` | `live: describe-services` (caller, 10:55): desired 3, running 3 | ✓ |
| Service behind `paymentapi-tg-prod` | `code: main.tf:84-88` | `live: describe-services` loadBalancers (caller, 10:35) | ✓ |
| Alert topic subscribers | `code: main.tf:174-175` | `live: list-subscriptions-by-topic` (caller, 10:42): email, email | ✓ |
| Stack matches the code | — | `live: terraform plan -refresh-only` (caller, 10:46): No changes | ✓ |

No drift rows. No unverified rows.

## Verification
- Citations checked: 14 (every Green on 1, 2, 4, 7, 9, 10, 11 re-opened against `plan-prod.txt` and the live results; fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 1 (category 5); hard blocks checked: irreversible data change (2), active incident + deploy freeze (5), public exposure / encryption removal / secrets (9), error budget exhausted (10) → none triggered → YELLOW (a ⚪ caps the verdict at YELLOW)
- Fresh eyes: not run — dry run
- Not verified: `Q1(declared)`, `Q2`, `Q4`, `Q5`, `Q7` rest on `operator`; the delivery model is operator-stated; peak hours come from the last 7 days only; category 7 Green rests on the assessor's rule for a change that only adds not-app-facing monitoring, with no live read of the new alarm possible before the apply

## Hard Blocks
none

## Acknowledged Risks
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`)

## Mitigations Committed
verdict returned to caller — operator acknowledges at the caller's execution gate (`[B]`)

## Context Provided (L2)
- Q1(alarms) = no — `live: aws cloudwatch describe-alarms --state-value ALARM` (caller, 10:57): 0 firing on the snapshot set
- Q1(declared) = no — operator (no objection at [A], 10:34)
- Q2 = no — operator (no objection at [A], 10:34); no freeze calendar in the repo (`code:` grep 10:14)
- Q3 = unsure — UNVERIFIED — apply at merge; peak hours 14-18 +07:00 (live, `get-metric-data`, 10:39); request rate 41,442 per h vs 40,827 a week ago (1.02x)
- Q4 = many times — operator (this run, [A] 10:34)
- Q5 = experienced — operator (this run, [A] 10:34)
- Q6 — not asked: L1 scores cost from the plan and the price lookup
- Q7 = none — operator (no objection at [A], 10:34)
- Q8 — not needed (not an app-facing change)
- iac-change.1 = yes (plan hash passed) · iac-change.2 = CI applies on merge (Delivery model) · iac-change.3 = no: default workspace, the env's own var-file (Target + plan command) · iac-change.4 = recent — `live: gh run list` (caller, 10:43): last `terraform-apply` success 2026-11-06 11:31 +07:00

## L1 Analysis Detail
Scanned: the plan text (1 create), `main.tf` and the added block, `outputs.tf` (unchanged), `envs/prod.tfvars`. No service-discovery catalog (none exists). Git history: 0 commits to `main.tf` in 7 days on `origin/main`; the change itself is uncommitted. Alarm actions both resolve to the SNS topic `paymentapi-alerts-prod`; subscribers are `email` only.

## L3 Queries Run
Inline mode: the caller's results, each `live: <cmd> (caller, <time>)`; pre-flight added one read of its own, the target check.
1. `aws sts get-caller-identity` (pre-flight target check, 11:00) — account 123456789012, matches `Target:`
2. `git log --since=7.days --oneline origin/main -- main.tf` (10:59) — no commits
3. `aws sts get-caller-identity` (caller, 10:47) — account 123456789012, `assumed-role/paymentapi-operator`
4. `aws ecs describe-services …` (caller, 10:55) — ACTIVE, 3/3 running, deployment PRIMARY COMPLETED
5. `aws elbv2 describe-target-groups --names paymentapi-tg-prod` (caller, 10:36) — ALB `paymentapi-alb-prod`
6. `aws elbv2 describe-target-health …` (caller, 10:56) — 3 healthy
7. `aws cloudwatch describe-alarms --state-value ALARM …` (caller, 10:57) — 0 firing
8. `aws cloudwatch get-metric-data` 7 days hourly (caller, 10:58) — values as in category 10
9. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` (caller, 10:40) — none
10. `aws cloudwatch describe-alarms-for-metric` (caller, 10:41) — none
11. `aws sns list-subscriptions-by-topic … --query Subscriptions[].Protocol` (caller, 10:42) — email, email
12. `gh run list --limit 5` (caller, 10:43) — last `terraform-apply` success 2026-11-06
13. `aws pricing get-products` (caller, 10:44) — USD 0.10 per standard alarm metric month
14. `terraform plan -refresh-only` (caller, 10:46) — No changes
