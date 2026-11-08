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

Stop target: **5 stops**, in this order: `F1`, `F2`, `F3` (phase 1), `F4` (phase 1), `F4` (phase 2). **+1 `H5`** if a pre-flight verdict is RED: that is an accepted extra stop in this fixture.

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
