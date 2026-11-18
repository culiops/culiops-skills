**IaC change execution for:** `orders` / `none (single instance)`
**Change:** Remove the `10.20.0.0/16` ingress rule (`aws_vpc_security_group_ingress_rule.orders_db_from_vpc`) from the orders-db security group: staging first, then prod. Direct apply by hand from the operator's workstation, no PR.
**Date:** 2026-11-16 11:50 (+07:00)
**Commit:** `a1b2c3d` (`origin/main`, the base of branch `iac-change/orders-remove-db-vpc-ingress-rule`); the change itself is an uncommitted working-tree change (direct apply path)
**IaC tool(s):** terraform (aws provider `~> 5.0`, v5.74.0 locked)
**Execution path:** Direct apply
**Pre-flight record:** `.culiops/pre-flight/orders-remove-db-vpc-ingress-20261116-1122.md` — invoked inline — verdict: RED — soft block (staging; no matching record existed to reuse; prod not reached)
**Lane:** full — L1 fails: the plan shows a destroy (`plan: 0 to add, 0 to change, 1 to destroy`), and the targets are staging and prod, not proven dev (`lanes.md` › Lane rule, line 4)
**Escalations:** none
**Environment tier:** staging=staging (live: `aws sts get-caller-identity` 10:00 → account 222222222222 = `code: envs/staging.tfvars:3` and `providers.tf:14-16`)
**Environment tier:** prod=prod (live: `aws sts get-caller-identity` 10:01 → account 333333333333 = `code: envs/prod.tfvars:3` and `providers.tf:14-16`)
**Staging-first:** applied — staging 2026-11-16 11:32
**Waived:** none

## Research Summary
- Catalog used: none — proceeding without catalog (no `.culiops/service-discovery/orders.md`; no runtime-trace profile). Suggested: run service-discovery for orders.
- Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset). Workspace name `acme/orders-infra` (from `git remote get-url origin`, 10:02).
- Duplicate check: **not done** — `code: main.tf:287-294`, `main.tf:290`, `variables.tf:17`; `git log --all -S'10.20.0.0/16'` and `-S'orders_db_from_vpc'` empty (10:09, 10:10); `git branch -a --list '*orders*'` empty (10:11); `gh pr list --state open --search '10.20.0.0/16'` none (10:12). No ticket was given.
- Delivery model: applied by hand, direct apply — `operator-stated` (first message), consistent with `code:` no CI / Atlantis / TFC / Spacelift config in the repo (`providers.tf:1-10` has no backend or `cloud` block). Local workstation apply, not going through a pipeline: it raises the pre-flight risk (A4).
- Environment selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/*.tfvars`, `providers.tf:12-13`). Where each environment's state lives is not in the code (`UNVERIFIED`).
- Target: staging account 222222222222 / ap-southeast-1; prod account 333333333333 / ap-southeast-1, both `assumed-role/orders-operator`.
- Lane (predicted at Step 1, confirmed at 4a): full. No escalation checks needed (not a light-lane candidate).
- Operator profile read (`~/.culiops/operator.md`, 10:05): Q5 terraform = experienced, Q4 acme/orders-infra/orders = many times, both 2026-10-26; no incident command; nothing saved to it (nothing was asked that it lacked). Freeze source: none in the repo.
- L2 from evidence: `Q1(alarms)=no` (live 11:11), `Q3=no` (live 11:12, 1.01x the same hour last week), `iac-change.4=recent` (live 11:08, ECS deployment 2026-11-12); `Q1(declared)=no`, `Q2=no`, `Q7=none` — operator (no objection at `[F2]`, 10:55); `Q4`, `Q5` — operator (profile, 2026-10-26); `Q8=(c)` application source not available — operator (the only typed L2 item, asked at `[F2]`).
- App source: not found. `ls ..` listed `dotfiles` and `orders-infra` (this repo); `../dotfiles` origin is `git@github.com:acme/dotfiles.git`, not the app.
- Documentation lookups: two (what removing an ingress rule does to connections; whether re-adding restores it) — `no canned output`, so both claims stay `UNVERIFIED`.
- Fresh eyes (code): `not run — dry run`.
- Observation window: none, by operator choice at `[F2]` (the plan had proposed 30 minutes).

## Evidence
| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| The rule exists and admits `10.20.0.0/16` on tcp 5432 | `code: main.tf:287-294` | `live: aws ec2 describe-security-groups --group-ids sg-0e5a4b3c2d1f09876` (10:25): ingress 5432 from `10.20.0.0/16`; prod sg-0c5a4b3c2d1f09876 (10:38): same | ✅ |
| The only other ingress on the DB SG is the admin host's SG | `code: main.tf:296-303`, `code: envs/staging.tfvars:13` | same read: `UserIdGroupPairs` sg-0e9f8a7b6c5d4e3f2 (prod sg-0c9f8a7b6c5d4e3f2) | ✅ |
| The DB instance is attached to that SG | `code: main.tf:262` | `live: aws rds describe-db-instances` (10:24): `VpcSecurityGroups` sg-0e5a4b3c2d1f09876 (prod 10:37) | ✅ |
| Nothing else is attached to the SG | `code: main.tf:262,288,297` | `live: aws ec2 describe-network-interfaces` (10:26): 1 interface, `RDSNetworkInterface`; api and worker not attached (prod 10:39) | ✅ |
| The api and worker dial the DB through `DB_HOST` | `code: main.tf:42,70` | `live: aws ecs describe-task-definition` (10:22, 10:23): env names include `DB_HOST` (prod 10:35, 10:36) | ✅ |
| The api and worker run inside `10.20.0.0/16` | `code: envs/staging.tfvars:6-11`, `code: variables.tf:17` | `live: aws ecs describe-services` (10:21): task subnets = the var-file ids | ✅ |
| Neither the api's nor the worker's SG is a source on the DB SG | `code: main.tf:200-243`, `code: main.tf:296-303` | same SG read (10:25): no api / worker group in `UserIdGroupPairs`; task SGs sg-0e6b5c4d3e2f10987 / sg-0e7c6d5e4f3a21098 (10:21) | ✅ — so the CIDR rule is how they are admitted (inferred) |
| Clients are connected through the rules today | n/a | `live: get-metric-data` (10:32): `DatabaseConnections` avg 38, max 46 (prod 85.8 / 102) | inferred: connection sources not visible |
| Batch jobs and other hosts rely on the rule | `code: main.tf:285-286` (comment: data, Constraint 12) | none readable | `UNVERIFIED` — callers outside this repo not covered |
| Alarm `orders-worker-errors-staging` exists, enabled | `code: main.tf:341` | `live: aws cloudwatch describe-alarms --alarm-name-prefix orders` (10:30): enabled, `OK` | ✅ |
| No drift | `code: main.tf` | `live: terraform plan -refresh-only` (10:33 staging, 10:46 prod): No changes | ✅ |
| Where each environment's state lives | `code: providers.tf:1-10` has no backend block | not read | `UNVERIFIED` |
| What removing the rule does to existing and new connections | n/a | n/a | `UNVERIFIED` — `docs:` lookup (10:47) returned no canned output |

Drift rows: 0. Unverified rows: 3. Code-only rows: 0.

## Change Plan
**Phase 1 of 1: remove the legacy VPC-wide CIDR rule from the database security group** (staging, then prod)
- Files: `main.tf` (delete lines 285-295: the 2 comment lines, the resource `aws_vpc_security_group_ingress_rule.orders_db_from_vpc`, the blank line after it). No var-file change.
- Resources affected: destroy `aws_vpc_security_group_ingress_rule.orders_db_from_vpc`, 1 per environment (0 to add, 0 to change, 1 to destroy).
- Blast radius: the snapshot set: `orders-db-<env>`, `orders-api-<env>`, `orders-worker-<env>` (+ alarm `orders-worker-errors-<env>`), `orders-alb-<env>`; the rule and its SG `n/a — no health signals of their own`. `Snapshot coverage: code (main.tf, var-files) + live reads (ENIs on the DB security group, ECS task-definition variable names); not covered: the batch jobs and any other VPC host that connects through the rule, no catalog, no runtime-trace profile.`
- Disruption: `UNVERIFIED` — expected: new connections from orders-api and orders-worker to the database on 5432 are refused once the rule is gone (the rule is the only one that admits their addresses: `code: main.tf:296-303`, `live:` SG describe 10:25, ENI read 10:26; their subnets are inside the CIDR, `code: envs/staging.tfvars:6-11`). Behaviour of established connections: `UNVERIFIED` (docs lookup returned no canned output). Not `none`.
- Rollback path: re-add the resource block (revert the diff), then plan and apply per environment. Expected reversible (a rule holds no data), `untested`, claim `UNVERIFIED`. The effect above holds until the restore.
- Success criteria: (1) `aws ec2 describe-security-groups --group-ids <DB SG id>` → no `10.20.0.0/16`, only the admin host's group; (2) `terraform plan -var-file=envs/<env>.tfvars` → `No changes`; (3) `aws rds describe-db-instances --db-instance-identifier orders-db-<env> --query 'DBInstances[].DBInstanceStatus'` → `available`; (4) `aws ecs describe-services --cluster orders-cluster-<env> --services orders-api-<env> orders-worker-<env>` → running = desired; plus S2 on the snapshot set after two 5-minute periods.
- Execution path: direct apply (operator's request). Staging-first (H7): staging, then prod, each with its own `[F4]`. Observation window: none (operator choice at `[F2]`; proposed 30 minutes). Branch: `iac-change/orders-remove-db-vpc-ingress-rule` from `origin/main` @ `a1b2c3d`.
- Plan self-check: 8/8 pass (disruption and rollback class named `UNVERIFIED` under item 1). Drift (H4): none.

## Execution Log
### Phase 1: remove the legacy VPC-wide CIDR rule — staging
- Files changed: `main.tf` (lines 285-295 deleted; uncommitted; branch `iac-change/orders-remove-db-vpc-ingress-rule`)
- Self-check: plan 8/8 · diff 6/6, no accepted failures
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 0 to change, 1 to destroy (`aws_vpc_security_group_ingress_rule.orders_db_from_vpc`; `terraform plan -out=tfplan -var-file=envs/staging.tfvars`, 11:07)
- Plan hash: `sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7`
- Parity check: n/a
- Pre-flight verdict: RED — soft block. Red 1 (blast radius) and 4 (dependency impact) acknowledged at `[H5]` 11:22, operator: "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures". Yellow / ⚪ 2 (reversibility), 7 (observability), 9 (security posture), 11 (application compatibility) acknowledged at `[F4]` 11:27. Mitigations committed: none.
- Execution: `terraform apply tfplan` against account 222222222222 / ap-southeast-1 / `envs/staging.tfvars`, approved at `[F4]` 11:27, run 11:32: `Destruction complete after 1s` · `Apply complete! Resources: 0 added, 0 changed, 1 destroyed.`
- Verification: re-plan (11:33) `No changes. Your infrastructure matches the configuration.`; (1) `aws ec2 describe-security-groups --group-ids sg-0e5a4b3c2d1f09876` (11:34) → ranges `[]`, groups `[sg-0e9f8a7b6c5d4e3f2]` — pass; (2) `aws rds describe-db-instances … DBInstanceStatus` (11:35) → `available` — pass; (3) `aws ecs describe-services …` (11:36) → orders-api-staging 2/2, orders-worker-staging 2/2 — pass; **`fail (snapshot)`**: 3 regressed signals (S2 below)
- Snapshot: before 11:31 · after 11:42 · 17 ok / 3 regressed / 4 no data (counted per member-signal row; regressed members: `orders-worker-staging`, `orders-alb-staging`)
- `[H10]` at 11:45: the operator replied "I don't know why — stop here." (no reason), so the run ended `partially completed`. There is no `Snapshot override:` line.

### Phase 1: remove the legacy VPC-wide CIDR rule — prod
- Files changed: none (not reached)
- Self-check: not reached (the plan self-check 8/8 and the diff self-check 6/6 cover the shared change)
- Fresh eyes: not run — dry run
- Plan output summary: not run
- Plan hash: not computed
- Parity check: n/a — not reached
- Pre-flight verdict: not run
- Execution: not applied — staging's health regressed after its apply (`orders-worker-staging`, `orders-alb-staging`) and the operator gave no reason at `[H10]` 11:50, so prod's plan, S1, pre-flight, `[F4]`, apply and S2 did not run (`snapshot.md` › After a regression).
- Verification: not run
- Snapshot: prod S0 only (10:34-10:45, hour ending 10:45); no S1 or S2 taken

## Health Snapshot
`Snapshot coverage: code (main.tf, var-files) + live reads (ENIs on the DB security group, ECS task-definition variable names); not covered: the batch jobs and any other VPC host that connects through the rule, no catalog, no runtime-trace profile.`

Members (4 with reads per environment, cap 10, none over the cap; the changed resource has no health signals of its own):
- `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` — the changed resource: `n/a — no health signals of its own` (also its SG `aws_security_group.orders_db`)
- `aws_db_instance.orders` (`orders-db-<env>`) — attached to the SG: `code: main.tf:262`; live ENI read
- `aws_ecs_service.orders_api` (`orders-api-<env>`) — dials the DB (`DB_HOST`), inside the CIDR: `code: main.tf:42`, `code: envs/<env>.tfvars:6-7`
- `aws_ecs_service.orders_worker` (`orders-worker-<env>`), with job metrics and alarm `orders-worker-errors-<env>` — same: `code: main.tf:70`, `code: envs/<env>.tfvars:10-11`, `code: main.tf:317,329,341`
- `aws_lb.orders` (`orders-alb-<env>`) and its target group — front door of the api: `code: main.tf:145,158`

Legend: `[M]` = `aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-<env>.json …` (S0 and S1: `Period` 3600, hour ending the read time and the same hour a week earlier, hourly values derived from the canned 5-minute values; S2: `Period` 300, `--start-time` apply time `--end-time` read time); `[R]` = `aws rds describe-db-instances --db-instance-identifier orders-db-<env> --query 'DBInstances[].DBInstanceStatus'`; `[E]` = `aws ecs describe-services --cluster orders-cluster-<env> --services orders-api-<env> orders-worker-<env>`; `[A]` = `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1`; `[T]` = `aws elbv2 describe-target-health --target-group-arn <tg-arn>`. Four RDS series (`ReadLatency`, `WriteLatency`, `FreeableMemory`, `FreeStorageSpace`) return no datapoint in any read.

### staging — S0 (with the `[F1]` batch, reads 10:21-10:32)
| Member | Signal | Hour ending 10:32 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 22.05% | [M] | 10:32 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 37 | [M] | 10:32 |
| orders-db-staging | DatabaseConnections (max) | 46 | 45 | [M] | 10:32 |
| orders-db-staging | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | status (point-in-time) | available | n/a | [R] | 10:24 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | not read (no 1w series) | [M] | 10:32 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | not read (no 1w series) | [M] | 10:32 |
| orders-api-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 10:21 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | not read (no 1w series) | [M] | 10:32 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | not read (no 1w series) | [M] | 10:32 |
| orders-worker-staging | JobsProcessed (traffic, sum) | 7,201 | 7,129 | [M] | 10:32 |
| orders-worker-staging | JobErrors (sum) | 36 (0.500% of jobs) | 36 (0.505%) | [M] | 10:32 |
| orders-worker-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 10:21 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (0 firing on the set) | n/a | [A] | 10:31 |
| orders-alb-staging | RequestCount (sum) | 24,130 | 23,890 | [M] | 10:32 |
| orders-alb-staging | HTTPCode_Target_5XX_Count (sum) | 48 (0.199% of requests) | 47 (0.197%) | [M] | 10:32 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 10:32 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.184 s | [M] | 10:32 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | [M] | 10:32 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | [M] | 10:32 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | n/a | [T] | 10:29 |
### staging — S1 (first read, 11:08-11:12; the S0 was 36 minutes old)
| Member | Signal | Hour ending 11:12 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 22.05% | [M] | 11:12 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 37 | [M] | 11:12 |
| orders-db-staging | DatabaseConnections (max) | 46 | 45 | [M] | 11:12 |
| orders-db-staging | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | status (point-in-time) | available | n/a | [R] | 11:09 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | not read (no 1w series) | [M] | 11:12 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | not read (no 1w series) | [M] | 11:12 |
| orders-api-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:08 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | not read (no 1w series) | [M] | 11:12 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | not read (no 1w series) | [M] | 11:12 |
| orders-worker-staging | JobsProcessed (traffic, sum) | 7,201 | 7,129 | [M] | 11:12 |
| orders-worker-staging | JobErrors (sum) | 36 (0.500% of jobs) | 36 (0.505%) | [M] | 11:12 |
| orders-worker-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:08 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (0 firing on the set) | n/a | [A] | 11:11 |
| orders-alb-staging | RequestCount (sum) | 24,130 | 23,890 | [M] | 11:12 |
| orders-alb-staging | HTTPCode_Target_5XX_Count (sum) | 48 (0.199% of requests) | 47 (0.197%) | [M] | 11:12 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 11:12 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.184 s | [M] | 11:12 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | [M] | 11:12 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | [M] | 11:12 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | n/a | [T] | 11:10 |
### staging — S1 re-read just before the apply (11:27-11:31; the `[F4]` reply came 19 minutes after the first S1's oldest read)
| Member | Signal | Hour ending 11:31 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 22.05% | [M] | 11:31 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 37 | [M] | 11:31 |
| orders-db-staging | DatabaseConnections (max) | 46 | 45 | [M] | 11:31 |
| orders-db-staging | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | status (point-in-time) | available | n/a | [R] | 11:28 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | not read (no 1w series) | [M] | 11:31 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | not read (no 1w series) | [M] | 11:31 |
| orders-api-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:27 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | not read (no 1w series) | [M] | 11:31 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | not read (no 1w series) | [M] | 11:31 |
| orders-worker-staging | JobsProcessed (traffic, sum) | 7,201 | 7,129 | [M] | 11:31 |
| orders-worker-staging | JobErrors (sum) | 36 (0.500% of jobs) | 36 (0.505%) | [M] | 11:31 |
| orders-worker-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:27 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (0 firing on the set) | n/a | [A] | 11:30 |
| orders-alb-staging | RequestCount (sum) | 24,130 | 23,890 | [M] | 11:31 |
| orders-alb-staging | HTTPCode_Target_5XX_Count (sum) | 48 (0.199% of requests) | 47 (0.197%) | [M] | 11:31 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 11:31 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.184 s | [M] | 11:31 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | [M] | 11:31 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | [M] | 11:31 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | n/a | [T] | 11:29 |
### staging — S2 (after the apply at 11:32; ready at 11:42, two 5-minute periods)
| Member | Signal | Before (S1, re-read 11:27–11:31) | After (S2, 11:32–11:42) | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 14.10% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 30 | ok (fewer connections; no max_connections value read, so no saturation test) | [M] | 11:42 |
| orders-db-staging | DatabaseConnections (max) | 46 | 36 | ok (fewer connections; no max_connections value read, so no saturation test) | [M] | 11:42 |
| orders-db-staging | ReadLatency (avg) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | WriteLatency (avg) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | FreeableMemory (min) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | FreeStorageSpace (min) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | status (point-in-time) | available | available | ok | [R] | 11:35 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | 38.75% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | 52.65% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-api-staging | running vs desired | 2/2 | 2/2 | ok | [E] | 11:36 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | 31.50% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | 45.15% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-worker-staging | JobsProcessed per minute | 120.0/min | 120.2/min | ok (traffic, no threshold; low-volume floor 100 met) | [M] | 11:42 |
| orders-worker-staging | job error rate (JobErrors / JobsProcessed) | 36 / 7,201 = 0.500% | 279 / 1,202 = 23.21% | regressed (> 1.5x before = 0.750%; 279 errors >= 5) | [M] | 11:42 |
| orders-worker-staging | running vs desired | 2/2 | 2/2 | ok | [E] | 11:36 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (not firing, S1 11:30) | ALARM (StateUpdated 11:42) | regressed (firing after, not before) | [A] | 11:43 |
| orders-alb-staging | RequestCount per minute | 402.2/min | 400.0/min | ok (traffic, no threshold; low-volume floor 100 met) | [M] | 11:42 |
| orders-alb-staging | target 5XX rate (errors / requests) | 48 / 24,130 = 0.199% | 124 / 4,000 = 3.10% | regressed (> 1.5x before = 0.298%; 124 errors >= 5) | [M] | 11:42 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | ok (0 errors; floor of 5 not met) | [M] | 11:42 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.215 s | ok (1.19x, threshold 1.5x) | [M] | 11:42 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | ok (unchanged; no expected value differs) | [M] | 11:42 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | ok (unchanged; no expected value differs) | [M] | 11:42 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | 2/2 healthy | ok | [T] | 11:44 |

### prod — S0 (with the `[F1]` batch, reads 10:34-10:45)
| Member | Signal | Hour ending 10:45 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-prod | CPUUtilization (avg) | 24.35% | 24.85% | [M] | 10:45 |
| orders-db-prod | DatabaseConnections (avg) | 85.83 | 83.83 | [M] | 10:45 |
| orders-db-prod | DatabaseConnections (max) | 102 | 100 | [M] | 10:45 |
| orders-db-prod | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | status (point-in-time) | available | n/a | [R] | 10:37 |
| orders-api-prod | CPUUtilization (avg) | 41.35% | not read (no 1w series) | [M] | 10:45 |
| orders-api-prod | MemoryUtilization (avg) | 55.18% | not read (no 1w series) | [M] | 10:45 |
| orders-api-prod | running vs desired (point-in-time) | 4/4, deployment COMPLETED | n/a | [E] | 10:34 |
| orders-worker-prod | CPUUtilization (avg) | 29.35% | not read (no 1w series) | [M] | 10:45 |
| orders-worker-prod | MemoryUtilization (avg) | 47.24% | not read (no 1w series) | [M] | 10:45 |
| orders-worker-prod | JobsProcessed (traffic, sum) | 36,000 | 35,640 | [M] | 10:45 |
| orders-worker-prod | JobErrors (sum) | 180 (0.500% of jobs) | 180 (0.505%) | [M] | 10:45 |
| orders-worker-prod | running vs desired (point-in-time) | 4/4, deployment COMPLETED | n/a | [E] | 10:34 |
| orders-worker-prod | alarm orders-worker-errors-prod | OK (0 firing on the set) | n/a | [A] | 10:44 |
| orders-alb-prod | RequestCount (sum) | 108,130 | 107,050 | [M] | 10:45 |
| orders-alb-prod | HTTPCode_Target_5XX_Count (sum) | 217 (0.201% of requests) | 215 (0.201%) | [M] | 10:45 |
| orders-alb-prod | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 10:45 |
| orders-alb-prod | TargetResponseTime (p95) | 0.183 s | 0.187 s | [M] | 10:45 |
| orders-alb-prod | HealthyHostCount (min) | 4 | 4 | [M] | 10:45 |
| orders-alb-prod | UnHealthyHostCount (min) | 0 | 0 | [M] | 10:45 |
| orders-alb-prod | target health (point-in-time) | 4/4 healthy | n/a | [T] | 10:42 |

Prod has no S1 and no S2: the run ended at `[H10]` before prod's turn.

## Outcome
partially completed (phase 1 of 1: staging applied but not verified; prod not applied — the run ended at `[H10]`)

**Applied:** staging yes — not verified (regressed members: `orders-worker-staging`, `orders-alb-staging`; no data: `orders-db-staging` ReadLatency, WriteLatency, FreeableMemory, FreeStorageSpace); prod no — not applied (ended at `[H10]` after staging's regression)

## Ticket Reference
none
