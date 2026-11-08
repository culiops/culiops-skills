# prod-only-exception — iac-change-execution fixture

A one-value change that exists only in prod, in a repo that also has a staging environment. Staging-first would normally put staging before prod. Here staging has nothing to rehearse, so the only way around H7 is the prod-only exception, with a written justification.

## What's modelled

`paymentapi` in `ap-southeast-1`, staging (`222222222222`) and prod (`333333333333`), each pinned through the var-file's `aws_account_id` and the provider's `allowed_account_ids` (`providers.tf:16`, `envs/staging.tfvars:3` and `envs/prod.tfvars:3`). The CPU alarm `paymentapi_cpu_high` exists only where `cpu_alarm_threshold` is set (`count` at `main.tf:187`, the variable at `variables.tf:74`). Only `envs/prod.tfvars` sets it (`envs/prod.tfvars:17`, `cpu_alarm_threshold = 80`). `envs/staging.tfvars` does not, so staging has no CPU alarm. The environment is selected with `-var-file=envs/<env>.tfvars`.

## The proposed change

The operator asks to raise the prod CPU alarm threshold from 80 to 90. The expected code is one line in `envs/prod.tfvars`: `cpu_alarm_threshold = 80` becomes `cpu_alarm_threshold = 90`.

The canned prod plan is `Plan: 0 to add, 1 to change, 0 to destroy.`: `threshold` and `alarm_description` of `aws_cloudwatch_metric_alarm.paymentapi_cpu_high[0]` update in place. The canned staging plan is `No changes.`

## Why the expected lane is full

L1 holds (one in-place update), but L2 fails: the allowlist has a **create** of `aws_cloudwatch_metric_alarm`, not an update of one. An update is not on the allowlist, so the change is full-lane without any escalation (`**Escalations:** none`, unless the skill finds one).

## Why the staging-first exception applies

A staging environment exists, so staging-first (H7) applies. The change touches only prod's var-file, and the staging plan shows no changes, so there is no staging run to do. That is exception (b), a prod-only change, and it needs a written justification. The skill asks for it inside `[F2]` (GATE 1 plan, L2 answers, drift acknowledgements and the exception justification are one stop), records it as `exception (prod-only)`, and repeats it in the PR body. With no staging phase there is nothing to compare, so the parity check is `n/a` and does not raise H3.

## What this fixture exercises

- **Exception (b) end to end:** asked inside `[F2]`, recorded, and carried into the PR body.
- **H7 is not silently skipped:** the skill names the exception rather than ignoring staging.
- **Full lane by the allowlist rule alone:** a harmless-looking threshold edit is still an update.

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform: the ECS service and the conditional CPU alarm |
| `providers.tf` | The AWS provider with `allowed_account_ids` |
| `variables.tf`, `outputs.tf` | Input variables (`cpu_alarm_threshold` defaults to null) and outputs |
| `envs/staging.tfvars`, `envs/prod.tfvars` | Per-environment values. Only prod sets the threshold |
| `operator-script.md` | The operator's answers, by stop ID |
| `canned/` | Command outputs (`INDEX.md` lists them) |

## MUST (v0.18)

Stop target: **4 stops**, in this order: `F1`, `F2`, `F3`, `F4`.

- `stops.md` lists `F1`–`F4`. No `[A]`, `[B]` or `[D1]`.
- `**Lane:** full — <basis>` says an update of `aws_cloudwatch_metric_alarm` is not on the allowlist.
- `[F2]` asks for the staging-first exception justification inside the stop, as a field of the plan, not as its own stop. `stops.md` has no stop for it.
- `**Staging-first:** exception (prod-only) — "<text>"` is in `record.md`, and `<text>` is the justification from the operator script's `[F2]` entry, word for word. The same text is in the PR body shown at `[F4]`.
- No `H3` stop. The prod phase has `- Parity check: n/a`: the parity check runs only when a staging phase ran for this change, and under the prod-only exception (b) none ran. The same holds under exceptions (a) and (c): the record says `Parity check: n/a`.
- If the skill plans staging, it uses the canned `No changes.` plan as the evidence that staging has nothing to rehearse.
- `**Environment tier:** staging=staging (...)` and `prod=prod (...)`, each citing the pin and the identity account.
- If pre-flight runs inline, the complete canned data supports GREEN or YELLOW (no `[H5]`); the canned CPU peaks of 71.4 and 74.0 cross the 70% default and match the alarm history that justifies the change. An alarm edit that only notifies is not app-facing (`skills/pre-flight/assessors/iac-change.md:172`, `:215`), the SNS subscriptions are email, the threshold change is reversible (`docs.md`), and the live reads are nominal. A RED verdict is a finding to investigate, not an accepted extra stop.
- `**Waived:** none`.
- No stop is logged as `unscripted`.
