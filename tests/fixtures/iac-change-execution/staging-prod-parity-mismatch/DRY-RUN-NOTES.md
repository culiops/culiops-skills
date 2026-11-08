# Dry-run notes: `staging-prod-parity-mismatch`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 22**; 1 `unscripted` (phase gate).
- Verdict RED soft block on both pre-flight runs. Outcome: staging applied and verified; **prod stopped only by the operator at the last GATE 4**. The old skill has no parity check, and the prod replace was presented as a named plan item.
- Every gate repeats for the second environment, run as a phase.
