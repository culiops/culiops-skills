# Health snapshot — rule data for iac-change-execution

SKILL.md and `lanes.md` cite this file by section name, as `snapshot.md › <heading>`. A **health snapshot** reads the health of the changed resources and of their one-hop dependents and dependencies. It runs before each apply and after it, and the comparison can fail the phase. The same reads answer pre-flight's L2 questions, so the operator is not handed a questionnaire. It reads health, not configuration: configuration is in the Step 1 evidence table and the plan. This file holds the rules. The commands are in `examples/aws.md` / `examples/kubernetes.md` › Health Snapshot.

**IDs (exact):** snapshots `S0`, `S1`, `S2` · verdicts `ok`, `regressed`, `improved`, `no data`, `no data (low volume)`, `no data (replaced)`, `after: too early` · phase verification `fail (snapshot)` · hard gate `H10`.

- Every snapshot read is read-only, projects only the fields it needs and never retrieves a secret value (SKILL.md Step 1, Live verification batch; pre-flight Constraint 9). Every value carries its command, window and time (`live:`), and every member its source (SKILL.md Constraint 9).
- The normal path adds no stop: each read is approved in a batch the operator already approves. The only stop the snapshot adds is `[H10]`, on a regression.
- The numbers below (the cap, 15 minutes, two periods, 30 minutes, 1.5×, 70%, the error floors, the low-volume floor) are inferred defaults, not measurements. The team may set its own. Show the measured value next to every verdict.

## Snapshot set

**Members.** Every resource the change touches, plus its direct (one-hop) **dependents** and **dependencies**. Dependents are the consumers that break when it changes. Dependencies show whether something was already broken. Step 1 predicts the touched resources from the request and the code; Step 4a confirms them from the plan.

**Sources.** Each member cites where it came from.
- `code:` / `plan:` references in the repo: security-group rules that reference the changed group; `terraform_remote_state` consumers of changed outputs inside the repo; DNS records and aliases pointing at the resource; listeners and target groups; env vars, parameters and ConfigMaps that hold its endpoint (names only, never values); Kubernetes Services and Ingresses that select it; IAM policies that grant access to it.
- `catalog:` the service-discovery dependency graph. It is a lead: confirm each member in code or live (SKILL.md Constraint 9).
- The "Wiring (configured callers)" table of `.culiops/runtime-trace/<service>-runtime-profile.md`, when it exists under the output root.
- The assessor's L3 Dependency impact consumer reads (`skills/pre-flight/examples/<cloud>.md` › Disruption and dependents).

**Coverage line.** Show it with the set every time, and record it: `Snapshot coverage: <sources used>; not covered: <gaps>`. With no catalog and no runtime profile, callers that live in other repos are not covered, and the line says so. Never present the set as complete.

**Order and cap.**
- The changed resources come first, and the cap never cuts one. Then critical-path members (the catalog's critical-path edges), then other dependents, then dependencies.
- Default cap: 10 members that get reads. It keeps the batch short. The operator may raise it at the batch stop. List each member over the cap as `not snapshotted — over cap`. The coverage line names them as a gap.

**Members with no health signals** (security groups, IAM policies, DNS records, ConfigMaps, parameters):
- Measure them through their one-hop dependents, the workloads that use them: the services or instances attached to a security group, the workload that assumes a role, the load balancer a record points at, the Deployment that mounts a ConfigMap.
- The resource itself gets no rows. List it as `n/a — no health signals of its own`. It does not count against the cap.

**Not-app-facing changes** skip the dependents and dependencies. These are changes where every changed attribute is on pre-flight's not-app-facing list (`skills/pre-flight/assessors/iac-change.md` › Application compatibility) and no output or export changes, such as adding alarms, dashboards or tags. Pre-flight scores category 4 Green for exactly this case ("nothing can depend on it"). For such a change:
- the set is the service the change belongs to: its workload, plus its load balancer or other front door when it has one. S0 reads them because the L2 answers need them: `Q1(alarms)` reads their alarms, and Q3 reads the front door's request rate;
- there are no dependents or dependencies in the set;
- S2 has no two-period wait (When snapshots run).

**Blast radius is the snapshot set.** Step 2's blast-radius field names the set, so one list is named once and measured. If the 4a plan touches a resource outside the set, add it. Show its reads at the execution stop (`[D1]` / `[B]` / `[F4]`), where they are approved. They run on that approval, before the apply, and give that member's before value. That stop exists anyway, so no stop is added.

## Signals

A snapshot reads a fixed, small set of signals per member: firing alarms or alerts; readiness, or desired vs running state; and the golden signals the resource type has (traffic, errors, latency, saturation). Record each value with its command, window and time. The commands, the metric names (cited `docs:`) and the query-file format are in `examples/aws.md` / `examples/kubernetes.md` › Health Snapshot.

**AWS.**
- Alarms: one `aws cloudwatch describe-alarms --state-value ALARM` per region, filtered locally to the set. List other firing alarms as context only: they enter no verdict and no L2 answer.
- Metrics: one `aws cloudwatch get-metric-data` call per region, with one query file covering every member's signals. S0 and S1 read the hour ending now and the same hour last week (Q3, and noise context). The same call reads the last 7 days hourly when Q3 needs peak hours (L2 from evidence). Write the query file under the output root (SKILL.md Constraint 13), in `iac-change-execution/`, never elsewhere in the repo tree.
- Point-in-time state: ECS running vs desired and its deployments, ALB target health, RDS status. These extend `examples/aws.md` › Verification Checks.

**Kubernetes.**
- `kubectl get deploy,sts` ready vs desired, pod restarts, recent `Warning` events, HPA state.
- Metrics-backend queries (PromQL, with `offset 1w` for last week) when a backend is reachable.
- No backend reachable: the snapshot is point-in-time only. Say `no metrics backend — point-in-time only` against the members and in the coverage line. No metric signal is compared, and Q3 has no request-rate source.

**Batch length.** The snapshot adds at most about five commands per environment, whatever the member count: one alarms read, one metrics call per region or backend, and one state read per resource type. No read runs twice: the snapshot's alarms, metrics and state reads are also the assessor's L3 reads for categories 5 (timing) and 10 (resource health) on the set (`skills/pre-flight/assessors/iac-change.md` › L3 — Live Query Hooks). Run each once, and pass it in the caller block's `Live results:`.

## When snapshots run

**S0 — with the Step 1 read batch.**
- Full lane: in `[F1]`, run after it. Light lane: in `[A]`, run after it. Dev lane: run with no stop. Staging-first: each environment's S0 runs with that environment's share of the batch (`lanes.md` › Staging-first, Reads).
- S0 feeds L2 from evidence, and pre-flight's categories 3 (through `iac-change.4`), 5 (timing) and 10 (health).

**S1 — before each apply.**
- The latest snapshot of that environment, read again if it is older than 15 minutes. Reused: record it as reused, with its age.
- Take it after the 4a plan and before 4b's pre-flight, so pre-flight and the execution stop (`[B]` / `[F4]`) see the same S1. If S1 changes `Q1(alarms)` or Q3 from what pre-flight got, re-run pre-flight (`lanes.md` › Timing re-ask). Dev lane: no pre-flight, so S1 just precedes `[D1]`. It was approved with the batch, so it needs no stop. S1 is the "before" of that apply.
- S1 replaces the alarm and peak parts of the Q1–Q3 re-ask (`lanes.md` › Timing re-ask). The operator line is still shown at that stop.

**PR path where CI, GitOps or PR automation applies later.**
- "Before" is the metric window ending at the apply time, read after the fact once the operator says the apply has landed. The apply time comes from a live read (the CI run, the ECS deployment `createdAt`, `helm history`), or from the operator as `operator-stated`. Point-in-time state cannot be read back: it comes from the last snapshot taken before the PR, labelled with its time.
- Metrics can be read back only within retention. `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html (read 2026-11-18)`: "Data points with a period of 60 seconds (1 minute) are available for 15 days"; "After 15 days this data is still available, but is aggregated and is retrievable only with a resolution of 5 minutes."

**S2 — after the apply, in Step 5a, with the success criteria.** Approving the success criteria approves S2 (`[A]` / `[F2]`; dev lane: no stop).
- S2 starts once the rollout is complete, using the waits in `examples/` › Health Snapshot:
  - ECS: `aws ecs wait services-stable`. `docs: https://docs.aws.amazon.com/cli/latest/reference/ecs/wait/services-stable.html (read 2026-11-18)`: "Wait until JMESPath query length(services[?!(length(deployments) == 1 && runningCount == desiredCount)]) == 0 returns True"; it "will exit with a return code of 255 after 40 failed checks", and a non-zero exit is not a completed rollout.
  - Kubernetes: `kubectl rollout status`. `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_status/ (read 2026-11-18)`: "By default 'rollout status' will watch the status of the latest rollout until it's done."
- **Two periods.** At least two of each metric's periods must have elapsed after the apply, or after the disruption ends where the plan names one (Comparison).
  - Count elapsed periods, not datapoints received. A count metric may publish nothing at zero. `docs: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html (read 2026-11-18)`: "If there are no requests flowing through the load balancer or no data for a metric, the metric is not reported."
  - Fill a count metric's missing periods with 0, using metric math `FILL`. `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html (read 2026-11-18)`: "Fills the missing values of a time series."
  - `FILL` cannot tell zero from late. The same page warns, for alarms, that with metrics "published with a slight delay … FILL replaces that missing data point with the requested value"; reads are inferred to behave the same. So trust a filled 0 only in a period where another series of the same member (its request or invocation count) has a datapoint. Never fill a gauge (CPU, memory, latency).
- **Before two periods** have elapsed, the signal is `after: too early`, never `ok`. Say `S2 ready at HH:MM`, and read S2 then. The wait is not a stop.
- **Maximum wait:** 30 minutes after the rollout completes. Signals still too early then stay `after: too early`, and the environment's result is `Applied: yes — not verified`, the existing value. That is not a fail. A `regressed` already read still fails.
- **PR path:** if the operator says "landed" too early, say `S2 ready at HH:MM`, and run S2 then or when the operator next speaks. This is the existing "tell me when the apply lands" re-entry (SKILL.md Step 5b, Final message), with no new stop.
- **Observation window** (`lanes.md` › Staging-first): at its end, S2 runs again with staging's success criteria, so a delayed regression still blocks prod.
- **Not-app-facing change:** no two-period wait. S2 reads the alarms and the point-in-time state once, with the success criteria, which verify the change as today. No metrics call: its metric signals have no after-read, so they are left out of the counts and the no-data list, not counted as `no data`.

## Comparison

Each member and signal gets a before value (S1, or the S0 it reused, or the PR path's window ending at the apply time), an after value (S2) and a verdict: `ok`, `regressed`, `improved` or `no data`.

**`regressed`** uses pre-flight's default thresholds (`skills/pre-flight/SKILL.md` › Scoring Rules: "Thresholds are defaults, not measurements"), shown next to the measured values:
- an alarm on a member is firing after the apply and was not firing before;
- error count or rate, or p95 latency, is above 1.5× its before value (for errors, with the floor below);
- saturation crosses 70% from below;
- ready vs desired, healthy targets or running count is lower than before;
- restarts increased, or new `Warning` events appear on a member.

Compare an error rate (errors ÷ requests) where the member has a request count, and a count per period where it has none. An error signal is `regressed` only when both hold: the after window holds at least 5 errors, whatever the before value; and the rate or count is above 1.5× its before value, or, from a before value of 0 (no ratio), the after rate is ≥ 1% of requests. Below either bar the verdict is `ok`, with the values shown. Both bars are inferred defaults the team may set its own: a single sporadic error must not raise `[H10]`, and 1% is one failed request at the 100-request low-volume threshold, which still applies first.

**`improved`** is the same test the other way: below the before value ÷ 1.5, saturation crossing 70% from above, more ready or healthy than before. **`ok`** is neither.

**Low volume** (an inferred default). Fewer than 100 requests (or invocations, messages, jobs) in either window gives `no data (low volume)` for that member's error and latency signals, not `regressed`. Below 100, one failed request is 1% or more of the window, so a 1.5× ratio can be a single request.

**`no data`**: the signal has no value in one of the windows (a declined or failed read, no datapoint, no metrics backend). `no data (low volume)`, `no data (replaced)` and `after: too early` count as `no data` too. `no data` for every signal of a member does not fail the phase: list it with the no-data members beside `Applied:` (Record).

**Changes made on purpose are not regressions.**
- **Changed resources** are judged by their success criteria, which state the expected values: the new instance class, the new running count, the new alarm existing. The thresholds apply to them only for signals the success criteria do not cover.
- **The plan's Disruption field** (`restart` / `failover` / `replace` / `brief unavailability`) names expected transient effects. For every member, S2's window starts after the disruption ends: the rollout complete (the waits above), or the database's status `available` again (`live:`). Dependents get the same window, because the named disruption is what they feel during it. The two periods count from there.
  - RDS: `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html (read 2026-11-18)`: "The reboot process leads to a brief outage. During this outage, the DB instance status is rebooting."
- **A replaced resource** has no before series under its new identity: `no data (replaced)`, judged by its success criteria.
- **A new alarm** has no before state, so it is not "newly firing". Report its state: that is a success-criteria matter. An alarm that was already firing before is not `regressed` either.
- **Dependents** get the thresholds in full. Nothing about them is expected to change.

**Result.** Any `regressed` sets the phase verification to `fail (snapshot)` (After a regression). The first stop of the next phase or environment shows `Phase <N> success criteria: <check> — <pass/fail>`, then `Snapshot: <n ok · n regressed · n no data>`.

## After a regression

`[H10]` is a hard gate (`lanes.md` › Hard gates): every lane, dev included, never waived. This section is its behaviour.

**The stop.** Any `regressed` in a phase's S2 raises `[H10]`, its own stop, before anything further runs. It stops and reports, as a failed success criterion does (SKILL.md Step 4, Multi-phase handling). There is no automatic rollback (SKILL.md Constraint 8), and no rollback command runs. The prompt starts `**[H10]`, for example `**[H10] Health regressed after the apply of phase <N> in <env>. Type a reason to continue, or the run stops here.**`, and shows:
- each regressed signal: member, signal, before and after values, the threshold, and each read's command and time;
- the words "observed after the apply; the change is a suspect, not a proven cause";
- the `no data` members, and the plan's rollback path for this phase (informational: the operator's call).

**Answers.** There is no default answer.
- **A typed reason continues the run,** but only when the phase's success criteria passed; a failed success criterion stops the run as today. A reason says why the regression is unrelated or accepted, for example "unrelated: staging load test started 10:40, see #ops".
  - Record it word for word on the phase entry, `- Snapshot override: <reason> — operator, <time>`, as pre-flight records a RED justification at `[H5]`. Never rewrite it as evidence.
  - The phase verification stays `fail (snapshot)`, with the override beside it, and the environment's `Applied:` clause stays `yes — not verified` (Record).
- **Anything else ends the run:** "ok", "continue", "yes", "stop", or any other reply that gives no reason.
  - `Outcome: partially completed`, as for a failed success criterion.
  - No later phase's or environment's plan or apply runs, and no later S1 or S2 is taken. An entry never reached says `Execution: not applied — <reason>`; an environment never reached (prod, under staging-first) gets `no — not applied (<reason>)`. Both name the regression and `[H10]`.
  - The final message says what was applied and what was not. It makes no rollback offer (SKILL.md Step 5b, Final message).

**A staging regression blocks prod.** Prod starts only after staging's verification passes (`lanes.md` › Staging-first), or after an override at `[H10]`.

**An overridden signal is not raised again** in the same environment. A later S2 there (the observation window's end) raises no `[H10]` for it, unless it worsens past the threshold again, measured from the overridden after value (for example, an error rate above 1.5× the overridden one). Any other signal that regresses is a new `[H10]`. Each environment is judged against its own before values.

**An override is not evidence.** Prod's pre-flight still gets staging's before and after values, the regressed ones included, as staging evidence (`lanes.md` › Staging-first), cited `live: <cmd> (staging, <time>)`, with the override reason beside them, tagged `operator`.

## L2 from evidence

The snapshot and the other batch reads answer pre-flight's L2 questions. The operator types no L2 answer that a read can give, and inline pre-flight then asks nothing.

| Question | Source | Tag |
|---|---|---|
| Q1 active incident | `Q1(alarms)`: alarms or alerts firing on the snapshot set at S0 / S1. `Q1(declared)`: the incident command (Operator profile), otherwise the operator line | `live:` · `live:` or `operator (no objection at [<stop>], <time>)` |
| Q2 deploy freeze | A freeze calendar read in Step 1 (Operator profile › Freeze source), otherwise the operator line | `code:` or `operator (no objection at [<stop>], <time>)` |
| Q3 peak traffic | Request rate at S0 against the same hour last week; `yes` above 1.5× (assessor L3, Timing context). PR path where CI, GitOps or PR automation applies at merge: `unsure (apply at merge; peak hours HH–HH, live)`, the busiest hours of the last 7 days, shown as `peak hours: HH–HH` | `live:` |
| Q4 / Q5 experience | Operator profile; asked only when missing | `operator (profile, <date>)`, or `operator` when asked this run |
| Q6 cost | Unchanged (L1 from the plan) | — |
| Q7 other context | The reply to the operator line, or `none` | `operator` |
| Q8 app source | Located first (below); asked only when not found | `app:` or `operator` |
| `iac-change.4` applied recently | The assessor's automation-lag reads in the batch: CI history, S3 state `head-object` `LastModified`, `helm history`, ECS deployment `createdAt` | `live:` |
| `iac-change.1–3` | Unchanged: `Plan hash:`, `Delivery model:`, `Target:` | — |

**When a read cannot answer** (a declined or failed read, a member type with no request-rate metric, Kubernetes with no metrics backend):
- The answer is `unsure`, tagged `UNVERIFIED — <why>`. No typed question is asked. Pre-flight scores `unsure` as it does today (⚪ or Yellow).
- Q3 uses the request rate of the nearest member that has one: the load balancer, or the service in front of an RDS instance. With none, Q3 is `unsure`.
- `Q1(alarms)` unreadable: the operator line then covers incidents in general, not only declared ones.

**Q8: locate before asking.** Only when Step 1 predicts an app-facing change, so that Q8 would apply (`skills/pre-flight/SKILL.md` › Layer 2). Otherwise nothing is searched, and there is no `App source:` line and no Q8.
1. Look in the target repo first.
2. Then look at local checkouts beside it whose directory name or `origin` remote matches the service or the deployed image: `ls` of the parent directory, then `git -C <dir> remote get-url origin`. This search is a read in the batch, shown like any other. It is new scope: pre-flight's local mode covers only a checkout the operator names (`skills/pre-flight/examples/app-source.md`).
3. Check the checkout's version (`git -C <dir> rev-parse HEAD`, or its tag) against the deployed image tag or SHA (`live:`). A wrong match is caught here. Never fetch, pull, check out or stash in that checkout.

- **Found, version matches:** use it, shown as one line in the block below.
- **Found, version unknown or different:** one line inside the existing stop: `App source: <path> @ <sha>; deployed <tag> — correct?`.
- **Not found:** ask Q8 as today, inside the existing stop.
- Pass `Q8=<path> @ <deployed ref>`, so pre-flight reads the source at the deployed ref.

**The operator line.** One line, inside the stop that carries L2 (`[A]` / `[F2]`) and inside each later re-ask stop (`lanes.md` › Timing re-ask):

`Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.`

- An answer to the stop that says nothing about it is no reply. Record only the parts no source answered, as `Q1(declared)=no, Q2=no — operator (no objection at [<stop>], <time>)`, and `Q7=none`. An answer from a freeze calendar (`code:`) or the incident command (`live:`) keeps its own tag.
- A reply is recorded as given, tagged `operator`: `Q7=<text>`, and `Q1(declared)=yes` or `Q2=yes` when it names an incident or a freeze. Pre-flight handles those as today.
- A `Q1=yes` that comes only from `Q1(alarms)` gets no Incident Context follow-up: category 5 stays Red, and `[H5]` carries the operator's reason (pre-flight's inline rule).
- Drop the line only when both a freeze source and an incident source were read (Operator profile).

**Light lane, step by step.**
1. At `[A]`, before any read: the operator line, unless both a freeze source (a Step 1 repo read) and an incident command (from the profile) exist, both known before `[A]`; any app-source candidate found so far; Q4 / Q5, only if the profile lacks them.
2. After `[A]`, the batch runs: S0, the app-source search, the automation-lag read, the incident command. Assemble the derived answers into the caller block, then run pre-flight.
3. At `[B]`, the `**Checked for you:**` block sits next to the verdict.
   - A correction at `[B]` that changes an answer: re-run pre-flight and show a new `[B]`. This is the Timing re-ask rule: only a changed answer adds a stop.
   - An incident command whose result was not readable: the operator line also appears at `[B]`.

**Full lane:** S0 ran after `[F1]`, so the `**Checked for you:**` block, any `App source:` line and the operator line are in `[F2]`. Dev lane: no pre-flight, so no L2 answers, block or operator line. The block lists what the skill read and derived, one line each with its tag and time, so the operator can correct any of it. For example:

```
**Checked for you:** (correct anything that's wrong)
- Health: orders-api + 3 dependents — 0 alarms firing, 5xx 0.1% (same hour last week 0.1%) · live 14:02
- Peak: no — 120 rps, same hour last week 135 rps · live 14:02
- Last apply: 3 days ago, CI run #4567 succeeded · live 14:02
- App source: ../orders-api @ v1.4.2 = deployed image tag · app
- Experience: operator (profile, 2026-11-10)
Snapshot coverage: code + catalog; not covered: callers outside this repo
Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
```

**Bad news adds no stop of its own** (an alarm firing on a member, peak traffic, a recent failed apply). It goes to pre-flight in the caller block and shows in the verdict at the execution stop: a YELLOW with its findings, as today; a RED adds `[H5]`, as today; an active incident plus a freeze is pre-flight's existing hard block.

**Caller block.** The `L2 answers:` field (SKILL.md Step 4b) takes this form, each answer with its source tag:

`L2 answers: Q1(alarms)=… Q1(declared)=… Q2=… Q3=… Q4=… Q5=… Q7=… [Q8=…] [<assessor>.<n>=…]`
- For example, `Q1(alarms)=no (live: describe-alarms --state-value ALARM, 14:02: 0 firing on the snapshot set)` and `Q1(declared)=no (operator (no objection at [F2], 14:05))`.
- Tags: `live:`, `code:`, `app:`, `operator`, `operator (no objection at [<stop>], <time>)`, `operator (profile, <date>)`, `UNVERIFIED — <why>`.
- A later phase or environment passes its S1 answers (`Q1(alarms)`, Q3) and that stop's operator-line answers.

## Operator profile

**Path.** `$CULIOPS_HOME/operator.md` when `CULIOPS_HOME` is set and not empty, otherwise `~/.culiops/operator.md`. Never in the repo. The directory is `chmod 700` and the file `600`, as SKILL.md Constraint 13 does for `CULIOPS_HOME`. The first stop that saves to it says so: `I'll remember these in <path>`.

**Contents.** Q5 per IaC tool; Q4 per `<workspace>/<service>` (`<workspace>` as in Constraint 13); the date of each answer; optionally, an `incident check:` read-only command, with what "no incident" looks like. Nothing else: no secret, token or account data.

**Rules.**
- Missing → ask Q4 / Q5 inside the existing stop (`[A]` / `[F2]`) and save the answers. This run's answers are tagged `operator`.
- A stored `first time` is asked again on the next run: it is stale after one change.
- Other answers are reused and shown in the `**Checked for you:**` block as `operator (profile, <date>)`, so the operator can correct them. Save a correction.
- Profile unreadable or unwritable → ask every time, as today, and say why.

**Incident source.**
- Never guess an incident CLI. Save a command only when the operator offers it, for example by answering the operator line with "check `pd incident list --statuses triggered,acknowledged`". The operator also says what "no incident" looks like, for example an empty list.
- Once saved, it joins the read batch, shown like any other read. Its result answers `Q1(declared)`, tagged `live:`.
- It answers "none" only when the command exits 0 and its output matches the stated "none" shape. Any other result keeps the operator line.

**Freeze source.** A repo file whose name or heading says it is a change-freeze or change-window calendar, and which holds dates (`code:`). It answers Q2 only when the apply time is clearly inside or outside a listed window. Anything ambiguous keeps the operator line.

## Record

**Execution record** (SKILL.md Step 5b):
- A `## Health Snapshot` section, after `## Execution Log`:
  - the coverage line;
  - the members, each with its source, labelled `n/a — no health signals of its own`, `not snapshotted — over cap` or `no metrics backend — point-in-time only` where that applies;
  - per environment, the S0, S1 and S2 tables: member, signal, before, after, verdict, command, time. A reused S1 says so, with its age. No S2 yet (PR open, apply pending): S0 and S1 only, and no after value is claimed.
- Each phase entry, per environment:
  - `- Snapshot: before <time> · after <time> · <n ok / n regressed / n no data>`. `improved` counts as ok; every `no data` form and `after: too early` count as no data;
  - `- Verification:` carries `fail (snapshot)` when a signal regressed;
  - `- Snapshot override: <reason> — operator, <time>`, after an override at `[H10]`.
- `**Applied:**` `yes — verified` also requires no `regressed` member in that environment. List the `no data` members beside it. An environment with a `regressed` member is `yes — not verified`, overridden or not (an override keeps its `- Snapshot override:` line); so is one whose S2 timed out with signals still `after: too early`.
- `Outcome:` follows the existing rules: `completed` when every planned apply ran, an overridden regression included; `partially completed` when `[H10]` ended the run.

**Other records.** Staging's health before and after the apply, which prod's pre-flight gets (`lanes.md` › Staging-first), is staging's S1 and S2. The pre-flight record's `## Context Provided (L2)` shows each answer's tag (`live` / `code` / `operator` / `profile`); pre-flight writes it.
