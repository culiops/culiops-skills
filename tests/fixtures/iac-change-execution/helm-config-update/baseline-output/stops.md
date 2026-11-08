STOP 1: delivery model — How does a merged change reach prod? Nothing in the repo shows it (CI on merge / GitOps / PR-driven plan+apply / by hand).
STOP 2: read batch — Approve the Step 1 live verification batch of 13 read-only commands (target reads included), pick a subset, or decline?
STOP 3: GATE 1 — Approve the change plan for notifyapi / prod (Phase 1 of 1, PR path, branch iac-change/notifyapi-replicas-4)?
STOP 4: GATE 2 — Approve these code changes (values-prod.yaml: replicaCount 2 -> 4)?
STOP 5: 4a target check — Target check (account 123456789012, context prod-cluster, namespace notifyapi-prod, match: yes); about to run helm diff upgrade. Proceed?
STOP 6: 4b reuse re-check — Reusing the pre-flight record from 10:30: re-ask timing Q1-Q3 and approve the 3 category-10 read-only reads?
STOP 7: GATE 3 — Pre-flight clearance: reused record GREEN, Q1-Q3 and category-10 reads unchanged. Proceed to 4c or abort?
STOP 8: 4c heads-up offer — Draft a heads-up for affected people (owners, reviewers, on-call) with change-comms before the merge (draft-only)?
STOP 9: GATE 4 — On branch iac-change/notifyapi-replicas-4, stage only values-prod.yaml, commit, push and open a PR. Proceed?
STOP 10: 5a poll offer — PR created; poll the PR checks (read-only, with approval)?
STOP 11: GATE 5 — Execution record written; commit it? (Also offered: draft the result message and ticket-closing comment with change-comms.)
