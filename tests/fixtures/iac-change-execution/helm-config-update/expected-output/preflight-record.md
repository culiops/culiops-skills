# Pre-flight record: reused, not rewritten

No pre-flight run happened in this dry run. Step 4b found a reusable record and reused it (SKILL.md:364-365). The record file is unchanged.

**Record reused:** `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md`
**Shown at `[F4]` as:** "Using existing pre-flight record from `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` (verdict: GREEN — PROCEED)."

## Fields of the reused record

- Pre-flight assessment for: `notifyapi` / `prod`; action: Increase replica count from 2 to 4
- Date: 2026-04-24 10:30; commit `d4e5f6g`
- Target: context `prod-cluster` / namespace `notifyapi-prod`
- Plan hash: `sha256:9f2c4e…`; plan source: `helm diff upgrade notifyapi . -f values-prod.yaml -n notifyapi-prod`
- Delivery model (as recorded there): CI on merge
- Invoked by: operator; mode: standalone; assessor: iac-change; layers: L1 + L2 + L3
- Verdict: GREEN — PROCEED (10 category rows, all Green: blast radius, reversibility, change velocity, dependency impact, timing, familiarity, observability, cost, security, resource health). No hard blocks, no acknowledged risks, no mitigations.

## Match rule, as applied at 4b (14:47)

| Rule | Reused record | This run | Result |
|---|---|---|---|
| (a) plan hash | `sha256:9f2c4e…` | `sha256:9f2c4e…` (`sha256sum` of the `helm diff` text, 14:47; INDEX treats the shortened hash as equal) | match |
| (b) target | `prod-cluster` / `notifyapi-prod` | `prod-cluster` / `notifyapi-prod` (re-check 14:44) | match |
| (c) freshness | written 2026-04-24 10:30 | now 14:47, 4 h 17 min old; window 24 h | match |

## Categories 5 and 10, re-asked at apply time

- Category 5 (timing): the latest Q1-Q3 answers (`[F2]`, 14:38) are no / no / no. The record's L2 says no incident, no freeze, not peak. Unchanged.
- Category 10 (resource health): the record's reads re-run at 14:48-14:50 (approved in the `[F1]` batch): `readyReplicas/replicas` -> `2/2`; pod restart counts -> 0 and 0; `kubectl top nodes` -> 3 nodes, CPU 31-44%, memory 38-52%. The record had 2/2, 0 restarts, CPU 31-44%, memory 38-52%. Unchanged.

Both unchanged, so pre-flight was not re-run. The verdict was carried to `[F4]`, where the operator approved it. Operator's request at `[F2]` to skip pre-flight was refused under H9; the reused record counts as the pre-flight run.

Observation: the reused record scores 10 categories, and `skills/pre-flight/SKILL.md` now defines 11 (category 11, application compatibility). The 4b match rule does not check this.
