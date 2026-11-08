# Documentation lookups — staging-prod-parity-mismatch

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-11-09. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## The family of a DB parameter group cannot change in place

- URL: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
- Date read: 2026-11-09
- Sentence relied on (paraphrase): `family` is a required argument that forces a new resource: changing it replaces the parameter group instead of updating it.

## An RDS for PostgreSQL major version upgrade needs a parameter group of the new family

- URL: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): A major version upgrade needs a DB parameter group of the target major version's family, and the instance is unavailable while it upgrades. Major version upgrades can introduce changes that are not backward compatible.

## An RDS engine version upgrade cannot be reversed in place

- URL: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): After an engine version upgrade you cannot move the instance back to the older version. Going back means restoring a snapshot taken before the upgrade.
