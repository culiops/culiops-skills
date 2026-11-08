<!-- Would be written to .culiops/iac-change-execution/paymentapi-cpu-increase-20261109-1022.md -->
**IaC change execution for:** `paymentapi` / `dev`
**Change:** Raise the ECS task CPU for paymentapi in dev from 256 to 512.
**Date:** `2026-11-09 10:22`
**Commit:** `a1b2c3d`
**IaC tool(s):** Terraform (AWS provider ~> 5.0)
**Execution path:** not chosen (aborted in Step 1, before Step 2)
**Pre-flight record:** none (pre-flight not reached)
**Prerequisites (examples/aws.md):** AWS CLI v2; authentication by named profile, SSO, role or STS credentials, identity confirmed with `aws sts get-caller-identity`; Tier 1 read-only IAM for Steps 1 and 5, Tier 2 elevated role only for the apply; CloudWatch `GetMetric*` calls carry a small cost.

## Research Summary

- **Catalog used:** none — proceeding without catalog (`.culiops/service-discovery/paymentapi.md` not present).
- **Duplicate check:** not done (the change is not made yet). `code: envs/dev.tfvars:12` `task_cpu = 256`; `git: no commit touched task_cpu or 512 (git log --all -S, 10:02-10:03)`; no branch matching `*cpu*` and no open PR (`gh pr list`, 10:05). `envs/prod.tfvars:12` is `task_cpu = 512` (prod, outside this change).
- **Delivery model:** applied by hand (`operator-stated`; nothing in the repo shows how changes reach the environment).
- **Env selection:** `-var-file=envs/dev.tfvars` (`code: providers.tf:12`, `envs/`).
- **Target check:** `live: aws sts get-caller-identity` (2026-11-09 10:16) -> account `333333333333`, role `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator`. The change is for dev, account `111111111111` (`code: envs/dev.tfvars:3`, `providers.tf:16`). **Match: NO.**
- **Key finding:** the active credentials belong to the prod account. Red flag SKILL.md:77 (account does not match the environment the plan is for). The rest of the read batch (ECS reads, `terraform init`, `terraform plan -refresh-only`) was not run. No plan, no code change, no apply.
- **Fresh eyes:** not run — dry run (never reached).

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| dev task CPU | `code: envs/dev.tfvars:12` -> 256 | not run — batch halted at the target check | `code-only — not live-verified` |
| dev task memory | `code: envs/dev.tfvars:13` -> 1024 | not run — batch halted at the target check | `code-only — not live-verified` |
| dev account | `code: envs/dev.tfvars:3`, `providers.tf:16` -> 111111111111 | `live: aws sts get-caller-identity` (10:16) -> 333333333333 | **mismatch — active identity is prod** |
| dev ECS service state | `code: main.tf:72`, `main.tf:9` | not run — batch halted at the target check | `code-only — not live-verified` |

Drift rows: 0 (no live read of dev was possible). Unverified rows: 3. Account row: mismatch.

## Change Plan

None. Aborted before Step 2.

## Execution Log

No phase was started.

- Self-check: not run (plan and diff self-checks are in Steps 2 and 3)
- Fresh eyes: not run — dry run
- Plan output summary: none
- Plan hash: none
- Pre-flight verdict: none
- Execution: none
- Verification: none

## Outcome

**aborted** — ABORTED at the Step 1 target check (account `333333333333` is not the dev account `111111111111`). The operator said: "My shell is on the prod profile. I will switch to the dev credentials and start again."

**Applied:** no — nothing was planned, written or applied.

## Ticket Reference

none
