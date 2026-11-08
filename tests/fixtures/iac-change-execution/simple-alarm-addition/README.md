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
- `**Staging-first:** n/a — no staging env (<evidence>)`, with `envs/prod.tfvars` as the only env file named in the evidence.
- `**Waived:** none`.
- `record.md` has `**Applied:** no — PR open`.
- The final message ends with one `Next:` line.
- No stop is logged as `unscripted`.
