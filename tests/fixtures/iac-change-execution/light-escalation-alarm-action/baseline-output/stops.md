STOP 1: delivery model — No CI, GitOps or plan-automation config in the repo, so how do changes reach prod after merge (CI applies on merge / GitOps / PR automation / by hand)?
STOP 2: read batch — Approve the Step 1 live verification batch: 7 read-only commands (target check, terraform init, refresh-only drift plan, ECS service, alarm list, two Application Auto Scaling reads)?
STOP 3: GATE 1 — Approve the single-phase plan (add paymentapi-cpu-low-prod wired to the scale-in policy, PR path, branch iac-change/paymentapi-add-cpu-low-alarm)?
STOP 4: GATE 2 — Approve the code changes (main.tf, +30 lines, one new aws_cloudwatch_metric_alarm)?
STOP 5: 4a target check — Target is account 333333333333 / ap-southeast-1 / envs/prod.tfvars, match yes; proceed with terraform plan -out=tfplan?
STOP 6: pre-flight GATE 1 — Confirm detected scope: Terraform plan, 1 create in prod account 333333333333, delivered by CI after merge?
STOP 7: pre-flight L2 — Seven context questions (incident, freeze, peak, service familiarity, tool familiarity, cost, other) plus Q8 (application source)
STOP 8: unscripted — Four iac-change assessor questions (plan reviewed, delivery model, -target or -refresh=false, last successful apply), each with a proposed answer
STOP 9: pre-flight L3 opt-in — Run 17 read-only live queries, target check first?
STOP 10: pre-flight GATE 2 — RED soft block (4 of 11 categories Yellow or unknown, no single Red): acknowledge each finding with a reason, name committed mitigations, or abort
STOP 11: GATE 3 — Pre-flight verdict RED soft block: acknowledge each Red finding to clear execution, or abort?
STOP 12: change-comms heads-up offer — Draft a heads-up for affected people before the merge?
STOP 13: GATE 4 — On the change branch, stage only main.tf, commit, push, open the PR. Proceed?
STOP 14: PR checks polling offer — Poll the PR checks while CI runs?
STOP 15: GATE 5 — Execution record written; commit it?
STOP 16: change-comms result message offer — Draft the result message with change-comms?
