STOP 1: F1 — Run these reads? (Step 1 read batch with target, tier and S0; every command shown)
STOP 2: F2 — Approve this plan? (two phases, direct apply, Checked for you, App source line, operator line)
STOP 3: F3 — Approve these changes and the plan command? (phase 1, main.tf diff)
STOP 4: H5 — Pre-flight RED (soft block, 4 Yellow) for phase 1: acknowledge each finding with a reason, or abort?
STOP 5: F4 — Run this apply? (phase 1: terraform apply tfplan)
STOP 6: H5 — Pre-flight RED (soft block, 6 Yellow) for phase 2: acknowledge each finding with a reason, or abort?
STOP 7: F4 — Run this reboot? (phase 2: aws rds reboot-db-instance, no IaC change)
