# Dry-run notes: `light-escalation-alarm-action`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 16**; 1 `unscripted` (the assessor questions asked as a separate prompt).
- Verdict RED soft block (categories 1, 4, 7, 11 Yellow or ⚪). Outcome: PR opened.
- The scaling action on the copied alarm got no special handling: no escalation and no extra review. Fresh eyes was skipped by the add-only rule even though the alarm scales the service.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 5** (target 4 (+1 per RED pre-flight)): F1,F2,F3,H5,F4. `unscripted`: 0.
- Before → after: **16 → 5** stops.

## Findings and fixes

Per-MUST results from the verifier:

### light-escalation-alarm-action (expected-output)
Stops: 5 (target 4 + 1 H5 = 5; one pre-flight run, RED, `preflight-record.md:17`) — PASS. Unscripted: 0 (`grep -c unscripted stops.md` = 0).

Order in `stops.md:1-5`: F1, F2, F3, H5, F4.

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` lists F1-F4 (+H5 before F4); first stop F1; no `[A]`/`[B]`/`[D1]` | PASS | `stops.md:1-5`; first stop is `F1` at `stops.md:1`; grep for `[A]`/`[B]`/`[D1]` in `stops.md`, `record.md` and `transcript.md` finds none | |
| 2 | `**Escalations:** E1 — <evidence>` cites `main.tf:252` or `:250` and names the scale-out policy reference; `**Lane:** full — <basis>` points at it | PASS | `record.md:11`: `**Escalations:** E1 — alarm_actions[1] is aws_appautoscaling_policy.paymentapi_scale_in.arn ... Evidence: code: main.tf:250-253 (the CPU-high alarm this one is "wired like" carries the scale-out policy), code: main.tf:213, code: main.tf:280-283, plan: ... alarm_actions[1]`. `record.md:10`: `**Lane:** full — E1 escalation recorded at Step 1 (Lane rule line 1)`. Note: the cite is the range `250-253`, which contains both accepted lines. The scale-out policy is named in prose ("carries the scale-out policy"), not as `aws_appautoscaling_policy.paymentapi_scale_out.arn`; the full reference appears only in `transcript.md:57`. Accepted on content | |
| 3 | Lane not downgraded after the single-create plan | PASS | `transcript.md:379` ("the lane was full from Step 1 (E1) and never goes down"; E1 re-confirmed on the plan); `record.md:10` still `full` | |
| 4 | `**Staging-first:** n/a — no staging env (<evidence>)` naming only `envs/prod.tfvars`; `- Parity check: n/a` | PASS | `record.md:13`: `n/a — no staging env (code: envs/ holds only prod.tfvars; no staging var-file, workspace or overlay is defined)`; `record.md:67`: `- Parity check: n/a`; `transcript.md:381` | |
| 5 | `**Environment tier:** prod=prod (...)` citing the pin and the identity account (not `operator-stated`) | PASS | `record.md:12`: `prod=prod (live: aws sts get-caller-identity ... account 333333333333 ...; code: envs/prod.tfvars:3 pins aws_account_id, set as allowed_account_ids at providers.tf:16)` | |
| 6 | Q8 asked inside `[F2]` and answered (c); category 11 not scored Green from the plan alone | PASS | Q8 in the `[F2]` message `transcript.md:236`; answered `transcript.md:248` (`Q8=(c)`); category 11 scored UNKNOWN (README's ⚪) at `transcript.md:469`, `preflight-record.md:35`, with the scaling action making the alarm app-facing (`transcript.md:447`) | |
| 7 | RED verdict ends in an `H5` stop, logged as `H5` | PASS | `stops.md:4`: `STOP 4: H5 — RED soft block ...`; `transcript.md:510-512`; the `[H5]` prompt opens the pre-flight GATE 2 inline, and `[H5]` precedes `[F4]` | |
| 8 | `**Waived:** none` | PASS | `record.md:14` | |
| 9 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0; `grep unscripted` over all four files finds none | |

Result: 9 of 9 pass.

Notes (not MUST failures):
- The `[F2]` question list (`transcript.md:230-237`) skips Q6 (the operator volunteers it at `transcript.md:248`). Pre-flight treats Q6 as supplied (`preflight-record.md:82`). The tag-abac runner's own note (`light-escalation-tag-abac/expected-output/transcript.md:228`) says `SKILL.md:280` omits Q6; I did not re-check that line.
- Pre-flight scoring differs slightly from the README (Blast radius Yellow, Observability Yellow, category 11 UNKNOWN); the README accepts RED via 3+ Yellow/unknown either way.


No fixes needed. The `[H5]` stop is the accepted realistic RED documented in the README scoring table.
