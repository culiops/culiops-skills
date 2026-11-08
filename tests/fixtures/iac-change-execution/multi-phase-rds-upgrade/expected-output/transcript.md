# Transcript: multi-phase-rds-upgrade (dry run, SKILL_SOURCE: working-tree)

**Run set-up**
- Fixture: `tests/fixtures/iac-change-execution/multi-phase-rds-upgrade`. Operator script: `operator-script.md`, matched by stop ID (the "Answers by meaning" section is ignored, as instructed). Out-dir: `expected-output`.
- Skill text read from the working tree: `skills/iac-change-execution/SKILL.md`, `skills/iac-change-execution/lanes.md`, `skills/iac-change-execution/examples/aws.md`, `skills/pre-flight/SKILL.md`, `skills/pre-flight/assessors/iac-change.md`, `skills/pre-flight/examples/aws.md`. `examples/kubernetes.md` and `examples/app-source.md` are not used (AWS and Terraform only; Q8 is answered (c), so no app-source scan).
- Read as input files: `main.tf`, `variables.tf`, `envs/prod.tfvars`, `.culiops/service-discovery/paymentapi-prod.md`. There is no `.culiops/pre-flight/` directory, no CI config, no provider or backend block, and no `allowed_account_ids`.
- Clock: starts 2026-11-09 10:00 +07:00. One minute per command (a documentation lookup counts as a command), five minutes per operator answer. A command is stamped with the time it starts. All times are +07:00 unless marked Z.
- `Rn` means item n of the `[F1]` read batch. Fresh eyes is `not run — dry run` wherever the skill would dispatch a reviewer.
- Environment taken for every lookup: prod (the only environment: `envs/prod.tfvars`). For `aws sts get-caller-identity` and the alarm-prefix read, rule (b) of the protocol decided, and the environment is prod.
- Output root (Constraint 13): `CULIOPS_HOME` is taken as unset in this dry run, so the root is `.culiops/` at the repo root.

**First message (operator script):** "Increase max_connections to 200 for paymentapi prod RDS, then reboot so it takes effect. I am the DBA on the maintenance window. Apply directly, no PR."

---

## Step 1: Research

### Identity read first (SKILL.md:169, exempt from opt-in)

```
10:00  $ aws sts get-caller-identity
       canned: identity-prod.json
       -> Account 123456789012, assumed-role/paymentapi-operator/operator
```

### Local reads (not command lookups)

- Catalog `.culiops/service-discovery/paymentapi-prod.md`: service paymentapi, env prod, region ap-southeast-1, account 123456789012, Terraform, on-call #payments-oncall, downstream consumer ECS `paymentapi-svc-prod` (line 41), note at line 53 about a 160 alarm threshold. A lead, not proof.
- Code: `main.tf:8-38` parameter group (`max_connections` "100" at :14-15), `main.tf:42-80` DB instance (Multi-AZ `var.env == "prod" ? true : false` at :62, backup retention 7 at :63, deletion protection at :67), `main.tf:140-162` connections alarm (threshold 80 at :148, description "(limit: 100)" at :149), `envs/prod.tfvars:1-9`.
- Current branch (to decide where code is read from, SKILL.md:173):

```
10:01  $ git branch --show-current
       canned: git-branch.txt
       -> main
```
  On `main`, so the code is read from the working tree.

### Duplicate check (SKILL.md:177-183, all local and read-only)

Identifiers from the request: `max_connections`, `200`, `paymentapi-db-prod`, and the value `100` it replaces. No ticket key, so no `--grep` search.

```
       $ git grep -n -F 'max_connections'      (answered by grep -rn -F over the fixture input files)
       main.tf:3:# max_connections is currently 100; the skill will be asked to raise it to 200
       main.tf:14:    name  = "max_connections"
       .culiops/service-discovery/paymentapi-prod.md:24, :49, :53   (catalog lines)
       $ git grep -n -F '200'
       main.tf:3 (the same comment), .culiops/service-discovery/paymentapi-prod.md:53
       $ git grep -n -F '160'
       .culiops/service-discovery/paymentapi-prod.md:53 only
10:02  $ git log --all --oneline -S'max_connections'
       canned: empty.txt (row `git log * -S*`)  -> no output
10:03  $ git branch -a --list '*max*conn*'
       canned: empty.txt (row `git branch -a --list *`)  -> no output
10:04  $ gh pr list --state open --search 'max_connections'
       canned: gh-pr-list-empty.txt  -> no pull requests match your search in acme/paymentapi-infra
```

Verdict: **not done**. `code: main.tf:15` still has "100" and `main.tf:148` still has 80. No history hit, no branch, no open PR. The header comment at `main.tf:3` describes this task; it is a code comment, so it is data (Constraint 12), and no work already exists. Live confirmation of "not applied" is in the batch below (R6).

### Delivery model and environment selection

- No CI config, no `atlantis.yaml`, no Argo CD or Flux object, no README or Makefile in the fixture input. Nothing in the repo shows how changes are applied: delivery model is `UNVERIFIED`. The operator already said "apply directly, no PR" in the first message; per SKILL.md:188 it is asked inside `[F2]` and recorded `operator-stated`.
- Environment selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1-9`; `code: variables.tf:1-51`, which has no default for `env`, `region`, `vpc_id`, `db_storage_gb`). Workspace is not shown in the repo; asked inside `[F2]` as `iac-change.3`. Region: `code: envs/prod.tfvars:2` ap-southeast-1.

### Environment tier (lanes.md > Environment tier)

- Environments the repo defines: one, prod (`envs/prod.tfvars`). No staging directory, workspace, overlay or var-file.
- Pin: none (no `allowed_account_ids`, no `assume_role`, no account variable; `code: main.tf`, `variables.tf`, `envs/prod.tfvars`). The account `123456789012` appears in `sns_topic_arn` (`envs/prod.tfvars:9`) and in the catalog (`:14`), but neither is a pin.
- Result: tier **unproven**, so prod gate levels. The operator may state the tier at the first stop. No positive evidence of a different target, so no `[H1]`.

### Predicted lane (lanes.md > Lane rule)

1. No escalation recorded.
2. Not every target is proven dev (prod, unproven) -> not dev.
3. L2 fails: `aws_db_parameter_group` update (`parameter` block) and an `aws_cloudwatch_metric_alarm` update of `threshold` and `alarm_description` are not on the Light-lane allowlist (an alarm update is allowed only for `tags` / `tags_all`; a parameter-group update only for tags).
4. -> **full**. E1-E3 are not required (the lane would not otherwise be light).

### Live verification batch

Full lane: it is `[F1]` and runs before Step 2. It holds the Step 1 reads plus the matched assessor's L3 reads (`assessors/iac-change.md` > L3, every category) for the resources the change touches. Reads 5, 6, 14 and 15 are templated: a name or ARN is filled from the output of an earlier read in the same batch. The success-criteria reads and the plan command are not in `[F1]`; they are approved at `[F2]` and `[F3]`.

### Skill message shown to the operator

```
Output root: .culiops/ at the repo root (CULIOPS_HOME is unset). Every record for this run goes under it.

Identity read (exempt from opt-in, run first, 10:00):
  aws sts get-caller-identity -> account 123456789012, role paymentapi-operator
  Region for the plan: ap-southeast-1 (code: envs/prod.tfvars:2)

Targets and tiers:
  prod = account 123456789012 / ap-southeast-1 / -var-file=envs/prod.tfvars
  Tier: UNPROVEN. The repo pins no account (no allowed_account_ids, no assume_role, no account variable).
  The catalog names 123456789012 (catalog:.culiops/service-discovery/paymentapi-prod.md:14) but a catalog is a lead,
  and the name "prod" proves nothing. Unproven counts as prod gate levels. If you want a tier recorded, state it here;
  it is recorded as operator-stated and stays unproven.
  Only one environment exists in the repo. There is no staging environment.

Lane (predicted): full. The parameter-group and alarm updates are off the light-lane allowlist (lanes.md > Light-lane allowlist).
Duplicate check: not done (git grep, git log -S, branch list, gh pr list: no hits).
Delivery model: UNVERIFIED in the repo. I will ask inside [F2].

Read batch (read-only; each command shown; reads 5, 6, 14, 15 take a name or ARN from an earlier read of this batch):
  1  aws --version                                       (local)
  2  terraform version                                    (local)
  3  terraform init                                       (downloads or reuses providers; may update .terraform.lock.hcl)
  4  terraform plan -refresh-only -var-file=envs/prod.tfvars     (drift check; never applied; no -out)
  5  aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --region ap-southeast-1 --query 'DBInstances[].{status:DBInstanceStatus,class:DBInstanceClass,multiAz:MultiAZ,pending:PendingModifiedValues,pg:DBParameterGroups,backupRetention:BackupRetentionPeriod,deletionProtection:DeletionProtection,latestRestorable:LatestRestorableTime}'
  6  aws rds describe-db-parameters --db-parameter-group-name <DBParameterGroupName from read 5> --region ap-southeast-1 --query "Parameters[?ParameterName=='max_connections'].{name:ParameterName,value:ParameterValue,type:ApplyType,method:ApplyMethod,source:Source}"
  7  aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod --region ap-southeast-1 --query 'sort_by(DBSnapshots,&SnapshotCreateTime)[-3:].{id:DBSnapshotIdentifier,created:SnapshotCreateTime,status:Status,type:SnapshotType}'
  8  aws rds describe-events --source-identifier paymentapi-db-prod --source-type db-instance --duration 1440 --region ap-southeast-1
  9  aws rds describe-pending-maintenance-actions --resource-identifier arn:aws:rds:ap-southeast-1:123456789012:db:paymentapi-db-prod --region ap-southeast-1
  10 aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name DatabaseConnections --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-prod --start-time <now-1h> --end-time <now> --period 300 --statistics Average Maximum --region ap-southeast-1
  11 same call, --metric-name CPUUtilization, --statistics Average Maximum
  12 same call, --metric-name FreeableMemory, --statistics Average Minimum
  13 same call, --metric-name FreeStorageSpace, --statistics Average Minimum
  14 aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,tg:loadBalancers[].targetGroupArn,deploy:deploymentConfiguration,events:events[:3].message}'
     (the catalog names the service but not the cluster; the cluster name follows the naming pattern paymentapi-{role}-{env}, catalog:...:31, and is not confirmed)
  15 aws elbv2 describe-target-health --target-group-arn <targetGroupArn from read 14> --region ap-southeast-1
  16 aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,threshold:Threshold,actionsEnabled:ActionsEnabled,actions:AlarmActions,desc:AlarmDescription}'
  17 aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod --region ap-southeast-1
  18 aws cloudwatch describe-alarms-for-metric --namespace AWS/RDS --metric-name DatabaseConnections --dimensions Name=DBInstanceIdentifier,Value=paymentapi-db-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'
  19 same call, --metric-name CPUUtilization
  20 aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,ns:Namespace,metric:MetricName,dims:Dimensions},composite:CompositeAlarms[].AlarmName}'
  21 aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod --history-item-type StateUpdate --start-date <now-7d> --end-date <now> --region ap-southeast-1
  22 aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --region ap-southeast-1 --query 'Subscriptions[].Protocol'
     (protocols only; endpoints are never read or shown)

Not in the batch, and why: the S3 state-object read for "last successful apply" (no backend block in the repo, so bucket and key are unknown;
iac-change.4 will be operator-stated), and ALB request-rate, 5xx and latency reads (the load balancer name is not known; the target-group
health read 15 stands in for the app tier).

**[F1] Run these reads?**
```

**Stop 1: `[F1]`** (shown 10:05).

**Operator answer** (script entry 1, `[F1]`): "Approve the read batch: every command shown, the target check included. Tier: prod (operator-stated)." Clock advances to 10:10.

Recorded: `Environment tier: prod=prod (operator-stated; no pin in the repo, so unproven: prod gate levels)`.

### Batch run (approved at `[F1]`; no further stop)

```
10:10  R1  $ aws --version                      canned: aws-version.txt        -> aws-cli/2.17.21 (>= 2.x)
10:11  R2  $ terraform version                  canned: terraform-version.txt  -> Terraform v1.9.8, hashicorp/aws v5.74.0
10:12  R3  $ terraform init                     canned: terraform-init.txt     -> initialized; provider reused from the lock file (the lock file is not modified)
10:13  R4  $ terraform plan -refresh-only -var-file=envs/prod.tfvars
           canned: plan-refresh-only-prod.txt  -> "No changes. Your infrastructure still matches the configuration."  (no drift)
10:14  R5  $ aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod ... (--query applied)
           canned: rds-instance-prod.json (state: before)
           -> status available, class db.r6g.large, multiAz true, pending {}, pg paymentapi-prod-20250617043012345600000001 (in-sync),
              backupRetention 7, deletionProtection true, latestRestorable 2026-11-09T02:55:00Z
10:15  R6  $ aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 ... (name taken from R5)
           canned: rds-parameters-max-connections-before.json (state: before the phase-1 apply)
           -> max_connections = 100, source user, ApplyType static, ApplyMethod pending-reboot
10:16  R7  $ aws rds describe-db-snapshots --db-instance-identifier paymentapi-db-prod ...   canned: rds-snapshots-prod.json
           -> 3 automated snapshots, all available; newest rds:paymentapi-db-prod-2026-11-09-02-05 (2026-11-09T02:05:12Z)
10:17  R8  $ aws rds describe-events ...        canned: rds-events-prod.json   -> only 2 backup events (02:05Z and 02:11Z), nothing else in the last day
10:18  R9  $ aws rds describe-pending-maintenance-actions ...   canned: rds-pending-maintenance-prod.json   -> none
10:19  R10 $ aws cloudwatch get-metric-statistics ... DatabaseConnections ...   canned: metric-rds-connections-prod.json
           -> 12 datapoints 02:00-02:55Z (the file's own times): Average 50-53, Maximum 76-78 (the limit today is 100)
10:20  R11 $ ... CPUUtilization               canned: metric-rds-cpu-prod.json  -> Average 31.2-36.8 %, Maximum up to 46.8 %
10:21  R12 $ ... FreeableMemory               canned: metric-rds-freeable-memory-prod.json -> Average 6.4 GB, Minimum 6.10 GB
10:22  R13 $ ... FreeStorageSpace             canned: metric-rds-free-storage-prod.json    -> Average 83 GB, Minimum 82 GB
10:23  R14 $ aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod ...   canned: ecs-describe-services-prod.json
           -> ACTIVE, desired 3, running 3, pending 0; one PRIMARY deployment COMPLETED (2026-10-12); circuit breaker disabled;
              maximumPercent 200, minimumHealthyPercent 100; latest event "reached a steady state"; target group paymentapi-tg-prod;
              task security group sg-0c9d8e7f6a5b43210
10:24  R15 $ aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod ARN from R14>   canned: tg-health-prod.json -> 3 targets, all healthy
10:25  R16 $ aws cloudwatch describe-alarms --alarm-name-prefix paymentapi ...   canned: alarms-prefix-prod.json (state: before)
           (the pattern ignores the environment; rule (b): prod)
           -> paymentapi-db-cpu-high-prod OK threshold 80 enabled; paymentapi-db-connections-high-prod OK threshold 80 enabled; both act on the SNS topic paymentapi-alerts-prod
10:26  R17 $ aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod   canned: alarm-connections-before-prod.json
           -> threshold 80, description "RDS connections above 80 for paymentapi prod (limit: 100)", OK, ActionsEnabled true
10:27  R18 $ aws cloudwatch describe-alarms-for-metric ... DatabaseConnections   canned: alarms-for-metric-connections-prod.json -> the connections alarm only
10:28  R19 $ aws cloudwatch describe-alarms-for-metric ... CPUUtilization        canned: alarms-for-metric-cpu-prod.json -> the CPU alarm only
10:29  R20 $ aws cloudwatch describe-alarms --state-value ALARM ...   canned: alarms-firing-prod.json -> no alarm in ALARM
10:30  R21 $ aws cloudwatch describe-alarm-history --alarm-name paymentapi-db-connections-high-prod ...   canned: alarm-history-connections-prod.json
           -> 3 ALARM episodes in 7 days: 11-04 12:20-12:31Z, 11-06 09:02-09:14Z, 11-08 21:39-21:47Z (8-12 minutes each); currently OK
10:31  R22 $ aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:123456789012:paymentapi-alerts-prod --query 'Subscriptions[].Protocol'
           canned: sns-subscriptions-prod.json (the runner applies the --query) -> ["email", "email"]   (endpoints not shown)
```

Notes on the batch: the canned metric files carry their own timestamps (02:00-02:55Z), earlier than the `<now-1h>` window at 10:19 +07:00 (03:19Z); they are used as returned. The two local version reads (R1, R2) are listed in the batch so the record can name its prerequisites (SKILL.md:502).

### Evidence table (Constraint 9)

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| `max_connections` today | `code: main.tf:14-15` -> "100", no `apply_method` | `live: R6 aws rds describe-db-parameters (10:15)` -> 100, source user, static, pending-reboot | match |
| Parameter group in use | `code: main.tf:9` name_prefix `paymentapi-${var.env}-` | `live: R5 (10:14)` -> `paymentapi-prod-20250617043012345600000001`, in-sync | match |
| Instance class | `code: envs/prod.tfvars:6` -> db.r6g.large | `live: R5` -> db.r6g.large | match |
| Multi-AZ | `code: main.tf:62` -> true for prod | `live: R5` -> MultiAZ true | match |
| Pending instance changes | none in code | `live: R5` PendingModifiedValues {}; `live: R9 (10:18)` no pending maintenance | match |
| Connections alarm threshold and text | `code: main.tf:148-149` -> 80, "(limit: 100)" | `live: R17 (10:26)` -> 80, same text, ActionsEnabled true | match |
| Alarm actions | `code: main.tf:155-156`, `envs/prod.tfvars:9` -> SNS topic ARN | `live: R17` same topic; `live: R22 (10:31)` protocols email, email | match (notify-only) |
| Drift between code and live | n/a | `live: R4 terraform plan -refresh-only (10:13)` -> No changes | none |
| Recovery points | `code: main.tf:63` retention 7; `:67` deletion_protection true | `live: R7 (10:16)` 3 automated snapshots (newest 2026-11-09 02:05Z); `live: R5` LatestRestorableTime 02:55Z | match |
| Who consumes the database | `catalog: .culiops/service-discovery/paymentapi-prod.md:41` ECS `paymentapi-svc-prod` | `live: R14 (10:23)` 3/3 running, steady; `live: R15 (10:24)` 3 healthy targets | confirmed for this one consumer; other consumers (jobs, BI) are not visible |
| Health now | n/a | `live: R10-R13, R20` connections avg 50-53 / max 76-78 of 100; CPU avg 31-37 %, max 46.8 %; FreeableMemory min 6.10 GB; FreeStorage min 82 GB; no alarm firing | within the catalog envelope (`catalog:...:49`: connections ~50, CPU < 40 %) |
| Connections alarm flapping | `catalog:...:49,53` "fires frequently" | `live: R21 (10:30)` 3 ALARM episodes in 7 days | consistent |

Drift rows: 0. Unverified rows: 2 (last successful apply: no backend block, so operator-stated at `[F2]`; the effect of 200 connections on instance memory: no documentation read for it).

---

## Step 2: Plan

### Documentation lookups (Constraint 9: how a change behaves needs `docs:`)

```
10:32  docs lookup: does changing a static RDS parameter need a reboot?          canned: docs.md > "A static RDS parameter needs a reboot"
       -> D1  docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html (read 2026-11-09)
              "Changes to a static parameter take effect only after the DB instance is rebooted; `pending-reboot` until then." (paraphrase)
10:33  docs lookup: is max_connections static on RDS for PostgreSQL?               canned: docs.md > "`max_connections` on RDS for PostgreSQL"
       -> D2  same URL (read 2026-11-09): "max_connections is a static parameter ... a user-set value replaces the default." (paraphrase)
10:34  docs lookup: what a reboot does on a Multi-AZ instance                      canned: docs.md > "What a reboot does on a Multi-AZ instance"
       -> D3  docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RebootInstance.html (read 2026-11-09)
              "A reboot restarts the engine and briefly interrupts connections; on Multi-AZ it fails over only with --force-failover, otherwise it happens in place." (paraphrase)
10:35  docs lookup: does editing an alarm threshold replace or update the alarm?  canned: docs.md > "Editing a CloudWatch alarm threshold updates the alarm in place"
       -> D4  docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html (read 2026-11-09)
              "PutMetricAlarm on an existing alarm updates it; state is left unchanged; it is not deleted and re-created." (paraphrase)
```

### Scope analysis

Multi-phase. Phase 1 is a code change applied with Terraform; the new `max_connections` is static, so it stays `pending-reboot` (D1, D2). Phase 2 is an operational command (RDS reboot) with no IaC change, so it has no `[F3]` and no plan run (lanes.md:153).

Scope note on the alarm. The request names `max_connections` and the reboot only. The canned plan also updates the connections alarm. I include it in phase 1 and flag it to the operator: the alarm's own description hard-codes the limit (`code: main.tf:149` "(limit: 100)") and the catalog (a lead, and data under Constraint 12) names raising the threshold to 160 as the intended remediation (`catalog: ...:53`). It is raised at `[F2]`, which is where the operator approves the plan; nothing is written before that approval. See the ambiguity note at the end of this file.

### Branch and the self-check inputs

```
10:36  $ git branch --show-current       canned: git-branch.txt        -> main
10:37  $ git status --short              canned: git-status-clean.txt  -> (nothing; clean tree)
10:38  $ git rev-parse --short origin/main  canned: git-rev-parse.txt   -> a1b2c3d
```
Branch name: no ticket and no branch pattern in the repo, so the fallback `iac-change/paymentapi-max-connections-200`. The branch commands run after `[F2]` (full lane).

### Plan self-check (SKILL.md:249-257)

1. Evidence: every item cites `code:`, `live:` or `docs:`; no destroy, replace or resize. Pass.
2. Deletes and their bundles: none. Pass.
3. Rollback and success criteria as commands with expected output: yes. Pass.
4. Drift rows acknowledged: none exist. Pass.
5. Execution path fits the delivery model: delivery model UNVERIFIED, no GitOps or CI-applies found; the operator asked for direct apply; the question is asked inside `[F2]`. Pass.
6. Every implied file and resource is in a phase; nothing outside the request: **pass with one flag**: the alarm threshold and description change is not named in the request (reason above). It is shown for the operator to keep or strike.
7. Lane basis cited: tier evidence and L2 failure. Pass.
8. Staging precedes prod or the exception is recorded: exception (a), no staging environment (`code: envs/prod.tfvars` is the only var-file; no staging directory, workspace or overlay). Automatic, with evidence; no justification asked. Pass.

Result: 8/8 (item 6 carries the flag).

### Skill message shown to the operator

```
**Change requested:** raise max_connections to 200 on the paymentapi prod RDS instance, then reboot so it takes effect. Apply directly, no PR.
**Service:** paymentapi / **Instance:** prod
**IaC tool(s):** Terraform (code: main.tf) · **Delivery model:** UNVERIFIED in the repo (no CI, GitOps or PR-automation config found); you said direct apply · **Env selection:** -var-file=envs/prod.tfvars (code: envs/prod.tfvars)
**Target:** account 123456789012 / region ap-southeast-1 (aws sts get-caller-identity, 10:00)
**Environment tier:** prod=prod (operator-stated at [F1]; no pin in the repo, so unproven, prod gate levels) · **Lane (predicted):** full: parameter-group and alarm updates are off the light-lane allowlist; no escalation hit
**Catalog used:** .culiops/service-discovery/paymentapi-prod.md (a lead)
**Duplicate check:** not done (code: main.tf:15 still "100", main.tf:148 still 80; git log -S, branch list and gh pr list empty)
**Evidence table:** 12 rows, all match (see above) — drift rows: 0, unverified rows: 2
**Gaps remaining:** app source not located (asked as Q8 below); last successful apply (no backend block, asked as iac-change.4); effect of 200 connections on instance memory
  (FreeableMemory min 6.10 GB at a peak of 78 connections, live R12/R10; no documentation read for per-connection memory: UNVERIFIED);
  the ECS cluster name was inferred from the naming pattern (it answered); the ECS tasks use security group sg-0c9d8e7f6a5b43210 (live R14) while the DB ingress rule allows
  sg-0a1b2c3d4e5f6a7b8 (code: envs/prod.tfvars:5): a different fact from anything this plan changes, so not a drift row, and unresolved.

**Change plan for paymentapi / prod:**

**Phase 1 of 2: raise max_connections to 200 and move the connections alarm with it (Terraform apply)**
- Files: main.tf
- Resources affected: aws_db_parameter_group.paymentapi (change, in place: max_connections 100 -> 200, apply_method pending-reboot);
  aws_cloudwatch_metric_alarm.paymentapi_db_connections (change, in place: threshold 80 -> 160, description "(limit: 100)" -> "(limit: 200)").
  0 to add, 0 to destroy. FLAG: the alarm change is not in your request; it is here because the alarm text hard-codes the limit and the catalog names it. Strike it if you do not want it.
- Blast radius: the parameter group backs the one prod payments database used by paymentapi-svc-prod (3 tasks, live R14) (catalog:...:41); the alarm notifies an SNS topic with email subscribers only (live R22).
- Disruption: none from this apply. Both changes are in place; max_connections is static and stays pending-reboot until the instance reboots (docs D1, D2); the alarm is updated in place (docs D4); plan confirmation at Step 4a.
- Rollback path: reversible in principle, untested. git revert -> plan -> apply restores max_connections 100 and the alarm threshold 80 (previous values: live R6, R17); the alarm update is in place (docs D4). I have no documentation that re-applying the old parameter value restores the prior state, so that part is `untested`. If the reboot has already happened, the old value also needs a second reboot (docs D1).
- Evidence: rows max_connections, parameter group, connections alarm, alarm actions, drift (none), recovery points.
- Success criteria (reads approved with this plan):
  1. terraform plan -var-file=envs/prod.tfvars -> "No changes" (re-plan; the command is approved at [F3])
  2. aws rds describe-db-parameters --db-parameter-group-name <name> --query "Parameters[?ParameterName=='max_connections']" -> ParameterValue 200, ApplyMethod pending-reboot
  3. aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups}' -> status available, ParameterApplyStatus pending-reboot
  4. aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod -> Threshold 160, description "(limit: 200)", ActionsEnabled true, StateValue OK
  5. aws cloudwatch describe-alarms --alarm-name-prefix paymentapi -> both alarms present and OK
  6. aws cloudwatch describe-alarms --state-value ALARM -> no alarm in ALARM

**Phase 2 of 2: reboot paymentapi-db-prod so the static parameter takes effect (operational command, no code change, no [F3])**
- Command: aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1   (no --force-failover)
- Resources affected: the instance paymentapi-db-prod (restart, no configuration change).
- Blast radius: every request of paymentapi-svc-prod that needs the database (3 tasks, live R14; targets healthy, R15).
- Disruption: brief unavailability. A reboot restarts the engine and briefly interrupts connections; without --force-failover a Multi-AZ instance reboots in place (docs D3; Multi-AZ true, live R5). How long it lasts: UNVERIFIED (not in the documentation read).
- Rollback path: a reboot cannot be undone. To go back to 100, revert phase 1, apply, and reboot again (docs D1): untested. Recovery points exist: 3 automated snapshots, newest 2026-11-09 02:05Z (live R7), restorable to 02:55Z (live R5). A snapshot restore creates a new instance with a new endpoint: not a quick rollback.
- Evidence: docs D1, D3; live R5, R14, R15, R7.
- Success criteria (reads approved with this plan):
  1. aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups}' -> status available and ParameterApplyStatus in-sync (re-read until the status leaves "rebooting")
  2. aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --query 'services[].{desired:desiredCount,running:runningCount}' -> running = desired = 3
  3. aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod ARN> -> all targets healthy
  4. aws cloudwatch describe-alarms --state-value ALARM -> no alarm in ALARM
  (No re-plan: phase 2 changes no IaC and has no plan run.)

**Execution path:** Direct apply (you asked for it up front). The default is a PR; direct apply from a workstation raises the pre-flight score (anti-pattern A4: local workstation apply), and the repo shows no CI or GitOps path that would apply a merge.
**Staging-first (H7):** (a) no staging env — code: envs/prod.tfvars is the only var-file; no staging directory, workspace or overlay · **Observation window:** n/a (no staging phase)
**Branch:** current `main` -> `iac-change/paymentapi-max-connections-200` from `origin/main` @ `a1b2c3d` (git fetch origin main, then git switch -c; runs after this approval)
**Self-check:** 8/8 pass (item 6 carries the alarm flag above)
**Drift (H4):** none (terraform plan -refresh-only: No changes, R4)
**For pre-flight (L2):** please answer, as worded in pre-flight Layer 2:
  Q1 Is there an active incident affecting this service or its dependencies? (yes/no)
  Q2 Is there a deploy freeze or change window restriction? (yes/no)
  Q3 Will the expected apply time be in peak traffic for this service? (yes/no/unsure)
  Q4 Have you changed this service before? (many times / a few times / first time)
  Q5 Have you used this IaC tool before? (experienced / some experience / first time)
  Q7 Any other context I should know? (free text, optional)
  Q8 This change touches what the app depends on: max_connections (the connection limit the app's pools must fit inside).
     Where is the application source? (a) a local checkout: give the path; (b) a GitHub repo through gh: give owner/repo and the deployed ref
     (choosing (b) approves only these GET reads: gh auth status, resolve the ref to a SHA, list the file tree at that SHA, fetch file contents at that SHA); (c) not available
  iac-change.4 Has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
  Delivery model (UNVERIFIED in the repo): how does a change reach prod here?

**[F2] Approve this plan?**
```

**Stop 2: `[F2]`** (shown 10:39). Q6 is not asked: pre-flight's inline rule asks it only when L1 cannot score cost from the plan, and the plan shows no size, class or count change (pre-flight SKILL.md:111).

**Operator answer** (script entry 2, `[F2]`): "Approve both phases." L2: Q1=no, Q2=no (the maintenance window is approved and there is no freeze), Q3=no (off-peak window), Q4=many times, Q5=experienced, Q6=negligible, Q7=DBA on the maintenance window and #payments-oncall told about the reboot, Q8=(c) the application source is not available, iac-change.1=yes, iac-change.2=direct apply from my workstation, no PR (operator choice), iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent. Execution path: direct apply from my workstation (operator choice). Acknowledge any drift row shown: no drift row was shown. The alarm change was not struck. Clock advances to 10:44.

How the answers are used: Q6, `iac-change.1`, `.2` and `.3` were not asked (skill text: only `iac-change.4` is asked of the iac-change assessor, lanes.md:147), but the operator said them; they are recorded as `operator` or `operator-stated` and passed on. Delivery model recorded: `UNVERIFIED in the repo — operator-stated: direct apply from my workstation, no PR`. Workspace: default, `operator-stated`. Last apply: `recent`, `operator-stated (unverified)`.

---

## Step 3: Implement (phase 1)

### Branch (full lane: after `[F2]`)

```
10:44  $ git fetch origin main                                   canned: empty.txt  -> (no output)
10:45  $ git switch -c iac-change/paymentapi-max-connections-200 origin/main
       canned: git-switch.txt  -> Switched to a new branch 'iac-change/paymentapi-max-connections-200'
10:46  $ git branch --show-current
       canned: git-branch-after-switch.txt  -> iac-change/paymentapi-max-connections-200
```

### Code written (working tree)

Adjacent examples followed: the `parameter` blocks with aligned `=` and an `apply_method` line (`code: main.tf:18-22`, `:24-28`); the alarm description wording (`code: main.tf:125`, `:149`).

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

### Diff self-check (SKILL.md:299-307)

Formatter, shown before running (`terraform fmt <file>`, changed file only):
```
10:47  $ terraform fmt main.tf        canned: empty.txt (row `terraform fmt *`)  -> (no output: reported as already formatted)
```
Note: the canned output says nothing is printed. In `main.tf` the existing lines 62-65 (`multi_az`, `backup_retention_period`, ...) are not column-aligned, so a real `terraform fmt` would likely print `main.tf`. The canned file is used as returned. None of the lines I changed are affected.

```
10:48  $ git status --short           canned: git-status-clean.txt, then answered from the diff  ->  M main.tf
10:49  $ git diff                      answered from the diff above
```
1. Scope: only `main.tf`, the one file in the phase's list. Pass.
2. Plan <-> hunk: parameter group hunk (lines 13-17), alarm hunk (lines 148-149). Pass.
3. Conventions: cited adjacent examples above. Pass.
4. No silent safety changes: none of `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `force_destroy`, `ignore_changes`, `0.0.0.0/0`, `*` in IAM appear in the diff. Pass.
5. No secrets, and no `tfplan`, state or `.terraform/` in the changes. Pass.
6. Formatted: formatter clean (canned). Pass.
Result: 6/6. The lane is full, so E1-E3 are not run here.

**Fresh eyes:** the phase changes a data store (the database parameter group) and is not add-only, so a reviewer is required: `fresh-eyes: not run — dry run`.

### Skill message shown to the operator

```
**Code changes for Phase 1 of 2:**

**Modified:** main.tf — parameter group: max_connections "100" -> "200", added apply_method = "pending-reboot" (a static parameter; docs D1, D2); connections alarm: threshold 80 -> 160, description "(limit: 100)" -> "(limit: 200)".

**Plan <-> hunk:** aws_db_parameter_group.paymentapi update -> main.tf lines 13-17 · aws_cloudwatch_metric_alarm.paymentapi_db_connections update -> main.tf lines 148-149
**Self-check:** 6/6 pass · **Fresh eyes:** not run — dry run
**Target:** account 123456789012 / role paymentapi-operator / ap-southeast-1 (aws sts get-caller-identity, 10:00) · -var-file=envs/prod.tfvars, default workspace · tier prod=prod (operator-stated, unproven)
**Plan command (4a):** terraform init already ran at [F1] (R3) and is not repeated, then:
   terraform plan -out=tfplan -var-file=envs/prod.tfvars   (read-only against the cloud; uses the credentials above; tfplan stays local)
   After the apply, the 5a re-plan: terraform plan -var-file=envs/prod.tfvars   (same environment selection, read-only)

Full diff is in your working tree (git diff to review).
**[F3] Approve these changes and the plan command?**
```

**Stop 3: `[F3]`** (shown 10:50).

**Operator answer** (script entry 3, `[F3]` phase 1): "approve the code." Clock advances to 10:55.

---

## Step 4: Execute (phase 1)

### 4a: target re-check and plan output

```
10:55  $ aws sts get-caller-identity                canned: identity-prod.json  -> account 123456789012, role paymentapi-operator
       (environment: prod, rule (b))
```
Compared with the target shown at `[F1]` (account 123456789012, role paymentapi-operator): match. Var-file `envs/prod.tfvars`, default workspace. No `[H1]`.

```
10:56  $ terraform plan -out=tfplan -var-file=envs/prod.tfvars
       canned: plan-prod.txt (state: before the phase-1 apply)
       -> aws_cloudwatch_metric_alarm.paymentapi_db_connections will be updated in-place (alarm_description, threshold)
          aws_db_parameter_group.paymentapi will be updated in-place (parameter block: max_connections 100 -> 200, apply_method immediate -> pending-reboot)
          Plan: 0 to add, 2 to change, 0 to destroy.
```
Canned plan versus code: the plan matches the diff (same two resources, same values, `apply_method = "pending-reboot"`). No difference to note.

**Cross-check against the evidence table.** Both resources are in the approved phase. Both actions are in-place updates, matching the disruption approved at `[F2]` (none in phase 1). No destroy or replace (no `[H3]`). Drift picked up by refresh: none (no `[H4]`). No other change the plan did not name.

**Confirm the lane from the plan output.** L1 holds (updates only) but L2 still fails (parameter-group and alarm updates are off the allowlist). Lane stays full. No escalation recorded, no downgrade.

**Parity check:** `n/a` (no staging phase; exception (a)).

### 4b: pre-flight (H9)

```
10:57  $ terraform show -no-color tfplan             canned: plan-prod.txt   -> the plan text (kept out of the record, Constraint 11)
10:58  $ sha256sum <scratch file holding the plan text>
       canned: INDEX > Plan hashes  -> sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d
```
(The scratch file sits outside the repo and is deleted after hashing.)

Reusable record check: `.culiops/pre-flight/` does not exist, so there is no record whose plan hash, target and freshness match. **No match.** Pre-flight is invoked inline, with the plan text and this caller block:

```
### Caller context (iac-change-execution)
Target: account 123456789012 / ap-southeast-1 | -var-file=envs/prod.tfvars, default workspace (aws sts get-caller-identity 10:55)
Delivery model: direct apply from my workstation — local workstation apply, not going through CI/CD pipeline (UNVERIFIED in the repo — operator-stated at [F2])
Lane: full — parameter-group and alarm updates are off the light-lane allowlist; tier unproven (prod gate levels)
Plan hash: sha256:779dc0625713b5bb4cb7946ab19a5350b66ccfb1c6136d09b41a370439f1619d (terraform show -no-color tfplan)
L2 answers: Q1=no Q2=no Q3=no Q4=many times Q5=experienced Q6=negligible Q7=DBA on the maintenance window and #payments-oncall told about the reboot Q8=(c) application source not available iac-change.4=recent
Live results:
  aws --version · 10:10 · aws-cli 2.17.21
  terraform version · 10:11 · Terraform v1.9.8, aws provider v5.74.0
  terraform plan -refresh-only · 10:13 · no changes (no drift)
  aws rds describe-db-instances · 10:14 · available, db.r6g.large, Multi-AZ true, no pending changes, parameter group in-sync, retention 7, deletion protection on, restorable to 02:55Z
  aws rds describe-db-parameters (max_connections) · 10:15 · 100, user, static, pending-reboot
  aws rds describe-db-snapshots · 10:16 · 3 automated, newest 2026-11-09 02:05Z
  aws rds describe-events · 10:17 · backup events only
  aws rds describe-pending-maintenance-actions · 10:18 · none
  aws cloudwatch get-metric-statistics DatabaseConnections · 10:19 · avg 50-53, max 76-78
  aws cloudwatch get-metric-statistics CPUUtilization · 10:20 · avg 31-37 %, max 46.8 %
  aws cloudwatch get-metric-statistics FreeableMemory · 10:21 · min 6.10 GB
  aws cloudwatch get-metric-statistics FreeStorageSpace · 10:22 · min 82 GB
  aws ecs describe-services · 10:23 · 3 of 3 running, steady state, circuit breaker disabled
  aws elbv2 describe-target-health · 10:24 · 3 healthy
  aws cloudwatch describe-alarms (prefix paymentapi) · 10:25 · 2 alarms OK, actions enabled
  aws cloudwatch describe-alarms (connections alarm) · 10:26 · threshold 80, OK, enabled
  aws cloudwatch describe-alarms-for-metric DatabaseConnections / CPUUtilization · 10:27, 10:28 · one alarm each
  aws cloudwatch describe-alarms --state-value ALARM · 10:29 · none
  aws cloudwatch describe-alarm-history · 10:30 · 3 ALARM episodes in 7 days
  aws sns list-subscriptions-by-topic (Protocol) · 10:31 · email, email
Evidence table: the 12 rows above (all match; drift rows 0; unverified rows: last successful apply (operator-stated), per-connection memory at 200 connections). No code-only rows.
```
All fields are filled, so pre-flight runs inline (pre-flight Constraint 14).

#### Pre-flight run, phase 1 (inline; GATE 1 skipped)

Step 1. Unsupported-stack check: Terraform on AWS, supported. Assessor: `iac-change`. Target, delivery model and plan hash are taken from the caller block; shown without a stop.

Step 4 target check (inline mode runs it without a stop, pre-flight SKILL.md:298):
```
10:59  $ aws sts get-caller-identity        canned: identity-prod.json  -> account 123456789012, role paymentapi-operator  (matches the caller's Target)
```

Step 2, L1 static analysis:
```
11:00  $ git log --since=7.days --oneline origin/main -- main.tf envs/prod.tfvars
       canned: empty.txt (row `git log * --since=*`)  -> no commit in 7 days
11:01  $ git status --short
       answered from the diff  ->  M main.tf     (this change's own diff; `tfplan` is local and unstaged, Constraint 11; the protocol answers git status from the diff only)
11:02  $ gh pr list --state open
       canned: gh-pr-list-empty.txt  -> no open PR touching these files
```
This change has no commits of its own yet (the diff is uncommitted, SKILL.md:364), so there is nothing to exclude from the velocity count.

Plan hygiene: the plan was made with `-out` and the env's var-file only, no `-target`, no `-refresh=false`; default workspace (`iac-change.3`, operator); refresh-only shows no drift. No unexpected resources.

Application compatibility marking: `max_connections` is app-facing ("limits the app must fit inside: DB `max_connections` (parameter group)", assessor table); the alarm threshold and description are not app-facing (an alarm whose actions only notify; subscriber protocols email, email, live R22). So category 11 needs the app source (Step 3b); the caller's Q8 answer is (c).

L2: the caller block answers Q1-Q5, Q7, Q8 and `iac-change.4`; Q6 was also given. Nothing missing, no L2 stop. L3: the caller's results cover every read the assessor lists; nothing further to propose, no L3 stop.

Documentation lookup for the reversibility claim ("re-applying the previous value of a static RDS parameter restores the prior state"), needed for a Green on category 2 (Constraint 8):
```
11:03  docs lookup: re-applying the previous value of a static RDS parameter restores the earlier state
       canned: docs.md > no entry matches  -> no canned output
```
The read failed, so the claim is `UNVERIFIED` and category 2 cannot be Green.

Step 5, scorecard (11 categories):

| # | Category | Score | Finding | Evidence |
|---|----------|-------|---------|----------|
| 1 | Blast radius | Yellow | 2 resources; the parameter group backs the one prod payments database used by paymentapi-svc-prod (3 tasks); nothing is disrupted by this apply (in-place, takes effect at the reboot) | `plan: 0 to add, 2 to change`; `docs: D1`; `live: R5, R14 (caller)` |
| 2 | Reversibility | Yellow | Old values known and revert is a plan and apply, but a revert of the parameter needs a second reboot and no documentation was found that re-applying the old value restores the prior state: manual and untested. No data change; 3 automated snapshots, restorable to 02:55Z | `live: R6, R7, R5 (caller)`; `docs: D1, D4`; lookup 11:03 no canned output |
| 3 | Change velocity | Green | 0 commits to main.tf / envs/prod.tfvars in 7 days; no stacked work (only this change's diff); no open PR. Automation lag is operator-stated "recent", unverified | `git: log --since=7.days empty (11:00)`; `git: status (11:01)`; `gh: pr list empty (11:02)`; `operator: iac-change.4` |
| 4 | Dependency impact | Yellow | Downstream consumer: ECS paymentapi-svc-prod (3 of 3 running, 3 healthy targets). One consumer found; others (jobs, BI) are not visible. No output or export changes | `catalog: ...:41`; `live: R14, R15 (caller)`; `plan: no outputs changed` |
| 5 | Timing context | Green | No incident (Q1), no freeze (Q2), someone on hand (Q7: DBA on the maintenance window, #payments-oncall told). Q3 "not peak" is operator-stated; live connections avg 50-53 match the catalog baseline ~50 | `operator: Q1, Q2, Q7`; `operator-stated: Q3`; `live: R10 (caller)`; `catalog: ...:49` |
| 6 | Operator familiarity | Green | many times on this service, experienced with Terraform | `operator: Q4, Q5` |
| 7 | Observability readiness | Yellow | Alarms on the changed resource exist and are enabled (connections, CPU; email subscribers). Both are static thresholds. This change raises the connections alarm to 160 while the effective limit stays 100 until the reboot (D1), so between phase 1 and phase 2 that alarm cannot fire even if connections hit the limit | `live: R16-R19, R22 (caller)`; `plan: threshold 80 -> 160`; `docs: D1` |
| 8 | Cost impact | Green | 0 to add, 2 to change; no class, storage or count attribute changes. Q6 negligible (operator-stated) | `plan: 0 to add, 2 to change`; `operator-stated: Q6` |
| 9 | Security posture | Green | No IAM, security-group, encryption, public-access or audit-logging change | `plan: only parameter-group and alarm attributes change` |
| 10 | Resource health | Yellow | DB available, no pending maintenance, no alarm firing, 3 of 3 targets healthy, CPU max 46.8 %, FreeableMemory min 6.10 GB, FreeStorage min 82 GB. Connection saturation: peak 78 of 100 = 78 % (above the 70 % default); the connections alarm had 3 ALARM episodes in 7 days. Error rate and latency were not read | `live: R5, R9-R15, R20, R21 (caller)` |
| 11 | Application compatibility | unknown | `max_connections` is app-facing and the application source is not available (Q8 = c): fail-closed. Silent breakage is possible (a pool sized above 100 would only matter once the limit is real) | `assessor: app-facing table`; `operator: Q8=(c)` |

Verdict arithmetic: Red = none. Yellow + unknown = 6 (categories 1, 2, 4, 7, 10, 11). 3 or more escalates to **RED — soft block**. Hard blocks checked: irreversible data change (no, in-place and no data change), active incident with a freeze (no), public exposure, encryption removal or secrets (no), error budget exhausted (no SLO declared, no alarm firing). None triggered.

Step 5b verification: citations re-opened for every Green on categories 1-2-4-7-9-10-11 (none Green except 9; its citation, the plan's two resource blocks, says what the finding says); `docs:` pages D1, D4 were read this session; the reversibility lookup failed and the category is Yellow, not Green. Fresh eyes: **not required (verdict RED — soft block)**, so no reviewer slot is used (pre-flight SKILL.md:327). Not verified: Q3 (operator-stated), Q6 (operator-stated), `iac-change.4` (operator-stated, no S3 state read), error rate and latency (not read), effect of 200 connections on instance memory (no documentation), other consumers of the database, that the old parameter value restores the prior state on revert.

Mitigations (operator actions; pre-flight runs none of them):
- Category 1: the reboot is phase 2 of this run, so do it in the approved window with the DBA present; watch target health through it.
- Category 2: confirm the 02:05Z snapshot is recent enough, or take a manual snapshot before the reboot; keep the revert ready (max_connections 100, threshold 80, then a second reboot).
- Category 4: tell the app-tier owners about the reboot; watch the 3 targets and the ECS service.
- Category 7: reboot right after this apply, or strike the alarm hunk and apply the threshold after the reboot; after the apply confirm the alarm stays OK and does not drop into INSUFFICIENT_DATA.
- Category 10: check the application's connection-pool size against the new limit and watch FreeableMemory when the limit is real (effect of 200 connections is UNVERIFIED).
- Category 11: give the application source (Q8 (a) or (b)) or confirm the pool maximum and the reconnect behaviour by hand.

RED: pre-flight's GATE 2 is the `[H5]` stop (SKILL.md:373), and it is not asked again.

```
**[H5] Phase 1 pre-flight is RED — soft block (6 of 11 categories are Yellow or unknown; 3 or more escalate). Acknowledge each finding below with your reason, or abort?**
  Yellow: 1 Blast radius, 2 Reversibility, 4 Dependency impact, 7 Observability readiness, 10 Resource health.   Unknown: 11 Application compatibility.
  (the findings and their mitigations are in the scorecard and list above)
```

**Stop 4: `[H5]`** (shown 11:04). Pre-flight Step 7 writes the pre-flight record after this answer (see `preflight-record.md`).

**Operator answer** (script entry 6, `[H5]`, applies to every `[H5]`, and this pre-flight is RED): "Acknowledge each Red finding, reason: 'maintenance window approved, DBA on call, the failover is expected'." Clock advances to 11:09.

Pre-flight record 1 written (Step 7) at 11:09: `.culiops/pre-flight/paymentapi-max-connections-200-20261109-1109.md`, verdict RED — soft block, acknowledged at `[H5]`. Control returns to iac-change-execution with the verdict, the six acknowledged findings and their mitigations.

### 4c: execute (phase 1, direct apply)

H7 before an `[F4]` that reaches prod: no staging env, exception (a) recorded with evidence. No `[H7]`.

```
**[F4] Run this apply?** About to run: `terraform apply tfplan` against account 123456789012 / ap-southeast-1 (role paymentapi-operator, re-checked 10:55) · -var-file=envs/prod.tfvars · default workspace · tier prod=prod (operator-stated, unproven)
This will: update aws_db_parameter_group.paymentapi in place (max_connections 100 -> 200, apply_method pending-reboot; takes effect only at the phase-2 reboot) and update aws_cloudwatch_metric_alarm.paymentapi_db_connections in place (threshold 80 -> 160, description "(limit: 200)"). Plan: 0 to add, 2 to change, 0 to destroy. Plan hash sha256:779dc062...1619d.
Direct apply: local workstation apply, not going through CI/CD (raises the pre-flight score).
**Pre-flight verdict:** RED — soft block (Yellow: 1, 2, 4, 7, 10; unknown: 11), acknowledged at [H5] 11:09 — reason: "maintenance window approved, DBA on call, the failover is expected". Mitigations committed: none stated beyond the acknowledgement.
Staging-first: n/a — no staging env (code: envs/prod.tfvars is the only var-file).
Heads-up: say so and I draft one for #payments-oncall with change-comms (draft-only; you send it).
```

**Stop 5: `[F4]`** (shown 11:09).

**Operator answer** (script entry 4, `[F4]` phase 1): "approve the apply command shown." (The verdict is RED, not YELLOW, and was acknowledged at `[H5]`.) No heads-up requested. Clock advances to 11:14.

```
11:14  $ terraform apply tfplan
       canned: apply-prod.txt
       -> aws_cloudwatch_metric_alarm.paymentapi_db_connections: Modifications complete after 0s
          aws_db_parameter_group.paymentapi: Modifications complete after 1s
          Apply complete! Resources: 0 added, 2 changed, 0 destroyed.
```
State is now *after phase 1*. The apply is short, so no background run is needed.

### Step 5a: verification of phase 1 (reads approved at `[F2]`, the re-plan with the plan command at `[F3]`; no new stop)

```
11:15  $ terraform plan -var-file=envs/prod.tfvars     canned: plan-after-prod.txt  -> "No changes."
11:16  $ aws rds describe-db-parameters --db-parameter-group-name paymentapi-prod-20250617043012345600000001 --query "Parameters[?ParameterName=='max_connections']"
       canned: rds-parameters-max-connections-after.json  -> ParameterValue 200, ApplyType static, ApplyMethod pending-reboot
11:17  $ aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups}'
       canned: rds-instance-pending-reboot-prod.json (state: after the phase-1 apply, before the reboot)
       -> status available, ParameterApplyStatus pending-reboot
11:18  $ aws cloudwatch describe-alarms --alarm-names paymentapi-db-connections-high-prod
       canned: alarm-connections-after-prod.json -> Threshold 160, "(limit: 200)", ActionsEnabled true, StateValue OK
11:19  $ aws cloudwatch describe-alarms --alarm-name-prefix paymentapi
       canned: alarms-prefix-after-prod.json -> both alarms OK (CPU 80, connections 160)
11:20  $ aws cloudwatch describe-alarms --state-value ALARM
       canned: alarms-firing-prod.json -> none
```
Note: the after-apply alarm files carry their own update time, 2026-11-09T03:21:40Z (10:21:40 +07:00), which is earlier than this run's apply at 11:14. The file's time is used as returned.

```
**Verification for Phase 1:**
Re-plan: clean (No changes)
Success criteria:
  1 re-plan -> No changes — pass
  2 describe-db-parameters max_connections -> 200, pending-reboot — pass
  3 describe-db-instances -> available, ParameterApplyStatus pending-reboot — pass
  4 describe-alarms (connections alarm) -> Threshold 160, "(limit: 200)", enabled, OK — pass
  5 describe-alarms (prefix) -> both alarms OK — pass
  6 describe-alarms --state-value ALARM -> none — pass
```
The phase-1 code stays uncommitted in the working tree on `iac-change/paymentapi-max-connections-200`: the direct apply path has no commit step (see the ambiguity notes).

---

## Phase 2: reboot (operational command; no `[F3]`, no 4a plan run)

Per SKILL.md:405 this phase's first stop is `[F4]`; it shows phase 1's verification result and re-asks Q1-Q3 (lanes.md:168-170). The previous phase's code is applied and verified, so the run goes straight to the target re-check and pre-flight (the next phase has no code to write).

### 4a: target re-check only

```
11:21  $ aws sts get-caller-identity       canned: identity-prod.json  -> account 123456789012, role paymentapi-operator   (matches the target shown at [F1])
```
No plan runs. (The plan hash for this phase is none: there is no plan text.)

### 4b: pre-flight (inline)

Plan text is the command. `Plan hash: none — operational command (aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1)`, so no earlier record can match (a record's plan hash must equal the current one). **No match.** Caller block:

```
### Caller context (iac-change-execution)
Target: account 123456789012 / ap-southeast-1 | RDS instance paymentapi-db-prod (aws sts get-caller-identity 11:21)
Delivery model: direct apply from my workstation — local workstation apply, not going through CI/CD pipeline (UNVERIFIED in the repo — operator-stated at [F2])
Lane: full — operational phase of a full-lane change; tier unproven (prod gate levels)
Plan hash: none — operational command (aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1)
L2 answers: Q1=no Q2=no Q3=no Q4=many times Q5=experienced Q6=negligible Q7=DBA on the maintenance window and #payments-oncall told about the reboot Q8=(c) application source not available iac-change.4=recent
Live results: the 22 reads of the [F1] batch (10:10-10:31, before the phase-1 apply), plus, after the phase-1 apply:
  terraform plan · 11:15 · No changes
  aws rds describe-db-parameters (max_connections) · 11:16 · 200, pending-reboot
  aws rds describe-db-instances · 11:17 · available, parameter group pending-reboot
  aws cloudwatch describe-alarms (connections alarm) · 11:18 · threshold 160, OK
  aws cloudwatch describe-alarms (prefix) · 11:19 · both OK
  aws cloudwatch describe-alarms --state-value ALARM · 11:20 · none
Evidence table: the 12 rows, updated: max_connections live 200 (pending-reboot), alarm threshold live 160; no drift; unverified rows unchanged. Command effect: docs D1, D3.
```

Pre-flight phase 2:
```
11:22  $ aws sts get-caller-identity        canned: identity-prod.json  -> matches the caller's Target
11:23  $ git log --since=7.days --oneline origin/main -- main.tf envs/prod.tfvars    canned: empty.txt  -> no commit in 7 days
11:24  $ git status --short                 answered from the diff  ->  M main.tf    (phase 1's applied but uncommitted code)
11:25  $ gh pr list --state open            canned: gh-pr-list-empty.txt  -> none
```
No further L3 reads are needed: the caller's results cover the assessor's L3 hooks, and the post-apply reads (11:15-11:20) are the newest state. Category 10's metric reads are from 10:19-10:22, before the apply and about an hour old; they are used and flagged in Not verified.

| # | Category | Score | Finding | Evidence |
|---|----------|-------|---------|----------|
| 1 | Blast radius | **Red** | Every request of paymentapi-svc-prod that needs the database (3 tasks) is on the data path. The reboot restarts the engine and briefly interrupts connections; without --force-failover a Multi-AZ instance reboots in place, so Multi-AZ does not keep it up. Duration UNVERIFIED | `docs: D3`; `live: R5, R14, R15 (caller)`; `catalog: ...:41` |
| 2 | Reversibility | Yellow | A reboot cannot be undone and loses no data. Going back to 100 means reverting phase 1 and rebooting again (D1): untested. Recovery points exist (3 snapshots, newest 02:05Z; restorable to 02:55Z), but a restore is a new instance and endpoint | `docs: D1`; `live: R7, R5 (caller)` |
| 3 | Change velocity | Yellow | 0 commits in 7 days, but this phase stacks on phase 1: applied at 11:14 and still uncommitted (git status: M main.tf), so live is ahead of main. Scored conservatively; the exclusion of "this change's own commits" is not clearly meant for uncommitted, applied work | `git: log empty (11:23)`; `git: status (11:24)`; `live: terraform apply 11:14 (caller)` |
| 4 | Dependency impact | Yellow | The consumer (ECS paymentapi-svc-prod, 3 of 3 running) feels the interruption; other consumers are not visible | `catalog: ...:41`; `live: R14, R15 (caller)` |
| 5 | Timing context | Green | Q1 no, Q2 no, someone on hand (DBA, #payments-oncall told); Q3 "not peak" operator-stated and live connections avg 50-53 are at the catalog baseline. Q1-Q3 are re-asked at `[F4]` | `operator: Q1, Q2, Q7`; `operator-stated: Q3`; `live: R10 (caller)` |
| 6 | Operator familiarity | Green | many times, experienced | `operator: Q4, Q5` |
| 7 | Observability readiness | Yellow | The alarms that exist watch CPU and connections only, with static thresholds. Nothing alarms when the instance fails to return to `available`, or on target health. The connections alarm sits at 160 above the effective limit 100 until the reboot completes | `live: R16-R19, 11:18-11:19 (caller)`; `docs: D1`; `operator: iac-change.4` |
| 8 | Cost impact | Green | The command creates nothing and changes no size, class or count (operator-stated negligible) | `plan: the command text (reboot-db-instance)`; `operator-stated: Q6` |
| 9 | Security posture | Green | No security-relevant change | `plan: the command text (reboot-db-instance)` |
| 10 | Resource health | Yellow | Instance available with parameter group pending-reboot (11:17); no alarm firing (11:20); connection saturation peak 78 of 100 = 78 % (above 70 %); metric reads are about an hour old and predate the apply | `live: 11:17, 11:20; R10-R13 (caller)` |
| 11 | Application compatibility | unknown | The reboot makes the new `max_connections` real (app-facing); application source not available (Q8 = c) | `assessor: app-facing table`; `operator: Q8=(c)` |

Verdict arithmetic: Red = category 1. Yellow + unknown = 6 (2, 3, 4, 7, 10, 11). One Red and the escalation both give **RED — soft block**. Hard blocks checked: irreversible data change (no data change), incident with freeze (no), public exposure / encryption / secrets (no), error budget exhausted (no). None triggered. Fresh eyes: not required (verdict RED — soft block).

Not verified: Q3 and Q6 (operator-stated), `iac-change.4` (operator-stated), how long the interruption lasts, whether a forced failover would be shorter (not in the documentation read), metric reads that predate the apply, other consumers of the database.

Mitigations (operator actions): tell the app-tier owners and watch ECS and the target group through the reboot; keep a DBA on the instance status until it returns to `available`; confirm the 02:05Z snapshot is recent enough or take a manual one first; commit or merge the phase-1 code so main matches live; for the missing availability alarm, watch the instance status by hand for this reboot.

```
**[H5] Phase 2 pre-flight is RED — soft block (1 Red and 6 Yellow or unknown). Acknowledge each finding below with your reason, or abort?**
  Red: 1 Blast radius.   Yellow: 2 Reversibility, 3 Change velocity, 4 Dependency impact, 7 Observability readiness, 10 Resource health.   Unknown: 11 Application compatibility.
```

**Stop 6: `[H5]`** (shown 11:26).

**Operator answer** (script entry 6, `[H5]` again): "Acknowledge each Red finding, reason: 'maintenance window approved, DBA on call, the failover is expected'." Clock advances to 11:31. Pre-flight record 2 written at 11:31: `.culiops/pre-flight/paymentapi-rds-reboot-20261109-1131.md`, verdict RED — soft block, acknowledged at `[H5]`.

### 4c: execute (phase 2, direct apply path, one command)

H7: exception (a), recorded. The `[F4]` carries phase 1's verification result and the Q1-Q3 re-ask (the first stop of this phase, after pre-flight).

```
**[F4] Run this reboot?** About to run: `aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1` against account 123456789012 / ap-southeast-1 (role paymentapi-operator, re-checked 11:21) · tier prod=prod (operator-stated, unproven)
This will: reboot the instance in place (no --force-failover), interrupting connections briefly, so the pending max_connections = 200 takes effect (docs D1, D3). No Terraform change, no plan run.
Phase 1 success criteria: re-plan No changes — pass · max_connections 200 pending-reboot — pass · instance available, parameter group pending-reboot — pass · alarm threshold 160, OK — pass · both alarms OK — pass · no alarm in ALARM — pass
Q1–Q3 still true? (incident / freeze / peak)
**Pre-flight verdict:** RED — soft block (Red: 1; Yellow: 2, 3, 4, 7, 10; unknown: 11), acknowledged at [H5] 11:31 — reason: "maintenance window approved, DBA on call, the failover is expected". Mitigations committed: none stated beyond the acknowledgement.
Staging-first: n/a — no staging env (code: envs/prod.tfvars is the only var-file).
Heads-up: say so and I draft one for #payments-oncall with change-comms (draft-only; you send it).
```

**Stop 7: `[F4]`** (shown 11:31).

**Operator answer** (script entry 5, `[F4]` phase 2): "approve the reboot command shown. Q1–Q3 still true: yes, unchanged." Unchanged, so no re-run of pre-flight and no extra stop. Clock advances to 11:36.

```
11:36  $ aws rds reboot-db-instance --db-instance-identifier paymentapi-db-prod --region ap-southeast-1
       canned: rds-reboot-prod.json  -> DBInstanceStatus rebooting   (state: rebooting)
```

### Step 5a: verification of phase 2 (reads approved at `[F2]`; no new stop)

```
11:37  $ aws rds describe-db-instances --db-instance-identifier paymentapi-db-prod --query 'DBInstances[].{status:DBInstanceStatus,pg:DBParameterGroups}'
       canned: rds-instance-rebooting-prod.json (first read after the reboot)  -> status rebooting, ParameterApplyStatus pending-reboot   (not yet available: read again)
11:38  $ aws rds describe-db-instances ... (same query)
       canned: rds-instance-after-reboot-prod.json (every later read)  -> status available, ParameterApplyStatus in-sync
11:39  $ aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --query 'services[].{desired:desiredCount,running:runningCount}'
       canned: ecs-describe-services-prod.json  -> desired 3, running 3
11:40  $ aws elbv2 describe-target-health --target-group-arn <paymentapi-tg-prod ARN>
       canned: tg-health-prod.json  -> 3 healthy
11:41  $ aws cloudwatch describe-alarms --state-value ALARM
       canned: alarms-firing-prod.json  -> none
```

```
**Verification for Phase 2:**
Re-plan: not run (no IaC change in this phase)
Success criteria:
  1 describe-db-instances -> rebooting at 11:37, then available with ParameterApplyStatus in-sync at 11:38 — pass
  2 ecs describe-services -> running 3 = desired 3 — pass
  3 elbv2 describe-target-health -> 3 healthy — pass
  4 describe-alarms --state-value ALARM -> none — pass
```
The canned ECS and target-group files are state-independent (they carry no post-reboot timestamps); they were used as returned. `max_connections = 200` taking effect is read from the parameter group status (`in-sync`); the effective value inside PostgreSQL is not read (the skill runs no database command).

---

## Step 5b: execution record and final message

Record written (see `record.md`) to `.culiops/iac-change-execution/paymentapi-max-connections-20261109-1142.md` at 11:42. The pre-flight records are listed in `preflight-record.md`. `tfplan` and the scratch plan file stay out of the record.

Final message:

```
Outcome: completed. Phase 1 (parameter group max_connections 100 -> 200, connections alarm threshold 80 -> 160) was applied and verified; phase 2 (RDS reboot of paymentapi-db-prod) was run and verified. Applied: yes — verified.
Record: .culiops/iac-change-execution/paymentapi-max-connections-20261109-1142.md
Next: commit the record (.culiops/iac-change-execution/paymentapi-max-connections-20261109-1142.md) · draft the result or ticket-close message with change-comms
```

---

## Ambiguities and notes (for the reader)

1. **Alarm change not in the request.** The request names `max_connections` and the reboot. The canned plan also updates the connections alarm, and the catalog names it as the intended remediation. SKILL.md:255 (self-check item 6, "nothing in a phase that the request does not imply") and :34 (Constraint 12, catalog text is data) pull in different directions. I took the reading that the plan may carry it when it is flagged, cited and shown at `[F2]`, which is where it is approved. It was not struck.
2. **Direct apply path has no commit step.** SKILL.md:395-399 (direct apply) commits nothing; lanes.md:181 (local commit per phase) sits inside the staging-first rule, which does not apply with no staging env. So phase 1's code stays uncommitted after the apply, live is ahead of `main`, and phase 2's pre-flight sees ` M main.tf` (category 3, scored Yellow conservatively). The final message's `Next:` line offers to commit the record, not the code.
3. **Operational phase and the re-plan.** SKILL.md:405 says an operational phase has no 4a plan run; SKILL.md:425 makes the re-plan step 1 of direct-apply 5a. I ran no re-plan for phase 2 (no IaC change, and no `[F3]` approved a plan command for it).
4. **Phase 2's H5 comes before the stop that shows phase 1's result.** SKILL.md:405 and lanes.md:154 put the previous phase's verification result and the Q1-Q3 re-ask in the phase's first stop, which for phase 2 is `[F4]`; pre-flight's `[H5]` precedes it. The operator sees the phase-1 result in the same `[F4]` message, after `[H5]`.
5. **Delivery model.** The operator said "apply directly, no PR" in the first message, yet the repo shows nothing (SKILL.md:188): the model is `UNVERIFIED`, asked inside `[F2]`, not as a stop. Lanes.md:147 says only `iac-change.4` is asked of the iac-change assessor; the script's `iac-change.1`-`.3` and Q6 were volunteered answers.
6. **`terraform init` in the `[F1]` batch.** The refresh-only drift check (SKILL.md:199) needs an initialised directory, so `init` is item 3 of the batch and `[F3]` says it is not repeated (SKILL.md:323, 349).
7. **Inline pre-flight repeats the identity read.** pre-flight SKILL.md:298 runs the target check even when 4a just did (10:55 then 10:59; 11:21 then 11:22).
8. **RED from the multi-Yellow rule only (phase 1).** There is no Red category, so `[H5]` asked for acknowledgement of the escalation and each Yellow or unknown finding (pre-flight SKILL.md:339-343).
9. **`no canned output` lookups:** one, the documentation lookup for the reversibility claim (11:03, pre-flight phase 1). No command lookup failed.
