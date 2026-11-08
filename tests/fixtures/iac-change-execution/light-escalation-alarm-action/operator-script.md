# Operator script — light-escalation-alarm-action

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one."

## Answers by stop

1. `[F1]` — approve the read batch: every command shown, the target check included.
2. `[F2]` — approve the plan. L2: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8=(c) the application source is not available, iac-change.1=yes, iac-change.2=PR, and a CI pipeline applies on merge (operator-stated), iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent. Alarm details, if asked: threshold 20 percent, 3 periods of 5 minutes, otherwise the same as CPU-high. Delivery model, if asked: PR, and a CI pipeline applies on merge (operator-stated).
3. `[F3]` — approve the code.
4. `[F4]` — approve: open the PR. Approving also acknowledges a YELLOW verdict, if one is shown. Skip the optional heads-up line.
5. `[H5]` — only if a pre-flight verdict is RED. Acknowledge each Red finding, reason: "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged".

## Answers by meaning

For a run of the old v0.17.0 skill, which has no stop IDs. Map each question to the script entry that covers its intent. Approve or answer yes to anything the script's intent covers, and give the same L2 answers.

- Step 1 read batch (the live verification batch): approve every command shown.
- GATE 1 (the plan): approve. Execution path: PR.
- GATE 2 (the code): approve.
- 4a target check (`Proceed?`): yes.
- Pre-flight GATE 1 (scope and target): confirm.
- Pre-flight L2 questions: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8=(c) the application source is not available. The assessor's IaC questions, asked after them: iac-change.1=yes, iac-change.2=PR, and a CI pipeline applies on merge, iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent.
- Pre-flight L3 opt-in: yes. Pre-flight GATE 2 (risk decision): acknowledge and proceed.
- GATE 3 (clearance) and GATE 4 (execution): approve.
- Optional offers (a change-comms heads-up, polling the PR checks or the sync status, committing the record at GATE 5): no. They are not covered by the script's intent. They still count as stops.
- Delivery-model question (UNVERIFIED in the repo): a CI pipeline applies on merge.
- Pre-flight Q8 (application source): (c) not available.
