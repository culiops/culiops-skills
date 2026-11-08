# Dry-run of `iac-change-execution` against `multi-phase-rds-upgrade`

Expected skill behaviour at each step. Recorded for pre-dry-run reference; "Gaps surfaced" and "Fixes applied" are filled in during the actual dry-run.

## Step 1 — Research

**Input:** operator request — "Increase max_connections to 200 for paymentapi prod RDS, then reboot so it takes effect."

**Expected behaviour:**

| Check | Expected outcome |
|-------|-----------------|
| Catalog lookup | Finds `.culiops/service-discovery/paymentapi-prod.md` — reads signal envelopes and dependency graph |
| Catalog signal note | Reads the note about connections alarm firing frequently at threshold=80 vs limit=100 |
| Tool detection | Finds `main.tf`, `variables.tf` → identifies Terraform |
| Naming pattern | Reads catalog: `paymentapi-{role}-{env}` — no inference needed |
| Reboot requirement | Recognises `max_connections` is a static parameter in PostgreSQL — requires a reboot to take effect. The IaC should set `apply_method = "pending-reboot"` |
| Alarm threshold analysis | Reads `aws_cloudwatch_metric_alarm.paymentapi_db_connections` threshold=80 vs current limit=100 (80%). Notes new limit=200 → proportional threshold=160 |
| Direct apply flag | Operator specifies `--direct-apply` (maintenance window context); skill records execution path as direct apply |
| tfvars location | Finds `envs/prod.tfvars` |
| Evidence table | `max_connections` current value: `code:` the parameter group in `main.tf` vs `live: aws rds describe-db-parameters` (filtered to `max_connections`); instance class `code: envs/prod.tfvars` vs `live: aws rds describe-db-instances`; alarm threshold `code: main.tf` vs `live: aws cloudwatch describe-alarms`. Any mismatch is drift and must be acknowledged before planning. The reboot phase cannot be approved on a `catalog:`-only row |
| Target check | Direct apply ⇒ target check shown before plan **and** re-shown at each GATE 4 (account / region / `-var-file=envs/prod.tfvars`) |

## Step 2 — Plan

**Expected output:**

```
Phase 1 of 2 — IaC (terraform apply):
  Modify: aws_db_parameter_group.paymentapi  (max_connections: "100" → "200")
  Modify: aws_cloudwatch_metric_alarm.paymentapi_db_connections  (threshold: 80 → 160)
  Add:    (none)
  Destroy:(none)

Phase 2 of 2 — Operational (AWS CLI):
  Command: aws rds reboot-db-instance \
             --db-instance-identifier paymentapi-db-prod \
             --region ap-southeast-1
  Rationale: max_connections is a static/pending-reboot parameter; reboot required for change to take effect.
  Impact: brief connection interruption (~30s); Multi-AZ failover will occur automatically.

Execution path: direct apply (operator override)
Pre-flight: required before Phase 1 apply
```

## Step 3 — Implement

**Expected behaviour:**

- Modifies `main.tf`:
  - `aws_db_parameter_group.paymentapi`: changes `max_connections` value from `"100"` to `"200"` and sets `apply_method = "pending-reboot"`
  - `aws_cloudwatch_metric_alarm.paymentapi_db_connections`: updates `threshold` from `80` to `160` and updates `alarm_description` to reflect new limit
- Does NOT modify `aws_cloudwatch_metric_alarm.paymentapi_db_cpu` (CPU alarm is unrelated)
- Phase 2 command is documented (in plan output or operator note) but not written as IaC

## Step 4 — Execute

### GATE 2: Code review

- Skill surfaces the diff for operator review
- Operator verifies: param group change + alarm threshold update; approves

### 4a: Generate plan output

- `terraform plan -var-file=envs/prod.tfvars -out=tfplan`
- Expected: 2 to change (param group + alarm), 0 to add, 0 to destroy

### 4b: Pre-flight gate

- Skill invokes `pre-flight` with context: multi-phase, RDS parameter group + reboot, paymentapi, ap-southeast-1, direct apply
- Expected scores: Yellow on blast radius (database = shared infrastructure), Yellow on reversibility (param group change is reversible but reboot causes brief downtime), elevated risk from direct apply path
- GATE 3: operator acknowledges Yellow/Red findings before direct apply proceeds

### 4c: Execute Phase 1 (direct apply)

- Skill presents: `terraform apply tfplan` — GATE 4, operator approves
- Runs apply, captures output

### 5a: Verify Phase 1

- Re-plan: expects no changes
- Health check: `aws rds describe-db-instances` — status `available`, parameter group status `pending-reboot`

### Phase gate

- "Phase 1 complete. Parameter group updated. Instance shows pending-reboot. Ready to proceed to Phase 2: reboot instance?"
- Operator confirms

### Step 3 → Step 4 (Phase 2)

- Phase 2 is an operational command, not IaC — no code change needed
- 4c: Skill presents:
  ```
  aws rds reboot-db-instance \
    --db-instance-identifier paymentapi-db-prod \
    --region ap-southeast-1
  ```
- GATE 4: operator approves

### 5a: Verify Phase 2

- Health check: `aws rds describe-db-instances` — status returns to `available`
- Parameter apply status:
  ```
  aws rds describe-db-instances \
    --db-instance-identifier paymentapi-db-prod \
    --query 'DBInstances[0].DBParameterGroups[0].ParameterApplyStatus'
  # Expected: "in-sync"
  ```

## Step 5b — Record

- Writes execution record with both phases documented
- GATE 5: offers to commit

## Key multi-phase tests

| Test | What it verifies |
|------|-----------------|
| Multi-phase detection | Skill produces a 2-phase plan (not a single apply) |
| Phase 2 as operational command | Phase 2 is `aws rds reboot-db-instance`, not `terraform apply` |
| Catalog consumption | Skill reads `.culiops/service-discovery/paymentapi-prod.md` and uses signal envelopes |
| Alarm threshold proportional update | Connections alarm threshold updated from 80 to 160 (80% of new limit=200) |
| Direct apply risk escalation | Direct apply path surfaces elevated risk; pre-flight is Amber/Red; operator must acknowledge |
| Inter-phase gate | Skill pauses between Phase 1 and Phase 2 for operator confirmation |

## Gaps surfaced

_(to be filled during actual dry-run)_

## Fixes applied

_(to be filled during actual dry-run)_

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 25**; 2 `unscripted` (health-check offers).
- Verdict RED soft block in both pre-flights. Outcome: both phases applied and verified.
- Phase 2, an operational reboot with no code, repeated every gate, including GATE 2 and the 4a target check. Pre-flight GATE 2 and iac GATE 3 asked for the same acknowledgement twice per phase.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 7** (target 5 (+1 per RED pre-flight)): F1,F2,F3,H5,F4,H5,F4. `unscripted`: 0.
- Before → after: **25 → 7** stops.

## Findings and fixes

Per-MUST results from the verifier:

### multi-phase-rds-upgrade (expected-output)
Stops: 7 (target 7) — PASS. Unscripted: 0.

Stop arithmetic: base 5 (`F1`, `F2`, `F3` phase 1, `F4` phase 1, `F4` phase 2) + 1 per RED pre-flight run. `preflight-record.md` has two runs, both RED (`preflight-record.md:21` and `:96`), so +2 = 7. `stops.md` lines 1-7 are `F1, F2, F3, H5, F4, H5, F4`: two `[H5]`, one per RED run. `grep -c -i unscripted` is 0 in `stops.md`, `transcript.md`, `record.md` and `preflight-record.md`.

The 10 README MUST bullets are rows 1-10. The 11 scoring-table categories are rows 11-21. The "six Yellow or unknown gives RED" verdict is row 22. Where the table and a run differ, the row says which run.

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | `stops.md` lists F1, F2, F3 (ph1), F4 (ph1), F4 (ph2) in order (plus the H5s); phase 2 has no `[F3]`; no separate phase gate | PASS | `stops.md:1-7`. The non-H5 IDs run F1, F2, F3, F4, F4 in the required order. Each `[H5]` sits right before the `[F4]` it gates (`stops.md:4`, `:6`), the same order as SKILL.md Step 4b then 4c. Phase 2 goes `transcript.md:629` (4a target re-check only), `:689` `[H5]`, `:702` `[F4]`, with no `[F3]`. `grep -c "Ready to proceed"` is 0 in all four files. | |
| 2 | Phase-1 success-criteria result (re-plan and `describe-db-instances` showing `pending-reboot`) is shown in phase 2's `[F4]` | PASS | `transcript.md:704` (inside the `[F4]` at `:702`): "Phase 1 success criteria: re-plan No changes — pass · max_connections 200 pending-reboot — pass · instance available, parameter group pending-reboot — pass · alarm threshold 160, OK — pass · both alarms OK — pass · no alarm in ALARM — pass". This matches the `Phase <N> success criteria: <check> — <pass/fail>` form at SKILL.md:405. `stops.md:7` says "phase 1 result shown; Q1-Q3 re-asked". The phase-2 `[H5]` at `transcript.md:689` does not show it, but per R6 the `[F4]` is the stop that must. | |
| 3 | `**Lane:** full — <basis>` names the reason (parameter-group update and alarm update, neither on the allowlist); `**Escalations:** none` or the one that applies | PASS | `record.md:11`: "full — the parameter-group update and the alarm update (threshold, description) are off the light-lane allowlist (`lanes.md` > Light-lane allowlist, L2 fails); targets are not proven dev (prod, unproven). Confirmed from the plan output at 4a." `record.md:12`: `**Escalations:** none`. The form matches the SKILL.md:443-444 template. The L2 rule is at `lanes.md:17`. | |
| 4 | `**Environment tier:** prod=prod (operator-stated ...)`; repo pins no account, so unproven and prod gate levels | PASS | `record.md:13`: "prod=prod (operator-stated at `[F1]`; no pin in the repo — no `allowed_account_ids`, no `assume_role`, no account variable ...; identity read ... account 123456789012; unproven, so prod gate levels)". The prefix matches the quoted string. | |
| 5 | `**Staging-first:** n/a — no staging env (<evidence>)` | PASS | `record.md:14`: "n/a — no staging env (code: `envs/prod.tfvars` is the only var-file; no staging directory, workspace or overlay in the repo)". Exact form per `lanes.md:225`. | |
| 6 | `**Waived:** none` | PASS | `record.md:15`. | |
| 7 | Each phase in `record.md` has `- Parity check: n/a` | PASS | `record.md:72` (phase 1) and `record.md:83` (phase 2), both exactly `- Parity check: n/a`. | |
| 8 | Direct apply flagged to pre-flight as a local workstation apply (A4); apply and reboot each shown alone, run only after approval, target check re-shown | PASS | Flag: the caller block `Delivery model:` says "local workstation apply, not going through CI/CD pipeline" at `transcript.md:464` (phase 1) and `:645` (phase 2); `preflight-record.md:14` and `:89` carry it. A4 is named to the operator at `[F2]`, `transcript.md:305`. Shown alone: `[F4]` at `:573` shows only `terraform apply tfplan`; `[F4]` at `:702` shows only `aws rds reboot-db-instance ...`. Run after approval: the apply runs at `:586` (11:14), after the `:583` answer; the reboot runs at `:716` (11:36), after the `:713` answer. Target re-shown: `:573` "against account 123456789012 / ap-southeast-1 (role paymentapi-operator, re-checked 10:55)"; `:702` "(... re-checked 11:21)". Note, not a FAIL: SKILL.md:376 gives the phrase as "local workstation apply — not going through CI/CD pipeline." and the runner wrote a comma for the dash. The MUST does not quote that string. | |
| 9 | `## Outcome` says completed with `**Applied:** yes — verified`, citing phase-1 and phase-2 success-criteria outputs | PASS | `record.md:89` `completed`. `record.md:91`: "**Applied:** yes — verified (phase 1: re-plan No changes, `max_connections` 200 and alarm threshold 160 read back at 11:15-11:19, parameter group `pending-reboot`; phase 2: instance `available` with parameter group `in-sync` at 11:38, ECS 3/3, 3 healthy targets, no alarm firing at 11:39-11:41)". The underlying outputs are at `transcript.md:597-608` and `:723-732`. | |
| 10 | No stop is logged as `unscripted` | PASS | `grep -c -i unscripted` is 0 in `stops.md`, `transcript.md`, `record.md` and `preflight-record.md`. | |
| 11 | Pre-flight cat 1 Blast radius: Yellow | FAIL | Phase 1 run: Yellow (`preflight-record.md:27`), matches. Phase 2 run: Red (`preflight-record.md:102`; `transcript.md:670`). The runner's basis is `docs: D3`, which is `canned/docs.md:15`: a reboot without `--force-failover` "happens in place", and the phase-2 command has no `--force-failover` (`record.md:56`). That contradicts the README basis "Multi-AZ softens the reboot", and `DRY-RUN-NOTES.md` ("Multi-AZ failover will occur automatically"). The runner followed the canned docs and the Red column of pre-flight SKILL.md:44. Red or Yellow does not change the verdict (RED either way) or the stop count. | fixture |
| 12 | Cat 2 Reversibility: Yellow | PASS | Both runs Yellow: `preflight-record.md:28` and `:103`. | |
| 13 | Cat 3 Change velocity: Green (`git log --since=7.days` returns nothing) | FAIL | Phase 1 run: Green (`preflight-record.md:29`), matches. Phase 2 run: Yellow (`preflight-record.md:104`; `transcript.md:672`). `git log --since=7.days` was empty (`transcript.md:662`), but `git status` showed ` M main.tf`, phase 1's applied and uncommitted code (`transcript.md:663`), and the runner scored "stacking". Skill text: the assessor's "Are there uncommitted changes to the same files? (git status)" (`assessors/iac-change.md:123-124`) and the Red cell "stacking on uncommitted prior change" (`pre-flight SKILL.md:51`) have no exemption for a multi-phase change's own earlier phase. The exclusion at `assessors/iac-change.md:117` and `pre-flight SKILL.md:82` covers only "this change's own commits". The direct-apply path has no commit step (SKILL.md:395-399, and `lanes.md:181` commits per phase only under staging-first), so phase 1 stays uncommitted. The runner flagged the ambiguity itself (`transcript.md:765`). | skill-text |
| 14 | Cat 4 Dependency impact: Yellow | PASS | Both runs Yellow, one consumer (ECS `paymentapi-svc-prod`): `preflight-record.md:30` and `:105`. | |
| 15 | Cat 5 Timing context: Green | PASS | Both runs Green: `preflight-record.md:31` and `:106`. | |
| 16 | Cat 6 Operator familiarity: Green | PASS | Both runs Green: `preflight-record.md:32` and `:107`. | |
| 17 | Cat 7 Observability readiness: Yellow | PASS | Both runs Yellow, static thresholds on CPU and connections: `preflight-record.md:33` and `:108`. | |
| 18 | Cat 8 Cost impact: Green | PASS | Both runs Green: `preflight-record.md:34` and `:109`. | |
| 19 | Cat 9 Security posture: Green | PASS | Both runs Green: `preflight-record.md:35` and `:110`. | |
| 20 | Cat 10 Resource health: Yellow (78 of 100 peak; three alarm episodes) | PASS | Both runs Yellow, peak 78 of 100 = 78 %: `preflight-record.md:36` (also "3 ALARM episodes of the connections alarm in 7 days") and `:111`. | |
| 21 | Cat 11 Application compatibility: ⚪ (Q8 is (c), no source) | PASS | Both runs ⚪: `preflight-record.md:37` and `:112`. The transcript tables call it "unknown" (`transcript.md:540`, `:680`). | |
| 22 | Six Yellow or ⚪ escalate to RED (soft block), so `[H5]` is expected | PASS | Phase 1: Red none, Yellow + ⚪ = 6 (1, 2, 4, 7, 10, 11), RED soft block (`preflight-record.md:54`). Phase 2: Red = cat 1 plus Yellow + ⚪ = 6 (2, 3, 4, 7, 10, 11), RED soft block (`preflight-record.md:125`). Both acknowledged at `[H5]` (`transcript.md:564`, `:695`). The phase-2 six includes the two deviating cats (1 and 3), so it stays RED, but not on the table's six. | |

Result: 20 of 22 MUST pass.


Fixes applied:
- The operator script's `[H5]` entry now covers every `[H5]`, because both pre-flight runs are RED.
- lanes.md now says a phase's first stop shows the previous phase's full verification result (re-plan and success criteria).
- The README blast-radius row for the reboot now accepts Yellow or Red.
- The Outcome MUST now reads the record's `## Outcome` section.

**Still open (reported, not fixed in this branch):** row 13, phase-2 change velocity. The phase-2 Yellow, "stacking on an uncommitted prior change", is a true signal, not a scoring error. The direct-apply path never commits applied code, so phase 1's applied change lives only in the working tree, and a later apply from the default branch would revert it. That gap predates this branch. The follow-up is to commit applied code on the direct-apply path, not to change pre-flight's scoring. It changes neither the stop count nor the verdict.
