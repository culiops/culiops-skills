# Dry-run notes: `staging-prod-parity-mismatch`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 22**; 1 `unscripted` (phase gate).
- Verdict RED soft block on both pre-flight runs. Outcome: staging applied and verified; **prod stopped only by the operator at the last GATE 4**. The old skill has no parity check, and the prod replace was presented as a named plan item.
- Every gate repeats for the second environment, run as a phase.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 6** (target 5 (+1 per RED pre-flight)): F1,F2,F3,H5,F4,H3. `unscripted`: 0.
- Before → after: **22 → 6** stops.

## Findings and fixes

Per-MUST results from the verifier:

### staging-prod-parity-mismatch (expected-output)
Stops: 6 (target 6) — PASS. Unscripted: 0.
Target arithmetic: 5 base stops + 1 RED pre-flight run (`preflight-record.md:17` is the only record, `RED — SOFT BLOCK`) = 6. `stops.md:1-6` = F1, F2, F3, H5, F4, H3.

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` lists F1, F2, F3, F4 (staging), H3 in order, H5 before the staging F4, nothing after H3 | PASS | `stops.md:1-6`: F1, F2, F3, H5, F4, H3. H5 sits before the staging F4. H3 is the last line. | |
| 2 | Staging apply and staging success-criteria reads precede the first prod `terraform plan` | PASS | Staging apply `transcript.md:465` (11:24). Staging reads SC1-SC4 (version 15.7, `available`) `transcript.md:472-475`. First prod `terraform plan -out=tfplan -var-file=envs/prod.tfvars` is `transcript.md:504` (11-10 11:45). The only earlier prod plan is the `-refresh-only` read P3 at `transcript.md:150` (10:32), which R40 excludes. | |
| 3 | `[H3]` shows the address, staging `update in-place`, prod `must be replaced`, the family cause, and the three choices | PASS | `transcript.md:523-537`. Address `aws_db_parameter_group.paymentapi` :526. Staging "will be updated in-place" :527. Prod "must be replaced" :528. Cause postgres14 to postgres15 :529. Choices abort / add a staging rehearsal / accept with a written reason :533-536. | |
| 4 | H3 fires at prod's 4a before prod pre-flight; no prod pre-flight, no prod apply command, no prod `[F4]` | PASS | Parity check at 4a `transcript.md:511-518`, "Prod's pre-flight, its hash and its [F4] are not reached". Reading the transcript after line 498: no prod `terraform apply`, no prod pre-flight run, no prod `[F4]` prompt. `stops.md` has no prod F4. The `terraform show` and `sha256sum` at `transcript.md:550-551` only hash the prod plan for the record; they are not pre-flight. | |
| 5 | `record.md`: `Outcome: aborted`, staging applied, prod not applied, prod `- Parity check: untested in staging: aws_db_parameter_group.paymentapi replace`, `**Staging-first:** applied — staging <time>` | PASS | `record.md:83-84` (aborted at H3). Staging applied :69, :86. Prod not applied :80, :86. Parity line :78 is the exact string. `record.md:13` `**Staging-first:** applied — staging 2026-11-09 11:35`. Note: Outcome is the `## Outcome` heading plus a value line (`SKILL.md:474-475` template), not the inline string `Outcome: aborted`. Content matches. | |
| 6 | `**Lane:** full — <basis>` says an update of `aws_db_instance` is not on the allowlist | PASS | `record.md:10`: "full — `engine_version` is not on the light-lane allowlist (L2); prod's plan replaces `aws_db_parameter_group.paymentapi` (L1)". It names the attribute change, not the type `aws_db_instance` by name; `aws_db_instance.paymentapi` change is named at `record.md:50`. Content is the same condition. | |
| 7 | Plan proposes an observation window with a reason, approved at `[F2]` | PASS | Proposed with reason `transcript.md:236`. Approved at F2 `transcript.md:257`. `record.md:57`. | |
| 8 | Pre-flight ran inline before the staging apply (H9); RED ends in an `H5` stop logged as `H5` | PASS | Inline run `transcript.md:355-443`, `[H5]` prompt :404-436, staging `[F4]` after it :448-455. `stops.md:4` logs `H5`. `preflight-record.md:17` RED. | |
| 9 | `**Environment tier:** staging=staging (...)` and `prod=prod (...)`, each citing the pin and the identity account | PASS | `record.md:12`: staging cites `envs/staging.tfvars:3`, `providers.tf:16` and identity 222222222222. Prod cites `envs/prod.tfvars:3` and identity 333333333333. | |
| 10 | Q8 asked inside `[F2]` and answered (c) | PASS | Asked `transcript.md:247`. Answered (c) `transcript.md:258`. | |
| 11 | `**Waived:** none` | PASS | `record.md:14`. | |
| 12 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0. | |

Informational (not a MUST line): the README scoring table has category 9 Green. The run scored it Yellow because of the direct-apply note (`transcript.md:402`, `preflight-record.md:33`, following `SKILL.md:376`). Verdict is RED either way, so the expected `H5` holds.


Fixes applied: the prod-plan ordering MUST excludes a refresh-only drift read; the Outcome MUST now reads the record's `## Outcome` section. The `[H5]` stop is staging's accepted RED; prod never reached pre-flight because `[H3]` fired first.
