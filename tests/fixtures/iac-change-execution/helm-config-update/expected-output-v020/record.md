(Would be written to `.culiops/iac-change-execution/notifyapi-scale-replicas-20260424-1509.md`; not committed.)

**IaC change execution for:** `notifyapi` / `prod`
**Change:** Increase replica count from 2 to 4 for notifyapi in prod.
**Date:** `2026-04-24 15:09`
**Commit:** `7f3a9c1`
**IaC tool(s):** Helm (chart `notifyapi` 1.2.0, `values.yaml` + `values-prod.yaml`); prerequisites for `examples/kubernetes.md`: `kubectl` v1.29.4, `helm` v3.14.4 (with the `helm-diff` plugin for the plan), a kubeconfig context for `prod-cluster`, read-only RBAC for Steps 1 and 5, namespace-scoped mutation RBAC only for a direct apply (none used)
**Execution path:** PR (https://github.com/acme/notifyapi/pull/57)
**Pre-flight record:** invoked inline — verdict: RED — soft block (`.culiops/pre-flight/notifyapi-scale-replicas-20260424-1458.md`); `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` not reused: its plan hash, target and age matched (4 h 18 min), but S1 could only answer `Q1(alarms)` and `Q3` as `unsure` against its recorded `no` answers, which counts as changed (Step 4b)
**Lane:** full — a `Deployment` update is not on the Kubernetes light-lane allowlist (L2 fails, `lanes.md`); L1 and L3 hold; no escalation
**Escalations:** none
**Environment tier:** prod=prod (operator-stated at [F1], 14:14; no pin in the repo — no CI config, no GitOps destination — so unproven, prod gate levels)
**Staging-first:** n/a — no staging env (code: `values-prod.yaml` is the only per-environment values file; catalog: Environment prod only)
**Waived:** F3 — operator, 14:38

## Research Summary

- Catalog used: `.culiops/service-discovery/notifyapi-prod.md` (a lead; every fact below confirmed in code and live). Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset).
- Duplicate check: **not done**. `code: values-prod.yaml:4` is `replicaCount: 2`; `git grep -F` finds no `replicaCount: 4` / `replicas: 4`; `git: git log --all -S'replicaCount: 4'` has no commits; no branch matches `*replica*`; no open PR. No ticket key given.
- Delivery model: **UNVERIFIED in the repo** (no CI config, no `Application` / `HelmRelease` / `Kustomization`; no Argo CD or Flux in the cluster, `live: 14:19, 14:20`); asked at `[F2]` and recorded `operator-stated`: a CI job runs `helm upgrade` on merge (`live: gh run list 14:29` shows a `helm-upgrade` workflow that succeeded 2026-04-02). PR path only.
- Env selection: values file per environment (`-f values.yaml -f values-prod.yaml`), namespace `notifyapi-prod` (`code: values-prod.yaml:1-2`).
- Target check: `kubectl config current-context` → `prod-cluster` at 14:01 and again at 14:45 (4a) and 14:51 (pre-flight): same. The API server read (`kubectl config view --minify`) had no output.
- Key findings: no HPA, no PDB, RollingUpdate 25% / 25%, 2 of 2 pods ready and 0 restarts, last apply 22 days ago. Operator profile read (`~/.culiops/operator.md`): Q4 many times, Q5 experienced (2026-04-10); no `incident check:` command; no freeze calendar in the repo.
- No metrics backend (no Prometheus address anywhere): the snapshot is point-in-time only; `Q1(alarms)` and `Q3` are `unsure`.

## Evidence

| # | Fact | Code evidence | Live evidence | Match? |
|---|------|---------------|---------------|--------|
| 1 | prod `replicas` is 2, 2 of 2 ready | `code: values-prod.yaml:4`; `code: templates/deployment.yaml:10` | `live: kubectl get deploy notifyapi … (14:15)` → 2 / 2; `live: helm get values (14:16)` → `replicaCount: 2` | ✅ |
| 2 | release `notifyapi` chart 1.2.0 deployed | `code: Chart.yaml:5` | `live: helm list (14:17)` → revision 9 `deployed` | ✅ |
| 3 | no HPA scales the Deployment | `code: none` | `live: S0 (14:27)` → no HPA | ✅ |
| 4 | no PDB; RollingUpdate 25% / 25% | `code: none` (no PDB, no `strategy:`) | `live: kubectl get pdb (14:21)` → none; `live: (14:15)` strategy | ✅ |
| 5 | no drift in the release | — | `live: helm diff upgrade … (14:18)` → no differences | ✅ |
| 6 | alert rules exist for the service | `code: none` (rules are in namespace `monitoring`, not this chart) | `live: kubectl get prometheusrule (14:25)` → 3 alerts | live only |
| 7 | delivery model: CI runs `helm upgrade` on merge | `code: none` | `live: gh run list (14:29)` | ⚠️ UNVERIFIED (operator-stated at `[F2]`) |

Drift rows: 0. Unverified rows: 1 (delivery model). Disruption evidence: `docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment (read 2026-04-24)`: changing `.spec.replicas` adds or removes pods and does not roll the pod template.

## Change Plan

**Phase 1 of 1: Scale prod notifyapi from 2 to 4 replicas**
- Files: `values-prod.yaml` (line 4: `replicaCount: 2` → `4`)
- Resources affected: `Deployment/notifyapi` (notifyapi-prod): in place, `spec.replicas` 2 → 4. No add, no destroy.
- Blast radius: Deployment `notifyapi` and its pods; Service `notifyapi` (`n/a — no health signals of its own`). `Snapshot coverage: code + catalog + live kubectl reads; not covered: callers outside this repo; no metrics backend — point-in-time only`
- Disruption: none (`docs:` above; `live:` no HPA, no PDB, RollingUpdate 25% / 25%); confirmed at 4a by `plan:` (in-place update, one hunk)
- Rollback path: revert the PR and let the pipeline apply it, or `helm rollback notifyapi 9 -n notifyapi-prod` (a mutation, own approval; revert the PR as well). Reversible, `untested`. `live: helm history (14:28)` revision 9 exists.
- Success criteria: `kubectl rollout status deploy/notifyapi -n notifyapi-prod --timeout=5m` → `successfully rolled out`; `kubectl get deploy notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'` → `4/4`; `helm history notifyapi -n notifyapi-prod --max 5` → a new revision `deployed`; `kubectl top pods … -l app.kubernetes.io/name=notifyapi` → 4 pods under their requests; S2 on the snapshot set (not-app-facing: no two-period wait; point-in-time only)
- Execution path: PR. Staging-first: (a) no staging env. Branch: `iac-change/notifyapi-replicas-4` from `origin/main` @ `a1b2c3d`.
- Plan self-check: 8/8 pass.

## Execution Log

### Phase 1: Scale prod notifyapi from 2 to 4 replicas
- Files changed: `values-prod.yaml` (line 4, `replicaCount` 2 → 4)
- Self-check: plan 8/8 · diff 6/6 (`helm lint .` clean; one INFO line about a missing chart icon, not a failure)
- Fresh eyes: not run — dry run
- Plan output summary: 1 object changed — `Deployment/notifyapi`, `replicas: 2` → `4`, in place; 0 to add, 1 to change, 0 to destroy
- Plan hash: `sha256:9f2c4e…` (`helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml`, run 14:46)
- Parity check: n/a
- Pre-flight verdict: RED — soft block (categories 5 ⚪, 7 🟡, 8 🟡, 10 ⚪; Red = none; Yellow + ⚪ = 4, so the multi-Yellow escalation applies). Risks acknowledged at `[H5]` 14:58: "Acknowledged, each finding as shown. I'll merge in staffed hours with on-call on hand and follow the mitigations listed." Mitigations committed: merge in staffed hours with on-call on hand; check traffic, error rate and latency on the dashboard before merging; confirm `NotifyApiPodNotReady` is loaded in Prometheus after the apply; check node allocatable vs requests before merging. Approved at `[F4]`, 15:05.
- Execution: PR https://github.com/acme/notifyapi/pull/57 opened (branch `iac-change/notifyapi-replicas-4`, commit `7f3a9c1`, "notifyapi: scale prod replicas from 2 to 4"). Not merged; after merge the CI job runs `helm upgrade` (operator-stated).
- Verification: not run — the apply has not landed (PR open). No re-plan, no success-criteria output, no S2.
- Snapshot: before 14:48 (S1) · after not taken (PR open, apply pending) · n/a

## Health Snapshot

`Snapshot coverage: code + catalog + live kubectl reads; not covered: callers outside this repo (the catalog lists none); no metrics backend — point-in-time only.`

Not-app-facing change (`replicas` only), so no dependents or dependencies in the set.

Members:
- Deployment `notifyapi` and its pods `notifyapi-6c9f7d58b4-x7k2p`, `notifyapi-6c9f7d58b4-m4t9d` — source `code: templates/deployment.yaml:10`, `catalog:`, `plan:`; changed resource; `no metrics backend — point-in-time only`
- Service `notifyapi` — source `code: templates/service.yaml`; `n/a — no health signals of its own`

### prod — S0 (read 14:27, with the Step 1 batch)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| Deployment `notifyapi` | ready vs desired | 2 of 2 | — | — | `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod -o custom-columns=…` | 14:27 |
| Pod `notifyapi-6c9f7d58b4-x7k2p` | phase, restarts | Running, 0 | — | — | same | 14:27 |
| Pod `notifyapi-6c9f7d58b4-m4t9d` | phase, restarts | Running, 0 | — | — | same | 14:27 |
| Deployment `notifyapi` | `Warning` events | none | — | — | same | 14:27 |
| Deployment `notifyapi` | HPA | none | — | — | same | 14:27 |
| Deployment `notifyapi` | alerts firing | no data (alerts unreadable, no metrics backend) | — | — | none run | — |
| Deployment `notifyapi` | request rate, error rate, p95 | no data (no metrics backend) | — | — | none run | — |
| (automation lag) | last apply | revision 9 deployed 2026-04-02 09:41 UTC (22 days); CI run succeeded 2026-04-02 09:40 UTC | — | — | `helm history notifyapi -n notifyapi-prod --max 5`; `gh run list --limit 5 …` | 14:28, 14:29 |

### prod — S1 (read 14:48, after the 4a plan; S0 was 20 minutes old, so not reused)

| Member | Signal | Before | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| Deployment `notifyapi` | ready vs desired | 2 of 2 | — | — | `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod -o custom-columns=…` | 14:48 |
| Pod `notifyapi-6c9f7d58b4-x7k2p` | phase, restarts | Running, 0 | — | — | same | 14:48 |
| Pod `notifyapi-6c9f7d58b4-m4t9d` | phase, restarts | Running, 0 | — | — | same | 14:48 |
| Deployment `notifyapi` | `Warning` events | none | — | — | same | 14:48 |
| Deployment `notifyapi` | HPA | none | — | — | same | 14:48 |
| Deployment `notifyapi` | alerts firing, request rate, error rate, p95 | no data (no metrics backend) | — | — | none run | — |

### prod — S2

Not taken: the PR is open and the apply has not landed. No after value is claimed.

## Outcome

Outcome: completed

**Applied:** no — PR open

## Ticket Reference

none
