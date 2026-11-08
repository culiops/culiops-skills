# light-escalation-alarm-action — iac-change-execution fixture

A request that sounds small (add one CloudWatch alarm) but copies an alarm that is wired to automation. The rule, not the size of the change, decides the lane.

## What's modelled

`paymentapi` in `ap-southeast-1`, prod only (account `333333333333`, pinned through `allowed_account_ids`: `providers.tf:16` and `envs/prod.tfvars:3`). The service scales with Application Auto Scaling. The existing alarm `paymentapi_cpu_high` has two alarm actions: the SNS topic and the scale-out policy `aws_appautoscaling_policy.paymentapi_scale_out` (`main.tf:252`, in the `alarm_actions` list that opens at `main.tf:250`). A scale-in policy, `paymentapi_scale_in`, exists but no alarm drives it.

## The proposed change

The operator asks: "Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one." That means a second `aws_cloudwatch_metric_alarm` with an SNS action and the scale-in policy as its alarm action.

The expected code (the canned plan assumes it):

```hcl
resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_low" {
  alarm_name          = "paymentapi-cpu-low-${var.env}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "CPU utilization below 20% for paymentapi ${var.env}"

  dimensions = {
    ClusterName = aws_ecs_cluster.paymentapi.name
    ServiceName = aws_ecs_service.paymentapi.name
  }

  alarm_actions = [
    aws_sns_topic.paymentapi_alerts.arn,
    aws_appautoscaling_policy.paymentapi_scale_in.arn,
  ]
  ok_actions = [aws_sns_topic.paymentapi_alerts.arn]

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}
```

## Why the expected lane is full

The change is a single create, and a create of `aws_cloudwatch_metric_alarm` is on the allowlist, so L1 and L2 hold. The change still leaves the light lane, because **E1** fires: an alarm action is not an SNS topic. The new alarm's action is a scaling policy, and the existing alarm it copies is wired the same way (`main.tf:252`). Once the alarm exists, a low-CPU reading removes a task from a prod service. The escalation is visible from the request and the code, so the lane is full from Step 1 and the first stop is `F1`, not `A`.

There is no staging environment in the repo, so staging-first does not apply.

## What this fixture exercises

- **E1 from the code.** The reason cites the exact line of the existing alarm's `alarm_actions`.
- **No downgrade.** A GREEN-looking plan (`1 to add`) does not return the change to the light lane.
- **Pre-flight treats the alarm as app-facing.** An alarm whose action scales is not notify-only (`skills/pre-flight/assessors/iac-change.md:215`). Category 11 is triggered (Q8 is asked), and with no app source it is ⚪, never Green from the plan alone. The scoring below shows how the verdict reaches RED, so an `H5` stop is expected here and the script answers it.
- **Reads that make the verdict reachable:** the existing CPU-high alarm live and enabled, the scaling target and policies, recent scaling activity, the SNS subscription protocols.

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform: the ECS service, Application Auto Scaling (target, scale-out and scale-in policies), the CPU-high alarm |
| `providers.tf` | The AWS provider with `allowed_account_ids` |
| `variables.tf`, `outputs.tf` | Input variables and outputs |
| `envs/prod.tfvars` | Prod values, including the account pin |
| `operator-script.md` | The operator's answers, by stop ID |
| `canned/` | Command outputs (`INDEX.md` lists them) |

## MUST (v0.18)

Stop target: **4 (+1 if H5)**: `F1`, `F2`, `F3`, `F4`, and one `H5` if the pre-flight verdict is RED. The scoring below leads to RED, so the `H5` stop is expected and accepted.

- `stops.md` lists `F1`–`F4` (and `H5` before `F4` if shown). The first stop is `F1`, not `A`. No `[A]`, `[B]` or `[D1]`.
- `**Escalations:** E1 — <evidence>` where the evidence cites `code: main.tf:252` (the line `aws_appautoscaling_policy.paymentapi_scale_out.arn,`) or `code: main.tf:250` (the line that opens the `alarm_actions` list of `aws_cloudwatch_metric_alarm.paymentapi_cpu_high`), and names the scale-out policy reference. `**Lane:** full — <basis>` points at that escalation.
- The lane is not downgraded after the plan comes back as a single create.
- `**Staging-first:** n/a — no staging env (<evidence>)`, with `envs/prod.tfvars` as the only env file named in the evidence. `- Parity check: n/a` in the phase entry: the parity check runs only when a staging phase ran for this change.
- `**Environment tier:** prod=prod (...)`, citing the pin and the identity account (not `operator-stated`).
- Q8 is asked inside `[F2]` and answered (c). Pre-flight does not score category 11 Green from the plan alone.
- A RED verdict ends in an `H5` stop, logged as `H5`, and is accepted here (see the scoring below).
- `**Waived:** none`.
- No stop is logged as `unscripted`.

### Expected pre-flight scoring (against the complete canned data)

The canned reads cover the service's health, the load balancer's error and latency metrics, the existing alarm, the scaling target and policies, recent scaling activity, the SNS subscription protocols and the alarm price. So no score below rests on a missing read. Citations: `S` is `skills/pre-flight/SKILL.md`, `A` is `skills/pre-flight/assessors/iac-change.md`.

| # | Category | Score | Basis |
|---|---|---|---|
| 1 | Blast radius | Yellow | When CPU is low the new alarm removes a task from a prod service: a capacity reduction, which scores here (`A:42`). `live:` minimum capacity 2 and desired count 3 soften it, one task per step. |
| 2 | Reversibility | Green | `plan:` a create. Deleting the alarm stops further scale-in, and the scale-out policy raises capacity again (`docs:` step scaling). |
| 3 | Change velocity | Green | `git log --since=7.days` returns nothing. |
| 4 | Dependency impact | Green | `code:` `git grep` finds nothing that references the new alarm, so the changed resource has no consumers (`S:51`). |
| 5 | Timing context | Green | Q1 to Q3 are no. |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced. |
| 7 | Observability readiness | Yellow | The alarms on the service are static CPU thresholds (`A:166`). The change is not a not-app-facing alarm, so the `A:172` exception does not apply. |
| 8 | Cost impact | Green | One alarm, priced by the Price List read (0.10 USD, publication 2026-10-07). Scale-in lowers cost and leaves nothing billing (`A:184`). |
| 9 | Security posture | Green | No IAM, network or encryption change. |
| 10 | Resource health | Green | `live:` 3 of 3 tasks running, targets healthy, nothing firing, CPU 40%, no 5xx and latency about 40 ms. |
| 11 | Application compatibility | ⚪ | A scaling action makes the alarm app-facing (`A:215`). Q8 is (c), so there is no source (`S:68`). |

Three categories are Yellow or ⚪ (1, 7, 11), and `S:66` escalates 3 or more to RED (soft block), so `H5` is expected. Category 1 is the judgment call: a skill that scores it Green on the one-task step and the minimum capacity ends at YELLOW with no `H5`. Either result is accepted. The real risk is the scenario's: an alarm that removes capacity from a prod service. None of the three comes from a missing read.
