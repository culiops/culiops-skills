**Pre-flight assessment for:** `orders` / `none (single instance)`
**Action:** Destroy `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` (the legacy `10.20.0.0/16` ingress on the orders-db security group) in staging; direct apply by hand. Prod is not assessed: the run ended before prod's turn.
**Date:** 2026-11-16 11:22 (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** account 222222222222 / ap-southeast-1 | `envs/staging.tfvars`, default workspace, state backend not declared in code
**Plan hash:** `sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan` (from `terraform plan -out=tfplan -var-file=envs/staging.tfvars`, 11:07)
**Delivery model:** manual apply by the operator from a workstation, direct apply (`operator-stated`, first message; `code:` no CI / Atlantis / TFC / Spacelift config in the repo) — local workstation apply, not going through CI/CD pipeline
**Invoked by:** iac-change-execution
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, answered from the caller's reads and the operator profile) + L3 (live, the caller's reads)`
**App source:** not available — category 11 ⚪ (`Q8=(c)`)
**Output root:** `.culiops/` at the repo root

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | The destroyed rule is the only one that admits orders-api and orders-worker to the database; two services, plus callers outside this repo (the code comment names batch jobs), lose their data path. orders-api is the user-facing order path. Disruption is expected, not established: the `docs:` lookups returned no canned output, so "refused" is `UNVERIFIED`; it is not `none`. | `plan:6`, `plan:21`; `code: main.tf:42,70,296-303`; `live: aws ec2 describe-security-groups sg-0e5a4b3c2d1f09876 (10:25)`; `live: aws ec2 describe-network-interfaces (10:26)`; `assessor: Blast radius (deletions, user-facing data path)` | Expand–contract: first add rules that admit the api and worker by security group, then remove the CIDR rule. S2 reads the dependents right after the apply. |
| 2 | Reversibility | 🟡 | Destroy of a stateless network rule: recreatable (revert the diff, plan, apply) but untested, and the effect holds until it is restored. No data, backup, key or one-way attribute is involved. "Re-creating the rule restores access" is `UNVERIFIED` (docs lookup returned no canned output). | `plan:6`; `assessor: Reversibility (destroy on stateless resources → Yellow; Terraform rollback)`; `code: main.tf:287-294` | Keep the reverted diff ready; know that the restore is a second apply per environment. |
| 3 | Change velocity | 🟢 | No commit to the changed paths in the last 7 days; no open PR or branch for this change; the stack was last deployed 4 days ago (ECS), well inside 90 days. | `code: git log --since=7.days --oneline origin/main -- main.tf envs/ → none (11:16)`; `live: gh pr list (caller, 10:12)`; `live: aws ecs describe-services deployments createdAt 2026-11-12 15:20 +07:00 (caller, 11:08)` | — |
| 4 | Dependency impact | 🔴 | The security group protects the shared database used by two services (api, worker) and possibly batch jobs; the rule is the path they use. No catalog exists (a catalog would only be a lead). | `code: main.tf:42,70,262`; `live: aws ecs describe-task-definition (caller, 10:22, 10:23)`; `live: DatabaseConnections avg 38 (caller, 11:12)`; `assessor: Dependency impact (shared infrastructure used by multiple services → Red)` | Inventory the other clients of the database before the apply (batch jobs, other VPC hosts); run service-discovery for orders; same expand–contract. |
| 5 | Timing context | 🟢 | No firing alarm on the set (`Q1(alarms)=no`), no declared incident and no freeze (operator, no objection at `[F2]`), request rate 1.01x the same hour last week (`Q3=no`); the operator applies by hand, so someone is on hand. | `live: aws cloudwatch describe-alarms --state-value ALARM (caller, 11:11)`; `live: get-metric-data (caller, 11:12)`; `operator (no objection at [F2], 10:55)` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times, experienced with terraform. | `operator (profile, 2026-10-26)` | — |
| 7 | Observability readiness | 🟡 | One alarm exists, is enabled and is `OK`: `orders-worker-errors-staging` (static threshold, JobErrors > 20 per 5 minutes). Nothing alarms on ALB 5XX, target health or database connections, so a break seen by the api would not page. | `code: main.tf:341`; `live: aws cloudwatch describe-alarms --alarm-name-prefix orders (caller, 10:30)`; `assessor: Observability (static threshold → Yellow; no alarm on part of the changed path)` | Watch S2 right after the apply; adding alarms for ALB 5XX and DB connections is a separate change. |
| 8 | Cost impact | 🟢 | 0 to add, 0 to change, 1 to destroy; no new resource or size increase; a rule has no companion that keeps billing. | `plan:21`; `code: main.tf:287-294` | — |
| 9 | Security posture | 🟡 | Network rule modification within the VPC: removes the `10.20.0.0/16` ingress allow, leaving the admin host's group. No public exposure, encryption or secret is touched. Narrowing is not marked Green (the effective-access conclusion needs documentation that was not available). | `plan:6,10`; `live: aws ec2 describe-security-groups (10:25)`; `assessor: Security posture (network rule modification within VPC → Yellow)` | Confirm that VPC access to the database should be limited to the admin host once the clients have their own rules. |
| 10 | Resource health | 🟢 | All signals nominal on the set at S1: no alarm firing, ALB target 5XX 0.20% (same hour last week 0.20%), p95 0.180 s (1w 0.184 s), worker job errors 0.50% (1w 0.50%), CPU and memory under 53% (below 70%), RDS `available`, 2/2 targets healthy. Silent breakage (the api's health check `/healthz` may not exercise the database): a Green here does not clear category 11. | `live: get-metric-data (caller, 11:12)`; `live: aws rds describe-db-instances (caller, 11:09)`; `live: aws elbv2 describe-target-health (caller, 11:10)`; `live: describe-alarms --state-value ALARM (caller, 11:11)`; `code: main.tf:165-168` | — |
| 11 | Application compatibility | ⚪ | Triggered: a network ingress change on a resource the app dials is app-facing (fail-closed). The application source is not available (`Q8=(c)`), so what the api and worker do when the connection is refused is unknown. | `plan:6`; `operator (Q8=(c))` | Name a source (local checkout or `owner/repo` + deployed ref `v1.9.0-rc1`) and re-run the check. |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| The rule admits 10.20.0.0/16 on 5432 | `code: main.tf:287-294`, `plan:10` | `live:` SG describe (10:25) | ✓ |
| Only other ingress is the admin host's SG | `code: main.tf:296-303` | `live:` SG describe (10:25) | ✓ |
| Only the DB (ENI) is attached to the SG | `code: main.tf:262` | `live:` ENI read (10:26) | ✓ |
| api and worker use `DB_HOST` | `code: main.tf:42,70` | `live:` task definition env names (10:22, 10:23) | ✓ |
| No drift | `code: main.tf` | `live: terraform plan -refresh-only (caller, 10:33)`: no changes | ✓ |
| Batch jobs / other callers use the rule | `code: main.tf:285-286` (comment: data) | not readable | UNVERIFIED |
| What removing a rule does to connections | n/a | n/a | UNVERIFIED (no `docs:`) |

No drift rows. `UNVERIFIED`: callers outside the repo, behaviour of the rule removal.

## Verification
- Citations checked: 13 (every Red, and every Green on categories 1, 2, 4, 7, 9, 10, 11 — only 10 is Green among them — plus the factual premise of each mitigation, re-opened against `main.tf`, the plan text and the live reads cited). Fixed: none.
- Verdict working: Red = categories 1, 4; Yellow + ⚪ = 4 (2, 7, 9, 11); 3 or more Yellow/⚪ also escalates to Red on its own; hard blocks checked: category 2 (irreversible data change — none: no data, backup or key involved), category 5 (active incident plus freeze — neither), category 9 (public exposure, encryption removal, secrets — none), category 10 (error budget exhausted — no SLO declared, no firing alarm) → none triggered → RED — soft block.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: the disruption and rollback behaviour (no `docs:` available); `Q1(declared)`, `Q2` and `Q7` rest on the operator's no-objection, not a calendar or an incident command; that someone is on hand rests on the operator applying by hand (operator-stated); `Q4` / `Q5` are profile answers; callers outside this repo (batch jobs) are not visible; where state lives is not in the code; what the application does when the connection is refused (no source).

## Hard Blocks
None.

## Acknowledged Risks
- Red 1 (Blast radius) and Red 4 (Dependency impact) — acknowledged at `[H5]` 11:22 (pre-flight's GATE 2), operator reason: "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures".
- Yellow / ⚪ findings 2 (Reversibility), 7 (Observability readiness), 9 (Security posture), 11 (Application compatibility): verdict returned to caller — operator acknowledges at the caller's execution gate (`[F4]`).

## Mitigations Committed
None committed at `[H5]`: the operator's reply gave a reason and did not commit to expand–contract, the client inventory or the other mitigations offered. Yellow / ⚪ items: verdict returned to caller — operator acknowledges at the caller's execution gate.

## Context Provided (L2)
- Q1 active incident: `Q1(alarms)=no` — `live: aws cloudwatch describe-alarms --state-value ALARM (caller, 11:11)`, 0 firing on the staging snapshot set; `Q1(declared)=no` — `operator (no objection at [F2], 10:55)`. No Incident Context follow-up (Q1 is no).
- Q2 deploy freeze: `no` — `operator (no objection at [F2], 10:55)`; no freeze calendar in the repo.
- Q3 peak traffic: `no` — `live: aws cloudwatch get-metric-data (caller, 11:12)`, ALB RequestCount 24,130 vs 23,890 the same hour last week (1.01x).
- Q4 service familiarity: `many times` — `operator (profile, 2026-10-26)`.
- Q5 tool familiarity: `experienced` — `operator (profile, 2026-10-26)`.
- Q6 cost: not asked; scored from the plan (one destroy, nothing added).
- Q7 other context: `none` — `operator (no objection at [F2], 10:55)`.
- Q8 application source: `(c) not available` — `operator`; no `app:` citations.
- iac-change.1: plan reviewed — answered by `Plan hash:` and its plan command. iac-change.2: manual apply, direct — answered by `Delivery model:`. iac-change.3: no `-target`, no `-refresh=false`, default workspace with `envs/staging.tfvars` — answered by `Target:` and the plan command. iac-change.4: `recent` — `live: aws ecs describe-services deployments createdAt 2026-11-12 15:20 +07:00 (caller, 11:08)`.

## L1 Analysis Detail
- Scanned: the staging plan text (`plan:1-21`), `main.tf`, `variables.tf`, `providers.tf`, `envs/staging.tfvars`, `envs/prod.tfvars`; git history on the changed paths (`git log --since=7.days --oneline origin/main -- main.tf envs/` → none, 11:16).
- Catalog: none. The evidence table from the caller (13 rows, 0 drift, 3 `UNVERIFIED`) is cited, not re-queried.
- Plan hygiene: no `-target`, no `-refresh=false`; the refresh found no drift; no unexpected resource; not an unexpected "No changes".
- App-facing marking: a network ingress change on the database's security group is not on the not-app-facing list, so category 11 is triggered.
- Docs: no documentation tool had an entry (the caller's lookups 10:47 and 10:48, and this run, returned no canned output); so no behaviour claim rests on `docs:` and none clears a score.

## L3 Queries Run
Caller's results (cited as `live: <cmd> (caller, <time>)`):
1. `aws ecs describe-services` (orders-api-staging, orders-worker-staging) · 10:21, 11:08 · 2/2 and 2/2, COMPLETED, createdAt 2026-11-12
2. `aws ecs describe-task-definition` (api, worker) · 10:22, 10:23 · env names only: `APP_ENV`, `DB_HOST`, `PORT` / `APP_ENV`, `DB_HOST`
3. `aws rds describe-db-instances` · 10:24, 11:09 · available, MultiAZ false, SG sg-0e5a4b3c2d1f09876
4. `aws ec2 describe-security-groups` · 10:25 · two ingress rules on 5432 (the CIDR and the admin group)
5. `aws ec2 describe-network-interfaces` · 10:26 · 1 interface (RDSNetworkInterface)
6. `aws elbv2 describe-target-groups` / `describe-load-balancers` / `describe-target-health` · 10:27-10:29, 11:10 · 2/2 healthy
7. `aws cloudwatch describe-alarms --alarm-name-prefix orders` · 10:30 · `orders-worker-errors-staging` enabled, OK
8. `aws cloudwatch describe-alarms --state-value ALARM` · 10:31, 11:11 · none firing
9. `aws cloudwatch get-metric-data` (staging snapshot set) · 10:32, 11:12 · target 5XX 0.199%, p95 0.180 s, job errors 0.500%, CPU/memory under 53%, DB connections avg 38; four RDS series no data
10. `terraform plan -refresh-only -var-file=envs/staging.tfvars` · 10:33 · no changes
Pre-flight's own reads:
11. `aws sts get-caller-identity` (target check) · 11:15 · account 222222222222 = the caller's `Target:`
12. `git log --since=7.days --oneline origin/main -- main.tf envs/` · 11:16 · no commits
