STOP 1: delivery model — The repo shows no CI, GitOps or PR-automation config, so the delivery model is UNVERIFIED: how are Terraform changes applied here?
STOP 2: read batch — Step 1 live verification batch (aws sts get-caller-identity, ecs describe-services, ecs describe-task-definition, terraform init, terraform plan -refresh-only for dev): approve, pick a subset, or decline?
STOP 3: red flag, target mismatch — `aws sts get-caller-identity` shows account 333333333333 but the change is for dev (111111111111); the skill stops and shows the mismatch (SKILL.md:77).
