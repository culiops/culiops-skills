STOP 1: F1 — Run these reads? (Step 1 read batch for staging and prod: target check, tiers, S0, drift check, app-source search)
STOP 2: F2 — Approve this plan? (plan + Checked for you + operator line + Q8, staging then prod)
STOP 3: F3 — Approve these changes and the plan command? (main.tf diff, targets, plan command per environment)
STOP 4: H5 — Pre-flight is RED (soft block) for the staging apply: acknowledge each Red finding with a reason, or abort?
STOP 5: F4 — Run this apply? (staging: terraform apply tfplan)
STOP 6: H10 — Health regressed after the apply of phase 1 in staging. Type a reason to continue, or the run stops here.
