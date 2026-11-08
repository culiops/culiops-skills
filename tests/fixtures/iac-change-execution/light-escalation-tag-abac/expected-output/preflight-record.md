(Would be written to `.culiops/pre-flight/paymentapi-exports-team-tag-20261109-1109.md`. Left uncommitted: invoked by another skill.)

**Pre-flight assessment for:** `paymentapi` / `exports`
**Action:** change the `team` tag on `aws_s3_bucket.exports` (`paymentapi-exports-prod`) from `payments` to `platform`, one in-place update
**Date:** `2026-11-09 11:09` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `main.tf`)
**Target:** `333333333333 / ap-southeast-1` | `n/a` | `workspace default (operator-stated) / var-file envs/prod.tfvars / backend key: none declared in code`
**Plan hash:** `sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a` (SHA-256 of the exact plan/diff text assessed)
**Plan source:** `terraform show -no-color tfplan` (from `terraform plan -out=tfplan -var-file=envs/prod.tfvars`, 10:59)
**Delivery model:** `CI pipeline applies on merge` (`UNVERIFIED` in the repo, no CI config found; operator-stated at `[F2]`)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live: the caller's reads, pre-flight's own target check and git log)`
**App source:** `not available — category 11 unknown` (Q8 = (c))

## Verdict: RED — SOFT BLOCK

Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset).

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | Green | One resource changes (`aws_s3_bucket.exports`, `tags` and `tags_all` only), one region. Bucket disruption: none. The readers' access effect is scored under 4 and 9, not twice | `plan: aws_s3_bucket.exports will be updated in-place; Plan: 0 to add, 1 to change, 0 to destroy`; `code: main.tf:9-17`; `docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html (2026-11-09)` | — |
| 2 | Reversibility | Green | A tag value, no data change. Rollback: revert the PR, CI applies; re-tagging `payments` makes the policy match again. Rollback is untested; if the policy is later changed to `platform`, reverting the tag alone does not restore the old access | `plan:`; `docs:` (ABAC page above); `assessor:` tags are exempt from the behaviour-claim rule | — |
| 3 | Change velocity | Green | 0 commits to `main.tf` in 7 days, no open PR, no other uncommitted work. Last successful apply: `iac-change.4 = recent`, `operator-stated` (no backend or CI history in the repo) | `git: git log --since=7.days origin/main -- main.tf` -> none (11:03); `git: gh pr list` -> none (10:10); `git status --short` -> only this change's file (11:04) | — |
| 4 | Dependency impact | Yellow | `aws_iam_policy.team_bucket_read` consumes the tag: `s3:GetObject` and `s3:ListBucket` on `*` where `aws:ResourceTag/team = payments`. It is attached to role `paymentapi-engineers-prod` only. This bucket is the only resource with a `team` tag, so after the apply the policy matches nothing and the role loses read on the bucket | `code: main.tf:72`, `main.tf:85-88`; `live: aws iam get-policy-version (caller, 10:24)`; `live: aws iam list-entities-for-policy (caller, 10:25)`; `live: aws iam list-attached-role-policies (caller, 10:26)`; `live: aws resourcegroupstaggingapi get-resources (caller, 10:27)` | Operator action: loss is intended (acknowledged); if the platform team needs access at apply time, ship a `platform` grant first in a separate PR, then re-tag |
| 5 | Timing context | Green | No incident, no freeze, not peak. The apply happens at merge (CI), Monday 10:00 +07:00 in the run clock | `operator` Q1=no, Q2=no, Q3=no (Q3 `operator-stated`); `live: AllRequests (caller, 10:37 and 10:38)` 380-467 per 5 min, 1.0x the baseline | — |
| 6 | Operator familiarity | Green | Changed this service many times; experienced with Terraform | `operator` Q4, Q5 | — |
| 7 | Observability readiness | Yellow | The 4xx and 5xx alarms exist, are enabled and watch this bucket (request metrics `EntireBucket`). They are static count thresholds (25 and 5 per 5 min over 2 periods; 4xx baseline max 2), so a few denied manual reads may not trip them. Whether a denied read counts in `4xxErrors` is `UNVERIFIED` (the code comment at `main.tf:91-92` says so; it is not evidence) | `code: main.tf:94-97`, `main.tf:108-158`; `live: describe-alarms-for-metric (caller, 10:30 and 10:31)`; `live: list-bucket-metrics-configurations (caller, 10:34)`; `live: describe-alarm-history (caller, 10:32 and 10:33)` | Operator action: after the apply run the success criteria, and check the 4xx metric and CloudTrail for denied calls from the role |
| 8 | Cost impact | Green | No new or resized resource; a tag edit changes no billed attribute | `plan:`; `operator-stated` Q6 = negligible | — |
| 9 | Security posture | Yellow | IAM-relevant permission scope change (assessor: IAM). The payments role narrows (full policy document read live). The new value `platform` may match a policy or SCP outside this repo and widen access for other principals: the repo has no hit for `platform`, but `git grep` sees only this repo | `code: main.tf:72`; `live: aws iam get-policy-version (caller, 10:24)`; `git: git grep -F 'platform'` -> no hits (10:06); `UNVERIFIED` for policies and SCPs outside the repo | Operator action: before merge, search the account's customer-managed policies and org SCPs for `aws:ResourceTag/team` with `platform` |
| 10 | Resource health | Green | Nothing firing; 4xx max 2 and 5xx 0 per 5 min; both alarms `OK`; no alarm state change in 24 h | `live: describe-alarms --state-value ALARM (caller, 10:28)`; `live: get-metric-statistics 4xxErrors / 5xxErrors (caller, 10:35 and 10:36)`; `live: describe-alarms --alarm-name-prefix paymentapi (caller, 10:29)` | — |
| 11 | Application compatibility | unknown | The tag is read at request time by an IAM condition, so it is not on the not-app-facing list: category 11 is triggered. No app source was given, so whether anything reads the bucket through this role is not known. A failed read may be silent | `code: main.tf:72`; `operator` Q8 = (c) | The evidence that resolves it: the app source (Q8 (a) or (b)), or `live:` role last-accessed or CloudTrail data events showing no use of the role on this bucket for 30 days |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| Bucket `team` tag | `code: main.tf:15` = `payments` | `live: get-bucket-tagging (caller, 10:21)` -> `team=payments` | match |
| Bucket exists in `ap-southeast-1` | `code: main.tf:10`, `envs/prod.tfvars:2` | `live: head-bucket (caller, 10:22)` | match |
| Policy keyed on the tag | `code: main.tf:62-77` | `live: get-policy-version (caller, 10:24)` | match |
| Policy holders | `code: main.tf:85-88` | `live: list-entities-for-policy (caller, 10:25)`; `live: list-attached-role-policies (caller, 10:26)` | match |
| Other resources with `team` | `code: main.tf:15` only | `live: tagging get-resources (caller, 10:27)` -> this bucket only | match |
| Alarms on the bucket | `code: main.tf:108-158` | `live: describe-alarms-for-metric (caller, 10:30, 10:31)` | match |
| Drift | `plan: terraform plan -refresh-only` | `live: (caller, 10:20)` -> No changes | no drift |
| Delivery model | `code: none` | none | UNVERIFIED (operator-stated) |
| `platform`-keyed principals outside this repo | `code: none` | none | UNVERIFIED |
| Last successful apply | `code: none` | none | UNVERIFIED (operator-stated "recent") |

Drift rows: none. Unverified: delivery model, outside-repo `platform` grants, last apply.

## Verification
- Citations checked: 12 (fixed: none)
- Verdict working: Red = none; Yellow + unknown = 4 (4, 7, 9, 11), which is 3 or more, so the multi-Yellow rule escalates to RED — soft block; hard blocks checked: category 2 (no irreversible change), 5 (no incident, no freeze), 9 (no public exposure, no encryption removal, no secret), 10 (no exhausted error budget), none triggered -> RED — soft block
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: `operator-stated`: Q3, Q6, `iac-change.4 = recent`, the CI-on-merge delivery model, the workspace; `UNVERIFIED`: that a denied read counts in `4xxErrors`, principals outside this repo keyed on `team = platform`, the role's inline policies, whether anything other than the payments engineers reads the bucket through the role

## Hard Blocks
none

## Acknowledged Risks
Acknowledged at `[H5]` by the operator, 2026-11-09 11:09, for each of findings 4 (dependency impact), 7 (observability readiness), 9 (security posture) and 11 (application compatibility), and for the RED soft-block escalation itself. Reason, in the operator's words: "ownership move approved by the platform team; the policy is updated in a separate ticket".

## Mitigations Committed
None named by the operator at `[H5]`. Offered and not committed to: ship a `platform` grant before the re-tag; check the 4xx metric and CloudTrail after the apply; search org policies and SCPs for `platform`-keyed conditions; resolve category 11 with the app source or last-accessed evidence.

## Context Provided (L2)
From the caller block (`[F2]`, 10:46): Q1 = no (`operator`), Q2 = no (`operator`), Q3 = no (`operator-stated`), Q4 = many times (`operator`), Q5 = experienced (`operator`), Q6 = negligible (`operator-stated`, volunteered), Q7 = none, Q8 = (c) application source not available, `iac-change.1` = yes, `iac-change.2` = PR and a CI pipeline applies on merge (`operator-stated`), `iac-change.3` = no, default workspace and the environment's own var-file (`operator-stated`), `iac-change.4` = recent (`operator-stated`). Also stated at `[F2]`: the payments engineers role losing read access is intended; ownership of the exports moves to the platform team and a separate ticket updates the policy.

## L1 Analysis Detail
Scanned the plan (`Plan: 0 to add, 1 to change, 0 to destroy`; only `tags` and `tags_all`, key `team`), `main.tf`, `providers.tf`, `envs/prod.tfvars`, and git history (no commit to `main.tf` in the last 7 days; three older commits). No service-discovery catalog. The changed attribute is read by an IAM condition, so it is app-facing.

## L3 Queries Run
Target check (pre-flight, 11:02): `aws sts get-caller-identity` -> account 333333333333, matches the caller's Target.
Pre-flight's own: `git log --since=7.days --oneline origin/main -- main.tf` (11:03) -> none; `git status --short` (11:04) -> ` M main.tf`.
The caller's results, each as `live: <cmd> (caller, <time>)`:
1. `terraform plan -refresh-only -var-file=envs/prod.tfvars` (caller, 10:20) -> No changes
2. `aws s3api get-bucket-tagging --bucket paymentapi-exports-prod` (caller, 10:21) -> team=payments
3. `aws s3api head-bucket --bucket paymentapi-exports-prod` (caller, 10:22) -> ap-southeast-1
4. `aws iam get-policy` (caller, 10:23) -> 1 attachment, v1
5. `aws iam get-policy-version` (caller, 10:24) -> Allow GetObject/ListBucket, `*`, condition `aws:ResourceTag/team = payments`
6. `aws iam list-entities-for-policy` (caller, 10:25) -> role `paymentapi-engineers-prod` only
7. `aws iam list-attached-role-policies --role-name paymentapi-engineers-prod` (caller, 10:26) -> that policy only
8. `aws resourcegroupstaggingapi get-resources --tag-filters Key=team` (caller, 10:27) -> this bucket only
9. `aws cloudwatch describe-alarms --state-value ALARM` (caller, 10:28) -> none
10. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi` (caller, 10:29) -> 4xx and 5xx alarms, enabled, OK
11. `aws cloudwatch describe-alarms-for-metric` 4xxErrors, 5xxErrors (caller, 10:30, 10:31) -> thresholds 25 and 5, 2 periods, SNS action
12. `aws cloudwatch describe-alarm-history` both alarms (caller, 10:32, 10:33) -> none
13. `aws s3api list-bucket-metrics-configurations` (caller, 10:34) -> EntireBucket
14. `aws cloudwatch get-metric-statistics` 4xxErrors, 5xxErrors (caller, 10:35, 10:36) -> max 2, all 0
15. `aws cloudwatch get-metric-statistics` AllRequests, now and a week earlier (caller, 10:37, 10:38) -> 380-467 per 5 min, ratio 1.0x
