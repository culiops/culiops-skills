# multi-phase-rds-upgrade — iac-change-execution fixture

A multi-phase change: update an RDS parameter group to increase `max_connections` from 100 to 200, then reboot the RDS instance so the dynamic parameter takes effect.

## What's modelled

`paymentapi` — the same fictional service as `simple-alarm-addition`, focusing on its RDS PostgreSQL 15 database in `ap-southeast-1`. A service catalog entry exists under `.culiops/service-discovery/`.

## The proposed change

1. **Phase 1 (IaC):** modify the `aws_db_parameter_group` to set `max_connections = 200`, and update the `aws_cloudwatch_metric_alarm.paymentapi_db_connections` threshold proportionally from 80 to 160.
2. **Phase 2 (operational):** reboot the RDS instance (`aws rds reboot-db-instance`) so the parameter group change takes effect. This phase is not expressible as a Terraform apply — it is an imperative AWS CLI command.

## What this fixture exercises

- **Multi-phase detection:** skill recognises that a parameter group change requires a subsequent reboot, producing a two-phase plan
- **Phase 2 as operational command:** Phase 2 is an AWS CLI call, not a `terraform apply` — skill must model both IaC and non-IaC phases
- **Catalog consumption:** `.culiops/service-discovery/paymentapi-prod.md` exists; skill reads it for signal envelopes and dependency graph before planning
- **Alarm threshold proportional update:** connections alarm threshold scales with `max_connections` (80% of 100 → 80, 80% of 200 → 160); skill detects and applies this update as part of Phase 1
- **Direct apply path:** the operator is a DBA performing a maintenance window procedure; they set the direct-apply flag, bypassing the PR workflow
- **Elevated risk pre-flight:** reboot causes a brief connection interruption; pre-flight should surface this as Amber or Red, requiring operator acknowledgement

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform: RDS parameter group (max_connections=100), RDS instance, security group, two CloudWatch alarms |
| `variables.tf` | Input variables |
| `envs/prod.tfvars` | Prod-environment variable values |
| `.culiops/service-discovery/paymentapi-prod.md` | Service catalog entry (signal envelopes, dependency graph) |
| `DRY-RUN-NOTES.md` | Expected multi-phase skill behaviour |

## MUST (v0.18)

Stop target: **5 (+1 per RED pre-flight run (each is its own `[H5]`))**: `F1`, `F2`, `F3` (phase 1), `F4` (phase 1), `F4` (phase 2), and one `H5` if the pre-flight verdict is RED. The scoring below leads to RED, so the `H5` stop is expected and accepted.

- `stops.md` lists those IDs in that order. Phase 2 is an operational command with no IaC code, so it has no `[F3]`. There is no separate phase gate between the phases.
- The phase-1 success-criteria result (the `describe-db-instances` and re-plan reads captured after the apply, showing `pending-reboot`) is shown in the first phase-2 stop, `[F4]` (phase 2).
- `**Lane:** full — <basis>` names the reason: the plan has updates (`aws_db_parameter_group`, and an alarm update) and neither is on the allowlist. `**Escalations:** none`, or the one that applies with its evidence.
- `**Environment tier:** prod=prod (operator-stated ...)`. The repo pins no account, so the tier is unproven and prod gate levels apply.
- `**Staging-first:** n/a — no staging env (<evidence>)`.
- `**Waived:** none`.
- Each phase in `record.md` has `- Parity check: n/a`.
- The direct apply is flagged to pre-flight as a local workstation apply (A4). The apply command and the reboot command are each shown alone and run only after approval, with the target check re-shown.
- `record.md` ends `Outcome: completed` with `**Applied:** yes — verified`, citing the phase-1 and phase-2 success-criteria outputs.
- No stop is logged as `unscripted`.

### Expected pre-flight scoring (against the complete canned data)

Pre-flight runs inline for phase 1 and the phase-2 reboot. The canned reads cover health, observability, change velocity, backups and the consumers, so no score below rests on a missing read. Citations: `S` is `skills/pre-flight/SKILL.md`, `A` is `skills/pre-flight/assessors/iac-change.md`.

| # | Category | Score | Basis |
|---|---|---|---|
| 1 | Blast radius | Yellow | A database is shared infrastructure (`A:47`). Multi-AZ softens the reboot (`live:` `MultiAZ` true). The direct apply raises it further. |
| 2 | Reversibility | Yellow | Undoing `max_connections` takes another edit and another reboot: manual rollback, untested (`S:49`). |
| 3 | Change velocity | Green | `git log --since=7.days` returns nothing. |
| 4 | Dependency impact | Yellow | The catalog lists one downstream consumer, the ECS tasks (`A:144`). |
| 5 | Timing context | Green | Q1 to Q3 are no. |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced. |
| 7 | Observability readiness | Yellow | The alarms on CPU and connections are static thresholds (`A:166`). |
| 8 | Cost impact | Green | No new resource and no size increase. |
| 9 | Security posture | Green | No security-relevant change. |
| 10 | Resource health | Yellow | Connections peaked at 78 of 100 in the last hour, above 70% saturation (`S:57`). The alarm history shows three episodes (six state changes) in the last week. |
| 11 | Application compatibility | ⚪ | `max_connections` is a limit the app must fit inside (`A:229`). Q8 is (c), so there is no source (`S:68`). |

Six categories are Yellow or ⚪. `S:66` escalates 3 or more to RED (soft block), so `H5` is expected. Every one of them comes from the scenario: a shared database, a reboot, saturated connections and no app source.