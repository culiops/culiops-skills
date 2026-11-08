# Lanes — rule data for iac-change-execution

SKILL.md cites this file by section name. A lane sets the **stops**, the points where the operator must answer. It never removes a **check**. Self-checks, the duplicate check, the evidence rules, the plan cross-check, success criteria, the parity check and fresh eyes (its own skip rule; the dev lane skips it) run in every lane. The hard gates H1–H9 hold in every lane.

**IDs (exact):** lanes `dev`, `light`, `full` · stops `D1`, `A`, `B`, `F1`, `F2`, `F3`, `F4` · hard gates `H1`–`H9` · escalations `E1`–`E4`.

**Lane rule.** Go down the list. The first line that holds decides the lane.
1. An escalation is recorded (see Escalation checks) → **full**.
2. Every target of the change has a proven `dev` tier (see Environment tier) → **dev**.
3. L1, L2, L3 and L4 all hold → **light**.
4. Anything else → **full**.

The light-lane conditions:
- **L1:** every resource action is a create or an in-place update. Nothing is deleted or replaced. Evidence is `plan:`.
- **L2:** every change is on the Light-lane allowlist.
- **L3:** one phase per environment, no drift row, and the duplicate check says not done (or partly done with the remainder on the allowlist).
- **L4:** every escalation check passes.

**Direction.** The rule decides, from the plan output, not from the size of the change. The LLM can only escalate, through E1–E3 or `plan-confirm`, each with a reason and evidence. It never downgrades. The operator can always force the full lane (E4). The lane is never downgraded during a run.

## Environment tier

- Step 1 maps every environment the repo defines (directory, var-file, workspace, overlay, values file) to **dev**, **staging** or **prod**.
- A target's tier is **proven** only when the target identity matches what the repo pins for that environment. Cite both sides: `live:` for the identity, `code: <path>:<line>` for the pin.
  - Terraform: the account from `aws sts get-caller-identity` equals `allowed_account_ids`, the account in the provider `assume_role` ARN, or the account variable in the environment's var-file.
  - Kubernetes: the context from `kubectl config current-context` is the context or cluster named in the CI config, or the Argo CD / Flux destination.
- The environment's name alone does not prove it is dev or staging. `dev` or `stg` in a directory, workspace, var-file, account alias or context name proves nothing on its own.
- The environment the plan is for has a pin, and the identity does not match it → H1.
- When nothing is pinned, the operator may state the tier at the first stop. Record it as `operator-stated`. An `operator-stated` tier is not proven: an operator-stated dev tier does not open the dev lane and does not skip pre-flight.
- **An unproven tier gets prod gate levels.** Unproven covers: no pin, an identity read that failed or was not run, an `operator-stated` tier, and an environment that cannot be mapped.
- **Identity reads need no opt-in:** `aws sts get-caller-identity` and `kubectl config current-context`. They return only who the caller is, not resource data. Run them first, before any other live command, and show the result at the first stop. No other read is exempt.
  - AWS: GetCallerIdentity needs no IAM permission. `docs: https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity.html (2026-11-08)`: "No permissions are required to perform this operation."
  - Kubernetes: `kubectl config current-context` reads the local kubeconfig. `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_current-context/ (2026-11-08)`: "Display the current-context". The parent command works on kubeconfig files: `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/ (2026-11-08)`: "Modify kubeconfig files".

## Hard gates

Every lane, never waived. A request to skip one is refused, citing its H-id and the reason. Where no lane stop carries a gate, the gate is its own stop, and the prompt starts with its H-id, for example `**[H3] …**`.

| ID | Gate | Held at |
|---|---|---|
| H1 | The target identity does not match the environment the plan is for: stop, run nothing further. | Its own stop `[H1]`, as soon as an identity read or target check shows the mismatch. Show both identities. Run nothing further. "Proceed anyway" is refused. If the operator switches credentials, re-run the identity read; it must match. |
| H2 | Approval before every mutation: each apply command, each push + open PR, each merge the skill would do. | `[D1]`, `[B]`, `[F4]`. Each approves only the mutation it shows. Any further mutation gets its own approval. |
| H3 | The plan shows a destroy or replace that the approved plan did not name, or the parity check fails. | Its own stop `[H3]` at Step 4a, before pre-flight. In the light lane the same plan also escalates (L1). |
| H4 | Drift rows are acknowledged before planning. | Inside `[F2]`. Any other drift row (dev lane, or found after the plan) is its own stop `[H4]`, before anything further runs. |
| H5 | A RED verdict: acknowledgement for a soft block, written justification for a hard block. | Its own stop `[H5]`: pre-flight's GATE 2 on RED, before `[B]` / `[F4]`. |
| H6 | The duplicate check says already done, in flight or reverted. | Its own stop `[H6]` in Step 1, before planning. |
| H7 | Staging before prod. The only ways around it are the staging-first exceptions (a)–(c) in SKILL.md Step 2. | Checked before each prod `[B]` / `[F4]`. Ordering detail: SKILL.md Step 2. |
| H8 | Unsupported owner tool, or an import over an active CloudFormation / Serverless owner (existing rules). | Its own stop `[H8]` in Step 1. Rules: SKILL.md › Supported stack, and the Step 1 ownership check. |
| H9 | Pre-flight runs before every staging or prod apply. Only a proven dev target skips it. | Before each staging or prod `[B]` / `[F4]`. A reusable record (Step 4b match rule) counts as a run. An unproven target counts as prod. |

## Light-lane allowlist

L2 passes only when every change matches a row below. A change is one resource action in the plan output (`plan:`). Step 1 predicts the actions from the request and the code; Step 4a confirms them.
- A row covers only its own type, action and condition. An update or delete of an alarm, or a new log group, is off the list.
- An update matches a row only when every attribute it changes is covered by that one row.
- The list is closed. Do not extend it by analogy. A change that matches no row is off the list, and the change is not light.

### Terraform AWS

| Resource type | Allowed action | Condition |
|---|---|---|
| `aws_cloudwatch_metric_alarm` | create | none (E1 checks its actions) |
| `aws_cloudwatch_composite_alarm` | create | none (E1 checks its actions) |
| `aws_cloudwatch_dashboard` | create or update | any attribute |
| `aws_cloudwatch_log_metric_filter` | create | none |
| any `aws_*` type | update | the only changed attributes are `tags` / `tags_all` (E2 checks each changed key) |
| `aws_cloudwatch_log_group` | update | `retention_in_days` increased, or set to `0` (never expire). `0` means never expire, so a change from `0` (or unset) to any number shortens retention: off the list. |

### Kubernetes

| Resource type | Allowed action | Condition |
|---|---|---|
| `PrometheusRule` | create | none |
| `ServiceMonitor` | create | none |
| `PodMonitor` | create | none |

### ecspresso / lambroll

| Resource type | Allowed action | Condition |
|---|---|---|
| any | `none in v1` | every ecspresso or lambroll change is off the list |

## Escalation checks

Any hit moves the change to the full lane, with the reason and the evidence (`code: <path>:<line>` or `plan:`). The record lists each hit under `Escalations:`. Run E1–E3 whenever the lane would otherwise be light (not dev, and L1–L3 hold): once the diff exists, before the stop that approves it, and again at Step 4a on the plan output. Other changes are not required to run them, but a hit found anyway still escalates and is recorded.

**E1: an alarm action is not an SNS topic.** Check every value of `alarm_actions`, `ok_actions` and `insufficient_data_actions` in the diff. Each value must resolve to `aws_sns_topic.<name>.arn` or a literal ARN that starts with `arn:aws:sns:`. Follow a variable, local or module input to its value, and cite each step as `code: <path>:<line>`. A hit is any value that resolves to something else (a scaling policy, `arn:aws:automate:`, SSM, Lambda) or that you cannot trace to the end. At Step 4a, a known value for these attributes in the plan that does not start with `arn:aws:sns:` is also a hit.

**E2: a changed tag key drives automation.** For each tag key that an update adds, removes or gives a new value, run both commands from the repo root:

```
git grep -n -E 'aws:(ResourceTag|RequestTag)/<key>|aws:TagKeys'
git grep -n -F '<key>'
```

In the `-E` command, put a `\` before any regex metacharacter in `<key>`. Read every hit before you clear it. An unread hit counts as a hit. Clear a hit only when reading it shows it is not an IAM condition (`aws:ResourceTag/`, `aws:RequestTag/`, `aws:TagKeys`), an SCP, a backup selection, a scheduler, or any other tag-driven automation that uses this key. Examples that clear: the line that sets the tag, a comment. Unsure → hit.

**E3: self-review.** For each resource action and each changed output, answer this question in writing: "does this change trigger an automated action, or does anything read this value?" Yes or unsure → hit. A "no" cites what was checked.

**E4: the operator asks for the full lane.** At any stop or at any time. Escalate at once and record it.

### When the lane is decided

1. Step 1 predicts the lane from the request and the code.
2. Step 4a confirms it from the plan output: check L1–L4 again against the plan. If the prediction was wrong, the change escalates and the skill says why (`plan-confirm` with its `plan:` evidence, or the E-id that hit). Approval already given stays valid. The full-lane stops not yet passed are added: `[A]` approved what `[F1]`–`[F3]` approve, so after `[A]` the next stop is `[F4]` in place of `[B]`, plus any hard-gate stop that fires. A plan or diff that changes after the escalation needs new approval at `[F2]` / `[F3]`.
3. The lane is never downgraded during a run.

## Stops per lane

A stop is a point where the operator must answer. Each stop prompt starts with its ID in brackets, for example `**[F2] Approve this plan?**`. Hard-gate stops (see Hard gates) come on top of these.

| Lane | Stop | Shows / asks | Operator answers | Soft |
|---|---|---|---|---|
| dev | `[D1]` | diff + plan output + target | apply, or open the PR | no |
| light | `[A]` | change plan + diff + target + read batch + L2 answers + any delivery-model question + any staging-first exception justification | approve | no |
| light | `[B]` | PR or apply, one per environment, showing the verdict line | proceed | no |
| full | `[F1]` | Step 1 read batch, with the target shown | approve the batch | yes |
| full | `[F2]` | GATE 1 plan + L2 answers + drift acknowledgements + exception justification | approve | no |
| full | `[F3]` | GATE 2 code + target + plan command | approve | yes |
| full | `[F4]` | PR or apply, per environment, showing the verdict | proceed | no |

Rules for all lanes:
- **Read batch.** One batch, each command shown. At `[A]` it includes the plan command (`terraform plan` or the tool's diff), pre-flight's category 7 (observability) and 10 (resource health) reads, and the post-apply success-criteria reads. At `[F1]` it includes the Step 1 reads and the category 7 and 10 reads; the full lane approves the success-criteria reads at `[F2]` and the plan command at `[F3]`. A read approved at a stop needs no further stop.
- **L2 answers** (`[A]`, `[F2]`): pre-flight's Q1–Q5 and Q7; Q8 when the change plan touches an app-facing attribute; and the matched assessor's questions as `<assessor>.<n>=…`. They go to pre-flight in the caller block (pre-flight Constraint 14). Anything missing makes pre-flight ask, which is an extra stop. So is a pre-flight L3 batch for reads the caller did not run.
- **Delivery model** `UNVERIFIED`: ask inside `[A]` / `[F2]`, not as a stop of its own.
- **Verdict.** `[B]` / `[F4]` show the pre-flight verdict line. A YELLOW is shown with each Yellow and ⚪ finding and its mitigation; approving there is the acknowledgement, and it is recorded. **RED** adds the `[H5]` stop.
- **Dev lane.** Reads and the plan run without a stop. No pre-flight (H9). No fresh eyes. Self-checks and the duplicate check still run. The record says why pre-flight and fresh eyes were skipped (SKILL.md Step 5b).
- **Code before the first stop** (light and dev only): create the branch and write the code before `[A]` / `[D1]` only when `git status` is clean. Otherwise stop and ask, as today. Full lane: no code before `[F2]` is approved.
- **Multi-phase** (full lane): each phase gets `[F3]` and `[F4]`. A phase with no IaC code change (an operational command only, such as an RDS reboot) has no `[F3]`: its command is shown and approved at `[F4]` (H2). Each phase's first stop (`[F3]`, or `[F4]` when the phase has no `[F3]`) shows the previous phase's success-criteria result. The separate phase gate goes away. A failed success criterion stops the run, as today. In the dev lane, each phase gets its own `[D1]` (H2).
- **Observation window** (staging → prod): no stop of its own. Light lane: prod's `[B]` comes once staging's success criteria pass. Full lane: SKILL.md Step 2.
- **No other stops.** GATE 5 and the standalone offers are removed. `[B]` / `[F4]` may carry one optional heads-up line (change-comms). The final message ends with one `Next:` line: commit the record, and draft the result or ticket-close message with change-comms.
- **Soft stops: `[F1]` and `[F3]` only.** The operator may waive one explicitly; the LLM never waives a stop. Waived `[F1]`: run the read batch without asking. Waived `[F3]`: show the diff, the target and the plan command at `[F4]` instead, and run the plan without a stop; H1 still stops a target mismatch. Record each waiver under `Waived:`. Every other stop holds: a request to skip one is refused, citing the H-id it holds (H2 at `[D1]`, `[B]`, `[F4]`) or the reason it exists. No check is waivable; fresh eyes keeps its existing skip rule. The waiver procedure is in SKILL.md.
