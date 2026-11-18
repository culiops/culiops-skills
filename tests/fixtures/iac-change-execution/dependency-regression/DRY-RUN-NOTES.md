# Dry-run notes — `dependency-regression`

Notes for the person checking a run. The runner does not read this file (`../DRY-RUN-PROTOCOL.md`). The expected behaviour is in `README.md` › `## MUST (v0.20)`.

### Known runner deviations (v0.20 round 3)

Deviations from skill text that the MUST checker judged clear. The skill text is not changed for them; a re-run should show whether they recur.

- (c1) `[F2]` showed the snapshot set without a source for each member (MUST D4, both scripts). The sources appeared only in the research narration before `[F1]` and in the record. `snapshot.md:7` ("every member its source") and the SKILL.md research summary (`Snapshot set: <members, each with its source and any label>`) ask for them in the stop.
- (c3) `[H10]` gave before and after values without each read's command (MUST D9, both scripts). `snapshot.md` › After a regression lists "each read's command and time" for every regressed signal.
- (c4) Prod's pre-flight cited staging's snapshot as `live: staging S2 <time>`, without the command (`operator-script-override.md`, MUST O5). SKILL.md Step 4b › Prod after staging and `snapshot.md` › After a regression ask for `live: <cmd> (staging, <time>)`.
