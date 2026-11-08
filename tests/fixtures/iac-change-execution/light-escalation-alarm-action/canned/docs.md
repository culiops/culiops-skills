# Documentation lookups — light-escalation-alarm-action

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-11-09. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## An alarm action can be an Application Auto Scaling policy

- URL: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): Step scaling policies are triggered by CloudWatch alarms: when the alarm breaches, Application Auto Scaling changes the scalable target's capacity by the policy's step adjustment, within the target's minimum and maximum capacity.

## Cooldown on a step scaling policy

- URL: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): The cooldown period of a step scaling policy limits how soon the policy can scale again after a scaling activity.
