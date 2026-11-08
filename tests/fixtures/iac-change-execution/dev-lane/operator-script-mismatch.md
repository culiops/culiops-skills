# Operator script — dev-lane (credentials mismatch)

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Raise the ECS task CPU for paymentapi in dev from 256 to 512."

## Answers by stop

1. `[H1]` — abort. The operator says: "My shell is on the prod profile. I will switch to the dev credentials and start again." Nothing else is asked or answered.

With this script the operator's shell is on the prod profile: STS returns the prod account for every call (see `canned/INDEX.md`).

If the skill asks anything before `[H1]`, answer as `operator-script.md` does: Q8 (if asked)=(c) the application source is not available; the assessor's IaC questions iac-change.1=yes, iac-change.2=terraform is applied by hand (operator-stated), iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent.

## Answers by meaning

For a run of the old v0.17.0 skill, which has no stop IDs and no hard gate for a wrong account. Answer every stop as `operator-script.md` does until the skill shows that the active account does not match the environment the plan is for (the 4a target check reads `match: NO`, or an earlier read shows account `333333333333`). Abort at that point: the skill stops and writes an `ABORTED` record.

- Optional offers (a change-comms heads-up, polling, committing the record): no.
- Pre-flight L2 questions and the assessor's IaC questions, if the old skill reaches them before the abort: the answers in the by-stop paragraph above and in `operator-script.md`.
