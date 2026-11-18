# Dry-run transcript — multi-phase-rds-upgrade (skill: iac-change-execution v0.20, branch feat/iac-change-snapshot-and-l2)

Operator script: `operator-script.md`. Out-dir: `expected-output-v020`. Dry-run clock starts 2026-11-09 10:00 +07:00 (03:00Z), one minute per command, five minutes per operator answer. Times below are +07:00 unless marked Z.

Run-level notes (apply to the whole run):
- Environment: the repo has one env file, `envs/prod.tfvars`. Every canned lookup is for prod (rule 1(a)/(b)). Commands that read the same in every environment (`aws sts get-caller-identity`, the alarm prefix read) were decided by (b): the environment the skill is working on, prod.
- `CULIOPS_HOME`: nothing in the fixture or the canned files sets it, so it is treated as unset. Output root = `.culiops/` at the repo root. Profile path = `~/.culiops/operator.md`.
- PROFILE-WRITE: none. Q4 and Q5 came from the profile, no answer was typed, nothing is saved.
- AMBIGUITY: `terraform plan` needs `var.db_password` (variables.tf:34-38, no default, absent from envs/prod.tfvars) and the skill text does not say how a plan gets a secret — reading taken: the operator's own environment supplies it (`TF_VAR_db_password`), the skill never reads or shows it, and the canned plan is used as given.
- AMBIGUITY: no `backend` block anywhere in the code (git grep 10:08), so the state location is not in the repo. The skill text names `{state-bucket}`/`{state-key}` for the automation-lag read but gives no source for them when the code declares none — reading taken: the S3 `head-object` read is not proposed (no bucket to name, none invented); `iac-change.4` is answered `unsure (UNVERIFIED)` from the reads that can run.

---

## Operator's first message

> Increase max_connections to 200 for paymentapi prod RDS, then reboot so it takes effect. I am the DBA on the maintenance window. Apply directly, no PR.

---

## Step 1 — Research

Identity read first (exempt from opt-in, Constraint 3), then the local reads.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:01 | `aws sts get-caller-identity` | `identity-prod.json` (env prod, (b)) | Account `123456789012`, `arn:aws:sts::123456789012:assumed-role/paymentapi-operator/operator` |
| 10:02 | read `~/.culiops/operator.md` | `operator-profile.md` (row `operator profile read`) | Q5 terraform = experienced (2026-10-19); Q4 `acme/paymentapi-infra/paymentapi` = many times (2026-10-19); no `incident check:` line |
| 10:03 | `git branch --show-current` | `git-branch.txt` | `main` |
| 10:04 | `git status --short` | `git-status-clean.txt` | (empty) — clean tree |
| 10:05 | `git grep -n -F 'max_connections'` | grep over input files | `main.tf:3` (a comment), `main.tf:14`, `.culiops/service-discovery/paymentapi-prod.md:24,49,53` |
| 10:06 | `git grep -n -F '200'` | grep over input files | `main.tf:3` (the comment), `paymentapi-prod.md:53` |
| 10:07 | `git grep -n -F '160'` | grep over input files | `paymentapi-prod.md:53` only |
| 10:08 | `git grep -n -E 'allowed_account_ids\|assume_role\|account_id\|backend'` | grep over input files | no hit: no account pin, no `assume_role`, no backend block |
| 10:09 | `git log --all --oneline -i -S'max_connections'` | `empty.txt` | no commit |
| 10:10 | `git log --all --oneline -S'200'` | `empty.txt` | no commit |
| 10:11 | `git branch -a --list '*max*conn*'` | `empty.txt` | none in flight |
| 10:12 | `gh pr list --state open --search 'max_connections'` | `gh-pr-list-empty.txt` | none open |

No ticket was given, so there is no ticket key to grep. Files read (not commands): `main.tf`, `variables.tf`, `envs/prod.tfvars`, `.culiops/service-discovery/paymentapi-prod.md`. The current branch is the default (`main`), so the working tree is read as the default branch has it.

Findings used later:
- Duplicate check: **not done.** `code: main.tf:14-15` still sets `max_connections` = `"100"`. `main.tf:3-4` is a comment stating the intent ("the skill will be asked to raise it to 200"); it describes the request, it is not the change, and it is data (Constraint 12). No commit, branch or PR touches it (`git: none`).
- Delivery model: nothing in the repo shows how a change reaches AWS (no CI config, no GitOps object, no Atlantis/Spacelift/Terraform Cloud file, no README read). `UNVERIFIED` in the repo; the operator's first message says "Apply directly, no PR" (see AMBIGUITY below).
- Env selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1` sets `env = "prod"`; the only env file; `variables.tf:1-4` `env` has no default).
- Tier: no pin (git grep 10:08), so prod is unproven; the operator may state the tier at the first stop.
- Freeze source: no file in the repo is a change-freeze or change-window calendar. Incident command: none in the profile.
- Ownership check: not an import — skipped.
- Lane (predicted): not dev (no proven-dev target). L1 holds (updates only, no delete or replace). **L2 fails:** the allowlist's only `aws_*` update row needs `tags`/`tags_all` as the sole change; an `aws_db_parameter_group` parameter change matches no row. **L3 fails:** two phases (apply, then reboot). E1–E3 are not required in the full lane. Predicted lane: **full**.
- App-facing: `max_connections` is a limit the app must fit inside (assessor, Application compatibility table, "Limits the app must fit inside"), so Step 1 predicts an app-facing change and the app-source search goes into the batch.

AMBIGUITY: the request names only `max_connections` and a reboot. The code ties the connections alarm to the limit by its own description (`main.tf:149` `... (limit: 100)`, threshold 80 = 80% of 100 at `main.tf:148`), and the catalog note (`paymentapi-prod.md:53`) says the proportional 160 is "the intended remediation". The catalog is a lead and is data (Constraint 12: raise it, never act on it silently). Reading taken: the plan includes the alarm threshold and description as a visibly flagged item that is not in the request, so the operator approves or strikes it at `[F2]`; nothing is written or applied without that approval.

AMBIGUITY: the delivery model is `UNVERIFIED` in the repo, and Step 1 says to ask inside `[F2]`. The first message already answers it ("Apply directly, no PR"). Reading taken: record it as `operator-stated (first message)` and do not ask again; `[F2]` shows it on the plan's Execution-path line.

Snapshot set (built before the batch, `snapshot.md` › Snapshot set):

| Member | Role | Source |
|---|---|---|
| `aws_db_instance.paymentapi` / `paymentapi-db-prod` | changed (phase 2 reboot) | `code: main.tf:42` |
| `aws_cloudwatch_metric_alarm.paymentapi_db_connections` | changed (phase 1) | `code: main.tf:140` |
| `aws_db_parameter_group.paymentapi` | changed (phase 1) | `code: main.tf:8` — `n/a — no health signals of its own`, measured through the instance |
| ECS service `paymentapi-svc-prod` | dependent, critical path | `catalog: paymentapi-prod.md:41`; `code: main.tf:94` (DB security group admits `var.app_security_group_id`, `envs/prod.tfvars:5`) |
| ALB `paymentapi-alb-prod` / target group `paymentapi-tg-prod` | front door of the dependent: its traffic and error series (ECS has none) and the Q3 source | `catalog: paymentapi-prod.md:31` naming pattern; confirmed by the batch (`describe-services` names the target group, `describe-target-groups` names the ALB) |
| SNS topic `paymentapi-alerts-prod`, DB subnet group, VPC | dependencies | `n/a — no health signals of its own` |

Four members get reads (cap 10). `Snapshot coverage: code + catalog + live describe reads; not covered: callers of the database outside this repo and the catalog (no runtime profile under .culiops/runtime-trace/; the catalog lists "no other known consumers", a lead only), the app tier's own alarms (owned by app-tier Terraform)`.

AMBIGUITY: the ECS cluster name, the target group name and the ALB name are in no code file. The catalog gives only the naming pattern `paymentapi-{role}-{env}` (`paymentapi-prod.md:31`) with roles `svc`, `tg`. Reading taken: the batch names `paymentapi-cluster-prod` and `paymentapi-tg-prod` from that pattern, labelled as pattern-derived leads; a failed read leaves the member `no data`. The ALB is named from the target group's own output, not guessed.

AMBIGUITY: some batch reads take an argument from an earlier read (the parameter group name from the instance read, the target group ARN and the task definition from the ECS read, the ALB ARN from the target group read). Reading taken: the batch shows each such command with a `<from Bn>` placeholder, and the operator approves the command shape; the resolved command is shown in the transcript when it runs.

### [F1] message shown to the operator (10:12)

**[F1] Run these reads?**

Target: account `123456789012` / region `ap-southeast-1` (`live: aws sts get-caller-identity`, 10:01: `assumed-role/paymentapi-operator/operator`). Output root: `.culiops/` at the repo root (`CULIOPS_HOME` unset); records are written there, never the query file anywhere else.
Environment tier: `prod = unproven` — no pin in the repo (`git grep` 10:08 found no `allowed_account_ids`, `assume_role` or account variable). Unproven counts as prod. If you want it recorded as stated, say which tier it is.
Lane (predicted): **full** — L2 fails (an `aws_db_parameter_group` parameter change is off the allowlist), L3 fails (two phases). Escalations: none needed.
Duplicate check so far: not done (`code: main.tf:14-15`, `git: none`).
Snapshot set: the table above, with its coverage line.

Reads (read-only; the identity read already ran):
1. `terraform init` — downloads providers, may update `.terraform.lock.hcl` (local only).
2. `terraform plan -refresh-only -var-file=envs/prod.tfvars` — drift check, never applied.
3. `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --region ap-southeast-1 --query 'DBInstances[].{status:DBInstanceStatus,class:DBInstanceClass,engine:EngineVersion,multiAz:MultiAZ,pending:PendingModifiedValues,paramGroups:DBParameterGroups,deletionProtection:DeletionProtection,backupRetention:BackupRetentionPeriod,latestRestorable:LatestRestorableTime,storageGb:AllocatedStorage}'`
4. `aws rds describe-db-parameters --db-parameter-group-name <from 3: DBParameterGroups[0]> --region ap-southeast-1 --query "Parameters[?ParameterName=='max_connections']"`
5. `aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod --region ap-southeast-1 --query 'sort_by(DBSnapshots,&SnapshotCreateTime)[-3:].{id:DBSnapshotIdentifier,created:SnapshotCreateTime,status:Status,type:SnapshotType}'` (assessor L3: reversibility)
6. `aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name DatabaseConnections --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled,threshold:Threshold}'` (assessor L3: observability)
7. the same for `--metric-name CPUUtilization`
8. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,threshold:Threshold,desc:AlarmDescription,actionsEnabled:ActionsEnabled,actions:AlarmActions}'`
9. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod --history-item-type StateUpdate --start-date 2026-11-08T03:00:00Z --end-date 2026-11-09T03:00:00Z` (last-24h form; the canned file is returned as it is)
10. `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --query 'Subscriptions[].Protocol'` (protocols only, never endpoints: is the alarm notify-only?)
11. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,taskDef:taskDefinition,tg:loadBalancers[].targetGroupArn,deploy:deploymentConfiguration,deployments:deployments[].{status:status,rollout:rolloutState,created:createdAt}}'` (dependent state, deployment settings, automation lag)
12. `aws elbv2 describe-target-health --target-group-arn <from 11> --region ap-southeast-1`
13. `aws elbv2 describe-target-groups --target-group-arns <from 11> --region ap-southeast-1 --query 'TargetGroups[].{name:TargetGroupName,lbs:LoadBalancerArns}'`
14. `aws elbv2 describe-load-balancers --load-balancer-arns <from 13> --region ap-southeast-1 --query 'LoadBalancers[].{name:LoadBalancerName,scheme:Scheme,state:State.Code}'`
15. `aws ecs describe-task-definition --task-definition <from 11> --region ap-southeast-1 --query 'taskDefinition.containerDefinitions[].image'` (image tags only, no environment values; the deployed ref for Q8)
16. `gh run list --limit 5 --json databaseId,status,conclusion,createdAt,updatedAt,headSha,url` (automation lag: CI history)
17. `ls ..` (app-source sibling search, only because Step 1 predicts an app-facing change)
18. `git -C ../paymentapi remote get-url origin` (directory name matches the service)
19. `git -C ../dotfiles remote get-url origin` (see AMBIGUITY)
20. `git -C ../paymentapi rev-parse HEAD`
21. S0: `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,ns:Namespace,metric:MetricName,dims:Dimensions,math:Metrics[].MetricStat.Metric.Dimensions},composite:CompositeAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,rule:AlarmRule}}'`
22. S0: `aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-prod.json --start-time <T-7d-1h> --end-time <now> --scan-by TimestampAscending --query 'MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]}'` (one query file, every member's signals; metric identifiers only)

S1 runs on this same approval, before the apply. Not proposed: an S3 `head-object` on the Terraform state (no state bucket or key in the code) and any incident command (none in the profile). Success-criteria reads and the plan command are approved later (`[F2]`, `[F3]`).

AMBIGUITY: `snapshot.md` says to look at checkouts "whose directory name or `origin` remote matches", while `examples/aws.md` says to read `origin` for each candidate whose directory name matches. Reading taken: read `origin` for every sibling directory that is not this repo (`paymentapi`, `dotfiles`), so a match by remote is also caught (reads 18-19).

### Operator answer 1 (script entry 1, `[F1]`) — 10:17

> Approve the read batch, every command shown, the target check included. Tier: prod (operator-stated).

Recorded: `Environment tier: prod=prod (operator-stated; no pin found: git grep 10:08)` — still unproven, prod gate levels.

### Batch run (10:18–10:39)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:18 | `terraform init` | `terraform-init.txt` | "successfully initialized", lock file reused (`hashicorp/aws v5.74.0`), no lock change |
| 10:19 | `terraform plan -refresh-only -var-file=envs/prod.tfvars` | `plan-refresh-only-prod.txt` | "No changes. Your infrastructure still matches the configuration." — no drift |
| 10:20 | read 3 (`describe-db-instances`) | `rds-instance-prod.json` + `--query` | status `available`; `db.r6g.large`; engine 15.4; MultiAZ `true`; pending `{}`; DBParameterGroups `paymentapi-prod-20250617043012345600000001` `in-sync`; deletionProtection `true`; backupRetention 7; latestRestorable `2026-11-09T02:55:00+00:00`; storage 100 GB |
| 10:21 | read 4 with `paymentapi-prod-20250617043012345600000001` | `rds-parameters-max-connections-before.json` | `max_connections` = `100`, Source `user`, **ApplyType `static`**, ApplyMethod `pending-reboot` |
| 10:22 | read 5 (`describe-db-snapshots`) | `rds-snapshots-prod.json` + `--query` | 3 automated snapshots, `available`; newest `rds:paymentapi-db-prod-2026-11-09-02-05` (2026-11-09T02:05:12Z) |
| 10:23 | read 6 (`describe-alarms-for-metric` DatabaseConnections) | `alarms-for-metric-connections-prod.json` | `paymentapi-db-connections-high-prod`, `OK`, ActionsEnabled `true`, threshold 80 |
| 10:24 | read 7 (CPUUtilization) | `alarms-for-metric-cpu-prod.json` | `paymentapi-db-cpu-high-prod`, `OK`, ActionsEnabled `true`, threshold 80 |
| 10:25 | read 8 (`--alarm-name-prefix paymentapi`) | `alarms-prefix-prod.json` | 2 alarms, both `OK`, actions = SNS `paymentapi-alerts-prod`; connections alarm description `... above 80 ... (limit: 100)`, last config update 2026-11-08T21:47:03Z |
| 10:26 | read 9 (`describe-alarm-history`) | `alarm-history-connections-prod.json` | 3 OK→ALARM→OK cycles in 5 days (2026-11-04 12:20Z, 2026-11-06 09:02Z, 2026-11-08 21:39Z), each 8–12 minutes |
| 10:27 | read 10 (SNS protocols) | `sns-subscriptions-prod.json` + `--query Protocol` | `["email","email"]` — notify-only |
| 10:28 | read 11 (`describe-services`) | `ecs-describe-services-prod.json` + `--query` | `ACTIVE`, desired 3, running 3, pending 0; task definition `paymentapi-prod:12`; target group `.../targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`; deployment config min healthy 100 / max 200, circuit breaker off; one PRIMARY deployment `COMPLETED`, created 2026-10-12T14:02:11Z |
| 10:29 | read 12 with the target group ARN from 11 | `tg-health-prod.json` | 3 targets, all `healthy` |
| 10:30 | read 13 with the same ARN | `tg-describe-prod.json` + `--query` | `paymentapi-tg-prod`, LB `.../loadbalancer/app/paymentapi-alb-prod/50dc6c495c0c9188` |
| 10:31 | read 14 with that ARN | `lb-describe-prod.json` + `--query` | `paymentapi-alb-prod`, `internal`, `active` |
| 10:32 | read 15 with `paymentapi-prod:12` | `ecs-describe-task-definition-prod.json` + `--query` | `["123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/paymentapi:v2.4.1"]` — deployed tag **v2.4.1** |
| 10:33 | read 16 (`gh run list`) | `gh-run-list-empty.json` | `[]` — no CI history |
| 10:34 | read 17 (`ls ..`) | `siblings-ls.txt` | `dotfiles`, `paymentapi`, `paymentapi-infra` (this repo) |
| 10:35 | read 18 | `sibling-origin-paymentapi.txt` | `git@github.com:acme/paymentapi.git` |
| 10:36 | read 19 | `sibling-origin-dotfiles.txt` | `git@github.com:acme/dotfiles.git` — not the app |
| 10:37 | read 20 (`rev-parse HEAD` in `../paymentapi`) | `app-source-rev-parse.txt` | `5d1c8e4a7b2f90361a4c6e8d0b3f5a7c9e1d2b4f` |
| 10:38 | read 21 (S0 alarms) | `alarms-firing-prod.json` | `{"MetricAlarms":[],"CompositeAlarms":[]}` — nothing firing in the region |
| 10:39 | read 22 (S0 metrics) | `metric-data-s0-prod.json` | see below |

The query file the skill writes (metric identifiers only; not written in a dry run — it would sit at `.culiops/iac-change-execution/snapshot-queries-prod.json`). `Period` is 3600 for S0 and S1, and 300 for S2. LB dimension `app/paymentapi-alb-prod/50dc6c495c0c9188`, target group dimension `targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`:

```json
[
 {"Id":"cpu_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"CPUUtilization","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"paymentapi-db-prod"}]},"Period":3600,"Stat":"Average"},"Label":"paymentapi-db-prod CPUUtilization"},
 {"Id":"conn_db_avg","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"DatabaseConnections","Dimensions":[...same]},"Period":3600,"Stat":"Average"},"Label":"paymentapi-db-prod DatabaseConnections"},
 {"Id":"conn_db_max","MetricStat":{"Metric":{... "DatabaseConnections" ...},"Period":3600,"Stat":"Maximum"},"Label":"paymentapi-db-prod DatabaseConnections Maximum"},
 {"Id":"rlat_db", ... "ReadLatency" ... "Average"}, {"Id":"wlat_db", ... "WriteLatency" ... "Average"},
 {"Id":"mem_db", ... "FreeableMemory" ... "Minimum"}, {"Id":"stor_db", ... "FreeStorageSpace" ... "Minimum"},
 {"Id":"cpu_svc", ... "AWS/ECS" "CPUUtilization" ClusterName=paymentapi-cluster-prod, ServiceName=paymentapi-svc-prod ... "Average"},
 {"Id":"mem_svc", ... "AWS/ECS" "MemoryUtilization" ... "Average"},
 {"Id":"req_alb", ... "AWS/ApplicationELB" "RequestCount" LoadBalancer=app/paymentapi-alb-prod/50dc6c495c0c9188 ... "Sum"},
 {"Id":"m_5xx_alb", ... "HTTPCode_Target_5XX_Count" ... "Sum", "ReturnData":false}, {"Id":"err_alb","Expression":"FILL(m_5xx_alb, 0)","Label":"paymentapi-alb-prod HTTPCode_Target_5XX_Count"},
 {"Id":"m_elb5xx_alb", ... "HTTPCode_ELB_5XX_Count" ... "Sum", "ReturnData":false}, {"Id":"errelb_alb","Expression":"FILL(m_elb5xx_alb, 0)","Label":"paymentapi-alb-prod HTTPCode_ELB_5XX_Count"},
 {"Id":"p95_alb", ... "TargetResponseTime" ... "Stat":"p95"},
 {"Id":"hh_alb", ... "HealthyHostCount" + TargetGroup dim ... "Minimum"}, {"Id":"uh_alb", ... "UnHealthyHostCount" ... "Minimum"}
]
```

(`...` abbreviates repeated dimension blocks in this transcript only; the real file spells them out. `err_*` are count series with `FILL`, `req_alb` is read unfilled, gauges are never filled.)

AMBIGUITY: the skill's S0/S1 form is `Period` 3600 (one value per hour), but the canned file holds each series as 12 values of 300 s (one hour) and the `(1w ago)` series for the same hour a week earlier. Reading taken: for a `Period` 3600 query the runner folds the 12 values into the one hourly value: sum for counts, mean for `Average`, max for `Maximum`, min for `Minimum`, mean for `p95` (the canned data cannot give a true hourly p95; every p95 value is within 0.108–0.122 s, so no verdict depends on the choice). Count series are also shown as per-minute rates (sum ÷ 60), as `examples/aws.md` says.

S0 result (hour ending 10:39 = 03:39Z; same hour last week in brackets; values dated by the runner from the end of the window):

| Member | Signal | Value now [1w ago] |
|---|---|---|
| RDS `paymentapi-db-prod` | CPU avg | 33.8% [34.1%] |
| | connections avg | 51.5 [50.5] |
| | connections max | 78 [76] — **78% of `max_connections` 100** (live: read 4) |
| | read / write latency avg | 1.20 ms / 2.23 ms [1.15 / 2.18] |
| | freeable memory min | 6.10 GB [6.14 GB] |
| | free storage min | 82.0 GB [82.6 GB] |
| ECS `paymentapi-svc-prod` | CPU / memory avg | 37.7% / 51.8% |
| | running vs desired | 3 / 3 (read 11) |
| ALB `paymentapi-alb-prod` | request count | 41,442 in the hour = **690.7 per minute** [680.3 per minute] |
| | target 5xx / ELB 5xx | 0 / 0 (0.000% of requests) [0 / 0] |
| | target response p95 | 0.114 s [0.116 s] |
| | healthy / unhealthy hosts | 3 / 0 (read 12: 3 targets healthy) |
| Alarms firing on the set | | 0 |

S0 time: alarms 10:38, metrics 10:39.

L2 answers derived so far: `Q1(alarms)=no` (read 21, 0 firing); `Q3=no` (690.7 ÷ 680.3 = 1.02× the same hour last week, not above 1.5×).

Evidence table (Constraint 9):

| Fact | Code evidence | Live evidence | Match? |
|---|---|---|---|
| `max_connections` current value | `code: main.tf:14-15` → `"100"` | `live: describe-db-parameters` 10:21 → `100`, ApplyType `static` | match |
| parameter group in use | `code: main.tf:9` `name_prefix`, `main.tf:58` | `live: describe-db-instances` 10:20 → `paymentapi-prod-20250617043012345600000001`, `in-sync` | match |
| `apply_method` on `max_connections` | `code: main.tf:13-16` none (the other two blocks set `immediate`, `main.tf:21,27`) | `live: describe-db-parameters` → ApplyMethod `pending-reboot`; `live: terraform plan -refresh-only` 10:19 → no changes | not a value disagreement; the tool reports no drift, so not a drift row |
| instance class / engine / Multi-AZ | `code: envs/prod.tfvars:6` `db.r6g.large`, `main.tf:46` `15.4`, `main.tf:62` `multi_az` (prod → true) | `live: describe-db-instances` → `db.r6g.large`, `15.4`, `true` | match |
| recovery points | `code: main.tf:63` retention 7, `main.tf:67-68` deletion protection on, final snapshot on | `live: describe-db-instances` → retention 7, latestRestorable 02:55Z; `describe-db-snapshots` → 3 automated, newest 2026-11-09 02:05Z | match |
| connections alarm | `code: main.tf:140-156` threshold 80, description `(limit: 100)`, actions `[var.sns_topic_arn]` = `envs/prod.tfvars:9` | `live: describe-alarms-for-metric` 10:23 → threshold 80, enabled, OK; AlarmActions = that SNS ARN | match |
| alarm is notify-only | `code: main.tf:155-156` | `live: SNS protocols` 10:27 → `email`, `email` | match (E1 is not required in the full lane; shown for pre-flight's not-app-facing list) |
| the app tier connects to the DB | `code: main.tf:94` ingress from `var.app_security_group_id` = `envs/prod.tfvars:5`; `catalog: paymentapi-prod.md:41` | `live: describe-services` 10:28 → service security group `sg-0a1b2c3d4e5f6a7b8`, the same ID | match |
| deployed app image | `code: none` (no ECS code in this repo) | `live: describe-task-definition` 10:32 → `paymentapi:v2.4.1` | no code source; live only |
| how the change reaches AWS | `code: none` — no CI config, no GitOps object, no automation file | `live: gh run list` 10:33 → `[]` | `UNVERIFIED` in the repo; operator-stated direct apply (first message) |
| when this stack was last applied | `code: none` (no backend block) | `live: gh run list` → `[]`; ECS deployment `createdAt` 2026-10-12 is an app deploy, not this stack's apply | `UNVERIFIED` |

Drift rows: 0. Unverified rows: 2 (delivery model in the repo, last apply). No row is `code-only`.

Gaps remaining: the running value of `max_connections` inside PostgreSQL is not read (no SQL access); the task definition's environment names were not read (the query projects images only), so a `DB_POOL_SIZE` override is unknown.

---

## Step 2 — Plan

Branch read: current `main`, tree clean (reads 10:03-10:04). The plan proposes the branch below. Full lane: the branch commands run after `[F2]`.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:40 | `git rev-parse --short origin/main` | `git-rev-parse.txt` (`--short`) | `a1b2c3d` |

Documentation lookups for the claims that drive decisions (Constraint 9; each is a `docs:` read in this session, date 2026-11-09, canned in `docs.md`):

| Time | Subject | Canned entry |
|---|---|---|
| 10:41 | a static RDS parameter needs a reboot | `docs.md` "A static RDS parameter needs a reboot" |
| 10:42 | what a reboot does on a Multi-AZ instance | `docs.md` "What a reboot does on a Multi-AZ instance" |
| 10:43 | `max_connections` on RDS for PostgreSQL is static | `docs.md` "`max_connections` on RDS for PostgreSQL" |
| 10:44 | editing an alarm threshold updates the alarm in place | `docs.md` "Editing a CloudWatch alarm threshold updates the alarm in place" |
| 10:45 | reverting a static parameter | `docs.md` "Reverting a static RDS parameter to its previous value" |

Plan self-check (SKILL.md Step 2, 8 items): 1 pass (every item, its disruption and its rollback cite `code:`/`live:`/`docs:`; nothing rests on `UNVERIFIED` or `catalog:`-only); 2 pass (no delete); 3 pass; 4 pass (no drift); 5 pass (direct apply, no GitOps/CI found); 6 pass with a flag (the alarm item is not named in the request, shown for the operator to strike); 7 pass; 8 pass (exception (a), evidence below). **8/8**.

### [F2] message shown to the operator (10:45)

**Change requested:** raise `max_connections` to 200 on `paymentapi-db-prod`, then reboot so it takes effect. Apply directly.
**Service:** `paymentapi` / **Instance:** `prod`
**IaC tool(s):** Terraform (AWS provider v5.74.0) · **Delivery model:** direct apply from your workstation — `operator-stated` (first message); nothing in the repo shows another path (no CI config, `gh run list` → `[]`, 10:33) · **Env selection:** `-var-file=envs/prod.tfvars`, default workspace (`code: envs/prod.tfvars:1`)
**Target:** account `123456789012` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:01; role `assumed-role/paymentapi-operator`)
**Environment tier:** `prod=prod (operator-stated; no pin in the repo)` · **Lane (predicted):** `full` — L2 fails (parameter-group parameter change is off the allowlist), L3 fails (two phases); escalations: none
**Catalog used:** `.culiops/service-discovery/paymentapi-prod.md` (a lead; confirmed in code and live above)
**Duplicate check:** not done — `code: main.tf:14-15` still `"100"`; `git: none`; no branch or PR in flight
**Evidence table:** as above — drift rows: 0, unverified rows: 2 (delivery model in the repo; last apply)
**Snapshot set:** RDS `paymentapi-db-prod` (changed), connections alarm (changed), parameter group (`n/a — no health signals of its own`), ECS `paymentapi-svc-prod` (dependent), ALB `paymentapi-alb-prod` (front door) · `Snapshot coverage: code + catalog + live describe reads; not covered: callers of the database outside this repo and the catalog, the app tier's own alarms`
**Gaps remaining:** running value inside PostgreSQL not read; task-definition env names not read

> **Change plan for `paymentapi` / `prod`:**
>
> **Phase 1 of 2: raise `max_connections` to 200 (static, takes effect at the reboot) and keep the connections alarm in step**
> - Files: `main.tf`
> - Resources affected: change `aws_db_parameter_group.paymentapi` (in place: `max_connections` 100 → 200, `apply_method = "pending-reboot"`); change `aws_cloudwatch_metric_alarm.paymentapi_db_connections` (in place: threshold 80 → 160, description `(limit: 100)` → `(limit: 200)`). **The alarm item is not in your request.** The code ties it to the limit (`main.tf:148-149`: threshold 80 is 80% of the limit 100, and the description says `limit: 100`) and the catalog calls 160 "the intended remediation" (`paymentapi-prod.md:53`, a lead). Strike it if you do not want it; 160 is 80% of 200, the same ratio. No add, no destroy.
> - Blast radius: the snapshot set above, with its coverage line.
> - Disruption: **none** at apply time. `max_connections` is static: `live: describe-db-parameters` 10:21 → ApplyType `static`; `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html (read 2026-11-09)`: a static parameter's change takes effect only after the instance reboots, the instance shows `pending-reboot` until then. The alarm is updated in place, its state left unchanged: `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html (read 2026-11-09)`; Step 4a confirms both with `plan:`.
> - Rollback path: reversible. Set the value back to `100` in `main.tf` and plan and apply the reverted code through the same reviewed path; `docs: .../USER_WorkingWithParamGroups.html (read 2026-11-09)`: a parameter can be modified back to its earlier value at any time, and a static parameter's restored value takes effect only after the next reboot, no data is changed. Recovery points exist (`live: describe-db-snapshots` 10:22, newest 2026-11-09 02:05Z). Untested.
> - Evidence: rows 1, 2, 3, 6, 7 of the table above.
> - Success criteria (commands with expected output), then S2 on the snapshot set:
>   1. `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"` → `ParameterValue` = `"200"`
>   2. `aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups}'` → status `available`, `ParameterApplyStatus` = `pending-reboot`
>   3. `terraform plan -var-file=envs/prod.tfvars` → `No changes.`
>   4. `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod --query 'MetricAlarms[].{state:StateValue,threshold:Threshold,enabled:ActionsEnabled}'` → threshold `160`, state `OK`, enabled `true`
>   5. S2: `describe-alarms --state-value ALARM` (nothing firing on the set) and the metric and state reads of the snapshot set, once two 5-minute periods have elapsed after the apply
>
> **Phase 2 of 2: reboot `paymentapi-db-prod` so the parameter takes effect (operational command, no IaC change)**
> - Command: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` — no `--force-failover`
> - Resources affected: `aws_db_instance.paymentapi` (rebooted; Terraform sees no change)
> - Blast radius: the snapshot set; the three ECS tasks that connect lose their connections for the duration.
> - Disruption: **brief unavailability** of the database. `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html (read 2026-11-09)`: a reboot restarts the engine and briefly interrupts connections; on Multi-AZ a failover happens only with `--force-failover`, otherwise the reboot is in place. `live: describe-db-instances` 10:20 → `MultiAZ` true, so a standby exists, but this command does not use it. The ECS tasks reconnect through the pool (`app:` evidence is gathered by pre-flight, Step 3b).
> - Rollback path: a reboot cannot be undone. The parameter can be set back to 100 (phase 1's rollback) and takes effect only at another reboot, with the same brief outage. Untested.
> - Evidence: rows 1, 2, 3, 5, 8 of the table above; `docs:` as listed.
> - Success criteria, then S2: `aws rds describe-db-instances ... → DBInstanceStatus = available`, `ParameterApplyStatus = in-sync`, `PendingModifiedValues = {}`; `aws rds describe-db-parameters ... → ParameterValue "200"`; `describe-alarms --state-value ALARM` → none on the set. S2 starts when the status is `available` again and waits two periods after it.
> - Ordering: phase 2 starts only after phase 1's success criteria and S2 pass. Ordering note: between phase 1 and the reboot the alarm threshold is 160 while the live limit is still 100, so the connections alarm cannot fire on connection exhaustion in that window (minutes, with you on the window). If you would rather keep the alarm at 80 until after the reboot, say so and it moves to a third phase.
>
> **Execution path:** Direct apply, as you asked in the first message — this escalates pre-flight (anti-pattern A4: local workstation apply). PR is the default and is not used.
> **Staging-first (H7):** (a) no staging env — `code: envs/` holds only `prod.tfvars`, no staging var-file, workspace or directory is defined · **Observation window:** n/a (no staging)
> **Branch:** current `main` → `iac-change/paymentapi-raise-max-connections` from `origin/main` @ `a1b2c3d` (`git fetch origin main`, then `git switch -c`)
> **Self-check:** 8/8 pass (item 6 flagged: the alarm item is not named in the request)
> **Drift (H4):** none
> **Checked for you:** (correct anything that's wrong)
> - Health: RDS + ECS + ALB — 0 alarms firing in `ap-southeast-1`, target 5xx 0 of 41,442 requests in the hour, RDS CPU 33.8%, DB connections max 78 of `max_connections` 100 (78%) · live 10:38-10:39
> - Peak: no — 690.7 requests/min, same hour last week 680.3/min (1.02×) · live 10:39
> - Last apply: unsure — UNVERIFIED: no state backend in the code, no CI history (`gh run list` → `[]`, 10:33); the ECS deployment of 2026-10-12 is an app deploy, not this stack's apply
> - Experience: Q4 many times, Q5 experienced — operator (profile, 2026-10-19)
> - Snapshot coverage: code + catalog + live describe reads; not covered: callers of the database outside this repo and the catalog, the app tier's own alarms
> - Delivery model: direct apply — operator-stated (first message)
> **App source:** `../paymentapi` @ `5d1c8e4` (HEAD, `v2.5.0-3`, app checkout beside this repo, `origin` `git@github.com:acme/paymentapi.git`); deployed `v2.4.1` (live: `aws ecs describe-task-definition` → `paymentapi:v2.4.1`, 10:32) — correct?
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
>
> **[F2] Approve this plan?**

Note: nothing in the profile or the repo supplies `Q2` (no freeze calendar) or `Q1(declared)` (no incident command), so the operator line is shown.

### Operator answer 2 (script entry 2, `[F2]`) — 10:50

The items the skill asked for are said; the rest of the entry is not said.

> Approve both phases. Execution path: direct apply from my workstation (operator choice). The app source line is correct: yes.

- L2-ASKED: Q8 (App source line: `../paymentapi` @ 5d1c8e4, deployed v2.4.1 — correct?) — yes
- Operator line: no reply (script: `Operator line: no reply`). Recorded as `Q1(declared)=no, Q2=no — operator (no objection at [F2], 10:50)` and `Q7=none`.
- No drift row was shown, so there was nothing to acknowledge. The alarm item stays in the plan (approved with the plan).
- Not said, because the skill did not ask: Q1, Q2, Q3, Q4, Q5, Q6, Q7, `iac-change.1`-`iac-change.4` (all answered by reads, the profile, or the plan), the Incident Context follow-up.

AMBIGUITY: the `App source: ... — correct?` line is Q8's "found, version unknown or different" form, not Q8's `(a)/(b)/(c)` question. The script lists `Q8 (if asked)=yes`, which fits the confirmation. Reading taken: it is a typed L2 item, logged as `L2-ASKED: Q8`.

---

## Step 3 — Implement (phase 1)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:51 | `git fetch origin main` | `empty.txt` | (no output) |
| 10:52 | `git switch -c iac-change/paymentapi-raise-max-connections origin/main` | `git-switch.txt` | `Switched to a new branch 'iac-change/paymentapi-raise-max-connections'` |
| 10:53 | `git branch --show-current` | `git-branch-after-switch.txt` (branch name filled in) | `iac-change/paymentapi-raise-max-connections` |

Code written (adjacent examples: `main.tf:18-22` sets `apply_method = "immediate"` with aligned `=`; `main.tf:116-125` the CPU alarm, same attribute style). The static parameter gets `apply_method = "pending-reboot"` because `live: describe-db-parameters` shows ApplyType `static` and `docs: USER_WorkingWithParamGroups.html (read 2026-11-09)` says a static change applies only after a reboot.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 10:54 | `terraform fmt main.tf` (shown before running) | `empty.txt` | no output, no file reformatted |
| 10:55 | `git status --short` | answered from the diff | ` M main.tf` |
| 10:56 | `git diff` | answered from the diff | below |

```diff
diff --git a/main.tf b/main.tf
--- a/main.tf
+++ b/main.tf
@@ -11,8 +11,9 @@ resource "aws_db_parameter_group" "paymentapi" {
   description = "paymentapi ${var.env} PostgreSQL 15 parameter group"
 
   parameter {
-    name  = "max_connections"
-    value = "100"
+    name         = "max_connections"
+    value        = "200"
+    apply_method = "pending-reboot"
   }
 
   parameter {
@@ -145,8 +146,8 @@ resource "aws_cloudwatch_metric_alarm" "paymentapi_db_connections" {
   namespace           = "AWS/RDS"
   period              = 60
   statistic           = "Average"
-  threshold           = 80
-  alarm_description   = "RDS connections above 80 for paymentapi ${var.env} (limit: 100)"
+  threshold           = 160
+  alarm_description   = "RDS connections above 160 for paymentapi ${var.env} (limit: 200)"
 
   dimensions = {
     DBInstanceIdentifier = aws_db_instance.paymentapi.identifier
```

Observation, left alone as out of scope: the header comment at `main.tf:3-4` ("max_connections is currently 100 ...") becomes stale after the change. The approved plan does not name it, so it is not touched.

Diff self-check (6 items):
1. Scope — pass: only `main.tf`, which is in the phase's file list; nothing else changed.
2. Plan ↔ hunk — pass: `aws_db_parameter_group.paymentapi` → hunk 1; `aws_cloudwatch_metric_alarm.paymentapi_db_connections` → hunk 2; each hunk maps to a plan item.
3. Conventions — pass: `apply_method` aligned as at `main.tf:18-22`; alarm attributes unchanged in form from `main.tf:140-149`; description keeps `${var.env}`.
4. No silent safety changes — pass: no `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `force_destroy`, `ignore_changes`, `0.0.0.0/0` or `*` in IAM touched.
5. No secrets — pass: no literal credential; no `tfplan`, state or `.terraform/` in the changes.
6. Formatted — pass: `terraform fmt main.tf` printed nothing.
**6/6.** E1–E3 are not required (full lane).

Fresh eyes: required (the phase changes an existing resource and touches a data store's parameter group; skip rule does not hold). Run instructions say do not dispatch subagents, protocol default applies: `fresh-eyes: not run — dry run`.

### [F3] message shown to the operator (10:56)

> **Code changes for Phase 1 of 2:**
>
> **Modified:** `main.tf` — hunk 1: `max_connections` 100 → 200 with `apply_method = "pending-reboot"` (static parameter, applied at the phase-2 reboot); hunk 2: connections alarm threshold 80 → 160 and description `(limit: 200)` (the flagged item)
>
> **Plan ↔ hunk:** `aws_db_parameter_group.paymentapi` update in place → `main.tf` hunk 1; `aws_cloudwatch_metric_alarm.paymentapi_db_connections` update in place → `main.tf` hunk 2
> **Self-check:** 6/6 pass · **Fresh eyes:** not run — dry run
> **Target:** `aws sts get-caller-identity` (10:01) → account `123456789012`, `assumed-role/paymentapi-operator`, region `ap-southeast-1` · default workspace, `-var-file=envs/prod.tfvars` · tier `prod=prod (operator-stated)`
> **Plan command (4a):** `terraform init` is not needed again (it ran at 10:18, providers and lock file unchanged); `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above). The re-plan after the apply (`terraform plan -var-file=envs/prod.tfvars`) runs on this approval too. Phase 2 has no plan command.
>
> Full diff is in your working tree (`git diff` to review).
> **[F3] Approve these changes and the plan command?**

### Operator answer 3 (script entry 3, `[F3]` phase 1) — 11:01

> Approve the code.

---

## Step 4a — Plan output (phase 1)

Re-check the target first, no stop.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:02 | `aws sts get-caller-identity` | `identity-prod.json` (prod, (b)) | account `123456789012`, `assumed-role/paymentapi-operator` — matches the target shown at 10:01 and at `[F3]`. Env selection `-var-file=envs/prod.tfvars`, default workspace |
| 11:03 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | `plan-prod.txt` | `Plan: 0 to add, 2 to change, 0 to destroy.` |
| 11:04 | `terraform show -no-color tfplan` | `plan-prod.txt` | same text |
| 11:05 | `sha256sum <scratch file with the plan text>` (scratch file outside the repo, deleted after) | INDEX "Plan hashes" | `sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d` |

Canned plan versus code: the canned plan matches the code written. Plan lines: `plan-prod.txt:6-16` the alarm `updated in-place` (description, threshold; tags unchanged), `plan-prod.txt:18-39` the parameter group `updated in-place` (old block `apply_method immediate, max_connections, 100` replaced by `pending-reboot, max_connections, 200`). No difference to note.

Cross-check against the evidence table and the approved phase: both resources are in the phase; both actions are in-place updates, matching the disruption approved (`none` at apply time); no destroy or replace (no `[H3]`); no drift picked up by the refresh (no `[H4]`); no change outside the approved plan. `plan:` evidence: `aws_db_parameter_group.paymentapi update in-place`, `aws_cloudwatch_metric_alarm.paymentapi_db_connections update in-place`. No planned resource is outside the snapshot set.

Lane confirmed from the plan output: still full (L2 fails, L3 fails). No downgrade. Escalations: none.
Parity check: n/a (no staging phase ran: exception (a)).

## Step 4b — S1, then pre-flight (phase 1)

S1: the latest prod snapshot is S0 (10:38-10:39), now 26 minutes old at 11:05, over 15 minutes, so it is read again (approved with the batch, no stop).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:06 | `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm ...` | `alarms-firing-prod.json` (S0/S1 of phase 1) | nothing firing |
| 11:07 | `aws cloudwatch get-metric-data ... --start-time 2026-11-02T03:07:00Z --end-time 2026-11-09T04:07:00Z` (the S0/S1 query file, `Period` 3600) | `metric-data-s0-prod.json` | same values as S0 (folded as at 10:39): request count 690.7/min [680.3/min], connections max 78, CPU 33.8%, target 5xx 0, p95 0.114 s |
| 11:08 | `aws ecs describe-services ...` (same projection) | `ecs-describe-services-prod.json` | 3/3 running, one PRIMARY `COMPLETED` deployment |
| 11:09 | `aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod ARN>` | `tg-health-prod.json` | 3/3 `healthy` |
| 11:10 | `aws rds describe-db-instances ...` (status projection) | `rds-instance-prod.json` | `available`, `in-sync`, pending `{}` |

S1 time 11:06-11:10. `Q1(alarms)=no`, `Q3=no` (1.02×) — both unchanged from S0.

Reusable pre-flight record: none (`.culiops/pre-flight/` does not exist in the fixture). **No match**, so pre-flight is invoked inline.

Caller block passed to pre-flight (every field filled):

```
### Caller context (iac-change-execution)
Target: account 123456789012 / ap-southeast-1 · default workspace · -var-file=envs/prod.tfvars (aws sts get-caller-identity 11:02: assumed-role/paymentapi-operator); no state backend declared in the code
Delivery model: direct apply from the operator's workstation, no PR — local workstation apply, not going through CI/CD pipeline (operator-stated, first message; UNVERIFIED in the repo: no CI config, gh run list -> [] at 10:33)
Lane: full — L2 fails (aws_db_parameter_group parameter change is off the allowlist), L3 fails (two phases); prod operator-stated (unproven)
Plan hash: sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d (terraform show -no-color tfplan)
L2 answers: Q1(alarms)=no (live: aws cloudwatch describe-alarms --state-value ALARM, 11:06: 0 firing in ap-southeast-1) Q1(declared)=no (operator (no objection at [F2], 10:50)) Q2=no (operator (no objection at [F2], 10:50); no freeze calendar in the repo) Q3=no (live: aws cloudwatch get-metric-data, 11:07: 690.7 requests/min vs 680.3/min same hour last week, 1.02x) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator (no objection at [F2], 10:50)) Q8=../paymentapi @ v2.4.1 (app: sibling checkout, HEAD 5d1c8e4 is not the deployed ref; operator confirmed the checkout at [F2], 10:50) iac-change.1=yes (plan: terraform show -no-color tfplan 11:04, reviewed at [F3] 11:01) iac-change.2=direct apply from the workstation (operator-stated, first message; see Delivery model) iac-change.3=no (plan: -var-file=envs/prod.tfvars, default workspace, no -target, no -refresh=false; the plan command at 11:03) iac-change.4=unsure (UNVERIFIED — no state backend in the code so no state-object read, gh run list -> [] at 10:33, ECS deployment 2026-10-12 is an app deploy)
Live results:
  terraform plan -refresh-only -var-file=envs/prod.tfvars · 10:19 · No changes (no drift)
  aws rds describe-db-instances paymentapi-db-prod · 10:20 · available, db.r6g.large, 15.4, MultiAZ true, pending {}, param group in-sync, deletion protection on, retention 7, latestRestorable 02:55Z
  aws rds describe-db-parameters (paymentapi-prod-20250617043012345600000001) · 10:21 · max_connections 100, static, pending-reboot
  aws rds describe-db-snapshots paymentapi-db-prod · 10:22 · 3 automated, available, newest 2026-11-09 02:05Z
  aws cloudwatch describe-alarms-for-metric DatabaseConnections · 10:23 · paymentapi-db-connections-high-prod OK, enabled, threshold 80
  aws cloudwatch describe-alarms-for-metric CPUUtilization · 10:24 · paymentapi-db-cpu-high-prod OK, enabled, threshold 80
  aws cloudwatch describe-alarms --alarm-name-prefix paymentapi · 10:25 · 2 alarms OK, actions SNS paymentapi-alerts-prod
  aws cloudwatch describe-alarm-history paymentapi-db-connections-high-prod · 10:26 · 3 ALARM episodes in 5 days (2026-11-04, 11-06, 11-08), 8-12 min each
  aws sns list-subscriptions-by-topic paymentapi-alerts-prod (protocols) · 10:27 · email, email
  aws ecs describe-services paymentapi-svc-prod · 10:28 · 3/3 running, one PRIMARY deployment COMPLETED since 2026-10-12, min healthy 100 / max 200, no circuit breaker
  aws elbv2 describe-target-health paymentapi-tg-prod · 10:29 · 3/3 healthy
  aws elbv2 describe-target-groups / describe-load-balancers · 10:30-10:31 · paymentapi-alb-prod, internal, active
  aws ecs describe-task-definition paymentapi-prod:12 (images only) · 10:32 · paymentapi:v2.4.1
  gh run list --limit 5 · 10:33 · []
  git -C ../paymentapi remote get-url origin · 10:35 · git@github.com:acme/paymentapi.git; rev-parse HEAD · 10:37 · 5d1c8e4a7b2f90361a4c6e8d0b3f5a7c9e1d2b4f
  S0 aws cloudwatch describe-alarms --state-value ALARM · 10:38 · none; S0 get-metric-data · 10:39 · see snapshot
  S1 (11:06-11:10) · alarms none; metrics unchanged from S0; ECS 3/3; target health 3/3 healthy; RDS available, in-sync
Evidence table: the Step 1 table (drift rows: 0; unverified rows: 2 — delivery model in the repo, last apply; code-only rows: 0). Staging evidence: none (no staging phase: exception (a)).
```

The caller block has no empty or `unknown` field, so pre-flight runs inline.

### Pre-flight (inline, phase 1), as run by the skill

Pre-flight Step 1. Matched assessor: `iac-change` (the plan text has the `Plan:` summary line). Action: two in-place Terraform updates. Target, delivery model and plan hash come from the caller block; GATE 1 is skipped. Output root: `.culiops/` (name the root in the report; `CULIOPS_HOME` unset). Unsupported-stack check: Terraform on AWS, supported. Plan hygiene: no "Objects have changed outside of Terraform" block in the plan; `iac-change.3` says no `-target`, no `-refresh=false`, default var-file; plan is not "No changes"; no unexpected resource (the alarm update is the flagged item the operator approved at `[F2]`).

Pre-flight Step 2 (L1) reads the git history (local read):

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:11 | `aws sts get-caller-identity` (target check, no stop) | `identity-prod.json` | account `123456789012` = the caller's `Target:` |
| 11:12 | `git log --since=7.days --oneline main -- main.tf envs/prod.tfvars` | `empty.txt` | no commit in 7 days; this change has made no commit, so there are none of its own to exclude. `git status` (from the diff): ` M main.tf` is this change's own uncommitted edit |

Attributes marked: `max_connections` (parameter group) — **app-facing** (a limit the app must fit inside; assessor table). Alarm threshold and description — not-app-facing (a notify-only alarm: `live: SNS protocols email, email`, 10:27). Category 11 is therefore triggered by `max_connections`, and Step 3b runs.

Pre-flight Step 3 (L2 and L3): the caller block answers every question; Q6 is scored from the plan (no new resource, no size change); Q8 arrives as a location. No L2 stop, no extra L3 batch.

Pre-flight Step 3b (local mode, no further approval; the path and the search terms are named): path `../paymentapi`; the terms `DB_POOL_SIZE`, `DB_MAX_OVERFLOW`, `max_connections`, the engine construction.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:13 | `git -C ../paymentapi status --porcelain` | `empty.txt` | clean tree |
| 11:14 | `git -C ../paymentapi describe --tags --always` | `app-source-describe.txt` | `v2.5.0-3-g5d1c8e4` — HEAD is 3 commits past v2.5.0, not the deployed ref |
| 11:15 | `git -C ../paymentapi rev-parse v2.4.1` | `app-source-rev-parse-tag.txt` | `c0a7e93f1b6d4285a9e0c3b7d5f2a18e46b9d07c` — the deployed tag exists in the checkout, so it is read at that ref, with no fetch or checkout |
| 11:16 | `git -C ../paymentapi grep -n -e DB_POOL_SIZE -e DB_MAX_OVERFLOW -e max_connections v2.4.1 -- .` | `app-source-grep-deployed.txt` | `config.py:6` `DB_POOL_SIZE` default 20; `config.py:7` `DB_MAX_OVERFLOW` default 5; `db.py:11-13` pool_size, max_overflow, `pool_pre_ping=True`; no `max_connections` hit |
| 11:17 | `git -C ../paymentapi show v2.4.1:app/db.py` | `app-source-show-db.py.txt` | the engine: `pool_pre_ping` replaces a connection the server closed on checkout (comment at line 10) |
| 11:18 | `git -C ../paymentapi show v2.4.1:app/config.py` | `app-source-show-config.py.txt` | `DB_HOST` from the environment, no password in the file |

Pinned: `app:paymentapi@c0a7e93` (v2.4.1, read without checkout; the checkout's HEAD `5d1c8e4` differs and is noted). Reading: the app's pool is `DB_POOL_SIZE` 20 + `DB_MAX_OVERFLOW` 5 = 25 connections per process by default (`app:paymentapi@c0a7e93:app/config.py:6-7`); with the ECS service's 3 tasks that is 75 if each task runs one process (not verified), below both the old limit 100 and the new limit 200. Raising the limit cannot break that contract. Search limits: the task definition's environment names were not read, so an override of the pool variables is unknown, and a text search can miss other consumers.

Pre-flight Step 5 scores (phase 1 plan text):

| # | Category | Score | Finding | Evidence |
|---|---|---|---|---|
| 1 | Blast radius | Yellow | two resources, one a parameter group of the shared database; disruption at apply time none | `plan: aws_db_parameter_group.paymentapi update in-place`, `plan: aws_cloudwatch_metric_alarm.paymentapi_db_connections update in-place`, `docs: USER_WorkingWithParamGroups.html (read 2026-11-09)`, `live: describe-db-parameters 10:21 ApplyType static`; the reboot is scored by phase 2's own pre-flight |
| 2 | Reversibility | Green | in place; `max_connections` is not on the assessor's one-way table (a table is a starting point), so `docs` shows reverting a parameter restores it and an alarm update is in place | `plan:`, `docs: USER_WorkingWithParamGroups.html`, `docs: API_PutMetricAlarm.html`, `live: describe-db-snapshots 10:22` |
| 3 | Change velocity | Green | 0 commits to the changed paths in 7 days; nothing stacked. Automation lag is `UNVERIFIED` (`iac-change.4=unsure`), listed under Not verified | `git: log --since 11:12`, `live: gh run list 10:33` |
| 4 | Dependency impact | Yellow | the ECS service depends on the database; catalog lists 1 consumer, confirmed by `code:`/`live:` as above; no other consumer found | `catalog: paymentapi-prod.md:41`, `code: main.tf:94`, `live: describe-services 10:28` |
| 5 | Timing context | Green | `Q1(alarms)=no` live, `Q1(declared)=no`, `Q2=no` (`operator`, no objection), `Q3=no` live (1.02×); the operator applies it himself | `live: describe-alarms 11:06`, `live: get-metric-data 11:07`, `operator` |
| 6 | Operator familiarity | Green | many times, experienced | `operator (profile, 2026-10-19)` |
| 7 | Observability readiness | Yellow | both DB alarms exist, are enabled and notify; they are static-threshold alarms (Yellow on the maturity ladder); between the phases the connections alarm (160) sits above the live limit (100) | `live: describe-alarms-for-metric 10:23, 10:24`, `code: main.tf:116-156` |
| 8 | Cost impact | Green | no new resource, no size or count change | `plan: 0 to add, 2 to change, 0 to destroy` |
| 9 | Security posture | Green | no IAM, network, encryption, public-access or logging change | `plan:`, `code: diff` |
| 10 | Resource health | Yellow | no alarm firing, no errors, CPU 33.8%; **connection saturation is above 70%**: `DatabaseConnections` max 78 of `max_connections` 100 = 78% (the same value in S0 and S1) | `live: get-metric-data 11:07`, `live: describe-db-parameters 10:21` |
| 11 | Application compatibility | Green | the app's pool (25 per process by default) fits inside both 100 and 200; the alarm change is notify-only | `app:paymentapi@c0a7e93:app/config.py:6-7`, `app:paymentapi@c0a7e93:app/db.py:11-13`, `live: SNS protocols 10:27` |

Hard blocks checked: reversibility (no irreversible data change), timing (no active incident plus freeze), security (none), health (no SLO, no exhausted budget): none triggered. Multi-Yellow: 4 Yellow (1, 4, 7, 10) → **RED — soft block**.

Pre-flight Step 5b: citations re-opened for the Greens on 2, 9, 11 and the premises of each mitigation: all say what the findings claim (`docs` entries read this session; `app:` lines from the pinned ref); one fix: category 3 first read as a pure Green, then the unread automation lag was moved to Not verified instead of being assumed. Verdict arithmetic: Red = none; Yellow + unknown = 4 (1, 4, 7, 10); hard blocks checked: 2, 5, 9, 10 → RED — soft block. Fresh eyes: not required (the verdict is RED — soft block). Not verified: delivery model (`operator-stated`), `Q1(declared)` and `Q2` (`operator`, no objection), last apply time, the task definition's pool variables, process count per task, the running value inside PostgreSQL, other consumers of the database (catalog lead).

Verdict returned to the caller: `RED — soft block`. The record is `preflight-record.md` (phase 1 section).

### [H5] message shown to the operator (11:18)

**[H5] Pre-flight is RED — soft block: four categories are Yellow (blast radius, dependency impact, observability readiness, resource health), and three or more Yellow escalate to Red. Acknowledge each finding with a reason, or abort?**

Scorecard: as in the table above (Red none; Yellow 1, 4, 7, 10; Green 2, 3, 5, 6, 8, 9, 11). Drift: none. Verification: citations checked, verdict working above, fresh eyes not required, not-verified list above.

Findings and mitigations:
1. Blast radius (Yellow): the change touches the shared database's parameter group. At apply time nothing restarts (`docs:` static parameter). Mitigation: the reboot is scored on its own at phase 2.
4. Dependency impact (Yellow): the ECS service depends on the database. Mitigation: S2 reads the service, load balancer and target health after the apply, and `[H10]` stops the run on a regression.
7. Observability readiness (Yellow): both alarms are static thresholds, and the connections alarm will sit at 160 above the live limit of 100 until the reboot. Mitigation (operator action): do the reboot straight away, or keep the alarm at 80 until then (a third phase).
10. Resource health (Yellow): connection saturation is 78% of the limit before the change. Mitigation: this is the reason for the change; apply in the maintenance window, as planned.

### Operator answer 4 (script entry 6, `[H5]`, first use) — 11:23

> Acknowledged, each finding. Reason: maintenance window approved, DBA on call, the failover is expected.

Recorded word for word as the acknowledgement. (The reason mentions a failover. Phase 1 has no restart or failover and phase 2's command has no `--force-failover`; the reason is recorded as given, not changed.) Pre-flight GATE 2 on RED was this stop, so it is not asked again.

---

## Step 4c — Execute (phase 1, direct apply)

H7 before this `[F4]`: no staging environment; exception (a) recorded with its evidence (`code: envs/ holds only prod.tfvars`).

### [F4] message shown to the operator (11:23)

> **[F4] Run this apply?** About to run: `terraform apply tfplan` against account `123456789012` / `ap-southeast-1` (target re-checked in 4a at 11:02: `assumed-role/paymentapi-operator`), default workspace, `-var-file=envs/prod.tfvars`, plan hash `sha256:779dc062...f1619d`
> This will: update in place `aws_db_parameter_group.paymentapi` (`max_connections` 100 → 200, applied at the next reboot) and `aws_cloudwatch_metric_alarm.paymentapi_db_connections` (threshold 80 → 160, description `(limit: 200)`); `Plan: 0 to add, 2 to change, 0 to destroy.` No destroy or replace.
> **Pre-flight verdict:** RED — soft block (four Yellow: blast radius, dependency impact, observability readiness, resource health), acknowledged at `[H5]` 11:23 with the operator's reason. Mitigations: S2 and `[H10]` after the apply; keep the reboot close behind (the alarm sits at 160 over a live limit of 100 until then).
> **S1 (prod, 11:06-11:10):** 0 alarms firing; request rate 690.7/min; connections max 78 of 100; ECS 3/3; targets 3/3 healthy.
> *Heads-up: say so and I draft one for the service owners, reviewers and on-call (`#payments-oncall`) with `change-comms` (draft-only; you send it).*

### Operator answer 5 (script entry 4, `[F4]` phase 1) — 11:28

> Approved: run the apply command shown. (This also acknowledges the verdict.)

Acknowledged verdict recorded: `RED — soft block`, acknowledged at `[H5]` 11:23 and carried to `[F4]` 11:28 with the mitigations committed (S2 and `[H10]`; reboot soon after). The heads-up offer was not taken (nothing in the script says it).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:29 | `terraform apply tfplan` | `apply-prod.txt` | alarm: Modifying... Modifications complete after 0s; parameter group: Modifying... Modifications complete after 1s; `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` Not long-running; no lock problem |

The apply ended at 11:29. `{rollout-complete}` = 11:29:00 (04:29:00Z). Phase disruption is `none`, so S2's two periods count from the apply.

AMBIGUITY: `tfplan` is read from a local plan file and the working tree is not committed. The `Commits` rule in `lanes.md` (each phase's approved code is a local commit) sits under Staging-first and applies when an environment is mapped to `staging`; here there is none (exception (a)), and the PR path in 4c is the only one that commits. Reading taken: no commit, no push, no PR on the direct-apply path; the applied code stays uncommitted on the change branch.

NOTE: the canned alarm files carry their own time: `AlarmConfigurationUpdatedTimestamp` `2026-11-09T03:21:40Z` (10:21:40 +07:00) in `alarm-connections-after-prod.json`, `alarms-prefix-after-prod.json` and `alarms-for-metric-connections-after-prod.json`. That is earlier than this run's apply (11:29). The runner does not edit canned files and does not hide the mismatch; it is recorded as printed.

## Step 5a — Verification (phase 1)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:30 | `terraform plan -var-file=envs/prod.tfvars` (re-plan; approved at `[F3]`) | `plan-after-prod.txt` | `No changes. Your infrastructure matches the configuration.` |
| 11:31 | success criterion 1: `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"` | `rds-parameters-max-connections-after.json` | `ParameterValue` `"200"` — pass |
| 11:32 | success criterion 2: `aws rds describe-db-instances ... --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups}'` | `rds-instance-pending-reboot-prod.json` | status `available`, `ParameterApplyStatus` `pending-reboot` — pass |
| 11:33 | success criterion 4: `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod --query 'MetricAlarms[].{state:StateValue,threshold:Threshold,enabled:ActionsEnabled}'` | `alarm-connections-after-prod.json` | state `OK`, threshold `160`, enabled `true` — pass |

S2 is two 5-minute periods after the apply (11:29:00): **S2 ready at 11:39**. The wait is not a stop. Clock jump 11:33 → 11:39 (rule: waiting for S2).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:39 | `aws cloudwatch get-metric-data ... --start-time 2026-11-09T04:29:00Z --end-time 2026-11-09T04:39:00Z` (query file with `Period` 300) | `metric-data-s0-prod.json` ("nothing changed in the metrics") | the last two 5-minute values of each series (see below) |
| 11:40 | `aws cloudwatch describe-alarms --state-value ALARM ...` | `alarms-firing-after-prod.json` | nothing firing |
| 11:41 | `aws ecs describe-services ...` | `ecs-describe-services-prod.json` | 3/3, one PRIMARY `COMPLETED` deployment (no rollout started; `aws ecs wait services-stable` not needed: no ECS change) |
| 11:42 | `aws elbv2 describe-target-health ...` | `tg-health-prod.json` | 3/3 `healthy` |
| 11:43 | `aws rds describe-db-instances ...` | `rds-instance-pending-reboot-prod.json` | `available`, `pending-reboot` |

AMBIGUITY: phase 1 is app-facing (`max_connections`) with disruption `none`, so the two-period wait applies even though nothing is expected to move before the reboot; the not-app-facing exemption (no wait) does not hold. Reading taken: wait two periods (10 minutes), as `snapshot.md` › When snapshots run says for an app-facing change. The canned file holds no S2-specific series for this state; its "nothing changed" values are used, the last two 5-minute values of each series.

Comparison (S1 = the hour ending 11:07; S2 = 2 periods, 11:29-11:39; counts as per-minute rates):

| Member | Signal | Before (S1) | After (S2) | Verdict |
|---|---|---|---|---|
| RDS | status | `available` | `available` (pending-reboot, expected) | ok |
| RDS | CPU avg | 33.8% | 32.6% | ok |
| RDS | connections avg | 51.5 | 52.5 | ok |
| RDS | connections max vs limit | 78 / 100 = 78% | 77 / 100 = 77% | ok (above 70% before, so no crossing from below) |
| RDS | read latency avg | 1.20 ms | 1.25 ms | ok (1.04×) |
| RDS | write latency avg | 2.23 ms | 2.30 ms | ok (1.03×) |
| RDS | freeable memory min | 6.10 GB | 6.10 GB | ok |
| RDS | free storage min | 82.0 GB | 82.0 GB | ok |
| ECS | running vs desired | 3/3 | 3/3 | ok |
| ECS | CPU avg | 37.7% | 36.4% | ok |
| ECS | memory avg | 51.8% | 50.9% | ok |
| ALB | request rate | 690.7/min | 685.7/min | ok (context, no threshold) |
| ALB | target 5xx | 0 | 0 (below the 5-error floor) | ok |
| ALB | ELB 5xx | 0 | 0 | ok |
| ALB | p95 | 0.114 s | 0.117 s | ok (1.03×) |
| ALB | healthy / unhealthy hosts | 3 / 0 | 3 / 0 | ok |
| set | alarms firing | 0 | 0 | ok |

`Snapshot: 17 ok · 0 regressed · 0 no data`. No `[H10]`. The connections alarm and the parameter group are judged by success criteria 1, 2 and 4 (all pass).

> **Verification for Phase 1:**
> Re-plan: clean
> Success criteria: 1 `max_connections` = "200" — pass; 2 status `available`, `pending-reboot` — pass; 3 re-plan `No changes` — pass; 4 alarm threshold 160, `OK`, enabled — pass
> Snapshot: 17 ok · 0 regressed · 0 no data — none regressed

Phase 1 verification: pass. Next phase's code is not to be written (operational command), so the run goes to phase 2's first stop, `[F4]`; there is no `[F3]` and no 4a plan run.

---

## Phase 2 — operational reboot (Step 4a re-check, S1, pre-flight, `[F4]`)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:44 | `aws sts get-caller-identity` (target re-check) | `identity-prod.json` | account `123456789012`, `assumed-role/paymentapi-operator` — matches |

S1 for phase 2. The latest prod snapshot is phase 1's S2 (11:39-11:43). It is not reused: S1 needs the hour ending now and the same hour last week for `Q3`, and an S2 read holds neither. AMBIGUITY: `snapshot.md` says S1 is "the latest snapshot of that environment, read again if older than 15 minutes"; S2 is a snapshot, but its shape (10 minutes at `Period` 300, no week-ago window) cannot answer `Q3`. Reading taken: a fresh S1 is read (approved with the batch).

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:45 | `aws cloudwatch describe-alarms --state-value ALARM ...` | `alarms-firing-after-prod.json` | nothing firing |
| 11:46 | `aws cloudwatch get-metric-data ... --start-time 2026-11-02T03:46:00Z --end-time 2026-11-09T04:46:00Z` (`Period` 3600) | `metric-data-s0-prod.json` (S1 of phase 2: nothing changed in the metrics) | same values as S0: 690.7/min [680.3/min], connections max 78 (78% of the live limit, which is still 100), CPU 33.8% |
| 11:47 | `aws ecs describe-services ...` | `ecs-describe-services-prod.json` | 3/3 |
| 11:48 | `aws elbv2 describe-target-health ...` | `tg-health-prod.json` | 3/3 healthy |
| 11:49 | `aws rds describe-db-instances ...` | `rds-instance-pending-reboot-prod.json` | `available`, `ParameterApplyStatus` `pending-reboot` |

S1 time 11:45-11:49. `Q1(alarms)=no`, `Q3=no` (1.02×) — unchanged. Pre-flight for the operational phase: `Plan hash: none — operational command (aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1)`; a record with no hash is never reusable, so it runs inline (no match).

Caller block, phase 2:

```
### Caller context (iac-change-execution)
Target: account 123456789012 / ap-southeast-1 · default workspace · -var-file=envs/prod.tfvars (aws sts get-caller-identity 11:44: assumed-role/paymentapi-operator); the command runs through the same credentials (no assume_role pin)
Delivery model: direct apply from the operator's workstation, no PR — local workstation apply, not going through CI/CD pipeline (operator-stated, first message; UNVERIFIED in the repo)
Lane: full — L2 fails (aws_db_parameter_group parameter change), L3 fails (two phases); prod operator-stated (unproven)
Plan hash: none — operational command (aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1)
L2 answers: Q1(alarms)=no (live: aws cloudwatch describe-alarms --state-value ALARM, 11:45: 0 firing) Q1(declared)=no (operator (no objection at [F2], 10:50); re-asked at [F4]) Q2=no (operator (no objection at [F2], 10:50)) Q3=no (live: aws cloudwatch get-metric-data, 11:46: 690.7/min vs 680.3/min, 1.02x) Q4=many times (operator (profile, 2026-10-19)) Q5=experienced (operator (profile, 2026-10-19)) Q7=none (operator (no objection at [F2], 10:50)) Q8=../paymentapi @ v2.4.1 (app: sibling checkout read at the deployed ref in phase 1; operator confirmed at [F2]) iac-change.1=yes (the command text is the plan text; phase 1's plan was reviewed at [F3] and applied at 11:29) iac-change.2=direct apply from the workstation (operator-stated) iac-change.3=no (no plan was made for this phase; no -target, no -refresh=false) iac-change.4=recent (live: this run's phase-1 apply at 11:29, `terraform apply tfplan` output; re-plan 11:30 clean)
Live results: the phase-1 list, plus
  aws cloudwatch describe-alarms --state-value ALARM · 11:45 · none
  aws cloudwatch get-metric-data (S1) · 11:46 · unchanged from S0 (connections max 78 of live limit 100; 690.7/min)
  aws ecs describe-services · 11:47 · 3/3 running; aws elbv2 describe-target-health · 11:48 · 3/3 healthy
  aws rds describe-db-instances · 11:49 · available, ParameterApplyStatus pending-reboot, MultiAZ true
  aws rds describe-db-parameters · 11:31 · max_connections 200 (configured), pending the reboot
  aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod · 11:33 · threshold 160, OK, enabled
  terraform apply tfplan · 11:29 · Apply complete, 2 changed; terraform plan · 11:30 · No changes
Evidence table: the Step 1 table, plus phase 1's measured outcome (parameter 200, pending-reboot, alarm 160, S2 17 ok / 0 regressed); drift rows: 0; unverified rows: 1 (delivery model in the repo); code-only rows: 0. Staging evidence: none (exception (a)).
```

### Pre-flight (inline, phase 2), as run by the skill

Pre-flight Step 1: matched assessor `iac-change` (operational command, `Plan hash: none`); Step 2/3 as in phase 1 with these differences. Reads:

| Time | Command | Canned file | Result |
|---|---|---|---|
| 11:50 | `aws sts get-caller-identity` (target check, no stop) | `identity-prod.json` | matches the caller's `Target:` |
| 11:51 | `git log --since=7.days --oneline main -- main.tf envs/prod.tfvars` | `empty.txt` | no commit in 7 days; `git status` (from the diff): ` M main.tf`, this change's own phase-1 edit, applied and not committed |

Step 3b: the app source was pinned and read in phase 1 (same session, same ref `v2.4.1` = `c0a7e93`); reused, not re-read. For the reboot: `app:paymentapi@c0a7e93:app/db.py:13` `pool_pre_ping=True`, with the comment at `app/db.py:10` "replaces a connection the server closed (restart, failover) on checkout". Requests that arrive while the database is down still fail; the two files read show no retry or fallback (a search of two files can miss one).

Scores (phase 2, the command text as the plan):

| # | Category | Score | Finding | Evidence |
|---|---|---|---|---|
| 1 | Blast radius | Yellow | the shared database behind the payment API is rebooted in place: brief unavailability for every connection; Multi-AZ present but not used (no `--force-failover`), so it does not soften an in-place reboot | `docs: USER_RebootInstance.html (read 2026-11-09)`, `live: describe-db-instances 11:49 MultiAZ true`, `live: describe-services 11:47 3 tasks` |
| 2 | Reversibility | Yellow | no data changes, but a reboot cannot be undone; the way back is the parameter revert plus a second reboot with the same outage, untested | `docs: USER_WorkingWithParamGroups.html (read 2026-11-09)`, `live: describe-db-snapshots 10:22` (recovery point 02:05Z) |
| 3 | Change velocity | Green | no commit to the changed paths in 7 days; the only recent change is this change's own phase 1 (11:29), excluded as its own | `git: log --since 11:51`, `live: terraform apply 11:29` |
| 4 | Dependency impact | Yellow | the ECS service (3 tasks) is the downstream consumer; catalog lists no other (a lead) | `catalog: paymentapi-prod.md:41`, `live: describe-services 11:47` |
| 5 | Timing context | Green | `Q1(alarms)=no` live, `Q1(declared)=no`, `Q2=no`, `Q3=no` live; the operator applies it himself | `live: describe-alarms 11:45`, `live: get-metric-data 11:46`, `operator` |
| 6 | Operator familiarity | Green | many times, experienced | `operator (profile, 2026-10-19)` |
| 7 | Observability readiness | Yellow | the two DB alarms exist, are enabled and notify; static thresholds; after the reboot the connections alarm (160) matches the new limit (200) | `live: describe-alarms 11:33`, `code: main.tf:116-156` |
| 8 | Cost impact | Green | the command adds no resource and changes no size | `code: the command text` |
| 9 | Security posture | Green | no security-relevant change | `code: the command text` |
| 10 | Resource health | Yellow | no alarm, no errors; connection saturation 78% of the live limit 100 (above 70%) until the reboot | `live: get-metric-data 11:46`, `live: describe-db-parameters (limit 100 until the reboot)` |
| 11 | Application compatibility | Yellow | a reboot interrupts the app's connections; the pool replaces dead connections on checkout (`pool_pre_ping`), so the app recovers, but requests during the outage fail and no retry was found | `app:paymentapi@c0a7e93:app/db.py:10-13` |

Hard blocks checked: 2, 5, 9, 10: none triggered. Multi-Yellow: 6 Yellow (1, 2, 4, 7, 10, 11) → **RED — soft block**. Step 5b: citations re-opened (Greens on 9; the docs for the reboot claims; app lines); no fix needed; fresh eyes not required (RED — soft block). Not verified: delivery model (operator-stated), `Q1(declared)`, `Q2`, the pool variables in the task definition, retry behaviour beyond the two files, running value in PostgreSQL after the reboot.

### [H5] message shown to the operator (11:51)

**[H5] Pre-flight is RED — soft block: six categories are Yellow (blast radius, reversibility, dependency impact, observability readiness, resource health, application compatibility). Acknowledge each finding with a reason, or abort?**

Mitigations: 1/4/11 — the reboot is in place and brief; `pool_pre_ping` lets the tasks reconnect; S2 and `[H10]` follow. 2 — rollback is the parameter revert plus a second reboot (untested). 7 — after the reboot the alarm (160) matches the new limit (200). 10 — the reboot is what brings the limit to 200 and the saturation to about 39% of the new limit.

### Operator answer 6 (script entry 6, `[H5]`, second use) — 11:56

> Acknowledged, each finding. Reason: maintenance window approved, DBA on call, the failover is expected.

Recorded word for word. (Same note as at the first `[H5]`: the command shown has no `--force-failover`.)

### [F4] message shown to the operator (11:56)

> `Phase 1 success criteria: max_connections = "200", pending-reboot, re-plan clean, alarm 160 — pass`
> `Snapshot: 17 ok · 0 regressed · 0 no data`
>
> **[F4] Run this reboot?** About to run: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` against account `123456789012` / `ap-southeast-1` (target re-checked at 11:44: `assumed-role/paymentapi-operator`; no assume_role pin, so no profile is named). No Terraform plan runs for this phase (no IaC change).
> This will: reboot the instance in place (no `--force-failover`) so the static `max_connections` = 200 takes effect; expected disruption: brief unavailability of the database (`docs: USER_RebootInstance.html (read 2026-11-09)`), the instance shows `rebooting` and then `available`. **Pre-flight verdict:** RED — soft block (six Yellow), acknowledged at `[H5]` 11:56 with the operator's reason. **S1 (prod, 11:45-11:49):** 0 alarms firing; 690.7 requests/min; connections max 78 of the live limit 100; ECS 3/3; targets 3/3.
> Timing re-ask: `Q1(alarms)` and `Q3` come from this S1 and equal what pre-flight got (no, no); `Q1(declared)`, `Q2` and `Q7` stand at "no / no / none" unless you say otherwise.
> Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.
> *Heads-up: say so and I draft one for the service owners, reviewers and on-call (`#payments-oncall`) with `change-comms` (draft-only; you send it).*

### Operator answer 7 (script entry 5, `[F4]` phase 2) — 12:01

> Approved: run the reboot command shown. (The incident, freeze and peak answers still hold: yes, unchanged.)

Operator line: no reply. The answers are unchanged, so pre-flight is not re-run and no new `[F4]` is shown.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:02 | `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` | `rds-reboot-prod.json` | `DBInstanceStatus` `rebooting`, `ParameterApplyStatus` `pending-reboot` |
| 12:03 | status poll 1: `aws rds describe-db-instances ... --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups,pending:PendingModifiedValues}'` | `rds-instance-rebooting-prod.json` (the first read after the reboot) | `rebooting`, `pending-reboot` |
| 12:04 | status poll 2 (same command) | `rds-instance-after-reboot-prod.json` | `available`, `ParameterApplyStatus` `in-sync`, pending `{}` — success criterion 1 |

`{rollout-complete}` = 12:04:00 (05:04:00Z), the first read that shows `available` again. The disruption (rebooting, 12:02-12:04) is the plan's named `brief unavailability`; S2's window starts after it.

## Step 5a — Verification (phase 2)

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:05 | success criterion 2: `aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"` | `rds-parameters-max-connections-after.json` | `ParameterValue` `"200"` (the configured value; the value inside PostgreSQL is not read, no SQL access) — pass |
| 12:06 | `aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod ...` | `alarm-connections-after-prod.json` | threshold 160, `OK` — consistent with the new limit |

AMBIGUITY: step 5a item 1 (re-plan) is written for the direct-apply path. Phase 2 changes no IaC and ran no 4a plan, and the plan command was approved at `[F3]` for phase 1 only. Reading taken: no re-plan for phase 2 ("a read not approved there needs its own approval"); `Re-plan: n/a — operational phase`.

S2: two 5-minute periods after 12:04:00 → **S2 ready at 12:14**. Clock jump 12:06 → 12:14.

| Time | Command | Canned file | Result |
|---|---|---|---|
| 12:14 | `aws cloudwatch get-metric-data ... --start-time 2026-11-09T05:04:00Z --end-time 2026-11-09T05:14:00Z` (`Period` 300) | `metric-data-s2-reboot-prod.json` | the two periods inside the window |
| 12:15 | `aws cloudwatch describe-alarms --state-value ALARM ...` | `alarms-firing-after-prod.json` | nothing firing |
| 12:16 | `aws ecs describe-services ...` | `ecs-describe-services-prod.json` | 3/3 (the service did not roll) |
| 12:17 | `aws elbv2 describe-target-health ...` | `tg-health-prod.json` | 3/3 `healthy` |
| 12:18 | `aws rds describe-db-instances ...` | `rds-instance-after-reboot-prod.json` | `available`, `in-sync`, pending `{}` |

Runner note on the canned S2 file: it holds 6 periods from the reboot command; its first period is the reboot itself (CPU 86.4%, connections 0, read/write latency 4.8 / 7.1 ms), which falls before the window the skill asked for (the window starts when the status was `available`, 12:04:00). The two buckets inside the window are the file's periods 2 and 3. The reboot period is shown here for transparency, not judged: it is the plan's named disruption.

Comparison (before = S1 of phase 2, 11:45-11:49, hour values; after = the 2 periods, per-minute rates for counts):

| Member | Signal | Before (S1) | After (S2) | Verdict |
|---|---|---|---|---|
| RDS | status / parameter | `available`, `pending-reboot` | `available`, `in-sync` | ok (success criterion 1) |
| RDS | CPU avg | 33.8% | 32.8% | ok |
| RDS | connections avg | 51.5 | 50.0 | ok |
| RDS | connections max vs limit | 78 / 100 = 78% | 71 / 200 = 35.5% | **improved** (saturation crossed 70% from above) |
| RDS | read latency avg | 1.20 ms | 1.15 ms | ok |
| RDS | write latency avg | 2.23 ms | 2.15 ms | ok |
| RDS | freeable memory min | 6.10 GB | 6.45 GB | ok (higher after the reboot) |
| RDS | free storage min | 82.0 GB | 82.0 GB | ok |
| ECS | running vs desired | 3/3 | 3/3 | ok |
| ECS | CPU avg | 37.7% | 38.8% | ok |
| ECS | memory avg | 51.8% | 52.6% | ok |
| ALB | request rate | 690.7/min | 689.0/min | ok (context) |
| ALB | target 5xx | 0 | 0 (below the 5-error floor) | ok |
| ALB | ELB 5xx | 0 | 0 | ok |
| ALB | p95 | 0.114 s | 0.114 s | ok |
| ALB | healthy / unhealthy hosts | 3 / 0 | 3 / 0 | ok |
| set | alarms firing | 0 | 0 | ok |

`Snapshot: 17 ok · 0 regressed · 0 no data` (the `improved` row counts as ok). No `[H10]`. Success criteria: 1 `DBInstanceStatus` `available` / `ParameterApplyStatus` `in-sync` / `PendingModifiedValues` `{}` — pass; 2 `max_connections` `"200"` — pass; 3 nothing firing on the set — pass.

> **Verification for Phase 2:**
> Re-plan: n/a — operational phase, no IaC change
> Success criteria: `DBInstanceStatus` = `available`, `in-sync`, pending `{}` — pass; `max_connections` = "200" — pass; no alarm firing on the set — pass
> Snapshot: 17 ok · 0 regressed · 0 no data — none regressed

---

## Step 5b — Record, final message (12:19)

Records written (to `record.md` and `preflight-record.md` in this out-dir, not into the fixture): execution record `.culiops/iac-change-execution/paymentapi-raise-max-connections-20261109-1219.md`; pre-flight records `.culiops/pre-flight/paymentapi-raise-max-connections-20261109-1118.md` and `.culiops/pre-flight/paymentapi-reboot-max-connections-20261109-1151.md`.

Final message:

> Both phases ran and verified: `max_connections` is 200 on `paymentapi-db-prod` (applied at 11:29, in effect after the reboot at 12:02-12:04), the connections alarm now fires at 160, and the health snapshot shows no regression (17 ok · 0 regressed · 0 no data after each phase). The applied code is still uncommitted on `iac-change/paymentapi-raise-max-connections`. Record: `.culiops/iac-change-execution/paymentapi-raise-max-connections-20261109-1219.md`.
>
> Next: commit the record (`.culiops/iac-change-execution/paymentapi-raise-max-connections-20261109-1219.md`) · draft the result or ticket-close message with change-comms

Counts: 7 stops (see `stops.md`); 1 typed L2 (`L2-ASKED: Q8`); 0 unscripted; 0 `no canned output` commands.

L2-ASKED log, in the order said:
1. `L2-ASKED: Q8` — at `[F2]`, the `App source: ../paymentapi @ 5d1c8e4 ... — correct?` line; answer `yes`.
