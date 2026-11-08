# Operator script — multi-phase-rds-upgrade

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Increase max_connections to 200 for paymentapi prod RDS, then reboot so it takes effect. I am the DBA on the maintenance window. Apply directly, no PR."

## Answers by stop

1. `[F1]` — approve the read batch: every command shown, the target check included. Tier: prod (operator-stated).
2. `[F2]` — approve both phases. L2: Q1=no, Q2=no (the maintenance window is approved and there is no freeze), Q3=no (off-peak window), Q4=a few times, Q5=experienced, Q6=negligible, Q7=DBA on the maintenance window, #payments-oncall told about the reboot. Execution path: direct apply from my workstation (operator choice). Acknowledge any drift row shown.
3. `[F3]` (phase 1) — approve the code.
4. `[F4]` (phase 1) — approve the apply command shown. Approving also acknowledges a YELLOW verdict, if one is shown.
5. `[F4]` (phase 2) — approve the reboot command shown.
6. `[H5]` — only if a pre-flight verdict is RED. Acknowledge each Red finding, reason: "maintenance window approved, DBA on call, the failover is expected". A hard block gets the same written reason.

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
- Direct-apply escalation and the per-apply target check: approve.
- Phase gate (`Ready to proceed to Phase 2?`): yes. This is the old skill's stop between phase 1 and phase 2.
- GATE 4 for phase 2 (the reboot command): approve.
