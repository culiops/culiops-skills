# Documentation lookups — helm-config-update

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-04-24. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## Changing `replicas` on a Deployment

- URL: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment
- Date read: 2026-04-24
- Sentence relied on (paraphrase): Scaling a Deployment by changing `.spec.replicas` adds or removes pods; it does not trigger a rollout of the pod template, so existing pods are left running.
