# Canned output index — helm-config-update

Lookup rules are in `../../DRY-RUN-PROTOCOL.md` (rule 1). Rows that share a pattern are told apart by the environment and the state in their `Use when` column.

- **Dry-run clock:** starts 2026-04-24 14:00 +07:00 (07:00Z). The existing pre-flight record in `.culiops/pre-flight/` was written the same day at 10:30, so it is inside a 24-hour freshness window.
- **Identity:** `kubectl config current-context` returns `prod-cluster`, the context the existing pre-flight record names. `aws sts get-caller-identity` returns account `123456789012`, the account the catalog and the SQS queue URL in `values-prod.yaml` name.
- **Namespace:** `notifyapi-prod`. Every read is for prod. There is no Argo CD or Flux in the cluster.
- **Plan hash.** `helm-diff.txt` is the diff that the existing pre-flight record assessed. The record prints its hash shortened, as `sha256:9f2c4e…`. When the skill hashes `helm-diff.txt`, the runner gives `sha256:9f2c4e…` and treats it as equal to the record's hash.
- **State.** *Before* means nothing has been applied. *After* means the release has been upgraded (the CI job ran after merge, or the skill ran the upgrade).

## Identity

| Command pattern | Canned file | Use when |
|---|---|---|
| `kubectl config current-context` | `kubectl-context.txt` | always |
| `aws sts get-caller-identity` | `identity-prod.json` | always. Account 123456789012 |

## Git and GitHub (simulated)

| Command pattern | Canned file | Use when |
|---|---|---|
| `git branch --show-current` | `git-branch.txt` | before the skill switches branch: the default branch, `main` |
| `git branch --show-current` | `git-branch-after-switch.txt` | after `git switch -c <name>` or `git checkout -b <name>`: that new branch. The runner puts `<name>` where `<branch>` stands |
| `git status` | `git-status-clean.txt` | always, before the skill writes code. `git status --short` prints nothing |
| `git fetch origin *` | `empty.txt` | always (no output) |
| `git remote get-url origin` | `git-remote.txt` | always |
| `git rev-parse *` | `git-rev-parse.txt` | always. `--short` gives the first 7 characters, `a1b2c3d` |
| `git log * --since=*` | `empty.txt` | change velocity: no commit touched the changed paths in the window |
| `git log * --grep=*` | `empty.txt` | duplicate check by ticket key: no hits |
| `git log * -S*` | `empty.txt` | duplicate check by identifier: no hits |
| `git log *` | `git-log-recent.txt` | any other `git log` (all three commits are older than 30 days) |
| `git branch -a --list *` | `empty.txt` | duplicate check for an in-flight branch: none |
| `git branch -a` | `git-branches.txt` | always |
| `gh pr list *` | `gh-pr-list-empty.txt` | duplicate check for an in-flight PR: none |
| `git switch -c *`, `git checkout -b *` | `git-switch.txt` | the runner puts the real branch name where `<branch>` stands |
| `git add *` | `empty.txt` | no output |
| `git commit *` | `git-commit.txt` | the runner fills in the branch, subject and counts |
| `git push *` | `git-push.txt` | the runner fills in the branch |
| `gh pr create *` | `gh-pr-create.txt` | the PR URL |

## Tool versions

| Command pattern | Canned file | Use when |
|---|---|---|
| `helm version*` | `helm-version.txt` | always |
| `kubectl version*` | `kubectl-version.txt` | always |
| `aws --version` | `aws-version.txt` | always |

## Helm

| Command pattern | Canned file | Use when |
|---|---|---|
| `helm diff upgrade notifyapi * -n notifyapi-prod*` | `empty.txt` | before the code change: no differences between the release and the chart as it is (no drift). Any values-file arguments |
| `helm diff upgrade notifyapi * -n notifyapi-prod*` | `helm-diff.txt` | the plan, after the code change: `replicaCount` 2 → 4 for the expected code. Any values-file arguments |
| `helm list -n notifyapi-prod*` | `helm-list.txt` | always |
| `helm get values notifyapi -n notifyapi-prod` | `helm-get-values.yaml` | always (`--all` is not canned) |
| `helm lint *` | `helm-lint.txt` | always |
| `helm upgrade notifyapi *` | `helm-upgrade.txt` | only if the skill applies directly |
| `sha256sum <scratch file holding the diff text>` | (see the Plan hash bullet above) | the plan hash |

## Kubernetes reads (prod)

| Command pattern | Canned file | Use when |
|---|---|---|
| `kubectl get deploy*notifyapi* -n notifyapi-prod*` | `deploy-notifyapi-prod.json` | before. The runner applies any `-o jsonpath` or `-o custom-columns` |
| `kubectl get deploy*notifyapi* -n notifyapi-prod*` | `deploy-notifyapi-after-prod.json` | after |
| `kubectl get pods -n notifyapi-prod*` | `pods-notifyapi-prod.json` | before. Two pods, zero restarts |
| `kubectl get pods -n notifyapi-prod*` | `pods-notifyapi-after-prod.json` | after. Four pods, zero restarts |
| `kubectl get hpa -n notifyapi-prod*` | `kubectl-no-resources.txt` | always. No HPA |
| `kubectl get pdb -n notifyapi-prod*` | `kubectl-no-resources.txt` | always. No PodDisruptionBudget |
| `kubectl get ns notifyapi-prod*` | `kubectl-get-ns.txt` | always |
| `kubectl top nodes*` | `kubectl-top-nodes.txt` | always. Three nodes with CPU 31–44% and memory 38–52% |
| `kubectl top pods -n notifyapi-prod*` | `kubectl-top-pods.txt` | before. Two pods, each well under its 250m CPU and 256Mi memory requests |
| `kubectl top pods -n notifyapi-prod*` | `kubectl-top-pods-after.txt` | after. Four pods |
| `kubectl get prometheusrule* *` | `prometheusrules-notifyapi.json` | always. One rule, `notifyapi-slo` in `monitoring`, with a burn-rate alert, a queue-age alert and a not-ready alert |
| `kubectl get servicemonitor* *` | `servicemonitors-notifyapi.json` | always. One ServiceMonitor for notifyapi |
| `kubectl rollout status deploy/notifyapi -n notifyapi-prod*` | `kubectl-rollout-status.txt` | before, and after the rollout |
| `kubectl get applications.argoproj.io *` | `kubectl-no-resource-type.txt` | always. No Argo CD |
| `kubectl get kustomizations.kustomize.toolkit.fluxcd.io *` | `kubectl-no-resource-type-flux.txt` | always. No Flux |

## Operator profile

| Command pattern | Canned file | Use when |
|---|---|---|
| `operator profile read` (`$CULIOPS_HOME/operator.md`, else `~/.culiops/operator.md`) | `operator-profile.md` | always. Q5 for helm and Q4 for `acme/notifyapi/notifyapi`, each dated 2026-04-10; none is `first time`; no `incident check:` line |

## App-source search

There are no rows for `ls <parent of the repo>`, for any `git -C <dir>` read of a sibling checkout, or for an app-source read. A read of that kind has no canned output.

## Snapshot reads (prod)

S0/S1 = before the upgrade (the Step 1 batch, and the re-read just before the apply). S2 = after the CI job has run the upgrade and the rollout has completed. No Kubernetes metrics backend is reachable: the cluster has a `PrometheusRule` and a `ServiceMonitor`, but no Prometheus API address is in the repo, the catalog or the pre-flight record, and the fixture has no row for one. A query to a Prometheus backend has no canned output. The cluster's only metric reads are `kubectl top`, which are point-in-time. CloudWatch in `ap-southeast-1` answers with the prod identity: the SQS queue `notifyapi-prod-inbound` publishes its metrics there. A `get-metric-data` file answers whatever query file the skill writes (protocol, Notes › `get-metric-data` files).

| Command pattern | Canned file | Use when |
|---|---|---|
| `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod*` | `k8s-snapshot-prod.json` | S0/S1. A `List`: the Deployment `notifyapi` 2 of 2 ready, 2 pods `Running` with 0 restarts, no event, no StatefulSet, no HPA. The runner applies any `-o jsonpath` or `-o custom-columns` |
| `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod*` | `k8s-snapshot-after-prod.json` | S2. The Deployment 4 of 4 ready, 4 pods `Running` with 0 restarts, three `Normal` events from the scale-up, no `Warning` event |
| `helm history notifyapi -n notifyapi-prod*` | `helm-history.txt` | S0/S1: revision 9 `deployed` on 2026-04-02, 22 days before the clock start |
| `helm history notifyapi -n notifyapi-prod*` | `helm-history-after.txt` | S2: revision 10 `deployed` at 14:31 +07:00 |
| `aws cloudwatch describe-alarms --state-value ALARM *` | `alarms-firing-prod.json` | always, `ap-southeast-1`: nothing is firing |
| `aws cloudwatch get-metric-data *` | `metric-data-7d-prod.json` | a window longer than one day: the S0/S1 call of `examples/aws.md` › Health Snapshot (7 days and 1 hour, `Period` 3600). The queue `notifyapi-prod-inbound`, one value per hour, 169 hours oldest first, the last the hour ending at the clock start and the first the same hour a week earlier. `NumberOfMessagesSent` (last 2,910, first 2,860): weekdays peak between 09:00 and 12:00 +07:00 (02:00–05:00 UTC), about 4,000–4,500 per hour; weekend hours are about half the weekday ones; 00:00–05:00 +07:00 68–184 per hour. `ApproximateNumberOfMessagesVisible` maximum 0–15 (last 10, first 8). `ApproximateAgeOfOldestMessage` maximum 1–11 s (last 6, first 7) |
| `aws cloudwatch get-metric-data *` | `metric-data-s2-prod.json` | S2: the queue's signals for the 6 periods of 300 s after the rollout completed. `NumberOfMessagesSent` 247–261 per period, `ApproximateNumberOfMessagesVisible` maximum 3–5, `ApproximateAgeOfOldestMessage` maximum 3–4 s. The runner returns the periods inside the window the skill asked for |
| `gh run list *` | `gh-run-list.json` | CI history: the last run of the `helm-upgrade` workflow succeeded 2026-04-02 16:40 +07:00 |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
