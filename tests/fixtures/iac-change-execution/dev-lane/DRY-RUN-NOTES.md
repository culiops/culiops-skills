# Dry-run notes: `dev-lane`

## Baseline (v0.17.0)

Run: `baseline-output/` with `operator-script.md`, and `baseline-output-mismatch/` with `operator-script-mismatch.md`. Skill text from `origin/main` (v0.17.0).

- `operator-script.md`: **Stops: 14**; 1 `unscripted` (health-check offer). Verdict RED soft block (category 7: no alarms on the dev service). Outcome: applied. A dev change went through the full prod process.
- `operator-script-mismatch.md`: **Stops: 3** (delivery model, read batch, target-mismatch Red Flag); 0 `unscripted`. The run stopped at the mismatch only through a Red Flag. The old skill has no hard identity gate.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 1** (target 1): D1. `unscripted`: 0.
- Before → after: **14 → 1** stops.

## Findings and fixes

Per-MUST results from the verifier:

### dev-lane (expected-output, `operator-script.md`)
Stops: 1 (target 1) — PASS. Unscripted: 0. No pre-flight run, so no RED and no `[H5]`.

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` is one line, `D1`; no A, B, F1-F4, no H3; no read-batch stop | PASS | `S:1` (`STOP 1: D1`). Transcript search: no `[A]`, `[B]` as stops (mentions only in notes `T:506`); `[H3]` only as "no `[H3]`" `T:341`. Batch ran with no stop `T:93-171` | — |
| 2 | `**Lane:** dev` cites `envs/dev.tfvars:3`, `providers.tf:16`, identity `111111111111`; `**Environment tier:** dev=dev (...)`, not operator-stated | PASS | `R:9` (`live: aws sts get-caller-identity` → 111111111111 equals `code: envs/dev.tfvars:3` and `code: providers.tf:16`); `R:11` `dev=dev (live: account 111111111111 = code: envs/dev.tfvars:3, providers.tf:16)`; no `operator-stated` | — |
| 3 | `- Pre-flight verdict: skipped — dev lane (<evidence>)` in record; no `preflight-record.md`; no pre-flight invoked | PASS | `R:64` (with `live:` and `code:` evidence); out-dir holds only `record.md`, `stops.md`, `transcript.md`; `T:3`, `T:347-349` ("Dev lane: no pre-flight"); no caller block anywhere in the transcript | — |
| 4 | Reads and plan ran before `[D1]` with no stop; `[D1]` shows diff, plan output, target together; summary names the `aws_ecs_task_definition.paymentapi` replacement | PASS | Reads `T:97-169` (10:09-10:27), plan `T:289` (10:38), `[D1]` message `T:357-415`: diff lines `T:401-403`, plan output `T:405-408`, target `T:364`, `T:400`; replacement named `T:376`, `T:398`, `T:406`; plan says "must be replaced" `T:313` | — |
| 5 | Diff self-check and duplicate check shown as run; fresh eyes `skipped — dev lane` | PASS | Duplicate check `T:48-79`; diff self-check `T:257-273` (6/6); `R:17`, `R:59`; fresh eyes `T:275`, `R:60` | — |
| 6 | Apply only after `[D1]` is answered; re-plan after reads `No changes.` | PASS | `[D1]` `T:410`; answer 10:45 `T:419-422`; apply 10:46 `T:430`; no `terraform apply` earlier. Re-plan `T:450-452` and `R:67` `No changes. Your infrastructure matches the configuration.` | — |
| 7 | `**Staging-first:** n/a — no staging env (<evidence>)`; `**Waived:** none` | PASS | `R:12` (`envs/` holds `dev.tfvars` and `prod.tfvars` only); `R:13` | — |
| 8 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0; `T:506` | — |


No fixes needed (operator-script.md).

## Dry-run (v0.18) — `operator-script-mismatch.md`

Run: `expected-output-mismatch/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 1** (target 1 (H1)): H1. `unscripted`: 0.
- Before → after: **3 → 1** stops.

## Findings and fixes — `operator-script-mismatch.md`

Per-MUST results from the verifier:

### dev-lane (expected-output-mismatch, `operator-script-mismatch.md`)
Stops: 1 (target 1) — PASS. Unscripted: 0.

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` is one line, `H1`; no `[D1]` | PASS | `S:1` (`STOP 1: H1`); no `[D1]` string in `T` | — |
| 2 | `[H1]` stop shows both accounts: `333333333333` and the pin `111111111111` (`envs/dev.tfvars:3`) | PASS | `T:50` (dev pin 111111111111, `code: envs/dev.tfvars:3`), `T:51` (active identity 333333333333) | — |
| 3 | No plan or read command after the identity read; transcript is only the stop and the abort after it | PASS | The only command is `aws sts get-caller-identity` (`T:18-21`). After it: tier mapping from local fixture files (`T:34-44`, the pin comparison H1 needs, not a read command), the `[H1]` message `T:48-54`, the operator abort `T:58-62`, abort and final message `T:64-72`. No `terraform`, `git`, `gh` or further `aws` command (search of `T`). The closing "Notes on the skill text" (`T:74-80`) is commentary | — |
| 4 | `record.md`, if written, says `Outcome: aborted`; no pre-flight, no code change, no PR | PASS | `R:47-48` (`## Outcome` then `aborted`; `**Applied:** no — not applied (aborted at [H1] ...)` `R:50`); `R:37` `Files changed: none`; `R:43` pre-flight `not run — aborted at [H1]`; `R:44` `Execution: none`; `T:66-68` no branch, no code, no plan | — |
| 5 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0 | — |


No fixes needed (operator-script-mismatch.md).
