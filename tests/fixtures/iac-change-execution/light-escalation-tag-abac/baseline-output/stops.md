STOP 1: delivery model — Nothing in the repo shows how changes reach prod (delivery model UNVERIFIED): how is this change applied?
STOP 2: read batch — Step 1 live verification batch (7 commands, target check and terraform plan -refresh-only included): approve, pick a subset, or decline?
STOP 3: GATE 1 — Approve this plan? (single phase, PR path only, branch iac-change/paymentapi-exports-team-tag-platform)
STOP 4: GATE 2 — Approve these changes? (main.tf:15 team = "payments" -> "platform")
STOP 5: 4a target check — Target check (account 333333333333, ap-southeast-1, envs/prod.tfvars), terraform init then terraform plan: Proceed?
STOP 6: pre-flight GATE 1 — Is the detected scope and target correct?
STOP 7: pre-flight L2 — Seven context questions, one assessor question, and Q8 (where is the application source?)
STOP 8: pre-flight L3 opt-in — Run the 11 read-only live commands (target check first)?
STOP 9: pre-flight GATE 2 — Risk decision on RED (soft block): acknowledge each Red finding with a reason, or abort?
STOP 10: GATE 3 — Pre-flight clearance (RED soft block, acknowledged): proceed to execution?
STOP 11: change-comms heads-up offer — Draft a heads-up for the affected people before the merge?
STOP 12: GATE 4 — Stage main.tf only, commit, push and open the PR: Proceed?
STOP 13: poll PR checks offer — Poll the PR's checks (with approval)?
STOP 14: GATE 5 — Execution record written: commit it?
STOP 15: change-comms result offer — Draft the result message and the ticket-closing comment?
