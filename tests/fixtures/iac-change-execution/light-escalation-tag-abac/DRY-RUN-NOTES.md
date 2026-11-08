# Dry-run notes: `light-escalation-tag-abac`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 15**; 0 `unscripted`.
- Verdict RED soft block (categories 1, 4, 7, 9 Yellow; 11 ⚪). Outcome: PR opened.
- The duplicate-check grep surfaced the IAM `aws:ResourceTag/team` condition, but only as a blast-radius note and a Yellow, not as a decision point.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 5** (target 4 (+1 per RED pre-flight)): F1,F2,F3,H5,F4. `unscripted`: 0.
- Before → after: **15 → 5** stops.

## Findings and fixes

Per-MUST results from the verifier:

### light-escalation-tag-abac (expected-output)
Stops: 5 (target 4 + 1 `[H5]` for 1 RED pre-flight run = 5) — PASS. Unscripted: 0.

`stops.md` order: F1, F2, F3, H5, F4 (`stops.md:1-5`). `preflight-record.md` holds one pre-flight run, verdict RED (`preflight-record.md:17`).

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` lists F1–F4 (+H5); first stop F1; no `[A]`/`[B]`/`[D1]` | PASS | `stops.md:1-5`; grep for `[A]`, `[B]`, `[D1]` in `stops.md` and `record.md` returns nothing | |
| 2 | `**Escalations:** E2 — <evidence>` citing `code: main.tf:72`, the `aws:ResourceTag/team` line of `aws_iam_policy.team_bucket_read`, changed key `team`; `**Lane:** full — <basis>` points at it | PASS | `record.md:12` is `**Escalations:** E2 — ` with `code: main.tf:72`, the condition, `aws_iam_policy.team_bucket_read`, "changed key `team`"; `record.md:11` `**Lane:** full — the light allowlist matched ... but E2 and E3 hit; Lane rule line 1`. A second line `record.md:13` records E3 (one full line per hit, `SKILL.md:483`) | |
| 3 | `git grep` for tag key `team` before the lane is decided | PASS | `transcript.md:77` (`git grep -n -E 'aws:(ResourceTag\|RequestTag)/team\|aws:TagKeys'`) and `:79` (`git grep -n -F 'team'`) both precede the lane decision at `:94` | |
| 4 | Lane not downgraded after the tags-only plan | PASS | `transcript.md:416` "L4 fails (E2, E3), so full stands; nothing to add and nothing is downgraded" after the plan at `:409` (`0 to add, 1 to change, 0 to destroy`) | |
| 5 | `[F2]` change summary names `aws_iam_policy.team_bucket_read`, role `paymentapi-engineers-prod`, and loss of `s3:GetObject` and `s3:ListBucket` | PASS | `transcript.md:266` and `:276` name `aws_iam_policy.team_bucket_read`; `:277` names the role `paymentapi-engineers-prod` and says it "loses `s3:GetObject` and `s3:ListBucket` on this bucket"; `:304` intent question | |
| 6 | `**Staging-first:** n/a — no staging env (<evidence>)` with `envs/prod.tfvars` the only env file named; `- Parity check: n/a` | PASS | `record.md:15` `n/a — no staging env (`code: envs/` holds only `prod.tfvars`; the repo defines no other environment)`; `record.md:66` `- Parity check: n/a`; `transcript.md:416` | |
| 7 | Q8 asked inside `[F2]`, answered (c) | PASS | Q8 in the `[F2]` message `transcript.md:299`; answer `transcript.md:312` (Q8=(c)) | |
| 8 | `**Environment tier:** prod=prod (...)` citing the pin and identity account, not `operator-stated` | PASS | `record.md:14` cites `live: aws sts get-caller-identity` 10:01 and 10:58, account 333333333333 = `code: providers.tf:16` / `envs/prod.tfvars:3`; no `operator-stated` in the line | |
| 9 | RED verdict ends in an `H5` stop, logged as `H5` | PASS | `stops.md:4` `STOP 4: H5`; `transcript.md:539-541`; `record.md:67` acknowledged at `[H5]` | |
| 10 | `**Waived:** none` | PASS | `record.md:16` | |
| 11 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0 | |

Observation (not a MUST line, no FAIL): the README scoring table has category 7 Green (alarms exist and are enabled, `A:165`); the runner scored 7 Yellow because the 4xx/5xx alarms are static count thresholds (`preflight-record.md:31`, `assessors/iac-change.md:166`). It gives 4 Yellow or unknown (4, 7, 9, 11) instead of 3 (4, 9, 11). The verdict is RED either way and the stop count is unchanged.


Fix applied after the first v0.18 run: the record wrote a bare `**Escalations:**` header with a list. SKILL.md 5b now says each hit is its own full `**Escalations:** <id> — <evidence>` line. Re-run: the table above is from the re-run. The `[H5]` stop is the accepted realistic RED.
