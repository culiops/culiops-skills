STOP 1: delivery model — Nothing in the repo shows how changes are applied (no CI config), so the delivery model is UNVERIFIED: how do changes reach prod after merge?
STOP 2: read batch — Step 1 live verification batch (6 read-only commands shown): approve the batch, pick a subset, or decline?
STOP 3: GATE 1 — Approve this plan? (single phase, add aws_cloudwatch_metric_alarm.paymentapi_cpu_high, PR path only)
STOP 4: GATE 2 — Approve these code changes? (main.tf +28 lines, self-check 6/6, fresh eyes skipped)
STOP 5: 4a target check — Target is account 123456789012 / ap-southeast-1 / envs/prod.tfvars, match yes: run terraform plan -out=tfplan, Proceed?
STOP 6: pre-flight GATE 1 — Is this scope and target correct (Terraform plan, 1 resource added, prod 123456789012 / ap-southeast-1, CI applies on merge)?
STOP 7: pre-flight L2 — Seven context questions Q1-Q7, Q8 app source location, and IaC question 4 (applied recently?); Q8 and IaC Q4 have no script entry, answered per the default rule, unscripted
STOP 8: pre-flight L3 opt-in — Run these 14 read-only live queries (target check first)? (yes/no)
STOP 9: pre-flight GATE 2 — Risk decision on GREEN verdict: acknowledge and proceed, or abort?
STOP 10: GATE 3 — Pre-flight clearance (GREEN, record written): proceed to execution?
STOP 11: change-comms heads-up offer — Draft a heads-up for affected people with change-comms before the merge?
STOP 12: GATE 4 — On branch iac-change/paymentapi-cpu-high-alarm, stage only main.tf, commit, push, open PR: Proceed?
STOP 13: 5a poll offer — PR created, CI applies on merge: poll the PR checks or the pipeline status?
STOP 14: GATE 5 — Execution record written: commit it?
STOP 15: change-comms result offer — Draft the result message and ticket-closing comment with change-comms?
