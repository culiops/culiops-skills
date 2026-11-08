# Documentation lookups — light-escalation-tag-abac

Canned answers for `docs:` lookups. They are fixture text, not fetched pages: the URL is the page the claim would come from, the sentence is a paraphrase kept short on purpose, and the date read is the dry-run date, 2026-11-09. Use an entry only when its subject matches the claim the skill is about to make. If no entry matches, the lookup returns `no canned output`.

## A condition on `aws:ResourceTag` follows the resource's tag

- URL: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html
- Date read: 2026-11-09
- Sentence relied on (paraphrase): In attribute-based access control, a policy condition with the `aws:ResourceTag/tag-key` condition key compares the tag on the resource being accessed. Changing the tag on the resource changes whether the policy allows the request.
