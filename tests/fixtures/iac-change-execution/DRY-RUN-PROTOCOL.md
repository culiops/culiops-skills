# Dry-run protocol for the iac-change-execution fixtures

A dry run plays the skill against one fixture without touching anything real. A runner follows the skill text step by step, looks up the output of every command in the fixture's canned files, and answers every operator stop from the fixture's operator script. It records what the skill text made it do. Later tasks compare those records with the fixture's `## MUST (v0.18)` list.

Used for the baseline run of the old skill (`<out-dir>` = `baseline-output`) and for runs of the new skill (`<out-dir>` = `expected-output`, or `expected-output-v018` for the pre-flight regression run).

## What the runner is given and what it reads

- The fixture directory, the skill under test (`SKILL.md` and every file it points to), the name of the operator script (`operator-script.md` unless told otherwise), and the `<out-dir>` name.
- The runner reads: the IaC or chart files, any `.culiops/` records already in the fixture (catalog, earlier pre-flight record), the operator script, and `canned/INDEX.md` with the canned files it lists.
- The runner does **not** read `README.md` or `DRY-RUN-NOTES.md` in the fixture. They hold the expected behaviour and would anchor the run. It also reads no other fixture and no earlier out-dir.
- The first message to the skill is the `First message` line at the top of the operator script.
- Dry-run clock: `canned/INDEX.md` gives the start time. The runner advances it one minute per command and five minutes per operator answer, unless a canned file carries its own time. Every time in the transcript and the records comes from this clock.

## Rules

1. **Canned lookup.** When the skill would run a command, the runner looks it up in `canned/INDEX.md` (command pattern → file). A row matches when its pattern matches the command and its `Use when` condition holds. If no row matches, the runner prints `no canned output` and treats the read as failed; the skill text then says what happens next (for pre-flight, the category stays unknown). The runner never invents output.
   - **Environment.** In a fixture with more than one environment, several rows can match one command, because the same read exists for each environment. The runner picks the row for the environment the command targets, found in this order: (a) the command itself: `--profile`, `-var-file=envs/<env>.tfvars`, a workspace, `--context` or `-n <namespace>`, or a resource name or ARN that carries the environment (`paymentapi-cluster-staging`); (b) otherwise the environment the skill is working on at that moment, the one its current plan, read batch or apply is for. Some commands read the same in every environment, such as `aws sts get-caller-identity` and `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi`; for those, (b) decides. The runner never answers one environment's command with another environment's file, except where an INDEX row is keyed to a named operator script: that row overrides this rule for that script (for example `dev-lane`'s `operator-script-mismatch.md` returns the prod STS file while the skill works on dev). Whenever (b) decided, it notes the environment it took in `transcript.md`.
   - **State.** Where rows differ by state (before or after an apply, a reboot or a merge), the `Use when` column says which. The runner follows what has already happened in the run.
   - If several rows still match after that, the first one in table order whose `Use when` holds is used.
   - A pattern ignores `--profile`, `--region`, `--output` and `--no-cli-pager`. For `--query`, the runner applies the JMESPath to the canned JSON itself; a field that is not in the file gives `null`.
   - Reading the fixture's own input files (Read, `grep`) is not a command lookup. It stands in for `cat`, `git grep` and `git show origin/<default>:<path>`: `git grep` is answered with a `grep -rn -F` over the fixture's input files (not `README.md`, `DRY-RUN-NOTES.md`, `operator-script*.md`, `canned/`, or any out-dir).
   - Every other git command, and every aws, kubectl, terraform, helm and gh command, goes through the lookup.
2. **Operator answers.** They come from the operator script, matched by stop ID (`A`, `B`, `D1`, `F1`–`F4`, `H1`–`H9`) in the order the script lists them. For an older skill with no stop IDs, the runner maps each stop by meaning, using the script's `Answers by meaning` note. A script entry is used once. If the skill asks something the script does not cover, the runner answers "approve / yes / as proposed" and logs the stop as `unscripted`.
   - A script entry can hold several items. An item marked `if asked` is said only when the skill asks that question. Every other item (the L2 answers, a tier statement) is said in that stop's answer, as the operator would say it. The runner says nothing else.
   - Every prompt that waits for the operator is one stop, even when one answer covers several questions.
3. **Outputs.** The runner writes these files, and only these, in `<fixture>/<out-dir>/`:
   - `stops.md`: one line per stop, in order, nothing else: `STOP <n>: <id or unscripted> — <question, one line>`. `<id>` is the stop's bracketed ID in the new skill, or the skill's own label (for example `GATE 2`, `read batch`) in an older skill. It is `unscripted` when the script had no entry for that stop.
   - `transcript.md`: the run in order. Each skill message shown to the operator, each command with the canned file used (or `no canned output`), each operator answer with the script entry it came from, each code diff, and a note wherever the canned plan does not match the code the skill wrote.
   - `record.md`: the execution record the skill would write under `.culiops/iac-change-execution/`.
   - `preflight-record.md`: the pre-flight record, if the run wrote one (inline mode, or a reused record shown as reused).
4. **Out-dir.** `<out-dir>` is `baseline-output` for a baseline run of the old skill and `expected-output` for a run of the new skill. The runner creates it if it is missing and replaces its own earlier files there.
5. **Safety.** The runner never executes any command the skill would run: no aws, kubectl, terraform, helm, gh, and no git branch, commit or push in the repo. Every command is simulated through the canned lookup.
   - The runner never edits fixture input files. It writes only inside `<fixture>/<out-dir>/`.
   - Code the skill would write is shown as a unified diff in `transcript.md`. After the skill "writes" code, `git status --short` and `git diff` are answered from that diff.
   - Records the skill would write under `.culiops/` go to `record.md` and `preflight-record.md`, not into the fixture.
   - The runner is not the judge. It records what the skill text makes it do, including the stops the text forces, and it does not skip a stop because the fixture "expects" fewer.

## Notes for the run

- **Time.** `date` and any other read of the time return the dry-run clock.
- **Plan hash.** `canned/INDEX.md` gives the SHA-256 of each canned plan text. When the skill hashes a plan, the runner uses that value.
- **Canned plan versus code.** The canned plan was written for the change as the first message asks for it, with names and values that follow the repo's existing code. If the skill writes code that would plan differently, the runner notes the difference in the transcript and still uses the canned plan.
- **State.** A few canned files depend on what already happened (before and after an apply, before and after a reboot). `canned/INDEX.md` says when each applies.
- **Separate reviewer (fresh eyes).** How a reviewer is simulated is set in the run instructions. The default is `fresh-eyes: not run — dry run`.
- **End of run.** The run ends when the skill prints its final message or the operator aborts. An abort still writes `record.md`.
