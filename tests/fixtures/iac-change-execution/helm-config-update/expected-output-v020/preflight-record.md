<!-- Would be written to .culiops/pre-flight/notifyapi-scale-replicas-20260424-1504.md by the inline pre-flight run. Written once, after [H5] (15:04). Not committed. -->

**Pre-flight assessment for:** `notifyapi` / `prod`
**Action:** Increase replica count from 2 to 4 (`replicaCount` in `values-prod.yaml`)
**Date:** `2026-04-24 15:04` (+07:00)
**Commit:** `a1b2c3d` (+ uncommitted changes: `values-prod.yaml`)
**Target:** context `prod-cluster` / namespace `notifyapi-prod` | account `123456789012` / `ap-southeast-1` | values `values.yaml` + `values-prod.yaml`
**Plan hash:** `sha256:9f2c4e…` (SHA-256 of the exact `helm diff upgrade` text assessed)
**Plan source:** `helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml`
**Delivery model:** CI job runs `helm upgrade` on merge (`UNVERIFIED` in the repo — `operator-stated` at [F2], 14:36)
**Invoked by:** iac-change-execution
**Mode:** inline (caller: iac-change-execution)
**Assessor used:** `iac-change`
**Layers evaluated:** `L1 (static) + L2 (human) + L3 (live, the caller's reads and the target check)`
**App source:** not needed — only not-app-facing attributes changed (`replicas`)
**Output root:** `.culiops/` (repo root; `CULIOPS_HOME` unset)

## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🟢 | One object (`Deployment/notifyapi`), one namespace, one region. Scale up, no capacity reduction. Disruption `none`: a replicas change adds pods and does not roll the pod template. | `plan:` helm diff, 1 object, `replicas` only; `docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment (read 2026-04-24)`; `live: kubectl get deploy notifyapi … jsonpath (caller, 14:16)` RollingUpdate 25%/25%; `live: kubectl get pdb (caller, 14:20)` none; `live: kubectl get hpa (caller, 14:19)` none | — |
| 2 | Reversibility | 🟢 | In-place `replicas` change. Scaling back to 2 removes the two added pods. Helm keeps revisions 7–9, so `helm rollback` has a target. No one-way attribute. Rollback untested. | `plan:` `replicas` only; `docs:` scaling adds or removes pods (same page); `live: helm history notifyapi --max 5 (caller, 14:25)` revisions 7, 8, 9; `assessor:` Helm rollback row (risk-raising use only; not relied on for the Green) | — |
| 3 | Change velocity | 🟢 | 0 commits to the chart paths on `main` in 7 days; this change's own edit is uncommitted and excluded; no open PR or branch for it; last apply 22 days ago (under 90). | `git: git log --since=7.days --oneline main -- Chart.yaml values.yaml values-prod.yaml templates` (14:56) empty; `live: gh pr list --state open --search 'replica'` (caller, 14:07) none; `live: helm history (caller, 14:25)` rev 9 on 2026-04-02; `live: gh run list (caller, 14:26)` success 2026-04-02 | — |
| 4 | Dependency impact | 🟢 | Every changed resource is not-app-facing (a scaling count) and no output or export changes, so nothing can depend on it. The catalog lists no downstream consumers (a lead); the live Ingress read failed, and callers that dial the Service by DNS name are not visible in the cluster API. | `plan:` only `replicas` changes; `assessor:` Application compatibility › not-app-facing list ("Scaling counts alone"); `catalog: .culiops/service-discovery/notifyapi-prod.md` (Dependency graph, downstream: none known) | — |
| 5 | Timing context | 🟡 | The apply happens at merge (operator-stated), at a time not yet known. `Q3=unsure (apply at merge)`: weekday peak hours are 09:00–12:00 +07:00 (02:00–05:00 UTC). `Q1(alarms)=unsure` (the workload's alerts were not read; 0 firing on the queue), so `Q1` rests on `Q1(declared)=no`. `Q2=no`. Nobody is confirmed on hand at merge time; the catalog names #notifications-oncall (PagerDuty). | `live: aws cloudwatch get-metric-data (caller, 14:28 and 14:51)` peak hours `peak hours: 09:00–12:00 +07:00`; `live: describe-alarms (caller, 14:27 and 14:50)` 0 firing; `operator (no objection at [F2], 14:36)` for `Q1(declared)`, `Q2`; `catalog: Overview › On-call` | Operator action: merge outside 09:00–12:00 +07:00 on a weekday, with someone from #notifications-oncall on hand (committed at `[H5]`) |
| 6 | Operator familiarity | 🟢 | Helm experienced; notifyapi changed many times. | `operator (profile, 2026-04-10)` | — |
| 7 | Observability readiness | ⚪ | No alert, SLO or dashboard for notifyapi in the chart (`templates/` holds a Deployment, a Service and a ConfigMap) or the catalog. Rules loaded in the cluster were not read: the only reads (Prometheus rules API, Alertmanager) need `$PROM_URL` / `$AM_URL`, and none is known. L3 unavailable for this category. | `code: templates/` (no `PrometheusRule`, no alert definition); `catalog:` none listed; `UNVERIFIED` live | Evidence that would resolve it: a Prometheus or Alertmanager address for a rules read, or a hand check that alerts covering notifyapi exist and are enabled (committed at `[H5]`) |
| 8 | Cost impact | 🟡 | Two more pods requesting 250m CPU and 256Mi memory each. Nodes show usage headroom (CPU 31–44%, memory 38–52%), but whether a node is added is not read and the cost is not priced (a pricing lookup returned nothing). | `code: values-prod.yaml:10-11`; `plan:` `replicas` 2 → 4; `live: kubectl top nodes (caller, 14:22)`; pricing: no result (`UNVERIFIED`) | Operator action: confirm the node pool places two more 250m / 256Mi pods without a scale-up, or price the added capacity for `ap-southeast-1` (committed at `[H5]`) |
| 9 | Security posture | 🟢 | No IAM, RBAC, network, secret or image change. | `plan:` `replicas` only | — |
| 10 | Resource health | ⚪ | Read: 2/2 ready, 0 restarts, rollout complete; pod CPU 47% / 42% and memory 67% / 65% of request (under 70%); nodes CPU ≤ 44%, memory ≤ 52%; 0 alarms on the queue; queue backlog max 10 and oldest message 6 s (last week 8 and 7 s). Not read: notifyapi's error rate and latency (no metrics backend), workload alerts, Warning events (read failed). "Within the service's own recent baseline" cannot be shown, so not Green. | `live: kubectl get deploy / pods / top pods / top nodes / rollout status (caller, 14:16–14:23)`; `live: describe-alarms (caller, 14:50)`; `live: get-metric-data (caller, 14:51)`; Warning events: no data | Evidence that would resolve it: S2 and the success criteria after the merge; error rate and latency by hand if a metrics backend exists (committed at `[H5]`) |
| 11 | Application compatibility | 🟢 | Only a not-app-facing attribute changes (`replicas`). | `plan: only not-app-facing attributes changed (replicas)` | — |

## Evidence

| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| notifyapi prod replicas | `code: values-prod.yaml:4` → 2 | `live: kubectl get deploy … (caller, 14:16)` 2; `live: helm get values (caller, 14:15)` `replicaCount: 2` | ✓ |
| Release equals chart | `plan:` helm diff after the code change: `replicas` 2 → 4 only | `live: helm diff upgrade … (caller, 14:14)` before the change: no differences | ✓ no drift |
| Requests | `code: values-prod.yaml:10-11` 250m / 256Mi | `live:` (caller, 14:16) 250m / 256Mi | ✓ |
| Rollout strategy | `code: none` (Kubernetes default) | `live:` RollingUpdate 25% / 25% | live only |
| HPA, PDB | `code: none` | `live:` none, none | ✓ |
| Delivery model | `code: values-prod.yaml:2` (a comment, data) | `live: gh run list (caller, 14:26)` one success run | `UNVERIFIED` — `operator-stated` |
| Downstream consumers | `catalog:` none known | `live:` Ingress read failed | `UNVERIFIED` |

No drift found.

## Verification

- Citations checked: 9 (every Green on categories 1, 2, 4, 9 and 11; each hard-block condition; the premise of each of the four mitigations). Fixed: none.
- Verdict working: Red = none; Yellow + ⚪ = 4 (🟡 5, 8; ⚪ 7, 10), 3 or more → multi-Yellow escalation → RED — soft block. Hard blocks checked: category 2 irreversible data change (no); category 5 active incident + freeze (no: `Q1(declared)=no`, `Q2=no`); category 9 public exposure, encryption removal, secrets (no); category 10 error budget exhausted (no SLO known; no signal shows exhaustion). None triggered.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: delivery model (`operator-stated`); `Q1(declared)`, `Q2`, `Q7` (operator, no objection at `[F2]`); `Q1(alarms)` for the workload (alerts not read); pricing; downstream consumers (catalog lead, Ingress read failed, DNS callers invisible); load on the upstream SMTP relay and AWS SES at up to twice the delivery concurrency (catalog leads, no read); API server of the context (read failed; the context and account match `Target:`).

## Hard Blocks

None.

## Acknowledged Risks

Acknowledged at `[H5]` (2026-04-24 15:04), each finding as shown, reason given by the operator word for word: "Acknowledged, each finding as shown. I'll merge in staffed hours with on-call on hand and follow the mitigations listed."
- 5 Timing context 🟡
- 7 Observability readiness ⚪
- 8 Cost impact 🟡
- 10 Resource health ⚪

## Mitigations Committed

- Merge outside 09:00–12:00 +07:00 on a weekday, with someone from #notifications-oncall on hand (category 5).
- Give a Prometheus or Alertmanager address for a rules read, or confirm by hand that alerts covering notifyapi exist and are enabled (category 7).
- Confirm the node pool places two more 250m / 256Mi pods without a scale-up, or price the added capacity for `ap-southeast-1` (category 8).
- After the merge, compare S2 and the success criteria; read error rate and latency by hand if a metrics backend exists (category 10).

## Context Provided (L2)

- `Q1(alarms)`: `unsure` — `UNVERIFIED — no metrics backend: notifyapi workload alerts not read`; `live: aws cloudwatch describe-alarms --state-value ALARM (caller, 14:50)`: 0 firing on the queue.
- `Q1(declared)`: `no` — `operator (no objection at [F2], 14:36)`.
- `Q2`: `no` — `operator (no objection at [F2], 14:36)`; no freeze calendar in the repo (`code:` none).
- `Q3`: `unsure (apply at merge; peak hours 02:00–05:00 UTC [09:00–12:00 +07:00] weekdays, live)` — `live: aws cloudwatch get-metric-data (caller, 14:28)`; now 2,910 vs 2,860 the same hour last week.
- `Q4`: `many times` — `operator (profile, 2026-04-10)`.
- `Q5`: `experienced` — `operator (profile, 2026-04-10)`.
- `Q6`: not asked; L1 scores cost from the plan (`code: values-prod.yaml:10-11`, `plan: replicas 2 → 4`).
- `Q7`: `none` — `operator (no objection at [F2], 14:36)`.
- `Q8`: not asked; no app-facing change.
- `iac-change.1`–`.3`: from `Plan hash:` with its plan command, `Delivery model:` and `Target:` (no `-target`, no `-refresh=false`, values files `values.yaml` + `values-prod.yaml`).
- `iac-change.4`: `recent` — `live: helm history (caller, 14:25)` rev 9 on 2026-04-02; `live: gh run list (caller, 14:26)` success 2026-04-02.

## L1 Analysis Detail

Scanned `Chart.yaml` (`notifyapi` 1.2.0, appVersion 3.1.0), `values.yaml`, `values-prod.yaml`, `templates/deployment.yaml`, `templates/configmap.yaml`, `templates/service.yaml`. Catalog used: `.culiops/service-discovery/notifyapi-prod.md` (generated by service-discovery; a lead). Earlier record `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md`: same plan hash (`sha256:9f2c4e…`), same target, 4 h 21 min old, **not reused**: its timing answers (`Q1`–`Q3`: no incident, no freeze, not peak hours; `operator`) are replaced by `Q1(alarms)=unsure` and `Q3=unsure (apply at merge)` from S1 (14:46–14:51), which count as changed. Git: 0 commits to the chart paths on `main` in 7 days. Plan: one object changed, `Deployment/notifyapi` `replicas: 2 → 4`; no output or export changes. Attribute class: `replicas` is not-app-facing (scaling count).

## L3 Queries Run

Caller's results, cited as `live: <cmd> (caller, <time>)`:
1. `helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml` (before the change, 14:14): no differences.
2. `helm get values notifyapi -n notifyapi-prod` (14:15): `replicaCount: 2`; key names only.
3. `kubectl get deploy notifyapi … -o jsonpath=…` (14:16): 2 desired, 2 ready, RollingUpdate 25% / 25%, image tag `v3.1.0`, requests 250m / 256Mi.
4. `kubectl get pods … -l app.kubernetes.io/name=notifyapi` (14:17, S1 14:47): 2 `Running`, 0 restarts.
5. `kubectl get events … type=Warning` (14:18, S1 14:48): no canned output, no data.
6. `kubectl get hpa` (14:19, S1 14:49): none.
7. `kubectl get pdb` (14:20): none.
8. `kubectl top pods` (14:21): 118m / 171Mi and 104m / 166Mi.
9. `kubectl top nodes` (14:22): CPU 31–44%, memory 38–52%.
10. `kubectl rollout status deploy/notifyapi --timeout=5s` (14:23): successfully rolled out.
11. `kubectl get ingress -A -o json | jq …` (14:24): no canned output, no data.
12. `helm history notifyapi --max 5` (14:25): rev 9 `deployed` 2026-04-02 09:41.
13. `gh run list --limit 5 --json …` (14:26): `success`, 2026-04-02.
14. `aws cloudwatch describe-alarms --state-value ALARM …` (14:27, S1 14:50): 0 firing.
15. `aws cloudwatch get-metric-data …` (14:28, S1 14:51): queue sent 2,910 vs 2,860; visible max 10 vs 8; oldest age 6 s vs 7 s; peak hours 09:00–12:00 +07:00 weekdays.

Pre-flight's own target check (no stop):
16. `kubectl config current-context` (14:52): `prod-cluster`, matches `Target:`.
17. `aws sts get-caller-identity` (14:53): account `123456789012`, matches.
18. `kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'` (14:54): no canned output; no mismatch shown.
19. `kubectl get namespace notifyapi-prod` (14:55): `Active`.
Local: `git log --since=7.days …` (14:56): empty; `git rev-parse --short HEAD` (14:57): `a1b2c3d`. Docs: scaling a Deployment (14:30, read 2026-04-24); pricing lookup (14:58): no result.
