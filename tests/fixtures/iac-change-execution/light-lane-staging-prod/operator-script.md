# Operator script — light-lane-staging-prod

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR."

## Answers by stop

1. `[A]` — approve. L2: Q1=no, Q2=no, Q3=no, Q4=a few times, Q5=experienced, Q6=negligible, Q7=none. Delivery model, if asked: terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated). Plan order, if asked: staging first, then prod, with prod starting once staging's success criteria pass. Read batch: approve every command shown, for both environments.
2. `[B]` (staging) — approve the apply command shown for staging. Approving also acknowledges a YELLOW verdict, if one is shown.
3. `[B]` (prod) — approve the apply command shown for prod. Approving also acknowledges a YELLOW verdict, if one is shown.

Both environments' credentials are available. When the skill moves from staging to prod, the operator switches the shell profile without a stop.

## Answers by meaning

For a run of the old v0.17.0 skill, which has no stop IDs. Map each question to the script entry that covers its intent. Approve or answer yes to anything the script's intent covers, and give the same L2 answers.

- Step 1 read batch (the live verification batch): approve every command shown.
- GATE 1 (the plan): approve. Execution path: direct apply.
- GATE 2 (the code): approve.
- 4a target check (`Proceed?`): yes.
- Pre-flight GATE 1 (scope and target): confirm.
- Pre-flight L2 questions: Q1=no, Q2=no, Q3=no, Q4=a few times, Q5=experienced, Q6=negligible, Q7=none.
- Pre-flight L3 opt-in: yes. Pre-flight GATE 2 (risk decision): acknowledge and proceed.
- GATE 3 (clearance) and GATE 4 (execution): approve.
- Optional offers (a change-comms heads-up, polling the PR checks or the sync status, committing the record at GATE 5): no. They are not covered by the script's intent. They still count as stops.
- Delivery-model question (UNVERIFIED in the repo): terraform is applied by hand from my workstation, and a direct apply is fine.
- The old skill knows one environment. Answer its target check for prod only. If it asks which environment to change, the answer is prod.
- GATE 4 (the apply command): approve.
