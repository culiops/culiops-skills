# Documentation lookups — dev-lane

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-11-09. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## A task definition revision is immutable

- URL: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): A task definition revision cannot be changed after it is registered. Changing a parameter such as `cpu` registers a new revision, and the service is updated to run it with a rolling deployment.

## Valid Fargate CPU and memory pairs

- URL: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): For Fargate tasks, 512 CPU units supports memory values from 1024 MiB to 4096 MiB, and 256 CPU units supports 512 MiB, 1024 MiB or 2048 MiB.
