# Execution record (as the skill would write it)

Path it would be written to: `.culiops/iac-change-execution/orders-remove-db-vpc-cidr-rule-20261116-1146.md` (output root `.culiops/`, uncommitted).

**IaC change execution for:** `orders` / `none (single instance)`
**Change:** Remove the legacy `10.20.0.0/16` ingress rule (`aws_vpc_security_group_ingress_rule.orders_db_from_vpc`, 5432/tcp) from the orders-db security group; staging first, then prod
**Date:** `2026-11-16 11:46`
**Commit:** `a1b2c3d` (`origin/main` base; the change stays uncommitted in the working tree on branch `iac-change/orders-remove-legacy-db-vpc-rule`: direct apply, no commit, no PR)
**IaC tool(s):** terraform (AWS provider ~> 5.0, v5.74.0 in use)
**Execution path:** Direct apply (operator-requested, first message 2026-11-16 10:00)
**Pre-flight record:** `.culiops/pre-flight/orders-remove-db-vpc-cidr-rule-20261116-1121.md` — invoked inline for staging — verdict: RED — soft block (acknowledged at `[H5]`, 11:21). Prod: not reached, no pre-flight run.
**Lane:** full — Lane rule line 4: L1 fails (`plan:` 1 to destroy), L2 fails (the allowlist has no delete row); neither target is a proven dev tier
**Escalations:** none
**Environment tier:** staging=staging (live: account 222222222222 = code: `envs/staging.tfvars:3`, `providers.tf:16`); prod=prod (live: account 333333333333 = code: `envs/prod.tfvars:3`, `providers.tf:16`)
**Staging-first:** applied — staging 11:27
**Waived:** none

Prerequisites (examples files referenced): `examples/aws.md` — AWS CLI v2 (`aws-cli/2.17.21`); Tier 1 read-only role for Steps 1 and 5 (`ReadOnlyAccess` or a scoped `Describe*` / `List*` / `Get*` policy plus `cloudwatch:GetMetricData`, `cloudwatch:DescribeAlarms`, and `s3:GetObject` on the one state key for `head-object`); Tier 2 role for the mutation only (here `terraform apply` of one security-group-rule destroy); CloudWatch `GetMetricData` is billed per metric requested.

## Research Summary

- Catalog: none — `.culiops/service-discovery/orders.md` is absent; proceeded without it (service-discovery suggested).
- Duplicate check: **not done** — `code: main.tf:287-294` still defines the rule; `git:` `git log --all -S'10.20.0.0/16'` and `-S'orders_db_from_vpc'` found nothing; no branch `*orders-db*`; no open PR (`gh pr list`, 10:08).
- Delivery model: manual apply from the operator's workstation, direct apply — nothing in the repo shows it (no CI / GitOps config, `gh run list` → `[]`); `operator-stated` (first message). Env selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/*.tfvars`, `providers.tf:16`).
- Target: staging account 222222222222 / ap-southeast-1 (live 2026-11-16 10:01, re-read 11:06); prod account 333333333333 / ap-southeast-1 (live 10:32; not re-read: prod's 4a was not reached).
- Drift: none in either environment (`terraform plan -refresh-only`, staging 10:15, prod 10:33).
- Snapshot set and coverage: see Health Snapshot.
- Key findings: the rule is the only ingress that admits the api and the worker to the database (live: only the RDS ENI is on the DB SG; code: the tasks use their own SGs and their subnets sit inside 10.20.0.0/16). A documentation lookup for what the removal does to new and established connections returned no canned output (10:47): the mechanism is `UNVERIFIED`.
- Output root: `.culiops/` (`CULIOPS_HOME` unset). No write to the operator profile this run.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| Legacy CIDR rule exists (staging) | `code: main.tf:287-294` | `live: aws ec2 describe-security-groups sg-0e5a4b3c2d1f09876 (10:17)`: present | ✅ |
| Legacy CIDR rule exists (prod) | `code: main.tf:287-294` | `live: … sg-0c5a4b3c2d1f09876 (10:35)`: present | ✅ |
| DB SG's other ingress: the admin host | `code: main.tf:296-303` | `live:` same describes: admin SG pair on 5432 | ✅ |
| The DB uses this SG | `code: main.tf:262` | `live: aws rds describe-db-instances (10:16 / 10:34)` | ✅ |
| api and worker tasks use their own SGs; only the RDS ENI is on the DB SG | `code: main.tf:100, 129` | `live: aws ecs describe-services (10:19 / 10:37)`, `aws ec2 describe-network-interfaces (10:18 / 10:36)` | ✅ |
| api and worker reach the DB through the CIDR rule | `code: main.tf:42, 70, 285-286`; `envs/*.tfvars:6-11` inside 10.20.0.0/16 (`variables.tf:17`); no other rule on the DB SG admits them (`main.tf:287-303`) | `live:` SG describes; task definitions carry `DB_HOST` (names only) | ✅ |
| Batch jobs use the rule | `code: main.tf:285-286` (comment only) | none | ⚠️ UNVERIFIED — gap |
| Effect of the removal on new / established connections | none | none (docs lookup: no canned output) | ⚠️ UNVERIFIED |
| Worker alarm exists and is enabled | `code: main.tf:341-360` | `live: aws cloudwatch describe-alarms (10:25 / 10:43)` | ✅ |
| api and DB have no alarm | `code:` none | `live:` prefix read lists only the worker alarm | ✅ (a gap) |
| Multi-AZ | `code: main.tf:264` | `live:` staging false, prod true | ✅ |
| Drift | — | `terraform plan -refresh-only`: No changes (both) | ✅ — drift rows 0, unverified rows 2 |

## Change Plan

**Phase 1 of 1: Remove the legacy VPC-wide ingress rule from `orders-db-sg-<env>` — staging, then prod** (approved at `[F2]`, 2026-11-16 10:54)
- Files: `main.tf` — delete the comment block and `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` (`main.tf:285-295`).
- Resources affected: destroy `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` in staging (`sg-0e5a4b3c2d1f09876`) and prod (`sg-0c5a4b3c2d1f09876`). 0 add, 0 change, 1 destroy each. The rule has no bundle (no EIP, listener, DNS, volume).
- Blast radius: the snapshot set — `orders-db-<env>`, `orders-api-<env>`, `orders-worker-<env>` (+ its alarm), `orders-alb-<env>` + target group.
- Disruption: `UNVERIFIED` — expected loss of DB connectivity for the api, the worker and any batch job (`code: main.tf:287-303`; `live:` SG describe, ENI read). Mechanism not established (`docs:` lookup returned no canned output).
- Rollback: re-add the rule from git (`main.tf:287-294` at `origin/main`), plan and apply through the same path. Reversible (recreatable, new rule id), `untested`.
- Success criteria: SG describe shows no `10.20.0.0/16` and keeps the admin SG; `terraform plan -var-file=envs/<env>.tfvars` → No changes; RDS `available`; ECS running = desired with one deployment; every target `healthy`; S2 on the snapshot set after two 300 s periods.
- Execution path: direct apply. Staging-first (H7): staging, then prod. Observation window: none — operator choice at `[F2]` (the plan proposed 30 minutes).
- Branch: `iac-change/orders-remove-legacy-db-vpc-rule` from `origin/main` @ `a1b2c3d`. Self-check: 8/8 (disruption shown `UNVERIFIED`). Drift: none. Operator line: no reply (`operator (no objection at [F2], 10:54)`). Q8: (c) not available (operator, 10:54).

## Execution Log

### Phase 1: Remove the legacy VPC-wide ingress rule — staging
- Files changed: `main.tf` (11 lines removed: `main.tf:285-295`)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 0 to change, 1 to destroy
- Plan hash: `sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7`
- Parity check: n/a
- Pre-flight verdict: RED — soft block. Red: blast radius, dependency impact; multi-Yellow escalation (reversibility, observability, application compatibility ⚪). Acknowledged at `[H5]` (operator, 11:21): "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures". Mitigations committed: none. Execution approved at `[F4]` 11:26.
- Execution: `terraform apply tfplan` (staging, account 222222222222, 11:27) → `Apply complete! Resources: 0 added, 0 changed, 1 destroyed.`
- Verification: re-plan (11:28) → No changes. Success criteria: SG describe (11:29) → `cidrs: []`, `groups: [sg-0e9f8a7b6c5d4e3f2]` — pass; `terraform plan` → No changes — pass; RDS (11:41) → `available` — pass; ECS (11:39) → api 2/2, worker 2/2, one COMPLETED deployment each — pass; target health (11:40) → 2 of 2 `healthy` — pass. **fail (snapshot)**: `orders-alb-staging` target 5XX 0.20% → 3.1%, `orders-worker-staging` job error rate 0.50% → 23.2%, alarm `orders-worker-errors-staging` OK → ALARM.
- Snapshot: before 11:08–11:12 · after 11:37–11:41 · 17 ok / 3 regressed / 4 no data
- No `Snapshot override` line: the operator gave no reason at `[H10]` (11:46).

### Phase 1: Remove the legacy VPC-wide ingress rule — prod
- Files changed: none
- Self-check: plan 8/8 (shared with staging) · diff n/a
- Fresh eyes: n/a
- Plan output summary: not run
- Plan hash: n/a
- Parity check: not run
- Pre-flight verdict: not run
- Execution: not applied — run ended at `[H10]`: staging health regressed after the apply and the operator gave no reason to continue
- Verification: not run
- Snapshot: S0 only (before 10:34–10:46); no S1, no S2

## Health Snapshot

`Snapshot coverage: code + live reads (RDS, ECS, ALB, ENIs on the SG); not covered: the batch jobs named in the comment at main.tf:285-286 (no source in this repo), any other host in 10.20.0.0/16 (a caller through a CIDR rule shows up on no ENI of the SG), callers in other repos; no service-discovery catalog, no runtime profile.`

Members (source; label):
1. `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` on `orders-db-sg-<env>` — changed (`code: main.tf:287-294`; `plan:` destroy) — `n/a — no health signals of its own`
2. `orders-db-<env>` (RDS) — dependent (`code: main.tf:262`; `live:` `VpcSecurityGroups`)
3. `orders-api-<env>` (ECS) — dependent (`code: main.tf:42, 285-286`, `envs/*.tfvars:6-7`; `live:` task definition `DB_HOST`, ENI read)
4. `orders-worker-<env>` (ECS, with alarm `orders-worker-errors-<env>`) — dependent (`code: main.tf:70, 341-360`, `envs/*.tfvars:10-11`)
5. `orders-alb-<env>` + target group — front door of member 3 (`code: main.tf:104-108, 145-185`)
4 members get reads (cap 10). Over cap: none. Metrics backend: CloudWatch.

Commands (staging; prod's are the same with `-prod` names and `orders-cluster-prod`):
- R1 `aws rds describe-db-instances --db-instance-identifier orders-db-staging`
- R2 `aws ecs describe-services --cluster orders-cluster-staging --services orders-api-staging orders-worker-staging`
- R3 `aws elbv2 describe-target-health --target-group-arn <orders-api-tg-staging>`
- R4 `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm` (+ `--alarm-name-prefix orders` at 10:25 for the worker alarm's state)
- R5 `aws cloudwatch get-metric-data --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json` (S0 / S1: `Period` 3600, the hour ending now and the same hour a week earlier, hourly values aggregated by the runner from the canned five-minute values; S2: `Period` 300 from the apply)

### Staging — S0 (reads 10:16–10:27)

| Member | Signal | Before (now / same hour 1w ago) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-alb | requests | 24,130 (402/min) / 23,890 (398/min) | — | — | R5 | 10:27 |
| orders-alb | target 5XX | 48 = 0.20% / 47 = 0.20% | — | — | R5 | 10:27 |
| orders-alb | ELB 5XX | 0 / 0 | — | — | R5 | 10:27 |
| orders-alb | p95 latency | 0.180 s / 0.184 s | — | — | R5 | 10:27 |
| orders-alb | healthy / unhealthy hosts (min) | 2 / 0 (1w: 2 / 0) | — | — | R5 | 10:27 |
| orders-alb | target health | 2 of 2 healthy | — | — | R3 | 10:24 |
| orders-api | ready vs desired | 2/2, one COMPLETED deployment | — | — | R2 | 10:19 |
| orders-api | CPU / memory | 38.4% / 52.2% | — | — | R5 | 10:27 |
| orders-worker | ready vs desired | 2/2, one COMPLETED deployment | — | — | R2 | 10:19 |
| orders-worker | CPU / memory | 26.8% / 44.4% | — | — | R5 | 10:27 |
| orders-worker | jobs processed | 7,201 / 7,129 | — | — | R5 | 10:27 |
| orders-worker | job errors | 36 = 0.50% / 36 = 0.50% | — | — | R5 | 10:27 |
| orders-worker | alarm `orders-worker-errors-staging` | OK (not firing) | — | — | R4 | 10:25 / 10:26 |
| orders-db | status | available | — | — | R1 | 10:16 |
| orders-db | CPU | 21.7% / 22.1% | — | — | R5 | 10:27 |
| orders-db | connections avg / max | 38 / 46 (1w: 37 / 45) | — | — | R5 | 10:27 |
| orders-db | read latency, write latency, freeable memory, free storage (4 signals) | no data | — | no data | R5 | 10:27 |

### Staging — S1 (reads 11:08–11:12; the snapshot of 10:27 was 41 minutes old, so S1 was read again)

| Member | Signal | Before (now / same hour 1w ago) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-alb | requests | 24,130 (402/min) / 23,890 (398/min) | — | — | R5 | 11:09 |
| orders-alb | target 5XX | 48 = 0.20% / 47 = 0.20% | — | — | R5 | 11:09 |
| orders-alb | ELB 5XX | 0 / 0 | — | — | R5 | 11:09 |
| orders-alb | p95 latency | 0.180 s / 0.184 s | — | — | R5 | 11:09 |
| orders-alb | healthy / unhealthy hosts (min) | 2 / 0 | — | — | R5 | 11:09 |
| orders-alb | target health | 2 of 2 healthy | — | — | R3 | 11:11 |
| orders-api | ready vs desired | 2/2, one COMPLETED deployment | — | — | R2 | 11:10 |
| orders-api | CPU / memory | 38.4% / 52.2% | — | — | R5 | 11:09 |
| orders-worker | ready vs desired | 2/2, one COMPLETED deployment | — | — | R2 | 11:10 |
| orders-worker | CPU / memory | 26.8% / 44.4% | — | — | R5 | 11:09 |
| orders-worker | jobs processed | 7,201 / 7,129 | — | — | R5 | 11:09 |
| orders-worker | job errors | 36 = 0.50% / 36 = 0.50% | — | — | R5 | 11:09 |
| orders-worker | alarm `orders-worker-errors-staging` | not firing | — | — | R4 | 11:08 |
| orders-db | status | available | — | — | R1 | 11:12 |
| orders-db | CPU | 21.7% / 22.1% | — | — | R5 | 11:09 |
| orders-db | connections avg / max | 38 / 46 (1w: 37 / 45) | — | — | R5 | 11:09 |
| orders-db | read latency, write latency, freeable memory, free storage (4 signals) | no data | — | no data | R5 | 11:09 |

(Values equal S0's: the canned S0/S1 file is one file. It is its own table because it is its own read.)

### Staging — S2 (reads 11:37–11:41; two 300 s periods, 11:27–11:37, after the apply at 11:27; "before" = S1)

| Member | Signal | Before (S1) | After (S2) | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-alb | requests | 402/min | 400/min | ok | R5 | 11:38 |
| orders-alb | target 5XX rate | 48 / 24,130 = 0.20% | 124 / 4,000 = 3.1% (≥ 5 errors; 15.6× before) | **regressed** | R5 | 11:38 |
| orders-alb | ELB 5XX | 0 | 0 | ok | R5 | 11:38 |
| orders-alb | p95 latency | 0.180 s | 0.215 s (1.19×) | ok | R5 | 11:38 |
| orders-alb | healthy / unhealthy hosts (min) | 2 / 0 | 2 / 0 | ok | R5 | 11:38 |
| orders-alb | target health | 2 of 2 healthy | 2 of 2 healthy | ok | R3 | 11:40 |
| orders-api | ready vs desired | 2/2 | 2/2, one COMPLETED deployment | ok | R2 | 11:39 |
| orders-api | CPU / memory | 38.4% / 52.2% | 38.8% / 52.7% | ok | R5 | 11:38 |
| orders-worker | ready vs desired | 2/2 | 2/2, one COMPLETED deployment | ok | R2 | 11:39 |
| orders-worker | CPU / memory | 26.8% / 44.4% | 31.5% / 45.2% | ok | R5 | 11:38 |
| orders-worker | jobs processed | 120/min | 120/min | ok | R5 | 11:38 |
| orders-worker | job error rate | 36 / 7,201 = 0.50% | 279 / 1,202 = 23.2% (≥ 5 errors; 46× before) | **regressed** | R5 | 11:38 |
| orders-worker | alarm `orders-worker-errors-staging` | OK | ALARM since 11:37 (141 at 11:37, 138 at 11:32, threshold 20) | **regressed** | R4 | 11:37 |
| orders-db | status | available | available | ok | R1 | 11:41 |
| orders-db | CPU | 21.7% | 14.1% (below 21.7 ÷ 1.5 = 14.4) | improved | R5 | 11:38 |
| orders-db | connections avg / max | 38 / 46 | 30 / 36 | ok (`max_connections` not read: no saturation threshold applied) | R5 | 11:38 |
| orders-db | read latency, write latency, freeable memory, free storage (4 signals) | no data | no data | no data | R5 | 11:38 |

Snapshot: 17 ok · 3 regressed · 4 no data (improved counts as ok). Observed after the apply; the change is a suspect, not a proven cause.

### Prod — S0 only (reads 10:34–10:46)

| Member | Signal | Before (now / same hour 1w ago) | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-alb | requests | 108,130 (1,802/min) / 107,050 (1,784/min) | — | — | R5 | 10:45 |
| orders-alb | target 5XX | 217 = 0.20% / 215 = 0.20% | — | — | R5 | 10:45 |
| orders-alb | ELB 5XX | 0 / 0 | — | — | R5 | 10:45 |
| orders-alb | p95 latency | 0.183 s / 0.187 s | — | — | R5 | 10:45 |
| orders-alb | healthy / unhealthy hosts (min) | 4 / 0 | — | — | R5 | 10:45 |
| orders-alb | target health | 4 of 4 healthy | — | — | R3 | 10:42 |
| orders-api | ready vs desired | 4/4, one COMPLETED deployment | — | — | R2 | 10:37 |
| orders-api | CPU / memory | 41.4% / 55.2% | — | — | R5 | 10:45 |
| orders-worker | ready vs desired | 4/4, one COMPLETED deployment | — | — | R2 | 10:37 |
| orders-worker | CPU / memory | 29.4% / 47.2% | — | — | R5 | 10:45 |
| orders-worker | jobs processed | 36,000 / 35,640 | — | — | R5 | 10:45 |
| orders-worker | job errors | 180 = 0.50% / 180 = 0.50% | — | — | R5 | 10:45 |
| orders-worker | alarm `orders-worker-errors-prod` | OK (not firing) | — | — | R4 | 10:43 / 10:44 |
| orders-db | status | available | — | — | R1 | 10:34 |
| orders-db | CPU | 24.4% / 24.9% | — | — | R5 | 10:45 |
| orders-db | connections avg / max | 86 / 102 (1w: 84 / 100) | — | — | R5 | 10:45 |
| orders-db | read latency, write latency, freeable memory, free storage (4 signals) | no data | — | no data | R5 | 10:45 |

Prod S1 and S2: not taken (the run ended at `[H10]` before prod's 4a).

## Outcome
partially completed (phase 1 of 1: staging applied, prod not applied)

**Applied:** staging yes — not verified (success criteria pass: re-plan clean, SG rule gone, RDS `available`, ECS 2/2, targets healthy; but 3 signals `regressed`: `orders-alb-staging` target 5XX, `orders-worker-staging` job error rate, alarm `orders-worker-errors-staging`; no data: `orders-db-staging` read latency, write latency, freeable memory, free storage); prod no — not applied (run ended at `[H10]`: staging health regressed after the apply and the operator gave no reason to continue)

## Ticket Reference
none
