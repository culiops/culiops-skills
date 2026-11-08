STOP 1: delivery model — Step 1: nothing in the repo shows how a merged change reaches prod; how is it applied?
STOP 2: read batch — Step 1 live verification batch (4 read-only commands, identity check first): approve, pick a subset, or decline?
STOP 3: GATE 1 — Approve this plan? (single phase, PR path, envs/prod.tfvars 80 to 90)
STOP 4: GATE 2 — Approve these code changes? (envs/prod.tfvars line 17, one hunk)
STOP 5: target check — 4a: account 333333333333 / ap-southeast-1 / envs/prod.tfvars, match yes; run terraform init then plan -out=tfplan. Proceed?
STOP 6: pre-flight GATE 1 — Is this detection correct (Terraform in-place change, 1 alarm, prod 333333333333, CI after merge)?
STOP 7: pre-flight L2 — context questions Q1-Q8 plus the assessor's open question
STOP 8: pre-flight L3 — Run these 12 read-only live checks (identity check first)? (yes/no)
STOP 9: pre-flight GATE 2 — Verdict YELLOW: acknowledge and proceed, or abort?
STOP 10: GATE 3 — Pre-flight clearance (YELLOW): cleared to proceed to execution?
STOP 11: heads-up offer — Draft a change-comms heads-up for the people affected before the merge?
STOP 12: GATE 4 — On the change branch, stage envs/prod.tfvars only, commit, push, open the PR. Proceed?
STOP 13: poll PR checks offer — Poll the PR's checks until it merges and the pipeline applies?
STOP 14: GATE 5 — Execution record written. Commit it?
STOP 15: result-message offer — Draft the result message and ticket-closing comment with change-comms?
