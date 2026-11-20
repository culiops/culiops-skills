STOP 1: F1 — Run these reads? (Step 1 batch for staging and prod, with targets and tiers)
STOP 2: F2 — Approve this plan? (research summary, plan, Checked for you, Q8, operator line)
STOP 3: F3 — Approve these changes and the plan command?
STOP 4: H5 — Pre-flight RED (staging): acknowledge each Red finding with a reason, or abort?
STOP 5: F4 — Run this apply? (staging: terraform apply tfplan)
STOP 6: H10 — Health regressed after the apply of phase 1 in staging: type a reason to continue, or the run stops here
STOP 7: H5 — Pre-flight RED (prod): acknowledge each Red finding with a reason, or abort?
STOP 8: F4 — Run this apply? (prod: terraform apply tfplan)
