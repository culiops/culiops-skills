# Operator script — light-lane-staging-prod (an alarm already firing in staging)

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Add a CloudWatch CPU utilization alarm for paymentapi in prod. Apply it directly, no PR."

With this script, in staging, the alarm `paymentapi-alb-elb5xx-staging` (on the load balancer in front of the service) is already in `ALARM` before the apply: the `describe-alarms --state-value ALARM` rows keyed to this script return it (see `canned/INDEX.md`). Prod has nothing firing. The alarm is a known flaky one, and the operator knows it. The operator is asked no L2 question about it: the skill reads it.

## Answers by stop

1. `[A]` — approve. Operator line: no reply. L2: Q1 (if asked)=no, Q2 (if asked)=no, Q3 (if asked)=no, Q4 (if asked)=many times, Q5 (if asked)=experienced, Q6 (if asked)=negligible, Q7 (if asked)=none, Q8 (if asked)=(c) the application source is not available, iac-change.1 (if asked)=yes, iac-change.2 (if asked)=terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated), iac-change.3 (if asked)=no (default workspace; the env's own var-file), iac-change.4 (if asked)=recent. Incident Context follow-up (if asked, at any stop): no, this change is not a mitigation for the alarm. Delivery model, if asked: terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated). Plan order, if asked: staging first, then prod, with prod starting once staging's success criteria pass. Read batch: approve every command shown, for both environments.
2. `[H5]` (staging) — staging's pre-flight is RED because of the firing alarm (category 5, which alone is a soft block, so an acknowledgement is enough). Acknowledge the Red finding, reason: "known flaky alarm, it has fired and cleared on its own for weeks, unrelated to the CPU alarm". If another `[H5]` appears for prod, it is not scripted.
3. `[B]` (staging) — approve the apply command shown for staging. Approving also acknowledges a YELLOW verdict, if one is shown.
4. `[B]` (prod) — approve the apply command shown for prod. Approving also acknowledges a YELLOW verdict, if one is shown. Q1–Q3 still true (if asked): yes, unchanged.

Both environments' credentials are available. When the skill moves from staging to prod, the operator switches the shell profile without a stop.
