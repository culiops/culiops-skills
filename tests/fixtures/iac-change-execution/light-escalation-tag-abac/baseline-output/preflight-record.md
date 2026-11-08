Path the skill would write: `.culiops/pre-flight/paymentapi-exports-team-tag-20261109-1131.md`

**Pre-flight assessment for:** `paymentapi` / `none (single environment: prod)`
**Action:** Change the `team` tag on `aws_s3_bucket.exports` (`paymentapi-exports-prod`) from `payments` to `platform`
**Date:** `2026-11-09 11:31` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes)
**Target:** `333333333333 / ap-southeast-1` | `n/a (not Kubernetes)` | `Terraform var-file envs/prod.tfvars (default workspace; no backend key in code)`
**Plan hash:** `sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a` (SHA-256 of the exact plan text assessed)
**Plan source:** `terraform show -no-color tfplan`
**Delivery model:** `CI after merge` (`operator-stated`; no pipeline config, GitOps object or PR-automation marker found in the repo, `git grep` at 10:09)
**Invoked by:** `iac-change-execution`
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live)`
**App source:** `not available — category 11 ⚪ (Q8 answer: c)`

## Verdict: RED — SOFT BLOCK

Compound-risk escalation: 5 categories are Yellow or ⚪ (1, 4, 7, 9, 11). No category is Red on its own and no hard block applies.

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟡 | One resource changed (tag only) in one region, but the tag is the condition key of the shared policy `paymentapi-team-bucket-read-prod`. After the change the role `paymentapi-engineers-prod` stops matching on this bucket and loses `s3:GetObject` / `s3:ListBucket` on it. Nothing softens it: no second grant was seen (bucket policy not read). Disruption: bucket and data path none expected (tag-only, in-place); access removed for 1 role | `plan:6-10`, `plan:22`, `code: main.tf:12-17,58-77`, `evidence-table:2,3`, `docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html` (read 2026-11-09) | Operator action: confirm the payments engineers no longer need this bucket; update or replace the policy in the same release or schedule it |
| 2 | Reversibility | 🟢 | In-place tag update. Rollback is a revert PR that CI applies on merge; restoring `payments` makes the policy match again. Tags are exempt from the one-way-attribute check. No data is touched | `plan:6-10`, `docs: IAM ABAC page` (changing the tag changes whether the policy allows the request), `assessor: iac-change.md:97` (risk-raising rule, tags exempt) | — |
| 3 | Change velocity | 🟢 | 0 commits to `main.tf` in the last 7 days; no open PR touches it. This change's own uncommitted edit is the only working-tree change. Last-apply age could not be read (no backend block, no CI history): noted, not scored | `git: git log --since=7.days origin/main -- main.tf` → none (11:02), `live: gh pr list --state open` → none (11:03), `code: git status --short` → ` M main.tf` (this change) | — |
| 4 | Dependency impact | 🟡 | One dependent reaches the bucket through the tag: policy `paymentapi-team-bucket-read-prod` and its single role `paymentapi-engineers-prod`. No catalog. `outputs.tf` (`bucket_name`, `bucket_arn`) does not change | `code: main.tf:72,85-88`, `evidence-table:3` (`live: iam list-entities-for-policy`) | Same as category 1 |
| 5 | Timing context | 🟢 | No incident, no freeze (operator). Not peak (operator-stated); request rate over the last hour is flat at 380 to 467 per 5 min and nothing is firing. Apply happens at merge by CI, so the apply time is the operator's merge time (not known now) | `operator` (Q1, Q2), `operator-stated` (Q3), `live:2`, `live:10` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Terraform | `operator` (Q4, Q5) | — |
| 7 | Observability readiness | 🟡 | The 4xx and 5xx alarms watch this bucket (`BucketName` + `FilterId=EntireBucket`), are enabled, notify SNS `paymentapi-exports-alerts-prod`, and request metrics are on. They are static thresholds (25 and 5 per 5 min, 2 periods); no SLO and no dashboard in code. A loss of read access for a few engineers shows as 4xx but may stay under 25 | `code: main.tf:94-158`, `live:3`, `live:4`, `live:7` | Operator action: after apply, make a read as the engineers' role and confirm the 4xx alarm behaves |
| 8 | Cost impact | 🟢 | No new resources, no size change: `Plan: 0 to add, 1 to change, 0 to destroy`, tags only | `plan:22`, `operator-stated` (Q6: negligible) | — |
| 9 | Security posture | 🟡 | Permission-scope change through ABAC. The role is narrowed on this bucket. Any policy keyed on `team=platform` could now match it, and none was enumerated. No public access, no wildcard action, no encryption or audit-log change | `code: main.tf:68-72`, `evidence-table:2` (`live: iam get-policy-version v1`), `docs: IAM ABAC page` | Operator action: list the bucket policy and any IAM policy that references `aws:ResourceTag/team` before apply |
| 10 | Resource health | 🟢 | Nothing firing; no alarm state change in the last 24h; 4xx Sum 0 to 2 per 5 min (threshold 25); 5xx 0; request rate flat. No SLO, so the service's own recent window is the baseline (1 hour read) | `live:2`, `live:5`, `live:6`, `live:8`, `live:9`, `live:10` | — |
| 11 | Application compatibility | ⚪ | The tag is read by IAM at request time, so it is not on the not-app-facing list: the category is triggered. Application source not available (Q8 = c); the live last-accessed read produced no output. Silent breakage: a reader that gets a 403 and swallows it keeps health and error-rate signals green | `code: main.tf:72`, `operator` (Q8), `live:11` (unavailable) | What would resolve it: the source of whatever reads the bucket as the payments engineers role (Q8 a or b), or an IAM last-accessed result for the role |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| `team` tag on `paymentapi-exports-prod` | `main.tf:15` → `payments` | `evidence-table:1` (`aws s3api get-bucket-tagging`, 10:22) → `team=payments` | ✓ |
| Policy statement and condition | `main.tf:58-77` | `evidence-table:2` (`aws iam get-policy-version v1`, 10:24) → same | ✓ |
| Policy holders | `main.tf:85-88` | `evidence-table:3` (`aws iam list-entities-for-policy`, 10:25) → 1 role | ✓ |
| Stack matches code | `main.tf` | `evidence-table:4` (`terraform plan -refresh-only`, 10:26) → No changes | ✓ no drift |
| Target account | `envs/prod.tfvars:3`, `providers.tf:14-16` | `live:1` → 333333333333 | ✓ |
| Alarms exist and are enabled | `main.tf:108-158` | `live:3`, `live:4` → both `ActionsEnabled: true`, state OK | ✓ |
| Other grants on the bucket, grants keyed on `team=platform` | `none` in this repo | not read | UNVERIFIED |
| Who reads the bucket | no application source | `live:11` unavailable | UNVERIFIED |

Drift rows: none. Unverified facts: the two last rows.

## Verification

- Citations checked: 10 (fixed: none). Re-opened: `plan:6-10`, `plan:22`, `main.tf:15,58-77,85-88`, the docs entry for category 2, `assessor: iac-change.md:97`, `live:2,5,6,8,9` for category 10, and the factual premise of the category 1 and 9 mitigations.
- Verdict working: Red = none; Yellow + ⚪ = 5 (1, 4, 7, 9, 11) → escalation, RED — soft block; hard blocks checked: 2 irreversible data change (no: tag in place, reversible), 5 active incident + freeze (no: Q1, Q2), 9 public exposure / encryption removal / secrets (none), 10 error budget exhausted (none: no SLO, nothing firing) → RED — soft block.
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: peak-traffic answer (`operator-stated`; no 7-day baseline read), cost answer (`operator-stated`), last apply and automation lag (no backend block, no CI history; the assessor question "applied recently?" was answered as proposed: unsure), delivery model (`operator-stated`), other grants on the bucket and who gains access under `team=platform`, who actually reads the bucket.

## Hard Blocks

none

## Acknowledged Risks

- Compound-risk escalation (Yellow: 1 Blast radius, 4 Dependency impact, 7 Observability readiness, 9 Security posture; ⚪: 11 Application compatibility). Reason (operator): "ownership move approved by the platform team; the policy is updated in a separate ticket".

## Mitigations Committed

None named as committed. The operator's reason says the policy is updated in a separate ticket (`operator-stated`, not verified, not tracked by this skill). The other mitigations (confirm the payments engineers do not need the bucket, enumerate other grants, post-apply access check, provide app source or last-accessed result) were neither committed nor declined explicitly.

## Context Provided (L2)

- Q1 active incident: no (`operator`)
- Q2 deploy freeze: no (`operator`)
- Q3 apply in peak traffic: no (`operator-stated`; the apply happens at merge)
- Q4 changed this service before: many times (`operator`)
- Q5 used this IaC tool before: experienced (`operator`)
- Q6 expected cost impact: negligible (`operator-stated`)
- Q7 other context: none
- Q8 application source: (c) not available
- Assessor question, applied successfully recently: unsure (as proposed; `operator-stated`)

## L1 Analysis Detail

Scanned: the plan text (hash above), `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `envs/prod.tfvars`, `git log --since=7.days origin/main -- main.tf` (none), open PRs (none), the caller's evidence table (6 rows, 0 drift, 1 `UNVERIFIED`). No service-discovery catalog. Assessor `iac-change`. The tag is read by the policy condition `aws:ResourceTag/team` (`main.tf:72`), so it is app-facing and category 11 is triggered. The `<base>..HEAD` own-commit exclusion was not run: the 7-day window was already empty.

## L3 Queries Run

1. `aws sts get-caller-identity` → account 333333333333, role `paymentapi-operator`; matches the recorded target
2. `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1` → no metric or composite alarm firing
3. `aws cloudwatch describe-alarms-for-metric` (4xxErrors, bucket + EntireBucket) → `paymentapi-exports-4xx-prod`, enabled, OK, threshold 25 / 300 s / 2 periods
4. `aws cloudwatch describe-alarms-for-metric` (5xxErrors) → `paymentapi-exports-5xx-prod`, enabled, OK, threshold 5 / 300 s / 2 periods
5. `aws cloudwatch describe-alarm-history` (4xx alarm, 24h) → no items
6. `aws cloudwatch describe-alarm-history` (5xx alarm, 24h) → no items
7. `aws s3api list-bucket-metrics-configurations --bucket paymentapi-exports-prod` → one configuration, `EntireBucket`
8. `aws cloudwatch get-metric-statistics` 4xxErrors, 1h at 5 min → Sum 0 to 2 per period
9. `aws cloudwatch get-metric-statistics` 5xxErrors, 1h at 5 min → 0 in every period
10. `aws cloudwatch get-metric-statistics` AllRequests, 1h at 5 min → Sum 380 to 467 per period
11. `aws iam generate-service-last-accessed-details` (role `paymentapi-engineers-prod`) → no output; L3 unavailable for category 11 — scoring based on L1+L2 only
