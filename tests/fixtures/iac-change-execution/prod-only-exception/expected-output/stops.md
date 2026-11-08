STOP 1: F1 — Run these reads? (19 commands: terraform init, refresh-only drift checks for prod and staging, prod alarm / health / timing reads, staging alarm reads; identity results, tiers and output root shown)
STOP 2: F2 — Approve this plan? (single phase: raise prod CPU alarm threshold 80 to 90; L2 questions Q1-Q5 and Q7 plus iac-change.1-4; delivery-model question; exception (b) prod-only justification; drift: none)
STOP 3: F3 — Approve these changes and the plan command? (envs/prod.tfvars line 17, 80 to 90; target; terraform plan -out=tfplan -var-file=envs/prod.tfvars)
STOP 4: F4 — Open the PR? (branch, envs/prod.tfvars only, target, pre-flight YELLOW verdict with finding and mitigation, Staging-first exception line, optional heads-up line)
