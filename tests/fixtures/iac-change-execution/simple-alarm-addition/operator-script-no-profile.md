# Operator script — simple-alarm-addition (no operator profile)

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Add a CloudWatch CPU utilization alarm for paymentapi in prod."

With this script the operator has no profile yet: the `operator profile read` row for this script returns "file not found" (see `canned/INDEX.md`). The skill cannot take Q4 and Q5 from a profile, so it asks them inside `[A]` and says it will remember them in the profile path. Q4 and Q5 are not marked `if asked` here: the operator says them in the `[A]` answer, and the runner logs each as `L2-ASKED`. Every other L2 item is `if asked`, as in `operator-script.md`.

## Answers by stop

1. `[A]` — approve. Operator line: no reply. L2: Q1 (if asked)=no, Q2 (if asked)=no, Q3 (if asked)=no, Q4=many times, Q5=experienced, Q6 (if asked)=negligible, Q7 (if asked)=none, Q8 (if asked)=(c) the application source is not available, iac-change.1 (if asked)=yes, iac-change.2 (if asked)=a CI pipeline applies on merge (operator-stated), iac-change.3 (if asked)=no (default workspace; the env's own var-file), iac-change.4 (if asked)=recent. Tier: prod (operator-stated). Delivery model, if asked: a CI pipeline applies on merge (operator-stated). Read batch: approve every command shown.
2. `[B]` — approve: open the PR. Skip the optional heads-up line.
