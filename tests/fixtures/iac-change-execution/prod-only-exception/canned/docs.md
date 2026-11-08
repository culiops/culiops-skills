# Documentation lookups — prod-only-exception

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-11-09. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## A CloudWatch alarm's threshold can be changed in place

- URL: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): `PutMetricAlarm` creates or updates an alarm. An update replaces the alarm's earlier settings, and the alarm's state is evaluated again afterwards. Putting the earlier threshold back restores the earlier behaviour.
