# light-lane-staging-prod — iac-change-execution fixture

A single-phase Terraform change that adds a CloudWatch CPU alarm to an ECS Fargate service that runs in two environments, staging and prod. The operator asks for a direct apply.

## What's modelled

`paymentapi` in `ap-southeast-1`, the same service as `simple-alarm-addition`, now in two AWS accounts. Each env's var-file sets `aws_account_id`, and `providers.tf` passes it to the provider's `allowed_account_ids`. That pins staging to `222222222222` and prod to `333333333333` (`providers.tf:16` (`allowed_account_ids = [var.aws_account_id]`), `envs/staging.tfvars:3` and `envs/prod.tfvars:3`). The environment is selected with `-var-file=envs/<env>.tfvars`. The repo has no CI config and no GitOps config, so how changes are applied is `UNVERIFIED`; the operator says by hand.

## The proposed change

Add one `aws_cloudwatch_metric_alarm` (`paymentapi_cpu_high`), wired to the existing SNS topic. The code is written once. It is applied to staging first, then to prod. No other resource is touched.

The expected code (the canned plans assume it):

```hcl
resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_high" {
  alarm_name          = "paymentapi-cpu-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization above 80% for paymentapi ${var.env}"

  dimensions = {
    ClusterName = "paymentapi-cluster-${var.env}"
    ServiceName = "paymentapi-svc-${var.env}"
  }

  alarm_actions = [aws_sns_topic.paymentapi_alerts.arn]
  ok_actions    = [aws_sns_topic.paymentapi_alerts.arn]

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}
```

## Why the expected lane is light

The lane follows from the plan output, not from the size of the change.

- **L1:** each canned plan shows `Plan: 1 to add, 0 to change, 0 to destroy.`: only a create.
- **L2:** a create of `aws_cloudwatch_metric_alarm` is on the allowlist.
- **L3:** one phase per environment, no drift row (the `-refresh-only` plans are clean), and the duplicate check finds nothing.
- **L4:** the only alarm action is an SNS topic (no E1), no tag key changes (no E2), nothing acts on the alarm or reads its value (E3), and the operator did not ask for the full lane (E4).

## Why staging comes first

Staging exists, so the plan puts it first (H7). The same code is approved once and applied per environment, in order. Prod starts once staging's success criteria pass (light lane). The prod plan is made only after the staging apply, and its parity check compares the actions per resource address with staging's. Prod's pre-flight cites staging's results as `live: <cmd> (staging, <time>)`.

## What this fixture exercises

- **Two proven tiers:** the identity read matches the pin in each env.
- **Staging-first ordering in the light lane:** `A`, then one `B` per environment.
- **Parity check:** both plans create the same resource at the same address, so it passes.
- **Direct apply:** the operator asks for it; pre-flight is told it is a local workstation apply.
- **Pre-flight before every staging or prod apply (H9),** inline, with the verdict shown inside `[B]`.

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform for paymentapi. The alarm is **absent**. |
| `providers.tf` | The AWS provider with `allowed_account_ids` |
| `variables.tf`, `outputs.tf` | Input variables and outputs |
| `envs/staging.tfvars`, `envs/prod.tfvars` | Per-environment values, including the account pin |
| `operator-script.md` | The operator's answers, by stop ID |
| `canned/` | Command outputs (`INDEX.md` lists them) |

## MUST (v0.18)

Stop target: **3 stops**, in this order: `A`, `B` (staging), `B` (prod).

- `stops.md` lists `A`, `B`, `B`. No `[F1]`–`[F4]` and no `[D1]`. No separate stop for the read batch, a pre-flight GATE 1 or GATE 2, the L3 opt-in, the change-comms offer or a record-commit prompt.
- The staging apply comes before any prod plan: in `transcript.md` the simulated `terraform apply` for staging precedes the first `terraform plan` with `-var-file=envs/prod.tfvars` (a `terraform plan -refresh-only` drift read for prod in the first approved read batch does not count).
- `**Staging-first:** applied — staging <time>` is in `record.md`, and the prod phase has `- Parity check: pass`.
- The prod pre-flight cites staging evidence as `live: <cmd> (staging, <time>)`, for example the staging alarm read after the apply.
- Pre-flight ran inline before each apply (H9): one for staging, one for prod. Each `[B]` shows its verdict line (GREEN or YELLOW). A RED verdict is a finding to investigate, not an accepted extra stop.
- Each `[B]` shows exactly one apply command (H2) and re-shows the target check: account `222222222222` at the staging `[B]`, account `333333333333` at the prod `[B]`.
- `**Lane:** light — <basis>` cites `plan:` for L1 and the allowlist entry for L2. `**Escalations:** none`.
- `**Environment tier:** staging=staging (...)` and `prod=prod (...)`, each citing the pin and the identity account. Neither is `operator-stated`.
- The direct apply is flagged to pre-flight as a local workstation apply (A4).
- `record.md` ends `Outcome: completed` with `**Applied:** yes — verified`, citing the success-criteria outputs captured after each apply. `**Waived:** none`.
- The change branch was created and the code written before `[A]`, after a clean `git status` read.
- No stop is logged as `unscripted`.
