Path the skill would write: `.culiops/iac-change-execution/paymentapi-exports-team-tag-20261109-1158.md`

**IaC change execution for:** `paymentapi` / `none (single environment: prod)`
**Change:** Change the `team` tag on the paymentapi-exports bucket in prod from `payments` to `platform`
**Date:** `2026-11-09 11:58`
**Commit:** `7f3a9c1`
**IaC tool(s):** Terraform (AWS provider ~> 5.0, `code: providers.tf:2-8`)
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/paymentapi-exports-team-tag-20261109-1131.md` (invoked inline, verdict: RED — soft block)
**Prerequisites (`examples/aws.md`):** AWS CLI v2 (`aws-cli/2.17.21`); authentication through the assumed role `paymentapi-operator` (checked with `aws sts get-caller-identity`); read-only tier for Steps 1 and 5; no elevated tier was used (PR path, the skill ran no apply); CloudWatch `GetMetricStatistics` calls were made by pre-flight L3 (3 calls) and carry a small charge.

## Research Summary

- Catalog used: none (no `.culiops/service-discovery/` in the repo); service-discovery was suggested.
- Duplicate check: **not done**. `team = "platform"` is not in the code (`git grep`, 10:03); no commit added or removed `platform` or `paymentapi-exports` (`git log -S`, 10:05, 10:06); no branch (10:07); no open PR (10:08).
- Delivery model: CI applies on merge (`operator-stated`; nothing in the repo shows it: no CI config, no GitOps object, no PR automation marker, no backend block).
- Env selection: `-var-file=envs/prod.tfvars` (`code: variables.tf:1-14`, `code: envs/prod.tfvars:1-3`, `code: providers.tf:12-16`). No workspace or backend key in code.
- Target check: `aws sts get-caller-identity` → account `333333333333`, `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator`; region `ap-southeast-1` (`envs/prod.tfvars:2`); match with `allowed_account_ids` (`envs/prod.tfvars:3`). Re-checked at 4a (10:47) and by pre-flight L3 (11:15).
- Key findings: the `team` tag is read by IAM. Policy `paymentapi-team-bucket-read-prod` allows `s3:GetObject` and `s3:ListBucket` where `aws:ResourceTag/team` = `payments` (`code: main.tf:58-77`) and is attached only to role `paymentapi-engineers-prod` (`code: main.tf:85-88`). After the change that role no longer matches on this bucket. No drift (`terraform plan -refresh-only` → No changes). Staging: the repo has one env file (prod); no other environment exists to apply first.

## Evidence

| # | Fact | Code evidence | Live evidence | Match? |
|---|------|---------------|---------------|--------|
| 1 | `paymentapi-exports-prod` `team` tag | `code: main.tf:15` → `payments` | `live: aws s3api get-bucket-tagging` (10:22) → `team=payments` | ✅ |
| 2 | Policy `paymentapi-team-bucket-read-prod` | `code: main.tf:58-77` → Allow `s3:GetObject`, `s3:ListBucket`, `Resource *`, Condition `aws:ResourceTag/team` = `payments` | `live: aws iam get-policy-version v1` (10:24) → same | ✅ |
| 3 | Who holds that policy | `code: main.tf:85-88` → role `paymentapi-engineers-prod` | `live: aws iam list-entities-for-policy` (10:25) → 1 role, 0 users, 0 groups | ✅ |
| 4 | Stack matches its code | `code: main.tf` | `live: terraform plan -refresh-only -var-file=envs/prod.tfvars` (10:26) → No changes | ✅ no drift |
| 5 | Target account | `code: envs/prod.tfvars:3`, `code: providers.tf:14-16` → 333333333333 | `live: aws sts get-caller-identity` (10:21) → 333333333333 | ✅ |
| 6 | Other grants on the bucket (bucket policy, other roles' tag-keyed policies, grants keyed on `team=platform`) | `code: none` in this repo | not read | `UNVERIFIED` |

Drift rows: 0. Unverified rows: 1 (row 6). Behaviour claim: `docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html` (read 2026-11-09): changing the tag on the resource changes whether a policy using `aws:ResourceTag/tag-key` allows the request.

## Change Plan

**Phase 1 of 1: Change the `team` tag on the exports bucket from `payments` to `platform`**
- Files: `main.tf` (line 15)
- Resources affected: change `aws_s3_bucket.exports` (`tags`, `tags_all`, in place). `aws_iam_policy.team_bucket_read` is not touched.
- Blast radius: the tag is read by IAM. The role `paymentapi-engineers-prod` loses read access to `paymentapi-exports-prod` once the tag is `platform` (`docs`, `code`, `live` as in the table). Any policy keyed on `team=platform` would start to match. Other grants on the bucket are `UNVERIFIED` (row 6).
- Disruption: bucket and data path none expected (tag-only edit, `code: main.tf:12-17`), confirmed in-place by `plan: aws_s3_bucket.exports update in-place` at 4a. Access: the payments engineers role loses read until a policy grants it again.
- Rollback path: reversible, `untested`. Revert the commit through a PR; CI applies on merge; the policy matches again.
- Evidence: rows 1 to 5; row 6 `UNVERIFIED`.
- Success criteria:
  1. `aws s3api get-bucket-tagging --bucket paymentapi-exports-prod` → `team` = `platform`, `Service` and `Environment` unchanged
  2. `terraform plan -var-file=envs/prod.tfvars` → `No changes.`
  3. `aws cloudwatch describe-alarms --state-value ALARM --alarm-name-prefix paymentapi-exports` → `MetricAlarms: []`

Execution path: PR (the only one offered: CI applies on merge). Branch: `iac-change/paymentapi-exports-team-tag-platform` from `origin/main` @ `a1b2c3d`.

## Execution Log

### Phase 1: Change the `team` tag on the exports bucket from `payments` to `platform`
- Files changed: `main.tf`
- Self-check: plan 6/6 · diff 6/6, no accepted failures
- Fresh eyes: not run — dry run
- Plan output summary: 0 to add, 1 to change, 0 to destroy (`aws_s3_bucket.exports`, `tags` and `tags_all`, update in-place)
- Plan hash: `sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a`
- Pre-flight verdict: RED — soft block (compound risk: 🟡 1 Blast radius, 4 Dependency impact, 7 Observability readiness, 9 Security posture; ⚪ 11 Application compatibility). Acknowledged by the operator, reason: "ownership move approved by the platform team; the policy is updated in a separate ticket"
- Execution: PR https://github.com/acme/paymentapi-infra/pull/142, branch `iac-change/paymentapi-exports-team-tag-platform`, commit `7f3a9c1` ("paymentapi: set exports bucket team tag to platform"). CI applies on merge (`operator-stated`); not merged at the time of this record.
- Verification: not run. The apply has not landed, so none of the three success-criteria commands has an output captured after an apply. No re-plan (that belongs to the direct apply path).

## Outcome

completed — PR opened (Phase 1 of 1). The change is not applied.

**Applied:** no — PR open

## Ticket Reference

none
