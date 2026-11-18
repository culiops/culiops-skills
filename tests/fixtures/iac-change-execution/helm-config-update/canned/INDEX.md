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
| `git remote get-url origin` | `git-remote.txt` | always, for the repo itself (a `git -C <dir>` read of a sibling checkout is in App-source search) |
| `git rev-parse *` | `git-rev-parse.txt` | always, for the repo itself. `--short` gives the first 7 characters, `a1b2c3d` |
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
| `helm diff upgrade notifyapi * -n notifyapi-prod*` | `helm-diff.txt` | the plan: `replicaCount` 2 → 4 for the expected code. Any values-file arguments |
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

## App-source search (in the read batch)

The app source is a sibling checkout, `../notifyapi-app`, whose origin matches the service name. Its checkout is not at the deployed version: the deployed image is `registry.internal/notifyapi:v3.1.0` (`values-prod.yaml:5`, and `deploy-notifyapi-prod.json`), but `HEAD` is 4 commits past the tag `v3.2.0`, and `v3.1.0` is an older commit.

| Command pattern | Canned file | Use when |
|---|---|---|
| `ls <parent of the repo>` (`ls ..`, `ls ../`, or the parent's path) | `siblings-ls.txt` | always. `dotfiles`, `notifyapi` (this repo) and `notifyapi-app` |
| `git -C ../dotfiles remote get-url origin` | `sibling-origin-dotfiles.txt` | always. `git@github.com:acme/dotfiles.git`, not the app |
| `git -C ../notifyapi-app remote get-url origin` | `sibling-origin-notifyapi-app.txt` | always. `git@github.com:acme/notifyapi-app.git` |
| `git -C ../notifyapi-app rev-parse HEAD` | `app-source-rev-parse.txt` | always. `9be7a31c0d52f48e6a1b7c3d2e5f80194a6b7c8d`, not the commit of `v3.1.0` |
| `git -C ../notifyapi-app describe --tags*` | `app-source-describe.txt` | always. `v3.2.0-4-g9be7a31` |
| `git -C ../notifyapi-app rev-parse v3.1.0*` | `app-source-rev-parse-tag.txt` | always. The commit of the deployed tag, `4e2a9c5b7d1f3a60b8c2e4d6f81a3b5c7d9e0f12` |

## Snapshot reads (prod)

S0/S1 = before the upgrade (the Step 1 batch, and the re-read just before the apply). S2 = after the CI job has run the upgrade and the rollout has completed. The snapshot set is the Deployment `notifyapi` and its pods; the catalog lists no consumers. **No metrics backend is reachable:** the cluster has a `PrometheusRule` and a `ServiceMonitor`, but no Prometheus API address is in the repo, the catalog or the pre-flight record, and the fixture has no row for one. A query to a backend gets `no canned output`. The only metric reads are `kubectl top`, which are point-in-time, so the snapshot says `no metrics backend — point-in-time only` and Q3 has no request-rate source.

| Command pattern | Canned file | Use when |
|---|---|---|
| `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod*` | `k8s-snapshot-prod.json` | S0/S1. A `List`: the Deployment `notifyapi` 2 of 2 ready, 2 pods `Running` with 0 restarts, no event, no StatefulSet, no HPA. The runner applies any `-o jsonpath` or `-o custom-columns` |
| `kubectl get deploy,sts,pods,events,hpa -n notifyapi-prod*` | `k8s-snapshot-after-prod.json` | S2. The Deployment 4 of 4 ready, 4 pods `Running` with 0 restarts, three `Normal` events from the scale-up, no `Warning` event |
| `helm history notifyapi -n notifyapi-prod*` | `helm-history.txt` | S0/S1, and the automation-lag read: revision 9 `deployed` on 2026-04-02, 22 days before the clock start |
| `helm history notifyapi -n notifyapi-prod*` | `helm-history-after.txt` | S2: revision 10 `deployed` at 14:31 +07:00 |
| `gh run list *` | `gh-run-list.json` | CI history. The operator-stated delivery model is a CI job that runs `helm upgrade` on merge: its last run succeeded 2026-04-02 16:40 +07:00 |

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
