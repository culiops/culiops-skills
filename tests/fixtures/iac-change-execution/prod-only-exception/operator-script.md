# Operator script — prod-only-exception

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Raise the paymentapi prod CPU alarm threshold from 80 to 90."

## Answers by stop

1. `[F1]` — approve the read batch: every command shown, the target check included.
2. `[F2]` — approve the plan. L2: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none. If asked to justify changing prod without a staging run, the operator gives this justification inside this stop, in these words: "Staging has no CPU alarm and runs one task at about 12 percent CPU, so a threshold change there exercises nothing. 90 only makes sense against prod's CPU profile, where the alarm fired 4 times in the last week at readings of 85 to 88 percent." Delivery model, if asked: PR, and a CI pipeline applies on merge (operator-stated).
3. `[F3]` — approve the code.
4. `[F4]` — approve: open the PR. Approving also acknowledges a YELLOW verdict, if one is shown. Skip the optional heads-up line.
5. `[H5]` — only if a pre-flight verdict is RED. Acknowledge each Red finding, reason: "the threshold change is deliberate, the alarm is flapping at 85 to 88 percent".

## Answers by meaning

For a run of the old v0.17.0 skill, which has no stop IDs. Map each question to the script entry that covers its intent. Approve or answer yes to anything the script's intent covers, and give the same L2 answers.

- Step 1 read batch (the live verification batch): approve every command shown.
- GATE 1 (the plan): approve. Execution path: PR.
- GATE 2 (the code): approve.
- 4a target check (`Proceed?`): yes.
- Pre-flight GATE 1 (scope and target): confirm.
- Pre-flight L2 questions: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none.
- Pre-flight L3 opt-in: yes. Pre-flight GATE 2 (risk decision): acknowledge and proceed.
- GATE 3 (clearance) and GATE 4 (execution): approve.
- Optional offers (a change-comms heads-up, polling the PR checks or the sync status, committing the record at GATE 5): no. They are not covered by the script's intent. They still count as stops.
- Delivery-model question (UNVERIFIED in the repo): a CI pipeline applies on merge.
- The old skill has no staging-first rule. If it asks why only prod changes, give the justification text from the `[F2]` entry.
