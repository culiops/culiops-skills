# Documentation lookups — multi-phase-rds-upgrade

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-11-09. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## A static RDS parameter needs a reboot

- URL: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): Changes to a static parameter in a DB parameter group take effect only after the DB instance is rebooted. The instance shows `pending-reboot` as the parameter apply status until then.

## What a reboot does on a Multi-AZ instance

- URL: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): A reboot restarts the database engine and briefly interrupts connections. On a Multi-AZ instance, a reboot can fail over to the standby if `--force-failover` is given; without it the reboot happens in place.

## `max_connections` on RDS for PostgreSQL

- URL: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): `max_connections` is a static parameter for RDS for PostgreSQL. Its default is derived from the instance memory, and a user-set value replaces the default.
