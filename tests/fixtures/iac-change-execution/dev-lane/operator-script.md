# Operator script — dev-lane

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Raise the ECS task CPU for paymentapi in dev from 256 to 512."

## Answers by stop

1. `[D1]` — apply directly from my workstation. Delivery model, if asked: terraform is applied by hand (operator-stated). The dev lane runs no pre-flight, so these are said only if asked: Q8 (if asked)=(c) the application source is not available; the assessor's IaC questions iac-change.1=yes, iac-change.2=terraform is applied by hand (operator-stated), iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent.

With this script the operator's credentials are for the dev account (see `canned/INDEX.md`).

## Answers by meaning

For a run of the old v0.17.0 skill, which has no stop IDs. Map each question to the script entry that covers its intent. Approve or answer yes to anything the script's intent covers, and give the same L2 answers.

- Step 1 read batch (the live verification batch): approve every command shown.
- GATE 1 (the plan): approve. Execution path: direct apply.
- GATE 2 (the code): approve.
- 4a target check (`Proceed?`): yes.
- Pre-flight GATE 1 (scope and target): confirm.
- Pre-flight L2 questions: Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8 (if asked)=(c) the application source is not available. The assessor's IaC questions, asked after them: iac-change.1=yes, iac-change.2=terraform is applied by hand from my workstation, iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent.
- Pre-flight L3 opt-in: yes. Pre-flight GATE 2 (risk decision): acknowledge and proceed.
- GATE 3 (clearance) and GATE 4 (execution): approve.
- Optional offers (a change-comms heads-up, polling the PR checks or the sync status, committing the record at GATE 5): no. They are not covered by the script's intent. They still count as stops.
- Delivery-model question (UNVERIFIED in the repo): terraform is applied by hand from my workstation.
- GATE 4 (the apply command): approve.
