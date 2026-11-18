# Operator script — dependency-regression (the operator judges the regression unrelated)

This script answers the stops of a dry run (see `../DRY-RUN-PROTOCOL.md`). Match each stop by its ID. Answer by the intent written here. Items given inside a stop are said in that stop's answer.

**First message:** "Remove the 10.20.0.0/16 ingress rule from the orders-db security group: staging first, then prod. I apply with terraform by hand from my workstation, no PR."

Both environments' credentials are available. When the skill moves from staging to prod, the operator switches the shell profile without a stop. The app source is not available (the sibling search finds nothing, `canned/INDEX.md`), so Q8 is asked and answered (c): the one L2 item this script says.

## Answers by stop

1. `[F1]` — approve the read batch: every command shown, for both environments, the target check included. Tier: staging and prod as the var-files pin them.
2. `[F2]` — approve the plan: staging first, then prod, with the observation window the plan proposes. Operator line: no reply. L2: Q1 (if asked)=no, Q2 (if asked)=no, Q3 (if asked)=no, Q4 (if asked)=many times, Q5 (if asked)=experienced, Q6 (if asked)=negligible, Q7 (if asked)=none, Q8 (if asked)=(c) the application source is not available, iac-change.1 (if asked)=yes, iac-change.2 (if asked)=terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated), iac-change.3 (if asked)=no (default workspace; the env's own var-file), iac-change.4 (if asked)=recent. Delivery model, if asked: terraform is applied by hand from my workstation, and a direct apply is fine (operator-stated). Acknowledge any drift row shown. Observation window, if the plan proposes one: none, prod starts as soon as staging's verification and the `[H10]` decision are done (operator choice).
3. `[F3]` — approve the code (both var-files).
4. `[F4]` (staging) — approve the apply command shown for staging. Approving also acknowledges a YELLOW verdict, if one is shown.
5. `[H10]` — the regression stop after staging's apply. The operator types a reason: "unrelated: staging load test started 10:40, see #ops". That is a reason, so the run continues to prod.
6. `[F4]` (prod) — approve the apply command shown for prod. Approving also acknowledges a YELLOW verdict, if one is shown. Q1–Q3 still true (if asked): yes, unchanged.
7. `[H5]` — applies to every `[H5]` in the run, only if that pre-flight verdict is RED. Acknowledge each Red finding, reason: "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures".
