# Dry-run notes: `light-escalation-tag-abac`

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 15**; 0 `unscripted`.
- Verdict RED soft block (categories 1, 4, 7, 9 Yellow; 11 ⚪). Outcome: PR opened.
- The duplicate-check grep surfaced the IAM `aws:ResourceTag/team` condition, but only as a blast-radius note and a Yellow, not as a decision point.
