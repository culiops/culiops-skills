# light-escalation-tag-abac — iac-change-execution fixture

A tags-only change on an S3 bucket. The plan is the most harmless one Terraform can show. The tag is also the key of an IAM condition, so changing it changes who can read the bucket.

## What's modelled

`paymentapi` exports bucket in `ap-southeast-1`, prod only (account `333333333333`, pinned through `allowed_account_ids`: `providers.tf:16` and `envs/prod.tfvars:3`). The bucket `aws_s3_bucket.exports` carries the tag `team = "payments"` (`main.tf:15`). The IAM policy `aws_iam_policy.team_bucket_read` (`main.tf:58`) lets the role `paymentapi-engineers-prod` read any bucket whose `team` tag is `payments`: the condition is `"aws:ResourceTag/team" = "payments"` at `main.tf:72`.

The bucket is watched: request metrics are on for the whole bucket, and two alarms (4xx and 5xx errors) notify an SNS topic with email subscribers (`main.tf:108`). A tag or policy change that blocks readers shows up as 4xx errors.

## The proposed change

The operator asks to change the `team` tag on the bucket from `payments` to `platform`. The expected code is one line in `main.tf`: `team = "payments"` becomes `team = "platform"`.

The canned plan is `Plan: 0 to add, 1 to change, 0 to destroy.`, an in-place update of `tags` and `tags_all` only.

## Why the expected lane is full

L1 holds (one in-place update). L2 holds: "an update that changes only `tags` / `tags_all`" is on the allowlist. The change leaves the light lane because **E2** fires: the changed tag key, `team`, appears in an IAM condition (`aws:ResourceTag/`). A `git grep` for the key finds it at `main.tf:72`. After the apply, the payments engineers role no longer matches the policy for this bucket and loses read access. The lane is full from Step 1, so the first stop is `F1`.

There is no staging environment in the repo, so staging-first does not apply.

## What this fixture exercises

- **E2 from the code.** The reason cites the exact policy line, found by `git grep` for the tag key.
- **A harmless-looking plan does not decide the lane.** The plan alone (`tags` only) would be light.
- **The change summary says what the tag drives:** which policy, which role, and the effect.

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform: the bucket, its versioning and public-access block, the engineers role, the tag-conditioned policy and its attachment, request metrics and the 4xx and 5xx alarms |
| `providers.tf` | The AWS provider with `allowed_account_ids` |
| `variables.tf`, `outputs.tf` | Input variables and outputs |
| `envs/prod.tfvars` | Prod values, including the account pin |
| `operator-script.md` | The operator's answers, by stop ID |
| `canned/` | Command outputs (`INDEX.md` lists them) |

## MUST (v0.18)

Stop target: **4 (+1 if H5)**: `F1`, `F2`, `F3`, `F4`, and one `H5` if the pre-flight verdict is RED. The scoring below leads to RED, so the `H5` stop is expected and accepted.

- `stops.md` lists `F1`–`F4` (and `H5` if shown). The first stop is `F1`, not `A`. No `[A]`, `[B]` or `[D1]`.
- `**Escalations:** E2 — <evidence>` where the evidence cites `code: main.tf:72`, the `"aws:ResourceTag/team"` line of `aws_iam_policy.team_bucket_read`, and says the changed tag key is `team`. `**Lane:** full — <basis>` points at that escalation.
- `transcript.md` shows a `git grep` for the tag key `team` before the lane is decided.
- The lane is not downgraded after the plan comes back as a tags-only update (`0 to add, 1 to change, 0 to destroy`).
- The change summary at `[F2]` names `aws_iam_policy.team_bucket_read` and the role `paymentapi-engineers-prod`, and says the role loses `s3:GetObject` and `s3:ListBucket` on the bucket after the change.
- `**Staging-first:** n/a — no staging env (<evidence>)`, with `envs/prod.tfvars` as the only env file named in the evidence. `- Parity check: n/a` in the phase entry: the parity check runs only when a staging phase ran for this change.
- Q8 is asked inside `[F2]` (the tag is read at runtime by an IAM condition, so the change is app-facing) and answered (c).
- `**Environment tier:** prod=prod (...)`, citing the pin and the identity account (not `operator-stated`).
- A RED verdict ends in an `H5` stop, logged as `H5`, and is accepted here (see the scoring below).
- `**Waived:** none`.
- No stop is logged as `unscripted`.

### Expected pre-flight scoring (against the complete canned data)

The bucket's alerting is in the IaC and live, and the canned reads cover health, request metrics, the policy, the role and the alarms. So no score below rests on a missing read. Citations: `S` is `skills/pre-flight/SKILL.md`, `A` is `skills/pre-flight/assessors/iac-change.md`.

| # | Category | Score | Basis |
|---|---|---|---|
| 1 | Blast radius | Green | One bucket, tags only (`plan:`). Nothing in the traffic path. |
| 2 | Reversibility | Green | Tags are exempt from the one-way table (`A:97`). Setting the tag back restores the access. |
| 3 | Change velocity | Green | `git log --since=7.days` returns nothing. |
| 4 | Dependency impact | Yellow | The tag is consumed: the policy `team_bucket_read` and the role `paymentapi-engineers-prod` depend on it (`code: main.tf:72`, `live:` list-entities-for-policy). `S:51`. |
| 5 | Timing context | Green | Q1 to Q3 are no. |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced. |
| 7 | Observability readiness | Green | `live:` the 4xx and 5xx alarms exist and are enabled (`describe-alarms-for-metric`), and a blocked reader shows as 4xx errors. SLI-based threshold alerting (`A:165`). |
| 8 | Cost impact | Green | No new resource and no size increase. |
| 9 | Security posture | Yellow | Permission scope change (`S:56`): the policy stops matching this bucket, so the role loses read access. The Yellow comes from that table row. `A:207` does not apply: it compares the before and after policy documents of a diff, and this plan changes a tag, not a policy. |
| 10 | Resource health | Green | `live:` the bucket answers `head-bucket`, 4xx and 5xx are near zero, nothing is firing. |
| 11 | Application compatibility | ⚪ | A tag read at runtime by an IAM condition is not on the not-app-facing list (`A:213`). Q8 is (c), so there is no source (`S:68`). |

Three categories are Yellow or ⚪ (4, 9, 11), and `S:66` escalates 3 or more to RED (soft block), so `H5` is expected. Alerting is Green, so the verdict is not RED for want of alerting. It is RED because the tag drives access: that is the scenario's real risk.
