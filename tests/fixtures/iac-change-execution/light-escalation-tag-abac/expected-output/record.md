(Would be written to `.culiops/iac-change-execution/paymentapi-exports-team-tag-20261109-1119.md`. Left uncommitted.)

**IaC change execution for:** `paymentapi` / `exports`
**Change:** change the `team` tag on the `paymentapi-exports` bucket in prod from `payments` to `platform`
**Date:** `2026-11-09 11:19`
**Commit:** `7f3a9c1`
**IaC tool(s):** Terraform (AWS provider `~> 5.0`, v5.74.0; Terraform v1.9.8)
**Prerequisites (`examples/aws.md`):** AWS CLI aws-cli/2.17.21 (>= 2.x); credentials `assumed-role/paymentapi-operator` used for read-only reads and the plan; the skill performs no mutation on this path (a CI pipeline applies on merge, operator-stated)
**Execution path:** PR
**Pre-flight record:** invoked inline — verdict: RED — soft block (`.culiops/pre-flight/paymentapi-exports-team-tag-20261109-1109.md`)
**Lane:** full — the light allowlist matched (tag-only in-place update on an `aws_*` type) but E2 and E3 hit; Lane rule line 1
**Escalations:** E2 — `code: main.tf:72` has the IAM condition `aws:ResourceTag/team = "payments"` in `aws_iam_policy.team_bucket_read`; `main.tf:4` and `main.tf:60` describe tag-driven access on this key; changed key `team`
**Escalations:** E3 — the changed tag value is read by `aws_iam_policy.team_bucket_read` (`code: main.tf:72`), attached to role `paymentapi-engineers-prod` (`code: main.tf:85-88`; `live: aws iam list-entities-for-policy`, 10:25)
**Environment tier:** prod=prod (`live: aws sts get-caller-identity` 10:01 and 10:58 -> account 333333333333 = `code: providers.tf:16` `allowed_account_ids` / `envs/prod.tfvars:3`; the name `prod` is not the proof; no dev tier claimed; no staging env)
**Staging-first:** n/a — no staging env (`code: envs/` holds only `prod.tfvars`; the repo defines no other environment)
**Waived:** none

## Research Summary
- Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset).
- Catalog: none (`.culiops/service-discovery/` has no entry; service-discovery suggested).
- Duplicate check: not done. `code: main.tf:15` = `payments`; `git grep -F 'platform'` -> no hits (10:06); `git log --all -S'platform'` -> none (10:08); no in-flight branch (10:09); no open PR (10:10, `gh pr list`).
- Delivery model: `UNVERIFIED` in the repo (no CI, GitOps or Atlantis config found); `operator-stated` at `[F2]`: a PR, and a CI pipeline applies on merge. Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars`), default workspace (`operator-stated`); no backend block in code.
- Target check: `aws sts get-caller-identity` -> account 333333333333, `assumed-role/paymentapi-operator`, region `ap-southeast-1` (`code: envs/prod.tfvars:2`); re-checked at 4a (10:58): same.
- Key findings: the tag is read by an IAM condition (`main.tf:72`), so the lane is full; after the change the policy matches nothing and the payments engineers role loses read on the bucket, which the operator confirmed is intended (ownership moves to the platform team; a separate ticket updates the policy). Refresh-only plan: no drift. Nothing firing; 4xx max 2 and 5xx 0 per 5 min.
- Read batch at `[F1]` approved in full (20 reads plus the identity read); success-criteria reads approved at `[F2]`; plan command approved at `[F3]`.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| Bucket `team` tag | `code: main.tf:15` -> `payments` | `live: aws s3api get-bucket-tagging` (10:21) -> `team=payments` | match |
| Bucket exists in `ap-southeast-1` | `code: main.tf:10`, `envs/prod.tfvars:2` | `live: aws s3api head-bucket` (10:22) | match |
| Policy keyed on the tag | `code: main.tf:62-77`, condition `main.tf:72` | `live: aws iam get-policy-version` (10:24) | match |
| Policy holders | `code: main.tf:85-88` | `live: aws iam list-entities-for-policy` (10:25) -> role `paymentapi-engineers-prod` only; `live: aws iam list-attached-role-policies` (10:26) | match |
| Other resources with `team` | `code: main.tf:15` only | `live: aws resourcegroupstaggingapi get-resources` (10:27) -> this bucket only | match |
| Alarms on the bucket | `code: main.tf:108-132`, `134-158` | `live: aws cloudwatch describe-alarms-for-metric` (10:30, 10:31) -> enabled, OK; history empty (10:32, 10:33) | match |
| Request metrics | `code: main.tf:94-97` | `live: aws s3api list-bucket-metrics-configurations` (10:34) -> `EntireBucket` | match |
| Health baseline | none | `live: describe-alarms --state-value ALARM` (10:28) none; 4xx max 2, 5xx 0 per 5 min (10:35, 10:36); AllRequests 380-467 per 5 min, 1.0x baseline (10:37, 10:38) | no drift |
| Drift | none | `live: terraform plan -refresh-only` (10:20) -> No changes | no drift |
| Delivery model | `code: none` | none | UNVERIFIED (operator-stated at `[F2]`) |
| `platform`-keyed principals outside this repo | `code: none` | none | UNVERIFIED |
| Last successful apply | `code: none` (no backend, no CI config) | none | UNVERIFIED (operator-stated "recent") |

Drift rows: 0. Unverified rows: 3.

## Change Plan

**Phase 1 of 1: change the bucket's `team` tag to `platform` (prod)**
- Files: `main.tf` (line 15, `team = "payments"` -> `team = "platform"`)
- Resources affected: `aws_s3_bucket.exports` (`paymentapi-exports-prod`) update in place, `tags` and `tags_all` only. Not in this change: `aws_iam_policy.team_bucket_read` (condition `main.tf:72` stays `payments`).
- Blast radius: one bucket, one region (`code: main.tf:9-17`). Through the tag: the policy `paymentapi-team-bucket-read-prod` grants nothing afterwards (this bucket is the only resource with the key, `live:` 10:27), and its only holder, `paymentapi-engineers-prod`, loses `s3:GetObject` and `s3:ListBucket` on the bucket. Inline policies on the role were not read.
- Disruption: bucket none (`plan:` in place, confirmed at 4a); readers: the role is denied reads from the apply (`docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html`, read 2026-11-09). The apply happens at merge.
- Rollback path: `git revert` of the PR, plan, apply through the same reviewed path; re-tagging `payments` makes the policy match again (`docs:` as above). Reversible, untested. If the policy has been changed to `platform` meanwhile, reverting the tag alone does not restore the old access.
- Evidence: the rows above.
- Success criteria: (1) `aws s3api get-bucket-tagging --bucket paymentapi-exports-prod` -> `team = platform`, `Service` and `Environment` unchanged; (2) `terraform plan -var-file=envs/prod.tfvars` -> `No changes.`; (3) `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` -> both alarms `OK`, `ActionsEnabled` true; (4) `aws cloudwatch get-metric-statistics` for `4xxErrors` and `5xxErrors` 15 min after the apply -> Sum per 5 min below 25 and 5 (before: max 2 and 0)

**Execution path:** PR. **Staging-first (H7):** (a) no staging env. **Observation window:** n/a. **Branch:** `main` -> `iac-change/paymentapi-exports-team-tag-platform` from `origin/main` @ `a1b2c3d`. **Self-check:** 8/8 pass. **Drift (H4):** none.

## Execution Log
### Phase 1: change the bucket's `team` tag to `platform` (prod)
- Files changed: `main.tf`
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 1 to change, 0 to destroy (`aws_s3_bucket.exports`, `tags` / `tags_all`, `team`)
- Plan hash: `sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a`
- Parity check: n/a
- Pre-flight verdict: RED — soft block (4 Yellow or unknown: dependency impact, observability readiness, security posture, application compatibility), acknowledged at `[H5]`, 2026-11-09 11:09, operator, reason "ownership move approved by the platform team; the policy is updated in a separate ticket". Mitigations committed: none named (offered: a `platform` grant first, post-apply 4xx and CloudTrail check, org policy and SCP search, app-source evidence).
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142, branch `iac-change/paymentapi-exports-team-tag-platform`, commit `7f3a9c1` ("exports: move the bucket team tag from payments to platform"), opened at `[F4]` (approved 11:16). The merge is applied by a CI pipeline (operator-stated).
- Verification: not run — the apply has not landed. The success criteria above run once the operator says it has.

## Outcome
completed for this run (PR opened; the change is not applied yet)

**Applied:** no — PR open

## Ticket Reference
none
