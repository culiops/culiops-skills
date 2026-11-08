# Dry run: dev-lane, operator-script-mismatch.md (skill source: working tree)

Skill text read: `skills/iac-change-execution/SKILL.md`, `skills/iac-change-execution/lanes.md`. Pre-flight and the examples files were not reached (the run ends at `[H1]` in Step 1, before any plan, lane stop or pre-flight call), so their text was not played.
Dry-run clock: starts 2026-11-09 10:00 +07:00. One minute per command, five minutes per operator answer.

## Operator's first message (operator-script-mismatch.md, `First message`)

> Raise the ECS task CPU for paymentapi in dev from 256 to 512.

## Step 1: Research

Output root (Constraint 13, SKILL.md:35): no canned row covers `CULIOPS_HOME`, so no command was run for it. Treated as unset: root is `.culiops/` at the repo root. See ambiguity note A2.

Environment the change is for: `dev` (from the request). Environments the repo defines: `envs/dev.tfvars`, `envs/prod.tfvars` (reading the fixture's input files is not a command lookup).

Identity read first, before any other live command (SKILL.md:169, lanes.md:45; exempt from opt-in, Constraint 3). No profile is named in the repo or the request, so the bare command runs.

### Command 1 (10:01)

```
aws sts get-caller-identity
```

Canned: `canned/identity-prod.json` (INDEX row: `aws sts get-caller-identity`, script `operator-script-mismatch.md`, account 333333333333). Environment decided by rule 1(b): the skill is working on dev; the INDEX row is keyed to this script and overrides the environment pick, so the prod file is returned for a dev target.

```
{
  "UserId": "AROAEXAMPLEPRDOPR:operator",
  "Account": "333333333333",
  "Arn": "arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator"
}
```

### Tier mapping and pin comparison (SKILL.md:169, lanes.md:33-42)

Files read: `providers.tf`, `variables.tf`, `envs/dev.tfvars`, `envs/prod.tfvars`.

| Environment | Pin (code) | Live identity | Result |
|---|---|---|---|
| dev (the target of this change) | `code: envs/dev.tfvars:3` `aws_account_id = "111111111111"`; `code: providers.tf:16` `allowed_account_ids = [var.aws_account_id]` | `live: aws sts get-caller-identity` (10:01) -> account `333333333333`, `assumed-role/paymentapi-operator` | no match |
| prod (not part of this change) | `code: envs/prod.tfvars:3` `aws_account_id = "333333333333"` | same read | match |
| staging | none: no staging environment in `envs/` | n/a | n/a |

lanes.md:42: H1 needs positive evidence that the target differs. Here the environment the plan is for (dev) has a pin, and the identity read does not match it; the identity matches prod's pin, which is a different environment's. That is the evidence. H1 fires now. Per SKILL.md:169 ("run nothing further") and lanes.md:56 ("its own stop `[H1]`, as soon as the evidence ... shows a mismatch"), the catalog load, code read, duplicate check, lane prediction and research summary do not run. No further command was run.

Skill message shown to the operator:

> **[H1] The active identity does not match the environment this change is for. Nothing further will run.**
>
> - Change is for: `dev`. Dev's pin: account `111111111111` (`code: envs/dev.tfvars:3`; the provider also refuses any other account, `code: providers.tf:16`).
> - Active identity: account `333333333333`, `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` (`live: aws sts get-caller-identity`, 10:01). That is prod's pin (`code: envs/prod.tfvars:3`).
> - Dev tier: not proven. Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset).
>
> "Proceed anyway" is refused (H1). I have run no plan, read, branch command or code change. Switch to credentials for account `111111111111` and tell me; I will re-run the identity read and it must match dev's pin before anything else runs.

STOP 1 recorded in `stops.md` (id `H1`).

### Operator answer (operator-script-mismatch.md, entry 1 `[H1]`, 10:06)

> My shell is on the prod profile. I will switch to the dev credentials and start again.

Script intent: abort. Nothing else asked or answered.

## Abort

SKILL.md:374: the operator aborts, the skill stops and writes a partial execution record with `Outcome: aborted` (`record.md`). No code was written, no branch was created, no plan was run, pre-flight was not invoked. `git status` is clean (no git command was run).

Final message shown to the operator (SKILL.md:485):

> Aborted at `[H1]`: the active identity (account 333333333333) did not match dev's pin (111111111111). Nothing was run against dev, no code was written, and nothing was applied. Execution record: `.culiops/iac-change-execution/paymentapi-raise-task-cpu-20261109-1006.md` (outcome: aborted).
>
> Next: commit the record (`.culiops/iac-change-execution/paymentapi-raise-task-cpu-20261109-1006.md`) · draft the result or ticket-close message with change-comms

## Notes on the skill text

- A1. `SKILL.md:169` + `lanes.md:42,56`: H1 fires inside Step 1 right after the identity read and tier mapping, before the catalog load, code read and duplicate check. The text supports this most directly ("run nothing further"), so those Step 1 items did not run. A reader could argue the duplicate check is local and read-only and still runs; I took "run nothing further" literally.
- A2. `SKILL.md:35` (Constraint 13): the output root must be resolved at the start and shown at the first stop. There is no canned way to read `CULIOPS_HOME`, so I assumed unset and showed `.culiops/` in `[H1]`. No lookup was attempted, so no `no canned output` was recorded.
- A3. `SKILL.md:485`: the final message is specified as ending with a `Next: commit the record ...` line. On an aborted run that offer is odd, but the text has no abort-specific form, so I followed it.
- A4. The partial record has no lane (`SKILL.md:190` predicts it later in Step 1). I recorded the lane as not determined rather than invent a basis.
- `no canned output` lookups: none. Staging: no staging environment is mapped (no `staging` var-file), so H7 was never reached.
