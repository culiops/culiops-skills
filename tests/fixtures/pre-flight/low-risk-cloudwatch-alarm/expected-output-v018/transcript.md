# Dry-run transcript: pre-flight vs low-risk-cloudwatch-alarm

Operator (first message): "Run pre-flight on this Terraform change before I apply it."
No caller block was passed.

## Mode decision

The skill's inline mode starts only when the `### Caller context (iac-change-execution)` block is present with its heading and every field (SKILL.md:43, SKILL.md:448). There is no block here, so the run is **standalone**. Nothing is dropped: GATE 1, the full L2 batch, the L3 opt-in and GATE 2 all stay. No `Lane:`, `L2 answers:` or `Live results:` exist to cite.

## Step 1 - detect

Reads (fixture files, standing in for cat/grep): `plan-output.txt`, `main.tf`, `variables.tf`, `envs/prod.tfvars`.

Command: `echo "$CULIOPS_HOME"` (Constraint 13, resolve output root)
- no canned output -> treated as unset/empty -> output root is `.culiops/` at the repo root (SKILL.md:42). Shown to the operator at GATE 1.

Unsupported-stack check: Terraform on AWS -> supported.

Assessor match: loaded `assessors/iac-change.md` (only assessor). The input has a `Plan:` summary line (plan:26) -> match.

Target (from plan, IaC and operator; unknown parts are asked, not guessed):
- AWS account / region: `123456789012` / `us-east-1`, inferred only from the SNS topic ARN in `envs/prod.tfvars:2`. No provider block and no backend block exist in the fixture. Marked UNVERIFIED.
- Var-file: `envs/prod.tfvars` (inferred: plan values for `env` match `envs/prod.tfvars:1`).
- Workspace: not found. Backend key: not found. Both asked at GATE 1.

Delivery model: no pipeline file, Argo CD `Application` or Flux `Kustomization` in the fixture. Nothing found -> UNVERIFIED -> ask the operator and record `operator-stated`. The first message says "before I apply it", so the proposed value is `manual apply`.

Plan hash: the skill writes the exact plan text to a scratch file outside the repo, runs `sha256sum`, deletes the file.
- Command: `sha256sum <scratch plan file>` -> no canned output. Hash not obtained. A scratch file outside the repo is also outside this dry run's file rules.
- SKILL.md has no explicit fallback for "plan given, hash command failed". Closest rule is `none — record not reusable` (SKILL.md:250, Constraint 5). Used that.

Plan source (command that produced the text): not stated by the operator; the supplied text lacks the provider header, so plan vs show can't be told. `UNVERIFIED`.

### Skill message (GATE 1) - STOP 1

> Detected action type: Terraform plan, create-only. Scope: 1 resource, `aws_cloudwatch_metric_alarm.orderapi_cpu` (plan: 1 to add, 0 to change, 0 to destroy; no replace, moved, removed or import). Matched assessor: `iac-change`.
> Target: account `123456789012` / region `us-east-1` (UNVERIFIED: inferred from the SNS topic ARN in `envs/prod.tfvars:2`; no provider block); var-file `envs/prod.tfvars`; Terraform workspace and backend key not found in the files you gave me (please supply, or tell me they are default / not applicable).
> Delivery model: manual apply by you, `operator-stated` (from "before I apply it"; no pipeline file found).
> Plan hash: none - not computed (`sha256sum` unavailable in this session), so this record will not be reusable.
> Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset). Records go to `.culiops/pre-flight/`. Say if you want a different root.
> I detected this as a Terraform create change affecting one CloudWatch alarm in the target above, delivered by manual apply. Is this correct?

Operator answer (unscripted): **confirm.**

Result: the confirmation names no workspace or backend key, so both stay `not provided` in the record. Delivery model `manual apply` is now `operator-stated`.

## Step 2 - L1 static analysis

Reads (fixture files):
- plan:3 create, plan:4 resource, plan:5-23 attributes, plan:26 summary `1 to add, 0 to change, 0 to destroy`.
- `main.tf:1-19` one `aws_cloudwatch_metric_alarm`; `main.tf:6-9` metric `CPUUtilization`, namespace `AWS/ECS`, `statistic = Average`, `threshold = 80`; `main.tf:17-18` `alarm_actions` and `ok_actions` both point at `var.sns_topic_arn`.
- `variables.tf:1-9` two variables; `envs/prod.tfvars:1-2` `env = "prod"`, `sns_topic_arn` set.
- Catalog: read `.culiops/service-discovery/orderapi.md` -> file not present in the fixture. No catalog.
- Plan hygiene: no "Objects have changed outside of Terraform" block (no drift rows from the plan); no destroy / replace / moved / removed / import.

Commands (git history, Constraint 7/L1):
- `git log --since=7.days --oneline <base> -- main.tf variables.tf envs/prod.tfvars` -> no canned output
- `git log <base>..HEAD --oneline` -> no canned output
- `git status` -> no canned output
- `git rev-parse --short HEAD` -> no canned output

All four are failed reads. Change velocity has no signal -> pending as ⚪. Record `Commit:` is `unknown`.

Application compatibility, L1 marking. Every changed attribute belongs to one alarm. Per the assessor's not-app-facing list, an alarm is not-app-facing only if its actions only notify (SNS subscriptions all `email` / `email-json` / `sms`), checked with the protocol query in `examples/aws.md`. The protocols have not been checked, so the alarm is treated as **app-facing** (SKILL.md:69, assessor `iac-change.md:215`: "unsure means triggered"). Triggered attributes: `alarm_actions`, `ok_actions` (SNS topic `orderapi-alerts`). This is why Q8 is asked.

Preliminary L1 scores (cited): 1 create-only single resource (plan:3,26); 2 no in-place attribute change, no destroy (plan:3,26); 3 pending/⚪ (git unavailable); 4 no catalog, not-app-facing exception unavailable -> ⚪; 7 static-threshold alarm in code only -> Yellow; 8 new resource, price not looked up -> Yellow; 9 no security-relevant attributes (plan:4-24) -> Green. 5, 6, 10 pending.

## Step 3 - L2

Skipped on evidence: assessor Q1 (have you run and reviewed the plan?) is answered by the supplied plan text; assessor Q2 (delivery model) was asked and answered at GATE 1 (`manual apply`, operator-stated). Standard Q1-Q7: no L1 evidence answers any of them, so all are asked. Q8 is asked because L1 found an app-facing change. The assessor questions follow the standard 7 in the same message.

### Skill message (L2) - STOP 2

> **Pre-flight context check:**
> 1. Is there an active incident affecting this service or its dependencies? (yes/no)
> 2. Is there a deploy freeze or change window restriction? (yes/no)
> 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure)
> 4. Have you changed this service before? (many times / a few times / first time)
> 5. Have you used this IaC tool before? (experienced / some experience / first time)
> 6. What's the expected cost impact? (negligible / moderate / significant / unknown)
> 7. Any other context I should know? (free text, optional)
> 8. This change touches what the app depends on: `alarm_actions` and `ok_actions` (SNS topic `orderapi-alerts`; the alarm counts as app-facing until the topic's subscriber protocols are checked). Where is the application source? (a) a local checkout - give the path; (b) a GitHub repo through `gh` - give `owner/repo` and the deployed ref; choosing (b) approves only these `GET` reads: `gh auth status`, resolve the ref to a SHA, list the file tree at that SHA, fetch file contents at that SHA; (c) not available.
>
> IaC-specific:
> A3. Was the plan made with `-target`, `-refresh=false`, or a non-default workspace / var-file? (yes / no / unsure)
> A4. Has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)

Operator answers (unscripted, per the run rules):
- Q1 = no
- Q2 = no
- Q3 = no
- Q4 = many times
- Q5 = experienced
- Q6 = negligible
- Q7 = none
- Q8 = (c) not available
- A3 = "as proposed / yes"
- A4 = "as proposed / yes"

Recording:
- Q1, Q2, Q4, Q5: `operator` (operator-only facts). Q3, Q6: `operator-stated` (checkable; L3 not yet run).
- Q1 = no, so no Incident Context follow-up.
- A3 "yes": the non-default var-file part is certain (the only var-file is `envs/prod.tfvars`). The answer does not say whether `-target` or `-refresh=false` were also used, and the state is not readable. Per the assessor (Plan hygiene), a targeted or unrefreshed plan makes blast radius and reversibility ⚪ at best. Not ruled out -> categories 1 and 2 become ⚪. `operator-stated`. No follow-up stop is made, since the skill text prescribes none.
- A4 "as proposed / yes" does not match any of the three options -> recorded as `unsure`, `operator-stated (unverified)`.
- Q8 = (c) -> category 11 is ⚪.

Step 3b (app source scan): not run. Q8 = (c); category 11 is ⚪ with the reason "app source not available". No `gh` or local reads.

## Step 4 - L3

Built from the assessor's `## L3 — Live Query Hooks` and `examples/aws.md`; target check first.

### Skill message (L3 opt-in) - STOP 3

> I can check live system health with read-only queries if you have CLI access. Without it, resource health stays ⚪ and the best possible verdict is YELLOW. Here are the commands I'd run:
> 1. Target check: `aws sts get-caller-identity --query Account --output text` - must equal `123456789012`; region `us-east-1` (both inferred from the var-file, no provider block).
> 2. ECS health (cat 10): `aws ecs describe-services --cluster orderapi-cluster-prod --services orderapi-svc-prod --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount}' --region us-east-1`
> 3. CPU, last 1h (cat 10, 5): `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=orderapi-cluster-prod Name=ServiceName,Value=orderapi-svc-prod --start-time {T-1h} --end-time {now} --period 300 --statistics Average Maximum --region us-east-1`
> 4. Alarms firing in the region (cat 10): `aws cloudwatch describe-alarms --state-value ALARM --region us-east-1 --query '{metric:MetricAlarms[].{name:AlarmName,ns:Namespace,metric:MetricName,dims:Dimensions},composite:CompositeAlarms[].AlarmName}'`
> 5. Alarms already on this metric (cat 7): `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=orderapi-cluster-prod Name=ServiceName,Value=orderapi-svc-prod --region us-east-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> 6. SNS subscriber protocols only, never endpoints (cat 4, 11): `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:123456789012:orderapi-alerts --query 'Subscriptions[].Protocol'`
> 7. Alarm price for the region, with the lookup date (cat 8): `aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=us-east-1 --max-results 10` (adapted from the EC2 template in `examples/aws.md`; narrowed to the alarm product at run time)
> Not listed: request rate vs baseline and last-apply time - no load balancer, state bucket or key appears in the IaC.
> Run them? (yes/no)

Operator answer (unscripted): **yes.**

Execution:
1. `aws sts get-caller-identity --query Account --output text` -> **no canned output.** The live identity cannot be confirmed against the Step 1 target. Constraint 10 allows L3 queries only after the identity matches, so queries 2-7 are not run. (They would each return `no canned output` anyway.) Told to the operator: "Target check failed to return; I did not run queries 2-7."
2-7. not run (Constraint 10); same result as a failed read.
- Documentation tool: no `docs:` lookup made this session (no canned output), so no price and no behaviour claim is cited.

Per SKILL.md:132: "L3 unavailable for [category] - scoring based on L1+L2 only". Category 10 is ⚪. Verdict capped at YELLOW at best.

## Step 5 - Score

| # | Category | Score | Driver |
|---|---|---|---|
| 1 | Blast radius | ⚪ | create-only single resource (plan:3,26) but A3 = yes, plan completeness unconfirmed |
| 2 | Reversibility | ⚪ | create-only, rollback git revert -> plan -> apply; same A3 caveat |
| 3 | Change velocity | ⚪ | git history unreadable; A4 unparseable |
| 4 | Dependency impact | ⚪ | no catalog; not-app-facing exception unavailable (protocols unchecked) |
| 5 | Timing context | ⚪ | Q1, Q2 `operator` = no; Q3 "not peak" only `operator-stated`; apply time not stated; L3 request-rate check unavailable |
| 6 | Operator familiarity | 🟢 | Q4 many times, Q5 experienced, `operator` |
| 7 | Observability readiness | 🟡 | static-threshold alarm in code only (main.tf:6-9); not-app-facing shortcut unavailable; no live confirmation |
| 8 | Cost impact | 🟡 | new resource; price not looked up; Q6 negligible `operator-stated` |
| 9 | Security posture | 🟢 | no IAM, network, encryption, public-access, audit-log or secret change (plan:4-24) |
| 10 | Resource health | ⚪ | L3 unavailable |
| 11 | Application compatibility | ⚪ | triggered (alarm treated app-facing); Q8 = (c) no source |

Counts: Red = none. Yellow + ⚪ = 9 (1, 2, 3, 4, 5, 7, 8, 10, 11). Hard-block conditions checked: cat 2 (irreversible data change / public IP release: none, plan:3,26 create-only), cat 5 (active incident + freeze: Q1 no, Q2 no), cat 9 (public exposure / encryption removal / secrets: none, plan:4-24), cat 10 (error budget exhausted: not established, no live data, not triggered). None triggered. 3+ Yellow/⚪ -> **RED - soft block (escalation)**.

## Step 5b - Verify

1. Citation check. Re-opened: the only Green on the mandatory list (cat 9) -> plan:4-24 shows no security-relevant attribute; hard-block conditions for cats 2, 5, 9, 10; mitigation premises (`envs/prod.tfvars:2` names the SNS topic, `main.tf:17-18` lists the actions). No fixes needed. Citations checked: 7.
2. Source conflicts: none. The tfvars and plan agree. No catalog present.
3. Verdict arithmetic: written above and in the record.
4. Fresh eyes: the skill requires it "always, unless the verdict is RED - soft block" (SKILL.md:327). Verdict is RED - soft block, so the reviewer is not required. `fresh-eyes: not run - dry run` would also apply; the skill itself does not call for one here. Recorded as `not required (verdict RED — soft block)`.
5. Not verified: listed in the record.

## Step 6 - Report (presented to the operator)

Verdict: **RED - soft block** (escalation: 9 of 11 categories are Yellow or ⚪, none individually Red, no hard block). Seven categories are unknown, so I suggest gathering more information before proceeding (SKILL.md:68).

No catalog was found; consider running service-discovery first for a more complete assessment (SKILL.md:435).

Scorecard: see `preflight-record.md` (same table). Drift rows: none from the plan; live not checked.

Findings (what / why / mitigation):
- Cat 1, 2 ⚪: Create-only, one resource. You answered yes to "-target / -refresh=false / non-default var-file" without saying which. A targeted or unrefreshed plan can hide changes. Mitigation: say which applies, or supply a plain plan for `envs/prod.tfvars`.
- Cat 3 ⚪: Git history was unreadable. Mitigation: read-only `git log` of the changed paths for 7 days (excluding this change) and `git status`.
- Cat 4 ⚪: No catalog; nothing in the 3 IaC files references the alarm but other stacks are invisible; the alarm counts as app-facing until SNS protocols are read. Mitigation: approve the protocol read, or run service-discovery first.
- Cat 5 ⚪: "Not peak" is your statement only. Mitigation: request-rate check (L3), or confirm the apply window.
- Cat 7 🟡: Static-threshold alarm (CPU > 80%) exists in code only. Mitigation: after apply, confirm the new alarm is enabled and leaves `INSUFFICIENT_DATA`.
- Cat 8 🟡: New billable resource, price not looked up. Mitigation: look up the CloudWatch alarm price for `us-east-1` and record the date.
- Cat 10 ⚪: No live health data. Mitigation: approve the L3 health checks.
- Cat 11 ⚪: Alarm actions notify an SNS topic whose subscribers are unknown; no app source. Mitigation: read the subscriber protocols (all email / sms makes it not-app-facing).
- Green: cat 6 `operator` (Q4, Q5); cat 9 `plan:4-24`.

### Skill message (GATE 2) - STOP 4

> Verdict RED - soft block (escalation; no individual Red finding). Acknowledge the findings above with a stated reason, and tell me which mitigations you commit to, or abort?

Operator answer (unscripted): **acknowledge and proceed.**

Result: acknowledged, no separate reason given beyond "proceed", and no mitigation named. Recorded as acknowledged; mitigations recorded as not committed. SKILL.md:339-341 asks for "a stated reason" per Red finding; none of the findings is itself Red, and the scripted answer carries no reason, so I did not open a further stop.

## Step 7 - Record

Intended path: `.culiops/pre-flight/orderapi-cpu-alarm-create-20261108-HHmm.md` (the clock is not readable: `date` -> no canned output; written here as `preflight-record.md`).

Command: `git check-ignore -q .culiops/pre-flight/<filename>` -> no canned output. The commit offer applies only if `.culiops/` is tracked and the current branch is not the default; neither could be established, so **no commit offer** is made (no stop). Record left uncommitted. Re-read the record for secret values: none (account ID and topic name are identifiers; no env values, no Secret data, no raw plan text).
