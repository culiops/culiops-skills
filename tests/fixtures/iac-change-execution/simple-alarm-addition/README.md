# simple-alarm-addition — iac-change-execution fixture

A single-phase Terraform change that adds a CloudWatch CPU utilization alarm to an existing ECS Fargate service.

## What's modelled

`paymentapi` — a fictional ECS Fargate service in `ap-southeast-1`. The service already exists and is stable. The change adds a `aws_cloudwatch_metric_alarm` resource for CPU utilization.

## The proposed change

Add one `aws_cloudwatch_metric_alarm` resource wired to the existing SNS topic (`paymentapi-alerts-${var.env}`). No other resources are modified or destroyed.

## What this fixture exercises

- **Research without catalog:** no `.culiops/service-discovery/` entry exists; skill must inspect the repo directly to determine tooling, naming conventions, and existing resources
- **Convention matching:** skill detects the `paymentapi-*-${var.env}` naming pattern from existing resources and applies it to the new alarm
- **SNS topic discovery:** skill finds the existing `paymentapi-alerts-${var.env}` SNS topic and reuses it rather than creating a new one
- **Single-phase plan:** the change is purely additive (1 resource added, 0 modified, 0 destroyed) — no multi-phase logic required
- **PR path (default):** no direct-apply override is present; skill defaults to the PR workflow
- **Code review gate:** skill surfaces the generated Terraform for operator review before proceeding to plan/apply
- **Pre-flight integration:** skill invokes pre-flight before execution; expected verdict is Green (single alarm, no data-path impact, reversible)

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform for paymentapi (cluster, service, task def, SG, ALB TG, log group, SNS topic). The alarm is **absent** — it is what the skill would add. |
| `variables.tf` | Input variables |
| `outputs.tf` | Outputs |
| `envs/prod.tfvars` | Prod-environment variable values |
| `DRY-RUN-NOTES.md` | Expected skill behaviour at each step |

## MUST (v0.18)

Stop target: **2 stops**, in this order: `A`, `B`.

- `stops.md` lists exactly `A` then `B`. No `[F1]`–`[F4]` and no `[D1]`. No separate stop for the read batch, a pre-flight GATE 1 or GATE 2, the L3 opt-in, the change-comms offer, the poll offer or a record-commit prompt.
- `[A]` carries the change plan, the diff, the target, the read batch (including the `terraform plan` command, pre-flight's category 7 and 10 reads and the post-apply success-criteria reads), and the L2 questions. The delivery model (`UNVERIFIED` in the repo) is asked inside `[A]`, not as its own stop.
- The change branch was created and the code written before `[A]`, after a `git status` read that came back clean. The diff shown at `[A]` is that code.
- The verdict line (GREEN or YELLOW) appears inside `[B]`. Pre-flight ran inline: `preflight-record.md` exists and `record.md` links it. A RED verdict is a finding to investigate, not an accepted extra stop.
- `**Lane:** light — <basis>` cites `plan:` for L1 (1 add, 0 change, 0 destroy) and the allowlist entry for L2 (create `aws_cloudwatch_metric_alarm`). `**Escalations:** none`.
- `**Environment tier:** prod=prod (operator-stated ...)`. The repo pins no account, so the tier is unproven and prod gate levels apply.
- `**Staging-first:** n/a — no staging env (<evidence>)`, with `envs/prod.tfvars` as the only env file named in the evidence. `- Parity check: n/a` in the phase entry of `record.md`: the parity check runs only when a staging phase ran for this change.
- `**Waived:** none`.
- `record.md` has `**Applied:** no — PR open`.
- The final message ends with one `Next:` line.
- No stop is logged as `unscripted`.

## MUST (v0.20)

Run with `operator-script.md` (the profile is present) and with `operator-script-no-profile.md`. Out-dir `expected-output-v020`. Every line of `## MUST (v0.18)` still holds unless a line here replaces it. The v0.18 line that `[A]` carries "the L2 questions" is replaced by the lines below on the operator line and the `**Checked for you:**` block.

### `operator-script.md` (profile present)

Stop target: **2 stops**, in this order: `A`, `B` (v0.18: 2). Typed L2 target: **0** (v0.18 baseline: 12 L2 items in the script, see `DRY-RUN-NOTES.md`).

- `stops.md` lists exactly `A` then `B`. The snapshot, the app-source search, the profile read and the operator line add no stop. No `[H10]`.
- `transcript.md` has no `L2-ASKED` line.
- Not-app-facing change: the alarm and its SNS topic (email subscribers) are on pre-flight's not-app-facing list and no output changes. The snapshot set holds the service `paymentapi-svc-prod` and the load balancer in front of it (S0 reads them for the L2 answers). It holds no dependency members. The record's `## Health Snapshot` says so and has the line `Snapshot coverage: <sources used>; not covered: <gaps>`.
- There is no S2 datapoint wait: no `after: too early` and no `S2 ready at`. The phase's success criteria alone verify the new alarm.
- The batch shown in `[A]` holds the S0 reads: one `describe-alarms --state-value ALARM`, one `get-metric-data` call (the hour now and the same hour last week), the service state reads, the automation-lag read (`gh run list` or the state `head-object`) and the app-source search. It is not larger than v0.18's batch by more than about 5 commands.
- The operator line `Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.` is inside `[A]`. The operator does not reply (`Operator line: no reply.`). It is recorded as `Q1(declared)=no, Q2=no — operator (no objection at [A], <time>)`.
- `**Checked for you:**` is inside `[B]` (S0 runs after `[A]` in the light lane), not inside `[A]`. It shows health (0 alarms firing, from S0), the last apply (from the automation-lag read, `live:`), and experience from the profile as `operator (profile, 2026-10-19)`. It carries no app-source line: the change is not app-facing and nothing was found.
- The delivery-model question (`UNVERIFIED` in the repo) is asked inside `[A]` and answered from the script's `Delivery model, if asked`. It is not an L2 item and is not logged `L2-ASKED`.
- Q4 and Q5 are not asked: they come from `canned/operator-profile.md`. Q8 is not asked (not app-facing). Q3 is not asked: on this PR / CI path it is `unsure (apply at merge; peak hours HH–HH, live)`, from the 7-day request-rate read (the canned busiest hours are 13:00–16:00 +07:00).
- The caller block to pre-flight carries the tagged line `L2 answers: Q1(alarms)=… Q1(declared)=… Q2=… Q3=… Q4=… Q5=… Q7=…`: `Q1(alarms)` tagged `live:`, `Q1(declared)` and `Q2` tagged `operator (no objection at [A], <time>)`, `Q4` and `Q5` tagged `operator (profile, 2026-10-19)`. The delivery model, the plan hash and the target answer `iac-change.1–3`; `iac-change.4` is answered from the automation-lag read, tagged `live:`.
- `preflight-record.md` `## Context Provided (L2)` shows each answer's tag. The verdict is GREEN or YELLOW; a RED verdict is a finding, not an accepted extra stop.
- `record.md` still has `**Applied:** no — PR open`. No stop is logged as `unscripted`.

### `operator-script-no-profile.md` (no profile file)

Stop target: **2 stops**, in this order: `A`, `B`. Typed L2 target: **2** (`L2-ASKED: Q4` and `L2-ASKED: Q5`, both inside `[A]`).

- `stops.md` lists exactly `A` then `B`. Q4 and Q5 are asked inside `[A]`, not in a stop of their own.
- `[A]` says it will remember them in the profile path (`I'll remember these in $CULIOPS_HOME/operator.md` or `~/.culiops/operator.md`, whichever applies). The runner logs the profile write as `PROFILE-WRITE:`; nothing is written.
- Everything else is as for `operator-script.md`: no other `L2-ASKED` line, the operator line inside `[A]`, `**Checked for you:**` inside `[B]`. Q4 and Q5 in the caller block are tagged `operator`, not `operator (profile, <date>)`: they come from this run's answers.
