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
| `git branch --show-current` | `git-branch.txt` | always (the repo is on `main`) |
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
| `git switch -c *` | `git-switch.txt` | the runner puts the real branch name where `<branch>` stands |
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

## Documentation lookups

| Command pattern | Canned file | Use when |
|---|---|---|
| (a documentation lookup) | `docs.md` | use the entry whose subject matches the claim. No entry: `no canned output` |
