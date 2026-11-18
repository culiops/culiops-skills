# Dry-run notes — `dependency-regression`

Notes for the person checking a run. The runner does not read this file (`../DRY-RUN-PROTOCOL.md`). The expected behaviour is in `README.md` › `## MUST (v0.20)`.

### Known runner deviations (v0.20 round 3)

Deviations from skill text that the MUST checker judged clear. The skill text is not changed for them; a re-run should show whether they recur.

- (c1) `[F2]` showed the snapshot set without a source for each member (MUST D4, both scripts). The sources appeared only in the research narration before `[F1]` and in the record. `snapshot.md:7` ("every member its source") and the SKILL.md research summary (`Snapshot set: <members, each with its source and any label>`) ask for them in the stop.
- (c3) `[H10]` gave before and after values without each read's command (MUST D9, both scripts). `snapshot.md` › After a regression lists "each read's command and time" for every regressed signal.
- (c4) Prod's pre-flight cited staging's snapshot as `live: staging S2 <time>`, without the command (`operator-script-override.md`, MUST O5). SKILL.md Step 4b › Prod after staging and `snapshot.md` › After a regression ask for `live: <cmd> (staging, <time>)`.

## v0.20 run

Simulated dry-run (canned command output), 2026-11-18, sonnet runner following SKILL.md on branch feat/iac-change-snapshot-and-l2.

No v0.18 baseline: this fixture is new in v0.20. Stop target 6 (+1 `[H5]` per RED pre-flight).

### operator-script.md
- Out-dir: `expected-output-v020/`
- Stops: n/a → 6 (F1, F2, F3, H5, F4, H10).
- Typed L2: n/a → 1 (Q8; the log line is in backticks in the transcript).
- Snapshot commands added per snapshot: 5 (2 snapshot-only plus 3 shared state reads). Staging S0, S1, S2 and prod S0 were taken.
- MUST: 14 PASS / 2 FAIL (D4, D9; both listed above as c1 and c3).

### operator-script-override.md
- Out-dir: `expected-output-v020-override/`
- Stops: n/a → 8 (F1, F2, F3, H5, F4, H10, H5, F4; two RED pre-flights).
- Typed L2: n/a → 1 (Q8).
- Snapshot commands added per snapshot: 5 per environment (2 snapshot-only plus 3 shared); S0, S1 and S2 each stay at 5.
- MUST: 15 PASS / 3 FAIL (D4, D9, O5; listed above as c1, c3 and c4).
