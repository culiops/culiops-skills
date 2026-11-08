# Dry-run notes: `dev-lane`

## Baseline (v0.17.0)

Run: `baseline-output/` with `operator-script.md`, and `baseline-output-mismatch/` with `operator-script-mismatch.md`. Skill text from `origin/main` (v0.17.0).

- `operator-script.md`: **Stops: 14**; 1 `unscripted` (health-check offer). Verdict RED soft block (category 7: no alarms on the dev service). Outcome: applied. A dev change went through the full prod process.
- `operator-script-mismatch.md`: **Stops: 3** (delivery model, read batch, target-mismatch Red Flag); 0 `unscripted`. The run stopped at the mismatch only through a Red Flag. The old skill has no hard identity gate.
