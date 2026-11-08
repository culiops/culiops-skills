# Dry-run notes: `light-escalation-alarm-action`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 16**; 1 `unscripted` (the assessor questions asked as a separate prompt).
- Verdict RED soft block (categories 1, 4, 7, 11 Yellow or ⚪). Outcome: PR opened.
- The scaling action on the copied alarm got no special handling: no escalation and no extra review. Fresh eyes was skipped by the add-only rule even though the alarm scales the service.
