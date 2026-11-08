**IaC change execution for:** `notifyapi` / `prod`
**Change:** Increase replica count from 2 to 4 for notifyapi in prod.
**Date:** 2026-04-24 15:01
**Commit:** `7f3a9c1` (branch `iac-change/notifyapi-replicas-4`)
**IaC tool(s):** Helm (chart `notifyapi` 1.2.0, values `values.yaml` + `values-prod.yaml`)
**Prerequisites (examples/kubernetes.md):** `kubectl` client `v1.29.4` (`kubectl version --client`, 14:03; the +-1 minor check against the cluster's server version was not read, since `kubectl version` is a live read outside the approved batch); `helm` `v3.14.4` (`helm version`, 14:04), `helm-diff` plugin used at 4a; kubeconfig context `prod-cluster`; read-only (Tier 1) access used for every read; no mutation was run by the skill, so no Tier 2 (elevated) binding was used; cost: no new resources, two more pods at 250m / 256Mi requested.
**Execution path:** PR
**Pre-flight record:** `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` (reused under the Step 4b match rule — verdict: GREEN — PROCEED)
**Lane:** full — L2 fails: updating a `Deployment` is not on the Kubernetes light-lane allowlist (`lanes.md`); target tier is unproven (operator-stated prod)
**Escalations:** none
**Environment tier:** prod=prod (operator-stated, unproven: no pin in the repo names the context or the account; identity reads `live: kubectl config current-context` -> `prod-cluster`, `live: aws sts get-caller-identity` -> account `123456789012`, 14:00 and 14:01)
**Staging-first:** n/a — no staging env (code: `values-prod.yaml` is the only per-environment values file; `values.yaml:1` says environments are `values-{env}.yaml`)
**Waived:** F3 — operator, 14:38

## Research Summary

- Catalog used: `.culiops/service-discovery/notifyapi-prod.md` (Deployment `notifyapi`, Helm, EKS, namespace `notifyapi-prod`, no known downstream consumers; a lead only).
- Duplicate check: **not done**. `code: values-prod.yaml:4` is `replicaCount: 2`; `git grep -F 'replicaCount: 4'` has no hits; `git: git log --all -S'replicaCount: 4'` has no commits; no branch matches `*replica*`; no open PR for `replicaCount`. No ticket key was given.
- Delivery model: `UNVERIFIED` in the repo (no CI config, no Application / Kustomization / HelmRelease object; `values-prod.yaml:2` only shows a manual `helm upgrade`). Asked inside `[F2]`; answer `operator-stated`: a CI job runs `helm upgrade` on merge. So the PR path is the only path.
- Env selection: Helm values file per environment, `-f values.yaml -f values-prod.yaml`, namespace `notifyapi-prod` (`code: values-prod.yaml:2`, `code: values.yaml:1`, `catalog: .culiops/service-discovery/notifyapi-prod.md:29`).
- Target: context `prod-cluster` / namespace `notifyapi-prod`; account `123456789012`. Re-checked at 4a (14:44, 14:45): unchanged.
- Environments: `prod` only. Lane predicted full at Step 1; confirmed full from the plan output at 4a.
- Key findings: scale-up of one Deployment, no HPA or PDB, rolling update 25% / 25%, 2/2 pods ready with 0 restarts, alerts for notifyapi exist live (`monitoring/notifyapi-slo`, including `NotifyApiPodNotReady`).
- Gaps: node fit by requests not read (usage 31-44% CPU / 38-52% memory only); error rate, request rate and firing alerts need a Prometheus URL the repo and catalog do not give. The `helm diff` drift read at 14:20 had no canned output; the 4a plan (same command on the changed code) showed no change beyond `replicas`.

## Evidence

| # | Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|---|
| 1 | prod `replicaCount` is 2, 2/2 ready | `code: values-prod.yaml:4`; `code: templates/deployment.yaml:10` | `live: kubectl get deploy/notifyapi -n notifyapi-prod ... readyReplicas/replicas` -> `2/2` (14:15); `live: helm get values notifyapi -n notifyapi-prod` -> `replicaCount: 2` (14:19) | match |
| 2 | Rollout settings | `code: templates/deployment.yaml` (no `strategy:` block, Kubernetes default) | `live: ... .spec.strategy` -> RollingUpdate 25% / 25% (14:16) | match (default) |
| 3 | Per-pod requests and limits | `code: values-prod.yaml:11-12, 14-15` | `live: ... containers[*].resources` -> 250m / 256Mi, limits `1` / 512Mi (14:17) | match |
| 4 | No HPA, no PDB | `code: none` | `live: kubectl get hpa`, `kubectl get pdb` -> none (14:22, 14:23) | match |
| 5 | Release state | `code: Chart.yaml` version 1.2.0 | `live: helm list -n notifyapi-prod` -> revision 9, `deployed`, `notifyapi-1.2.0`, 2026-04-02 (14:18) | match |
| 6 | Pods healthy before the change | `code: none` | `live: kubectl get pods` -> 2 Running, 0 restarts (14:21); `live: kubectl top pods` -> 118m / 104m CPU (14:24); `live: kubectl rollout status` -> rolled out (14:26) | match |
| 7 | Node usage | `code: none` | `live: kubectl top nodes` -> CPU 31-44%, memory 38-52% (14:25) | usage only; fit by requests `UNVERIFIED` |
| 8 | Alerts and scrape config for notifyapi | `code: none` (defined outside this chart) | `live: kubectl get prometheusrule` -> `monitoring/notifyapi-slo` (NotifyApiErrorBudgetBurn, NotifyApiQueueBacklog, NotifyApiPodNotReady) (14:27); `live: kubectl get servicemonitor` -> `notifyapi` (14:28) | outside this repo, not drift |
| 9 | Chart vs live drift beyond `replicas` | `code: values-prod.yaml` | `live: helm diff` at 14:20 -> `no canned output`; `plan: helm diff` at 14:46 -> only `Deployment/notifyapi` `replicas` 2 -> 4 | resolved by the plan: no other drift |
| 10 | Delivery model | `code: none` (hint `values-prod.yaml:2`) | `operator-stated` at `[F2]`, 14:38: a CI job runs `helm upgrade` on merge | `UNVERIFIED` in the repo; operator-stated |
| 11 | Disruption of the change | `plan: Deployment/notifyapi update in place` (14:46) | `live: RollingUpdate 25% / 25%, no PDB` (14:16, 14:23); `docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment (2026-04-24)`: changing `.spec.replicas` adds or removes pods and does not trigger a rollout of the pod template | none |

Drift rows: 0. Unverified rows: row 7 (node fit by requests), row 10 until the operator's answer.

## Change Plan

**Phase 1 of 1: Raise prod replicas from 2 to 4**
- Files: `values-prod.yaml` (line 4: `replicaCount: 2` -> `4`)
- Resources affected: 1 changed, in place: `Deployment/notifyapi` (apps), `spec.replicas` 2 -> 4. 0 added, 0 destroyed.
- Blast radius: 1 object in 1 namespace (`code: templates/deployment.yaml:10`). More consumers on the SQS queue `notifyapi-prod-inbound` and the SMTP relay (`catalog: .culiops/service-discovery/notifyapi-prod.md:34-35`, lead only); their capacity was not read live. No downstream consumers listed (`catalog:39`, lead only).
- Disruption: none (`docs:` as in evidence row 11; `live:` rows 2 and 4; `plan:` 14:46).
- Rollback path: revert the PR (replicaCount back to 2) and let the pipeline apply it; or `helm rollback notifyapi 9 -n notifyapi-prod` (a mutation, own approval, and a later pipeline run re-applies merged code, so revert the PR as well). Reversible, `untested`. Evidence: `live: helm list` -> revision 9 exists (14:18); `docs:` replicas is a plain spec field (same page).
- Evidence: rows 1-6 and 11.
- Success criteria (approved at `[F2]`, to run once the apply has landed):
  1. `kubectl rollout status deploy/notifyapi -n notifyapi-prod --timeout=5m` -> `deployment "notifyapi" successfully rolled out`
  2. `kubectl get deploy/notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'` -> `4/4`
  3. `kubectl get pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{range .status.containerStatuses[*]}{.restartCount}{"\t"}{end}{"\n"}{end}'` -> 4 pods `Running`, 0 restarts
  4. `kubectl top pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi` -> 4 pods, each at or under 250m CPU and 256Mi memory

**Execution path:** PR (the operator's delivery model, a CI job running `helm upgrade` on merge, allows only the PR path).
**Staging-first (H7):** (a) no staging env — code: `values-prod.yaml` is the only per-environment values file; `values.yaml:1`. **Observation window:** n/a.
**Branch:** `main` -> `iac-change/notifyapi-replicas-4` from `origin/main` @ `a1b2c3d`.
**Self-check:** 8/8 pass. **Drift (H4):** none.

## Execution Log

### Phase 1: Raise prod replicas from 2 to 4
- Files changed: `values-prod.yaml` (line 4, `replicaCount` 2 -> 4)
- Self-check: plan 8/8 · diff 6/6 (`helm lint . -f values.yaml -f values-prod.yaml` clean: 1 chart linted, 0 failed)
- Fresh eyes: not run — dry run
- Plan output summary: 1 resource — 0 to add, 1 to change (`Deployment/notifyapi`, `replicas` 2 -> 4, in place), 0 to destroy
- Plan hash: `sha256:9f2c4e…` (`helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml`)
- Parity check: n/a
- Pre-flight verdict: GREEN — PROCEED, from the reused record `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` (hash, target and the 24 h window matched; Q1-Q3 and the category-10 reads re-run at 14:48-14:50, unchanged). No Yellow or unknown findings; no mitigations committed. Operator asked to skip pre-flight at `[F2]`; refused under H9, and the reused record met H9. Acknowledged at `[F4]`, 14:58 (operator).
- Execution: PR `https://github.com/acme/notifyapi/pull/57`, branch `iac-change/notifyapi-replicas-4`, commit `7f3a9c1` (`notifyapi: raise prod replicas from 2 to 4`). The skill ran no apply; the apply is the operator's CI job on merge (`operator-stated`).
- Verification: not run. The PR is open and the apply has not landed. Success criteria 1-4 above are pending.

## Outcome

completed (PR path: the PR is open; the change is not applied yet, see Applied)

**Applied:** no — PR open

## Ticket Reference

none
