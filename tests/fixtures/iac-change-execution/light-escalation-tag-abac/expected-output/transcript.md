# Dry run: light-escalation-tag-abac (new skill, SKILL_SOURCE = working-tree)

- Skill text read from the working tree: `skills/iac-change-execution/SKILL.md`, `skills/iac-change-execution/lanes.md`, `skills/iac-change-execution/examples/aws.md`, `skills/pre-flight/SKILL.md`, `skills/pre-flight/assessors/iac-change.md`, `skills/pre-flight/examples/aws.md`. `examples/kubernetes.md` and `examples/app-source.md` were not needed (AWS and Terraform only; Q8 = (c)).
- Operator script: `operator-script.md`, matched by stop ID. The "Answers by meaning" section is ignored.
- Dry-run clock: starts 10:00 +07:00 (2026-11-09). Each command advances it one minute (stamped after the advance). Each operator answer advances it five minutes.
- `CULIOPS_HOME`: the dry run has no environment lookup, so it is taken as unset. Output root is `.culiops/` at the repo root (SKILL.md Constraint 13).
- Reads of the fixture's input files (`main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `envs/prod.tfvars`) stand in for `cat` and `git grep`. `README.md` and `DRY-RUN-NOTES.md` were not read. The fixture holds no `.culiops/` records, no CI config and no `.gitignore`.
- First message: "Change the team tag on the paymentapi-exports bucket in prod from payments to platform."

---

## Step 1: Research

Identity read first, before any other live command (SKILL.md:169, exempt from opt-in).

```
[cmd 1]  10:01  aws sts get-caller-identity
         canned: identity-prod.json
         -> Account 333333333333, Arn arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator
```

Pin: `code: providers.tf:16` `allowed_account_ids = [var.aws_account_id]`; `code: envs/prod.tfvars:3` `aws_account_id = "333333333333"`. The live account equals the pin exactly. Only one environment is defined (`envs/prod.tfvars`), named `prod`; no dev or staging environment exists. No identity mismatch, so no `[H1]`.

Local version reads (not live reads; they feed the record's prerequisites line, SKILL.md:502):

```
[cmd 2]  10:02  aws --version
         canned: aws-version.txt -> aws-cli/2.17.21 (>= 2.x, matches examples/aws.md Prerequisites)
[cmd 3]  10:03  terraform version
         canned: terraform-version.txt -> Terraform v1.9.8, provider hashicorp/aws v5.74.0
```

Code read (input files): `main.tf` (bucket `main.tf:9-17`, tag at `main.tf:15`, tag-based policy `main.tf:58-77`, condition `main.tf:72`, role attachment `main.tf:85-88`, request metrics `main.tf:94-97`, alarms `main.tf:108-132` and `134-158`), `providers.tf`, `variables.tf`, `outputs.tf`, `envs/prod.tfvars`. Naming and style: tag keys are aligned with `=`, tag map `main.tf:12-16`; commit-message style from history is `exports: <lowercase subject>`.

```
[cmd 4]  10:04  git branch --show-current
         canned: git-branch.txt -> main
```

Current branch is the default branch, so the code is read from the working tree (SKILL.md:173).

```
[cmd 5]  10:05  git remote get-url origin
         canned: git-remote.txt -> git@github.com:acme/paymentapi-infra.git   (host: GitHub, so PR via gh)
```

Catalog: `.culiops/service-discovery/` does not exist in the fixture. None loaded. The skill suggests running service-discovery first.

Ticket: none given.

**Duplicate check** (identifiers: `platform` (the new value), `paymentapi-exports` (bucket name form used in code), tag key `team` (covered by the E2 greps below); no ticket key, so no `--grep`).

```
[cmd 6]  10:06  git grep -n -F 'platform'
         answered by grep -rn -F over the input files -> no hits (exit 1)
[cmd 7]  10:07  git grep -n -F 'paymentapi-exports'
         answered by grep -rn -F over the input files ->
           main.tf:10   bucket = "paymentapi-exports-${var.env}"
           main.tf:100  name = "paymentapi-exports-alerts-${var.env}"
           main.tf:109  alarm_name = "paymentapi-exports-4xx-${var.env}"
           main.tf:118  alarm_description ... paymentapi-exports ${var.env}
           main.tf:135  alarm_name = "paymentapi-exports-5xx-${var.env}"
           main.tf:144  alarm_description ... paymentapi-exports ${var.env}
[cmd 8]  10:08  git log --all --oneline -S'platform'
         canned: empty.txt -> no hits
[cmd 9]  10:09  git branch -a --list '*exports*'
         canned: empty.txt -> no in-flight branch
[cmd 10] 10:10  gh pr list --state open --search 'paymentapi-exports'
         canned: gh-pr-list-empty.txt -> no pull requests match your search in acme/paymentapi-infra
```

Verdict: **not done.** `code: main.tf:15` still has `team = "payments"`; the value `platform` appears nowhere in the repo or its history (`git: none`). No `[H6]`.

**Predict the lane** (lanes.md Lane rule). Not dev: no target is proven dev (the only target is `prod`). L1 to L3 on the implied action (a tag-only in-place update of `aws_s3_bucket.exports`) would hold: row "any `aws_*` type, update, only `tags` / `tags_all`". Now E1 to E3 on the request and the code. E2 for the changed tag key `team`:

```
[cmd 11] 10:11  git grep -n -E 'aws:(ResourceTag|RequestTag)/team|aws:TagKeys'
         answered by grep over the input files -> main.tf:72:            "aws:ResourceTag/team" = "payments"
[cmd 12] 10:12  git grep -n -F 'team'
         answered by grep over the input files ->
           main.tf:4    # payments engineers read any bucket whose `team` tag is "payments".
           main.tf:15   team        = "payments"
           main.tf:58   resource "aws_iam_policy" "team_bucket_read" {
           main.tf:59   name = "paymentapi-team-bucket-read-${var.env}"
           main.tf:60   description = "Read objects in buckets tagged for the payments team"
           main.tf:72   "aws:ResourceTag/team" = "payments"
           main.tf:87   policy_arn = aws_iam_policy.team_bucket_read.arn
```

All seven hits read. `main.tf:15` sets the tag: clears. `main.tf:58`, `59`, `87` are resource and policy names that carry the word and do not use the key: clear. `main.tf:72` is an IAM condition on `aws:ResourceTag/team`: **hit**. `main.tf:4` and `main.tf:60` describe tag-driven access acting on this key: **hit** (supporting). E2 hit.

E3 (written): resource action `aws_s3_bucket.exports` tags `team` payments -> platform. "Does this change trigger an automated action, or does anything read this value?" Yes: `aws_iam_policy.team_bucket_read` reads it (`main.tf:72`), attached to role `paymentapi-engineers-prod` (`main.tf:85-88`). No output changes. E3 hit. E1: no alarm is touched; no `alarm_actions` value in the change: pass.

Lane rule line 1 (an escalation is recorded) gives **full**. The first stop is `[F1]`.

**Delivery model and environment selection.**

```
[cmd 13] 10:13  git grep -n -i -E 'atlantis|spacelift|backend|workspace|workflow|pipeline'
         answered by grep over the input files -> no hits (exit 1)
```

No CI config, no `atlantis.yaml`, no `Application` / `Kustomization`, no `backend` or `cloud {}` block, no Makefile among the input files. Delivery model: **UNVERIFIED** (asked inside `[F2]`, SKILL.md:188). Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars`, `variables.tf:1-15`), the only var-file; default workspace and backend key are not stated in code (no `backend` block), to be operator-stated.

**Evidence table, live column pending.** Built from the code reads; the live column is filled by the `[F1]` batch.

**Live verification batch.** Full lane: it is `[F1]`, ahead of Step 2 (SKILL.md:199). It holds the Step 1 reads, the tool's drift check, and the assessor's L3 reads for the resources the change touches (lanes.md:144-145). Categories with no read: reversibility (the L3 hook is for destroys and one-way changes; a tag edit is neither), cost (a tag edit changes no billed attribute), app compatibility (Q8 is not yet answered; live data alone never settles it). The success-criteria reads are approved at `[F2]`, the plan command at `[F3]`.

### Skill message shown to the operator

> **Step 1 so far** (the full research summary comes with `[F2]`, once these reads have run)
>
> - **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset). Records go to `.culiops/iac-change-execution/` and `.culiops/pre-flight/`.
> - **Change requested:** change the `team` tag on the `paymentapi-exports` bucket in prod from `payments` to `platform`.
> - **Target** (identity read, 10:01, run without opt-in): account `333333333333`, `assumed-role/paymentapi-operator`; region `ap-southeast-1` (`code: envs/prod.tfvars:2`).
> - **Environment tier:** `prod=prod`. It is the only environment the repo defines (`code: envs/prod.tfvars`). The live account equals the pin (`live:` identity read; `code: providers.tf:16`, `envs/prod.tfvars:3`), so the target is this environment's account. The name `prod` proves nothing by itself and no dev tier is claimed. No `staging` environment exists.
> - **Lane (predicted): full.** The action is a tag-only in-place update, which is on the light allowlist, but **E2 hits**: `code: main.tf:72` has the IAM condition `aws:ResourceTag/team = "payments"` in `aws_iam_policy.team_bucket_read`, attached to `paymentapi-engineers-prod` (`main.tf:85-88`). **E3 hits** for the same reason (something reads this value). E1 does not apply. The stops are `[F1]` to `[F4]`.
> - **Catalog:** none (`.culiops/service-discovery/` has no entry). Consider running service-discovery first for a more complete picture.
> - **Duplicate check:** not done (`code: main.tf:15` still `payments`; `platform` appears nowhere in the repo; `git log -S'platform'`, branch list and open-PR list are empty).
> - **Delivery model:** nothing in the repo shows how a merge reaches prod, so it is `UNVERIFIED`. I ask inside `[F2]`.
>
> **[F1] Run these reads?** All read-only, against prod (account 333333333333, `ap-southeast-1`, var-file `envs/prod.tfvars`). Metric windows: the hour up to the run start (`2026-11-09T02:00:00Z` to `03:00:00Z`) and, for the baseline, the same hour a week earlier.
>
> 0. Target check: `aws sts get-caller-identity` (already run at 10:01: account 333333333333, `assumed-role/paymentapi-operator`; matches the pin).
> 1. `terraform init -input=false` (needed for the drift check; it can update `.terraform.lock.hcl`, and the lock file is reused if nothing changes)
> 2. `terraform plan -refresh-only -var-file=envs/prod.tfvars -input=false` (drift check; never applied)
> 3. `aws s3api get-bucket-tagging --bucket paymentapi-exports-prod` (current `team` value)
> 4. `aws s3api head-bucket --bucket paymentapi-exports-prod` (bucket and region)
> 5. `aws iam get-policy --policy-arn arn:aws:iam::333333333333:policy/paymentapi-team-bucket-read-prod`
> 6. `aws iam get-policy-version --policy-arn arn:aws:iam::333333333333:policy/paymentapi-team-bucket-read-prod --version-id v1` (the tag condition, as live)
> 7. `aws iam list-entities-for-policy --policy-arn arn:aws:iam::333333333333:policy/paymentapi-team-bucket-read-prod` (who the policy applies to)
> 8. `aws iam list-attached-role-policies --role-name paymentapi-engineers-prod` (other grants on that role)
> 9. `aws resourcegroupstaggingapi get-resources --tag-filters Key=team --region ap-southeast-1` (what else carries the `team` key)
> 10. `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1` (anything firing)
> 11. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1`
> 12. `aws cloudwatch describe-alarms-for-metric --namespace AWS/S3 --metric-name 4xxErrors --dimensions Name=BucketName,Value=paymentapi-exports-prod Name=FilterId,Value=EntireBucket --region ap-southeast-1`
> 13. the same with `--metric-name 5xxErrors`
> 14. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-exports-4xx-prod --history-item-type StateUpdate --start-date 2026-11-08T03:00:00Z --end-date 2026-11-09T03:00:00Z --region ap-southeast-1`
> 15. the same for `paymentapi-exports-5xx-prod`
> 16. `aws s3api list-bucket-metrics-configurations --bucket paymentapi-exports-prod` (request metrics behind the alarms)
> 17. `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name 4xxErrors --dimensions Name=BucketName,Value=paymentapi-exports-prod Name=FilterId,Value=EntireBucket --start-time 2026-11-09T02:00:00Z --end-time 2026-11-09T03:00:00Z --period 300 --statistics Sum --region ap-southeast-1`
> 18. the same with `--metric-name 5xxErrors`
> 19. the same with `--metric-name AllRequests` (traffic now)
> 20. `AllRequests` for `2026-11-02T02:00:00Z` to `03:00:00Z` (same hour last week, the peak baseline)
>
> Approve all, pick a subset, or decline (declined rows become `code-only — not live-verified`).

STOP 1: `[F1]`.

### Operator answer (script entry 1, `[F1]`)

> Approved: the whole batch, every command shown, the target check included.

Clock: 10:13 + 5 = 10:18.

### Live batch (approved at `[F1]`)

```
[cmd 14] 10:19  terraform init -input=false
         canned: terraform-init.txt -> "Reusing previous version of hashicorp/aws from the dependency lock file ... successfully initialized"
         .terraform.lock.hcl unchanged.
[cmd 15] 10:20  terraform plan -refresh-only -var-file=envs/prod.tfvars -input=false
         canned: plan-refresh-only-prod.txt -> "No changes. Your infrastructure still matches the configuration."  (no drift)
[cmd 16] 10:21  aws s3api get-bucket-tagging --bucket paymentapi-exports-prod
         canned: s3-bucket-tagging-prod.json -> Service=paymentapi, Environment=prod, team=payments   (state: before apply)
[cmd 17] 10:22  aws s3api head-bucket --bucket paymentapi-exports-prod
         canned: s3-head-bucket-prod.json -> BucketRegion ap-southeast-1
[cmd 18] 10:23  aws iam get-policy --policy-arn arn:aws:iam::333333333333:policy/paymentapi-team-bucket-read-prod
         canned: iam-get-policy-prod.json -> AttachmentCount 1, DefaultVersionId v1
[cmd 19] 10:24  aws iam get-policy-version --policy-arn ...paymentapi-team-bucket-read-prod --version-id v1
         canned: iam-get-policy-version-prod.json -> Allow s3:GetObject, s3:ListBucket on Resource "*" where StringEquals aws:ResourceTag/team = payments
[cmd 20] 10:25  aws iam list-entities-for-policy --policy-arn ...paymentapi-team-bucket-read-prod
         canned: iam-list-entities-for-policy-prod.json -> PolicyRoles [paymentapi-engineers-prod]; no users, no groups
[cmd 21] 10:26  aws iam list-attached-role-policies --role-name paymentapi-engineers-prod
         canned: iam-list-attached-role-policies-prod.json -> one attached policy: paymentapi-team-bucket-read-prod
[cmd 22] 10:27  aws resourcegroupstaggingapi get-resources --tag-filters Key=team --region ap-southeast-1
         canned: tagging-get-resources-team-prod.json -> one resource: arn:aws:s3:::paymentapi-exports-prod (team=payments)
[cmd 23] 10:28  aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1
         canned: alarms-firing-prod.json -> no metric alarms, no composite alarms
[cmd 24] 10:29  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1
         canned: alarms-prefix-prod.json -> paymentapi-exports-4xx-prod and -5xx-prod, both ActionsEnabled true, state OK, action = SNS topic paymentapi-exports-alerts-prod
[cmd 25] 10:30  aws cloudwatch describe-alarms-for-metric --namespace AWS/S3 --metric-name 4xxErrors --dimensions ...
         canned: alarms-for-metric-s3-4xx-prod.json -> paymentapi-exports-4xx-prod, Threshold 25 per 300 s x 2 periods, enabled, OK
[cmd 26] 10:31  aws cloudwatch describe-alarms-for-metric --namespace AWS/S3 --metric-name 5xxErrors --dimensions ...
         canned: alarms-for-metric-s3-5xx-prod.json -> paymentapi-exports-5xx-prod, Threshold 5 per 300 s x 2 periods, enabled, OK
[cmd 27] 10:32  aws cloudwatch describe-alarm-history --alarm-name paymentapi-exports-4xx-prod ...
         canned: alarm-history-prod.json -> no history items
[cmd 28] 10:33  aws cloudwatch describe-alarm-history --alarm-name paymentapi-exports-5xx-prod ...
         canned: alarm-history-prod.json -> no history items
[cmd 29] 10:34  aws s3api list-bucket-metrics-configurations --bucket paymentapi-exports-prod
         canned: s3-metrics-configuration-prod.json -> one configuration, EntireBucket
[cmd 30] 10:35  aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name 4xxErrors ...
         canned: metric-s3-4xx-prod.json -> 12 datapoints (02:00Z-02:55Z), Sum max 2, total 5
[cmd 31] 10:36  aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name 5xxErrors ...
         canned: metric-s3-5xx-prod.json -> 12 datapoints, all 0
[cmd 32] 10:37  aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name AllRequests ... (this hour)
         canned: metric-s3-requests-prod.json -> Sum 380-467 per 5 min, mean about 429
[cmd 33] 10:38  aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name AllRequests ... (same hour, 7 days earlier)
         canned: metric-s3-requests-prod.json -> same file ("any window"); baseline ratio therefore 1.0x
```

Notes on these lookups: the canned metric files cover `02:00Z-02:55Z` whatever window is asked ("any window" in INDEX), so I treat them as the hour up to the run start. Environment for every row: prod (the only environment). All 20 rows had a canned answer; none was `no canned output`.

**Evidence table, now filled.**

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| Bucket `paymentapi-exports-prod` `team` tag | `code: main.tf:15` -> `payments` (bucket `main.tf:9-10`) | `live: aws s3api get-bucket-tagging` (10:21) -> `team=payments` | match |
| Bucket exists in `ap-southeast-1` | `code: main.tf:10`, `envs/prod.tfvars:2` | `live: aws s3api head-bucket` (10:22) -> `ap-southeast-1` | match |
| Policy `paymentapi-team-bucket-read-prod` is keyed on the tag | `code: main.tf:62-77`, condition `main.tf:72` | `live: aws iam get-policy-version` (10:24) -> same condition, `s3:GetObject` + `s3:ListBucket`, `Resource "*"` | match |
| Who the policy applies to | `code: main.tf:85-88` (one role attachment) | `live: aws iam list-entities-for-policy` (10:25) -> role `paymentapi-engineers-prod` only; `live: aws iam list-attached-role-policies` (10:26) -> that policy is the role's only attached policy | match |
| Other resources with a `team` tag | `code: main.tf:15` only | `live: aws resourcegroupstaggingapi get-resources` (10:27) -> only this bucket | match |
| Alarms that watch the bucket | `code: main.tf:108-132`, `134-158` | `live: describe-alarms-for-metric` (10:30, 10:31) -> 4xx (> 25 per 5 min) and 5xx (> 5 per 5 min), enabled, OK, SNS action; history empty (10:32, 10:33) | match |
| Request metrics behind the alarms | `code: main.tf:94-97` | `live: list-bucket-metrics-configurations` (10:34) -> `EntireBucket` | match |
| Nothing firing; error baseline | none | `live: describe-alarms --state-value ALARM` (10:28) -> none; 4xx max 2 and 5xx 0 per 5 min (10:35, 10:36) | no drift |
| Drift | none | `live: terraform plan -refresh-only` (10:20) -> No changes | no drift |
| Delivery model | `code: none` | none | UNVERIFIED (asked at `[F2]`) |
| Principals outside this repo keyed on `team = platform` | `code: none` (`git grep 'platform'` -> no hits) | not readable with the approved batch | UNVERIFIED |
| Last successful apply ("recent") | `code: none` (no backend, no CI config) | none | UNVERIFIED (`operator-stated` at `[F2]`) |

Drift rows: 0. Unverified rows: 3. Gaps remaining and the command that would resolve each: delivery model, ask the operator; `platform`-keyed principals outside this repo, list the account's customer-managed policies and org SCPs and read their conditions (not in the approved batch); last apply, `aws s3api head-object --bucket <state-bucket> --key <state-key>` once the backend is known.

---

## Step 2: Plan

Single phase (one in-place tag edit; one environment). Local reads for the branch step (SKILL.md:247; `git branch --show-current` was already read at 10:04 -> `main`):

```
[cmd 34] 10:39  git status --short
         canned: git-status-clean.txt -> prints nothing (clean tree)
[cmd 35] 10:40  git rev-parse --short origin/main
         canned: git-rev-parse.txt -> a1b2c3d
```

Behaviour claim that drives the plan (what changing the tag does to the policy):

```
[cmd 36] 10:41  docs lookup: "an aws:ResourceTag condition follows the resource's tag"
         canned: docs.md entry "A condition on aws:ResourceTag follows the resource's tag"
         -> docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html (read 2026-11-09):
            a policy condition on aws:ResourceTag/tag-key compares the tag on the resource being accessed; changing the tag changes whether the policy allows the request. (paraphrase, per the fixture)
```

No other docs lookup was made: the claim that a denied read counts in the `4xxErrors` metric would only raise a score, so it is left `UNVERIFIED` (the code comment at `main.tf:91-92` says it; that is not evidence).

Plan self-check (8 items), run before the operator sees it: all pass.

1. Evidence cited for every item; no destroy, replace or resize rests on an `UNVERIFIED` row. The bucket's disruption is not claimed as `none`: `plan:` confirms in-place at 4a.
2. No deletes.
3. Rollback path and success criteria are commands with expected output.
4. No drift rows.
5. PR path fits every delivery model, including the unknown one.
6. Every implied file and resource is in the phase. The policy condition (`main.tf:72`) is not in it: the request does not imply it, and the plan says so.
7. Lane basis cited: E2 and E3 with `code: main.tf:72`; tier evidence.
8. No staging env: exception (a) with evidence.

### Skill message shown to the operator

> **Research summary**
>
> **Change requested:** change the `team` tag on the `paymentapi-exports` bucket in prod from `payments` to `platform`.
> **Service:** `paymentapi` / **Instance:** `exports`
> **IaC tool(s):** Terraform (`code: providers.tf:1-9`, AWS provider `~> 5.0`) · **Delivery model:** `UNVERIFIED` (nothing in the repo; asked below) · **Env selection:** `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars`), default workspace (to be stated)
> **Target:** account `333333333333` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:01)
> **Environment tier:** `prod=prod` (`live:` identity = `code: providers.tf:16` / `envs/prod.tfvars:3` pin; the name is not the proof) · **Lane (predicted):** `full`. L1 to L3 would hold (tag-only in-place update on an `aws_*` type), but E2 hits (`code: main.tf:72`, `main.tf:4`, `main.tf:60`) and E3 hits (the tag is read by `aws_iam_policy.team_bucket_read`, attached to `paymentapi-engineers-prod`, `main.tf:85-88`). E1 n/a.
> **Catalog used:** none, proceeding without catalog (consider service-discovery first)
> **Duplicate check:** not done (`code: main.tf:15` = `payments`; `git: none` for `platform`; no in-flight branch or PR)
> **Evidence table:** the table above, 12 rows, drift rows: 0, unverified rows: 3
> **Gaps remaining:** delivery model; `platform`-keyed principals outside this repo; last successful apply.
>
> **Change plan for `paymentapi` / `exports`:**
>
> **Phase 1 of 1: change the bucket's `team` tag to `platform` (prod)**
> - Files: `main.tf` (line 15, `team = "payments"` -> `team = "platform"`)
> - Resources affected: `aws_s3_bucket.exports` (`paymentapi-exports-prod`) update in place, `tags` and `tags_all` only. Nothing added, nothing destroyed. Not in this change: `aws_iam_policy.team_bucket_read` (condition `main.tf:72` stays `payments`).
> - Blast radius: one bucket, one region (`code: main.tf:9-17`). Through the tag, the access policy is affected: after the change no bucket in the account carries `team = payments` (`live: tagging get-resources`, 10:27: only this bucket has the key), so `paymentapi-team-bucket-read-prod` grants nothing, and its only holder, role `paymentapi-engineers-prod` (`live: list-entities-for-policy` 10:25; `list-attached-role-policies` 10:26: no other attached policy), loses `s3:GetObject` and `s3:ListBucket` on this bucket. Inline policies on the role were not read.
> - Disruption: bucket itself, none expected; `plan:` at 4a confirms in-place vs replace, and until then it is not claimed as `none`. Readers: the role `paymentapi-engineers-prod` is denied reads from the apply (`docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html`, read 2026-11-09). The apply happens at merge.
> - Rollback path: `git revert` of the PR, plan, apply through the same reviewed path; re-tagging `payments` makes the policy match again (`docs:` as above). Reversible (a tag value; no data change). Untested. If the policy has been changed to `platform` in the meantime, reverting the tag alone does not restore the old access.
> - Evidence: the table rows 1, 3, 4, 5, 6, 7, 8, 9.
> - Success criteria (read-only, approved with this plan; run once the apply lands):
>   1. `aws s3api get-bucket-tagging --bucket paymentapi-exports-prod` -> `team = platform`; `Service = paymentapi` and `Environment = prod` unchanged
>   2. `terraform plan -var-file=envs/prod.tfvars` -> `No changes.`
>   3. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1` -> both alarms `OK`, `ActionsEnabled` true
>   4. `aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name 4xxErrors ...` and `5xxErrors` (15 min after the apply) -> Sum per 5 min below 25 and 5 (before: max 2 and 0)
>
> **Execution path:** PR (default). After merge it is applied by whatever the delivery model is (below). I will not apply directly.
> **Staging-first (H7):** (a) no staging env, `code:` `envs/` holds only `prod.tfvars` and the repo defines no other environment · **Observation window:** n/a, no staging phase
> **Branch:** current `main` -> `iac-change/paymentapi-exports-team-tag-platform` from `origin/main` @ `a1b2c3d` (`git fetch origin main`, then `git switch -c`; the tree is clean, `git status --short` empty at 10:39)
> **Self-check:** 8/8 pass
> **Drift (H4):** none (`terraform plan -refresh-only` -> No changes; live `team` tag = code)
> **For pre-flight (L2):**
> - Q1. Is there an active incident affecting this service or its dependencies? (yes/no)
> - Q2. Is there a deploy freeze or change window restriction? (yes/no)
> - Q3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure; with CI the apply happens at merge, not now)
> - Q4. Have you changed this service before? (many times / a few times / first time)
> - Q5. Have you used this IaC tool before? (experienced / some experience / first time)
> - Q7. Any other context I should know? (optional)
> - Q8. This change touches what the app depends on: the `team` tag, which the IAM condition `aws:ResourceTag/team` (`main.tf:72`) reads at request time. Where is the application source? (a) a local checkout, give the path; (b) a GitHub repo through `gh`, give `owner/repo` and the deployed ref (choosing it approves only the `GET` reads `gh auth status`, ref to SHA, file tree, file contents); (c) not available.
> - `iac-change.4`: has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
> - Q6 (cost) is not asked: L1 prices it from the plan (a tag edit; no billed attribute changes).
>
> **Delivery model (UNVERIFIED):** how does this change reach prod after the PR merges: a CI pipeline on merge, a GitOps controller, PR-driven plan and apply (Atlantis / Terraform Cloud), or by hand?
> **Intent check:** after this change the payments engineers role (`paymentapi-engineers-prod`) loses read access to the bucket. Is that intended?
>
> **[F2] Approve this plan?** Approving also approves the four success-criteria reads above.

STOP 2: `[F2]`.

### Operator answer (script entry 2, `[F2]`)

> Approved. Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8=(c) the application source is not available, iac-change.1=yes, iac-change.2=PR, and a CI pipeline applies on merge, iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent.
> Yes, the payments engineers role losing read access to the bucket is intended: ownership of the exports moves to the platform team and a separate ticket updates the policy.
> Delivery model: PR, and a CI pipeline applies on merge.

Taken from script entry 2. The two `if asked` items were used because the plan asked them (delivery model, intent). Q6 and `iac-change.1` to `.3` were not asked (SKILL.md:280, lanes.md:147), but the script says every other item is said in the answer, so they are recorded as volunteered. Delivery model is now `operator-stated` (unverified in the repo). Clock: 10:41 + 5 = 10:46.

Resulting state: execution path PR, CI applies on merge (`operator-stated`); workspace default, var-file `envs/prod.tfvars` (`operator-stated`); Q8 = (c), so category 11 will be unknown; no exception justification needed (exception (a) is automatic); success-criteria reads approved.

---

## Step 3: Implement

Branch commands from the plan (full lane: run after `[F2]`):

```
[cmd 37] 10:47  git fetch origin main
         canned: empty.txt -> no output
[cmd 38] 10:48  git switch -c iac-change/paymentapi-exports-team-tag-platform origin/main
         canned: git-switch.txt -> Switched to a new branch 'iac-change/paymentapi-exports-team-tag-platform'
[cmd 39] 10:49  git branch --show-current
         canned: git-branch-after-switch.txt -> iac-change/paymentapi-exports-team-tag-platform
```

On the change's branch. Code written (adjacent example for style: `main.tf:13-15`, aligned `=`):

```diff
--- a/main.tf
+++ b/main.tf
@@ -12,7 +12,7 @@ resource "aws_s3_bucket" "exports" {
   tags = {
     Service     = "paymentapi"
     Environment = var.env
-    team        = "payments"
+    team        = "platform"
   }
 }
 
```

Local formatter on the changed file only (shown before running, SKILL.md:333):

```
[cmd 40] 10:50  terraform fmt main.tf
         canned: empty.txt -> nothing printed, main.tf already formatted
[cmd 41] 10:51  git status --short
         answered from the diff above ->  M main.tf
[cmd 42] 10:52  git diff
         answered from the diff above (one hunk, main.tf:15)
```

Diff self-check (6 items): 1 scope: only `main.tf`, which is the approved file list; 2 plan to hunk: `aws_s3_bucket.exports` tags -> `main.tf:15`; 3 conventions: key alignment kept, same as `main.tf:13-14`; 4 no silent safety change: no listed safety setting changes (the `aws:ResourceTag/team` policy value is untouched; the tag edit's access effect is the approved plan's named effect); 5 no secrets, no `tfplan`, state or `.terraform/` among the changes; 6 formatter clean. 6/6 pass.

E1 to E3 on the diff are a light-lane step; the lane is already full.

Fresh eyes: the change is not add-only (an existing tag value changes) and it touches a data store (bucket) and access control (the tag drives an IAM condition), so the skip rule does not apply. `fresh-eyes: not run — dry run`.

### Skill message shown to the operator

> **Code changes for Phase 1 of 1:**
>
> **Modified:** `main.tf` — line 15, `team = "payments"` -> `team = "platform"` on `aws_s3_bucket.exports`
>
> **Plan to hunk:** `aws_s3_bucket.exports` update in place (`tags` / `tags_all`, `team`) -> `main.tf:15`
> **Self-check:** 6/6 pass · **Fresh eyes:** not run — dry run
> **Target:** `aws sts get-caller-identity` -> account `333333333333` / `assumed-role/paymentapi-operator` / region `ap-southeast-1` (10:01) · var-file `envs/prod.tfvars`, default workspace · tier `prod=prod`
> **Plan command (4a):** `terraform init` is not run again (it ran in the `[F1]` batch and left `.terraform.lock.hcl` unchanged), then `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above); one environment, prod
>
> Full diff is in your working tree (`git diff` to review).
> **[F3] Approve these changes and the plan command?**

STOP 3: `[F3]`.

### Operator answer (script entry 3, `[F3]`)

> Approved.

Clock: 10:52 + 5 = 10:57. The plan command is approved with it (Constraint 3).

---

## Step 4a: Plan output

Target re-check, no stop:

```
[cmd 43] 10:58  aws sts get-caller-identity
         canned: identity-prod.json -> account 333333333333, assumed-role/paymentapi-operator
```

Matches the pin and the target shown at `[F3]`. var-file read from the approved command (`envs/prod.tfvars`); workspace `default` is `operator-stated` (no `terraform workspace show` is in the approved batch, so none was run). Plan mode (1): the skill runs it.

```
[cmd 44] 10:59  terraform plan -out=tfplan -var-file=envs/prod.tfvars
         canned: plan-prod.txt  (state: before apply)
         -> # aws_s3_bucket.exports will be updated in-place
            ~ tags     = { ~ "team" = "payments" -> "platform"  # (2 unchanged elements hidden) }
            ~ tags_all = { ~ "team" = "payments" -> "platform"  # (2 unchanged elements hidden) }
            Plan: 0 to add, 1 to change, 0 to destroy.
```

Canned plan versus code: the diff changes only `team` on `aws_s3_bucket.exports`; the canned plan shows exactly that on `tags` and `tags_all`. No difference to note. `tfplan` stays local.

Cross-check against the evidence table and approved phase: the plan touches only `aws_s3_bucket.exports`, in place, as approved; no destroy, no replace; no refresh drift in the plan text; no unplanned change. The bucket's disruption is now `plan:` in-place, so `none` for the bucket (readers' access change stays as planned).

Confirm the lane: already full (E2 and E3 recorded at Step 1). L1 holds, L2 holds, L3 holds, L4 fails (E2, E3), so full stands; nothing to add and nothing is downgraded. Parity check: no staging phase ran (exception (a)), `Parity check: n/a`.

## Step 4b: Pre-flight

Dev lane: no (prod). Reusable record in `.culiops/pre-flight/`: the directory does not exist in the fixture, so no match. Invoke pre-flight inline.

```
[cmd 45] 11:00  terraform show -no-color tfplan
         canned: plan-prod.txt (same text as the plan)
[cmd 46] 11:01  sha256sum <scratch file holding the plan text, outside the repo>
         canned INDEX plan hash -> sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a
```

(Writing and deleting the scratch file is part of the `sha256sum` step; INDEX has no separate row for it, so it is not a separate lookup.)

Caller block passed to pre-flight:

```
### Caller context (iac-change-execution)
Target: account 333333333333 / region ap-southeast-1 · var-file envs/prod.tfvars · workspace default (operator-stated) · backend key: none declared in code
Delivery model: UNVERIFIED in the repo (no CI config found) — operator-stated: PR; a CI pipeline applies on merge
Lane: full — E2 (code: main.tf:72, aws:ResourceTag/team condition) and E3 (the tag is read by aws_iam_policy.team_bucket_read, main.tf:85-88)
Plan hash: sha256:3044950cb5c54c8dbd2dc44396d20e826400e1d94f135880c12bd8aeebb8217a (terraform show -no-color tfplan)
L2 answers: Q1=no Q2=no Q3=no Q4=many times Q5=experienced Q6=negligible Q7=none Q8=(c) application source not available iac-change.1=yes iac-change.2=PR + CI applies on merge iac-change.3=no iac-change.4=recent
Live results:
  terraform plan -refresh-only -var-file=envs/prod.tfvars · 10:20 · No changes
  aws s3api get-bucket-tagging (bucket) · 10:21 · team=payments
  aws s3api head-bucket · 10:22 · ap-southeast-1
  aws iam get-policy · 10:23 · 1 attachment, default version v1
  aws iam get-policy-version · 10:24 · Allow GetObject/ListBucket, Resource *, condition aws:ResourceTag/team = payments
  aws iam list-entities-for-policy · 10:25 · role paymentapi-engineers-prod only
  aws iam list-attached-role-policies · 10:26 · that policy only
  aws resourcegroupstaggingapi get-resources (team) · 10:27 · only paymentapi-exports-prod
  aws cloudwatch describe-alarms --state-value ALARM · 10:28 · none firing
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi · 10:29 · 4xx and 5xx alarms, enabled, OK
  aws cloudwatch describe-alarms-for-metric 4xxErrors / 5xxErrors · 10:30, 10:31 · thresholds 25 and 5 per 5 min, 2 periods, SNS action
  aws cloudwatch describe-alarm-history (both alarms) · 10:32, 10:33 · no state changes
  aws s3api list-bucket-metrics-configurations · 10:34 · EntireBucket
  aws cloudwatch get-metric-statistics 4xxErrors · 10:35 · max 2 per 5 min
  aws cloudwatch get-metric-statistics 5xxErrors · 10:36 · all 0
  aws cloudwatch get-metric-statistics AllRequests (now, and 7 days earlier) · 10:37, 10:38 · 380-467 per 5 min, baseline ratio 1.0x
Evidence table: the 12-row table from Step 1. Drift rows: none. Unverified: delivery model (now operator-stated), platform-keyed principals outside this repo, last successful apply. code-only rows: none. docs: ABAC page, read 2026-11-09 (cmd 36).
```

Every field has a value, so pre-flight stays in inline mode (pre-flight Constraint 14).

### Pre-flight, inline

Step 1: no unsupported-stack signal; assessor `iac-change` matches a Terraform plan. Target, delivery model, plan hash taken from the caller block; plan target equals the caller's `Target:`. GATE 1 skipped (inline); the detection is shown without a stop.

Step 2, L1 from the plan and code, with the assessor's rules: 1 blast radius, 2 reversibility, 3 change velocity (needs git), 4 dependency impact, 7 observability, 8 cost, 9 security. Marks: the `team` tag is read at request time by an IAM condition, so it is not on the not-app-facing list ("tags that nothing reads at runtime"), so it is app-facing: category 11 is triggered.

Step 3, L2: the caller's answers cover Q1 to Q5, Q6, Q7, Q8 and `iac-change.4`; `iac-change.1` to `.3` are answered by `Plan hash:`, `Delivery model:`, and `Target:` plus the plan command (no `-target`, no `-refresh=false`). Nothing is missing, so no L2 stop. Q8 = (c): category 11 unknown.

Step 3b: skipped (no app source).

Step 4, L3 (inline): leave out what the caller's `Live results:` cover. Target check first, without a stop:

```
[cmd 47] 11:02  aws sts get-caller-identity
         canned: identity-prod.json -> account 333333333333; equals the caller's Target -> continue
```

Reads the caller did not run: change velocity.

```
[cmd 48] 11:03  git log --since=7.days --oneline origin/main -- main.tf
         canned: empty.txt -> no commit touched main.tf in the window
[cmd 49] 11:04  git status --short
         answered from the diff ->  M main.tf   (this change's own file only; no other uncommitted work)
```

Open PRs touching the file: none (the 10:10 `gh pr list` result is cited rather than re-run). Last successful apply: no backend declared and no CI config in the repo, so the state-bucket read cannot be built; `iac-change.4 = recent` stays `operator-stated`. No read is missing that pre-flight can propose, so there is no L3 stop. (Reversibility, cost and app-compat live hooks: not applicable or not decisive, see above.)

Step 5, scores:

| # | Category | Score | Why |
|---|---|---|---|
| 1 | Blast radius | Green | one resource, one region (`plan:` 1 to change; `code: main.tf:9-17`); bucket disruption none (`plan:` in place); the readers' access effect is scored under 4 and 9, not twice |
| 2 | Reversibility | Green | tag value; revert PR + CI apply; tags need no behaviour claim, and `docs:` ABAC shows re-tagging restores the policy match; rollback untested |
| 3 | Change velocity | Green | 0 commits in 7 days (`git`, 11:03), no open PR, no stacked uncommitted work |
| 4 | Dependency impact | Yellow | `aws_iam_policy.team_bucket_read` consumes the tag (`code: main.tf:72`; `live:` policy version) and is attached to one role (`live:` list-entities) |
| 5 | Timing context | Green | Q1, Q2, Q3 = no (`operator`); request rate 1.0x baseline (`live:` AllRequests); apply is at merge, Monday 10:00 +07:00 in the run clock |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced (`operator`) |
| 7 | Observability readiness | Yellow | alarms exist and are enabled (`live:`), but they are static count thresholds (25 and 5 per 5 min, 2 periods; 4xx baseline max 2) and whether denied reads count in `4xxErrors` is `UNVERIFIED`, so a few denied manual reads may not trip them |
| 8 | Cost impact | Green | `plan:` no new or resized resource; Q6 negligible (`operator-stated`) |
| 9 | Security posture | Yellow | permission scope change (assessor: IAM change); narrowing for the payments role is shown (full policy document live), but the new value `platform` may grant access to principals in policies outside this repo (`UNVERIFIED`; E2 note, lanes.md:120) |
| 10 | Resource health | Green | `live:` nothing firing, 4xx max 2 and 5xx 0 per 5 min, both alarms OK |
| 11 | Application compatibility | unknown | triggered (tag read by an IAM condition); Q8 = (c), no app source |

Hard blocks checked: category 2 (no irreversible change), 5 (no incident, no freeze), 9 (no public exposure, no encryption removal, no secret), 10 (no exhausted budget): none. Verdict arithmetic: Red = none; Yellow + unknown = 4 (4, 7, 9, 11), which is 3 or more, so the multi-Yellow rule escalates: **RED — soft block**.

Step 5b: citations re-opened for the Greens on 1, 2, 10 and for each Yellow (12 checked, none fixed). Source conflicts: none. Fresh eyes: not required (verdict RED — soft block, pre-flight SKILL.md:327); no reviewer dispatched either way. Not verified: listed in the report.

### Skill message shown to the operator (pre-flight report, then GATE 2 opened as `[H5]`)

> **Pre-flight report: `paymentapi` / `exports` — change the `team` tag `payments` -> `platform` (prod)**
> Mode: inline (caller: iac-change-execution) · Assessor: iac-change · Plan hash `sha256:3044950c...b8217a` · Target 333333333333 / ap-southeast-1 · Output root `.culiops/`
>
> **Verdict: RED — soft block** (4 of 11 categories are Yellow or unknown; 3 or more escalates). No category is individually Red and no hard block applies.
>
> | # | Category | Score | Evidence |
> |---|---|---|---|
> | 1 | Blast radius | Green | `plan:` 0 add / 1 change / 0 destroy; `code: main.tf:9-17`; `docs:` ABAC |
> | 2 | Reversibility | Green | `plan:`, `docs:` ABAC; revert PR then CI apply |
> | 3 | Change velocity | Green | `git:` no commit in 7 days (11:03); no open PR |
> | 4 | Dependency impact | Yellow | `code: main.tf:72`, `main.tf:85-88`; `live:` policy version, list-entities |
> | 5 | Timing context | Green | `operator` Q1 to Q3; `live:` AllRequests |
> | 6 | Operator familiarity | Green | `operator` Q4, Q5 |
> | 7 | Observability readiness | Yellow | `live:` alarms enabled; `UNVERIFIED` 403 counting |
> | 8 | Cost impact | Green | `plan:`; `operator-stated` Q6 |
> | 9 | Security posture | Yellow | `code: main.tf:72`; `live:` policy version; `UNVERIFIED` outside-repo `platform` grants |
> | 10 | Resource health | Green | `live:` alarms, 4xx / 5xx metrics |
> | 11 | Application compatibility | unknown | Q8 = (c) |
>
> **Drift:** none. **Verification:** citations checked 12 (fixed: none) · verdict working: Red none; Yellow + unknown 4 (4, 7, 9, 11); hard blocks 2, 5, 9, 10 checked, none · fresh eyes: not required (verdict RED — soft block) · not verified: `operator-stated` Q6, `iac-change.4=recent`, the CI-on-merge delivery model; the claim that a denied read counts in `4xxErrors`; principals outside this repo keyed on `team = platform`; the role's inline policies; whether the app or people other than the payments engineers read this bucket through the role.
>
> **Findings**
> 1. **Dependency impact, Yellow.** *Found:* the policy `paymentapi-team-bucket-read-prod` allows `s3:GetObject` and `s3:ListBucket` only where `aws:ResourceTag/team = payments` (`main.tf:72`), and its only holder is `paymentapi-engineers-prod`; this bucket is the only resource with the key (`live:` tagging, 10:27). *Why it matters:* after the apply the policy matches nothing and the role loses read on the bucket (`docs:` ABAC). *Mitigation (operator action):* the loss is intended per `[F2]`; if the platform team needs access at the moment of apply, ship a grant for `platform` first (separate PR) and re-tag second.
> 2. **Observability readiness, Yellow.** *Found:* the 4xx and 5xx alarms exist and are enabled, with thresholds 25 and 5 per 5 min over 2 periods (`live:`), against a 4xx baseline of at most 2 per 5 min; `main.tf:91-92` says a blocked reader shows as 4xx, which is not documented evidence. *Why:* a handful of denied manual reads may stay under 25 and go unnoticed. *Mitigation:* after the apply, run the success criteria and check the 4xx metric and CloudTrail for denied calls from the role.
> 3. **Security posture, Yellow.** *Found:* the change is an IAM-relevant permission scope change. The payments role narrows; the new value `platform` may match a policy or SCP outside this repo and widen access for other principals (`git grep` sees only this repo, lanes.md:120). *Why:* a tag edit can silently grant access. *Mitigation:* before merge, search the account's customer-managed policies and org SCPs for `aws:ResourceTag/team` with `platform`.
> 4. **Application compatibility, unknown.** *Found:* the tag is read by an IAM condition (app-facing); no app source was given (Q8 = (c)). *Why:* whether anything reads the bucket through that role is not known; failures may be silent. *Mitigation (the evidence that resolves it):* the app source (Q8 (a) or (b)), or `live:` last-accessed or CloudTrail data events showing no use of the role on this bucket for 30 days.
>
> **[H5] Pre-flight verdict is RED — soft block. Acknowledge each finding above (4 Yellow / unknown items, which together trigger the escalation) with a reason, or abort?** Say which of the mitigations you will do.

STOP 4: `[H5]`.

### Operator answer (script entry 5, `[H5]`)

> Acknowledged: findings 1, 2, 3 and 4 (the Red verdict). Reason: "ownership move approved by the platform team; the policy is updated in a separate ticket".

Clock: 11:04 + 5 = 11:09. The reason is recorded for each finding. No mitigation was committed to by name, so none is recorded as committed.

Pre-flight Step 7: record written (see `preflight-record.md`), left uncommitted, path `.culiops/pre-flight/paymentapi-exports-team-tag-20261109-1109.md`. The verdict, the findings and the acknowledgement go back to the caller. No target mismatch, no `[H1]`.

## Step 4c: Execute (full lane, PR path, `[F4]`)

H7 check for the mutation (a PR whose merge applies prod): the recorded exception (a), no staging env, evidence `code:` `envs/`. No `[H7]`. Single phase, single environment: no timing re-ask.

PR path step 2: stage exactly the approved file, then show the prompt.

```
[cmd 50] 11:10  git add main.tf
         canned: empty.txt -> no output
[cmd 51] 11:11  git status --short
         answered from the diff ->  M  main.tf    (staged; nothing else)
```

(Per protocol the status comes from the diff. In a real tree `tfplan` and `.terraform/` could show as untracked unless ignored; the fixture has no `.gitignore`. Only `main.tf` is staged, by explicit path.)

### Skill message shown to the operator

> **[F4] Open the PR?** On branch `iac-change/paymentapi-exports-team-tag-platform` (from `origin/main`), staged **only** this file: `main.tf`. On approval: commit, push, and open a PR.
> `git status` after staging: `M  main.tf` — no `tfplan` / state / `.terraform/` / unrelated files.
> Target: account `333333333333` / `assumed-role/paymentapi-operator` / `ap-southeast-1` (re-checked 10:58) · var-file `envs/prod.tfvars` · **Plan output:** 0 to add, 1 to change, 0 to destroy (`aws_s3_bucket.exports` tags and tags_all, `team`); plan hash `sha256:3044950c...b8217a`
> **Pre-flight verdict: RED — soft block**, acknowledged at `[H5]` (11:09) with the reason "ownership move approved by the platform team; the policy is updated in a separate ticket". Findings: dependency impact (Yellow), observability readiness (Yellow), security posture (Yellow), application compatibility (unknown); mitigations as listed in the report.
> **Staging-first (H7):** n/a — no staging env (`code:` `envs/` holds only `prod.tfvars`)
> PR will include: change summary, evidence table, pre-flight verdict, the `Staging-first:` line, execution record link.
> *Heads-up: say so and I draft one for the owners / reviewers / on-call with `change-comms` (draft-only; you send it).*

STOP 5: `[F4]`.

### Operator answer (script entry 4, `[F4]`)

> Approved: open the PR. (The RED verdict was acknowledged at `[H5]`. The heads-up line is skipped.)

Clock: 11:11 + 5 = 11:16.

```
[cmd 52] 11:17  git commit -m "exports: move the bucket team tag from payments to platform"
         canned: git-commit.txt, filled ->
           [iac-change/paymentapi-exports-team-tag-platform 7f3a9c1] exports: move the bucket team tag from payments to platform
            1 file changed, 1 insertion(+), 1 deletion(-)
[cmd 53] 11:18  git push -u origin iac-change/paymentapi-exports-team-tag-platform
         canned: git-push.txt, filled -> * [new branch]  iac-change/paymentapi-exports-team-tag-platform -> iac-change/paymentapi-exports-team-tag-platform
[cmd 54] 11:19  gh pr create --title "exports: move the bucket team tag from payments to platform" --body <body>
         canned: gh-pr-create.txt -> https://github.com/acme/paymentapi-infra/pull/142
```

PR body (no plan text, no state, no secrets): change summary (the `team` tag on `aws_s3_bucket.exports`, `payments` -> `platform`, prod, one in-place change); the evidence table (12 rows); pre-flight verdict (RED — soft block, acknowledged at `[H5]`, reason as above, findings with mitigations); `**Staging-first:** n/a — no staging env (code: envs/ holds only prod.tfvars)`; execution record link `.culiops/iac-change-execution/paymentapi-exports-team-tag-20261109-1119.md`.

## Step 5: Verify and record

5a, PR path, delivery model "CI applies on merge" (`operator-stated`): "PR https://github.com/acme/paymentapi-infra/pull/142 created. After merge, the CI pipeline applies it." The skill waits for the operator to say the apply landed; the script has no such message, so the run ends here. No success-criteria read ran (they need the applied change). The record says `Applied: no — PR open`.

5b: execution record written to `.culiops/iac-change-execution/paymentapi-exports-team-tag-20261109-1119.md` (see `record.md`), left uncommitted (`CULIOPS_HOME` unset, so the commit offer is the `Next:` line).

### Final message shown to the operator

> The change is in PR https://github.com/acme/paymentapi-infra/pull/142 (branch `iac-change/paymentapi-exports-team-tag-platform`, commit `7f3a9c1`). Nothing is applied: after merge, the CI pipeline applies it (operator-stated). Pre-flight verdict was RED — soft block (compound: dependency impact, observability readiness, security posture Yellow; application compatibility unknown), acknowledged at `[H5]`. Execution record: `.culiops/iac-change-execution/paymentapi-exports-team-tag-20261109-1119.md`. Pre-flight record: `.culiops/pre-flight/paymentapi-exports-team-tag-20261109-1109.md`.
> Next: commit the record (`.culiops/iac-change-execution/paymentapi-exports-team-tag-20261109-1119.md`) · draft the result or ticket-close message with change-comms · tell me when the apply lands and I run the success criteria

End of run: the skill printed its final message.

---

## Ambiguities and judgment calls (with the line relied on)

1. **Where the research summary shows in the full lane.** `SKILL.md:217` says it is shown "with the lane's next stop (`[F2]` full)", but `SKILL.md:199` puts `[F1]` before Step 2, and the summary needs the batch results. I showed a short preface at `[F1]` (root, identity, tier, lane and why, duplicate check, delivery model; `SKILL.md:169` and `:199`, Constraint 13 "first stop") and the full summary at `[F2]`. No stop was added.
2. **Intent question inside `[F2]`.** No line forces asking whether the role's loss of access is intended. I put it in the plan's blast radius and disruption (`SKILL.md:233-235`, Constraint 9) and asked it inside `[F2]` like the delivery-model question (`SKILL.md:188`). It adds no stop.
3. **Tag as app-facing.** The assessor's not-app-facing list says "tags that nothing reads at runtime" (`iac-change.md:213`); the IAM condition reads this one, so category 11 is triggered and Q8 was asked (`SKILL.md:280`, `pre-flight SKILL.md:107`).
4. **RED from the multi-Yellow rule, and `[H5]`.** `pre-flight SKILL.md:341` says "acknowledge each Red finding", but no category is individually Red (`:67`, `:316`). I asked for acknowledgement of the escalation and of each Yellow or unknown finding. The scores of categories 1, 5 and 7 are my reading of the assessor; the verdict is RED for any reading that keeps 4, 9 and 11 non-Green.
5. **Plan-time disruption.** In the full lane the plan command runs after `[F3]`, so at `[F2]` the bucket's disruption has no `plan:` evidence; I did not present it as `none` (`SKILL.md:235`) and let 4a confirm it.
6. **No pre-flight extra stop.** The caller block carried every field and all L2 answers, and the one read pre-flight lacked (last apply) cannot be built without a state bucket, so pre-flight added no L2 or L3 stop (`pre-flight SKILL.md:111`, `:134`).
7. **Canned lookups.** No lookup returned `no canned output`. Not looked up on purpose: `terraform workspace show` (workspace taken as `operator-stated`), the state-bucket `head-object` (no backend declared), a docs entry for 403s in `4xxErrors` (would only raise a score), SNS reads (no alarm is changed).
