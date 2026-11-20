# Dry-run of `iac-change-execution` against `helm-config-update`

Expected skill behaviour at each step. Recorded for pre-dry-run reference; "Gaps surfaced" and "Fixes applied" are filled in during the actual dry-run.

## Step 1 — Research

**Input:** operator request — "Increase replica count from 2 to 4 for notifyapi in prod."

**Expected behaviour:**

| Check | Expected outcome |
|-------|-----------------|
| Catalog lookup | Finds `.culiops/service-discovery/notifyapi-prod.md` — reads dependency graph and naming pattern |
| Tool detection | Finds `Chart.yaml` → identifies Helm. Notes `values.yaml` (base) and `values-prod.yaml` (prod overrides) |
| Values file targeting | `replicaCount: 2` is in `values-prod.yaml` (overrides base default of 1). Skill identifies `values-prod.yaml` as the file to modify |
| Naming pattern | Reads catalog: `{{ .Chart.Name }}` — Kubernetes resources use chart name directly |
| Evidence table | `replicaCount` `code: values-prod.yaml:<line>` = 2 vs `live: kubectl get deploy notifyapi -n notifyapi-prod -o jsonpath='{.spec.replicas}'` = 2 ✅; HPA presence checked live (an HPA would override `replicas` — drift if present) |
| Delivery model / target | Checks for Argo CD / Flux objects managing the release (none in fixture → PR path is default, direct apply allowed); target check = `kubectl config current-context` + namespace `notifyapi-prod` |

## Step 2 — Plan

**Expected output:**

```
Phase 1 (of 1):
  Modify: values-prod.yaml — replicaCount: 2 → 4
  Add:    (none)
  Destroy:(none)

Execution path: PR (default)
```

## Step 3 — Implement

**Expected behaviour:**

- Modifies `values-prod.yaml`: changes `replicaCount: 2` to `replicaCount: 4`
- Does NOT touch `values.yaml` (base defaults are not env-specific overrides)
- Does NOT modify any template files
- Change is minimal — only the one line

**Expected diff:**
```diff
--- a/values-prod.yaml
+++ b/values-prod.yaml
@@ -1,7 +1,7 @@
 # Prod overrides — applied on top of values.yaml
 # To change: helm upgrade notifyapi . -f values.yaml -f values-prod.yaml

-replicaCount: 2
+replicaCount: 4
```

## Step 4 — Execute

### GATE 2: Code review

- Skill surfaces the diff (single line change) for operator review
- Operator approves

### 4a: Generate plan output

- Skill presents: `helm diff upgrade notifyapi . -f values.yaml -f values-prod.yaml -n notifyapi-prod`
- Expected diff: Deployment replica count changes from 2 to 4

### 4b: Pre-flight gate

- Skill checks `.culiops/pre-flight/` for a reusable record
- Finds `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md`
- Match rule check: (a) record's **Plan hash** equals the SHA-256 of the current `helm diff` text ✓, (b) same target — context + namespace `notifyapi-prod` ✓, (c) record is within the 24h freshness window (dry-run clock: 2026-04-24, record 10:30 same day) ✓. If any of the three fails → invoke pre-flight inline instead
- **REUSE** — does NOT re-invoke pre-flight
- Shows: "Using existing pre-flight record from `.culiops/pre-flight/notifyapi-config-update-20260424-1030.md` (verdict: GREEN)"
- GATE 3: Green → proceed

### 4c: Execute (PR path)

- Skill presents PR action and waits for GATE 4 approval
- Creates branch `iac-change/notifyapi-scale-replicas`, commits, opens PR
- PR description references the reused pre-flight record
- Reports PR URL to operator
- Skill does NOT run `helm upgrade` directly

**Helm upgrade command for PR description (for operator reference):**
```
helm upgrade notifyapi . \
  -f values.yaml \
  -f values-prod.yaml \
  --namespace notifyapi-prod \
  --atomic \
  --timeout 5m
```

## Step 5 — Verify & Record

- PR path: the fixture has no CI or GitOps config, so the delivery model is `UNVERIFIED` and the operator is asked how changes are applied. The next-step message follows the answer (CI / GitOps: "After merge, `<pipeline>` applies it"; by hand: "merging applies nothing").
- Record: `Outcome: completed` (PR created) with `Applied: no — PR open`. Not `yes — verified`.
- Writes execution record to `.culiops/iac-change-execution/notifyapi-scale-replicas-<timestamp>.md`
- Record notes: pre-flight reused (not re-invoked)
- GATE 5: offers to commit the record

## Key tests

| Test | What it verifies |
|------|-----------------|
| Helm detection | Skill identifies Chart.yaml → Helm (not Terraform) |
| Catalog read | Skill uses dependency graph from `.culiops/service-discovery/notifyapi-prod.md` |
| Pre-flight reuse | Skill finds existing Green record, checks plan hash + target + freshness, reuses without re-invoking |
| Evidence table | `replicaCount` confirmed in code and live; HPA override checked |
| Values file targeting | `values-prod.yaml` is modified, not `values.yaml` |
| Minimal diff | Only `replicaCount` line is changed |
| PR path | No direct apply; skill produces PR workflow |

## Gaps surfaced

_(to be filled during actual dry-run)_

## Fixes applied

_(to be filled during actual dry-run)_

## Baseline (v0.17.0)

Run: `baseline-output/`, skill text from `origin/main` (v0.17.0), operator script mapped by meaning.

- **Stops: 11**; 0 `unscripted`.
- Verdict GREEN, from the existing pre-flight record (reused: same plan hash, target and window). Outcome: PR opened.
- The skill refused both "skip the code gate" and "don't run pre-flight" under "gates are non-negotiable" (SKILL.md:70). It made no distinction between a soft stop and a hard gate.

## Dry-run (v0.18)

Run: `expected-output/`, skill text from the working tree on `feat/iac-change-gate-lanes`, operator script matched by stop ID. Checked by an independent verifier, not the runner.

- **Stops: 3** (target 3): F1,F2,F4. `unscripted`: 0.
- Before → after: **11 → 3** stops.

## Findings and fixes

Per-MUST results from the verifier:

### helm-config-update (expected-output)
Stops: 3 (target 3: F1, F2, F4) — PASS. Unscripted: 0.

`stops.md:1-3` is F1, F2, F4 in order. No pre-flight ran inline: the existing record was reused (`preflight-record.md:1-4`).

| # | MUST (short) | PASS/FAIL | Evidence | Cause (FAIL only) |
|---|---|---|---|---|
| 1 | Stops F1, F2, F4 in that order; no `[F3]`; code shown inside `[F4]` with the PR action | PASS | `stops.md:1-3`; code summary, diff and plan command at `transcript.md:348-369`, PR prompt `:371-377` | |
| 2 | `[F2]` waives a soft stop and asks to skip a hard gate; the reply honours the F3 waiver and refuses the pre-flight skip citing `H9` | PASS | Operator message `transcript.md:222`; reply `:231` (F3 waiver honoured, `Waived: F3 — operator, 14:38`) and `:233` ("Not skipped: pre-flight. H9 says ... I will reuse the 10:30 record if it matches ... otherwise I run pre-flight inline"). Refusal is of the skip, reuse allowed | |
| 3 | `**Waived:** F3 — operator, <time>`; names F3 only; pre-flight request and `H9` not listed as waived | PASS | `record.md:16` `**Waived:** F3 — operator, 14:38`; no other waiver line. `record.md:76` mentions the skip request only as refused under H9 | |
| 4 | Pre-flight clearance present; record never says skipped; `**Pre-flight record:**` says which | PASS | `record.md:11` "reused under the Step 4b match rule — verdict: GREEN — PROCEED". Match rule `transcript.md:315-318` (hash equal, target same, 4 h 17 min old inside 24 h), Q1–Q3 re-asked inside `[F2]` `:217`, category-10 reads re-run `:324-326`. `grep -i skipped record.md` returns nothing. Note: README says "3.5 hours old"; the run clock gives 4 h 17 min (record 10:30, now 14:47). The rule is the 24 h window, so this does not change the result | |
| 5 | Waiving the stop does not waive the checks: self-check result and fresh-eyes line in `[F4]` and in `record.md` | PASS | `[F4]` `transcript.md:353` "Self-check: 6/6 pass · Fresh eyes: not run — dry run"; `record.md:71-72` | |
| 6 | `**Lane:** full — <basis>` (Deployment update not on the Kubernetes allowlist); `**Escalations:** none` | PASS | `record.md:12` ("updating a `Deployment` is not on the Kubernetes light-lane allowlist"), `record.md:13` | |
| 7 | `**Environment tier:** prod=prod (operator-stated ...)`; tier unproven, prod gate levels | PASS | `record.md:14` "prod=prod (operator-stated, unproven: no pin in the repo ...)"; prod gate levels `transcript.md:72` | |
| 8 | `**Staging-first:** n/a — no staging env (<evidence>)` with `values-prod.yaml` the only env values file named; `- Parity check: n/a` | PASS | `record.md:15` (`values-prod.yaml` is the only per-environment values file; the other text is the pattern `values-{env}.yaml`, not a named file); `record.md:75` | |
| 9 | If pre-flight runs inline: at most two Yellow, GREEN or YELLOW, RED is a finding | PASS | Pre-flight did not run inline; the reused record is GREEN — PROCEED (`preflight-record.md:16`, `record.md:11`). No RED, no `[H5]` | |
| 10 | No stop logged as `unscripted` | PASS | `grep -c unscripted stops.md` = 0 | |

Observation: the reused record scores 10 categories and the skill now defines 11 (`transcript.md:328`, `preflight-record.md:121`). The match rule does not check this. Not a MUST line.


Fix applied after the first v0.18 run: the record wrote ``**Waived:** `[F3]` `` (brackets and backticks). Constraint 15 and the 5b template now say the value is the bare stop ID (`**Waived:** F3 — operator, <time>`). Re-run: the table above is from the re-run.

## Baseline (v0.18 expected-output)

Measured on `expected-output/` (the v0.18 run) and on the v0.18 script (`git show main:tests/fixtures/iac-change-execution/helm-config-update/operator-script.md`, "Answers by stop"). A v0.20 run goes to `expected-output-v020/` and is compared with these figures.

- **Stops: 3** (`grep -c '^STOP ' expected-output/stops.md`): F1, F2, F4.
- **L2 items in the v0.18 script: 12** (Q1–Q7, Q8 `if asked`, `iac-change.1`–`iac-change.4`). This is the v0.18 figure for typed L2. v0.20 target: 0.

## v0.20 run

Simulated dry-runs (canned command output), sonnet runner following SKILL.md on branch feat/iac-change-snapshot-and-l2. The 2026-11-20 re-run replaced the 2026-11-18 out-dir.

### operator-script.md, 2026-11-18 (before the founder decisions)
- Out-dir: `expected-output-v020/`
- Stops: 3 → 4 (F1, F2, H5, F4).
- Typed L2: 12 → 0.
- Snapshot commands added: 1 (S0 combined `kubectl get deploy,sts,pods,events,hpa` read) plus 2 automation-lag reads (`helm history`, `gh run list`). S1 re-read the 1.
- MUST: 17 PASS / 0 FAIL.
- Stop target 4 is decided (founder, 2026-11-20): a change applied at merge keeps `Q3=unsure`, see README.
- This run's snapshot set had no dependents or dependencies: the text then skipped scaling counts.

### operator-script.md, 2026-11-20 (after the founder decisions)
- Out-dir: `expected-output-v020/`, replacing the 2026-11-18 output.
- Stops: 3 → 4 (F1, F2, H5, F4). Unscripted: 0. `[F3]` waived at `[F2]`; the pre-flight skip refused (H9); pre-flight ran inline, `RED — soft block`, shown as `[H5]`.
- Typed L2: 12 → 0 (L2-ASKED 0).
- Snapshot set as shown: Deployment `notifyapi` (changed) · Service `notifyapi` (`n/a — no health signals of its own`) · SQS `notifyapi-prod-inbound` (dependency) · SMTP relay and SES (catalog leads, not snapshotted). Coverage: code + catalog + live kubectl and CloudWatch; not covered: callers outside the repo, SMTP, SES, and notifyapi's error rate, latency and alerts (no metrics backend).
- Snapshot commands per environment: 6 (`kubectl get deploy`, `kubectl get pods`, `kubectl get events`, `kubectl get hpa`, `aws cloudwatch describe-alarms`, `aws cloudwatch get-metric-data`), one over the "about five" target, because Kubernetes state is read per type. Run at S0 and again at S1 (S0 was 17 minutes old). No S2: the PR is open.
- Q3 took its peak hours (09:00–12:00 +07:00) from the queue's `NumberOfMessagesSent`. The README MUST, as relaxed after review, allows peak hours only from a member `snapshot.md` › L2 from evidence names (a load balancer, or the service in front of an RDS instance), so this is a deviation for the verifier to score.
- Fixture gaps, `no canned output` (5 occurrences, 4 commands): `kubectl get events` with `type=Warning` (S0 14:18, S1 14:48); `kubectl get ingress -A` (14:24); `kubectl config view --minify` for the API server (pre-flight target check, 14:54); a pricing docs lookup (14:58). Rows and a `docs.md` entry for all four were added after the run; it was not re-run.
