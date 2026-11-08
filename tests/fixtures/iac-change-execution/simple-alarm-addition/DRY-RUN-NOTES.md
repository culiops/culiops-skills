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

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 2** (target 2): A,B. `unscripted`: 0.
- Before → after: **15 → 2** stops.

## Findings and fixes

Per-MUST results from the verifier:

### simple-alarm-addition (expected-output)
Stops: 2 (target 2) — PASS. Unscripted: 0. RED pre-flight runs: 0 (`P:15` `## Verdict: GREEN`).

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` is exactly `A`, `B`; no F1-F4, no D1; no separate stop for read batch, pre-flight GATE 1/2, L3 opt-in, comms offer, poll offer, record-commit | PASS | `S:1-2` (`A`, `B`). Full transcript search for `[F`, `[D1]`, `GATE`, `STOP n`: only `T:432` and `T:406` ("without a GATE 2", "GATE 1 is skipped"), `T:287` and `T:457` (the two stops). Heads-up is one optional line inside `[B]` (`T:455`), the operator skips it (`T:461`). Poll and record-commit offers are explicitly not made (`T:494`) | — |
| 2 | `[A]` carries plan, diff, target, read batch (plan command, cat 7 and 10 reads, success-criteria reads), L2 questions; delivery model asked inside `[A]` | PASS | Plan `T:220-234`; code summary with plan-to-hunk map `T:250-259`; target `T:198-199`, `T:256`; L2 questions `T:239-247`; delivery model `T:248`; read batch `T:261-283`: plan command `T:257` and `T:282`, cat 7 reads R10-R13 `T:271-274`, cat 10 reads R3, R5, R9, R14-R17 `T:264`, `T:266`, `T:270`, `T:275-278`, success criteria S1-S3 `T:229-232`, `T:282`. Note: the `[A]` block holds the code summary plus "Full diff is in your working tree" (`T:259`, per `SKILL.md:325`); the hunk text itself is printed at `T:111-146` just before `[A]` (`lanes.md:135` says "diff", `SKILL.md:314-328` says summary plus pointer) | — |
| 3 | Branch created and code written before `[A]`, after a clean `git status` | PASS | `git status --short` clean `T:82` (10:08); `git switch -c` `T:85` (10:11); code written `T:109-146`; `[A]` shown 10:15 (`T:194`) | — |
| 4 | Verdict line (GREEN or YELLOW) inside `[B]`; pre-flight inline; `preflight-record.md` exists; `record.md` links it | PASS | `[B]` verdict "Pre-flight verdict: GREEN" `T:453`; inline `T:361-436`, `P:10` (`Mode: inline`); record link `R:11` (`invoked inline — verdict: GREEN`) | — |
| 5 | `**Lane:** light` cites `plan:` for L1 and the allowlist entry for L2; `**Escalations:** none` | PASS | `R:12` ("`plan:42`: 1 to add, 0 to change, 0 to destroy"; "`aws_cloudwatch_metric_alarm` create is on the allowlist"); `R:13` `**Escalations:** none` | — |
| 6 | `**Environment tier:** prod=prod (operator-stated ...)`; unproven, prod gate levels | PASS | `R:14` `prod=prod (operator-stated, unproven: no allowed_account_ids, account variable or assume_role pin ...) → prod gate levels` | — |
| 7 | `**Staging-first:** n/a — no staging env (<evidence>)` with `envs/prod.tfvars` as the only env file; `- Parity check: n/a` | PASS | `R:15` (`code: envs/prod.tfvars` is the only environment file; `variables.tf:2` named only as an example value, not an env file); `R:60` `- Parity check: n/a` | — |
| 8 | `**Waived:** none` | PASS | `R:16` | — |
| 9 | `**Applied:** no — PR open` | PASS | `R:68`; outcome `R:65-66` | — |
| 10 | Final message ends with one `Next:` line | PASS | Final message `T:504-508`; single `Next:` line at `T:508` and it is the last line | — |
| 11 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0; `T:516` "No unscripted stop" | — |


No fixes needed for this fixture.
