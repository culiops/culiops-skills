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

Run with `operator-script.md`. Out-dir `expected-output-v020`. Every line of `## MUST (v0.18)` still holds unless a line here replaces it. The v0.18 words "Q1–Q3 re-asked inside `[F2]`" for the reused pre-flight record are replaced by the lines below: Q1–Q3 come from S0 and the operator line.

Stop target: **3 stops**, in this order: `F1`, `F2`, `F4` (v0.18: 3). Typed L2 target: **0** (v0.18 baseline: 12 L2 items in the script, see `DRY-RUN-NOTES.md`).

This is the app-source-version case (Review Focus 5): the app source is found, but its version is not the deployed one.

- `stops.md` lists exactly `F1`, `F2`, `F4`. The app-source search, the snapshot and the profile read add no stop, and there is no `[H10]`. The operator waives `[F3]` at `[F2]` and the skill still refuses to skip pre-flight (H9), as in v0.18.
- `transcript.md` has no `L2-ASKED` line. Q4 and Q5 come from `canned/operator-profile.md` (helm, `acme/notifyapi/notifyapi`). Q8 is not asked. The delivery-model question (`UNVERIFIED` in the repo), the execution path and the plan order are not L2 items: they are asked inside the stop and are not logged `L2-ASKED`.
- The sibling search is in the `[F1]` batch, each command shown: `ls` of the parent directory, `git -C ../notifyapi-app remote get-url origin` and `git -C ../notifyapi-app rev-parse HEAD`. It finds `../notifyapi-app`, whose origin matches the service.
- The checkout's version is compared with the deployed image tag: `HEAD` is `9be7a31…`, 4 commits past `v3.2.0`, while the deployed image tag is `v3.1.0` (`live:`). `[F2]` carries exactly one line `App source: ../notifyapi-app @ 9be7a31c0d52f48e6a1b7c3d2e5f80194a6b7c8d; deployed v3.1.0 — correct?` (the SHA may be shortened). It is a line inside the existing stop, never a stop of its own. The operator does not reply to it (script). The checkout is not presented as the deployed version: no `app:` citation claims the deployed version.
- Kubernetes reads: S0 is `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod`, taken from the `[F1]` batch, plus `helm history`. Each read is shown with its command, window and time.
- No metrics backend is reachable (`canned/INDEX.md`): the snapshot says `no metrics backend — point-in-time only`, in the coverage line or against the members. No PromQL query is run. Q3 has no request-rate source: it is `unsure` with `UNVERIFIED — <why>` (the why is that no metrics backend is reachable), never a typed question.
- `iac-change.4` is answered from `helm history` (revision 9 deployed 2026-04-02), tagged `live:`. The pre-flight reuse contract still holds (plan hash equal, same target, 3.5 hours old, category-10 reads re-run), and the record's `**Pre-flight record:**` says which.
- The run ends at the PR: S2 is not taken (the CI job applies after merge). The record's `## Health Snapshot` shows S0 with its time, does not claim an `after`, and `**Applied:**` is `no — PR open`.
- `**Checked for you:**` is inside `[F2]` (full lane: S0 ran after `[F1]`) and shows health, last apply, experience from the profile, and the `App source:` line. The operator line `Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.` is inside `[F2]`. The operator does not reply.
- No stop is logged as `unscripted`.
