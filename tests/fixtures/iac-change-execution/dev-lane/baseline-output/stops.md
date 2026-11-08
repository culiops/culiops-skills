STOP 1: delivery model — Nothing in the repo shows how changes reach dev (no CI config, no Atlantis/Spacelift/Terraform Cloud, no GitOps object, no backend block): how is Terraform applied?
STOP 2: read batch — Step 1 live verification batch (terraform version, aws --version, terraform init, sts get-caller-identity, ecs describe-services, ecs describe-task-definition, terraform plan -refresh-only): approve all, pick a subset, or decline?
STOP 3: GATE 1 — Approve the change plan (phase 1 of 1: task_cpu 256 -> 512 in envs/dev.tfvars; default PR, direct apply offered; branch commands included)?
STOP 4: GATE 2 — Approve the code changes (envs/dev.tfvars:12, self-check 6/6, fresh-eyes not run)?
STOP 5: 4a target check — Target check shows account 111111111111 / ap-southeast-1 / envs/dev.tfvars, match yes; about to run terraform plan -out=tfplan. Proceed?
STOP 6: pre-flight GATE 1 — Is this detected as a Terraform plan change to the dev ECS task definition and service, in account 111111111111, delivered by manual apply from your workstation, correct?
STOP 7: pre-flight L2 — Context questions Q1-Q7 plus Q8 (where is the application source?).
STOP 8: pre-flight L3 — Run these 14 read-only live queries (target check first)? (yes/no)
STOP 9: pre-flight GATE 2 — Risk decision on RED soft block (category 7 Red): acknowledge each Red finding with a reason, or abort?
STOP 10: GATE 3 — Pre-flight clearance is RED soft block: acknowledge each Red finding to proceed, or abort?
STOP 11: change-comms offer — Draft a heads-up for the people affected with change-comms before the apply?
STOP 12: GATE 4 — About to run terraform apply tfplan (target check re-shown). Proceed?
STOP 13: unscripted — Apply completed: run read-only health checks (4 commands shown)? (yes/no)
STOP 14: GATE 5 — Execution record written: commit it? (also offered: draft result message and ticket comment with change-comms)
