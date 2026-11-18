(Would be written to `.culiops/pre-flight/notifyapi-scale-replicas-20260424-1458.md`; left uncommitted. The earlier record `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` was found, matched on plan hash, target and age, and was NOT reused: see the execution record.)

**Pre-flight assessment for:** `notifyapi` / `prod`
**Action:** Increase replica count from 2 to 4 (`values-prod.yaml:4`, `Deployment/notifyapi` update in place)
**Date:** `2026-04-24 14:58` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `values-prod.yaml`)
**Target:** `context prod-cluster / namespace notifyapi-prod / chart . with values.yaml + values-prod.yaml`
**Plan hash:** `sha256:9f2c4e…` (SHA-256 of the exact `helm diff upgrade` text assessed)
**Plan source:** `helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml`
**Delivery model:** `a CI job runs helm upgrade on merge` (operator-stated at `[F2]` 14:38; UNVERIFIED in the repo: no CI config; `live: gh run list 14:29` shows a `helm-upgrade` workflow)
**Invoked by:** `iac-change-execution`
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human, from the caller block) + L3 (live, the caller's reads and the target check)`
**App source:** `not needed — only not-app-facing attributes changed`

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One object (`Deployment/notifyapi`), one namespace. A capacity increase. Disruption none: scaling adds pods and does not roll the pod template; no HPA, no PDB | `plan:` helm diff (one hunk, `replicas`); `docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment (read 2026-04-24)`; `live: S0 (caller, 14:27)`; `live: kubectl get pdb (caller, 14:21)` | — |
| 2 | Reversibility | 🟢 | One in-place attribute; re-applying `replicaCount: 2` removes the added pods; `helm rollback` target revision 9 exists. Not on the one-way list | `plan:` (`replicas` only); `docs:` same page; `live: helm history (caller, 14:28)` | — |
| 3 | Change velocity | 🟢 | No commit to the chart paths in 7 days; last apply 22 days ago; no uncommitted prior change; no open PR | `git: git log --since=7.days (14:49)` none; `live: helm history (caller, 14:28)`; `live: gh pr list (caller, 14:08)` | — |
| 4 | Dependency impact | 🟢 | All changed attributes are not-app-facing and the chart has no output / export | `plan:` (`replicas` only); `code: templates/` (no outputs); `catalog:` lists no consumers (a lead only) | — |
| 5 | Timing context | ⚪ | `Q1(alarms)` unreadable, `Q3=unsure` (no metrics backend); apply happens at merge, at an unfixed time; `Q1(declared)=no` and `Q2=no` are `operator` answers only | `operator (no objection at [F2], 14:38)`; `UNVERIFIED — no metrics backend` | Merge in staffed hours with on-call (`#notifications-oncall`, PagerDuty, `catalog:`) on hand; check the traffic dashboard first |
| 6 | Operator familiarity | 🟢 | Changed this service many times; experienced with Helm | `operator (profile, 2026-04-10)` | — |
| 7 | Observability readiness | 🟡 | `NotifyApiErrorBudgetBurn`, `NotifyApiQueueBacklog`, `NotifyApiPodNotReady` exist as a `PrometheusRule` in `monitoring`; the objects exist live, but "loaded and enabled" is not confirmed; rules not in this repo | `live: kubectl get prometheusrule (caller, 14:25)`; `live: kubectl get servicemonitor (caller, 14:26)`; `UNVERIFIED — rules loaded` | After the apply confirm `NotifyApiPodNotReady` is loaded and healthy in Prometheus (`/api/v1/rules`) |
| 8 | Cost impact | 🟡 | +2 replicas at 250m CPU / 256Mi each (+500m / +512Mi requested): a size increase with predictable pod count; no price looked up; node room vs requests unknown | `plan:` (`replicas` 2 → 4); `code: values-prod.yaml:10-12`; `live: kubectl top nodes (caller, 14:24)` (usage 31–44% CPU, 38–52% memory) | Check node allocatable vs requests (or the Cluster Autoscaler's node count) before merging; price the added node capacity if a node is added |
| 9 | Security posture | 🟢 | No IAM, RBAC, network, secret or image change | `plan:` (`replicas` only) | — |
| 10 | Resource health | ⚪ | Readiness, restarts and saturation nominal (2 of 2 ready, 0 restarts, no Warning event, pods under their requests, nodes under 52%); error rate, latency and firing alerts not read (no metrics backend), and Green needs them | `live: S0 (caller, 14:27)`; `live: S1 (caller, 14:48)`; `live: kubectl top (caller, 14:23, 14:24)`; `UNVERIFIED — error rate, latency, alerts` | Check error rate and latency on the dashboard before merging; supply a Prometheus address for a read |
| 11 | Application compatibility | 🟢 | Only a not-app-facing attribute changed (`replicas`) | `plan: only not-app-facing attributes changed (replicas)` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| prod replicas = 2, 2 of 2 ready | `values-prod.yaml:4`; `templates/deployment.yaml:10` | `live: kubectl get deploy (caller, 14:15)` → 2 / 2; `live: helm get values (caller, 14:16)` → `replicaCount: 2` | ✓ |
| release `notifyapi` chart 1.2.0 | `Chart.yaml:5` | `live: helm list (caller, 14:17)` → revision 9 `deployed` | ✓ |
| no HPA, no PDB | none in the chart | `live: S0 (caller, 14:27)`; `live: pdb (caller, 14:21)` | ✓ |
| no drift on the unchanged chart | — | `live: helm diff upgrade (caller, 14:18)` → no differences | ✓ |
| alert rules exist | none in the chart | `live: kubectl get prometheusrule (caller, 14:25)` | live only |
| delivery model | none in the repo | operator-stated | UNVERIFIED |

No drift found.

## Verification

- Citations checked: 9 (fixed: none)
- Verdict working: Red = none; Yellow + ⚪ = 4 (5 ⚪, 7 🟡, 8 🟡, 10 ⚪) ≥ 3, so the escalation applies; hard blocks checked: category 2 (irreversible: no), 5 (incident + freeze: `Q1(declared)=no`), 9 (public exposure, encryption, secrets: none), 10 (error budget exhausted: not established) → RED — SOFT BLOCK
- Fresh eyes: not required (verdict RED — soft block)
- Not verified: delivery model, `Q1(declared)`, `Q2`, `Q7` (`operator-stated`); `Q4` / `Q5` (operator profile, 2026-04-10); `Q1(alarms)`, `Q3`, error rate and latency (no metrics backend); that Prometheus loaded the three alert rules; the API server behind `prod-cluster` (the `kubectl config view --minify` read had no output)

## Hard Blocks

None.

## Acknowledged Risks

Acknowledged by the operator at `[H5]`, 14:58, all four findings (5 timing, 7 observability, 8 cost, 10 resource health): "Acknowledged, each finding as shown. I'll merge in staffed hours with on-call on hand and follow the mitigations listed."

## Mitigations Committed

- Merge in staffed hours with on-call on hand (category 5)
- Check traffic, error rate and latency on the dashboard before merging (categories 5, 10)
- Confirm `NotifyApiPodNotReady` is loaded in Prometheus after the apply (category 7)
- Check node allocatable vs requests before merging (category 8)

(The operator's reply says "follow the mitigations listed": committed as listed in the report.)

## Context Provided (L2)

- `Q1(alarms)=unsure` — `UNVERIFIED — no metrics backend; firing alerts not readable (S1 14:48)`
- `Q1(declared)=no` — `operator (no objection at [F2], 14:38)`
- `Q2=no` — `operator (no objection at [F2], 14:38)`; no freeze calendar in the repo (`code:` grep 14:09, no hit)
- `Q3=unsure` — `UNVERIFIED — no metrics backend, no request-rate source; apply at merge`
- `Q4=many times` — `operator (profile, 2026-04-10)`
- `Q5=experienced` — `operator (profile, 2026-04-10)`
- `Q6` — not asked; cost scored from the plan
- `Q7=none` — `operator (no objection at [F2], 14:38)`
- `iac-change.4=recent` — `live: helm history 14:28 (revision 9, 2026-04-02, 22 days); live: gh run list 14:29`
- Assessor items 1–3 — answered by `Plan hash:` + plan command, `Delivery model:` and `Target:`

## L1 Analysis Detail

Scanned: `Chart.yaml`, `values.yaml`, `values-prod.yaml`, `templates/` (the Deployment renders `.Values.replicaCount`; no `strategy:`, HPA or PDB), the helm diff (one `Deployment` hunk, `replicas: 2` → `4`). Catalog used: `.culiops/service-discovery/notifyapi-prod.md` (lead). Git: no commit to the chart paths in 7 days (`git log --since=7.days`, 14:49).

## L3 Queries Run

Caller's results, cited as `live: <cmd> (caller, <time>)`: `kubectl config current-context` (14:45), `kubectl get deploy notifyapi …` (14:15), `helm get values` (14:16), `helm list` (14:17), `helm diff upgrade` before the code change (14:18), Argo CD / Flux checks (14:19, 14:20), `kubectl get pdb` (14:21), `kubectl rollout status` (14:22), `kubectl top pods` (14:23), `kubectl top nodes` (14:24), `kubectl get prometheusrule` (14:25), `kubectl get servicemonitor` (14:26), S0 `kubectl get deploy,sts,pods,events,hpa` (14:27), `helm history` (14:28), `gh run list` (14:29), S1 (14:48).

Pre-flight's own target check (no stop): 1. `kubectl config current-context` (14:51) → `prod-cluster` (matches `Target:`). 2. `kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'` (14:52) → no canned output (read failed; not a mismatch). 3. `kubectl get namespace notifyapi-prod` (14:53) → `Active`.
