Intended path: `.culiops/iac-change-execution/paymentapi-raise-cpu-alarm-threshold-20261109-1112.md` (not written into the fixture; this file stands in for it)

**IaC change execution for:** `paymentapi` / `prod`
**Change:** Raise the paymentapi prod CPU alarm threshold from 80 to 90.
**Date:** `2026-11-09 11:12`
**Commit:** `7f3a9c1`
**IaC tool(s):** Terraform (`hashicorp/aws ~> 5.0`)
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/paymentapi-raise-cpu-alarm-threshold-20261109-1101.md` — invoked inline — verdict: YELLOW
**Lane:** full — L2 fails: an update of an existing `aws_cloudwatch_metric_alarm` that changes `threshold` and `alarm_description` is off the light-lane allowlist (`code: main.tf:196-197`; `lanes.md` › Light-lane allowlist). Prod is not a proven dev target. Confirmed from the plan output at 4a (10:56).
**Escalations:** none
**Environment tier:** prod=prod (live: `aws sts get-caller-identity` 10:01 → 333333333333; code: `envs/prod.tfvars:3`, `providers.tf:16`), staging=staging (live: `aws sts get-caller-identity` 10:02 → 222222222222; code: `envs/staging.tfvars:3`, `providers.tf:16`)
**Staging-first:** exception (prod-only) — "Staging has no CPU alarm and runs one task at about 12 percent CPU, so a threshold change there exercises nothing. 90 only makes sense against prod's CPU profile, where the alarm fired 4 times in the last week at readings of 85 to 88 percent."
**Waived:** none
**Prerequisites (examples/aws.md):** AWS CLI v2; credentials by named profile, SSO, IAM role or STS (identity confirmed with `aws sts get-caller-identity`); Tier 1 read-only access for Steps 1 and 5 (used: the `[F1]` batch); Tier 2 mutation role only for a direct apply (not used: PR path, CI applies on merge); CloudWatch `GetMetric*` reads carry small per-call charges.

## Research Summary
- Catalog used: none — `.culiops/service-discovery/paymentapi.md` does not exist; service-discovery was suggested.
- Duplicate check: **not done**. `code: envs/prod.tfvars:17` is 80; staging sets no value (`envs/staging.tfvars:1-14`, `variables.tf:77`, `main.tf:187`); `git:` `git log --all -S` finds no add or remove of `cpu_alarm_threshold` or `paymentapi-cpu-high`; no branch matches `*cpu*`; no open PR matches; live threshold is 80 (`live: describe-alarms`, 10:18).
- Delivery model: `UNVERIFIED` in the repo (no CI config, GitOps object, Atlantis / Terraform Cloud / Spacelift file, or backend block); `operator-stated` at `[F2]`: PR, and a CI pipeline applies on merge.
- Env selection: `-var-file=envs/<env>.tfvars`, default workspace, no declared backend (`code: envs/prod.tfvars`, `envs/staging.tfvars`, `providers.tf:12-17`).
- Target check: 10:01 prod identity 333333333333 / `assumed-role/paymentapi-operator` matches the pin; re-checked at 4a (10:55) and by pre-flight (10:59): unchanged. No `[H1]`.
- Key findings: one alarm in prod, notify-only (SNS topic, two `email` subscribers); no drift in prod or staging; the alarm went to ALARM 4 times in the last 7 days at 85 to 88 percent (`live: describe-alarm-history`, 10:21); nothing firing now; staging has no alarm.
- Reads declined or not run: none declined. Not run: last-apply read, because the repo declares no backend.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| prod CPU alarm threshold | `code: envs/prod.tfvars:17` → 80; `main.tf:196` | `live: aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod` (10:18) → 80.0 | ✅ |
| alarm description | `code: main.tf:197` → built from the threshold | `live: describe-alarms` (10:18) → "CPU utilization above 80% for paymentapi prod" | ✅ (will change with the threshold) |
| alarm actions | `code: main.tf:204-205` → `aws_sns_topic.paymentapi_alerts.arn` | `live: describe-alarms` (10:18) → `arn:…:paymentapi-alerts-prod`; `live: sns list-subscriptions-by-topic` protocols (10:22) → `email`, `email` | ✅ notify-only |
| alarm enabled and state | `code: none` | `live: describe-alarms` (10:18) → `ActionsEnabled true`, `OK`; `describe-alarms --state-value ALARM` (10:20) → none firing | n/a |
| alarm firing history | `code: none` | `live: describe-alarm-history` (10:21) → 4 ALARM episodes in 7 days, peaks 85 to 88 percent | n/a |
| staging has no CPU alarm | `code: envs/staging.tfvars:1-14`, `variables.tf:77`, `main.tf:187` | `live: describe-alarms --alarm-name-prefix paymentapi` (10:33, staging), `describe-alarms-for-metric` (10:34, staging) → none | ✅ |
| nothing in code consumes the alarm | `code: main.tf:186` only; `outputs.tf:1-19` | n/a | ✅ |
| drift | n/a | `live: terraform plan -refresh-only` prod (10:17), staging (10:32) → no changes | ✅ none |
| behaviour of the change | `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html (2026-11-09)`: an update replaces the alarm's earlier settings and its state is evaluated again; putting the earlier threshold back restores the earlier behaviour | `plan: update in-place` (10:56) | ✅ |

Drift rows: 0. Unverified rows: 0. Operator-stated, not verified by a read: delivery model, `iac-change.4=recent`, and the staging CPU figure in the exception justification ("one task at about 12 percent CPU").

## Change Plan

**Phase 1 of 1: raise the prod CPU alarm threshold from 80 to 90** (approved at `[F2]`, 10:43)
- Files: `envs/prod.tfvars` (line 17, `cpu_alarm_threshold = 80` → `90`).
- Resources affected: `aws_cloudwatch_metric_alarm.paymentapi_cpu_high[0]` changed in place (`threshold`, `alarm_description`). Nothing added or destroyed.
- Blast radius: one alarm in one account and region; notifies one SNS topic with two email subscribers; nothing references it besides its own definition.
- Disruption: `none` (`docs: PutMetricAlarm (2026-11-09)`; confirmed `plan: update in-place` at 4a).
- Rollback path: revert the tfvars line and plan and apply through the same CI path. Reversible (`docs: PutMetricAlarm (2026-11-09)`). `untested`.
- Evidence: the rows above.
- Success criteria:
  - SC1 `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1 --query 'MetricAlarms[].{threshold:Threshold,desc:AlarmDescription,enabled:ActionsEnabled,state:StateValue}'` → `threshold 90.0`, `desc "CPU utilization above 90% for paymentapi prod"`, `enabled true`, `state OK`
  - SC2 `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1` → one alarm, `Threshold 90.0`, `ActionsEnabled true`
  - SC3 `terraform plan -var-file=envs/prod.tfvars` → `No changes.`

Execution path: PR. Staging-first (H7): exception (b) prod-only, evidence `code:` and `live:` as in the Staging-first line above; observation window: n/a (no staging phase). Branch: `iac-change/paymentapi-raise-cpu-alarm-threshold` from `origin/main` @ `a1b2c3d`. Drift (H4): none. L2 answers (`[F2]`, 10:43): Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, iac-change.1=yes, iac-change.2=PR and CI applies on merge (operator-stated), iac-change.3=no, iac-change.4=recent.

## Execution Log

### Phase 1 — staging: not applied (exception (prod-only))
- Files changed: none
- Self-check: n/a
- Fresh eyes: n/a
- Plan output summary: not run — no staging phase under exception (prod-only); staging has nothing to apply (`code: envs/staging.tfvars:1-14`, `variables.tf:77`, `main.tf:187`; `live:` no alarm, 10:33, 10:34)
- Plan hash: n/a
- Parity check: n/a
- Pre-flight verdict: n/a
- Execution: not applied — exception (prod-only)
- Verification: n/a

### Phase 1 — prod
- Files changed: `envs/prod.tfvars`
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 1 to change, 0 to destroy (`aws_cloudwatch_metric_alarm.paymentapi_cpu_high[0]` update in place: `threshold` 80 → 90, `alarm_description` "above 80%" → "above 90%")
- Plan hash: `sha256:a064ec4b3620da485122e4d49f64ae579797abc4bc9577a7f170869d85a3bd73`
- Parity check: n/a
- Pre-flight verdict: YELLOW — acknowledged at `[F4]`, 11:09 (operator). Yellow: category 10 resource health (CPU `Maximum` 74.0 percent above the 70 percent default in the last hour; 4 alarm episodes in 7 days at 85 to 88 percent). Mitigation committed (operator action): after the CI apply, run SC1 and SC2 and watch CPU `Average` over the next business day.
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142 opened 11:12 from `iac-change/paymentapi-raise-cpu-alarm-threshold` (commit `7f3a9c1`, `paymentapi: raise prod CPU alarm threshold from 80 to 90`); only `envs/prod.tfvars` staged; a CI pipeline applies on merge (operator-stated)
- Verification: not run — the apply has not landed. SC1, SC2 and SC3 are pending until the operator says the apply has landed.

## Outcome
completed (PR opened; apply pending — see Applied)

**Applied:** staging no — not applied (exception (prod-only): nothing to apply in staging); prod no — PR open

## Ticket Reference
none
