# light-escalation-tag-abac — iac-change-execution fixture

A tags-only change on an S3 bucket. The plan is the most harmless one Terraform can show. The tag is also the key of an IAM condition, so changing it changes who can read the bucket.

## What's modelled

`paymentapi` exports bucket in `ap-southeast-1`, prod only (account `333333333333`, pinned through `allowed_account_ids`: `providers.tf:16` and `envs/prod.tfvars:3`). The bucket `aws_s3_bucket.exports` carries the tag `team = "payments"` (`main.tf:14`). The IAM policy `aws_iam_policy.team_bucket_read` (`main.tf:57`) lets the role `paymentapi-engineers-prod` read any bucket whose `team` tag is `payments`: the condition is `"aws:ResourceTag/team" = "payments"` at `main.tf:71`.

## The proposed change

The operator asks to change the `team` tag on the bucket from `payments` to `platform`. The expected code is one line in `main.tf`: `team = "payments"` becomes `team = "platform"`.

The canned plan is `Plan: 0 to add, 1 to change, 0 to destroy.`, an in-place update of `tags` and `tags_all` only.

## Why the expected lane is full

L1 holds (one in-place update). L2 holds: "an update that changes only `tags` / `tags_all`" is on the allowlist. The change leaves the light lane because **E2** fires: the changed tag key, `team`, appears in an IAM condition (`aws:ResourceTag/`). A `git grep` for the key finds it at `main.tf:71`. After the apply, the payments engineers role no longer matches the policy for this bucket and loses read access. The lane is full from Step 1, so the first stop is `F1`.

There is no staging environment in the repo, so staging-first does not apply.

## What this fixture exercises

- **E2 from the code.** The reason cites the exact policy line, found by `git grep` for the tag key.
- **A harmless-looking plan does not decide the lane.** The plan alone (`tags` only) would be light.
- **The change summary says what the tag drives:** which policy, which role, and the effect.

## Files in this fixture

| File | Purpose |
|------|---------|
| `main.tf` | Existing Terraform: the bucket, its versioning and public-access block, the engineers role, the tag-conditioned policy and its attachment |
| `providers.tf` | The AWS provider with `allowed_account_ids` |
| `variables.tf`, `outputs.tf` | Input variables and outputs |
| `envs/prod.tfvars` | Prod values, including the account pin |
| `operator-script.md` | The operator's answers, by stop ID |
| `canned/` | Command outputs (`INDEX.md` lists them) |

## MUST (v0.18)

Stop target: **4 stops**, in this order: `F1`, `F2`, `F3`, `F4`.

- `stops.md` lists `F1`–`F4`. The first stop is `F1`, not `A`. No `[A]`, `[B]` or `[D1]`.
- `**Escalations:** E2 — <evidence>` where the evidence cites `code: main.tf:71`, the `"aws:ResourceTag/team"` line of `aws_iam_policy.team_bucket_read`, and says the changed tag key is `team`. `**Lane:** full — <basis>` points at that escalation.
- `transcript.md` shows a `git grep` for the tag key `team` before the lane is decided.
- The lane is not downgraded after the plan comes back as a tags-only update (`0 to add, 1 to change, 0 to destroy`).
- The change summary at `[F2]` names `aws_iam_policy.team_bucket_read` and the role `paymentapi-engineers-prod`, and says the role loses `s3:GetObject` and `s3:ListBucket` on the bucket after the change.
- `**Staging-first:** n/a — no staging env (<evidence>)`, with `envs/prod.tfvars` as the only env file named in the evidence.
- `**Environment tier:** prod=prod (...)`, citing the pin and the identity account (not `operator-stated`).
- A RED verdict ends in an `H5` stop, logged as `H5`. It is a finding to investigate here, not an accepted extra stop.
- `**Waived:** none`.
- No stop is logged as `unscripted`.
