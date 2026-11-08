# Dry-run of `iac-change-execution` against `simple-alarm-addition`

Expected skill behaviour at each step. Recorded for pre-dry-run reference; "Gaps surfaced" and "Fixes applied" are filled in during the actual dry-run.

## Step 1 — Research

**Input:** operator request — "Add a CloudWatch CPU utilization alarm for paymentapi in prod."

**Expected behaviour:**

| Check | Expected outcome |
|-------|-----------------|
| Catalog lookup | No `.culiops/service-discovery/paymentapi-prod.md` found — skill proceeds without catalog |
| Tool detection | Finds `main.tf`, `variables.tf`, `outputs.tf` → identifies Terraform |
| Naming pattern | Scans existing resource names: `paymentapi-cluster-${var.env}`, `paymentapi-svc-${var.env}`, `paymentapi-alerts-${var.env}` → infers `paymentapi-*-${var.env}` |
| SNS topic discovery | Reads `aws_sns_topic.paymentapi_alerts` → alarm should reuse `aws_sns_topic.paymentapi_alerts.arn` |
| ECS identifiers | Records `ClusterName = "paymentapi-cluster-${var.env}"`, `ServiceName = "paymentapi-svc-${var.env}"` for alarm dimensions |
| tfvars location | Finds `envs/prod.tfvars` — notes `-var-file=envs/prod.tfvars` for plan command |
| Evidence table | Rows for the ECS cluster/service names and the SNS topic, each with `code: main.tf:<line>`; skill proposes a live batch (`aws ecs describe-services`, `aws sns get-topic-attributes`, `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi`) to confirm they exist and no alarm with the new name already exists. If declined → rows marked `code-only — not live-verified` and passed to pre-flight |
| Delivery model / target | Notes how prod is selected (`-var-file=envs/prod.tfvars`); target check (`aws sts get-caller-identity`) required before Step 4a plan |

## Step 2 — Plan

**Expected output:**

```
Phase 1 (of 1):
  Add: aws_cloudwatch_metric_alarm.paymentapi_cpu_high
  Modify: (none)
  Destroy: (none)

Execution path: PR (default)
Pre-flight: required before merge
```

**Alarm spec the skill should propose:**

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

## Step 3 — Implement

**Expected behaviour:**

- Appends the alarm block to `main.tf` (no new files created)
- Follows the `paymentapi-*-${var.env}` convention → names alarm `paymentapi-cpu-high-${var.env}`
- Uses `aws_sns_topic.paymentapi_alerts.arn` (resource reference, not hardcoded ARN)
- Tags match existing resources (`Service = "paymentapi"`, `Environment = var.env`)
- Does NOT create a `plan-output.txt` — that is produced by the operator running `terraform plan`

## Step 4 — Execute

### 4a: Generate plan output

- Skill presents: `terraform plan -var-file=envs/prod.tfvars -out=tfplan`
- Operator runs the command (or skill runs with approval)
- Expected plan: 1 to add, 0 to change, 0 to destroy

### 4b: Pre-flight gate

- No existing pre-flight record — skill invokes `pre-flight` inline
- Context: Terraform, 1 resource add, CloudWatch alarm, paymentapi, ap-southeast-1
- Expected verdict: **Green** — alarm addition is low-risk, reversible, non-data-path
- GATE 3: Green → proceed

### 4c: Execute (PR path)

- Skill presents PR action and waits for GATE 4 approval
- Creates branch `iac-change/paymentapi-cpu-alarm`, commits, opens PR
- PR description references the pre-flight record
- Reports PR URL to operator
- Skill does NOT run `terraform apply` directly

## Step 5 — Verify & Record

- PR path: the fixture has no CI or GitOps config, so the delivery model is `UNVERIFIED` and the operator is asked how changes are applied. The next-step message follows the answer (CI / GitOps: "After merge, `<pipeline>` applies it"; by hand: "merging applies nothing").
- Record: `Outcome: completed` (PR created) with `Applied: no — PR open`. Not `yes — verified`.
- Writes execution record to `.culiops/iac-change-execution/paymentapi-cpu-alarm-<timestamp>.md`
- GATE 5: offers to commit the record

## Gaps surfaced

_(to be filled during actual dry-run)_

## Fixes applied

_(to be filled during actual dry-run)_

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 15** (`grep -c '^STOP ' baseline-output/stops.md`); 1 `unscripted` (pre-flight L2: the assessor's "applied recently?" question had no script answer).
- Sequence: delivery model, read batch, GATE 1, GATE 2, 4a target check, pre-flight GATE 1, L2, L3 opt-in, pre-flight GATE 2, GATE 3, heads-up offer, GATE 4, poll offer, GATE 5, result-message offer.
- Verdict GREEN. Outcome: PR opened, nothing applied.
- GATE 3 repeats the acknowledgement already taken at pre-flight GATE 2.
