Execution record written by the dry run. Intended path under the output root: `.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1117.md`. Left uncommitted.

**IaC change execution for:** `paymentapi` / `prod`
**Change:** `Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one: paymentapi-cpu-low-prod, below 20% for 3 x 300 s (Average), actions: alerts SNS topic + scale-in policy`
**Date:** `2026-11-09 11:17` (+07:00)
**Commit:** `7f3a9c1`
**IaC tool(s):** `Terraform (hashicorp/aws ~> 5.0, v5.74.0)`
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1107.md` (invoked inline — verdict: RED — soft block)
**Lane:** full — E1 escalation recorded at Step 1 (Lane rule line 1); one prod target, no dev tier to prove
**Escalations:** E1 — `alarm_actions[1]` is `aws_appautoscaling_policy.paymentapi_scale_in.arn`, an Application Auto Scaling policy, not an SNS topic. Evidence: `code: main.tf:250-253` (the CPU-high alarm this one is "wired like" carries the scale-out policy), `code: main.tf:213` (the scale-in policy), `code: main.tf:280-283` (the new alarm's `alarm_actions` in the working tree), `plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_low alarm_actions[1] = arn:aws:autoscaling:ap-southeast-1:333333333333:scalingPolicy:...:policyName/paymentapi-scale-in-prod` (4a, 2026-11-09 10:57)
**Environment tier:** `prod=prod` (live: `aws sts get-caller-identity` 2026-11-09 10:01 and 10:56 → account `333333333333`, `assumed-role/paymentapi-operator`; code: `envs/prod.tfvars:3` pins `aws_account_id = "333333333333"`, set as `allowed_account_ids` at `providers.tf:16`). It is the only environment the repo defines.
**Staging-first:** n/a — no staging env (code: `envs/` holds only `prod.tfvars`; no staging var-file, workspace or overlay is defined)
**Waived:** none

## Research Summary

- Catalog: none — `.culiops/service-discovery/paymentapi.md` does not exist; the run proceeded without it.
- Duplicate check: **not done.** `code:` no hits for `paymentapi-cpu-low` or `cpu_low` (`git grep`, 10:03-10:04); `git:` no commit added or removed either identifier (`git log -S`, 10:05-10:06); no branch matching `*cpu-low*` (10:07); no open PR for `cpu-low` (10:08); `live:` the alarm does not exist in prod (`describe-alarms --alarm-names paymentapi-cpu-low-prod`, 10:29). The scale-in policy already exists with no alarm (`code: main.tf:212-230`, `live: describe-scaling-policies` 10:32).
- Delivery model: `UNVERIFIED` in the repo (no CI config, controller object or backend). `operator-stated` at `[F2]` (10:44): PR, and a CI pipeline applies on merge. So PR path only.
- Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1`, `providers.tf:12-17`); default workspace (`operator-stated`, `iac-change.3`).
- Target check: identity read first (10:01), re-read before the plan (10:56) and by pre-flight (11:00): account `333333333333`, matches the pin. No `[H1]`.
- Read batch: 23 commands approved at `[F1]` (10:13), run 10:14-10:36. Drift check `terraform plan -refresh-only`: no changes.
- Key findings: CPU-high is live as in code (70 %, 3 x 300 s, actions SNS + scale-out). The scale-in policy (-1, cooldown 300) has no alarm today. Scalable target min 2, max 6. Service 3 of 3 tasks running and healthy, nothing firing, CPU 37-43 %. The alerts topic has two email subscribers.
- Open items carried into the run: how ECS drains in-flight requests when scale-in stops a task is `UNVERIFIED` (documentation lookup returned no canned output); no application source (Q8 = (c)).

## Evidence

| Fact | Code evidence | Live evidence | Match |
|------|---------------|---------------|-------|
| CPU-high alarm: 70 %, 3 x 300 s, Average, actions SNS + scale-out, enabled | `code: main.tf:234-260` | `live: describe-alarms --alarm-names paymentapi-cpu-high-prod` (10:28) same | match |
| `paymentapi-cpu-low-prod` does not exist | `code: none` | `live: describe-alarms --alarm-names paymentapi-cpu-low-prod` (10:29) `[]` | match |
| Scale-in policy exists, -1, cooldown 300, no alarm | `code: main.tf:213-230` | `live: describe-scaling-policies` (10:32) `Alarms: []` | match |
| Scale-out policy driven by CPU-high | `code: main.tf:193-210, 252` | `live: describe-scaling-policies` (10:32) | match |
| Scalable target min 2, max 6 | `code: main.tf:189-190` | `live: describe-scalable-targets` (10:31) | match |
| Desired count 3, not pinned by Terraform | `code: envs/prod.tfvars:11`, `main.tf:93-95` | `live: describe-services` (10:16) desired 3, running 3 | match |
| Alerts topic: email subscribers only | `code: main.tf:174-181` | `live: list-subscriptions-by-topic` protocols (10:34) email, email | match |
| No drift | n/a | `live: terraform plan -refresh-only` (10:15) No changes | match |
| Delivery model | `code: none` | n/a | UNVERIFIED (operator-stated) |
| In-flight request handling when scale-in stops a task | `code: none` | n/a | UNVERIFIED (no docs read) |

Drift rows: none. Unverified rows: 2.

## Change Plan

Approved at `[F2]` (2026-11-09 10:44), with the alarm values the operator gave there.

**Phase 1 of 1: Add the CPU-low alarm**
- Files: `main.tf` (one new resource after the CPU-high alarm)
- Resources affected: `+ create aws_cloudwatch_metric_alarm.paymentapi_cpu_low` (`paymentapi-cpu-low-prod`, `AWS/ECS` `CPUUtilization`, `LessThanThreshold` 20, 3 x 300 s Average, same dimensions and tags as CPU-high; `alarm_actions` = alerts SNS topic + `paymentapi_scale_in` policy, `ok_actions` = alerts SNS topic). 0 changed, 0 destroyed.
- Blast radius: one new alarm. It is the first to drive `paymentapi-scale-in-prod`: one task per 300 s cooldown, never below `min_capacity` 2 (`live: 3 running, 3 healthy`). `docs: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html (2026-11-09)`.
- Disruption: applying it, `none` (create only). After it exists, a breach reduces capacity by one task at a time down to 2; in-flight request handling on the stopped task is `UNVERIFIED`.
- Rollback path: reversible; `git revert`, plan, apply through the same path. Does not undo a scale-in that already ran (Terraform does not own the count, `code: main.tf:93-95`). `untested`.
- Evidence: the Evidence table rows above.
- Success criteria: (1) `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-low-prod ...` → one alarm, enabled, threshold 20, 3 periods, actions = alerts topic + scale-in policy, state `OK` or `INSUFFICIENT_DATA`; (2) `aws cloudwatch describe-alarms-for-metric ... CPUUtilization ...` → CPU-high and CPU-low; (3) `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi ...` → both alarms, none in `ALARM`; (4) `aws ecs describe-services ...` → desired 3, running 3, pending 0; (5) `terraform plan -var-file=envs/prod.tfvars` → `No changes.`

**Execution path:** PR (the operator stated that CI applies on merge, so no direct apply). **Staging-first (H7):** (a) no staging env. **Branch:** `iac-change/paymentapi-cpu-low-alarm` from `origin/main` @ `a1b2c3d`.

## Execution Log

### Phase 1: Add the CPU-low alarm (prod)
- Files changed: `main.tf` (+30 lines)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: skipped — add-only, no sensitive types
- Plan output summary: 1 to add, 0 to change, 0 to destroy
- Plan hash: `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0`
- Parity check: n/a
- Pre-flight verdict: RED — soft block (Blast radius YELLOW, Observability readiness YELLOW, Application compatibility UNKNOWN). Acknowledged at `[H5]` by the operator, 2026-11-09 11:07, reason: "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged". Mitigations committed: none (a reason was given, no commitment). The verdict was shown again at `[F4]`.
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142, branch `iac-change/paymentapi-cpu-low-alarm`, commit `7f3a9c1`, approved at `[F4]` 2026-11-09 11:14, opened 11:17. The operator skipped the optional heads-up line.
- Verification: not run. The CI pipeline applies on merge and the apply has not landed, so there is no success-criteria output and no re-plan.

## Outcome

completed (Phase 1 of 1 delivered as an open PR; applying is left to the CI pipeline after merge)

**Applied:** no — PR open

## Ticket Reference

none
