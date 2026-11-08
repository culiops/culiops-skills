STOP 1: F1 — Run these reads? (Step 1 read batch for staging and prod, identity reads and tiers shown)
STOP 2: F2 — Approve this plan? (staging then prod, 24 h observation window, L2 answers, delivery model, prod 14.9 to 15.7 confirmation, no drift rows)
STOP 3: F3 — Approve these changes and the plan command? (db_engine_version to 15.7 in envs/staging.tfvars and envs/prod.tfvars)
STOP 4: H5 — Pre-flight verdict for staging is RED (soft block, multi-Yellow escalation): acknowledge each finding with a reason, or abort?
STOP 5: F4 — Run this apply? (terraform apply tfplan against staging, account 222222222222)
STOP 6: H3 — Prod does something staging did not (aws_db_parameter_group.paymentapi replace): abort, add a staging rehearsal, or accept with a written reason?
