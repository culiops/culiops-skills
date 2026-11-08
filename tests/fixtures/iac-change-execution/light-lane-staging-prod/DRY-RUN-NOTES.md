# Dry-run notes: `light-lane-staging-prod`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 13**; 1 `unscripted` (pre-flight L2 with Q8).
- Verdict YELLOW. Outcome: **prod applied with no staging phase.** The old skill never reads, plans or applies staging. This is the MUST failure the v0.18 change fixes (staging-first).
- The direct-apply path left the code uncommitted.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 3** (target 3): A,B,B. `unscripted`: 0.
- Before → after: **13 → 3** stops.

## Findings and fixes

Per-MUST results from the verifier:

### light-lane-staging-prod (expected-output)
Stops: 3 (target 3) — PASS. Unscripted: 0. RED pre-flight runs: 0 (`P:20`, `P:114` both YELLOW).

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` is `A`, `B`, `B`; no F1-F4, no D1; no separate stop for read batch, GATE 1/2, L3 opt-in, comms offer, record-commit | PASS | `S:1-3` (A, B staging, B prod). Transcript search: no `[F`, no `[D1]`; GATE mentions are "no GATE 1" / "no GATE 2" (`T:384`, `T:388`, `T:405`, `T:559`). Heads-up is an optional line inside each `[B]` (`T:432`, `T:601`), not taken (`T:438`, `T:607`) | — |
| 2 | Staging apply precedes the first prod `terraform plan` (R40: prod's change plan; refresh-only does not count) | PASS | Staging `terraform apply tfplan` `T:444` (10:54). Prod runs: refresh-only `T:488` (11:16), change plan `T:502` (11:18), both after `T:444`. Earlier prod-plan text at `T:223`, `T:249-278` is the proposed read batch in `[A]`, not an executed command | — |
| 3 | `**Staging-first:** applied — staging <time>` in record; prod phase has `- Parity check: pass` | PASS | `R:13` `applied — staging 10:54`; prod phase `R:78` `- Parity check: pass (prod create of ... matches staging's create ...)` (starts with the quoted string, adds an explanation); staging phase `R:67` `n/a` as `lanes.md:225` requires | — |
| 4 | Prod pre-flight cites staging evidence as `live: <cmd> (staging, <time>)` | PASS | Caller block `T:550-554`; prod record `P:145-148` e.g. `live: aws ecs describe-services (staging, 10:59)`, `live: terraform plan (staging, 10:55)`, `live: aws elbv2 describe-target-health (staging, 10:34 and 11:00)` | — |
| 5 | Pre-flight inline before each apply (H9), one per env; each `[B]` shows verdict (GREEN or YELLOW) | PASS | Staging: pre-flight `T:386-405`, `[B]` `T:427-432` (verdict YELLOW `T:430`), apply `T:444`. Prod: pre-flight `T:557-591`, `[B]` `T:593-601` (verdict YELLOW `T:600`), apply `T:613`. Two records `P:3`, `P:97`. No RED, so no `[H5]` | — |
| 6 | Each `[B]` shows exactly one apply command and re-shows the target check: `222222222222` at staging, `333333333333` at prod | PASS | Staging `[B]` `T:429` (one command `terraform apply tfplan`, account 222222222222, re-checked 10:41 and 10:47); prod `[B]` `T:599` (one command, account 333333333333, re-checked 11:17 and 11:22) | — |
| 7 | `**Lane:** light` cites `plan:` for L1 and the allowlist entry for L2; `**Escalations:** none` | PASS | `R:10` ("`plan:` staging 10:42 and prod 11:18, line 42: 1 to add, 0 to change, 0 to destroy"; "allowlist row 1"); `R:11` `none` | — |
| 8 | `**Environment tier:** staging=staging (...)` and `prod=prod (...)`, each citing the pin and identity account; neither `operator-stated` | PASS | `R:12`: staging proven (`live` 222222222222 at 10:01 and 10:41 = `envs/staging.tfvars:3`, `providers.tf:16`); prod proven (`live` 333333333333 at 11:17 = `envs/prod.tfvars:3`, `providers.tf:16`). No `operator-stated` on either | — |
| 9 | Direct apply flagged to pre-flight as a local workstation apply (A4) | PASS | Caller block `T:359`, `T:528` ("local workstation apply — not going through CI/CD pipeline"); `P:12`, `P:106`; scored as +1 step on categories 1 and 9 (`T:411`, `T:419`); wording from `SKILL.md:373`. The literal id `A4` is not cited in the caller block (it is in the `[A]` text, `T:234`) | — |
| 10 | Record ends `Outcome: completed` with `**Applied:** yes — verified` citing success-criteria outputs after each apply; `**Waived:** none` | PASS | `R:83-84` (`## Outcome` then `completed`); `R:86` `**Applied:** staging yes — verified (success criteria 1-6 at 10:55-11:00, outputs above); prod yes — verified (... 11:30-11:35 ...)`; outputs at `R:70`, `R:81`; `R:14` `**Waived:** none`. Form note: the per-env `Applied:` clauses are what `lanes.md:225` requires for staging-first, and `## Outcome` plus a value line is the `SKILL.md` 5b template, so the MUST's literal strings are read for content | — |
| 11 | Branch created and code written before `[A]`, after a clean `git status` | PASS | `git status --short` clean `T:86` (10:09); switch `T:89`; code and diff `T:99-143`; `[A]` at `T:168` (10:17) | — |
| 12 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0 | — |


Fix applied: the prod-plan ordering MUST now says a `terraform plan -refresh-only` drift read in the first approved batch does not count (it is a read, not prod's change plan).
