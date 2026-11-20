<!-- Would be written to .culiops/iac-change-execution/notifyapi-scale-replicas-20260424-1514.md at Step 5b. Not committed (the commit is offered in the final message). -->

**IaC change execution for:** `notifyapi` / `prod`
**Change:** Increase replica count from 2 to 4 for notifyapi in prod (`replicaCount` in `values-prod.yaml`)
**Date:** `2026-04-24 15:14`
**Commit:** `7f3a9c1` (branch `iac-change/notifyapi-replicas-2-to-4`)
**IaC tool(s):** Helm (chart `notifyapi` 1.2.0)
**Execution path:** PR (https://github.com/acme/notifyapi/pull/57)
**Pre-flight record:** `.culiops/pre-flight/notifyapi-scale-replicas-20260424-1504.md` — invoked inline — verdict: RED — soft block; `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` not reused: same plan hash, same target and inside 24 h, but S1 gave `Q3=unsure (apply at merge)` and `Q1(alarms)=unsure` against the record's recorded `not peak hours` / `no incident`, which counts as changed
**Lane:** full — `Deployment` update (`replicas`) is off the Light-lane allowlist (`lanes.md` › Light-lane allowlist, Kubernetes: only create of `PrometheusRule`, `ServiceMonitor`, `PodMonitor`); tier unproven, so not dev
**Escalations:** none
**Environment tier:** prod=prod (operator-stated at [F1]; no pin in the repo: no CI config, Argo CD or Flux object names a context — unproven, prod gate levels)
**Staging-first:** n/a — no staging env (code: `values.yaml` (base) and `values-prod.yaml` are the only environment files)
**Waived:** F3 — operator, 14:36

Prerequisites (Kubernetes examples, `examples/kubernetes.md`; the CloudWatch reads use `examples/aws.md` › Health Snapshot): `kubectl` 1.29.4 against server 1.29.8 (`kubectl-version.txt`), `helm` v3.14.4 with the `helm-diff` plugin, `aws-cli` 2.17.21, `gh`; read-only RBAC tier 1, plus `secrets` get/list in `notifyapi-prod` for `helm history`; no elevated tier needed (the apply is by CI).

## Research Summary

- Catalog used: `.culiops/service-discovery/notifyapi-prod.md` (resource inventory, dependency graph: SQS, SMTP relay, SES upstream; no known downstream consumers).
- Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset).
- Duplicate check: **not done** — `code: values-prod.yaml:4` → 2; `git log --all --oneline -S'replicaCount: 4'` empty; `git branch -a --list '*replica*'` empty; `gh pr list --state open --search 'replica'` none. The earlier pre-flight record (10:30) assessed this same change; it is not a change in code.
- Delivery model: `UNVERIFIED` in the repo (no CI config, no GitOps object; `values-prod.yaml:2` carries a manual `helm upgrade` comment, treated as data). Asked inside `[F2]`: a CI job runs `helm upgrade` on merge — `operator-stated`. PR path only.
- Environment selection: `-f values.yaml -f values-prod.yaml` (`code: values-prod.yaml:1-2`).
- Target check: `kubectl config current-context` → `prod-cluster` and `aws sts get-caller-identity` → account `123456789012` at 14:00–14:01 and again at 14:42–14:43 (4a); namespace `notifyapi-prod`. No mismatch (no pin to compare with; the account equals the account in `code: values-prod.yaml:20`).
- Operator profile read at 14:08 (`~/.culiops/operator.md`): Q5 helm experienced, Q4 `acme/notifyapi/notifyapi` many times, both 2026-04-10. Nothing saved.
- Key findings: no drift (`helm diff` before the change: no differences); no HPA, no PDB; RollingUpdate 25% / 25%; nodes CPU 31–44%, memory 38–52%; Helm rev 9 on 2026-04-02 (22 days), CI run success 2026-04-02; weekday peak hours 09:00–12:00 +07:00.
- Fresh eyes: required for this change (not add-only); `fresh-eyes: not run — dry run`.

## Evidence

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| notifyapi prod replicas | `code: values-prod.yaml:4` → 2 (base `values.yaml:3` = 1, overridden; consumed at `templates/deployment.yaml:10`) | `live: kubectl get deploy notifyapi … jsonpath` (14:16) → 2; `live: helm get values notifyapi` (14:15) → `replicaCount: 2` | ✅ |
| Ready replicas, restarts | — | `live:` 2/2 ready (14:16); 2 pods Running, 0 restarts (14:17) | observed |
| Release equals chart | `code:` chart as committed | `live: helm diff upgrade … ` (14:14) → no differences | ✅ no drift |
| Pod requests / limits | `code: values-prod.yaml:10-15` → 250m / 256Mi, 1000m / 512Mi | `live:` (14:16) → 250m / 256Mi, 1 / 512Mi | ✅ |
| Image tag | `code: values-prod.yaml:7` → `v3.1.0` | `live:` (14:16) → `registry.internal/notifyapi:v3.1.0` | ✅ |
| Rollout strategy | `code: none` (default) | `live:` (14:16) → RollingUpdate 25% / 25% | live only |
| HPA / PDB | `code: none` | `live:` (14:19, 14:20) → none, none | ✅ |
| Node headroom | — | `live:` (14:21–14:22) pods 47% / 42% CPU, 67% / 65% memory of request; nodes CPU 31–44%, memory 38–52% | observed; node allocatable not read |
| Behaviour of a `replicas` change | — | `docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment (read 2026-04-24)`: adds or removes pods, no template rollout | docs |
| Delivery model | `code: values-prod.yaml:2` comment (data) | `live: gh run list` (14:26): one success run 2026-04-02 | `UNVERIFIED` → `operator-stated` at `[F2]` |
| Downstream consumers | `catalog:` none known | `live:` Ingress read (14:24): no canned output, failed | `UNVERIFIED` |

Drift rows: 0 · unverified rows: 2 · code-only rows: 0.

## Change Plan

**Phase 1 of 1: raise the prod replica count from 2 to 4** (approved at `[F2]`, 14:36)
- Files: `values-prod.yaml`
- Resources affected: change `Deployment/notifyapi` (in place); no add, no destroy
- Blast radius: the snapshot set (see Health Snapshot), with its coverage line
- Disruption: `none` — `docs:` a replicas change adds pods and does not roll the pod template; `live:` RollingUpdate 25% / 25%, no PDB, no HPA; `plan:` (4a) only `replicas` changes
- Rollback path: reversible — `helm rollback notifyapi 9 -n notifyapi-prod` after the new revision, or a revert PR delivered the same way; `docs:` scaling adds or removes pods; `live:` `helm history` shows revisions 7–9; untested
- Success criteria: `kubectl rollout status deploy/notifyapi -n notifyapi-prod --timeout=5m` → `deployment "notifyapi" successfully rolled out`; `kubectl get deploy notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'` → `4/4`; pods list → 4 `Running`, restarts 0; `helm history notifyapi -n notifyapi-prod --max 5` → a new revision `deployed`; re-plan `helm diff upgrade …` → no differences; S2 on the snapshot set
- Execution path: PR (CI applies on merge, `operator-stated`)
- Staging-first (H7): (a) no staging env — `code: values.yaml`, `values-prod.yaml`. Observation window: n/a — no staging phase
- Branch: `iac-change/notifyapi-replicas-2-to-4` from `origin/main` @ `a1b2c3d`
- Self-check: 8/8

## Execution Log

### Phase 1: raise the prod replica count from 2 to 4
- Files changed: `values-prod.yaml` (line 4: `replicaCount: 2` → `4`)
- Self-check: plan 8/8 · diff 6/6
- Fresh eyes: not run — dry run
- Plan output summary: `helm diff upgrade` — 1 object changed (`Deployment/notifyapi`, `replicas: 2 → 4`); 0 to add, 1 to change, 0 to destroy
- Plan hash: `sha256:9f2c4e…`
- Parity check: n/a
- Pre-flight verdict: RED — soft block (4 of 11 Yellow or unknown: 🟡 timing, 🟡 cost, ⚪ observability, ⚪ resource health). Risks acknowledged at `[H5]`, 2026-04-24 15:04: "Acknowledged, each finding as shown. I'll merge in staffed hours with on-call on hand and follow the mitigations listed." Mitigations committed: merge outside weekday 09:00–12:00 +07:00 with on-call on hand; a Prometheus / Alertmanager address or a hand check that alerts exist; confirm node placement or price the added pods; compare S2 and error rate / latency after the merge. Shown again at `[F4]` (15:06), approved 15:11.
- Execution: PR https://github.com/acme/notifyapi/pull/57 opened from `iac-change/notifyapi-replicas-2-to-4` (commit `7f3a9c1`, `notifyapi: increase prod replicas from 2 to 4`); not merged by the skill. After merge the CI job (`operator-stated`) applies it.
- Verification: not run — the PR is open and no apply has landed. No success-criteria output exists; no re-plan was run; nothing is claimed.
- Snapshot: before 14:51 (S1; S0 14:28) · after — (no S2 yet) · n/a (S0 and S1 only)

## Health Snapshot

`Snapshot coverage: code (templates/, values-prod.yaml) + catalog (.culiops/service-discovery/notifyapi-prod.md) + live (kubectl, CloudWatch ap-southeast-1); not covered: callers outside this repo (callers that dial the Service by DNS name are not visible in the cluster API), SMTP relay and AWS SES (catalog leads, no read), notifyapi's own error rate, latency and firing alerts (no metrics backend: no Prometheus address in the repo, catalog or earlier record), Warning events (read returned nothing usable).`

Members (10-member cap; 2 get reads, none over the cap):
1. `Deployment/notifyapi` — changed; source `code: values-prod.yaml:4`, `plan: helm diff`; `no metrics backend — point-in-time only`.
2. `Service/notifyapi` — dependent; source `code: templates/service.yaml:15-16`; `n/a — no health signals of its own` (measured through the Deployment).
3. SQS queue `notifyapi-prod-inbound` — dependency; source `code: values-prod.yaml:20`, `code: templates/configmap.yaml:11`, `catalog:` dependency graph; CloudWatch `ap-southeast-1`.
4. SMTP relay `smtp.internal:587` — dependency; source `catalog:` only; not snapshotted (lead, not confirmed in code, no read available).
5. AWS SES — dependency; source `catalog:` only; not snapshotted (lead, not confirmed).

Peak hours (from the S0 7-day hourly series, UTC converted): weekdays 09:00–12:00 +07:00 (02:00–05:00 UTC), 4,026–4,511 messages per hour.

### Environment prod — S0 (before; taken 14:16–14:28)

| Member | Signal | Before (now) | Same hour last week | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|---|
| Deployment/notifyapi | desired vs ready | 2 / 2 | — | — | — | `kubectl get deploy notifyapi -n notifyapi-prod -o jsonpath=…` | 14:16 |
| Deployment/notifyapi | pods, restarts | 2 Running, 0 / 0 | — | — | — | `kubectl get pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -o custom-columns=…` | 14:17 |
| Deployment/notifyapi | Warning events | no data (no canned output) | — | — | — | `kubectl get events -n notifyapi-prod --field-selector type=Warning …` | 14:18 |
| Deployment/notifyapi | HPA | none | — | — | — | `kubectl get hpa -n notifyapi-prod …` | 14:19 |
| Deployment/notifyapi | traffic, errors, latency, firing alerts | no metrics backend — point-in-time only | — | — | — | — | — |
| Service/notifyapi | — | n/a — no health signals of its own | — | — | — | — | — |
| SQS notifyapi-prod-inbound | firing alarms | 0 | — | — | — | `aws cloudwatch describe-alarms --state-value ALARM …` | 14:27 |
| SQS notifyapi-prod-inbound | `NumberOfMessagesSent` (Sum, hour) | 2,910 (bucket 2026-04-24T06:28Z) | 2,860 (2026-04-17T06:28Z) | — | — | `aws cloudwatch get-metric-data … snapshot-queries-prod.json` | 14:28 |
| SQS notifyapi-prod-inbound | `ApproximateNumberOfMessagesVisible` (Maximum) | 10 | 8 | — | — | same call | 14:28 |
| SQS notifyapi-prod-inbound | `ApproximateAgeOfOldestMessage` (Maximum, s) | 6 | 7 | — | — | same call | 14:28 |

### Environment prod — S1 (before the apply; taken 14:46–14:51; S0 was 17 minutes old, not reused)

| Member | Signal | Before (now) | Same hour last week | After | Verdict | Command | Time |
|---|---|---|---|---|---|---|---|
| Deployment/notifyapi | desired vs ready | 2 / 2 | — | — | — | `kubectl get deploy notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'` | 14:46 |
| Deployment/notifyapi | pods, restarts | 2 Running, 0 / 0 | — | — | — | `kubectl get pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -o custom-columns=…` | 14:47 |
| Deployment/notifyapi | Warning events | no data (no canned output) | — | — | — | `kubectl get events -n notifyapi-prod --field-selector type=Warning …` | 14:48 |
| Deployment/notifyapi | HPA | none | — | — | — | `kubectl get hpa -n notifyapi-prod …` | 14:49 |
| Deployment/notifyapi | traffic, errors, latency, firing alerts | no metrics backend — point-in-time only | — | — | — | — | — |
| Service/notifyapi | — | n/a — no health signals of its own | — | — | — | — | — |
| SQS notifyapi-prod-inbound | firing alarms | 0 | — | — | — | `aws cloudwatch describe-alarms --state-value ALARM …` | 14:50 |
| SQS notifyapi-prod-inbound | `NumberOfMessagesSent` (Sum, hour) | 2,910 (bucket 2026-04-24T06:51Z) | 2,860 (2026-04-17T06:51Z) | — | — | `aws cloudwatch get-metric-data …` | 14:51 |
| SQS notifyapi-prod-inbound | `ApproximateNumberOfMessagesVisible` (Maximum) | 10 | 8 | — | — | same call | 14:51 |
| SQS notifyapi-prod-inbound | `ApproximateAgeOfOldestMessage` (Maximum, s) | 6 | 7 | — | — | same call | 14:51 |

### Environment prod — S2

Not taken: the PR is open and the apply is pending, so there is no after value and none is claimed. When the operator says the apply has landed, S2 reads `kubectl rollout status`, the pods, the alarms and the queue (`Period` 300 from the rollout completion), and compares against S1; the "before" for metrics is read back for the window ending at the apply time (`helm history` gives that time).

## Outcome

completed

**Applied:** no — PR open (https://github.com/acme/notifyapi/pull/57; not merged; the CI job applies on merge, `operator-stated`). Members with `no data`: Deployment/notifyapi Warning events; notifyapi's error rate, latency and alerts (no metrics backend).

## Ticket Reference

none
