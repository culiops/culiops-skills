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
- `record.md`'s `## Outcome` section says completed, with `**Applied:** yes — verified`, citing the phase-1 and phase-2 success-criteria outputs.
- No stop is logged as `unscripted`.

### Expected pre-flight scoring (against the complete canned data)

Pre-flight runs inline for phase 1 and the phase-2 reboot. The canned reads cover health, observability, change velocity, backups and the consumers, so no score below rests on a missing read. Citations: `S` is `skills/pre-flight/SKILL.md`, `A` is `skills/pre-flight/assessors/iac-change.md`.

| # | Category | Score | Basis |
|---|---|---|---|
| 1 | Blast radius | Yellow (phase 1); phase 2: Yellow or Red (an in-place reboot without `--force-failover` is not softened by Multi-AZ, `canned/docs.md`); the verdict is RED either way | A database is shared infrastructure (`A:47`). The direct apply raises it further. |
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

## MUST (v0.20)

Run with `operator-script.md`. Out-dir `expected-output-v020`. Every line of `## MUST (v0.18)` still holds unless a line here replaces it, and so does the expected pre-flight scoring above, except category 11 (below: the app source is found, so Q8 is no longer (c) and category 11 is no longer ⚪). The v0.18 lines that `[F2]` carries the L2 answers, and that `[F4]` (phase 2) re-asks `Q1–Q3`, are replaced by the lines below.

Stop target: **5 (+1 per RED pre-flight run: each is its own `[H5]`)**: `F1`, `F2`, `F3` (phase 1), `F4` (phase 1), `F4` (phase 2), and one `H5` per RED pre-flight (v0.18: 5 in the stop sequence, 7 lines in `stops.md` with its two `[H5]`). Typed L2 target: **≤1**: at most `L2-ASKED: Q8`, the operator's confirmation of the `App source:` line inside `[F2]` (script: "yes"). Every other L2 item comes from a read, the profile, the first message or the operator line. The v0.18 baseline is 12 typed L2 items.

This fixture pins two review points. Review Focus 1, the disruption case: an RDS reboot spikes CPU and drops connections for a few minutes, and the run does not judge that a regression. Review Focus 5, the app-source version case: the app source is found, but its version is not the deployed one. `max_connections` is app-facing (`skills/pre-flight/assessors/iac-change.md`, app-facing table: "Limits the app must fit inside"), so Step 1 predicts an app-facing change and the skill looks for the app source.

- `stops.md` lists the v0.18 sequence, with no `[H10]` and no stop added by the snapshot, the profile, the app-source search or the operator line.
- **App source (Review Focus 5).** The sibling search is in the `[F1]` batch, each command shown: `ls` of the parent directory, `git -C ../paymentapi remote get-url origin` and `git -C ../paymentapi rev-parse HEAD`. It finds `../paymentapi`, whose directory name and origin match the service. The deployed image tag comes from a live read, `aws ecs describe-task-definition` (`paymentapi:v2.4.1`).
- `[F2]` carries exactly one line `App source: ../paymentapi @ 5d1c8e4; deployed v2.4.1 (live: <cmd>, <time>) — correct?` (the path may be absolute, the SHA full or shortened; the `live:` citation names the `aws ecs describe-task-definition` read that gave the deployed tag). It sits inside the existing `[F2]`. It is never a stop of its own, and `stops.md` has no extra line for it.
- Pre-flight's app-source reads (category 11, local mode) run at the deployed ref, not at `HEAD`: `git -C ../paymentapi grep -n … v2.4.1 -- .` and `git -C ../paymentapi show v2.4.1:<file>`, after the operator's confirmation. No read of the working tree at `HEAD` is made, and no `git fetch`, `checkout` or `stash` runs in the checkout.
- `transcript.md` has no `L2-ASKED` line other than Q8. Q4 and Q5 come from `canned/operator-profile.md`. The one L2 answer from the operator, the confirmation of the `App source:` line (Q8), is asked inside `[F2]`, not in a stop of its own. The delivery-model question (`UNVERIFIED` in the repo), the execution path and the plan order are not L2 items: they are asked inside the stop and are not logged `L2-ASKED`.
- The snapshot set is shown in `[F2]`, ordered as `snapshot.md` › Order and cap says (the changed resources first, then critical-path members, other dependents, then dependencies; the spec ranks dependents above dependencies and does not place the changed resources, and an `n/a` member may sit anywhere because it takes no cap slot), each member with its source, and holds:
  - the ECS service `paymentapi-svc-prod`, the consumer of the database, with a `code:` citation (the database security group admits `var.app_security_group_id`, `main.tf`, and `envs/prod.tfvars` pins that group, which the service's live network configuration also names) and the catalog's downstream line as a lead;
  - the instance `paymentapi-db-prod`, which the changed parameter group is attached to;
  - the load balancer `paymentapi-alb-prod` in front of the service, the nearest member with a request rate;
  - the changed parameter group `aws_db_parameter_group.paymentapi` listed as `n/a — no health signals of its own`, measured through the instance.
- The record has a `## Health Snapshot` section: the coverage line `Snapshot coverage: <sources used>; not covered: <gaps>` (it names `code` and `catalog` as sources), the members each with its source, and per phase the S0, S1 and S2 tables (signal, before, after, verdict, command, time).
- `**Checked for you:**` is inside `[F2]` (full lane: S0 ran after `[F1]`), as a block of what the skill read and derived: health (0 alarms firing, from S0), peak (the load balancer's request rate against the same hour last week), last apply (the automation-lag read, `live:`), the `App source:` line, and experience from the profile as `operator (profile, 2026-10-19)`. It is not a stop of its own.
- Q3 comes from the nearest member with a request rate (the load balancer's `RequestCount` at S0 against the same hour last week, about 3,450 against 3,400 per 5 minutes: no peak), tagged `live:`. If the skill cannot reach that member, Q3 is `unsure` with `UNVERIFIED — <why>`. It is never a typed question.
- The plan names the reboot's disruption (a restart or failover of `paymentapi-db-prod`) as expected. The phase-2 S2 judges the instance by its phase-2 success criteria (`DBInstanceStatus` = `available`, and the parameter reads), and starts the comparison of its CPU and connections after the instance is `available`: from the second period of `metric-data-s2-reboot-prod.json`. S2 waits until two periods have elapsed after `available` (and logs the clock jump to the time it stated as `S2 ready at HH:MM`), or reports `after: too early` for what has not elapsed. It is never `ok` early.
- Nothing is `regressed`. The first period's CPU (86%, over 70% from about 35% before) and connections (0) are not judged against S0. Phase 2's entry has `- Snapshot: before <time> · after <time> · <n ok / n regressed / n no data>` with `0 regressed`. `fail (snapshot)` appears nowhere. `database connections` saturation is `improved` or `ok`: after `available` the maximum is about 70 of `max_connections` 200, against 78 of 100 before.
- Phase 1's S2 (after the apply, before the reboot) reads the instance as `pending-reboot` with unchanged metrics: `0 regressed`.
- `**Applied:** yes — verified` still holds, and also requires no `regressed` member. Any `no data` member is listed.
- The phase-2 `[F4]` shows `Phase 1 success criteria: <check> — pass` followed by `Snapshot: <n ok · n regressed · n no data>`, and no `Q1–Q3 still true?` line: S1 and the operator line replace it. The operator line `Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.` is inside `[F2]` and again at the phase-2 `[F4]`; the operator does not reply.
- Pre-flight: category 11 is scored from the app source read at `v2.4.1`, so it is not ⚪. It cites `app:paymentapi@c0a7e93:app/db.py:11` and `app/config.py:6` (a pool of `DB_POOL_SIZE` 20 plus `DB_MAX_OVERFLOW` 5 per task, 3 tasks, about 75 connections, under 200), and names what a text search cannot see. The verdict stays RED (soft block) as in v0.18, with the `[H5]` stops the script acknowledges: categories 1, 2, 4, 7 and 10 still hold their v0.18 scores. A derived answer that moves another category is a finding to record, not a failure.
- No stop is logged as `unscripted`.
