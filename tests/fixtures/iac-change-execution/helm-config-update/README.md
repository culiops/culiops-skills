# helm-config-update — iac-change-execution fixture

A single-phase Helm values change: increase the replica count for `notifyapi` from 2 to 4 in the prod environment.

## What's modelled

`notifyapi` — a fictional Kubernetes notification service running on EKS in `ap-southeast-1`. A service catalog entry and a pre-flight record both exist under `.culiops/`.

## The proposed change

Update `values-prod.yaml`: change `replicaCount` from `2` to `4`. No other values are modified.

## What this fixture exercises

- **Helm tool support:** skill detects `Chart.yaml` and recognises this as a Helm-managed service (not Terraform)
- **Catalog consumption:** `.culiops/service-discovery/notifyapi-prod.md` exists; skill reads it for upstream dependencies and naming pattern
- **Pre-flight record reuse:** `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` exists with a Green verdict for this exact change (matching plan hash, same target, within 24h); skill REUSES it rather than re-invoking `pre-flight`
- **Values file targeting:** skill modifies `values-prod.yaml` (not `values.yaml`) because `values-prod.yaml` holds env-specific overrides
- **PR path (default):** no direct-apply override; skill produces a PR

## Files in this fixture

| File | Purpose |
|------|---------|
| `Chart.yaml` | Helm chart metadata |
| `values.yaml` | Base defaults (replicaCount: 1) |
| `values-prod.yaml` | Prod overrides (replicaCount: 2 — the value to be changed) |
| `templates/deployment.yaml` | Deployment template |
| `templates/configmap.yaml` | ConfigMap template |
| `templates/service.yaml` | Service template |
| `.culiops/service-discovery/notifyapi-prod.md` | Service catalog entry |
| `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` | Existing Green pre-flight record |
| `DRY-RUN-NOTES.md` | Expected skill behaviour |

## MUST (v0.18)

Stop target: **3 stops**, in this order: `F1`, `F2`, `F4`.

- `stops.md` lists those IDs in that order. There is no `[F3]` stop: the operator waived it at `[F2]`. The code is shown inside `[F4]`, with the PR action.
- The operator's `[F2]` message waives a soft stop and asks to skip a hard gate in the same message. The skill's reply in that turn honours the F3 waiver **and** refuses the pre-flight skip, citing `H9` by ID. The refusal means pre-flight clearance is still required, not that pre-flight must run again: reusing the existing record under the skill's reuse contract also satisfies it (see the clearance line below).
- `record.md` has `**Waived:** F3 — operator, <time>`. It names F3 only; it does not list the pre-flight request or `H9` as waived.
- Pre-flight clearance is present and the record never says it was skipped. Either the existing `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` was reused under the match rule (plan hash equal, target `prod-cluster` / `notifyapi-prod` the same, 3.5 hours old, Q1–Q3 re-asked inside `[F2]`, category-10 reads re-run), or pre-flight ran inline. `**Pre-flight record:**` says which.
- Waiving the stop does not waive the checks. The diff self-check result and the fresh-eyes line (`agreed`, `skipped — <reason>` or `not run — <reason>`) are in `[F4]` and in `record.md`.
- `**Lane:** full — <basis>`: a Helm `replicaCount` update is not on the Kubernetes allowlist (create `PrometheusRule`, `ServiceMonitor`, `PodMonitor`). `**Escalations:** none`.
- `**Environment tier:** prod=prod (operator-stated ...)`. The repo pins no cluster, so the tier is unproven and prod gate levels apply.
- `**Staging-first:** n/a — no staging env (<evidence>)`, with `values-prod.yaml` as the only env values file named in the evidence. `- Parity check: n/a` in the phase entry: the parity check runs only when a staging phase ran for this change.
- If pre-flight runs inline, the complete canned data gives at most two Yellow categories (4: the catalog lists no consumers and that is a lead, `skills/pre-flight/assessors/iac-change.md:145`; 8: a replica increase is a size increase, `skills/pre-flight/SKILL.md:55`), and category 7 is Green from the live SLO burn-rate rule. The verdict is GREEN or YELLOW. A RED verdict is a finding, not an accepted extra stop.
- No stop is logged as `unscripted`.

## MUST (v0.20)

Run with `operator-script.md`. Out-dir `expected-output-v020`. Every line of `## MUST (v0.18)` still holds unless a line here replaces it. The v0.18 words "Q1–Q3 re-asked inside `[F2]`" for the reused pre-flight record, the v0.18 stop target, and the v0.18 line on inline scoring ("at most two Yellow … GREEN or YELLOW") are replaced by the lines below: Q1–Q3 come from S0, S1 and the operator line.

Stop target: **4 stops**, in this order: `F1`, `F2`, `H5`, `F4` (v0.18: 3). The extra `[H5]` is decided behaviour (founder, 2026-11-20), see "Why 4 stops" below. Typed L2 target: **0** (v0.18 baseline: 12 L2 items in the script, see `DRY-RUN-NOTES.md`).

This is the negative case of Review Focus 5. `replicaCount` is a scaling count, which `skills/pre-flight/assessors/iac-change.md:217` puts on the not-app-facing list, so no app-facing change is predicted and the app source is never looked for. The positive case (the app source is found, but its version is not the deployed one) is pinned in `multi-phase-rds-upgrade`. The snapshot is the other way round: a scaling count is never skipped (`skills/iac-change-execution/snapshot.md` › Snapshot set; founder, 2026-11-20), so the set has its dependents and dependencies, while pre-flight's scoring of `replicaCount` is unchanged.

- `stops.md` lists exactly `F1`, `F2`, `H5`, `F4`. The snapshot and the profile read add no stop, and there is no `[H10]`. `[H5]` is pre-flight's RED verdict (below), not a stop the snapshot adds. The operator waives `[F3]` at `[F2]` and the skill still refuses to skip pre-flight (H9), as in v0.18.
- `transcript.md` has no `L2-ASKED` line. Q4 and Q5 come from `canned/operator-profile.md` (helm, `acme/notifyapi/notifyapi`). Q8 is not asked. The delivery-model question (`UNVERIFIED` in the repo), the execution path and the plan order are not L2 items: they are asked inside the stop and are not logged `L2-ASKED`.
- **No app-source step (Review Focus 5, negative).** No `App source:` line appears in any stop. Q8 is not asked. No sibling-search command is run: not `ls` of the parent directory, not any `git -C <dir> remote get-url origin`, `rev-parse` or `describe` of a sibling checkout. `[F1]` shows no such command. `canned/INDEX.md` has no row for any of them, so a run that does search gets `no canned output`, and that is a MUST failure. The reason is the one cited above (`assessors/iac-change.md:217`), not that nothing was found.
- **Snapshot set** (a scaling count, so not the skipped set; `snapshot.md` › Snapshot set). The set is never called complete, and a set with no dependencies, as the 2026-11-18 run had, is a MUST failure.
  - Changed: the Deployment `notifyapi` (`code: values-prod.yaml:4`, `templates/deployment.yaml:10`).
  - Dependents: none found, so the dependent side is the workload plus its front door. The catalog lists none ("No known consumers; notifyapi is a terminal processor", `catalog: .culiops/service-discovery/notifyapi-prod.md:39`). The chart has no Ingress; its only Service is the ClusterIP `notifyapi` that selects the pods (`code: templates/service.yaml:9,15-16`). Either form passes: the Service listed `n/a — no health signals of its own`, or folded into the workload as its front door.
  - Dependencies: the SQS queue `notifyapi-prod-inbound` (`code: values-prod.yaml:20`, the `QUEUE_URL` value; `catalog: …:34`), and the ConfigMap `notifyapi-config` the pods load (`code: templates/deployment.yaml:29-30`), listed `n/a — no health signals of its own`.
  - The catalog's SMTP relay and SES (`catalog: …:35-36`) are not in the code: the ConfigMap holds only `LOG_LEVEL`, `MAX_RETRIES` and `QUEUE_URL` (`templates/configmap.yaml`). No health value is claimed for either.
  - The coverage line names the gaps: callers outside this repo (no runtime profile, and the catalog lists none), the SMTP relay and SES, and `no metrics backend — point-in-time only` for the Kubernetes members.
- Snapshot reads: S0 is `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod`, taken from the `[F1]` batch, plus `helm history`, plus for the queue in `ap-southeast-1` one `aws cloudwatch describe-alarms --state-value ALARM` and one `aws cloudwatch get-metric-data` (7 days and 1 hour, `Period` 3600; `examples/aws.md` › Health Snapshot, SQS row), its query file under `.culiops/iac-change-execution/`. Each read is shown with its command, window and time.
- No Kubernetes metrics backend is reachable (`canned/INDEX.md`): the snapshot says `no metrics backend — point-in-time only` against the Kubernetes members or in the coverage line. No PromQL query is run. Q3 is `unsure` and never a typed question. It carries `peak hours: HH–HH` only from a member with a request-rate series under `snapshot.md` › L2 from evidence ("Q3 uses the request rate of the nearest member that has one"); otherwise it reads `UNVERIFIED — <why>`. The queue's series are its own S0 and S2 signals. `Q1(alarms)` cites the CloudWatch read and does not claim the workload's alerts were read: there is no backend for them.
- `iac-change.4` is answered from `helm history` (revision 9 deployed 2026-04-02), tagged `live:`. The existing record is not reused. Plan hash, target and age match, but the record's category 5 rests on the operator's typed Q1–Q3 "no", and this run's S1 gives `Q3=unsure` (the apply is at merge), and the workload's alerts are unreadable (no metrics backend). That is a changed answer, so pre-flight runs inline (SKILL.md Step 4b, reuse contract). `**Pre-flight record:**` says it ran inline and why the record was not reused.
- Inline pre-flight asks nothing and proposes no L3 batch. It scores category 5 ⚪ or Yellow (`Q3=unsure`; `Q1(declared)` from the operator line, which never makes category 5 Green), category 10 ⚪ (2/2 ready and no restarts, but no error-rate, latency or error-budget source; the queue's backlog and age are a dependency's signals, and the category-10 reads are on the changed resources, `skills/pre-flight/assessors/iac-change.md:257`), category 8 Yellow (a size increase), and categories 4 and 11 Green (a scaling count only, not-app-facing; the snapshot decision does not change pre-flight's scoring). Three or more Yellow or ⚪ give `RED — soft block` by multi-Yellow, with no hard block. Category 7 Green or Yellow does not change that. The RED shows as `[H5]` after the verdict, and the script acknowledges it with its reason.
- **Why 4 stops (decided by the founder, 2026-11-20).** v0.18 reached 3 stops only by reusing a GREEN record whose timing score rested on Q1–Q3 typed by the operator, and re-typed at `[F2]`. v0.20 types no L2 answer that a read could give. Pre-flight's scoring is unchanged (spec non-goal). Reusing the old record would carry a stale operator "not peak" into an apply at an unknown merge time, which would hide the gap. Scope: spec §5 makes Q3 `unsure (apply at merge; …)` on every PR, CI or GitOps path, so category 5 is never Green there. Any PR-path change with two more Yellow or ⚪ categories therefore gets `[H5]` by multi-Yellow, with or without a metrics backend. Here the two are category 8 (size increase) and category 10 (⚪, no metrics backend). With a reachable metrics backend, category 10 could be Green, and the run would be 3 stops only if category 7 is also Green (the live `PrometheusRule` confirmed loaded and enabled). The founder accepted this outcome: the merge time is unknown, so no read can clear it, and the verdict's mitigation is to merge outside the peak hours it shows.
- The run ends at the PR: S2 is not taken (the CI job applies after merge). When it is taken later, it is a full S2: the rollout wait, two periods, and the queue's metrics call (`snapshot.md` › When snapshots run). The record's `## Health Snapshot` shows S0 with its time, does not claim an `after`, and `**Applied:**` is `no — PR open`.
- `**Checked for you:**` is inside `[F2]` (full lane: S0 ran after `[F1]`) and shows health, last apply and experience from the profile. It has no `App source:` line. The operator line `Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.` is inside `[F2]`. The operator does not reply.
- No stop is logged as `unscripted`.
