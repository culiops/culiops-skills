STOP 1: delivery model (UNVERIFIED) — Nothing in the repo shows how changes reach prod; is the apply done by CI, GitOps, or by hand?
STOP 2: read batch — Step 1 live verification batch (7 read-only commands shown, incl. terraform plan -refresh-only): approve, pick a subset, or decline?
STOP 3: GATE 1 — Approve this plan (single phase, direct apply, branch commands)?
STOP 4: GATE 2 — Approve these code changes (main.tf, +28 lines)?
STOP 5: 4a target check — Target check (account 333333333333, var-file envs/prod.tfvars, match: yes), about to run terraform init then terraform plan: Proceed?
STOP 6: pre-flight GATE 1 — I detected this as a Terraform plan change (1 add) in account 333333333333 / ap-southeast-1, delivered by manual apply: is this correct?
STOP 7: unscripted — Pre-flight L2 context check Q1-Q7 (answered from the script by meaning) plus Q8 app-source location (not in the script)
STOP 8: pre-flight L3 opt-in — Read-only live checks (13 commands listed, target check first): run them?
STOP 9: pre-flight GATE 2 — Risk decision on verdict YELLOW (categories 1 and 9 raised by the direct-apply flag): acknowledge and proceed, or abort?
STOP 10: 4c change-comms offer — Draft a heads-up for affected people with change-comms before the apply?
STOP 11: GATE 4 — About to run terraform apply tfplan (target check re-shown): Proceed?
STOP 12: 5a health checks offer — Apply completed; run read-only health checks? (yes/no)
STOP 13: GATE 5 — Execution record written; commit it? (plus offer to draft the result message and ticket-closing comment with change-comms)
