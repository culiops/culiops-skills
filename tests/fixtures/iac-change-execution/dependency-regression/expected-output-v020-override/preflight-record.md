<!-- Two pre-flight records, each the file pre-flight would write under .culiops/pre-flight/ (dry run: both are kept here). Section 1: staging. Section 2: prod. -->

# Section 1 — .culiops/pre-flight/orders-remove-db-vpc-cidr-rule-20261116-1121.md

**Pre-flight assessment for:** `orders` / `(no instance)`
**Action:** Destroy `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` (10.20.0.0/16 → tcp 5432 on the orders-db security group), staging
**Date:** `2026-11-16 11:21` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `222222222222 / ap-southeast-1` | no kube context | default workspace / `envs/staging.tfvars` / no backend block (local state)
**Plan hash:** `sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7`
**Plan source:** `terraform show -no-color tfplan` (plan made by `terraform plan -out=tfplan -var-file=envs/staging.tfvars`, 11:05)
**Delivery model:** local workstation apply, by hand — not going through CI/CD pipeline (operator-stated, first message; `code: providers.tf:1-17` no backend / cloud block, no CI config)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads)`
**App source:** `not available — category 11 ⚪` (Q8 = (c), operator, 10:53)

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | The rule is the only path from the api and the worker (two services, one behind the ALB) to the database; disruption predicted as loss of the database path, no softener (single-AZ staging); effect on open connections `UNVERIFIED` | `plan:` 1 to destroy; `code: main.tf:42,70,100,129`; `live:` 10:18, 10:19 | Operator action: confirm no other path (a rule outside this repo) lets those subnets reach 5432; have the rollback commit ready |
| 2 | Reversibility | 🟡 | Destroy of a stateless networking rule: recreatable, rollback by revert → plan → apply, untested; no `docs:` found (lookup 10:47: no canned output) | `plan:`, `assessor: destroy/replace on networking rules → Yellow` | Operator action: rehearse the revert in this environment |
| 3 | Change velocity | 🟢 | No commit to `main.tf` in 7 days; last deployment about 3 days ago (proxy) | `git: git log --since=7.days → none (11:14)`, `live:` ECS `createdAt` (10:20) | — |
| 4 | Dependency impact | 🔴 | One database shared by two services (api, worker); no catalog; batch jobs named in a code comment are unseen | `code: main.tf:42,70`; `live:` 10:19 (api and worker reach the database through the rule, not the group); `catalog: none` | Operator action: list the rule's consumers before prod; staging's S2 is the measurement |
| 5 | Timing context | 🟢 | No firing alarm, traffic 1.01x last week's hour, no declared incident, no freeze | `live:` S1 11:06-11:07; `operator (no objection at [F2], 10:53)`; `code:` no freeze calendar (10:10) | — |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced | `operator (profile, 2026-10-26)` | — |
| 7 | Observability readiness | 🟡 | One worker alarm exists and is enabled (static threshold 20 errors per 5 min, SNS actions); nothing watches the api's 5XX or the database path | `live:` 10:25 (`ActionsEnabled=true`); `code: main.tf:341-360` | Operator action: watch `orders-worker-errors-staging` and the api 5XX after the apply |
| 8 | Cost impact | 🟢 | One rule destroyed; no snapshot, backup or purchase is left behind to keep billing | `plan:` 1 to destroy; `code: main.tf:287-294` (no companion resource) | — |
| 9 | Security posture | 🟢 | A narrowing: the full before (two ingress rules) and after (admin-host rule only) documents are in evidence; no `0.0.0.0/0`, no `Deny` / `NotAction` | `plan:`; `live:` 10:18 | — |
| 10 | Resource health | 🟢 | No alarm firing; target 5XX 0.20% (1w 0.20%), p95 0.18 s (1w 0.184 s), CPU at most 38.4%, db connections avg 38 — within the same hour last week | `live:` S1 11:06-11:10 (caller) | — |
| 11 | Application compatibility | ⚪ | Triggered (a security-group rule on the database; not on the not-app-facing list); no app source; silent-breakage note: it is not known whether `/healthz` touches the database | `plan:`, `assessor:` fail-closed | Provide the app source (Q8) or check how the api and worker handle a refused database connection |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Rule exists | `code: main.tf:287-294`, `plan:` destroy | `live: describe-security-groups` 10:18 (caller) | ✓ |
| Group attached to the DB; only the DB's interface attached | `code: main.tf:262` | `live:` 10:17, 10:19 (caller) | ✓ |
| api and worker subnets inside 10.20.0.0/16 | `code: envs/staging.tfvars:6-7,10-11` | not read | code-only |
| Batch jobs use the rule | `code: main.tf:285-286` (comment) | not visible | UNVERIFIED |
| Effect on open connections | — | lookup 10:47: no canned output | UNVERIFIED |
| Drift | `plan:` no refresh changes | `live: terraform plan -refresh-only` 10:28: No changes | ✓ (no drift rows) |

## Verification
- Citations checked: 14 (fixed: none) — every Red, every Green on categories 4, 7, 9, 10 and the cost premise re-opened against the plan, the code lines and the caller's reads.
- Verdict working: Red = 1, 4; Yellow + ⚪ = 3 (2, 7, 11); hard blocks checked: category 2 (irreversible data change — no, stateless rule), 5 (active incident + freeze — no), 9 (public exposure / encryption removal / secrets — no), 10 (error budget exhausted — no) → RED — soft block.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: the effect on connections already open (`UNVERIFIED`); batch jobs and other callers outside the repo; `operator-stated` Q1(declared), Q2, Q7; whether `/healthz` touches the database; subnet CIDRs (`code:` only).

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]` by the operator, 2026-11-16 11:21: Red blast radius (1), Red dependency impact (4), and the multi-Yellow escalation (2, 7, 11). Reason, word for word: "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures".

## Mitigations Committed
none stated by the operator (the reason above was given instead). Offered: confirm no other path to 5432, rollback commit ready, watch the worker alarm and the api 5XX.

## Context Provided (L2)
- Q1: `Q1(alarms)=no` — `live: aws cloudwatch describe-alarms --state-value ALARM, S1 11:06 (caller): 0 firing on the snapshot set`; `Q1(declared)=no` — `operator (no objection at [F2], 10:53)`
- Q2: no — `operator (no objection at [F2], 10:53)`; no freeze calendar in the repo (`code:` 10:10)
- Q3: no — `live: aws cloudwatch get-metric-data, S1 11:07 (caller): 24,130 requests vs 23,890 the same hour last week, 1.01x`
- Q4: many times — `operator (profile, 2026-10-26)`
- Q5: experienced — `operator (profile, 2026-10-26)`
- Q6: not asked — scored by L1 from the plan (a single rule destroyed, nothing left billing)
- Q7: none — `operator (no objection at [F2], 10:53)`
- Q8: (c) not available — `operator` (10:53)
- `iac-change.1`: yes, plan run by the skill (`Plan hash:`); `iac-change.2`: applied by hand from the operator's workstation, direct apply — `operator-stated`; `iac-change.3`: no, default workspace, `envs/staging.tfvars` (`Target:`); `iac-change.4`: recent — `live:` ECS `createdAt` 2026-11-12T08:20Z (proxy; no CI history, state object location not in the code)

## L1 Analysis Detail
Plan: 0 to add, 0 to change, 1 to destroy (one `aws_vpc_security_group_ingress_rule`). Not made with `-target` or `-refresh=false`. No drift. No catalog. Git: no commit to `main.tf` in the last 7 days (the latest three commits are older than 30 days). Category 11 triggered (fail-closed).

## L3 Queries Run
Target check (pre-flight, 11:13): `aws sts get-caller-identity` → account 222222222222 = `Target:`. The caller's reads, as `live: <cmd> (caller, <time>)`: `aws rds describe-db-instances` (10:17, S1 11:10), `aws ec2 describe-security-groups` (10:18), `aws ec2 describe-network-interfaces` (10:19), `aws ecs describe-services` (10:20, S1 11:08), `aws ecs describe-task-definition` x2 (10:21-10:22), `aws elbv2 describe-target-groups` / `describe-target-health` (10:23-10:24, S1 11:09), `aws cloudwatch describe-alarms --alarm-name-prefix orders` (10:25), `aws cloudwatch describe-alarms --state-value ALARM` (10:26, S1 11:06), `aws cloudwatch get-metric-data` (10:27, S1 11:07), `terraform plan -refresh-only` (10:28), `gh run list` (10:41), `ls ..` / `git -C ../dotfiles remote get-url origin` (10:42-10:43). Pre-flight's own local reads: `git log --since=7.days` (11:14), `git status --short` (11:15). No further L3 batch was needed.

---

# Section 2 — .culiops/pre-flight/orders-remove-db-vpc-cidr-rule-20261116-1203.md

**Pre-flight assessment for:** `orders` / `(no instance)`
**Action:** Destroy `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` (10.20.0.0/16 → tcp 5432 on the orders-db security group), prod
**Date:** `2026-11-16 12:03` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `333333333333 / ap-southeast-1` | no kube context | default workspace / `envs/prod.tfvars` / no backend block (local state)
**Plan hash:** `sha256:b50cdd033369a9bc25f680a6c0dad1ca08bb74e7b9a09471d148eecd7ef008a2`
**Plan source:** `terraform show -no-color tfplan` (plan made by `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 11:47)
**Delivery model:** local workstation apply, by hand — not going through CI/CD pipeline (operator-stated, first message; no backend / cloud block, no CI config)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads)`
**App source:** `not available — category 11 ⚪` (Q8 = (c), operator, 10:53)

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | Same cause as staging (the rule is the api's and the worker's only path to the database), now on 4 tasks per service behind the production ALB, plus a measured staging effect: api target 5XX 0.20% → 3.10%, worker job errors 0.50% → 23.2%, worker alarm firing (staging evidence, not proof; the `[H10]` override calls it unrelated, and an override is not evidence) | `plan:` 1 to destroy; `code: main.tf:42,70`; `live:` 10:30-10:31; `live: staging S1 11:07 / S2 11:37` | Operator action: have the rollback commit ready; watch `orders-worker-errors-prod`; confirm no consumer other than the api and worker |
| 2 | Reversibility | 🟡 | Destroy of a stateless networking rule; rollback by revert, untested; no `docs:` found | `plan:`, `assessor:` | Rehearse or confirm the revert path (staging's apply is the only rehearsal of the destroy) |
| 3 | Change velocity | 🟢 | No commit to `main.tf` in 7 days; last deployment 11 days ago (proxy) | `git: none (11:56)`, `live:` ECS `createdAt` 2026-11-05 (10:32) | — |
| 4 | Dependency impact | 🔴 | One database shared by two services; no catalog; batch jobs unseen; staging showed both dependents react | `code: main.tf:42,70`; `live:` 10:31; `catalog: none`; `live: staging S2 11:37` | Operator action: list the rule's consumers before the apply |
| 5 | Timing context | 🟢 | No firing alarm, traffic 1.01x, no declared incident or freeze | `live:` S1 11:48-11:49; `operator (no objection at [F2], 10:53)` | — |
| 6 | Operator familiarity | 🟢 | many times / experienced | `operator (profile, 2026-10-26)` | — |
| 7 | Observability readiness | 🟡 | The worker alarm exists and is enabled; staging showed it firing; nothing watches the api's 5XX | `live:` 10:37; `live: staging S2 11:36` | Watch the api 5XX by hand, the worker alarm covers only the worker |
| 8 | Cost impact | 🟢 | One rule destroyed; nothing left billing | `plan:`, `code: main.tf:287-294` | — |
| 9 | Security posture | 🟢 | A narrowing; full before and after documents in evidence | `plan:`; `live:` 10:30 | — |
| 10 | Resource health | 🟢 | prod now: no alarm firing; target 5XX 0.20% (1w 0.20%), p95 0.183 s, CPU at most 41.4%, db connections avg 85.8 — within the same hour last week. Staging's regression is evidence about the change, not about prod's current health | `live:` S1 11:48-11:52 (caller) | — |
| 11 | Application compatibility | ⚪ | Triggered; no app source | `plan:`, `assessor:` fail-closed | Provide the app source (Q8) |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Rule exists | `code: main.tf:287-294`, `plan:` destroy | `live: describe-security-groups` 10:30 (caller) | ✓ |
| Group attached to the DB; only the DB's interface attached | `code: main.tf:262` | `live:` 10:29, 10:31 (caller) | ✓ |
| api and worker subnets inside 10.20.0.0/16 | `code: envs/prod.tfvars:6-7,10-11` | not read | code-only |
| Batch jobs use the rule | `code: main.tf:285-286` (comment) | not visible | UNVERIFIED |
| Drift | `plan:` no refresh changes | `live: terraform plan -refresh-only` 10:40: No changes | ✓ |

Staging evidence (evidence, not proof), from the caller block:
- measured disruption during staging's apply: no redeploy, no restart; the api and worker lost the database path (inferred from the signals below)
- success criteria: the security group shows the admin-host rule only (`live: describe-security-groups` staging 11:28); db `available` (staging 11:29); re-plan `No changes` (staging 11:27)
- staging S1 (11:06-11:10) → S2 (11:36-11:40): target 5XX 0.20% → 3.10% (regressed); worker job errors 0.50% → 23.2% (regressed); alarm `orders-worker-errors-staging` OK → ALARM (regressed); db connections avg 38 → 30; p95 0.180 → 0.215 s (ok)
- override at `[H10]`: "unrelated: staging load test started 10:40, see #ops" — operator, 11:46 (`operator`; an override is not evidence)
- var-file size differences: db class `db.t4g.medium` (`code: envs/staging.tfvars:15`) vs `db.r6g.large` (`code: envs/prod.tfvars:15`); api / worker desired count 2 (`envs/staging.tfvars:21-22`) vs 4 (`envs/prod.tfvars:21-22`); image tag `v1.9.0-rc1` (`envs/staging.tfvars:19-20`) vs `v1.8.3` (`envs/prod.tfvars:19-20`)

## Verification
- Citations checked: 16 (fixed: none)
- Verdict working: Red = 1, 4; Yellow + ⚪ = 3 (2, 7, 11); hard blocks checked: 2, 5, 9, 10 — none → RED — soft block.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: effect on connections already open (`UNVERIFIED`); batch jobs and other callers outside the repo; `operator-stated` Q1(declared), Q2, Q7; whether `/healthz` touches the database; subnet CIDRs; whether the staging regression and prod behave alike (staging evidence is not proof).

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]` by the operator, 2026-11-16 12:03: Red blast radius (1), Red dependency impact (4), and the multi-Yellow escalation (2, 7, 11). Reason, word for word: "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures".

## Mitigations Committed
none stated by the operator (the reason above was given instead).

## Context Provided (L2)
- Q1: `Q1(alarms)=no` — `live: describe-alarms --state-value ALARM, S1 11:48 (caller): 0 firing`; `Q1(declared)=no` — `operator (no objection at [F2], 10:53)`
- Q2: no — `operator (no objection at [F2], 10:53)`
- Q3: no — `live: get-metric-data, S1 11:49 (caller): 108,130 requests vs 107,050 the same hour last week, 1.01x`
- Q4: many times — `operator (profile, 2026-10-26)`; Q5: experienced — `operator (profile, 2026-10-26)`
- Q6: not asked — scored by L1 from the plan
- Q7: none — `operator (no objection at [F2], 10:53)`; Q8: (c) not available — `operator` (10:53)
- `iac-change.1`: yes; `.2`: applied by hand, direct apply — `operator-stated`; `.3`: no, default workspace, `envs/prod.tfvars`; `.4`: recent — `live:` ECS `createdAt` 2026-11-05T07:10Z (11 days; proxy)

## L1 Analysis Detail
Plan: 0 to add, 0 to change, 1 to destroy. No `-target`, no `-refresh=false`. No drift. No catalog. No commit to `main.tf` in 7 days.

## L3 Queries Run
Target check (pre-flight, 11:55): `aws sts get-caller-identity` → account 333333333333 = `Target:`. The caller's prod reads (10:29-10:40, S1 11:48-11:52), cited `live: <cmd> (caller, <time>)`, and staging's S1 / S2 as staging evidence. Pre-flight's own local reads: `git log --since=7.days` (11:56), `git status --short` (11:57). No further L3 batch was needed.
