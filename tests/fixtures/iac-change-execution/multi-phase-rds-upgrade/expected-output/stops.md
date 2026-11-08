STOP 1: F1 — Run these reads? (22-command read batch, identity read result and tier shown; operator states tier prod)
STOP 2: F2 — Approve this plan? (2 phases, direct apply, L2 answers, delivery-model question, no drift rows)
STOP 3: F3 — Approve these changes and the plan command? (phase 1 code, main.tf diff)
STOP 4: H5 — Phase 1 pre-flight is RED (soft block, 6 Yellow or unknown): acknowledge each finding with a reason, or abort?
STOP 5: F4 — Run this apply? (phase 1: terraform apply tfplan, prod 123456789012 / ap-southeast-1)
STOP 6: H5 — Phase 2 pre-flight is RED (soft block, 1 Red and 6 Yellow or unknown): acknowledge each finding with a reason, or abort?
STOP 7: F4 — Run this reboot? (phase 2: aws rds reboot-db-instance paymentapi-db-prod; phase 1 result shown; Q1-Q3 re-asked)
