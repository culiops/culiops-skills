STOP 1: F1 — Run these reads? (Step 1 read batch for staging and prod, S0 and the target checks included; targets and tiers shown)
STOP 2: F2 — Approve this plan? (staging first, then prod; operator line; Q8 asked because no app source was found)
STOP 3: F3 — Approve these changes and the plan command? (main.tf diff; plan commands for staging and prod var-files)
STOP 4: H5 — Pre-flight for staging is RED (soft block): acknowledge each Red finding with a reason, or abort?
STOP 5: F4 — Run this apply? (terraform apply tfplan against staging, account 222222222222)
STOP 6: H10 — Health regressed after the apply of phase 1 in staging. Type a reason to continue, or the run stops here.
