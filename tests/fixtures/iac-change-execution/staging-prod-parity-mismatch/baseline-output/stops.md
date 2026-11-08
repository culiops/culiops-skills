STOP 1: read batch — approve the Step 1 live verification batch (11 read commands, staging and prod, target checks included)
STOP 2: GATE 1 — approve the change plan (Phase 1 staging, Phase 2 prod) and pick the execution path
STOP 3: GATE 2 — approve the Phase 1 (staging) code change
STOP 4: 4a target check — Proceed? (Phase 1, staging, account 222222222222)
STOP 5: pre-flight GATE 1 — confirm detected action, scope and target (Phase 1, staging)
STOP 6: pre-flight L2 — context questions Q1-Q7 plus Q8 (Phase 1, staging)
STOP 7: pre-flight L3 opt-in — run the numbered read-only live queries? (Phase 1, staging)
STOP 8: pre-flight GATE 2 — risk decision on the RED soft block verdict (Phase 1, staging)
STOP 9: GATE 3 — pre-flight clearance, acknowledge the RED soft block (Phase 1, staging)
STOP 10: change-comms offer — draft a heads-up before the apply? (Phase 1, staging)
STOP 11: GATE 4 — approve `terraform apply tfplan` for staging, target check re-shown
STOP 12: health checks offer — run read-only health checks after the staging apply?
STOP 13: unscripted — phase gate: Phase 1 success criteria pass, proceed to Phase 2 (prod)?
STOP 14: GATE 2 — approve the Phase 2 (prod) code change
STOP 15: 4a target check — Proceed? (Phase 2, prod, account 333333333333)
STOP 16: pre-flight GATE 1 — confirm detected action, scope and target (Phase 2, prod)
STOP 17: pre-flight L2 — context questions Q1-Q7 plus Q8 (Phase 2, prod)
STOP 18: pre-flight L3 opt-in — run the numbered read-only live queries? (Phase 2, prod)
STOP 19: pre-flight GATE 2 — risk decision on the RED soft block verdict (Phase 2, prod)
STOP 20: GATE 3 — pre-flight clearance, acknowledge the RED soft block (Phase 2, prod)
STOP 21: change-comms offer — draft a heads-up before the apply? (Phase 2, prod)
STOP 22: GATE 4 — approve `terraform apply tfplan` for prod, target check re-shown
