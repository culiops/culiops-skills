# Pre-flight record (as written by the inline run for staging)

Path it would be written to: `.culiops/pre-flight/orders-remove-db-vpc-cidr-rule-20261116-1121.md` (uncommitted).
Prod's pre-flight did not run: the run ended at `[H10]` after staging's apply.

**Pre-flight assessment for:** `orders` / `none (single instance)`
**Action:** Remove the legacy VPC-wide ingress rule (`aws_vpc_security_group_ingress_rule.orders_db_from_vpc`, 10.20.0.0/16 → 5432/tcp) from `orders-db-sg-staging`
**Date:** `2026-11-16 11:21` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`, this change's own)
**Target:** `account 222222222222 / ap-southeast-1` | n/a | `Terraform var-file envs/staging.tfvars, default workspace, no backend declared in code`
**Plan hash:** `sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (plan made with `terraform plan -out=tfplan -var-file=envs/staging.tfvars`)
**Delivery model:** `manual apply — terraform apply by hand from the operator's workstation, direct apply` (`UNVERIFIED in the repo: no CI / GitOps config, gh run list → []; operator-stated, first message 2026-11-16 10:00`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, answered from the caller's reads, profile and operator line) + L3 (the caller's live results)`
**App source:** `not available — category 11 ⚪ (Q8 = (c); the sibling search found no checkout)`

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | The destroyed rule is the only ingress that admits `orders-api` and `orders-worker` (and, per the code comment, batch jobs) to the database: multi-service, and the api is on the user-facing data path. Disruption `UNVERIFIED` (no `docs:` lookup possible), never `none`; nothing softens a loss of connectivity | `plan: aws_vpc_security_group_ingress_rule.orders_db_from_vpc destroy`; `code: main.tf:285-303, envs/staging.tfvars:6-11`; `live: aws ec2 describe-network-interfaces (caller, 10:18)`; `assessor: Blast radius` | Expand–contract: first add 5432 ingress rules whose source is `aws_security_group.orders_api` and `aws_security_group.orders_worker`, apply, verify, then remove the CIDR rule (operator action, a separate change) |
| 2 | Reversibility | 🟡 | Destroy of a stateless networking rule: recreatable with `git revert` → plan → apply, but the break is immediate and the rollback is untested | `plan:`; `code: main.tf:287-294`; `assessor: Reversibility (destroy on stateless networking rules)` | Keep the exact rule definition ready (`main.tf:287-294` at `origin/main`); rehearse the re-add path |
| 3 | Change velocity | 🟢 | 0 commits to the changed paths in 7 days; last apply 4 days ago (< 90 days); no open PR; no stacked change | `live: git log --since=7.days --oneline origin/main -- main.tf envs/ (11:16)`; `live: aws s3api head-object (caller, 10:29)`: 2026-11-12 15:22 +07:00; `live: gh pr list (10:08)` | — |
| 4 | Dependency impact | 🔴 | The database is shared by the api and the worker, and both dial it through the removed rule. No catalog, but code and live show the consumers (`catalog:` none) | `code: main.tf:42, 70, 285-286`; `live: aws ec2 describe-security-groups (caller, 10:17)`; `live: aws ec2 describe-network-interfaces (caller, 10:18)` | As category 1 |
| 5 | Timing context | 🟢 | No alarm firing on the snapshot set; no incident or freeze (operator); not peak (402 req/min vs 398 the same hour last week, 1.01×); the operator is present and applies by hand | `live: aws cloudwatch describe-alarms --state-value ALARM (caller, 11:08)`; `live: aws cloudwatch get-metric-data (caller, 11:09)`; `operator` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times, experienced with terraform. A manual apply has no CI safety net (noted, not scored) | `operator (profile, 2026-10-26)` | — |
| 7 | Observability readiness | 🟡 | Alarm `orders-worker-errors-staging` exists and is enabled (live) but watches worker job errors only; no alarm on the api (5XX, latency) or on database connectivity | `live: aws cloudwatch describe-alarms --alarm-name-prefix orders (caller, 10:25)`; `code: main.tf:341-360` | Add an api 5XX alarm before the apply, or watch the ALB 5XX and the worker alarm by hand through S2 |
| 8 | Cost impact | 🟢 | One rule destroyed, nothing created, nothing left billing (the plan lists the one resource; the rule has no snapshot, volume or address attached in code) | `plan: 0 to add, 0 to change, 1 to destroy`; `code: main.tf:287-294` | — |
| 9 | Security posture | 🟢 | A narrowing: the full before (live describe: CIDR rule + admin SG rule) and after (the admin rule alone, `code: main.tf:296-303`; the plan shows the whole destroyed resource) are in evidence. No `0.0.0.0/0`, no IAM, no encryption change | `plan:`; `code: main.tf:296-303`; `live: aws ec2 describe-security-groups (caller, 10:17)` | — |
| 10 | Resource health | 🟢 | Live S1 (caller): no alarm firing on the set, target 5XX 0.20% (same as last week), p95 0.180 s vs 0.184 s, CPU 27–38%, memory 44–52%, DB CPU 22%, targets 2 of 2 healthy, ECS 2/2, RDS `available` | `live: S1 reads (caller, 11:08–11:12)` | — |
| 11 | Application compatibility | ⚪ | App-facing change (the network path from the app to the database); no application source (Q8 = (c)). Silent breakage possible: the ALB health check `/healthz` (`code: main.tf:166`) may not touch the database, so health, ALB state and the target-group alarms can stay Green while DB calls fail | `operator (Q8, 10:54)`; `UNVERIFIED` | Provide the app source (Q8) so this category can be scored; until then treat the app's behaviour on a refused DB connection as unknown |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| The rule exists and is the one in the plan | `code: main.tf:287-294`; `plan:` destroy `sgr-0e1a2b3c4d5e6f701` | `live:` SG describe 10:17: 10.20.0.0/16 rule present | ✓ |
| Remaining ingress after the change | `code: main.tf:296-303` | `live:` SG describe 10:17: admin SG `sg-0e9f8a7b6c5d4e3f2` pair | ✓ |
| Only the DB's ENI is on this SG; api and worker tasks use their own SGs | `code: main.tf:100, 129` | `live:` ENI read 10:18; `describe-services` 11:10 (task SGs `sg-0e6b…`, `sg-0e7c…`) | ✓ |
| The api and the worker reach the DB through the CIDR rule | `code: main.tf:42, 70, 285-286`, `envs/staging.tfvars:6-11` (subnets inside 10.20.0.0/16) | `live:` task definitions carry `DB_HOST` (names only) | ✓ |
| Batch jobs use the rule | `code: main.tf:285-286` (comment only) | none | UNVERIFIED |
| Effect of removing the rule on new and established connections | none | none (docs lookup: no canned output) | UNVERIFIED |
| Worker alarm exists and is enabled | `code: main.tf:341-360` | `live:` describe-alarms 10:25: OK, actions enabled | ✓ |
| No drift | — | `terraform plan -refresh-only` 10:15: No changes | ✓ (0 drift rows) |

No drift rows. Unverified: batch jobs as callers; the removal's effect on connections; the app's behaviour.

## Verification

- Citations checked: 9 (fixed: none)
- Verdict working: Red = categories 1, 4; Yellow + ⚪ = 3 (categories 2, 7, 11), so the multi-Yellow escalation (3+) also gives RED; hard blocks checked: cat 2 not an irreversible data change, cat 5 no active incident with a freeze, cat 9 no public exposure / encryption removal / secrets, cat 10 no exhausted error budget → none → RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: Q1(declared) and Q2 rest on `operator (no objection at [F2], 10:54)`; the effect of removing the rule on established connections (`UNVERIFIED`, no `docs:`); batch jobs and any other VPC host as callers; the application's behaviour when the database refuses a connection (no source)

## Hard Blocks

none

## Acknowledged Risks

Acknowledged at `[H5]` (iac-change-execution's stop; pre-flight's GATE 2), operator, 2026-11-16 11:21, each Red finding with one reason:
- Category 1 Blast radius (Red): "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures"
- Category 4 Dependency impact (Red): same reason
- Multi-Yellow escalation (categories 2, 7, 11): same reason

## Mitigations Committed

none committed — the operator acknowledged the findings with a reason and committed to no mitigation. Offered and not committed: expand–contract with source-SG rules for the api and the worker (categories 1, 4); an api 5XX alarm or manual watching through S2 (category 7); provide the app source (category 11).

## Context Provided (L2)

- Q1 active incident: `Q1(alarms)=no` — `live: aws cloudwatch describe-alarms --state-value ALARM (caller, 11:08)`: 0 firing on the snapshot set; `Q1(declared)=no` — `operator (no objection at [F2], 10:54)`
- Q2 deploy freeze: no — `operator (no objection at [F2], 10:54)`; no freeze calendar in the repo (`code:` grep, none)
- Q3 peak traffic: no — `live: aws cloudwatch get-metric-data (caller, 11:09)`: 402 req/min vs 398 the same hour last week (1.01×)
- Q4: many times — `operator (profile, 2026-10-26)`; Q5: experienced — `operator (profile, 2026-10-26)`
- Q6 cost: not asked (L1 scores cost from the plan: one destroy)
- Q7 other context: none — `operator (no objection at [F2], 10:54)`
- Q8 app source: (c) not available — `operator, 10:54`
- iac-change.1–3: answered by `Plan hash:` + plan command, `Delivery model:` and `Target:`; no `-target`, no `-refresh=false`, default workspace with `-var-file=envs/staging.tfvars`
- iac-change.4: recent — `live: aws s3api head-object (caller, 10:29)`: last modified 2026-11-12 15:22 +07:00, 4 days ago; ECS deployments created 2026-11-12 15:20 +07:00 (`live: aws ecs describe-services, 11:10`)

## L1 Analysis Detail

Plan: 0 to add, 0 to change, 1 to destroy (one `aws_vpc_security_group_ingress_rule`). Drift: none. Every changed attribute is app-facing (a network rule on the database path; not on the not-app-facing list). No catalog (`.culiops/service-discovery/orders.md` absent) → category 4 from code and live reads. Git history: no commit to `main.tf` or `envs/` in the last 7 days; recent commits `e81b4c7`, `3f9a2d0`, `b52c8e1` are all older than 30 days. Caller's disruption field: `UNVERIFIED — expected loss of DB connectivity for the api and the worker; mechanism not documented in evidence`.

## L3 Queries Run

All taken from the caller's results, cited `live: <cmd> (caller, <time>)`. Pre-flight's own reads: the target check and the `git log` below. No extra batch.
1. `aws sts get-caller-identity` (pre-flight target check, 11:15) → account 222222222222, assumed-role `orders-operator` = Target
2. `git log --since=7.days --oneline origin/main -- main.tf envs/` (11:16) → no commits
3. `terraform plan -refresh-only -var-file=envs/staging.tfvars` (caller, 10:15) → no changes
4. `aws rds describe-db-instances orders-db-staging` (caller, 11:12) → available, not Multi-AZ, no pending change
5. `aws ec2 describe-security-groups sg-0e5a4b3c2d1f09876` (caller, 10:17) → CIDR rule + admin SG rule
6. `aws ec2 describe-network-interfaces` on that group (caller, 10:18) → one RDS ENI
7. `aws ecs describe-services orders-cluster-staging` (caller, 11:10) → api 2/2, worker 2/2
8. `aws ecs describe-task-definition` api and worker (caller, 10:20 / 10:21) → `DB_HOST` among the env names
9. `aws elbv2 describe-target-health orders-api-tg-staging` (caller, 11:11) → 2 of 2 healthy
10. `aws cloudwatch describe-alarms --alarm-name-prefix orders` (caller, 10:25) → worker alarm OK, actions enabled
11. `aws cloudwatch describe-alarms --state-value ALARM` (caller, 11:08) → none
12. `aws cloudwatch get-metric-data` (S1, caller, 11:09) → values as in the scorecard
13. `aws s3api head-object` on the state object (caller, 10:29) → last modified 2026-11-12 15:22 +07:00
14. `gh run list` (caller, 10:28) → `[]`
