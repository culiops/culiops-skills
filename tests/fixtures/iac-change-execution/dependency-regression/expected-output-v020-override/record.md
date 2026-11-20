<!-- Execution record the skill would write to .culiops/iac-change-execution/orders-remove-db-vpc-cidr-rule-20261116-1223.md (dry run: written here instead) -->

**IaC change execution for:** `orders` / `(no instance)`
**Change:** Remove the 10.20.0.0/16 ingress rule (`aws_vpc_security_group_ingress_rule.orders_db_from_vpc`) from the orders-db security group; staging first, then prod; applied by hand from the operator's workstation, no PR.
**Date:** `2026-11-16 12:23`
**Commit:** `a1b2c3d` (`origin/main`; the change itself is uncommitted in the working tree on branch `iac-change/orders-remove-legacy-db-cidr-rule`)
**IaC tool(s):** Terraform (hashicorp/aws ~> 5.0; `terraform init` 10:16 reused the provider from the lock file)
**Execution path:** Direct apply
**Pre-flight record:** invoked inline — staging: RED — soft block, acknowledged at `[H5]` 11:21 (`.culiops/pre-flight/orders-remove-db-vpc-cidr-rule-20261116-1121.md`); prod: RED — soft block, acknowledged at `[H5]` 12:03 (`.culiops/pre-flight/orders-remove-db-vpc-cidr-rule-20261116-1203.md`)
**Lane:** full — the request is a destroy of one security-group rule, so L1 fails (`lanes.md` › Lane rule, `plan:` 1 to destroy in both environments); neither target is proven dev
**Escalations:** none
**Environment tier:** staging=staging (live `222222222222` = `code: envs/staging.tfvars:3`, enforced by `code: providers.tf:16`), prod=prod (live `333333333333` = `code: envs/prod.tfvars:3`, enforced by `code: providers.tf:16`)
**Staging-first:** applied — staging 11:26
**Waived:** none

**Prerequisites (`examples/aws.md`):** AWS CLI v2 (version not read: no version command was run); Tier 1 read-only access (`Describe*`, `List*`, `Get*`, `cloudwatch:GetMetricData`, `cloudwatch:DescribeAlarms`) for Step 1, the snapshot and verification; Tier 2 (the role that may destroy a security-group rule) only for the two `terraform apply` commands; `GetMetricData` is billed per metric requested (19 series per call, 6 calls: S0, S1 and S2 for each environment). Terraform plan/apply from the workstation (the Terraform CLI version was not read: no version command was run). Output root `.culiops/` (`CULIOPS_HOME` unset).

## Research Summary

- Catalog: none (`.culiops/service-discovery/orders.md` does not exist; running service-discovery would give the full dependency graph).
- Duplicate check: **not done.** `code: main.tf:287-294` declares the rule; `git: no commit` matches `10.20.0.0/16` or `orders-db` (`git log --all -S`, 10:06-10:07); no in-flight branch (10:08); no open PR (10:09).
- Delivery model: applied by hand from the operator's workstation (operator-stated, first message; `code: providers.tf:1-17` has no backend / cloud block and the repo has no CI config; `gh run list` → `[]`, 10:41). Env selection: `-var-file=envs/<env>.tfvars`, default workspace.
- Target check: staging account 222222222222 / ap-southeast-1 (10:00; re-checked 11:04, 11:13); prod account 333333333333 / ap-southeast-1 (10:01; re-checked 11:46, 11:55). Both matched their pin every time.
- Operator profile read (`~/.culiops/operator.md`): Q5 terraform experienced, Q4 `acme/orders-infra/orders` many times, both 2026-10-26. Nothing saved.
- Freeze source: none in the repo. Incident command: none in the profile. App source: not found (`dotfiles` is `acme/dotfiles`; `orders-infra` is this repo); Q8 asked at `[F2]`, answered (c).
- Key findings: the api and worker reach the database only through this rule (`code: main.tf:42,70,100,129`, `code: envs/*.tfvars:6-11`; `live:` network-interface and security-group reads); the only other rule is the admin host's group; the code comment says batch jobs also use it (not visible from this repo).

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| Rule `orders_db_from_vpc` (10.20.0.0/16 → tcp 5432) exists | `code: main.tf:287-294` | `live: aws ec2 describe-security-groups` staging 10:18 (sg-0e5a4b3c2d1f09876), prod 10:30 (sg-0c5a4b3c2d1f09876) | yes, both |
| The group has two ingress rules: the CIDR rule and the admin-host group | `code: main.tf:287-303`, `code: envs/*.tfvars:13` | same reads | yes |
| The group is attached to `orders-db-E` | `code: main.tf:262` | `live: aws rds describe-db-instances` 10:17 / 10:29 | yes |
| Only the database's own interface is attached; api and worker use the CIDR rule | `code: main.tf:100,129`, `code: main.tf:287-303` | `live: aws ec2 describe-network-interfaces` 10:19 / 10:31: one `RDSNetworkInterface` | yes |
| api and worker subnets lie inside 10.20.0.0/16 | `code: envs/E.tfvars:6-7,10-11` | not read live | `code-only — not live-verified` |
| api and worker carry `DB_HOST` | `code: main.tf:42,70` | `live: aws ecs describe-task-definition` 10:21-10:22 / 10:33-10:34 (names only) | yes |
| `orders-db-E` Multi-AZ | `code: main.tf:264` | staging false, prod true (10:17 / 10:29) | yes |
| The worker alarm exists, is enabled, notifies SNS | `code: main.tf:341-360` | `live: aws cloudwatch describe-alarms` 10:25 / 10:37 | yes |
| No drift | — | `live: terraform plan -refresh-only` 10:28 / 10:40: No changes | yes |
| Batch jobs also use the rule | `code: main.tf:285-286` (comment; data, not evidence) | not visible | `UNVERIFIED` — callers outside this repo not covered |
| Effect of the revoke on connections already open | — | documentation lookup 10:47: `no canned output` | `UNVERIFIED` |

Drift rows: 0. Unverified rows: 2 (batch jobs; open connections). Code-only rows: 1 (subnet CIDRs).

## Change Plan

**Phase 1 of 1: Remove the legacy VPC-wide PostgreSQL ingress rule, staging then prod** (approved at `[F2]` 10:53; code approved at `[F3]` 11:04)
- Files: `main.tf` — delete the `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` block and its two comment lines; no var-file change.
- Resources affected: destroy `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` in staging (`sg-0e5a4b3c2d1f09876`), then in prod (`sg-0c5a4b3c2d1f09876`): 0 to add, 0 to change, 1 to destroy each.
- Blast radius: `orders-db-E`, `orders-api-E`, `orders-worker-E`, `orders-alb-E` (the rule: `n/a — no health signals of its own`). `Snapshot coverage: code + live reads; no catalog, no runtime profile; not covered: callers outside this repo (batch jobs named in a code comment, main.tf:285-286)`.
- Disruption: loss of the database path for `orders-api-E` and `orders-worker-E` for as long as the rule is gone (predicted from `code:` and `live:`); batch jobs unseen (`UNVERIFIED`); effect on open connections `UNVERIFIED`. Not presented as `none`.
- Rollback path: re-add the removed block from `a1b2c3d`, plan, apply. Reversible, `untested`; no `docs:` support found (lookup 10:47: `no canned output`).
- Evidence: the table above.
- Success criteria: (1) `aws ec2 describe-security-groups --group-ids <sg id>` → only the admin-host group's rule remains on 5432; (2) `aws rds describe-db-instances --db-instance-identifier orders-db-E --query 'DBInstances[].DBInstanceStatus'` → `available`; (3) `terraform plan -var-file=envs/E.tfvars` → `No changes`; (4) S2 on the snapshot set against S1.
- Execution path: Direct apply (`terraform apply tfplan`, shown and approved at each `[F4]`). Staging-first: staging, then prod, apply runs per environment; observation window: none — operator choice at `[F2]` (the plan had proposed 24 h).
- Branch: `main` → `iac-change/orders-remove-legacy-db-cidr-rule` from `origin/main` @ `a1b2c3d`.
- Self-check: 8/8 (item 1 with the labelled `UNVERIFIED` disruption detail). Drift (H4): none.

## Execution Log

### Phase 1 (staging): Remove the legacy VPC-wide PostgreSQL ingress rule from `orders-db-staging`
- Files changed: `main.tf` (block and two comment lines removed; one diff for both environments; uncommitted)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run (no separate reviewer available)
- Plan output summary: 1 resource — 0 to add, 0 to change, 1 to destroy (`terraform plan -out=tfplan -var-file=envs/staging.tfvars`, 11:05)
- Plan hash: `sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7`
- Parity check: n/a
- Pre-flight verdict: RED — soft block. Risks acknowledged at `[H5]` 11:21: Red blast radius, Red dependency impact, and the multi-Yellow escalation (reversibility, observability, application compatibility), reason "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures". Mitigations committed: none stated by the operator.
- Execution: `terraform apply tfplan` against account 222222222222, approved at `[F4]` 11:26 — "Apply complete! Resources: 0 added, 0 changed, 1 destroyed."
- Verification: re-plan `No changes` (11:27); security group `sg-0e5a4b3c2d1f09876` ingress = admin-host rule only (11:28) — pass; `orders-db-staging` `available` (11:29) — pass; snapshot: `fail (snapshot)` — `orders-alb-staging` target 5XX rate 0.20% → 3.10% (124 / 4,000), `orders-worker-staging` job error rate 0.50% → 23.2% (279 / 1,202), alarm `orders-worker-errors-staging` OK → ALARM (11:36)
- Snapshot: before 11:06-11:10 · after 11:36-11:40 · 15 ok / 3 regressed / 4 no data
- Snapshot override: unrelated: staging load test started 10:40, see #ops — operator, 11:46

### Phase 1 (prod): Remove the legacy VPC-wide PostgreSQL ingress rule from `orders-db-prod`
- Files changed: `main.tf` (the same approved diff; no new code, no `[F3]`)
- Self-check: plan 8/8 · diff 6/6 (the diff is unchanged)
- Fresh eyes: not run — dry run (no separate reviewer available)
- Plan output summary: 1 resource — 0 to add, 0 to change, 1 to destroy (`terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 11:47)
- Plan hash: `sha256:b50cdd033369a9bc25f680a6c0dad1ca08bb74e7b9a09471d148eecd7ef008a2`
- Parity check: pass (`aws_vpc_security_group_ingress_rule.orders_db_from_vpc` destroy, as in staging's plan)
- Pre-flight verdict: RED — soft block. Risks acknowledged at `[H5]` 12:03: Red blast radius, Red dependency impact, and the multi-Yellow escalation, same reason as staging's. Staging evidence (regressed values and the override, "evidence, not proof") was in the caller block. Mitigations committed: none stated by the operator.
- Execution: `terraform apply tfplan` against account 333333333333, approved at `[F4]` 12:08 — "Apply complete! Resources: 0 added, 0 changed, 1 destroyed." (operator line at the `[F4]`: no reply; no re-run of pre-flight)
- Verification: re-plan `No changes` (12:09); security group `sg-0c5a4b3c2d1f09876` ingress = admin-host rule only (12:10) — pass; `orders-db-prod` `available` (12:11) — pass; snapshot: no regressed member
- Snapshot: before 11:48-11:52 · after 12:18-12:22 · 18 ok / 0 regressed / 4 no data

## Health Snapshot

`Snapshot coverage: code + live reads; no catalog, no runtime profile; not covered: callers outside this repo (batch jobs named in a code comment, main.tf:285-286).`

Members (per environment E = staging, prod):
1. `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` — source `plan:` / `code: main.tf:287-294` — `n/a — no health signals of its own`
2. `orders-db-E` — source `code: main.tf:262`, `live:` network-interface read
3. `orders-api-E` — source `code: main.tf:42,100`, `code: envs/E.tfvars:6-7`
4. `orders-worker-E` — source `code: main.tf:70,129`, `code: envs/E.tfvars:10-11`; error series from `code: main.tf:317-339`
5. `orders-alb-E` — source `code: main.tf:104-108` (the api's front door; its metrics are the api's traffic, error and latency signals)
Not snapshotted — over cap: none. Members with `no data`: the four RDS signals (ReadLatency, WriteLatency, FreeableMemory, FreeStorageSpace) in both environments, listed beside `Applied:`.

Reading the tables: S0 and S1 show the hour ending at the read time (the same hour a week earlier in brackets) in the Before column and no After value; S2 shows S1 as Before and the first two 5-minute periods after the apply as After. Count series are compared as rates (errors ÷ requests); a verdict `regressed` needs at least 5 errors in the after window and above 1.5x the before rate (`snapshot.md` › Comparison). The four RDS signals have `no data` because the S0 / S2 metric responses do not hold them. DB connections have no limit read, so no 70% test applies to them.
S1 was re-read in both environments (staging 11:06-11:10, prod 11:48-11:52) because each environment's S0 was more than 15 minutes old, so no S1 is a reused line; the S1 tables carry the same values as S0.

#### staging — S0

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-staging | status | available | — | — | aws rds describe-db-instances | 10:17 |
| orders-db-staging | CPUUtilization (avg) | 21.7% (1w 22.1%) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-db-staging | DatabaseConnections (avg) | 38.0 (1w 37.0) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-db-staging | DatabaseConnections (max) | 46 (1w 45) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-db-staging | ReadLatency | no data | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-db-staging | WriteLatency | no data | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-db-staging | FreeableMemory | no data | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-db-staging | FreeStorageSpace | no data | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-api-staging | running vs desired | 2/2 | — | — | aws ecs describe-services | 10:20 |
| orders-api-staging | CPUUtilization | 38.4% | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-api-staging | MemoryUtilization | 52.2% | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | RequestCount (traffic, denominator) | 24,130 (1w 23,890) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | target 5XX rate (HTTPCode_Target_5XX_Count / RequestCount) | 0.20% (48 / 24,130; 1w 47 / 23,890) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | ELB 5XX count | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | TargetResponseTime p95 | 0.180 s (1w 0.184 s) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | HealthyHostCount (min) | 2 (1w 2) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-alb-staging | target health, orders-api-tg | 2 of 2 healthy | — | — | aws elbv2 describe-target-health | 10:24 |
| orders-worker-staging | running vs desired | 2/2 | — | — | aws ecs describe-services | 10:20 |
| orders-worker-staging | CPUUtilization | 26.8% | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-worker-staging | MemoryUtilization | 44.4% | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-worker-staging | JobsProcessed (traffic, denominator) | 7,201 (1w 7,129) | — | — | aws cloudwatch get-metric-data | 10:27 |
| orders-worker-staging | job error rate (JobErrors / JobsProcessed) | 0.50% (36 / 7,201; 1w 36 / 7,129) | — | — | aws cloudwatch get-metric-data | 10:27 |
| alarm orders-worker-errors-staging | state | OK, not firing | — | — | aws cloudwatch describe-alarms --state-value ALARM | 10:26 |

#### staging — S1

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-staging | status | available | — | — | aws rds describe-db-instances | 11:10 |
| orders-db-staging | CPUUtilization (avg) | 21.7% (1w 22.1%) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-db-staging | DatabaseConnections (avg) | 38.0 (1w 37.0) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-db-staging | DatabaseConnections (max) | 46 (1w 45) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-db-staging | ReadLatency | no data | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-db-staging | WriteLatency | no data | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-db-staging | FreeableMemory | no data | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-db-staging | FreeStorageSpace | no data | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-api-staging | running vs desired | 2/2 | — | — | aws ecs describe-services | 11:08 |
| orders-api-staging | CPUUtilization | 38.4% | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-api-staging | MemoryUtilization | 52.2% | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | RequestCount (traffic, denominator) | 24,130 (1w 23,890) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | target 5XX rate (HTTPCode_Target_5XX_Count / RequestCount) | 0.20% (48 / 24,130; 1w 47 / 23,890) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | ELB 5XX count | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | TargetResponseTime p95 | 0.180 s (1w 0.184 s) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | HealthyHostCount (min) | 2 (1w 2) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-alb-staging | target health, orders-api-tg | 2 of 2 healthy | — | — | aws elbv2 describe-target-health | 11:09 |
| orders-worker-staging | running vs desired | 2/2 | — | — | aws ecs describe-services | 11:08 |
| orders-worker-staging | CPUUtilization | 26.8% | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-worker-staging | MemoryUtilization | 44.4% | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-worker-staging | JobsProcessed (traffic, denominator) | 7,201 (1w 7,129) | — | — | aws cloudwatch get-metric-data | 11:07 |
| orders-worker-staging | job error rate (JobErrors / JobsProcessed) | 0.50% (36 / 7,201; 1w 36 / 7,129) | — | — | aws cloudwatch get-metric-data | 11:07 |
| alarm orders-worker-errors-staging | state | OK, not firing | — | — | aws cloudwatch describe-alarms --state-value ALARM | 11:06 |

#### staging — S2

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-staging | status | available | available | ok | aws rds describe-db-instances | 11:40 |
| orders-db-staging | CPUUtilization (avg) | 21.7% (1w 22.1%) | 14.1% | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-db-staging | DatabaseConnections (avg) | 38.0 (1w 37.0) | 30.0 | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-db-staging | DatabaseConnections (max) | 46 (1w 45) | 36 | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-db-staging | ReadLatency | no data | no data | no data | aws cloudwatch get-metric-data | 11:37 |
| orders-db-staging | WriteLatency | no data | no data | no data | aws cloudwatch get-metric-data | 11:37 |
| orders-db-staging | FreeableMemory | no data | no data | no data | aws cloudwatch get-metric-data | 11:37 |
| orders-db-staging | FreeStorageSpace | no data | no data | no data | aws cloudwatch get-metric-data | 11:37 |
| orders-api-staging | running vs desired | 2/2 | 2/2 | ok | aws ecs describe-services | 11:38 |
| orders-api-staging | CPUUtilization | 38.4% | 38.8% | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-api-staging | MemoryUtilization | 52.2% | 52.7% | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | RequestCount (traffic, denominator) | 24,130 (1w 23,890) | 4,000 (2 periods) | context (no threshold) | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | target 5XX rate (HTTPCode_Target_5XX_Count / RequestCount) | 0.20% (48 / 24,130; 1w 47 / 23,890) | 3.10% (124 / 4,000) | regressed | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | ELB 5XX count | 0 (1w 0) | 0 | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | TargetResponseTime p95 | 0.180 s (1w 0.184 s) | 0.215 s | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | HealthyHostCount (min) | 2 (1w 2) | 2 | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 (1w 0) | 0 | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-alb-staging | target health, orders-api-tg | 2 of 2 healthy | 2 of 2 healthy | ok | aws elbv2 describe-target-health | 11:39 |
| orders-worker-staging | running vs desired | 2/2 | 2/2 | ok | aws ecs describe-services | 11:38 |
| orders-worker-staging | CPUUtilization | 26.8% | 31.5% | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-worker-staging | MemoryUtilization | 44.4% | 45.2% | ok | aws cloudwatch get-metric-data | 11:37 |
| orders-worker-staging | JobsProcessed (traffic, denominator) | 7,201 (1w 7,129) | 1,202 (2 periods) | context (no threshold) | aws cloudwatch get-metric-data | 11:37 |
| orders-worker-staging | job error rate (JobErrors / JobsProcessed) | 0.50% (36 / 7,201; 1w 36 / 7,129) | 23.2% (279 / 1,202) | regressed | aws cloudwatch get-metric-data | 11:37 |
| alarm orders-worker-errors-staging | state | OK, not firing (S1) | ALARM since 11:36 | regressed | aws cloudwatch describe-alarms --state-value ALARM | 11:36 |

#### prod — S0

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-prod | status | available | — | — | aws rds describe-db-instances | 10:29 |
| orders-db-prod | CPUUtilization (avg) | 24.4% (1w 24.9%) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-db-prod | DatabaseConnections (avg) | 85.8 (1w 83.8) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-db-prod | DatabaseConnections (max) | 102 (1w 100) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-db-prod | ReadLatency | no data | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-db-prod | WriteLatency | no data | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-db-prod | FreeableMemory | no data | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-db-prod | FreeStorageSpace | no data | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-api-prod | running vs desired | 4/4 | — | — | aws ecs describe-services | 10:32 |
| orders-api-prod | CPUUtilization | 41.4% | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-api-prod | MemoryUtilization | 55.2% | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | RequestCount (traffic, denominator) | 108,130 (1w 107,050) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | target 5XX rate (HTTPCode_Target_5XX_Count / RequestCount) | 0.20% (217 / 108,130; 1w 215 / 107,050) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | ELB 5XX count | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | TargetResponseTime p95 | 0.183 s (1w 0.187 s) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | HealthyHostCount (min) | 4 (1w 4) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | UnHealthyHostCount (min) | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-alb-prod | target health, orders-api-tg | 4 of 4 healthy | — | — | aws elbv2 describe-target-health | 10:36 |
| orders-worker-prod | running vs desired | 4/4 | — | — | aws ecs describe-services | 10:32 |
| orders-worker-prod | CPUUtilization | 29.4% | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-worker-prod | MemoryUtilization | 47.2% | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-worker-prod | JobsProcessed (traffic, denominator) | 36,000 (1w 35,640) | — | — | aws cloudwatch get-metric-data | 10:39 |
| orders-worker-prod | job error rate (JobErrors / JobsProcessed) | 0.50% (180 / 36,000; 1w 180 / 35,640) | — | — | aws cloudwatch get-metric-data | 10:39 |
| alarm orders-worker-errors-prod | state | OK, not firing | — | — | aws cloudwatch describe-alarms --state-value ALARM | 10:38 |

#### prod — S1

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-prod | status | available | — | — | aws rds describe-db-instances | 11:52 |
| orders-db-prod | CPUUtilization (avg) | 24.4% (1w 24.9%) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-db-prod | DatabaseConnections (avg) | 85.8 (1w 83.8) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-db-prod | DatabaseConnections (max) | 102 (1w 100) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-db-prod | ReadLatency | no data | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-db-prod | WriteLatency | no data | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-db-prod | FreeableMemory | no data | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-db-prod | FreeStorageSpace | no data | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-api-prod | running vs desired | 4/4 | — | — | aws ecs describe-services | 11:50 |
| orders-api-prod | CPUUtilization | 41.4% | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-api-prod | MemoryUtilization | 55.2% | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | RequestCount (traffic, denominator) | 108,130 (1w 107,050) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | target 5XX rate (HTTPCode_Target_5XX_Count / RequestCount) | 0.20% (217 / 108,130; 1w 215 / 107,050) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | ELB 5XX count | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | TargetResponseTime p95 | 0.183 s (1w 0.187 s) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | HealthyHostCount (min) | 4 (1w 4) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | UnHealthyHostCount (min) | 0 (1w 0) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-alb-prod | target health, orders-api-tg | 4 of 4 healthy | — | — | aws elbv2 describe-target-health | 11:51 |
| orders-worker-prod | running vs desired | 4/4 | — | — | aws ecs describe-services | 11:50 |
| orders-worker-prod | CPUUtilization | 29.4% | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-worker-prod | MemoryUtilization | 47.2% | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-worker-prod | JobsProcessed (traffic, denominator) | 36,000 (1w 35,640) | — | — | aws cloudwatch get-metric-data | 11:49 |
| orders-worker-prod | job error rate (JobErrors / JobsProcessed) | 0.50% (180 / 36,000; 1w 180 / 35,640) | — | — | aws cloudwatch get-metric-data | 11:49 |
| alarm orders-worker-errors-prod | state | OK, not firing | — | — | aws cloudwatch describe-alarms --state-value ALARM | 11:48 |

#### prod — S2

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-prod | status | available | available | ok | aws rds describe-db-instances | 12:22 |
| orders-db-prod | CPUUtilization (avg) | 24.4% (1w 24.9%) | 24.3% | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-db-prod | DatabaseConnections (avg) | 85.8 (1w 83.8) | 85.5 | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-db-prod | DatabaseConnections (max) | 102 (1w 100) | 99 | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-db-prod | ReadLatency | no data | no data | no data | aws cloudwatch get-metric-data | 12:19 |
| orders-db-prod | WriteLatency | no data | no data | no data | aws cloudwatch get-metric-data | 12:19 |
| orders-db-prod | FreeableMemory | no data | no data | no data | aws cloudwatch get-metric-data | 12:19 |
| orders-db-prod | FreeStorageSpace | no data | no data | no data | aws cloudwatch get-metric-data | 12:19 |
| orders-api-prod | running vs desired | 4/4 | 4/4 | ok | aws ecs describe-services | 12:20 |
| orders-api-prod | CPUUtilization | 41.4% | 41.5% | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-api-prod | MemoryUtilization | 55.2% | 55.2% | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | RequestCount (traffic, denominator) | 108,130 (1w 107,050) | 18,000 (2 periods) | context (no threshold) | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | target 5XX rate (HTTPCode_Target_5XX_Count / RequestCount) | 0.20% (217 / 108,130; 1w 215 / 107,050) | 0.20% (36 / 18,000) | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | ELB 5XX count | 0 (1w 0) | 0 | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | TargetResponseTime p95 | 0.183 s (1w 0.187 s) | 0.185 s | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | HealthyHostCount (min) | 4 (1w 4) | 4 | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | UnHealthyHostCount (min) | 0 (1w 0) | 0 | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-alb-prod | target health, orders-api-tg | 4 of 4 healthy | 4 of 4 healthy | ok | aws elbv2 describe-target-health | 12:21 |
| orders-worker-prod | running vs desired | 4/4 | 4/4 | ok | aws ecs describe-services | 12:20 |
| orders-worker-prod | CPUUtilization | 29.4% | 29.6% | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-worker-prod | MemoryUtilization | 47.2% | 47.4% | ok | aws cloudwatch get-metric-data | 12:19 |
| orders-worker-prod | JobsProcessed (traffic, denominator) | 36,000 (1w 35,640) | 6,002 (2 periods) | context (no threshold) | aws cloudwatch get-metric-data | 12:19 |
| orders-worker-prod | job error rate (JobErrors / JobsProcessed) | 0.50% (180 / 36,000; 1w 180 / 35,640) | 0.50% (30 / 6,002) | ok | aws cloudwatch get-metric-data | 12:19 |
| alarm orders-worker-errors-prod | state | OK, not firing | OK, not firing | ok | aws cloudwatch describe-alarms --state-value ALARM | 12:18 |

## Outcome
completed

**Applied:** staging yes — not verified (the success criteria passed, but `orders-alb-staging` target 5XX rate, `orders-worker-staging` job error rate and alarm `orders-worker-errors-staging` regressed; overridden at `[H10]` 11:46); prod yes — verified (re-plan `No changes` 12:09; security group shows the admin-host rule only 12:10; `orders-db-prod` `available` 12:11; no regressed member; no data: `orders-db-prod` ReadLatency, WriteLatency, FreeableMemory, FreeStorageSpace; `orders-db-staging` has the same four)

## Ticket Reference
none
