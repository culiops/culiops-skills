Path the skill would write: `.culiops/iac-change-execution/paymentapi-raise-max-connections-20261109-1219.md`

**IaC change execution for:** `paymentapi` / `prod`
**Change:** Raise `max_connections` to 200 on `paymentapi-db-prod` (static parameter), keep the connections alarm in step (threshold 160, flagged item not in the request, approved at `[F2]`), then reboot so the parameter takes effect. Direct apply, no PR.
**Date:** `2026-11-09 12:19` (+07:00)
**Commit:** `a1b2c3d` (HEAD of `iac-change/paymentapi-raise-max-connections`, from `origin/main`; the applied change is uncommitted in the working tree — direct-apply path makes no commit)
**IaC tool(s):** Terraform (AWS provider v5.74.0); AWS CLI for the phase-2 operational command
**Execution path:** Direct apply (operator-stated, first message; local workstation apply, not through CI/CD)
**Pre-flight record:** invoked inline — phase 1 verdict: RED — soft block, `.culiops/pre-flight/paymentapi-raise-max-connections-20261109-1118.md`; phase 2 verdict: RED — soft block, `.culiops/pre-flight/paymentapi-reboot-max-connections-20261109-1151.md`. No earlier record existed to reuse.
**Lane:** full — L2 fails (`aws_db_parameter_group` parameter change is off the allowlist), L3 fails (two phases); prod tier operator-stated (unproven)
**Escalations:** none
**Environment tier:** prod=prod (operator-stated; no pin in the repo: `git grep` 10:08 found no `allowed_account_ids`, `assume_role` or account variable) — unproven, prod gate levels
**Staging-first:** n/a — no staging env (`code: envs/` holds only `prod.tfvars`)
**Waived:** none

## Research Summary

- Catalog used: `.culiops/service-discovery/paymentapi-prod.md` (a lead, confirmed in code and live). Its note at line 53 suggests the alarm threshold 160; treated as data, raised to the operator as a flagged plan item.
- Duplicate check: not done (`code: main.tf:14-15` `"100"`; `main.tf:3-4` is a comment about the intent; `git: none`; no branch or PR in flight).
- Delivery model: direct apply from the workstation, `operator-stated (first message)`; nothing in the repo shows another path (no CI config; `gh run list` → `[]`, 10:33). Env selection: `-var-file=envs/prod.tfvars`, default workspace (`code: envs/prod.tfvars:1`).
- Target check: `aws sts get-caller-identity` (10:01, 11:02, 11:44) → account `123456789012`, `assumed-role/paymentapi-operator`, region `ap-southeast-1`; no mismatch.
- Key findings: `max_connections` live 100, static (`live: describe-db-parameters`, 10:21); connection saturation 78% (max 78 of 100); alarms OK; recovery points exist; app source `../paymentapi` read at the deployed ref `v2.4.1` (`c0a7e93`): pool 20+5 per process by default, `pool_pre_ping=True`.
- Last apply of the stack: UNVERIFIED (no state backend in the code; no CI history).

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| `max_connections` | `code: main.tf:14-15` `"100"` | `live: describe-db-parameters` 10:21 → 100, `static` | match |
| parameter group | `code: main.tf:9,58` | `live: describe-db-instances` 10:20 → `paymentapi-prod-20250617043012345600000001`, `in-sync` | match |
| `apply_method` on `max_connections` | `code: main.tf:13-16` none | `live:` ApplyMethod `pending-reboot`; `terraform plan -refresh-only` 10:19 → no changes | not a drift row (the tool reports none) |
| class / engine / Multi-AZ | `code: envs/prod.tfvars:6`, `main.tf:46,62` | `live: describe-db-instances` → `db.r6g.large`, 15.4, true | match |
| recovery points | `code: main.tf:63,67-68` | `live:` retention 7, latestRestorable 02:55Z, 3 automated snapshots (newest 2026-11-09 02:05Z) | match |
| connections alarm | `code: main.tf:140-156` | `live: describe-alarms-for-metric` 10:23 → threshold 80, enabled, OK | match |
| alarm notify-only | `code: main.tf:155-156` | `live:` SNS protocols `email`, `email` | match |
| app tier connects | `code: main.tf:94`, `envs/prod.tfvars:5`, `catalog: paymentapi-prod.md:41` | `live: describe-services` 10:28 → same security group | match |
| deployed app image | none | `live: describe-task-definition` 10:32 → `paymentapi:v2.4.1` | live only |
| delivery model | none | `live: gh run list` → `[]` | UNVERIFIED in the repo; operator-stated |
| last apply of this stack | none | `live: gh run list` → `[]` | UNVERIFIED |

Drift rows: 0. Unverified rows: 2. Code-only rows: 0.

## Change Plan

**Phase 1 of 2: raise `max_connections` to 200 (static, applied at the reboot) and the connections alarm to 160 / limit 200**
- Files: `main.tf`
- Resources: change `aws_db_parameter_group.paymentapi` (in place), change `aws_cloudwatch_metric_alarm.paymentapi_db_connections` (in place; not named in the request, flagged and approved at `[F2]`)
- Blast radius: RDS `paymentapi-db-prod`, the alarm, the parameter group (`n/a — no health signals of its own`), ECS `paymentapi-svc-prod`, ALB `paymentapi-alb-prod` · `Snapshot coverage: code + catalog + live describe reads; not covered: callers of the database outside this repo and the catalog, the app tier's own alarms`
- Disruption: none at apply time (`docs: USER_WorkingWithParamGroups.html (read 2026-11-09)`; `live:` ApplyType static; `docs: API_PutMetricAlarm.html (read 2026-11-09)`)
- Rollback: reversible, set back to 100 and apply the reverted code through the same path (`docs: USER_WorkingWithParamGroups.html`); takes effect after the next reboot; untested
- Success criteria: parameter `"200"`; status `available` with `pending-reboot`; re-plan `No changes`; alarm threshold 160, `OK`, enabled; S2

**Phase 2 of 2: reboot `paymentapi-db-prod` (operational, no IaC change)**
- Command: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` (no `--force-failover`)
- Disruption: brief unavailability (`docs: USER_RebootInstance.html (read 2026-11-09)`; `live:` Multi-AZ true, not used by this command)
- Rollback: not undoable; parameter revert plus a second reboot, same outage; untested
- Success criteria: `available`, `in-sync`, pending `{}`; parameter `"200"`; nothing firing; S2

Execution path: direct apply. Staging-first (H7): (a) no staging env. Branch: `iac-change/paymentapi-raise-max-connections` from `origin/main` @ `a1b2c3d`. Self-check 8/8 (item 6 flagged). Drift: none.

## Execution Log

### Phase 1: raise `max_connections` to 200 and the connections alarm to 160
- Files changed: `main.tf` (hunk 1 `max_connections` 100 → 200 with `apply_method = "pending-reboot"`; hunk 2 alarm threshold 80 → 160 and description `(limit: 200)`)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 2 to change, 0 to destroy
- Plan hash: `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` (`terraform show -no-color tfplan`)
- Parity check: n/a
- Pre-flight verdict: RED — soft block (four Yellow: blast radius, dependency impact, observability readiness, resource health), acknowledged at `[H5]` 11:23 and carried to `[F4]` 11:28. Reason, word for word: "maintenance window approved, DBA on call, the failover is expected". Mitigations committed: S2 and `[H10]` after the apply; keep the reboot close behind (the alarm sits at 160 over a live limit of 100 until then).
- Execution: `terraform apply tfplan` at 11:29, `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` Approved at `[F4]` 11:28. No commit, no push.
- Verification: re-plan 11:30 `No changes`; `describe-db-parameters` 11:31 → `"200"`; `describe-db-instances` 11:32 → `available`, `ParameterApplyStatus` `pending-reboot`; `describe-alarms --alarm-names` 11:33 → threshold 160, `OK`, enabled `true`. Phase verification: pass. (Canned alarm files carry `AlarmConfigurationUpdatedTimestamp` 2026-11-09T03:21:40Z, earlier than this run's apply; recorded as printed.)
- Snapshot: before 11:06-11:10 · after 11:39-11:43 · 17 ok / 0 regressed / 0 no data

### Phase 2: reboot `paymentapi-db-prod`
- Files changed: none (operational command)
- Self-check: n/a (no code) · plan item checks as above
- Fresh eyes: skipped — no code in this phase (not run: no IaC change)
- Plan output summary: n/a — no plan run (operational command)
- Plan hash: none — operational command (`aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1`)
- Parity check: n/a
- Pre-flight verdict: RED — soft block (six Yellow: blast radius, reversibility, dependency impact, observability readiness, resource health, application compatibility), acknowledged at `[H5]` 11:56, carried to `[F4]` 12:01. Reason, word for word: "maintenance window approved, DBA on call, the failover is expected". Mitigations committed: S2 and `[H10]`; `pool_pre_ping` lets the tasks reconnect; alarm (160) matches the new limit (200) after the reboot.
- Execution: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` at 12:02 (`rebooting`); `available` at 12:04. Approved at `[F4]` 12:01.
- Verification: status `available`, `ParameterApplyStatus` `in-sync`, `PendingModifiedValues` `{}` (12:04); `describe-db-parameters` 12:05 → `"200"` (configured value; the value inside PostgreSQL is not read); alarm 160, `OK` (12:06); nothing firing (12:15). Re-plan: n/a — operational phase. Phase verification: pass.
- Snapshot: before 11:45-11:49 · after 12:14-12:18 · 17 ok / 0 regressed / 0 no data (one row `improved`: connection saturation 78% → 35.5%)

## Health Snapshot

`Snapshot coverage: code + catalog + live describe reads; not covered: callers of the database outside this repo and the catalog (no runtime profile; the catalog lists no other consumers, a lead only), the app tier's own alarms`

Members:
- RDS `paymentapi-db-prod` — changed — `code: main.tf:42`
- `aws_cloudwatch_metric_alarm.paymentapi_db_connections` — changed — `code: main.tf:140` (judged by success criteria; its firing state is the `alarms firing` row)
- `aws_db_parameter_group.paymentapi` — changed — `code: main.tf:8` — n/a — no health signals of its own
- ECS `paymentapi-svc-prod` — dependent, critical path — `catalog: paymentapi-prod.md:41`, `code: main.tf:94`
- ALB `paymentapi-alb-prod` / TG `paymentapi-tg-prod` — front door of the dependent, traffic and error series — `catalog: paymentapi-prod.md:31` pattern, confirmed by the batch
- SNS topic `paymentapi-alerts-prod`, DB subnet group, VPC — dependencies — n/a — no health signals of its own
- Over cap: none. No metrics backend gap (CloudWatch).

Commands: **M** = `aws cloudwatch get-metric-data` with `.culiops/iac-change-execution/snapshot-queries-prod.json` (`Period` 3600 for S0 and S1, 300 for S2); **A** = `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm`; **E** = `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod`; **T** = `aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod>`; **R** = `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod`. S0 and S1 hourly values are folded from the canned 5-minute values (sum for counts, mean for averages and p95, max for Maximum, min for Minimum); counts as per-minute rates.

### prod S0 — 10:38 (A), 10:39 (M), 10:20 (R), 10:28 (E), 10:29 (T); phase-1 baseline

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| RDS | status | `available`, `in-sync` | — | — | R | 10:20 |
| RDS | CPU avg | 33.8% [1w 34.1%] | — | — | M | 10:39 |
| RDS | connections avg | 51.5 [50.5] | — | — | M | 10:39 |
| RDS | connections max vs limit 100 | 78 = 78% [76] | — | — | M, `describe-db-parameters` | 10:39 |
| RDS | read latency avg | 1.20 ms [1.15] | — | — | M | 10:39 |
| RDS | write latency avg | 2.23 ms [2.18] | — | — | M | 10:39 |
| RDS | freeable memory min | 6.10 GB [6.14] | — | — | M | 10:39 |
| RDS | free storage min | 82.0 GB [82.6] | — | — | M | 10:39 |
| ECS | running vs desired | 3/3 | — | — | E | 10:28 |
| ECS | CPU avg | 37.7% | — | — | M | 10:39 |
| ECS | memory avg | 51.8% | — | — | M | 10:39 |
| ALB | request rate | 690.7/min [680.3/min] | — | — | M | 10:39 |
| ALB | target 5xx | 0 [0] | — | — | M | 10:39 |
| ALB | ELB 5xx | 0 [0] | — | — | M | 10:39 |
| ALB | p95 | 0.114 s [0.116] | — | — | M | 10:39 |
| ALB | healthy / unhealthy hosts | 3 / 0 (T: 3 healthy) | — | — | M, T | 10:39, 10:29 |
| set | alarms firing | 0 | — | — | A | 10:38 |

### prod S1, phase 1 — 11:06-11:10 (S0 was 26 minutes old, read again; not reused)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| RDS | status | `available`, `in-sync` | — | — | R | 11:10 |
| RDS | CPU avg | 33.8% | — | — | M | 11:07 |
| RDS | connections avg | 51.5 | — | — | M | 11:07 |
| RDS | connections max vs limit 100 | 78 = 78% | — | — | M | 11:07 |
| RDS | read latency avg | 1.20 ms | — | — | M | 11:07 |
| RDS | write latency avg | 2.23 ms | — | — | M | 11:07 |
| RDS | freeable memory min | 6.10 GB | — | — | M | 11:07 |
| RDS | free storage min | 82.0 GB | — | — | M | 11:07 |
| ECS | running vs desired | 3/3 | — | — | E | 11:08 |
| ECS | CPU avg | 37.7% | — | — | M | 11:07 |
| ECS | memory avg | 51.8% | — | — | M | 11:07 |
| ALB | request rate | 690.7/min | — | — | M | 11:07 |
| ALB | target 5xx | 0 | — | — | M | 11:07 |
| ALB | ELB 5xx | 0 | — | — | M | 11:07 |
| ALB | p95 | 0.114 s | — | — | M | 11:07 |
| ALB | healthy / unhealthy hosts | 3 / 0 (T: 3 healthy) | — | — | M, T | 11:07, 11:09 |
| set | alarms firing | 0 | — | — | A | 11:06 |

### prod S2, phase 1 — 11:39-11:43 (two 5-minute periods after the apply at 11:29:00)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| RDS | status | `available` | `available`, `pending-reboot` (expected) | ok | R | 11:43 |
| RDS | CPU avg | 33.8% | 32.6% | ok | M | 11:39 |
| RDS | connections avg | 51.5 | 52.5 | ok | M | 11:39 |
| RDS | connections max vs limit 100 | 78% | 77 = 77% | ok (already above 70%) | M | 11:39 |
| RDS | read latency avg | 1.20 ms | 1.25 ms | ok (1.04×) | M | 11:39 |
| RDS | write latency avg | 2.23 ms | 2.30 ms | ok (1.03×) | M | 11:39 |
| RDS | freeable memory min | 6.10 GB | 6.10 GB | ok | M | 11:39 |
| RDS | free storage min | 82.0 GB | 82.0 GB | ok | M | 11:39 |
| ECS | running vs desired | 3/3 | 3/3 | ok | E | 11:41 |
| ECS | CPU avg | 37.7% | 36.4% | ok | M | 11:39 |
| ECS | memory avg | 51.8% | 50.9% | ok | M | 11:39 |
| ALB | request rate | 690.7/min | 685.7/min | ok | M | 11:39 |
| ALB | target 5xx | 0 | 0 (below 5-error floor) | ok | M | 11:39 |
| ALB | ELB 5xx | 0 | 0 | ok | M | 11:39 |
| ALB | p95 | 0.114 s | 0.117 s | ok (1.03×) | M | 11:39 |
| ALB | healthy / unhealthy hosts | 3 / 0 | 3 / 0 (T: 3 healthy) | ok | M, T | 11:39, 11:42 |
| set | alarms firing | 0 | 0 | ok | A | 11:40 |

### prod S1, phase 2 — 11:45-11:49 (fresh read; phase 1's S2 has no week-ago window, so not reused)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| RDS | status | `available`, `pending-reboot` | — | — | R | 11:49 |
| RDS | CPU avg | 33.8% | — | — | M | 11:46 |
| RDS | connections avg | 51.5 | — | — | M | 11:46 |
| RDS | connections max vs limit 100 | 78 = 78% | — | — | M | 11:46 |
| RDS | read latency avg | 1.20 ms | — | — | M | 11:46 |
| RDS | write latency avg | 2.23 ms | — | — | M | 11:46 |
| RDS | freeable memory min | 6.10 GB | — | — | M | 11:46 |
| RDS | free storage min | 82.0 GB | — | — | M | 11:46 |
| ECS | running vs desired | 3/3 | — | — | E | 11:47 |
| ECS | CPU avg | 37.7% | — | — | M | 11:46 |
| ECS | memory avg | 51.8% | — | — | M | 11:46 |
| ALB | request rate | 690.7/min | — | — | M | 11:46 |
| ALB | target 5xx | 0 | — | — | M | 11:46 |
| ALB | ELB 5xx | 0 | — | — | M | 11:46 |
| ALB | p95 | 0.114 s | — | — | M | 11:46 |
| ALB | healthy / unhealthy hosts | 3 / 0 (T: 3 healthy) | — | — | M, T | 11:46, 11:48 |
| set | alarms firing | 0 | — | — | A | 11:45 |

### prod S2, phase 2 — 12:14-12:18 (two 5-minute periods after the status was `available` again at 12:04:00)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| RDS | status | `available`, `pending-reboot` | `available`, `in-sync`, pending `{}` | ok | R | 12:18 |
| RDS | CPU avg | 33.8% | 32.8% | ok | M | 12:14 |
| RDS | connections avg | 51.5 | 50.0 | ok | M | 12:14 |
| RDS | connections max vs limit | 78 / 100 = 78% | 71 / 200 = 35.5% | improved (crossed 70% from above) | M | 12:14 |
| RDS | read latency avg | 1.20 ms | 1.15 ms | ok | M | 12:14 |
| RDS | write latency avg | 2.23 ms | 2.15 ms | ok | M | 12:14 |
| RDS | freeable memory min | 6.10 GB | 6.45 GB | ok | M | 12:14 |
| RDS | free storage min | 82.0 GB | 82.0 GB | ok | M | 12:14 |
| ECS | running vs desired | 3/3 | 3/3 | ok | E | 12:16 |
| ECS | CPU avg | 37.7% | 38.8% | ok | M | 12:14 |
| ECS | memory avg | 51.8% | 52.6% | ok | M | 12:14 |
| ALB | request rate | 690.7/min | 689.0/min | ok | M | 12:14 |
| ALB | target 5xx | 0 | 0 (below 5-error floor) | ok | M | 12:14 |
| ALB | ELB 5xx | 0 | 0 | ok | M | 12:14 |
| ALB | p95 | 0.114 s | 0.114 s | ok | M | 12:14 |
| ALB | healthy / unhealthy hosts | 3 / 0 | 3 / 0 (T: 3 healthy) | ok | M, T | 12:14, 12:17 |
| set | alarms firing | 0 | 0 | ok | A | 12:15 |

The reboot period itself (the canned file's first period: CPU 86.4%, connections 0, latency 4.8 / 7.1 ms) is before the S2 window and is the plan's named disruption; it is not judged.

## Outcome
completed

**Applied:** yes — verified (phase 1: re-plan `No changes`, `max_connections` `"200"` pending-reboot, alarm 160 `OK` enabled, S2 17 ok / 0 regressed; phase 2: `DBInstanceStatus` `available`, `ParameterApplyStatus` `in-sync`, `PendingModifiedValues` `{}`, `max_connections` `"200"`, S2 17 ok / 0 regressed, none `regressed`). No-data members: none; `n/a — no health signals of its own`: parameter group, SNS topic, DB subnet group, VPC. Not read: the running value inside PostgreSQL.

## Ticket Reference
none
