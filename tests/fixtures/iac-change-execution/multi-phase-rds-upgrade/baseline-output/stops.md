STOP 1: read batch — Approve the Step 1 live verification batch (7 read-only commands, target check included)?
STOP 2: GATE 1 — Approve this plan (2 phases, direct apply, branch commands, alarm item from the catalog)?
STOP 3: GATE 2 (phase 1) — Approve these code changes (main.tf, 2 hunks)?
STOP 4: 4a target check (phase 1) — Target is account 123456789012 / prod var-file, match yes; about to run terraform plan. Proceed?
STOP 5: pre-flight GATE 1 (phase 1) — Is the detected action type, scope, target and delivery model correct?
STOP 6: pre-flight L2 (phase 1) — Context questions Q1-Q7, Q8 (app source) and the assessor question on the last apply
STOP 7: pre-flight L3 opt-in (phase 1) — Run the 14 read-only live queries (target check first)? (yes/no)
STOP 8: pre-flight GATE 2 (phase 1) — Risk decision on RED soft block: acknowledge each finding with a reason, or abort
STOP 9: GATE 3 (phase 1) — Pre-flight clearance (RED soft block): acknowledge and clear for execution?
STOP 10: change-comms heads-up offer (phase 1) — Draft a heads-up for the people affected before the apply?
STOP 11: GATE 4 (phase 1) — About to run terraform apply tfplan, target check re-shown. Proceed?
STOP 12: unscripted — Optional read-only health checks after the phase-1 apply. Want me to try? (yes/no)
STOP 13: phase gate — Phase 1 complete, success criteria pass. Ready to proceed to Phase 2 (reboot)?
STOP 14: GATE 2 (phase 2) — Approve these code changes (none: the phase writes no file)?
STOP 15: 4a target check (phase 2) — Target is account 123456789012 / prod var-file, match yes; no plan command for the reboot. Proceed?
STOP 16: pre-flight GATE 1 (phase 2) — Is the detected action type, scope, target and delivery model correct?
STOP 17: pre-flight L2 (phase 2) — Context questions Q1-Q7, Q8 (app source) and the assessor question on the last apply
STOP 18: pre-flight L3 opt-in (phase 2) — Run the 10 read-only live queries (target check first)? (yes/no)
STOP 19: pre-flight GATE 2 (phase 2) — Risk decision on RED soft block: acknowledge each finding with a reason, or abort
STOP 20: GATE 3 (phase 2) — Pre-flight clearance (RED soft block): acknowledge and clear for execution?
STOP 21: change-comms heads-up offer (phase 2) — Draft a heads-up for the people affected before the reboot?
STOP 22: GATE 4 (phase 2) — About to run aws rds reboot-db-instance, target check re-shown. Proceed?
STOP 23: unscripted — Optional read-only health checks after the phase-2 reboot. Want me to try? (yes/no)
STOP 24: GATE 5 commit offer — Execution record written. Commit it?
STOP 25: change-comms result offer — Draft the result message and ticket-closing comment with change-comms?
