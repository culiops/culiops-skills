**Pre-flight assessment for:** `orderapi` / `prod`
**Action:** `Create CloudWatch metric alarm orderapi-prod-cpu-high (CPUUtilization > 80% on ECS orderapi-svc-prod); notifies SNS topic orderapi-alerts`
**Date:** `2026-11-08 HH:mm` (time and timezone unknown: clock read returned no canned output)
**Commit:** `unknown` (git: no canned output); dirty-tree state unknown
**Target:** `123456789012 / us-east-1` (UNVERIFIED: inferred from the SNS topic ARN in `envs/prod.tfvars:2`; no provider block) | `n/a` | `workspace: not provided / var-file: envs/prod.tfvars (inferred from plan values) / backend key: not provided`
**Plan hash:** `none — not reusable` (`sha256sum` returned no canned output; hash not computed)
**Plan source:** `UNVERIFIED — command not stated; operator-supplied plan-output.txt`
**Delivery model:** `manual apply by the operator` (`operator-stated`: first message "before I apply it", confirmed at GATE 1; no pipeline file found)
**Invoked by:** `operator`
**Mode:** standalone
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human)`; L3 opted in but unavailable (target check returned no canned output)
**App source:** `not available — category 11 ⚪`

## Verdict: RED — SOFT BLOCK

Escalation: 9 of 11 categories are Yellow or ⚪ (3+ rule). No category is individually Red. No hard block. Seven categories are unknown (⚪): gather more information before proceeding.

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | ⚪ | One resource created, nothing changed or destroyed. Plan completeness is unconfirmed: operator answered yes to "-target / -refresh=false / non-default workspace or var-file" without saying which; the non-default var-file part is certain, the other two are not ruled out and state is unreadable. A targeted or unrefreshed plan makes this ⚪ at best | `plan:3`, `plan:26`, `operator-stated` (assessor Q3), `UNVERIFIED` | Operator action: state which of the three applied, or supply a plain `terraform plan -var-file=envs/prod.tfvars` |
| 2 | Reversibility | ⚪ | Create-only: no in-place attribute change, no destroy, no data. Rollback is `git revert` -> plan -> apply. Same plan-completeness caveat as category 1 | `plan:3`, `plan:26`, `assessor:iac-change.md Reversibility (rollback)`, `operator-stated` (assessor Q3) | Same as category 1 |
| 3 | Change velocity | ⚪ | Git history for the changed paths could not be read; assessor Q4 answer did not match an option, recorded as unsure | `UNVERIFIED` (git: no canned output), `operator-stated (unverified)` | Read-only `git log --since=7.days <base> -- main.tf variables.tf envs/prod.tfvars`, excluding this change's commits, plus `git status` |
| 4 | Dependency impact | ⚪ | No catalog (`.culiops/service-discovery/orderapi.md` not found). The not-app-facing exception does not apply: SNS subscriber protocols were not checked, so the alarm counts as app-facing. The three IaC files hold no reference to the alarm, but other stacks are not visible | `code:main.tf:1-19`, `code:envs/prod.tfvars:2`, `UNVERIFIED` | Approve the SNS protocol read (L3 #6): all `email` / `email-json` / `sms` -> not-app-facing -> Green from the plan. Or run service-discovery first |
| 5 | Timing context | ⚪ | No incident (Q1 no) and no freeze (Q2 no), both `operator`. "Not in peak traffic" (Q3 no) is `operator-stated` only and cannot score Green on its own; the apply time was not stated; the L3 request-rate check was unavailable | `operator` (Q1, Q2), `operator-stated` (Q3) | Approve L3 and name the apply window; or confirm someone is on hand at apply time |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform. Does not lower any other category | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | The change adds a static-threshold CPU alarm (> 80%, 3 periods of 300s). It exists only in code; Green needs live confirmation it exists and is enabled. The not-app-facing shortcut (Green for a pure alarm addition) is unavailable until the SNS protocols are checked | `code:main.tf:6-9`, `code:main.tf:17-18`, `assessor:iac-change.md Observability` | After apply, confirm the alarm is enabled and leaves `INSUFFICIENT_DATA`; approve L3 #5 to see alarms already on this metric |
| 8 | Cost impact | 🟡 | One new billable resource. Price was not looked up (no pricing read, no `docs:`), so the alarm exception for Green does not apply. Cost answer is `operator-stated` | `plan:26`, `operator-stated` (Q6 negligible) | Look up the CloudWatch alarm price for us-east-1 and record the lookup date |
| 9 | Security posture | 🟢 | No IAM, network, encryption, public-access, audit-log or secret-reference change in the plan | `plan:4-24` | — |
| 10 | Resource health | ⚪ | L3 unavailable for this category: target check returned no canned output, so no health, saturation or firing-alarm data | `UNVERIFIED` | Approve and run L3 #2-#4 once the identity check passes |
| 11 | Application compatibility | ⚪ | Triggered: `alarm_actions` / `ok_actions` point at SNS topic `orderapi-alerts` and the subscriber protocols are unchecked, so the alarm is app-facing (fail-closed). No app source (Q8 = c). Silent breakage not assessable | `plan:18-23`, `operator` (Q8 = (c)) | Read the SNS subscriber protocols (L3 #6), or give an app source location |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Alarm name, metric, threshold, dimensions | `main.tf:2-15` | not checked | ✓ code ↔ plan (`plan:5-17`); live UNVERIFIED |
| Environment value `prod` | `envs/prod.tfvars:1` | not checked | ✓ (`plan:5`, `plan:15-16`) |
| SNS topic for alarm and ok actions | `envs/prod.tfvars:2`, `main.tf:17-18` | not checked | ✓ (`plan:18-23`); live UNVERIFIED |
| Account `123456789012` / region `us-east-1` | `envs/prod.tfvars:2` (inferred from ARN) | not checked | UNVERIFIED |
| Create-only plan: 1 add, 0 change, 0 destroy | `plan:3`, `plan:26` | not checked | ✓ code ↔ plan; completeness unconfirmed (assessor Q3) |
| An alarm of the same name already exists | none | not checked | UNVERIFIED |
| SNS subscriber protocols | not in code | not checked | UNVERIFIED |
| Drift ("Objects have changed outside of Terraform") | none in `plan:1-26` | not checked | no drift rows from the plan |

Unverified facts called out: target identity, SNS subscriber protocols, any pre-existing alarm, price, git history.

## Verification
- Citations checked: 7 (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 9 (1, 2, 3, 4, 5, 7, 8, 10, 11); hard blocks checked: cat 2 irreversible data change / public IP release (none, `plan:3`, `plan:26`), cat 5 active incident + freeze (Q1 no, Q2 no), cat 9 public exposure / encryption removal / secrets (none, `plan:4-24`), cat 10 error budget exhausted (not established, no live data) → none triggered → 3+ escalation → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model, workspace and backend key, apply time and "not peak" (Q3), cost answer (Q6), assessor Q3 and Q4 answers (`operator-stated`); account / region (inferred from an ARN), plan source, plan hash (none computed), git history, SNS subscriber protocols, existing alarms, alarm price, app source (all `UNVERIFIED`)

## Hard Blocks
none

## Acknowledged Risks
Operator answered "acknowledge and proceed" at GATE 2. No individual finding is Red, so the soft block comes from escalation. No separate reason was stated. Acknowledged items: categories 1, 2, 3, 4, 5, 10, 11 (⚪) and 7, 8 (Yellow).

## Mitigations Committed
None committed. The operator named no mitigation at GATE 2; all mitigations in the scorecard are treated as not committed.

## Context Provided (L2)
- Q1 active incident: no (`operator`)
- Q2 deploy freeze: no (`operator`)
- Q3 peak traffic at apply time: no (`operator-stated`)
- Q4 changed this service before: many times (`operator`)
- Q5 used this IaC tool before: experienced (`operator`)
- Q6 cost impact: negligible (`operator-stated`)
- Q7 other context: none
- Q8 application source: (c) not available (`operator`)
- Assessor Q1 (ran and reviewed the plan): answered by the supplied plan text, not asked
- Assessor Q2 (delivery model): manual apply, asked at GATE 1 (`operator-stated`)
- Assessor Q3 (-target / -refresh=false / non-default workspace or var-file): "as proposed / yes" (`operator-stated`; which of the three was not given)
- Assessor Q4 (stack applied recently): "as proposed / yes", no option matched, recorded as unsure (`operator-stated (unverified)`)

## L1 Analysis Detail
Scanned `plan-output.txt`, `main.tf`, `variables.tf`, `envs/prod.tfvars`. Plan is create-only for one `aws_cloudwatch_metric_alarm` (1 add, 0 change, 0 destroy); no replace, moved, removed or import; no drift block. No service-discovery catalog (`.culiops/service-discovery/orderapi.md` not found). Git history, `git status` and HEAD could not be read (no canned output). Output root: `.culiops/` at the repo root (`CULIOPS_HOME` read returned no canned output; treated as unset). Category 11 marking: the alarm's actions notify an SNS topic whose subscriber protocols were not checked, so the alarm is treated as app-facing. No commit offered: `.culiops/` tracked-state and current branch could not be established (`git check-ignore`: no canned output).

## L3 Queries Run
L3 requested, operator opted in (batch of 7 shown). 
1. `aws sts get-caller-identity --query Account --output text` → no canned output; live identity not confirmed against the target, so queries 2-7 were not run (Constraint 10).
2-7. not run: ECS health, ECS CPU, firing alarms, alarms on this metric, SNS subscriber protocols, alarm price.
L3 unavailable for categories 3, 4, 5, 7, 8, 10, 11 — scoring based on L1+L2 only.
