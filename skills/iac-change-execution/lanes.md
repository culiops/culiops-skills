# Lanes — rule data for iac-change-execution

SKILL.md cites this file by section name. A lane sets the **stops**, the points where the operator must answer. It never removes a **check**. Self-checks, the duplicate check, the evidence rules, the plan cross-check, success criteria, the parity check and fresh eyes (its own skip rule) run in every lane. The dev lane skips fresh eyes only. The hard gates H1–H9 hold in every lane.

**IDs (exact):** lanes `dev`, `light`, `full` · stops `D1`, `A`, `B`, `F1`, `F2`, `F3`, `F4` · hard gates `H1`–`H9` · escalations `E1`–`E4`, `plan-confirm`.

## Lane rule

Go down the list. The first line that holds decides the lane.
1. An escalation is recorded (see Escalation checks) → **full**.
2. Every target of the change has a proven `dev` tier (see Environment tier) → **dev**.
3. L1, L2, L3 and L4 all hold → **light**.
4. Anything else → **full**.

The light-lane conditions:
- **L1:** every resource action is a create or an in-place update. Nothing is deleted or replaced. Evidence is `plan:`.
- **L2:** every change is on the Light-lane allowlist.
- **L3:** one phase per environment, no drift row, and the duplicate check says not done (or partly done with the remainder on the allowlist).
- **L4:** every escalation check passes.

The rule decides, from the plan output, not from the size of the change. The LLM can only escalate, through E1–E3 or `plan-confirm`, each with a reason and evidence. The operator can always force the full lane (E4). **The lane is never downgraded during a run.**

**When the lane is decided.**
1. Step 1 predicts the lane from the request and the code.
2. Step 4a confirms it from the plan output: check L1–L4 again against the plan. If the prediction was wrong, the change escalates (`plan-confirm`) and the skill says why.
3. On any escalation, approval already given stays valid, and the full-lane stops not yet passed are added. Any hard-gate stop that fires comes on top.
   - Before `[A]`: `[F1]`–`[F4]`. Code already written stays uncommitted and is shown at `[F3]`.
   - After `[A]`: `[A]` approved what `[F1]`–`[F3]` approve, so the next stop is `[F4]` in place of `[B]`.
   - From dev (E4 or a hit): the full-lane stops. Pre-flight still follows H9 by tier: a proven dev target skips it unless the operator asks for it.
   - Leaving dev at Step 4a: a planned resource outside a proven-dev target, or a merge that applies other environments, ends the dev lane. Record `plan-confirm` with the `plan:` or `code:` evidence. That is a recorded escalation, so Lane rule line 1 makes the change full, and all the full-lane stops apply, because the dev lane approves nothing before `[D1]`.
   - A plan or diff that changes after the escalation needs new approval at `[F2]` / `[F3]`.

## Environment tier

- Step 1 maps every environment the repo defines (directory, var-file, workspace, overlay, values file) to **dev**, **staging** or **prod**.
- **A change's targets** are every account or Kubernetes context its plan or its merge reaches: the environment it is for, every environment that consumes an edited shared module, every environment the delivery model applies on the same merge, and every account an aliased provider reaches. Each target gets its own tier. The dev lane needs every target proven `dev`. If the delivery model is `UNVERIFIED`, the merge's reach cannot be listed. The dev lane then holds for the direct-apply path, which reaches only the planned targets, and the delivery-model question is asked inside `[D1]`. If the operator picks the PR path there, the dev lane ends before the PR opens: record `plan-confirm`, and the lane rule's stops are added (When the lane is decided).
- A target's tier is **proven** only when the target identity matches what the repo pins for that environment. Run the identity read with the same profile or kubeconfig that the plan and apply will use. Match exactly: no substring or fuzzy match. Cite both sides: `live:` for the identity, `code: <path>:<line>` for the pin.
  - Terraform, `allowed_account_ids` or an account variable in the environment's var-file: the account from `aws sts get-caller-identity` is listed in `allowed_account_ids`, or equals the variable.
  - Terraform, provider `assume_role`: the target identity is the account and role in the pinned role ARN. Prove it with an identity read through the same credential chain Terraform uses for that environment, for example a profile whose `role_arn` equals the pin, returning `assumed-role/<role>` in that account. A read of the base credentials proves nothing here. If no such read is possible, the tier is unproven.
  - Kubernetes: the context name from `kubectl config current-context`, or that context's cluster name or server from `kubectl config view --minify` (a local kubeconfig read; never `--raw`), equals the context or cluster the CI config names, or the Argo CD / Flux destination. A destination given only as a server URL cannot prove a tier.
- The environment's name alone does not prove it is dev or staging. `dev` or `stg` in a directory, workspace, var-file, account alias or context name proves nothing on its own.
- **H1 needs positive evidence that the target differs:** the environment the plan is for has a pin and the identity read does not match it, or the identity matches the pin of a different environment and not this one's. Or, with no pin, the identity at any later read differs from the identity shown for that same target at the first stop. Identity here means the account and role (or the context and cluster), not the full session ARN. Unproven is not a mismatch. For an `assume_role` pin, only an identity read through that pin's credential chain counts, for proof and for H1 alike: a read of the base credentials is neither proof nor a mismatch.
- When nothing is pinned, the operator may state the tier at the first stop. Record it as `operator-stated`. An `operator-stated` tier is not proven: an operator-stated dev tier does not open the dev lane and does not skip pre-flight.
- **An unproven tier gets prod gate levels.** Unproven covers: no pin; no identity read that can prove the pin (failed, not run, or not possible); an `operator-stated` tier; an environment that cannot be mapped.
- **Identity reads need no opt-in:** `aws sts get-caller-identity`, `kubectl config current-context` and `kubectl config view --minify` (never `--raw`). They return only who the caller is, not resource data. Run them first, before any other live command, and show the result at the first stop. No other live read is exempt.
  - AWS: GetCallerIdentity needs no IAM permission. `docs: https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity.html (2026-11-08)`: "No permissions are required to perform this operation."
  - Kubernetes: `kubectl config current-context` reads only the local kubeconfig. This is inferred from the cited pages, which do not say it in words. `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_current-context/ (2026-11-08)`: "Display the current-context". `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/ (2026-11-08)`: "Modify kubeconfig files".
  - Kubernetes: `kubectl config view --minify` also reads only the local kubeconfig, never the cluster. Inferred the same way. `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_view/ (2026-11-08)`: "Display merged kubeconfig settings or a specified kubeconfig file"; `--minify`: "Remove all information not used by current-context from the output"; `--raw`: "Display raw byte data and sensitive data", so `--raw` is never used.

## Hard gates

Every lane, never waived. A request to skip one is refused, citing its H-id and the reason. Where no lane stop carries a gate, the gate is its own stop, and the prompt starts with its H-id, for example `**[H3] …**`.

| ID | Gate | Held at |
|---|---|---|
| H1 | The target identity does not match the environment the plan is for: stop, run nothing further. | Its own stop `[H1]`, as soon as the evidence in Environment tier shows a mismatch. Show both identities. Run nothing further. "Proceed anyway" is refused. If the operator switches credentials, re-run the identity read; it must match. |
| H2 | Approval before every mutation: each apply command, each push + open PR, each merge the skill would do. | `[D1]`, `[B]`, `[F4]`. Each approves only the mutation it shows. Any further mutation gets its own approval. |
| H3 | The plan shows a destroy or replace that the approved plan did not name, or the parity check fails. | Its own stop `[H3]` at Step 4a, before pre-flight. Light lane: a destroy or replace also fails L1, and a parity failure escalates, then `[H3]`. Full lane: a parity failure is an `[H3]` stop. Dev lane: the approved plan is the one shown at `[D1]`. Parity detail: Staging-first › Parity check; SKILL.md Step 4a runs it. |
| H4 | Drift rows are acknowledged before planning. | Inside `[F2]`. Any other drift row (dev lane, or found after the plan) is its own stop `[H4]`, before anything further runs. |
| H5 | A RED verdict: acknowledgement for a soft block, written justification for a hard block. | Its own stop `[H5]`: pre-flight's GATE 2 on RED, before `[B]` / `[F4]`. |
| H6 | The duplicate check says already done, in flight or reverted. | Its own stop `[H6]` in Step 1, before planning. |
| H7 | Staging before prod. The only ways around it are the staging-first exceptions (a)–(c) (see Staging-first). | Checked before each `[B]` / `[F4]` whose mutation reaches prod: an apply, or a PR or merge that applies prod. No staging evidence and no recorded exception → its own stop `[H7]`. Ordering detail: Staging-first; SKILL.md Step 2 plans it. |
| H8 | Unsupported owner tool, or an import over an active CloudFormation / Serverless owner (existing rules). | Its own stop `[H8]` in Step 1. Rules: SKILL.md › Supported stack, and the Step 1 ownership check. |
| H9 | Pre-flight runs before every staging or prod apply. Only a proven dev target skips it. | Before each staging or prod `[B]` / `[F4]`. A reusable record counts as a run only under the full SKILL.md Step 4b reuse contract. An unproven target counts as prod. |

## Light-lane allowlist

L2 passes only when every change matches a row below. Here a change is one resource action in the plan output (`plan:`). Step 1 predicts the actions from the request and the code; Step 4a confirms them.
- Each change must match one row as a whole: its type, its action and every attribute it changes. An update that changes both `retention_in_days` and tags matches neither row, so it is off the list.
- No delete is on the list. An update of an alarm that changes anything but `tags` / `tags_all` is off the list. So is a new log group.
- The list is closed. Do not extend it by analogy. A change that matches no row is off the list, and the change is not light.

### Terraform AWS

| Resource type | Allowed action | Condition |
|---|---|---|
| `aws_cloudwatch_metric_alarm` | create | none (E1 checks its actions) |
| `aws_cloudwatch_composite_alarm` | create | none (E1 checks its actions) |
| `aws_cloudwatch_dashboard` | create or update | any attribute |
| `aws_cloudwatch_log_metric_filter` | create | none |
| any `aws_*` type | update | the only changed attributes are `tags` / `tags_all` (E2 checks each changed key) |
| `aws_cloudwatch_log_group` | update | `retention_in_days` increased, or set to `0` or unset (never expire). `0` or unset is the maximum, so going from `0` or unset to a number is a decrease: off the list. |

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

Any hit moves the change to the full lane, with the reason and the evidence (`code: <path>:<line>` or `plan:`). The record lists each hit under `Escalations:`. Run E1–E3 whenever the lane would otherwise be light (not dev, and L1–L3 hold): once the diff exists, before the stop that approves it, and again at Step 4a on the plan output. The dev and full lanes do not require them, but a hit found anyway escalates and is recorded.

**E1: an alarm action is not an SNS topic.** Check every value of `alarm_actions`, `ok_actions` and `insufficient_data_actions` in the diff. Each value must resolve to one of these:
- `aws_sns_topic.<name>.arn`;
- `data.aws_sns_topic.<name>.arn`;
- a literal SNS ARN in any AWS partition: `arn:aws:sns:`, `arn:aws-cn:sns:` or `arn:aws-us-gov:sns:`.

Follow a variable, local or module input to its value, and cite each step as `code: <path>:<line>`. A hit is any value that resolves to something else (a scaling policy, `arn:aws:automate:`, SSM, Lambda), or that you cannot trace to the end. At Step 4a, a known plan value for these attributes that is not such an SNS ARN is also a hit.

**E2: a changed tag key drives automation.** For each tag key that the diff adds, removes or gives a new value, on new and existing resources alike, run both commands from the repo root:

```
git grep -n -E 'aws:(ResourceTag|RequestTag)/<key>|aws:TagKeys'
git grep -n -F '<key>'
```

In the `-E` command, put a `\` before any regex metacharacter in `<key>`. Read every hit before you clear it. An unread hit counts as a hit.
- Clear a hit only when reading it shows it is not an IAM condition (`aws:ResourceTag/`, `aws:RequestTag/`, `aws:TagKeys`), an SCP, a backup selection, a scheduler, or any other tag-driven automation that uses this key.
- These clear: the line that sets the tag, and a comment that does not describe automation acting on this key. `# AWS Backup selects on this tag` is a hit.
- Unsure → hit.
- The commands see only this repo. Zero hits do not clear a key that other repos or org policies (SCPs, backup plans) may act on. If unsure, that is E3 "unsure" → escalate.

**E3: self-review.** For each resource action and each changed output, answer this question in writing: "does this change trigger an automated action, or does anything read this value?" Yes or unsure → hit. A "no" cites what was checked.

**E4: the operator asks for the full lane.** At any stop or at any time. Escalate at once and record it.

**`plan-confirm`** is the ID recorded when the Step 4a plan output escalates the lane, whether through L1–L3 or an E-check: `**Escalations:** plan-confirm — <evidence>`, citing the `plan:` line and the condition it fails.

## Stops per lane

A stop is a point where the operator must answer. Each stop prompt starts with its ID in brackets, for example `**[F2] Approve this plan?**`. Hard-gate stops (see Hard gates) come on top of these.

| Lane | Stop | Shows / asks | Operator answers | Soft |
|---|---|---|---|---|
| dev | `[D1]` | diff + plan output + target | apply, or open the PR | no |
| light | `[A]` | change plan + diff + target + read batch + L2 answers + any delivery-model question + any staging-first exception justification | approve | no |
| light | `[B]` | PR or apply, one per environment, showing the verdict line | proceed | no |
| full | `[F1]` | Step 1 read batch, with the targets and their tiers shown | approve the batch | yes |
| full | `[F2]` | GATE 1 plan + L2 answers + drift acknowledgements + exception justification | approve | no |
| full | `[F3]` | GATE 2 code + target + plan command | approve | yes |
| full | `[F4]` | PR or apply, per environment, showing the verdict | proceed | no |

Rules for all lanes:
- **Read batch.** One batch, each command shown. The identity read is exempt: it runs first, without opt-in, and the batch shows its result.
  - At `[A]` the batch holds the Step 1 live reads (live verification and the drift check), the plan command (`terraform plan` or the tool's diff), the matched assessor's L3 reads (`skills/pre-flight/assessors/iac-change.md` › L3 — Live Query Hooks, every category) for the resources the change is expected to touch, and the post-apply success-criteria reads.
  - At `[F1]` it holds the Step 1 live reads and the assessor's L3 reads. The full lane approves the success-criteria reads at `[F2]` and the plan command at `[F3]`.
  - A read approved at a stop needs no further stop. Inline pre-flight then normally proposes no batch of its own. A read it still finds missing is its one extra batch, and that batch is a stop. A declined read leaves its category ⚪.
- **L2 answers** (`[A]`, `[F2]`): pre-flight's Q1–Q5 and Q7; Q8 when the change plan touches an app-facing attribute; and the matched assessor's questions that the caller block cannot answer with evidence, as `<assessor>.<n>=…` (for the iac-change assessor: only question 4; 1–3 are answered by `Plan hash:`, `Delivery model:` and `Target:` + plan command). They go to pre-flight in the caller block (pre-flight Constraint 14). Anything missing makes pre-flight ask, which is an extra stop. So is a pre-flight L3 batch for reads the caller did not run.
- **Delivery model** `UNVERIFIED`: ask inside `[A]` / `[F2]` / `[D1]`, not as a stop of its own.
- **Verdict.** `[B]` / `[F4]` show the pre-flight verdict line. A YELLOW is shown with each Yellow and ⚪ finding and its mitigation; approving there is the acknowledgement, and it is recorded. **RED** adds the `[H5]` stop.
- **Dev lane.** Reads and the plan run without a stop. No pre-flight (H9); record `- Pre-flight verdict: skipped — dev lane (<evidence>)`. No fresh eyes; record `- Fresh eyes: skipped — dev lane`. Self-checks and the duplicate check still run.
- **Code before the first stop** (light and dev only): create the branch and write the code before `[A]` / `[D1]` only when `git status` is clean. Otherwise stop and ask, as today. Full lane: no code before `[F2]` is approved.
- **Multi-phase** (full lane): each phase gets `[F3]` and `[F4]`.
  - A phase with no IaC code change (an operational command only, such as an RDS reboot) has no `[F3]`. Its command is shown and approved at `[F4]` (H2).
  - Each phase's first stop (`[F3]`, or `[F4]` when the phase has no `[F3]`) shows the previous phase's verification result (Step 5a: the re-plan and the success-criteria reads). The separate phase gate goes away.
  - A failed success criterion stops the run, as today.
  - In the dev lane, each phase gets its own `[D1]` (H2).
- **Observation window** (staging → prod): no stop of its own. Light lane: prod's `[B]` comes once staging's success criteria pass. Full lane: see Staging-first.
- **No other stops**, except hard-gate stops and H2 approval of a further mutation (for example a merge the skill would do). GATE 5 and the standalone offers are removed. `[B]` / `[F4]` may carry one optional heads-up line (change-comms). The final message ends with one `Next:` line: commit the record, and draft the result or ticket-close message with change-comms.
- **Soft stops: `[F1]` and `[F3]` only.** The operator may waive one explicitly; the LLM never waives a stop. Record each waiver under `Waived:`. The waiver procedure is in SKILL.md.
  - Waived `[F1]`: run the read batch without asking.
  - Waived `[F3]`: show the diff, the target and the plan command at `[F4]` instead. The recorded waiver is the opt-in for the plan command, so the plan runs without a stop. One waiver covers every phase of the run unless the operator says otherwise. H1 still stops a target mismatch.
- **Every other stop holds.** A request to skip one is refused, citing the H-id it holds (H2 at `[D1]`, `[B]`, `[F4]`) or the reason it exists.
- **No check is waivable.** Fresh eyes keeps its existing skip rule.

## Timing re-ask

Pre-flight's Q1–Q3 (active incident, deploy freeze, peak traffic) describe the moment they were answered. As in pre-flight's reuse contract, they are re-asked before each later apply in the same run: each phase after the first, and each later environment. The dev lane runs no pre-flight and re-asks nothing.
- The first stop of that phase or environment carries one line: `Q1–Q3 still true? (incident / freeze / peak)`. The line adds no stop.
- That stop comes before pre-flight (`[F3]`): pass the fresh answers in the caller block's `L2 answers:`.
- That stop comes after pre-flight (`[F4]`, or `[B]`): an unchanged answer → proceed. A changed answer → re-run pre-flight with the new answers before the apply, then show a new `[F4]` / `[B]` with the new verdict. Only a changed answer adds a stop.

## Staging-first

H7 in rule form. SKILL.md Step 2 plans the order, Step 4a runs the parity check, Step 4b passes staging's evidence to prod's pre-flight, Step 4c checks H7 before each `[B]` / `[F4]` whose mutation reaches prod, and Step 5b records the outcome. None of it is a stop of its own: the exception questions go inside `[A]` / `[F2]`. The only stops it raises itself are the hard-gate stops `[H3]` and `[H7]`; any other comes from an operator's choice (a longer window, a staging rehearsal).

**When it applies.** Step 1 maps an environment to `staging`, and the change targets prod. A target that cannot be mapped counts as prod. The mapping sets the order; the proof sets the gate levels (Environment tier), so an unproven staging still goes first, at prod gate levels.

**Order.**
- The whole sequence runs in staging, then in prod: every phase in staging, then every phase in prod. This order is inferred from common rehearsal practice. The operator may ask for interleaving (each phase in staging, then in prod) at `[A]` / `[F2]`; the plan and the record say so.
- The code for every environment is written and approved once (`[A]`, or each phase's `[F3]`). `[A]` / `[F3]` show every environment's target and plan command, so prod's 4a runs on that approval (Constraint 3). After staging verifies, the run goes on to prod's Step 4a, never back to Step 3, and prod gets no `[F3]`. A prod diff that differs from the approved one needs new approval at `[A]` / `[F3]`.
- Commits. When the change has several phases or uses per-env PRs, each phase's approved code (every environment's files) is its own local commit on the change branch, made once approved; the next phase is written on top of it. Prod phase N plans and applies from phase N's commit. If the repo or the delivery model cannot express that (for example automation that applies only the default branch's head), the plan interleaves the phases instead, as the operator chooses at `[F2]`, and the record says so.
- Reads. Light lane: each environment's share of the `[A]` batch runs at its turn, so no prod read other than the identity read, and no prod plan, runs before staging verifies. Full lane: `[F1]` covers every environment before Step 2, because drift is acknowledged at `[F2]` (H4); at prod's turn, prod's category-10 reads from that batch run again, so prod's pre-flight sees prod's health as it is then. Both are pre-approved.

**Delivery per environment,** in order, by the delivery model from Step 1:
- apply runs (direct, or by hand after a merge that applies nothing): staging's first, prod's at prod's turn;
- per-env PRs: each environment's PR carries only its own files from the phase's commit, and the change branch itself is never pushed. At each environment's 4c, create its PR branch from the up-to-date `origin/<default>`: staging's first, prod's only after staging's PR has merged and staging has verified. Re-run the diff self-check on that branch: anything beyond that environment's part of the approved diff (for example a colleague's change it would undo) needs new approval;
- Atlantis / Terraform Cloud: the staging project is applied first (the operator comments or confirms the run; the skill never does);
- GitOps: the staging path first, then the controller's sync, then prod's path.

If one merge would apply the change to staging and prod together (a shared file or module with no per-env pin, or CI that applies every environment on merge), split it per environment: separate commits or PRs, or per-env module pins. If the repo cannot express the split, say so inside `[A]` / `[F2]`, with the evidence (`code:`). The operator then gives a written justification or aborts. Staging cannot go first, so this is exception (b), second form.

**Satisfied by evidence.** The staging phase counts as done when the duplicate check plus live reads show staging already has this change. Staging is not applied again, and prod's turn starts. Record `satisfied by evidence — <cite>`. A staging plan with no changes because the change has nothing to apply in staging (for example a value set only in prod's var-file) is not this: it is exception (b), first form.

**Exceptions (a)–(c)** are the only ways around H7. Each is recorded in the record and in the PR body.
- (a) No staging environment. Automatic, with evidence: the environments Step 1 mapped, none of them `staging` (`code:` the env dirs, var-files, workspaces or overlays). Record `n/a — no staging env (<evidence>)`.
- (b) A prod-only change: one that staging cannot go first for. It has two forms, each needing evidence, as (a) does: the change has nothing to apply in staging (`plan:` showing no changes in staging, or `code:` showing a path or value only prod uses); or one merge applies it to both and the repo cannot split it (the statement and its `code:` evidence, see Delivery per environment). Then ask for a written justification inside `[F2]` / `[A]`, as a field of the plan. Record it word for word: `exception (prod-only) — "<justification>"`; in the second form the text says why the change cannot be split. No evidence or no justification → the plan adds a staging rehearsal of the same change, or the operator aborts.
- (c) An incident hotfix: the incident reference and why the change mitigates it, in the format of pre-flight's incident override (`skills/pre-flight/SKILL.md` › Incident Context), asked inside `[F2]` / `[A]`. Record `exception (incident) — "<justification>"`. Pass the same answer to pre-flight in the caller block's `L2 answers:`, as `Q1=yes` and `Incident=<reference> · <how it mitigates> · <evidence> · <approver, if the freeze rules need one>`, so pre-flight does not ask its Incident Context follow-up again.

A change with no prod target, in a repo that has a staging environment, gives H7 nothing to hold. Record `n/a — no prod target (<evidence>)`. With no staging environment, (a) applies, whatever the targets.

**Observation window.** No stop of its own.
- Light lane: prod's turn starts once staging's success criteria pass.
- Full lane: the plan proposes a window with its reason (for example "24 h, so the nightly batch runs against the new value"), approved at `[F2]`. Prod's turn starts when it ends. The run waits until then, or for the operator to say it has ended; that wait is not an approval stop. At its end, re-run staging's success criteria.
- After a light→full escalation, propose the window at the first full-lane stop the escalation adds, and get it approved there. Before `[A]`, that is `[F2]`. At staging's 4a, it is staging's `[F4]`, and the window starts once staging verifies. At prod's 4a, it is prod's `[F4]`: show how long staging has run since its success criteria passed; approving `[F4]` accepts that as the window. If the operator wants a longer one, that `[F4]` ends without an apply, and prod's `[F4]` comes again when the window ends.
- Reads during the window are pre-approved at `[A]` / `[F1]`–`[F2]`. Prod's first stop shows staging's latest success-criteria result and re-asks Q1–Q3 (Timing re-ask).

**Parity check** (Step 4a, every prod phase, after the plan and the cross-check, before pre-flight).
- It runs only when a staging phase ran for this change. Under exceptions (a)–(c) the record says `Parity check: n/a`, and parity raises no `[H3]`. Satisfied by evidence: compare against the staging plan or apply output that the evidence cites; if none exists, `n/a — <reason>`.
- Compare against the plan staging applied for the same phase, plus the actions of any staging rehearsal added at `[H3]`.
- Normalise each resource address: strip the environment's name or index. `module.staging.aws_db_instance.main` and `module.prod.aws_db_instance.main` both become `module.<env>.aws_db_instance.main`; `aws_sqs_queue.q["prod"]` becomes `aws_sqs_queue.q[<env>]`. Plans made per var-file or per workspace usually share their addresses already. Kubernetes: kind, namespace and name, normalised the same way.
- Take each action in prod's plan: `create`, `update` (in place), `replace` or `destroy` (data-source reads aside). Look for the same normalised address in staging's plan with the same action. Missing, or a different action → `untested in staging: <address> <action>`, one per action. Compare actions only; value differences go to prod's pre-flight as staging evidence.
- No untested action → `pass`.
- Light lane: an untested action escalates (`plan-confirm`, citing both `plan:` lines). The change is now full, so the next item applies, and prod's `[F4]` replaces `[B]` (When the lane is decided).
- Full lane: an untested action is `[H3]`, before prod's pre-flight, even if `[F2]` named the action. One `[H3]` also carries any destroy or replace from the cross-check. It shows each untested action with staging's and prod's `plan:` lines, and the cause where the code or docs show it. It offers exactly three choices:
  - abort: prod is not applied, and the record keeps staging as applied (`Outcome: aborted`);
  - add a staging rehearsal: back to Step 2, where the plan gains a staging step that exercises the action, approved again at `[F2]` / `[F3]`; prod's 4a then runs the check again, now counting the rehearsal's actions as tested;
  - accept with a written reason: the parity line records it, then prod's pre-flight runs.

**Staging evidence for prod's pre-flight** (Step 4b, when a staging phase ran). Put it in the caller block's `Evidence table:`, under the line `Staging evidence (evidence, not proof):`.
- Measured disruption during staging's apply (duration, restarts, failovers, events), staging's success-criteria outputs, and staging's health before and after the apply. Cite each as `live: <cmd> (staging, <time>)`.
- Each size difference between the env var-files (instance class, count, storage, capacity, version), cited `code: <staging var-file>:<line>` against `code: <prod var-file>:<line>`.

It is evidence, not proof: it never by itself makes a category Green. It stays out of `Live results:`, which lists reads of the target pre-flight is assessing.

**Record** (SKILL.md Step 5b). `**Staging-first:**` takes one form: `applied — staging <time>`, `satisfied by evidence — <cite>`, `n/a — no staging env (<evidence>)`, `n/a — no prod target (<evidence>)`, or `exception (prod-only|incident) — "<justification>"`. The PR body carries the same line. A PR opened before staging has applied (staging's own PR, or one PR for both environments) carries `**Staging-first:** applied — pending (staging not applied yet)`; prod's PR and the record carry the final value. With staging-first, `Applied:` has one clause per environment, staging first, each taking a value from the 5b list: `**Applied:** staging yes — verified (<cite>); prod no — not applied (aborted at [H3])`. Each phase entry has `- Parity check: <pass | untested in staging: <address> <action> | n/a>`; staging's own entries say `n/a`. An accepted untested action adds ` — accepted at [H3]: "<reason>" (operator, <time>)` to its line.
