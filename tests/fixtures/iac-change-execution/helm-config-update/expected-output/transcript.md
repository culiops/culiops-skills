# Transcript: helm-config-update (working-tree skill, stop IDs)

## Run set-up

- Fixture `tests/fixtures/iac-change-execution/helm-config-update`, script `operator-script.md`, out-dir `expected-output`, skill source `working-tree`.
- Skill text read: `skills/iac-change-execution/SKILL.md`, `lanes.md`, `examples/kubernetes.md`; `skills/pre-flight/SKILL.md`, `assessors/iac-change.md`, `examples/kubernetes.md`. `examples/aws.md` and `examples/app-source.md` were not used: the selection rule (SKILL.md:496-500) sends a Helm change to `examples/kubernetes.md`, and no Q8 was asked.
- Fixture inputs read: `Chart.yaml`, `values.yaml`, `values-prod.yaml`, `templates/*`, `.culiops/service-discovery/notifyapi-prod.md`, `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md`, `operator-script.md`, `canned/INDEX.md` and the canned files. `README.md` and `DRY-RUN-NOTES.md` were not read.
- Operator answers are matched by stop ID (`[F1]`, `[F2]`, `[F4]`). The script's "Answers by meaning" section is ignored.
- Clock starts 2026-04-24 14:00 +07:00. A command's time is the clock when it is issued; the clock then advances 1 minute. Each operator answer advances it 5 minutes. File reads and the skill's own checks cost no time.
- No subagent is dispatched. Fresh eyes: `fresh-eyes: not run — dry run`.
- Canned plan versus code: the canned `helm-diff.txt` (replicas 2 to 4, nothing else) matches the one-line code change the skill writes. No difference to note.

Operator's first message: "Increase replica count from 2 to 4 for notifyapi in prod."

---

## Step 1 — Research

**Output root (Constraint 13, SKILL.md:35).** `CULIOPS_HOME` is treated as unset: no canned row exists for reading it, and the fixture's records sit in the repo's `.culiops/`. Root = `.culiops/` at the repo root. It is shown at `[F1]`.

**Identity read first (SKILL.md:169; exempt from opt-in, Constraint 3).** Both identity reads in the skill's list are run, before any other live command: the kubeconfig context is the Helm target, and an EKS kubeconfig authenticates through AWS, so the account is read too.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:00 | `kubectl config current-context` | `kubectl-context.txt` | `prod-cluster` |
| 14:01 | `aws sts get-caller-identity` | `identity-prod.json` | Account `123456789012`, role `paymentapi-operator` |

**Local read, branch.** The skill reads code from the default branch; the current branch tells it whether `origin/<default>` is needed (SKILL.md:173).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:02 | `git branch --show-current` | `git-branch.txt` | `main` (the default branch, so the working tree is read; no `git show origin/main` needed) |

**Catalog and code read (file reads, no lookup):** `.culiops/service-discovery/notifyapi-prod.md` (Deployment `notifyapi`, 2 replicas, Helm, namespace `notifyapi-prod`, no known downstream consumers); `Chart.yaml`; `values.yaml:3` (`replicaCount: 1`); `values-prod.yaml:4` (`replicaCount: 2`); `templates/deployment.yaml:10` (`replicas: {{ .Values.replicaCount }}`, no `strategy:` block); `templates/configmap.yaml`; `templates/service.yaml`. No ticket was given.

**Tool prerequisites (examples/kubernetes.md, "Prerequisites": Verify lines; local client reads, no cluster contact, so no opt-in).**

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:03 | `kubectl version --client` | `kubectl-version.txt` (client lines only) | Client `v1.29.4`, Kustomize `v5.0.4-0.20230601165947-6ce0bf390ce3` |
| 14:04 | `helm version` | `helm-version.txt` | `v3.14.4` |

**Duplicate check (SKILL.md:177-183).** Identifiers: `replicaCount`, the value `4`, release `notifyapi`. No ticket key, so the `--grep='<KEY>'` history search and the by-key branch search do not apply; identifiers are used instead.

| Time | Command | Canned / answered by | Result |
|---|---|---|---|
| 14:05 | `git grep -n -F 'replicaCount'` | `grep -rn -F` over the fixture input files (protocol rule 1) | `values.yaml:3: replicaCount: 1`; `values-prod.yaml:4: replicaCount: 2`; `templates/deployment.yaml:10: replicas: {{ .Values.replicaCount }}`; `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md:34` (the earlier record's evidence row, "Current replicas = 2") |
| 14:06 | `git grep -n -F 'replicaCount: 4'` | same | no hits |
| 14:07 | `git log --all --oneline -S'replicaCount: 4'` | `empty.txt` (row `git log * -S*`) | no commits |
| 14:08 | `git branch -a --list '*replica*'` | `empty.txt` | no in-flight branch |
| 14:09 | `gh pr list --state open --search 'replicaCount'` | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/notifyapi` |

Verdict: **not done**. `code: values-prod.yaml:4` says 2; no `replicaCount: 4` in any file; `git:` no commit adds it; no branch or PR in flight. No `[H6]` stop.

**Delivery model (SKILL.md:185-188).** Searched the repo for CI config, `Application` / `Kustomization` / `HelmRelease` objects, a Makefile and the README. None exists in the fixture's input files (the fixture's `README.md` is not read, per the protocol). The only hint is a comment, `code: values-prod.yaml:2` (`# To change: helm upgrade notifyapi . -f values.yaml -f values-prod.yaml`), which names a manual command but does not show who applies it. The earlier pre-flight record says "CI on merge" but is a record, not repo evidence. So the delivery model is `UNVERIFIED` and is asked inside `[F2]`, not as a stop of its own. Env selection: Helm values file per environment, `-f values.yaml -f values-prod.yaml`, namespace `notifyapi-prod` (`code: values-prod.yaml:2`, `code: values.yaml:1`, `catalog: .culiops/service-discovery/notifyapi-prod.md:29`). *(Ambiguity noted: SKILL.md:185 names the README as a delivery-model source; the dry run cannot read it.)*

**Environment tiers (lanes.md Environment tier).** Environments the repo defines: `prod` only (`values-prod.yaml`; `values.yaml` is the base, `values.yaml:1`). No pin: nothing in the repo names the context or the account as prod's. The names `prod-cluster` and `notifyapi-prod` prove nothing. Tier of prod = unproven, prod gate levels; the operator may state it at `[F1]`. No positive evidence that the target differs (the account matches `catalog:14` and `code: values-prod.yaml:20`), so no `[H1]`.

**Predicted lane (SKILL.md:190, lanes.md Lane rule).** Not all targets are proven dev. L2 fails: the change is an update to a `Deployment`, and the Kubernetes allowlist holds only `PrometheusRule`, `ServiceMonitor` and `PodMonitor` creates. Lane rule line 4: **full**. E1-E3 are not required (they run only when L1-L3 hold). No escalation recorded.

**Live verification batch (SKILL.md:199).** Full lane: it is `[F1]`. Built from `examples/kubernetes.md` (iac-change-execution and pre-flight), the tool's own drift check (`helm diff`), and the assessor's L3 hooks for the Deployment. Left out, with the reason shown at the stop: reversibility reads (no PVC or other stateful object in the chart), dependents reads (the Service and ConfigMap are unchanged), request-rate and error-rate reads (they need a Prometheus URL that neither the repo nor the catalog gives), cost reads (no autoscaler or new volume; replica count is a not-app-facing scaling count, assessor "Application compatibility").

### STOP 1 — [F1]

Skill message shown to the operator:

```
**Targets and tiers** (identity reads ran first; they need no opt-in)
- kubectl config current-context -> prod-cluster (14:00)
- aws sts get-caller-identity -> account 123456789012, role paymentapi-operator (14:01); the account the catalog (.culiops/service-discovery/notifyapi-prod.md:14) and the SQS queue URL (values-prod.yaml:20) name
- Target: context prod-cluster / namespace notifyapi-prod, Helm release notifyapi, values.yaml + values-prod.yaml
- Environments in the repo: prod only. Tier of prod: UNPROVEN. Nothing in the repo pins the context or the account (no CI config); the name "prod-cluster" proves nothing. Prod gate levels apply. If you know the tier, state it and I record it as operator-stated.
- Lane (predicted): full. L2 fails: updating a Deployment is not on the light-lane allowlist (lanes.md). Escalations: none.
- Duplicate check: not done (code: values-prod.yaml:4 = 2; no `replicaCount: 4` anywhere; git: no commit, branch or PR).
- Output root: .culiops/ at the repo root (CULIOPS_HOME is unset).

**Reads I would run** (read-only, against prod-cluster / notifyapi-prod; helm get values prints key names only, never --all)
 1. kubectl get deploy/notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
 2. kubectl get deploy/notifyapi -n notifyapi-prod -o jsonpath='{.spec.strategy}'
 3. kubectl get deploy/notifyapi -n notifyapi-prod -o jsonpath='{.spec.template.spec.containers[*].resources}'
 4. helm list -n notifyapi-prod
 5. helm get values notifyapi -n notifyapi-prod
 6. helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml   (drift check of the code as it stands; needs the helm-diff plugin)
 7. kubectl get pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{range .status.containerStatuses[*]}{.restartCount}{"\t"}{end}{"\n"}{end}'
 8. kubectl get hpa -n notifyapi-prod
 9. kubectl get pdb -n notifyapi-prod
10. kubectl top pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi
11. kubectl top nodes
12. kubectl rollout status deploy/notifyapi -n notifyapi-prod --timeout=5s
13. kubectl get prometheusrule -A -l app.kubernetes.io/name=notifyapi -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\t"}{range .spec.groups[*].rules[*]}{.alert}{" "}{end}{"\n"}{end}'
14. kubectl get servicemonitor -n notifyapi-prod -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.endpoints[*].port}{"\t"}{.spec.endpoints[*].interval}{"\n"}{end}'
Not proposed: reversibility reads (no PVC or stateful object in the chart); dependents reads (Service and ConfigMap unchanged); request-rate, error-rate and firing-alert reads (they need a Prometheus URL the repo and catalog do not give); cost reads (no autoscaler, no new volume).

**[F1] Run these reads?**
```

Operator answer (script entry 1, `[F1]`; clock 14:10, answer at 14:15): "Approved: run every command shown. Tier: prod, operator-stated."

Recorded: tier `prod=prod (operator-stated; unproven)`. The operator's "context read included" is already covered: the identity reads ran first and their results were shown.

### Read batch (approved at `[F1]`)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:15 | read 1 `kubectl get deploy/notifyapi ... {.status.readyReplicas}/{.spec.replicas}` | `deploy-notifyapi-prod.json` (before), jsonpath applied | `2/2` |
| 14:16 | read 2 `... {.spec.strategy}` | `deploy-notifyapi-prod.json` | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}` |
| 14:17 | read 3 `... {.spec.template.spec.containers[*].resources}` | `deploy-notifyapi-prod.json` | requests `250m` / `256Mi`, limits `1` / `512Mi` |
| 14:18 | read 4 `helm list -n notifyapi-prod` | `helm-list.txt` | release `notifyapi`, revision 9, `deployed`, chart `notifyapi-1.2.0`, updated 2026-04-02 09:41 UTC |
| 14:19 | read 5 `helm get values notifyapi -n notifyapi-prod` | `helm-get-values.yaml` | `replicaCount: 2` (other keys read, values not echoed here) |
| 14:20 | read 6 `helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml` | `no canned output` | The only INDEX row for this command is the plan row, whose `Use when` is "`replicaCount` 2 to 4 for the expected code". The code is still unchanged (`replicaCount: 2`), so the row's condition does not hold and the canned plan would contradict the code. Read treated as failed; the drift check by `helm diff` is `UNVERIFIED` until the 4a plan (the same command, run on the changed code, covers the whole release). |
| 14:21 | read 7 `kubectl get pods ... restartCount` | `pods-notifyapi-prod.json` (before), jsonpath applied | 2 pods `Running`, 0 restarts each |
| 14:22 | read 8 `kubectl get hpa -n notifyapi-prod` | `kubectl-no-resources.txt` | `No resources found in notifyapi-prod namespace.` |
| 14:23 | read 9 `kubectl get pdb -n notifyapi-prod` | `kubectl-no-resources.txt` | `No resources found in notifyapi-prod namespace.` |
| 14:24 | read 10 `kubectl top pods -n notifyapi-prod -l ...` | `kubectl-top-pods.txt` (before) | 2 pods: 118m / 171Mi and 104m / 166Mi |
| 14:25 | read 11 `kubectl top nodes` | `kubectl-top-nodes.txt` | 3 nodes, CPU 31-44%, memory 38-52% |
| 14:26 | read 12 `kubectl rollout status deploy/notifyapi -n notifyapi-prod --timeout=5s` | `kubectl-rollout-status.txt` | `deployment "notifyapi" successfully rolled out` |
| 14:27 | read 13 `kubectl get prometheusrule -A -l app.kubernetes.io/name=notifyapi ...` | `prometheusrules-notifyapi.json`, jsonpath applied | `monitoring/notifyapi-slo`: NotifyApiErrorBudgetBurn, NotifyApiQueueBacklog, NotifyApiPodNotReady |
| 14:28 | read 14 `kubectl get servicemonitor -n notifyapi-prod ...` | `servicemonitors-notifyapi.json`, jsonpath applied | `notifyapi`, port `http`, interval `30s` |

Environment taken for each read: the command carries `-n notifyapi-prod` (rule 1a); `helm list` and `helm get values` also carry it. Reads 13 and 14 use the only canned row for them.

**Evidence table (Constraint 9), built from the code and the reads above.**

| # | Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|---|
| 1 | prod `replicaCount` is 2 and 2/2 are ready | `code: values-prod.yaml:4` -> `replicaCount: 2`; `code: templates/deployment.yaml:10` renders it into `spec.replicas` | `live: kubectl get deploy/notifyapi ... {.status.readyReplicas}/{.spec.replicas}` -> `2/2` (14:15); `live: helm get values ...` -> `replicaCount: 2` (14:19) | match |
| 2 | Rollout settings | `code: templates/deployment.yaml` has no `strategy:` block (Kubernetes default applies) | `live: ... {.spec.strategy}` -> RollingUpdate, maxSurge 25%, maxUnavailable 25% (14:16) | match (default, no code value to differ from) |
| 3 | Per-pod requests and limits | `code: values-prod.yaml:11-12` (250m / 256Mi), `values-prod.yaml:14-15` (`1000m` / 512Mi) | `live: ...containers[*].resources` -> 250m / 256Mi, limits `1` / 512Mi (14:17) | match (`1000m` = `1`) |
| 4 | No HPA and no PDB | `code: none` (the chart has no HPA or PDB template) | `live: kubectl get hpa` / `get pdb` -> none (14:22, 14:23) | match; nothing resets `replicas`, nothing limits disruption |
| 5 | Release state | `code: Chart.yaml` version 1.2.0 | `live: helm list` -> revision 9, `deployed`, chart `notifyapi-1.2.0`, updated 2026-04-02 (14:18) | match; a previous revision exists; last apply 22 days ago |
| 6 | Pods healthy before the change | `code: none` | `live: kubectl get pods` -> 2 Running, 0 restarts (14:21); `live: kubectl top pods` -> 118m / 104m CPU, 171Mi / 166Mi (14:24); `live: kubectl rollout status` -> rolled out (14:26) | match |
| 7 | Node usage | `code: none` | `live: kubectl top nodes` -> CPU 31-44%, memory 38-52% (14:25). This is usage, not allocatable minus requests | `UNVERIFIED` that 2 more pods (500m / 512Mi requested in total) fit by requests |
| 8 | Alerts watching notifyapi | `code: none` (defined outside this chart) | `live: kubectl get prometheusrule` -> `monitoring/notifyapi-slo` with 3 alerts, among them `NotifyApiPodNotReady` (ready < desired, for 10m) (14:27); `live: kubectl get servicemonitor` -> `notifyapi` (14:28) | outside this repo, not a drift row |
| 9 | Chart vs live drift beyond `replicas` | `code: values-prod.yaml` | `live: helm diff` (14:20) -> `no canned output` | `UNVERIFIED`; the 4a plan covers it |
| 10 | Delivery model | `code: none` in the repo (hint only: `values-prod.yaml:2`) | none | `UNVERIFIED`; asked in `[F2]` |

Drift rows: 0. Unverified rows: 3 (7, 9, 10). Row 7 and 9 do not justify the replica change; row 1 does.

**Gaps remaining:** (a) delivery model, resolved by the operator's answer at `[F2]`; (b) drift beyond `replicas`, resolved by the 4a plan; (c) node fit by requests, `kubectl describe nodes` (Allocated resources) would resolve it and is not in the batch, the success criteria catch Pending pods; (d) error rate, request rate and firing alerts need a Prometheus URL the repo and catalog do not give.

**Resource ownership check:** no `import` in this change; not applicable.

---

## Step 2 — Plan

Single phase: one atomic in-place change (`replicaCount` 2 to 4), PR path (default; CI-applies-on-merge or by-hand both end at a PR).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:29 | `git branch --show-current` | `git-branch.txt` | `main` |
| 14:30 | `git status --short` | `git-status-clean.txt` | (nothing printed; clean tree) |
| 14:31 | `git rev-parse --short origin/main` | `git-rev-parse.txt` | `a1b2c3d` |
| 14:32 | docs lookup: how changing `spec.replicas` on a Deployment behaves | `docs.md` | `docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment (read 2026-04-24)`: scaling by changing `.spec.replicas` adds or removes pods; it does not trigger a rollout of the pod template, so existing pods keep running. |

Branch: current `main`, so the plan proposes `git fetch origin main` and `git switch -c iac-change/notifyapi-replicas-4 origin/main` (fallback name pattern `iac-change/<service>-<short-description>`; the repo has no other branch pattern, `git-branches.txt`). Full lane: the commands run after `[F2]`.

Staging-first (H7): the repo defines one environment, prod. No staging env, so exception (a), automatic, with evidence `code: values-prod.yaml` is the only per-environment values file and `values.yaml:1` says environments are `values-{env}.yaml`. No justification asked. Observation window: n/a.

**Plan self-check (8 items):**
1. Every item cites evidence; the resize rests on evidence-table row 1 (code and live), not on an `UNVERIFIED` row. Pass.
2. No delete in the plan. Pass.
3. Rollback and command-form success criteria present. Pass.
4. No drift rows. Pass.
5. Path is PR, which fits any delivery model. Pass.
6. `values-prod.yaml` (the one file) and `Deployment/notifyapi` (the one resource) cover the request, nothing else. Pass.
7. Lane basis cited (L2 fails, prod unproven). Pass.
8. Staging exception (a) recorded with evidence. Pass.

Result: 8/8 pass.

### STOP 2 — [F2]

Skill message shown to the operator (research summary and plan together):

```
**Change requested:** Increase replica count from 2 to 4 for notifyapi in prod.
**Service:** notifyapi / **Instance:** prod
**IaC tool(s):** Helm (code: Chart.yaml:1-5) · **Delivery model:** UNVERIFIED, asked below. The repo has no CI config and no Application / Kustomization / HelmRelease object. values-prod.yaml:2 only shows a manual `helm upgrade` command. · **Env selection:** Helm values file per environment, `-f values.yaml -f values-prod.yaml`, namespace notifyapi-prod (code: values-prod.yaml:2, values.yaml:1; catalog: .culiops/service-discovery/notifyapi-prod.md:29)
**Target:** context prod-cluster / namespace notifyapi-prod; account 123456789012 (kubectl config current-context 14:00, aws sts get-caller-identity 14:01)
**Environment tier:** prod=prod (operator-stated, unproven: no pin in the repo) · **Lane (predicted):** full. L2 fails (a Deployment update is not on the light-lane allowlist); prod unproven. Escalations: none.
**Catalog used:** .culiops/service-discovery/notifyapi-prod.md
**Duplicate check:** not done (code: values-prod.yaml:4 = 2; no `replicaCount: 4` in any file; git: no commit with -S'replicaCount: 4'; no branch or open PR)
**Evidence table:** 10 rows (code:/live: cited per row) · drift rows: 0 · unverified rows: 3
  1. replicas 2, ready 2/2: code values-prod.yaml:4, templates/deployment.yaml:10; live deploy 2/2 (14:15), helm get values (14:19): match
  2. rollout strategy RollingUpdate 25% / 25% (live 14:16; no value in code, Kubernetes default): match
  3. requests 250m/256Mi, limits 1/512Mi: code values-prod.yaml:11-15; live 14:17: match
  4. no HPA, no PDB: live 14:22, 14:23; code none: match
  5. release revision 9 deployed, chart notifyapi-1.2.0, last update 2026-04-02: live helm list 14:18
  6. 2 pods Running, 0 restarts, 118m / 104m CPU: live 14:21, 14:24, 14:26
  7. nodes at CPU 31-44%, memory 38-52% (usage): live 14:25. UNVERIFIED that 2 more pods fit by requests.
  8. PrometheusRule monitoring/notifyapi-slo (NotifyApiErrorBudgetBurn, NotifyApiQueueBacklog, NotifyApiPodNotReady) and ServiceMonitor notifyapi exist: live 14:27, 14:28. Outside this chart, not drift.
  9. chart vs live drift by `helm diff` (14:20): the read gave no result (no canned output). UNVERIFIED until the plan command runs on the changed code.
 10. delivery model: UNVERIFIED (asked below)
**Gaps remaining:** delivery model (asked below); drift beyond replicas (the plan run covers it); node fit by requests (`kubectl describe nodes` would resolve it; success criteria 2 and 3 below catch Pending pods); error rate, request rate and firing alerts (need a Prometheus URL the repo and catalog do not give)

**Change plan for notifyapi / prod:**

**Phase 1 of 1: Raise prod replicas from 2 to 4**
- Files: values-prod.yaml (line 4: `replicaCount: 2` -> `4`)
- Resources affected: 1 changed, in place: Deployment/notifyapi (apps), `spec.replicas` 2 -> 4. 0 added, 0 destroyed.
- Blast radius: 1 object in 1 namespace (code: templates/deployment.yaml:10). More consumers on the SQS queue notifyapi-prod-inbound and the SMTP relay (catalog: .culiops/service-discovery/notifyapi-prod.md:34-35, a lead only); their capacity is not read live. No downstream consumers listed (catalog:39, a lead).
- Disruption: none. Existing pods are left running; two pods are added (docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment, 2026-04-24: changing .spec.replicas does not trigger a rollout of the pod template). Live: RollingUpdate 25% / 25%, no PDB, no HPA (14:16, 14:22, 14:23). Step 4a confirms with `plan:` (update in place).
- Rollback path: revert the PR (replicaCount back to 2) and let the pipeline apply it. Or `helm rollback notifyapi 9 -n notifyapi-prod` (a mutation: its own approval; a later pipeline run re-applies merged code, so revert the PR too). Reversible, `untested`. Evidence: live: revision 9 exists (helm list 14:18); docs: replicas is a plain spec field (same page).
- Evidence: rows 1-6 above.
- Success criteria (approving this plan approves these reads, run once the apply has landed):
  1. kubectl rollout status deploy/notifyapi -n notifyapi-prod --timeout=5m -> deployment "notifyapi" successfully rolled out
  2. kubectl get deploy/notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' -> 4/4
  3. kubectl get pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{range .status.containerStatuses[*]}{.restartCount}{"\t"}{end}{"\n"}{end}' -> 4 pods Running, 0 restarts
  4. kubectl top pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -> 4 pods, each at or under 250m CPU and 256Mi memory

**Execution path:** PR (default). After merge it is applied by: not known yet, see the delivery-model question. If you want me to apply directly, say so (this escalates the pre-flight assessment, anti-pattern A4: local workstation apply).
**Staging-first (H7):** (a) no staging env: code: values-prod.yaml is the only per-environment values file; values.yaml:1 says environments are `values-{env}.yaml` · **Observation window:** n/a (no staging)
**Branch:** current `main` -> `iac-change/notifyapi-replicas-4` from `origin/main` @ `a1b2c3d` (fetch, then create)
**Self-check:** 8/8 pass
**Drift (H4):** none
**For pre-flight (L2):** Q1 active incident? Q2 deploy freeze? Q3 peak traffic at the apply time (for CI delivery the apply happens at merge)? Q4 changed this service before? Q5 used Helm before? Q7 anything else? iac-change.4: applied successfully recently? (Q8 is not asked: replicas is on the assessor's not-app-facing list, "Scaling counts alone".) · **Delivery model:** how does this change reach the cluster? values-prod.yaml:2 shows a manual `helm upgrade`; an earlier pre-flight record says "CI on merge". Which is it?

**[F2] Approve this plan?**
```

Operator answer (script entry 2, `[F2]`; stop shown 14:33, answer at 14:38): "Approved. Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none. iac-change.1=yes, iac-change.2=a CI job runs `helm upgrade` on merge (operator-stated), iac-change.3=no (no --set overrides; the env's own values file, values-prod.yaml), iac-change.4=recent. Delivery model: a CI job runs `helm upgrade` on merge (operator-stated). Skip the code gate, show me the diff at the PR step, and don't run pre-flight."

Note: the skill asked Q1-Q5, Q7 and iac-change.4 only. Q6 and iac-change.1-3 were volunteered; the script says those items are said in the stop's answer. Q8 is "if asked" and was not asked, so it is not said.

Skill handles the message (Constraint 15; the rest of the same message still counts):

```
Approved: the plan, the L2 answers and the success-criteria reads. Delivery model recorded: a CI job runs `helm upgrade` on merge (operator-stated), so the PR path is the only path. Tier of prod stays operator-stated.

Waiver: [F3] (code gate) skipped at your request. Recorded as `Waived: F3 — operator, 14:38`. The code summary, the diff and the plan command now come at [F4]. The waiver is also the opt-in for the plan command, so the plan runs without a stop.

Not skipped: pre-flight. H9 says no staging or prod apply without a pre-flight verdict; a PR that CI applies on merge counts, and prod is unproven-tier. I will reuse the 10:30 record if it matches this plan's hash, the target and the 24 h window (Step 4b), otherwise I run pre-flight inline. Either way you see the verdict at [F4].
```

---

## Step 3 — Implement

Branch commands (approved at `[F2]`):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:38 | `git fetch origin main` | `empty.txt` | (no output) |
| 14:39 | `git switch -c iac-change/notifyapi-replicas-4 origin/main` | `git-switch.txt` | `Switched to a new branch 'iac-change/notifyapi-replicas-4'` |
| 14:40 | `git branch --show-current` | `git-branch-after-switch.txt` | `iac-change/notifyapi-replicas-4` |

Code written (values-prod.yaml, one hunk):

```diff
--- a/values-prod.yaml
+++ b/values-prod.yaml
@@ -1,7 +1,7 @@
 # Prod overrides — applied on top of values.yaml
 # To change: helm upgrade notifyapi . -f values.yaml -f values-prod.yaml
 
-replicaCount: 2
+replicaCount: 4
 
 image:
   tag: "v3.1.0"
```

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:41 | `git status --short` | answered from the diff | ` M values-prod.yaml` |
| 14:42 | `git diff` | answered from the diff | the diff above |
| 14:43 | `helm lint . -f values.yaml -f values-prod.yaml` (the repo's local check, shown before running, no credentials or network) | `helm-lint.txt` | `[INFO] Chart.yaml: icon is recommended` / `1 chart(s) linted, 0 chart(s) failed` |

**Diff self-check (6 items):** (1) scope: only `values-prod.yaml`, which is in the approved file list, and it changed; (2) plan to hunk: Deployment/notifyapi `replicas` update maps to the `values-prod.yaml:4` hunk, and the hunk maps to that plan item; (3) conventions: same key and form as `code: values-prod.yaml:4` (`replicaCount: <integer>`), consumed at `code: templates/deployment.yaml:10`; (4) no silent safety change (no `replicas: 0`, no removed limits, nothing from the list); (5) no secrets, no `tfplan` / state / `.terraform/`, `git status --short` shows only the one file; (6) `helm lint` clean. Result: 6/6 pass.

**Fresh eyes:** `fresh-eyes: not run — dry run`. The change is an update, not add-only, so the skip rule (SKILL.md:310) does not apply and the review would run.

E1-E3 on the diff are a light-lane step (SKILL.md:307); the lane is full, so not run.

`[F3]` is waived (14:38): no stop here. The code summary and the plan command move to `[F4]`.

---

## Step 4 — Execute

### 4a — Plan output

**Target re-check (Constraint 10, no stop).**

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:44 | `kubectl config current-context` | `kubectl-context.txt` | `prod-cluster` |
| 14:45 | `aws sts get-caller-identity` | `identity-prod.json` | account `123456789012`, role `paymentapi-operator` |

Both match the target shown at `[F1]` (no pin exists, so the comparison is with the first read, SKILL.md:344). No `[H1]`.

**Plan (mode 1, the skill runs it; the recorded `[F3]` waiver is the opt-in).**

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:46 | `helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml` | `helm-diff.txt` | `notifyapi, notifyapi, Deployment (apps) has changed:` with one hunk, `-   replicas: 2` / `+   replicas: 4`. Environment: the command carries `-n notifyapi-prod` (rule 1a). |

Canned plan versus code: they agree (replicas 2 to 4, nothing else).

**Cross-check against the evidence table.** One resource, `Deployment/notifyapi`, action update in place. It is in the approved phase and its action matches the approved disruption (`none`, an in-place `spec.replicas` change); `plan:` Deployment/notifyapi update in place confirms it. No destroy or replace (no `[H3]`). No other object changed, so the `helm diff` also closes the drift gap from read 6: no drift beyond `replicas` (no `[H4]`). Gap (b) is resolved.

**Lane confirmed from the plan output:** full (L1 holds, L2 still fails: Deployment update off the allowlist). No downgrade.

**Parity check (H3):** no staging phase ran (exception (a)) -> `Parity check: n/a`. No `[H3]`.

### 4b — Pre-flight (H9)

Not dev lane, so check `.culiops/pre-flight/` for a reusable record: `notifyapi-config-update-20260424-1030.md`.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:47 | `sha256sum <scratch file holding the helm diff text>` (scratch file written outside the repo and deleted afterwards; simulated, no lookup) | INDEX Plan hash bullet | `sha256:9f2c4e…` |

Match rule (SKILL.md:364):
- (a) plan hash: record `sha256:9f2c4e…` equals the current `sha256:9f2c4e…`. Match.
- (b) target: record `context prod-cluster / namespace notifyapi-prod`; current `prod-cluster / notifyapi-prod`. Match.
- (c) freshness: record dated 2026-04-24 10:30; now 14:47, 4 h 17 min old, inside the 24 h window. Match.

Match found: reuse. Categories 5 and 10 re-ask (SKILL.md:365). Q1-Q3 from `[F2]`: no / no / no, the same as the record's L2 (no incident, no freeze, not peak). Category-10 reads re-run now (they were approved in the `[F1]` batch):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:48 | `kubectl get deploy/notifyapi -n notifyapi-prod -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'` | `deploy-notifyapi-prod.json` (before) | `2/2` |
| 14:49 | `kubectl get pods -n notifyapi-prod -l app.kubernetes.io/name=notifyapi -o jsonpath='...restartCount...'` | `pods-notifyapi-prod.json` (before) | 2 pods, 0 restarts each |
| 14:50 | `kubectl top nodes` | `kubectl-top-nodes.txt` | 3 nodes, CPU 31-44%, memory 38-52% |

Both the answers and the reads are the same as in the record, so the record stands; pre-flight is not re-run and no pre-flight stop occurs. Verdict carried to `[F4]`: `GREEN — PROCEED`. The record is shown as reused in `preflight-record.md`. (Observation: the reused record scores 10 categories; `pre-flight/SKILL.md:47-59` now has 11. The match rule does not check that, so the record is reused as it is.)

Direct-apply escalation: not applicable (PR path).

### 4c — Execute (PR path)

H7 check before `[F4]` (the PR applies prod on merge): exception (a), no staging env, recorded with evidence. No `[H7]` stop.

Staging by explicit path, then the PR action:

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:51 | `git add values-prod.yaml` | `empty.txt` | (no output) |
| 14:52 | `git status --short` | answered from the diff | `M  values-prod.yaml` |

### STOP 3 — [F4]

Skill message shown to the operator:

```
[F3] was waived at your request (Waived: F3 — operator, 14:38), so the code, the diff and the plan command are here.

**Code changes for Phase 1 of 1:**
**Modified:** values-prod.yaml — `replicaCount` 2 -> 4 (line 4), the prod override that templates/deployment.yaml:10 renders into `spec.replicas`
**Plan <-> hunk:** Deployment/notifyapi `spec.replicas` 2 -> 4 -> values-prod.yaml:4
**Self-check:** 6/6 pass · **Fresh eyes:** not run — dry run
**Target:** context prod-cluster / namespace notifyapi-prod; account 123456789012, role paymentapi-operator (re-checked 14:44, 14:45) · `-f values.yaml -f values-prod.yaml` · tier prod=prod (operator-stated)
**Plan command (4a, ran 14:46 under your F3 waiver):** helm diff upgrade notifyapi . -n notifyapi-prod -f values.yaml -f values-prod.yaml
**Plan output:** 1 object changed, update in place: Deployment/notifyapi, `spec.replicas` 2 -> 4. 0 added, 0 destroyed. Nothing else differs, so there is no drift. Disruption none, as planned. Plan hash sha256:9f2c4e…

Diff (git diff):
--- a/values-prod.yaml
+++ b/values-prod.yaml
@@ -1,7 +1,7 @@
 # Prod overrides — applied on top of values.yaml
 # To change: helm upgrade notifyapi . -f values.yaml -f values-prod.yaml
 
-replicaCount: 2
+replicaCount: 4
 
 image:
   tag: "v3.1.0"

**Open the PR?** On branch iac-change/notifyapi-replicas-4 (from origin/main), staged only this file: values-prod.yaml. On approval: commit, push, and open a PR.
git status --short after staging: `M  values-prod.yaml` (no tfplan / state / .terraform/ / unrelated files)
Target: prod-cluster / notifyapi-prod · **Pre-flight verdict:** Using existing pre-flight record from .culiops/pre-flight/notifyapi-config-update-20260424-1030.md (verdict: GREEN — PROCEED). It assessed this exact plan (hash sha256:9f2c4e…) on this target, 4 h 17 min ago. Q1-Q3 re-asked at [F2]: unchanged. Category-10 reads re-run 14:48-14:50: 2/2 ready, 0 restarts, nodes 31-44% CPU / 38-52% memory: unchanged. No Yellow or unknown findings to acknowledge. You asked me not to run pre-flight; it was not re-run, and H9 is met by this record. Approving here acknowledges the verdict.
PR will include: change summary, evidence table, pre-flight verdict, the `Staging-first:` line (n/a — no staging env), execution record link.
Heads-up: say so and I draft one for the notifyapi owners / #notifications-oncall with change-comms (draft-only; you send it).

**[F4] Open the PR?**
```

Operator answer (script entry 3, `[F4]`; stop shown 14:53, answer at 14:58): "Approved: open the PR. Skip the heads-up line."

Heads-up declined; no change-comms draft.

PR path, on approval (no repo PR template exists, so the skill's own PR body is used; commit subject follows the repo style seen in `git-log-recent.txt`, `notifyapi: <lowercase description>`):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 14:58 | `git commit -m "notifyapi: raise prod replicas from 2 to 4"` | `git-commit.txt` | `[iac-change/notifyapi-replicas-4 7f3a9c1] notifyapi: raise prod replicas from 2 to 4` / ` 1 file changed, 1 insertion(+), 1 deletion(-)` |
| 14:59 | `git push -u origin iac-change/notifyapi-replicas-4` | `git-push.txt` | `* [new branch]      iac-change/notifyapi-replicas-4 -> iac-change/notifyapi-replicas-4` (and the create-a-PR hint) |
| 15:00 | `gh pr create --base main --head iac-change/notifyapi-replicas-4 --title "notifyapi: raise prod replicas from 2 to 4" --body <body>` | `gh-pr-create.txt` | `https://github.com/acme/notifyapi/pull/57` |

PR body (summary): change summary (replicaCount 2 -> 4 in prod, Deployment/notifyapi update in place, disruption none); the evidence table (10 rows, 0 drift); pre-flight verdict (reused record, GREEN — PROCEED, hash `sha256:9f2c4e…`); `**Staging-first:** n/a — no staging env (code: values-prod.yaml is the only per-environment values file; values.yaml:1)`; execution record link `.culiops/iac-change-execution/notifyapi-replicas-20260424-1501.md` (not committed; written after the PR opens). No plan text, state or secret values.

Operator report: PR URL `https://github.com/acme/notifyapi/pull/57`.

---

## Step 5 — Verify and record

**5a (PR path, CI applies on merge, operator-stated).** "PR https://github.com/acme/notifyapi/pull/57 created. After merge, the CI job that runs `helm upgrade` applies it." The apply has not landed, so the success criteria are not run. The record says `Applied: no — PR open`.

**5b.** Execution record written at 15:01 to `.culiops/iac-change-execution/notifyapi-replicas-20260424-1501.md`: see `record.md`. The reused pre-flight record is shown in `preflight-record.md`.

**Final message shown to the operator:**

```
Outcome: PR opened, not applied. https://github.com/acme/notifyapi/pull/57 raises prod replicaCount from 2 to 4 (Deployment/notifyapi, update in place, disruption none). Pre-flight: reused record, GREEN — PROCEED. Staging-first: n/a, no staging env. Waived: F3.
Record: .culiops/iac-change-execution/notifyapi-replicas-20260424-1501.md
Next: commit the record (.culiops/iac-change-execution/notifyapi-replicas-20260424-1501.md) · draft the result or ticket-close message with change-comms · tell me when the apply lands and I run the success criteria
```

---

## Ambiguities in the skill text and lookups without canned output

1. **`no canned output`: one lookup.** Read 6 at 14:20, `helm diff upgrade ... ` as the Step 1 drift check (SKILL.md:199). The only row for it is the plan row, valid for the changed code; the code was unchanged then. Treated as failed; the 4a plan covered the gap.
2. **Delivery model sources (SKILL.md:185-188).** The text names the README; the protocol forbids reading the fixture's README. `values-prod.yaml:2` hints at a manual apply; the earlier record says CI on merge. Taken as `UNVERIFIED` and asked inside `[F2]` (SKILL.md:188).
3. **Reused record with 10 categories (SKILL.md:364-365).** The match rule checks hash, target and age only; it does not check that the record scored all 11 current categories. Reused as the text reads.
4. **Q6 (SKILL.md:280, lanes.md:147).** The caller block lists Q1-Q5 and Q7 plus `iac-change.4`, so the skill did not ask Q6 or `iac-change.1-3`; the script volunteered them anyway.
5. **Identity read set (SKILL.md:169).** The text lists both `aws sts get-caller-identity` and `kubectl config current-context`; both were run, at Step 1 and again at 4a.
6. **Output root (SKILL.md:35).** `CULIOPS_HOME` read as unset without a lookup (none exists for it).
7. **Prerequisites in the record preamble (SKILL.md:502).** Client versions were read locally; the cluster's server version (`kubectl version` contacts the cluster, a live read) was not in the approved batch, so the +-1 minor check is not verified.
