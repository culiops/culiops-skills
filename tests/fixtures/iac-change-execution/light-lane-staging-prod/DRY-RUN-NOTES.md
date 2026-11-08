# Dry-run notes: `light-lane-staging-prod`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 13**; 1 `unscripted` (pre-flight L2 with Q8).
- Verdict YELLOW. Outcome: **prod applied with no staging phase.** The old skill never reads, plans or applies staging. This is the MUST failure the v0.18 change fixes (staging-first).
- The direct-apply path left the code uncommitted.
