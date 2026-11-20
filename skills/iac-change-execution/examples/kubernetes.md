# Examples: Kubernetes CLI Templates for `iac-change-execution`

Reference command templates for the `iac-change-execution` skill when the target workloads are managed by Kubernetes tooling — Helm, Kustomize, or raw manifests. These templates apply to EKS and to self-managed / on-premises clusters. For EKS, use alongside `aws.md` for cluster-level cloud operations.

Replace placeholders (`{namespace}`, `{release}`, `{chart}`, `{image-tag}`, `{values-file}`, etc.) with the values resolved in Step 1 research or detected from the plan output.

## Prerequisites

**CLI tools:**
- `kubectl` — must be within ±1 minor version of the cluster's Kubernetes version. Verify: `kubectl version --client`.
- `helm` >= 3.x for Helm-managed releases. Verify: `helm version`.
- `kustomize` for Kustomize-managed overlays (standalone CLI preferred over `kubectl kustomize`). Verify: `kustomize version`.

**Authentication (kubeconfig):** The operator must have a valid kubeconfig context pointing to the target cluster before running any command.

- EKS: `aws eks update-kubeconfig --name {cluster} --region {region}`
- On-premises / self-managed: obtain kubeconfig from the cluster administrator.

Confirm active context: `kubectl config current-context`.

**Least-privilege RBAC — TWO tiers are required for this skill.**

- **Tier 1 (Steps 1 and 5 — read-only):** Kubernetes `ClusterRole` named `view` (built-in) bound to the operator's identity, or a namespace-scoped `Role` with `get`, `list`, `watch` on the relevant resource types. Never use `cluster-admin` or any `*` verb binding for read-only operations.
- **Tier 2 (Step 4 — mutation only):** a namespace-scoped `Role` or `ClusterRole` with only the `create`, `update`, `patch`, `delete` verbs on the specific resource types the change modifies (e.g., `deployments`, `configmaps`, `services`). Elevated binding must cover only the target namespace. Drop the elevated binding after the mutation completes.

**Helm releases:** Helm stores release metadata as Kubernetes Secrets in the target namespace. Read access to Secrets in that namespace is required for `helm status`, `helm get`, and `helm history`.

**Metrics backend (optional, for the health snapshot):** `$PROM_URL` is the Prometheus or Thanos / Mimir query endpoint, as in `skills/pre-flight/examples/kubernetes.md`. Reaching it from inside the cluster with `kubectl port-forward` or `kubectl exec` is beyond `view`; show the operator what is needed and do not request it by default. With no reachable backend, run none of the PromQL reads below.

---

## Research Queries (Step 1 — Read-Only)

### Deployment — current config

- Deployment details: `kubectl get deploy {deploy} -n {namespace} -o yaml` (inline `env[].value` entries can hold credentials — summarize env var names, don't echo values)
- Deployment summary: `kubectl describe deploy/{deploy} -n {namespace}`
- Deployment strategy: `kubectl get deploy {deploy} -n {namespace} -o jsonpath='{.spec.strategy}'`
- Replica count: `kubectl get deploy {deploy} -n {namespace} -o jsonpath='{.spec.replicas}'`

### Service and Ingress — current network config

- Service details: `kubectl get svc {service} -n {namespace} -o yaml`
- Ingress details: `kubectl get ingress {ingress} -n {namespace} -o yaml`
- Endpoints backing the service: `kubectl get endpoints {service} -n {namespace}`

### ConfigMap — current configuration

- ConfigMap contents: `kubectl get configmap {configmap} -n {namespace} -o yaml`
- List ConfigMaps in namespace: `kubectl get configmaps -n {namespace}`

### HPA — current autoscaling config

- HPA details: `kubectl get hpa {hpa} -n {namespace} -o yaml`
- HPA status (current vs min/max replicas): `kubectl describe hpa/{hpa} -n {namespace}`

### Current image — running version

- Current image in deployment: `kubectl get deploy {deploy} -n {namespace} -o jsonpath='{.spec.template.spec.containers[*].image}'`
- Pod images currently running: `kubectl get pods -n {namespace} -l app={service} -o jsonpath='{.items[*].spec.containers[*].image}'`

### Helm release — values and history

- Current release values: `helm get values {release} -n {namespace}`
- All values (including defaults): `helm get values {release} -n {namespace} --all`
- **Values and manifests can contain secrets** (DB passwords, API keys passed as values; rendered `Secret` objects with base64 `data`). Base64 is not encryption. Report key names only, and redact values before writing anything to the execution record.
- Release metadata and chart version: `helm status {release} -n {namespace}`
- Release history: `helm history {release} -n {namespace}`
- Rendered manifests for the current release, excluding Secrets: `helm get manifest {release} -n {namespace} | yq 'select(.kind != "Secret")'`

---

## Verification Checks (Step 5 — Read-Only)

### Deployment rollout status — post-apply health

- Rollout status (blocks until complete or timeout): `kubectl rollout status deploy/{deploy} -n {namespace} --timeout=5m`
- Ready replicas vs desired: `kubectl get deploy {deploy} -n {namespace} -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'`
- Rollout history: `kubectl rollout history deploy/{deploy} -n {namespace}`

### Pod status — individual pod health

- Pod list with status: `kubectl get pods -n {namespace} -l app={service} -o wide`
- Pod details (events, conditions): `kubectl describe pod/{pod} -n {namespace}`
- Recent events for namespace: `kubectl get events -n {namespace} --sort-by='.lastTimestamp' | tail -30`

### Helm release status — post-upgrade state

- Release status (expect `deployed`): `helm status {release} -n {namespace}`
- Manifest diff from previous revision: `helm diff revision {release} {prev-revision} {new-revision} -n {namespace}` (requires `helm-diff` plugin)

### Endpoints — traffic routing health

- Endpoint readiness (expect all addresses populated): `kubectl get endpoints {service} -n {namespace}`
- Ingress backend health: `kubectl describe ingress {ingress} -n {namespace}`

### Pod logs — error detection

- Recent logs for a pod: `kubectl logs {pod} -n {namespace} --tail=100`
- Logs filtered for errors: `kubectl logs {pod} -n {namespace} --tail=200 | grep -i error`
- Previous pod logs (if pod restarted): `kubectl logs {pod} -n {namespace} --previous --tail=100`

### Resource usage — saturation check

- Pod CPU and memory (requires metrics-server): `kubectl top pods -n {namespace} -l app={service}`
- Node resource usage: `kubectl top nodes`

---

## Health Snapshot (S0 / S1 / S2 — Read-Only)

Read templates for the health snapshot. The rules (the snapshot set, windows, waits, verdicts, and what each read feeds) are in `snapshot.md`; this section holds only the commands. Every command here is read-only and runs in a batch the operator already approves. Run each `kubectl` read once per namespace and the PromQL set once per backend, not once per member. Project only the fields shown: no `-o yaml`, no Secret values.

### Readiness, restarts, warnings and HPA (point-in-time)

- Ready vs desired, Deployments and StatefulSets together: `kubectl get deploy,sts -n {namespace} -o custom-columns=KIND:.kind,NAME:.metadata.name,DESIRED:.spec.replicas,READY:.status.readyReplicas`. `<none>` under `READY` is an absent field, which means 0 ready (inferred). `docs: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/ (read 2026-11-18)`: `readyReplicas` is the "Total number of non-terminating pods targeted by this Deployment with a Ready Condition."; `replicas` is the "Number of desired pods." `docs: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/stateful-set-v1/ (read 2026-11-18)`: `readyReplicas` is "the number of pods created for this StatefulSet with a Ready Condition."
- Pod restarts, per pod and container: `kubectl get pods -n {namespace} -l app={service} -o custom-columns=POD:.metadata.name,PHASE:.status.phase,RESTARTS:.status.containerStatuses[*].restartCount`. A pod the rollout creates has its own count, so S2 reads the current pods (inferred). `docs: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/ (read 2026-11-18)`: `containerStatuses` holds the "Statuses of containers in this pod."
- Recent `Warning` events, no message text: `kubectl get events -n {namespace} --field-selector type=Warning --sort-by=.lastTimestamp -o custom-columns=LAST:.lastTimestamp,KIND:.involvedObject.kind,OBJECT:.involvedObject.name,REASON:.reason,COUNT:.count`. `docs: https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/ (read 2026-11-18)`: `type` is the "Type of this event (Normal, Warning), new types could be added in the future". `docs: https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/ (read 2026-11-18)`: "Supported field selectors vary by Kubernetes resource type." If the API server rejects `type`, drop the selector, add `TYPE:.type` to the columns and filter locally.
- Events expire, so an empty list says little about the past. `docs: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/ (read 2026-11-18)`: `--event-ttl duration`, "Amount of time to retain events.", "Default: 1h0m0s".
- HPA: `kubectl get hpa -n {namespace} -o custom-columns=NAME:.metadata.name,TARGET:.spec.scaleTargetRef.name,CURRENT:.status.currentReplicas,DESIRED:.status.desiredReplicas,MAX:.spec.maxReplicas`. `docs: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/ (read 2026-11-18)`: `currentReplicas` is the "current number of replicas of pods managed by this autoscaler, as last seen by the autoscaler."; `desiredReplicas` is the "desired number of replicas of pods managed by this autoscaler, as last calculated by the autoscaler."; `maxReplicas` is "the upper limit for the number of replicas to which the autoscaler can scale up."

### Firing alerts and metrics (when `$PROM_URL` is set)

Metric and label names below are examples (the `http_requests_total` family, as in `skills/pre-flight/examples/kubernetes.md`). Adapt them to the names the stack uses; the service-discovery catalog may list them. With no backend, run none of this: the members say `no metrics backend — point-in-time only` (`snapshot.md › Signals`).

- Firing alerts, labels only; filter locally to the snapshot set by namespace and workload labels: `curl -s "$PROM_URL/api/v1/alerts" | jq -c '[.data.alerts[] | select(.state=="firing") | .labels]'`. `docs: https://prometheus.io/docs/prometheus/latest/querying/api/ (read 2026-11-18)`: "The `/alerts` endpoint returns a list of all active alerts."
- **S0 / S1 form** (and the "before" read): request rate, error ratio and p95 latency over the hour ending now and over the same hour last week, in one command (one expression per line; the `offset 1w` lines are last week). The `[1h]` range is for S0, S1 and "before" only, never S2:

  ```bash
  printf '%s\n' \
    'sum(rate(http_requests_total{service="{service}"}[1h]))' \
    'sum(rate(http_requests_total{service="{service}"}[1h] offset 1w))' \
    '(sum(rate(http_requests_total{service="{service}",code=~"5.."}[1h])) or vector(0)) / sum(rate(http_requests_total{service="{service}"}[1h]))' \
    '(sum(rate(http_requests_total{service="{service}",code=~"5.."}[1h] offset 1w)) or vector(0)) / sum(rate(http_requests_total{service="{service}"}[1h] offset 1w))' \
    'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{service="{service}"}[1h])))' \
    'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{service="{service}"}[1h] offset 1w)))' \
  | while IFS= read -r q; do echo "# $q"; curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=$q" | jq -c '.data.result'; done
  ```

- **S2 form**: the range is the minutes since `{rollout-complete}`, so the window holds only post-apply data. A `[1h]` range at S2 is mostly pre-apply data and would dilute a regression into `ok`. `{n}` is those minutes (at least 10, at most 30 after the rollout), evaluated at now. The last expression is the absolute 5xx count of the after window, for the floor of at least 5 errors:

  ```bash
  printf '%s\n' \
    'sum(rate(http_requests_total{service="{service}"}[{n}m]))' \
    '(sum(rate(http_requests_total{service="{service}",code=~"5.."}[{n}m])) or vector(0)) / sum(rate(http_requests_total{service="{service}"}[{n}m]))' \
    'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{service="{service}"}[{n}m])))' \
    'sum(increase(http_requests_total{service="{service}",code=~"5.."}[{n}m])) or vector(0)' \
  | while IFS= read -r q; do echo "# $q"; curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=$q" | jq -c '.data.result'; done
  ```

  - `docs: https://prometheus.io/docs/prometheus/latest/querying/basics/ (read 2026-11-18)`: "The `offset` modifier allows changing the time offset for individual instant and range vectors in a query."; "the `offset` modifier always needs to follow the selector immediately". `docs: https://prometheus.io/docs/prometheus/latest/querying/functions/ (read 2026-11-18)`: `rate()` "calculates the per-second average rate of increase of the time series in the range vector."; `histogram_quantile()` "calculates the φ-quantile (0 ≤ φ ≤ 1) from a classic histogram or from a native histogram."; `vector()` "converts the scalar `s` to a float sample and returns it as a single-element instant vector with no labels." `docs: https://prometheus.io/docs/prometheus/latest/querying/operators/ (read 2026-11-18)`: "vector1 or vector2 results in a vector that contains all original elements (label sets + values) of vector1" and "additionally all elements of vector2 which do not have matching label sets in vector1."
  - `or vector(0)` is the counterpart of `FILL(…, 0)`: with no 5xx series the sum is empty, and the ratio would be empty too, hiding a healthy zero. The request-rate expression has no such fill. An empty `[]` is `no data` only when the denominator (or the request rate) is empty. A p95 of `NaN` (a window with no observations) is `no data`, never a value to compare. `docs: https://prometheus.io/docs/prometheus/latest/querying/functions/ (read 2026-11-18)`: `histogram_quantile()`: "If `b` has 0 observations, `NaN` is returned." Show the expression beside each value.
  - Per-second rates, ratios and the quantile compare as they are, in S0 / S1 and S2 alike (a per-second rate differs from a per-minute one by a constant factor of 60, so the comparison and the 1.5× ratio are unchanged). The absolute `increase()` count is the only count: it feeds the floor, not a comparison.
- **Peak hours** (PR / CI path, when Q3 needs `peak hours: HH–HH`): the hourly request counts of the last 7 days, from whole-hour `{H-7d}` to `{H}` (now, rounded down to the hour). Each point is the count for the hour ending at its timestamp (UTC; label the result UTC, or convert it): `curl -sG "$PROM_URL/api/v1/query_range" --data-urlencode 'query=sum(increase(http_requests_total{service="{service}"}[1h]))' --data-urlencode "start={H-7d}" --data-urlencode "end={H}" --data-urlencode "step=3600" | jq -c '.data.result'`. `docs: https://prometheus.io/docs/prometheus/latest/querying/api/ (read 2026-11-18)`: `start=<rfc3339 | unix_timestamp>`: "Start timestamp, inclusive."; `end`: "End timestamp, inclusive."; `step=<duration | float>`: "Query resolution step width in `duration` format or float number of seconds."
- **"Before" on the PR / CI path** (read after the fact, ending at the apply time): run the S0 / S1 form above with `--data-urlencode "time={apply-time}"` added to the `curl`; the `offset 1w` lines are then the week before the apply. `docs: https://prometheus.io/docs/prometheus/latest/querying/api/ (read 2026-11-18)`: `time=<rfc3339 | unix_timestamp>`: "Evaluation timestamp. Optional." Point-in-time state cannot be read back (`snapshot.md › When snapshots run`).
- **Retention bounds the read-back.** `docs: https://prometheus.io/docs/prometheus/latest/storage/ (read 2026-11-18)`: for `--storage.tsdb.retention.time`, "If neither this flag nor `storage.tsdb.retention.size` is set, the retention time defaults to `15d`." A backend with shorter retention than the window gives shorter evidence: say how far it reaches.

### Wait before S2

- Deployment: `kubectl rollout status deploy/{deploy} -n {namespace} --timeout=5m`. StatefulSet: `kubectl rollout status sts/{sts} -n {namespace} --timeout=5m`. `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_status/ (read 2026-11-18)`: `--watch` "Watch the status of the rollout until it's done."; `--timeout`: "The length of time to wait before ending watch, zero means never." A watch that ends at `--timeout` is not a completed rollout. `docs: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/ (read 2026-11-18)`: valid resource types include "deployments", "daemonsets", "statefulsets".

### Automation lag (feeds `iac-change.4`)

- Helm release history: `helm history {release} -n {namespace} --max 5`. This needs `secrets` get/list in the namespace (Prerequisites › Helm releases), which also exposes every other Secret there. Record only revision, status and date. `docs: https://helm.sh/docs/helm/helm_history/ (read 2026-11-18)`: "History prints historical revisions for a given release."; `--max`: "maximum number of revision to include in history (default 256)".
- CI history and the Terraform state object: `examples/aws.md › Health Snapshot › Automation lag`.

### Sibling app-source search (only when Step 1 predicts an app-facing change)

The commands are in `examples/aws.md › Health Snapshot › Sibling app-source search`. The deployed ref to compare against is Research Queries → Current image in this file.

---

## Apply Commands (Step 4c — MUTATION)

Each command below changes cluster state. The skill presents each command to the operator and waits for explicit approval before running. Assume Tier 2 elevated RBAC permissions are active.

### Helm — upgrade an existing release

**MUTATION** — `helm upgrade {release} {chart} -n {namespace} -f {values-file} --version {chart-version} --atomic --timeout 5m` (Helm 4 renamed `--atomic` to `--rollback-on-failure`; check `helm version` and use the matching flag)
- Blast radius: all Kubernetes resources managed by the release (Deployments, Services, ConfigMaps, etc.); running pods in the namespace are restarted according to the deployment strategy.
- Elevated permission required: namespace-scoped `Role` with `create`, `update`, `patch`, `delete` on `deployments`, `services`, `configmaps`, and any other resource types the chart manages.
- Rollback path: `helm rollback {release} {prev-revision} -n {namespace}` — rolls back to the specified previous revision. `--atomic` / `--rollback-on-failure` auto-rolls back if the upgrade fails before `--timeout` elapses. Set `--timeout` longer than the chart's slowest hook (e.g. DB migration jobs) or a healthy-but-slow upgrade gets rolled back mid-migration.
- Note: always run `helm diff upgrade {release} {chart} -f {values-file}` (Step 4a) and review before approving the upgrade.

### Helm — install a new release

**MUTATION** — `helm install {release} {chart} -n {namespace} -f {values-file} --version {chart-version} --create-namespace`
- Blast radius: new Kubernetes resources created by the chart; no existing resources are modified. Namespace is created if it does not exist (when `--create-namespace` is used).
- Elevated permission required: namespace-scoped `Role` (or `ClusterRole` if the chart creates cluster-scoped resources) with `create` on the resource types the chart installs.
- Rollback path: `helm uninstall {release} -n {namespace}` to remove the release entirely. Note: PersistentVolumeClaims are not deleted by `helm uninstall` by default.

### Kustomize — apply an overlay

**MUTATION** — `kubectl apply -k {overlay-path}`
- Blast radius: all resources in the Kustomize overlay; existing resources with matching names are patched in-place. Review `kubectl diff -k {overlay-path}` (Step 4a) before approving.
- Elevated permission required: namespace-scoped `Role` with `create`, `update`, `patch` on the resource types in the overlay (typically `deployments`, `configmaps`, `services`, `ingresses`).
- Rollback path: revert the overlay files in the repo and re-apply (`kubectl apply -k {overlay-path}`). For Deployments / StatefulSets / DaemonSets, `kubectl rollout undo {kind}/{name} -n {namespace}` restores the previous pod template (it does not revert ConfigMaps, Services, or other objects).

### Raw manifest — apply a single manifest

**MUTATION** — `kubectl apply -f {manifest-file} -n {namespace}`
- Blast radius: only the resources defined in the manifest file. Review `kubectl diff -f {manifest-file}` (Step 4a) before approving.
- Elevated permission required: namespace-scoped `Role` with `create`, `update`, `patch` on the specific resource types in the manifest.
- Rollback path: apply the previous version of the manifest (`kubectl apply -f {prev-manifest-file}`); for workload pod-template changes, `kubectl rollout undo {kind}/{name} -n {namespace}`. **Never use `kubectl delete -f {manifest-file}` as a rollback** when the file contains any resource that existed before the apply — it deletes those pre-existing production objects too. Delete only the specific objects the change newly created, by name.

---

## Placeholder Reference

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{namespace}` | Kubernetes namespace | `production` |
| `{deploy}` | Deployment name | `widgetapi-web` |
| `{service}` | Service name (and label selector value) | `widgetapi-web` |
| `{ingress}` | Ingress name | `widgetapi-web-ingress` |
| `{configmap}` | ConfigMap name | `widgetapi-config` |
| `{hpa}` | HorizontalPodAutoscaler name | `widgetapi-web-hpa` |
| `{pod}` | Pod name (from `kubectl get pods`) | `widgetapi-web-abc12-xyz34` |
| `{release}` | Helm release name | `widgetapi-web` |
| `{chart}` | Helm chart reference | `oci://registry.example.com/charts/widgetapi` |
| `{chart-version}` | Helm chart version | `1.4.2` |
| `{values-file}` | Path to Helm values file | `./helm/values-prod.yaml` |
| `{overlay-path}` | Path to Kustomize overlay directory | `./k8s/overlays/prod` |
| `{manifest-file}` | Path to a raw Kubernetes manifest | `./k8s/manifests/deployment.yaml` |
| `{image-tag}` | Container image tag | `sha256:abc123` or `v1.4.2` |
| `{sts}` | StatefulSet name | `widgetapi-db` |
| `{H}`, `{H-7d}` | Now rounded down to the whole hour (UTC), and 7 days before that (Health Snapshot) | `2026-04-24T10:00:00Z`, `2026-04-17T10:00:00Z` |
| `{n}`, `{rollout-complete}` | Whole minutes since the rollout completed, and when it completed (Health Snapshot S2) | `12`, `2026-04-24T10:00:00Z` |
| `{apply-time}` | When the apply landed (Health Snapshot) | `2026-04-24T10:00:00Z` |
| `{prev-revision}` | Previous Helm revision number | `3` |
| `{new-revision}` | New Helm revision number | `4` |
| `{cluster}`, `{region}`, `{project}`, `{rg}` | Cloud-specific identifiers (see cloud examples file) | — |
