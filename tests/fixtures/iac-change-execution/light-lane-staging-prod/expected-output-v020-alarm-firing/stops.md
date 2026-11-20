STOP 1: A — Approve the plan, the code and these reads? (light lane: research summary, plan, code summary, read batch for both environments, delivery-model question, operator line)
STOP 2: H5 — Staging pre-flight is RED (soft block): acknowledge each Red finding (timing, resource health — alarm firing on the load balancer) with a reason, or abort?
STOP 3: B — Run this apply? `terraform apply tfplan` against staging (account 222222222222), pre-flight RED acknowledged at [H5]
STOP 4: B — Run this apply? `terraform apply tfplan` against prod (account 333333333333), pre-flight YELLOW, carries the operator line
