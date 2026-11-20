# Dry run transcript — dependency-regression, v0.20 skill, operator-script.md

Run setup
- Skill under test: `skills/iac-change-execution/SKILL.md` (branch `feat/iac-change-snapshot-and-l2`) with `lanes.md`, `snapshot.md`, `examples/aws.md`, and, for the inline run, `skills/pre-flight/SKILL.md`, `assessors/iac-change.md`, `examples/aws.md`.
- Fixture: `tests/fixtures/iac-change-execution/dependency-regression`. Operator script: `operator-script.md`. Out-dir: `expected-output-v020`.
- Dry-run clock starts 2026-11-16 10:00 +07:00. Rule: a command runs at the current clock, then the clock advances 1 minute; an operator answer arrives 5 minutes after the stop is shown. Git-grep stand-ins (a `grep -rn -F` over the fixture inputs) count as commands (1 minute); plain reads of IaC files do not.
- Canned lookup rule 1(b) is applied for every command that is not told apart by its own arguments: the environment the skill is working on at that moment. Where (b) decided it is noted.
- `CULIOPS_HOME` is not set in this run (nothing in the fixture sets it), so the output root is `.culiops/` at the repo root.
- No documentation tool has canned entries (`canned/INDEX.md` › Documentation lookups): every `docs:` lookup prints `no canned output`.
- Separate reviewer (fresh eyes): `not run — dry run` (protocol default; the runner instructions set nothing else).

User first message (operator script `First message`):

```text
Remove the 10.20.0.0/16 ingress rule from the orders-db security group: staging first, then prod. I apply with terraform by hand from my workstation, no PR.
```

---

## Step 1 — Research

Constraint 13 (output root) and Step 1 order: identity read first, before any other live command. Constraint 3 exempts it from opt-in. The repo defines two environments (`envs/staging.tfvars`, `envs/prod.tfvars`), each pinned to its own account in the var-file and in the provider. The skill says to prove each target's tier, so it reads the identity once per environment, with that environment's credentials (the script says both are available and switching is not a stop).

AMBIGUITY: Step 1 "run the identity read with the profile or kubeconfig the plan will use … prove each target's tier" — one read for the first environment, or one per environment — reading taken: one per environment, both before any other live command, so `[F1]` can show each target's tier as proven or not.

```
[10:00] $ aws sts get-caller-identity            (staging credentials)
        canned: identity-staging.json (rule 1(b): working on staging)
        -> Account 222222222222, Arn arn:aws:sts::222222222222:assumed-role/orders-operator/operator
[10:01] $ aws sts get-caller-identity            (prod credentials)
        canned: identity-prod.json (rule 1(b): this read is for prod)
        -> Account 333333333333, Arn arn:aws:sts::333333333333:assumed-role/orders-operator/operator
```

Pins in code: `code: envs/staging.tfvars:3` `aws_account_id = "222222222222"`, `code: envs/prod.tfvars:3` `aws_account_id = "333333333333"`, `code: providers.tf:14-16` `allowed_account_ids = [var.aws_account_id]`. Each live account equals its environment's pin, and the two pins are different accounts (no shared pin). Tiers: `staging=staging` and `prod=prod`, both proven.

Output root (Constraint 13) and workspace name:

```
[10:02] $ git remote get-url origin
        canned: git-remote.txt -> git@github.com:acme/orders-infra.git     (workspace acme/orders-infra)
[10:03] $ git branch --show-current
        canned: git-branch.txt -> main
[10:04] $ git status --short
        canned: git-status-clean.txt (rule: `git status --short` prints nothing) -> clean tree
```

Current branch is the default branch, so the code is read from the working tree (it is the default branch); no `git fetch` is needed in Step 1.

Operator profile (a local file read, not a live read; `snapshot.md` › Operator profile) and freeze source:

```
[10:05] $ cat ~/.culiops/operator.md            (CULIOPS_HOME unset)
        canned: operator-profile.md (rule 1, Operator profile)
        -> Q5 terraform = experienced (2026-10-26); Q4 acme/orders-infra/orders = many times (2026-10-26); no `incident check:` line
```

Code reads (IaC files, via Read; not command lookups): `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `envs/staging.tfvars`, `envs/prod.tfvars`. Naming pattern in use: `<thing>-${var.env}` (for example `main.tf:275` `name = "orders-db-sg-${var.env}"`). There is no `.culiops/service-discovery/orders.md` and no runtime-trace profile under the output root: catalog `none — proceeding without catalog`; the skill suggests running service-discovery first.

Duplicate check (all local, read-only). Identifiers from the request: `10.20.0.0/16` (CIDR), the rule `aws_vpc_security_group_ingress_rule.orders_db_from_vpc`, the SG `orders-db-sg-<env>`. No ticket was given, so there is no ticket key and no linked keys, and no `--grep` search.

```
[10:06] $ git grep -n -F '10.20.0.0/16'          (stand-in: grep -rn -F over the fixture input files)
        -> main.tf:290:  cidr_ipv4         = "10.20.0.0/16"
           variables.tf:17:  description = "VPC ID (10.20.0.0/16) where the service is deployed"
[10:07] $ git grep -n -F 'orders_db_from_vpc'
        -> main.tf:5 (header comment), main.tf:287 (the resource)
[10:08] $ git grep -n -iE 'freeze|change.window'   (freeze source search, Operator profile › Freeze source)
        -> no hits: no freeze or change-window calendar in the repo
[10:09] $ git log --all --oneline -S'10.20.0.0/16'
        canned: empty.txt (row `git log * -S*`) -> no hits
[10:10] $ git log --all --oneline -S'orders_db_from_vpc'
        canned: empty.txt (row `git log * -S*`) -> no hits
[10:11] $ git branch -a --list '*orders*'
        canned: empty.txt (row `git branch -a --list *`) -> no in-flight branch
[10:12] $ gh pr list --state open --search '10.20.0.0/16'
        canned: gh-pr-list-empty.txt -> no pull requests match your search in acme/orders-infra
```

Duplicate-check verdict: **not done**. The only forms of the CIDR in the repo are the rule itself (`code: main.tf:287-294`) and a variable description. No history hit, no branch, no PR. Not an `[H6]` stop.

Delivery model and environment selection:
- How changes reach the environment: the repo holds `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf` and `envs/` only: no CI workflow, no `atlantis.yaml`, no `.spacelift/`, no `cloud {}` or `backend` block (`code: providers.tf:1-10`). The README is not read (protocol). The operator said in the first message: "I apply with terraform by hand from my workstation, no PR". Delivery model: **applied by hand, direct apply** — `operator-stated (first message)`, consistent with `code: no CI / Atlantis / TFC / Spacelift config in the repo`. It is not `UNVERIFIED`, so no delivery-model question is asked anywhere.
- Environment selection: `-var-file=envs/<env>.tfvars`, default workspace (`code: envs/staging.tfvars`, `envs/prod.tfvars`; `code: providers.tf:12-13` "Each environment's var-file sets aws_account_id").
- Where each environment's state lives is not in the code (no backend block): recorded as an `UNVERIFIED` gap; the 4a plan output is the evidence of what each state holds.

Lane prediction (`lanes.md` › Lane rule). Not every target is a proven `dev` (staging and prod). L1: the request removes a resource from the code, so the plan will show a destroy — L1 fails (a delete is not a create or in-place update). Rule line 4: **full**. No escalation is recorded; E1–E3 run only when the lane would otherwise be light, and it is not. `Escalations: none`.

Snapshot set (`snapshot.md` › Snapshot set). The change is app-facing (a network rule on the database's SG is not on the not-app-facing list), so dependents are included. Changed resource: the rule `aws_vpc_security_group_ingress_rule.orders_db_from_vpc` — `n/a — no health signals of its own` (does not count against the cap), and so is its security group `aws_security_group.orders_db`. Members that get reads, one hop out, per environment:

| # | Member | Why it is in the set | Source |
|---|--------|----------------------|--------|
| 1 | `aws_db_instance.orders` (`orders-db-<env>`) | the instance the SG protects: attached to the SG | `code: main.tf:262` |
| 2 | `aws_ecs_service.orders_api` (`orders-api-<env>`) | dials the database through `DB_HOST`; its subnets are inside the rule's CIDR | `code: main.tf:42`, `code: envs/<env>.tfvars:6-7` |
| 3 | `aws_ecs_service.orders_worker` (`orders-worker-<env>`), with its job metrics and alarm | same: `DB_HOST`, subnets inside the CIDR | `code: main.tf:70`, `code: envs/<env>.tfvars:10-11`, `code: main.tf:317,329,341` |
| 4 | `aws_lb.orders` (`orders-alb-<env>`) and its target group | the front door of member 2: request and error series come from it | `code: main.tf:145,158` |

4 members with reads, under the cap of 10; none "not snapshotted". Neither the api's nor the worker's security group is referenced by any rule on the DB SG (`code: main.tf:296-303` references only `var.admin_security_group_id`), which is why the CIDR rule is the path in question.
`Snapshot coverage: code (main.tf, var-files) + live reads (ENIs on the DB security group, ECS task-definition variable names); not covered: the batch jobs and any other VPC host that connects through the rule (the comment at main.tf:285-286 names them; callers outside this repo are not visible), no catalog, no runtime-trace profile.`

Evidence table, live verification batch and the batch's additions (S0, assessor L3 reads, automation-lag reads, app-source search) are proposed at `[F1]`. App-facing change predicted, so Q8 applies and the sibling-checkout search is a read in the batch (`snapshot.md` › L2 from evidence, Q8): the target repo holds no app source (`code:` files listed above), so the search goes in the batch.

AMBIGUITY: automation-lag evidence (`iac-change.4`) — the assessor lists CI history, the S3 state object, `helm history`, ECS `createdAt`. This repo has no CI workflow file (the `gh run list` template needs `--workflow {workflow-file}`) and no backend block (the `head-object` template needs a bucket and key), so neither read can be written without inventing a value — reading taken: propose only the ECS deployment `createdAt` read (it is the same `describe-services` call as the state read). No `head-object` and no `gh run list` is proposed.

AMBIGUITY: sibling search (`snapshot.md`: "directory name or `origin` remote matches"; `examples/aws.md`: candidates "whose directory name matches") — reading taken: after `ls ..`, read the origin of every sibling that is not the repo itself, because `snapshot.md` also matches on origin.

Query file for S0 and S1 (`examples/aws.md` › Metrics): `.culiops/iac-change-execution/snapshot-queries-staging.json` (and `-prod.json`), written under the output root. The runner makes no write; the content is shown at the first read that uses it (10:32). Whatever the file, answers come from the canned `Label`s (protocol).

AMBIGUITY: `terraform init` in the Step 1 batch — the Step 1 text names `terraform plan -refresh-only` as the drift check and says init belongs to the 4a plan command ("if needed"); the drift check needs an initialised directory — reading taken: list `terraform init` in the `[F1]` batch (shown with its note that it downloads providers and may update `.terraform.lock.hcl`), and do not repeat it at 4a.

### `[F1]` shown to the operator (10:13)

```text
**Step 1 so far** (identity reads need no opt-in and ran first)
Target staging: account 222222222222 / ap-southeast-1, assumed-role/orders-operator (live: aws sts get-caller-identity, staging credentials, 10:00) — pin: code: envs/staging.tfvars:3 + providers.tf:14-16 → tier staging=staging (proven)
Target prod: account 333333333333 / ap-southeast-1, assumed-role/orders-operator (live: aws sts get-caller-identity, prod credentials, 10:01) — pin: code: envs/prod.tfvars:3 + providers.tf:14-16 → tier prod=prod (proven)
Lane (predicted): full — not every target is a proven dev, and the request removes a resource, so the plan will show a destroy (L1 fails). Escalations: none.
Output root: .culiops/ at the repo root (CULIOPS_HOME unset).
Delivery model: applied by hand from your workstation, direct apply (operator-stated, first message; code: no CI / Atlantis / TFC / Spacelift config in the repo). Env selection: -var-file=envs/<env>.tfvars, default workspace (code: envs/*.tfvars, providers.tf:12-13).
Catalog: none — proceeding without catalog (consider running service-discovery first). Duplicate check: not done (code: main.tf:287-294; git log -S, branch and PR searches empty).
Snapshot set per environment: orders-db, orders-api, orders-worker (+ alarm orders-worker-errors), orders-alb — 4 members, 0 over the cap. The rule and its SG: n/a — no health signals of their own.
Snapshot coverage: code + live reads; not covered: batch jobs and other VPC hosts that use the rule, no catalog, no runtime-trace profile.

**[F1] Run these reads?** Read-only unless marked. Each environment's reads use that environment's credentials. S0 and S1 run on this approval; so do both environments' reads, because drift is acknowledged at [F2].

Once:
 1. terraform init   (downloads providers, may update .terraform.lock.hcl; not a cloud read)
 2. ls ..                                                    (app-source sibling search)
 3. git -C ../<each sibling that is not this repo> remote get-url origin    (read-only; never fetch, pull, check out or stash there)

For each of staging, then prod (E = staging|prod):
 4. aws ecs describe-services --cluster orders-cluster-E --services orders-api-E orders-worker-E --region ap-southeast-1
      (state, running vs desired, deployments createdAt = automation-lag read; S0/S1/S2 state)
 5. aws ecs describe-task-definition --task-definition orders-api-E --query 'taskDefinition.containerDefinitions[].{image:image,env:environment[].name}'   (names only; the deployed ref)
 6. the same for orders-worker-E
 7. aws rds describe-db-instances --db-instance-identifier orders-db-E --query 'DBInstances[].{status:DBInstanceStatus,class:DBInstanceClass,multiAz:MultiAZ,sgs:VpcSecurityGroups,pending:PendingModifiedValues}'
 8. aws ec2 describe-security-groups --group-ids <the DB SG id from 7>
 9. aws ec2 describe-network-interfaces --filters Name=group-id,Values=<the DB SG id> --query 'NetworkInterfaces[].{id:NetworkInterfaceId,desc:Description,instance:Attachment.InstanceId}'   (what is attached to the SG)
10. aws elbv2 describe-target-groups --names orders-api-tg-E
11. aws elbv2 describe-load-balancers --load-balancer-arns <ARN from 10>
12. aws elbv2 describe-target-health --target-group-arn <ARN from 10>      (S0/S1/S2 state)
13. aws cloudwatch describe-alarms --alarm-name-prefix orders --region ap-southeast-1     (alarms exist and are enabled)
14. aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,ns:Namespace,metric:MetricName,dims:Dimensions,math:Metrics[].MetricStat.Metric.Dimensions},composite:CompositeAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,rule:AlarmRule}}'     (S0)
15. aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-E.json --start-time {T-7d-1h} --end-time {now} --scan-by TimestampAscending --query 'MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]}'     (S0: the hour ending now and the same hour last week; the file holds metric identifiers only)
16. terraform plan -refresh-only -var-file=envs/E.tfvars      (drift check, never applied)

The same reads are pre-flight's L3 reads (health, blast radius, dependents, observability, timing, velocity), so inline pre-flight should need no batch of its own. No CI workflow and no state backend exist in the repo, so no other automation-lag read applies. You can approve all, pick a subset, or decline (declined rows become code-only — not live-verified).
```

Also in this message (`[F1]` form, `lanes.md` › Stops per lane): no operator line and no L2 question here; they come with `[F2]`, after S0 has run.

Operator answer (script entry 1, `[F1]`, answered at 10:18): approve the read batch, every command shown, for both environments, the target check included. Tiers: staging and prod as the var-files pin them. (No L2 item in this entry.)

`stops.md` line 1 is written for this stop.

### Batch run after `[F1]` (10:18 on)

```
[10:18] $ terraform init
        canned: terraform-init.txt -> "Terraform has been successfully initialized!" (reuses hashicorp/aws v5.74.0 from the lock file; no lock-file change)
[10:19] $ ls ..
        canned: siblings-ls.txt -> dotfiles, orders-infra
[10:20] $ git -C ../dotfiles remote get-url origin
        canned: sibling-origin-dotfiles.txt -> git@github.com:acme/dotfiles.git      (not the app: no name or origin match for "orders" other than this repo)
```

App source search result: **not found** (no directory beside the repo matches `orders` by name or origin; `orders-infra` is this repo). Q8 is asked inside `[F2]`.

Staging (E = staging; rule 1(a): the commands carry `-staging` names and the staging var-file):

```
[10:21] $ aws ecs describe-services --cluster orders-cluster-staging --services orders-api-staging orders-worker-staging --region ap-southeast-1
        canned: ecs-describe-services-staging.json
        -> api 2/2 running, worker 2/2, both ACTIVE, deployments COMPLETED; createdAt 2026-11-12T08:20:41Z / 08:21:02Z (= 15:20 / 15:21 +07:00); api SG sg-0e6b5c4d3e2f10987, worker SG sg-0e7c6d5e4f3a21098; subnets 10.20.x (staging.tfvars)
[10:22] $ aws ecs describe-task-definition --task-definition orders-api-staging --query '...{image,env names}'
        canned: ecs-describe-task-definition-api-staging.json -> image .../orders-api:v1.9.0-rc1; env names APP_ENV, DB_HOST, PORT
[10:23] $ aws ecs describe-task-definition --task-definition orders-worker-staging --query '...'
        canned: ecs-describe-task-definition-worker-staging.json -> image .../orders-worker:v1.9.0-rc1; env names APP_ENV, DB_HOST
[10:24] $ aws rds describe-db-instances --db-instance-identifier orders-db-staging --query '...'
        canned: rds-instance-staging.json -> available, db.t4g.medium, MultiAZ false, VpcSecurityGroups sg-0e5a4b3c2d1f09876, no pending change
[10:25] $ aws ec2 describe-security-groups --group-ids sg-0e5a4b3c2d1f09876
        canned: sg-describe-staging.json (state: before the staging apply)
        -> two ingress rules on tcp 5432: 10.20.0.0/16 "PostgreSQL from the VPC (legacy)", and group sg-0e9f8a7b6c5d4e3f2 "PostgreSQL from the admin host"
[10:26] $ aws ec2 describe-network-interfaces --filters Name=group-id,Values=sg-0e5a4b3c2d1f09876 --query '...'
        canned: enis-orders-db-sg-staging.json -> 1 interface, eni-0e7f1a2b3c4d5e6f7 "RDSNetworkInterface". The api and worker tasks are not attached to this group.
[10:27] $ aws elbv2 describe-target-groups --names orders-api-tg-staging
        canned: tg-describe-staging.json -> targetgroup/orders-api-tg-staging/6d0ecf831eec9f09, LB app/orders-alb-staging/50dc6c495c0c9188
[10:28] $ aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:loadbalancer/app/orders-alb-staging/50dc6c495c0c9188
        canned: lb-describe-staging.json -> orders-alb-staging, internal, active
[10:29] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/orders-api-tg-staging/6d0ecf831eec9f09
        canned: tg-health-staging.json -> 2 targets, both healthy
[10:30] $ aws cloudwatch describe-alarms --alarm-name-prefix orders --region ap-southeast-1
        canned: alarms-prefix-staging.json (state: before the staging apply; rule 1(b): working on staging)
        -> orders-worker-errors-staging, ActionsEnabled true, OK, actions: SNS orders-alerts-staging
[10:31] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '...'
        canned: alarms-firing-staging.json (S0/S1 of staging) -> nothing firing
[10:32] $ aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-09T09:32:00+07:00 --end-time 2026-11-16T10:32:00+07:00 --scan-by TimestampAscending --query '...'
        canned: metric-data-s0-staging.json (S0/S1 of staging); results matched by Label, given the skill's own Ids
[10:33] $ terraform plan -refresh-only -var-file=envs/staging.tfvars
        canned: plan-refresh-only-staging.txt -> "No changes. Your infrastructure still matches the configuration."
```

Query file written for the call at 10:32 (staging; the prod file has `-prod` names and its own ARN values). Period 3600, one file for the whole set; every Id starts with a lowercase letter and carries its member; counts are `FILL(…, 0)` except the traffic series (`req_*`), which are read unfilled; gauges are never filled.

```json
[
 {"Id":"m_5xx_alb","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"HTTPCode_Target_5XX_Count","Dimensions":[{"Name":"LoadBalancer","Value":"app/orders-alb-staging/50dc6c495c0c9188"}]},"Period":3600,"Stat":"Sum"},"ReturnData":false},
 {"Id":"err_alb","Expression":"FILL(m_5xx_alb, 0)","Label":"orders-alb-staging HTTPCode_Target_5XX_Count"},
 {"Id":"m_elb5xx_alb","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"HTTPCode_ELB_5XX_Count","Dimensions":[{"Name":"LoadBalancer","Value":"app/orders-alb-staging/50dc6c495c0c9188"}]},"Period":3600,"Stat":"Sum"},"ReturnData":false},
 {"Id":"errelb_alb","Expression":"FILL(m_elb5xx_alb, 0)","Label":"orders-alb-staging HTTPCode_ELB_5XX_Count"},
 {"Id":"req_alb","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"RequestCount","Dimensions":[{"Name":"LoadBalancer","Value":"app/orders-alb-staging/50dc6c495c0c9188"}]},"Period":3600,"Stat":"Sum"},"Label":"orders-alb-staging RequestCount"},
 {"Id":"p95_alb","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"TargetResponseTime","Dimensions":[{"Name":"LoadBalancer","Value":"app/orders-alb-staging/50dc6c495c0c9188"}]},"Period":3600,"Stat":"p95"},"Label":"orders-alb-staging TargetResponseTime p95"},
 {"Id":"hh_alb","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"HealthyHostCount","Dimensions":[{"Name":"LoadBalancer","Value":"app/orders-alb-staging/50dc6c495c0c9188"},{"Name":"TargetGroup","Value":"targetgroup/orders-api-tg-staging/6d0ecf831eec9f09"}]},"Period":3600,"Stat":"Minimum"},"Label":"orders-alb-staging HealthyHostCount"},
 {"Id":"uh_alb","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"UnHealthyHostCount","Dimensions":[{"Name":"LoadBalancer","Value":"app/orders-alb-staging/50dc6c495c0c9188"},{"Name":"TargetGroup","Value":"targetgroup/orders-api-tg-staging/6d0ecf831eec9f09"}]},"Period":3600,"Stat":"Minimum"},"Label":"orders-alb-staging UnHealthyHostCount"},
 {"Id":"cpu_api","MetricStat":{"Metric":{"Namespace":"AWS/ECS","MetricName":"CPUUtilization","Dimensions":[{"Name":"ClusterName","Value":"orders-cluster-staging"},{"Name":"ServiceName","Value":"orders-api-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-api-staging CPUUtilization"},
 {"Id":"mem_api","MetricStat":{"Metric":{"Namespace":"AWS/ECS","MetricName":"MemoryUtilization","Dimensions":[{"Name":"ClusterName","Value":"orders-cluster-staging"},{"Name":"ServiceName","Value":"orders-api-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-api-staging MemoryUtilization"},
 {"Id":"cpu_worker","MetricStat":{"Metric":{"Namespace":"AWS/ECS","MetricName":"CPUUtilization","Dimensions":[{"Name":"ClusterName","Value":"orders-cluster-staging"},{"Name":"ServiceName","Value":"orders-worker-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-worker-staging CPUUtilization"},
 {"Id":"mem_worker","MetricStat":{"Metric":{"Namespace":"AWS/ECS","MetricName":"MemoryUtilization","Dimensions":[{"Name":"ClusterName","Value":"orders-cluster-staging"},{"Name":"ServiceName","Value":"orders-worker-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-worker-staging MemoryUtilization"},
 {"Id":"req_worker","MetricStat":{"Metric":{"Namespace":"Orders/Worker","MetricName":"JobsProcessed"},"Period":3600,"Stat":"Sum"},"Label":"orders-worker-staging JobsProcessed"},
 {"Id":"m_err_worker","MetricStat":{"Metric":{"Namespace":"Orders/Worker","MetricName":"JobErrors"},"Period":3600,"Stat":"Sum"},"ReturnData":false},
 {"Id":"err_worker","Expression":"FILL(m_err_worker, 0)","Label":"orders-worker-staging JobErrors"},
 {"Id":"cpu_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"CPUUtilization","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-db-staging CPUUtilization"},
 {"Id":"conn_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"DatabaseConnections","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-db-staging DatabaseConnections"},
 {"Id":"connmax_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"DatabaseConnections","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Maximum"},"Label":"orders-db-staging DatabaseConnections Maximum"},
 {"Id":"rlat_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"ReadLatency","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-db-staging ReadLatency"},
 {"Id":"wlat_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"WriteLatency","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Average"},"Label":"orders-db-staging WriteLatency"},
 {"Id":"fmem_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"FreeableMemory","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Minimum"},"Label":"orders-db-staging FreeableMemory"},
 {"Id":"fstor_db","MetricStat":{"Metric":{"Namespace":"AWS/RDS","MetricName":"FreeStorageSpace","Dimensions":[{"Name":"DBInstanceIdentifier","Value":"orders-db-staging"}]},"Period":3600,"Stat":"Minimum"},"Label":"orders-db-staging FreeStorageSpace"}
]
```

Runner notes on the metric answer (protocol rule 1 and "`get-metric-data` files"):
- The canned S0 file holds 12 five-minute values per label for the hour ending now, plus the same hour a week earlier under `(1w ago)`. The skill's file asks `Period` 3600, which makes one value per hour. The runner derived the hourly value from the 12 canned values: Sum for counts, mean for `Average` and `p95` (an hourly percentile is not derivable from 5-minute percentiles; the mean of the twelve is the closest and is labelled so), min for `Minimum`, max of the maxima for `Maximum`. `v_now` is the hour ending 10:32, `v_week` the hour ending 7 days earlier. Series with no `(1w ago)` label in the file (ECS CPU and memory) have `v_week` = null.
- The file has no result for `ReadLatency`, `WriteLatency`, `FreeableMemory` and `FreeStorageSpace` (the per-type list in `examples/aws.md` asks for them for RDS). They return no datapoints: `no data`. Nothing is invented.

S0 staging, read 10:21–10:32 (hour ending 10:32):

| Member | Signal | Hour ending 10:32 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 22.05% | [M] | 10:32 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 37 | [M] | 10:32 |
| orders-db-staging | DatabaseConnections (max) | 46 | 45 | [M] | 10:32 |
| orders-db-staging | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 10:32 |
| orders-db-staging | status (point-in-time) | available | n/a | [R] | 10:24 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | not read (no 1w series) | [M] | 10:32 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | not read (no 1w series) | [M] | 10:32 |
| orders-api-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 10:21 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | not read (no 1w series) | [M] | 10:32 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | not read (no 1w series) | [M] | 10:32 |
| orders-worker-staging | JobsProcessed (traffic, sum) | 7,201 | 7,129 | [M] | 10:32 |
| orders-worker-staging | JobErrors (sum) | 36 (0.500% of jobs) | 36 (0.505%) | [M] | 10:32 |
| orders-worker-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 10:21 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (0 firing on the set) | n/a | [A] | 10:31 |
| orders-alb-staging | RequestCount (sum) | 24,130 | 23,890 | [M] | 10:32 |
| orders-alb-staging | HTTPCode_Target_5XX_Count (sum) | 48 (0.199% of requests) | 47 (0.197%) | [M] | 10:32 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 10:32 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.184 s | [M] | 10:32 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | [M] | 10:32 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | [M] | 10:32 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | n/a | [T] | 10:29 |

Prod (E = prod; rule 1(a): the commands carry `-prod` names and the prod var-file):

```
[10:34] $ aws ecs describe-services --cluster orders-cluster-prod --services orders-api-prod orders-worker-prod --region ap-southeast-1
        canned: ecs-describe-services-prod.json -> api 4/4, worker 4/4, COMPLETED; createdAt 2026-11-05T07:10:12Z / 07:10:40Z (= 14:10 / 14:10 +07:00)
[10:35] $ aws ecs describe-task-definition --task-definition orders-api-prod --query '...'
        canned: ecs-describe-task-definition-api-prod.json -> env names APP_ENV, DB_HOST, PORT; image tag v1.8.3
[10:36] $ aws ecs describe-task-definition --task-definition orders-worker-prod --query '...'
        canned: ecs-describe-task-definition-worker-prod.json -> env names APP_ENV, DB_HOST; image tag v1.8.3
[10:37] $ aws rds describe-db-instances --db-instance-identifier orders-db-prod --query '...'
        canned: rds-instance-prod.json -> available, db.r6g.large, MultiAZ true, VpcSecurityGroups sg-0c5a4b3c2d1f09876
[10:38] $ aws ec2 describe-security-groups --group-ids sg-0c5a4b3c2d1f09876
        canned: sg-describe-prod.json (before the prod apply) -> the same two ingress rules (10.20.0.0/16 legacy; admin SG sg-0c9f8a7b6c5d4e3f2)
[10:39] $ aws ec2 describe-network-interfaces --filters Name=group-id,Values=sg-0c5a4b3c2d1f09876 --query '...'
        canned: enis-orders-db-sg-prod.json -> 1 interface (RDSNetworkInterface); api and worker not attached
[10:40] $ aws elbv2 describe-target-groups --names orders-api-tg-prod
        canned: tg-describe-prod.json -> targetgroup/orders-api-tg-prod/9c1ed4a2b7f06e83, LB app/orders-alb-prod/7ab3d14c88e0f2a5
[10:41] $ aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:ap-southeast-1:333333333333:loadbalancer/app/orders-alb-prod/7ab3d14c88e0f2a5
        canned: lb-describe-prod.json -> orders-alb-prod, internal, active
[10:42] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:333333333333:targetgroup/orders-api-tg-prod/9c1ed4a2b7f06e83
        canned: tg-health-prod.json -> 4 targets healthy
[10:43] $ aws cloudwatch describe-alarms --alarm-name-prefix orders --region ap-southeast-1
        canned: alarms-prefix-prod.json (rule 1(b): working on prod) -> orders-worker-errors-prod, enabled, OK
[10:44] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '...'
        canned: alarms-firing-prod.json (S0/S1 of prod) -> nothing firing
[10:45] $ aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-prod.json --start-time 2026-11-09T09:45:00+07:00 --end-time 2026-11-16T10:45:00+07:00 --scan-by TimestampAscending --query '...'
        canned: metric-data-s0-prod.json (S0/S1 of prod; same derivation as for staging)
[10:46] $ terraform plan -refresh-only -var-file=envs/prod.tfvars
        canned: plan-refresh-only-prod.txt -> "No changes."
```

S0 prod, read 10:34–10:45 (hour ending 10:45; the `--start-time` / `--end-time` above follow `{T-7d-1h}` / `{now}` for the 10:45 read):

| Member | Signal | Hour ending 10:45 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-prod | CPUUtilization (avg) | 24.35% | 24.85% | [M] | 10:45 |
| orders-db-prod | DatabaseConnections (avg) | 85.83 | 83.83 | [M] | 10:45 |
| orders-db-prod | DatabaseConnections (max) | 102 | 100 | [M] | 10:45 |
| orders-db-prod | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 10:45 |
| orders-db-prod | status (point-in-time) | available | n/a | [R] | 10:37 |
| orders-api-prod | CPUUtilization (avg) | 41.35% | not read (no 1w series) | [M] | 10:45 |
| orders-api-prod | MemoryUtilization (avg) | 55.18% | not read (no 1w series) | [M] | 10:45 |
| orders-api-prod | running vs desired (point-in-time) | 4/4, deployment COMPLETED | n/a | [E] | 10:34 |
| orders-worker-prod | CPUUtilization (avg) | 29.35% | not read (no 1w series) | [M] | 10:45 |
| orders-worker-prod | MemoryUtilization (avg) | 47.24% | not read (no 1w series) | [M] | 10:45 |
| orders-worker-prod | JobsProcessed (traffic, sum) | 36,000 | 35,640 | [M] | 10:45 |
| orders-worker-prod | JobErrors (sum) | 180 (0.500% of jobs) | 180 (0.505%) | [M] | 10:45 |
| orders-worker-prod | running vs desired (point-in-time) | 4/4, deployment COMPLETED | n/a | [E] | 10:34 |
| orders-worker-prod | alarm orders-worker-errors-prod | OK (0 firing on the set) | n/a | [A] | 10:44 |
| orders-alb-prod | RequestCount (sum) | 108,130 | 107,050 | [M] | 10:45 |
| orders-alb-prod | HTTPCode_Target_5XX_Count (sum) | 217 (0.201% of requests) | 215 (0.201%) | [M] | 10:45 |
| orders-alb-prod | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 10:45 |
| orders-alb-prod | TargetResponseTime (p95) | 0.183 s | 0.187 s | [M] | 10:45 |
| orders-alb-prod | HealthyHostCount (min) | 4 | 4 | [M] | 10:45 |
| orders-alb-prod | UnHealthyHostCount (min) | 0 | 0 | [M] | 10:45 |
| orders-alb-prod | target health (point-in-time) | 4/4 healthy | n/a | [T] | 10:42 |

Table legend, used by every snapshot table in this run (the full command is shown once at the stop or step that runs it): `[M]` = `aws cloudwatch get-metric-data … file://.culiops/iac-change-execution/snapshot-queries-<env>.json …`; `[R]` = `aws rds describe-db-instances --db-instance-identifier orders-db-<env> --query 'DBInstances[].DBInstanceStatus'`; `[E]` = `aws ecs describe-services --cluster orders-cluster-<env> --services orders-api-<env> orders-worker-<env>`; `[A]` = `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm …`; `[T]` = `aws elbv2 describe-target-health --target-group-arn <tg-arn>`. Values for counts are the hourly sums the runner derived; rates are shown with their numerator and denominator.

AMBIGUITY: `snapshot.md` › Record asks for S0, S1 and S2 tables with "member, signal, before, after, verdict, command, time". An S0 or S1 read has no before and after — reading taken: S0 and S1 tables show the hour ending at the read and the same hour a week earlier in the `before`/`after` places, with no verdict; the S2 table has the real before (S1) and after.

Evidence table (Constraint 9). Time in parentheses is the read's time; staging first, prod's row in the same cell when it differs only by name.

| Fact | Code evidence | Live evidence | Match? |
|------|---------------|---------------|--------|
| The rule exists and admits `10.20.0.0/16` on tcp 5432 | `code: main.tf:287-294` | `live: aws ec2 describe-security-groups --group-ids sg-0e5a4b3c2d1f09876` (10:25): ingress 5432 from `10.20.0.0/16`; prod sg-0c5a4b3c2d1f09876 (10:38): same | ✅ |
| The only other ingress on the DB SG is the admin host's SG | `code: main.tf:296-303`, `code: envs/staging.tfvars:13` | same read: `UserIdGroupPairs` sg-0e9f8a7b6c5d4e3f2 (prod sg-0c9f8a7b6c5d4e3f2) | ✅ |
| The DB instance is attached to that SG | `code: main.tf:262` | `live: aws rds describe-db-instances` (10:24): `VpcSecurityGroups` sg-0e5a4b3c2d1f09876 (prod 10:37) | ✅ |
| Nothing else is attached to the SG | `code: main.tf:262,288,297` (only the DB and the two rules reference `aws_security_group.orders_db`) | `live: aws ec2 describe-network-interfaces` (10:26): 1 interface, `RDSNetworkInterface`; api and worker not attached (prod 10:39: same) | ✅ |
| The api and worker dial the DB through `DB_HOST` | `code: main.tf:42,70` | `live: aws ecs describe-task-definition` (10:22, 10:23): env names include `DB_HOST` (prod 10:35, 10:36) | ✅ |
| The api and worker run inside `10.20.0.0/16` | `code: envs/staging.tfvars:6-11` (`10.20.1.0/24`, `10.20.2.0/24`, `10.20.8.0/24`, `10.20.9.0/24`), `code: variables.tf:17` | `live: aws ecs describe-services` (10:21): task subnets `subnet-0e1a…`, `subnet-0e2b…`, `subnet-0e3c…`, `subnet-0e4d…`, the var-file's ids | ✅ |
| Neither the api's nor the worker's SG is a source on the DB SG | `code: main.tf:200-243` (their SGs), `code: main.tf:296-303` (only the admin SG is referenced) | same SG read (10:25): no api / worker group in `UserIdGroupPairs`; the task SGs are sg-0e6b5c4d3e2f10987 and sg-0e7c6d5e4f3a21098 (10:21) | ✅ — so the CIDR rule is how they are admitted (inferred) |
| Clients are connected through the rules today | n/a | `live: get-metric-data` (10:32): `DatabaseConnections` avg 38, max 46 (prod 85.8, max 102) | inferred: the connection sources are not visible |
| Batch jobs and other hosts rely on the rule | `code: main.tf:285-286` (a comment: data, not evidence, Constraint 12) | none readable | `UNVERIFIED` — callers outside this repo are not covered |
| Alarm `orders-worker-errors-staging` exists, enabled | `code: main.tf:341` | `live: aws cloudwatch describe-alarms --alarm-name-prefix orders` (10:30): enabled, `OK` | ✅ |
| No drift | `code: main.tf` | `live: terraform plan -refresh-only` (10:33 staging, 10:46 prod): No changes | ✅ |
| Where each environment's state lives | `code: providers.tf:1-10` has no backend block | not read | `UNVERIFIED` — the 4a plan output shows what each state holds |
| What removing the rule does to existing and new connections | n/a | n/a | `UNVERIFIED` — `docs:` lookup is made in Step 2 (no canned output) |

Drift rows: 0. Unverified rows: 3 (callers outside the repo, state location, behaviour of the rule removal). Code-only rows: 0.

Step 1 gaps remaining: callers outside this repo (`not covered`); the state location; the documented behaviour of removing the rule.

AMBIGUITY: the `Evidence table` "Match?" for the api / worker dependency on the CIDR rule rests on rule semantics (a connection needs some allowing rule) which is documentation, not a repo or live fact — reading taken: mark the row ✅ for the code and live facts and label the conclusion `inferred`, and look the behaviour up as a `docs:` claim in Step 2.

---

## Step 2 — Plan

Scope: single phase (one atomic change: one resource removed from the code), delivered to two environments in order, staging then prod (H7). Execution path: the operator asked for a direct apply (first message), so the plan states it, with the elevated pre-flight risk it carries (anti-pattern A4, local workstation apply).

Documentation lookups for the claims that drive a decision (Constraint 9, source order: what the installed tool reports comes first; `terraform plan` has not run yet and does not describe what a removed rule does to traffic; documentation next; recall last and never decisive). Two claims drive the plan: what removing the rule does to new and existing connections (the Disruption field, and what S2 should expect), and whether re-adding it restores the previous state (the rollback class).

```
[10:47] docs lookup: the AWS documentation for VPC security group rules — what happens to new and to established connections when an inbound rule is removed
        canned: no canned output (canned/INDEX.md › Documentation lookups)   -> read failed
[10:48] docs lookup: the AWS documentation for security group rules — is a removed rule restored by creating the same rule again
        canned: no canned output -> read failed
```

Both claims are therefore `UNVERIFIED` and are written as such. Recall may say where to look but never decides a disruption or a rollback class, and an `UNVERIFIED` disruption may not be shown as `none`.

```
[10:49] $ git rev-parse --short origin/main
        canned: git-rev-parse.txt (`--short`: first 7 characters) -> a1b2c3d
```

Plan self-check (8 items), before the operator sees it:
1. Every phase item cites evidence. The destroy rests on `code: main.tf:287-294` and `live: describe-security-groups` (10:25, 10:38), not on an `UNVERIFIED` row; the disruption and the rollback class are `UNVERIFIED` and are shown as such — pass, with those two named.
2. Every delete lists its bundle: the rule has no companions (no EIP, listener, DNS record or volume); a rule delete leaves nothing billing or orphaned (`code: main.tf:287-294`, a single resource) — pass.
3. Rollback path and success criteria written as commands with expected output — pass.
4. Drift rows acknowledged: there are none (`terraform plan -refresh-only` clean in both environments) — pass.
5. Execution path fits the delivery model: applied by hand, direct apply requested — pass.
6. Every file and resource the request implies is in the phase (`main.tf`, one resource, both environments via the var-files), nothing else is — pass.
7. Lane basis cited: full, because the plan will show a destroy (L1 fails) and the targets are staging and prod, not proven dev (`lanes.md` › Lane rule) — pass.
8. Staging precedes prod: staging apply first, then prod, each with its own `[F4]`; the observation window is named — pass.
Result: 8/8 pass, with the two `UNVERIFIED` claims named under item 1.

Success criteria (commands with expected output; approving the plan approves these reads and S2):
1. `aws ec2 describe-security-groups --group-ids <DB SG id> --query 'SecurityGroups[].IpPermissions[].{ranges:IpRanges[].CidrIp,groups:UserIdGroupPairs[].GroupId}'` → no `10.20.0.0/16`; only the admin host's group remains.
2. `terraform plan -var-file=envs/<env>.tfvars` (the re-plan) → `No changes`.
3. `aws rds describe-db-instances --db-instance-identifier orders-db-<env> --query 'DBInstances[].DBInstanceStatus'` → `available`.
4. `aws ecs describe-services --cluster orders-cluster-<env> --services orders-api-<env> orders-worker-<env> --query 'services[].{name:serviceName,desired:desiredCount,running:runningCount}'` → running = desired for both.
5. S2 on the snapshot set, read when two 5-minute periods have elapsed after the apply (`snapshot.md` › When snapshots run). Alarm and metric health belong to S2, not to the success criteria, so a signal is judged once.

AMBIGUITY: `aws ecs wait services-stable` — `snapshot.md` says S2 starts once the rollout is complete, "using the waits"; this change touches no ECS resource and redeploys nothing, so there is no rollout to wait for — reading taken: the wait is not run (it has no canned row either).

AMBIGUITY: the Disruption field's closed list is `none / restart / failover / replace / brief unavailability`; the expected effect here (the api and worker losing the database path until the rule is put back) is not on it — reading taken: write `UNVERIFIED` and describe the expected effect from code and live evidence, instead of picking `brief unavailability` or `none`.

Staging-first (H7): Step 1 mapped `staging` and the change targets prod, so staging goes first. Delivery per environment: direct apply from the workstation, staging's `[F4]` first, prod's after staging verifies (or its `[H10]` is overridden). Parity check at prod's 4a. Observation window (full lane: proposed with its reason): 30 minutes after staging's success criteria pass; reason (guess): the batch jobs the comment at `main.tf:285-286` mentions are not visible, and a job that runs less often than S2's ten minutes would show up later. The run waits for it; at its end S2 is read again for staging.

Branch (`git branch --show-current` read at 10:03: `main`; `git status --short` clean at 10:04): not this change's branch, so propose `git fetch origin main`, then `git switch -c iac-change/orders-remove-db-vpc-ingress-rule origin/main` (no ticket and no existing branch pattern; fallback `iac-change/<service>-<short-description>`). Full lane: the branch commands run after `[F2]`.

### `[F2]` shown to the operator (10:50)

```text
**Research summary**
Change requested: remove the 10.20.0.0/16 ingress rule from the orders-db security group; staging first, then prod. Direct apply by hand.
Service: orders / Instance: none. IaC tool: terraform (aws provider ~> 5.0, v5.74.0 locked) · Delivery model: applied by hand, direct apply (operator-stated; code: no CI config in the repo) · Env selection: -var-file=envs/<env>.tfvars, default workspace (code: providers.tf:12-13).
Target: staging account 222222222222 / ap-southeast-1 (live: sts 10:00); prod account 333333333333 / ap-southeast-1 (live: sts 10:01).
Environment tier: staging=staging (proven: live sts 10:00 = code: envs/staging.tfvars:3), prod=prod (proven: live sts 10:01 = code: envs/prod.tfvars:3) · Lane (predicted): full — the plan will show a destroy, targets are not proven dev; escalations: none.
Catalog used: none — proceeding without catalog.
Duplicate check: not done (code: main.tf:287-294; git log -S, branch and PR searches empty).
Evidence table: 13 rows — drift rows: 0, unverified rows: 3 (callers outside this repo, where state lives, what removing the rule does to connections). The table is in the execution record.
Snapshot set: orders-db, orders-api, orders-worker (+ alarm orders-worker-errors), orders-alb (4 members). Snapshot coverage: code + live reads; not covered: batch jobs and other VPC hosts that use the rule, no catalog, no runtime-trace profile.
Gaps remaining: callers outside this repo; where state lives; documented behaviour of the rule removal (docs lookups returned nothing).

**Change plan for orders**

Phase 1 of 1: remove the legacy VPC-wide CIDR rule from the database security group
- Files: main.tf (delete lines 285-295: the 2 comment lines, the resource aws_vpc_security_group_ingress_rule.orders_db_from_vpc, and the blank line after it). No var-file change: both environments use the same file.
- Resources affected (predicted; the plan runs at [F3]): destroy aws_vpc_security_group_ingress_rule.orders_db_from_vpc, 1 per environment: 0 to add, 0 to change, 1 to destroy.
- Blast radius: orders-db, orders-api, orders-worker (+ alarm), orders-alb, in each environment. Coverage: code + live; not covered: batch jobs and other VPC hosts that use the rule.
- Disruption: UNVERIFIED — expected: new connections from orders-api and orders-worker to the database on 5432 are refused once the rule is gone. Evidence: the rule is the only one that admits their source addresses (code: main.tf:296-303 references only the admin host's group; live: describe-security-groups 10:25 shows only the CIDR rule and the admin group; their task SGs sg-0e6b5c4d3e2f10987 / sg-0e7c6d5e4f3a21098 are not sources and are not attached to the DB SG, live: describe-network-interfaces 10:26); their subnets are inside the CIDR (code: envs/staging.tfvars:6-11). Behaviour of established connections: UNVERIFIED — the docs lookup returned no canned output. Not "none".
- Rollback path: re-add the resource block (revert the diff), then terraform plan and apply for the environment. A rule holds no data, so this should be reversible, but it is untested and the claim is UNVERIFIED (docs lookup returned nothing). Between the apply and the restore the effect above stays.
- Evidence: the 13 evidence-table rows above.
- Success criteria:
    1. aws ec2 describe-security-groups --group-ids <DB SG id> → no 10.20.0.0/16 left, only the admin host's group
    2. terraform plan -var-file=envs/<env>.tfvars → No changes
    3. aws rds describe-db-instances --db-instance-identifier orders-db-<env> --query 'DBInstances[].DBInstanceStatus' → available
    4. aws ecs describe-services --cluster orders-cluster-<env> --services orders-api-<env> orders-worker-<env> → running = desired
    + S2 on the snapshot set, once two 5-minute periods have passed after the apply (the apply is at T; S2 ready at T+10 min)

Execution path: Direct apply, at your request (local workstation apply, not through a pipeline: it raises the pre-flight risk, anti-pattern A4). The PR path is the default and stays available.
Staging-first (H7): staging, then prod — direct apply per environment, staging's [F4] first · Observation window: 30 minutes after staging's success criteria pass, so a slower consumer shows up (reason: guess — the batch jobs in the comment at main.tf:285-286 are not visible).
Branch: current main → iac-change/orders-remove-db-vpc-ingress-rule from origin/main @ a1b2c3d (fetch + create).
Self-check: 8/8 pass (the disruption and the rollback class are named as UNVERIFIED under item 1).
Drift (H4): none (terraform plan -refresh-only: No changes in staging 10:33 and prod 10:46; code and live agree on every row).

**Checked for you:** (correct anything that's wrong)
- Health, staging: orders-db + orders-api + orders-worker + orders-alb — 0 alarms firing on the set; ALB target 5XX 0.20% of requests (same hour last week 0.20%); worker job errors 0.50% of jobs (1w 0.50%); p95 0.180 s (1w 0.184 s); CPU and memory under 53% · live 10:31-10:32
- Health, prod: same set — 0 alarms firing; target 5XX 0.20% (1w 0.20%); worker job errors 0.50% (1w 0.50%); p95 0.183 s (1w 0.187 s); CPU and memory under 56% · live 10:44-10:45
- Peak: staging no — 24,130 req/h, same hour last week 23,890 (1.01x); prod no — 108,130 vs 107,050 (1.01x) · live 10:32 / 10:45
- Last apply: no CI history and no state object to read (no workflow file, no backend block); latest ECS deployments: staging 2026-11-12 15:20 +07:00 (4 days ago), prod 2026-11-05 14:10 (11 days ago) · live 10:21 / 10:34
- App source: not found — `ls ..` lists dotfiles and orders-infra (this repo); ../dotfiles origin is git@github.com:acme/dotfiles.git, not the app · live 10:19-10:20
- Experience: Q4 many times (acme/orders-infra/orders), Q5 experienced (terraform) · operator (profile, 2026-10-26)
Snapshot coverage: code + live reads; not covered: batch jobs and other VPC hosts that use the rule, no catalog, no runtime-trace profile

Q8: This change touches what the app depends on: network ingress to the database (the rule that admits the api and worker). Where is the application source? (a) a local checkout — give the path; (b) a GitHub repo through gh — give owner/repo and the deployed ref (staging runs v1.9.0-rc1, prod v1.8.3; Choosing (b) approves only these GET reads: gh auth status, resolve the ref to a SHA, list the file tree at that SHA, fetch file contents at that SHA); (c) not available.

Anything I can't see — a declared incident, a change freeze, anything else? No reply means none.

**[F2] Approve this plan?**
```

Notes on what is not in `[F2]`: no Q4 / Q5 (the profile holds both, neither is `first time`); no delivery-model question (operator-stated in the first message, not `UNVERIFIED`); no Q6 (cost is scored from the plan: one destroy, nothing added); no iac-change assessor question (`iac-change.1–3` come from `Plan hash:`, `Delivery model:` and `Target:` + plan command; `.4` from the automation-lag read). The operator line stays, because no freeze source was read (no calendar in the repo) and the profile holds no incident command (`snapshot.md` › L2 from evidence, The operator line).

`stops.md` line 2 is written for this stop.

Operator answer (script entry 2, `[F2]`, answered at 10:55):
- Plan approved: staging first, then prod, with the observation window the plan proposes — then: "none, prod starts as soon as staging's verification and the `[H10]` decision are done (operator choice)". The script says: "Observation window, if the plan proposes one: none". The plan proposed one, so this is said.
- Operator line: no reply (script: `Operator line: no reply.`). Nothing is said about it, not logged as `L2-ASKED`.
- Q8 (the skill asked it): (c) the application source is not available.
- Drift rows to acknowledge: none shown.
- Not asked, so not said: Q1, Q2, Q3, Q4, Q5, Q6, Q7, `iac-change.1`–`.4`, delivery model.

L2-ASKED: Q8

Recorded from this stop: `Q1(declared)=no, Q2=no — operator (no objection at [F2], 10:55)`; `Q7=none — operator (no objection at [F2], 10:55)`; `Q8=(c) application source not available — operator`. The observation window is recorded as: none, by operator choice at `[F2]`. Nothing is saved to the operator profile (nothing was asked that it lacked); no `PROFILE-WRITE` line.

---

## Step 3 — Implement (staging and prod share one code change)

Branch commands, approved with the plan (full lane, after `[F2]`):

```
[10:55] $ git fetch origin main
        canned: empty.txt (row `git fetch origin *`) -> no output
[10:56] $ git switch -c iac-change/orders-remove-db-vpc-ingress-rule origin/main
        canned: git-switch.txt -> Switched to a new branch 'iac-change/orders-remove-db-vpc-ingress-rule'
[10:57] $ git branch --show-current
        canned: git-branch-after-switch.txt -> iac-change/orders-remove-db-vpc-ingress-rule
```

The branch shows the change's branch before any file is written. Code written to the working tree (the runner makes no write to the fixture; the diff below stands in):

```diff
--- a/main.tf
+++ b/main.tf
@@ -282,17 +282,6 @@
   }
 }
 
-# Legacy: any host in the VPC may open a PostgreSQL connection. The api, the worker
-# and the batch jobs all come in through this rule.
-resource "aws_vpc_security_group_ingress_rule" "orders_db_from_vpc" {
-  security_group_id = aws_security_group.orders_db.id
-  description       = "PostgreSQL from the VPC (legacy)"
-  cidr_ipv4         = "10.20.0.0/16"
-  from_port         = 5432
-  to_port           = 5432
-  ip_protocol       = "tcp"
-}
-
 resource "aws_vpc_security_group_ingress_rule" "orders_db_from_admin" {
   security_group_id            = aws_security_group.orders_db.id
   description                  = "PostgreSQL from the admin host"
```

Local formatter on the changed file only, shown before running (the skill may run `terraform fmt <file>`):

```
[10:58] $ terraform fmt main.tf
        canned: empty.txt (row `terraform fmt *`) -> nothing printed: already formatted
[10:59] $ git status --short
        answered from the diff above -> " M main.tf"
[11:00] $ git diff
        answered from the diff above (the hunk shown)
```

Note on the header comment at `main.tf:4-5` ("The change under test removes the legacy VPC-wide CIDR rule …"): it describes this change, is outside this phase's file list items (only the rule is), and is left as is — the scope check says "nothing else is touched".

Diff self-check (6 items), run on `git status --short` and `git diff`:
1. Scope: `main.tf` is the only changed file and it is the only file in the phase's list; it changed — pass.
2. Plan ↔ hunk: the one hunk deletes the one resource the phase destroys — pass.
3. Conventions: nothing added; the remaining rule `orders_db_from_admin` (`code: main.tf:296`) is untouched — pass.
4. No silent safety changes: none of `prevent_destroy`, `deletion_protection`, `skip_final_snapshot`, `force_destroy`, new `ignore_changes`, `0.0.0.0/0`, `*` in IAM is touched. The hunk removes an ingress allow (narrows exposure), which the approved plan names — pass.
5. No secrets: none in the diff; no `tfplan`, state or `.terraform/` in the working-tree changes — pass.
6. Formatted: `terraform fmt main.tf` printed nothing — pass.
Result 6/6 pass. Light-lane E1–E3 on the diff: not run (the lane is full).

Fresh eyes: the phase is not add-only (it destroys a resource) and it touches network exposure (a security-group rule), so it is not skippable. A separate reviewer in a fresh context would be handed the change request, the approved plan, the evidence table and the diff, and not the self-check. `fresh-eyes: not run — dry run`.

### `[F3]` shown to the operator (11:01)

```text
**Code changes for Phase 1 of 1:**

Modified: main.tf — deleted the legacy rule aws_vpc_security_group_ingress_rule.orders_db_from_vpc (lines 285-295, comment included).
Plan ↔ hunk: destroy aws_vpc_security_group_ingress_rule.orders_db_from_vpc → main.tf:285-295 (one hunk).
Self-check: 6/6 pass · Fresh eyes: not run — dry run
Target: staging — account 222222222222 / ap-southeast-1, assumed-role/orders-operator (live: sts 10:00; re-read at 4a) · -var-file=envs/staging.tfvars, default workspace · tier staging=staging. prod — account 333333333333 / ap-southeast-1 (live: sts 10:01) · -var-file=envs/prod.tfvars · tier prod=prod.
Plan command (4a), per environment, on this approval (read-only against the cloud; uses the credentials above):
  staging: terraform plan -out=tfplan -var-file=envs/staging.tfvars   (terraform init is not re-run: it ran at [F1] and no provider or module changed)
  prod: terraform plan -out=tfplan -var-file=envs/prod.tfvars, at prod's 4a
  after each apply: terraform plan -var-file=envs/<env>.tfvars (the re-plan)

Full diff is in your working tree (git diff to review).
**[F3] Approve these changes and the plan command?**
```

`stops.md` line 3 is written for this stop.

Operator answer (script entry 3, `[F3]`, answered at 11:06): approve the code (both var-files). No L2 item.

---

## Step 4 — Execute (staging)

### 4a: target re-check and plan output

Re-check the target first (Constraint 10), no stop. Credentials: staging.

```
[11:06] $ aws sts get-caller-identity            (staging credentials; var-file envs/staging.tfvars, default workspace)
        canned: identity-staging.json (rule 1(a): the plan is for staging)
        -> Account 222222222222, assumed-role/orders-operator. Matches the target the plan is for (pin: code: envs/staging.tfvars:3). No [H1].
[11:07] $ terraform plan -out=tfplan -var-file=envs/staging.tfvars
        canned: plan-staging.txt (state: staging, before the staging apply)
        -> "Plan: 0 to add, 0 to change, 1 to destroy." — aws_vpc_security_group_ingress_rule.orders_db_from_vpc will be destroyed (plan lines 6-21)
```

Canned plan versus code: the code diff removes exactly `orders_db_from_vpc`, and the canned plan destroys exactly that resource (`plan:6`, `plan:21`). No difference to note. `tfplan` stays local (Constraint 11).

Cross-check against the evidence table: the only resource in the plan is the approved one, the action (destroy) matches what `[F2]` approved; no unexpected destroy or replace (no `[H3]`); the refresh found no drift (no `[H4]`); the resource is already in the snapshot set's scope (the rule itself is `n/a`; its dependents are members), so no member is added.
Lane confirmation (`lanes.md` › Lane rule): L1 fails on the destroy (`plan:21`); the lane stays **full**. Nothing to escalate, nothing downgraded.
Parity check: `n/a` — this is the staging phase.

### 4b: S1, then pre-flight (H9)

S1 first, every lane. The latest staging snapshot is S0 (reads 10:21–10:32); at 11:08 it is more than 15 minutes old, so S1 is read again. It was approved with the batch, so no stop.

```
[11:08] $ aws ecs describe-services --cluster orders-cluster-staging --services orders-api-staging orders-worker-staging --region ap-southeast-1
        canned: ecs-describe-services-staging.json (state: any) -> api 2/2, worker 2/2, COMPLETED (same as S0)
[11:09] $ aws rds describe-db-instances --db-instance-identifier orders-db-staging --query 'DBInstances[].DBInstanceStatus'
        canned: rds-instance-staging.json -> available
[11:10] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/orders-api-tg-staging/6d0ecf831eec9f09
        canned: tg-health-staging.json -> 2/2 healthy
[11:11] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '...'
        canned: alarms-firing-staging.json (S0/S1 of staging, before the staging apply) -> nothing firing
[11:12] $ aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-09T10:12:00+07:00 --end-time 2026-11-16T11:12:00+07:00 --scan-by TimestampAscending --query '...'
        canned: metric-data-s0-staging.json (S0/S1 of staging; same derivation as at 10:32)
```

S1 staging (first read), reads 11:08–11:12 (hour ending 11:12):

| Member | Signal | Hour ending 11:12 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 22.05% | [M] | 11:12 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 37 | [M] | 11:12 |
| orders-db-staging | DatabaseConnections (max) | 46 | 45 | [M] | 11:12 |
| orders-db-staging | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 11:12 |
| orders-db-staging | status (point-in-time) | available | n/a | [R] | 11:09 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | not read (no 1w series) | [M] | 11:12 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | not read (no 1w series) | [M] | 11:12 |
| orders-api-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:08 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | not read (no 1w series) | [M] | 11:12 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | not read (no 1w series) | [M] | 11:12 |
| orders-worker-staging | JobsProcessed (traffic, sum) | 7,201 | 7,129 | [M] | 11:12 |
| orders-worker-staging | JobErrors (sum) | 36 (0.500% of jobs) | 36 (0.505%) | [M] | 11:12 |
| orders-worker-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:08 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (0 firing on the set) | n/a | [A] | 11:11 |
| orders-alb-staging | RequestCount (sum) | 24,130 | 23,890 | [M] | 11:12 |
| orders-alb-staging | HTTPCode_Target_5XX_Count (sum) | 48 (0.199% of requests) | 47 (0.197%) | [M] | 11:12 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 11:12 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.184 s | [M] | 11:12 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | [M] | 11:12 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | [M] | 11:12 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | n/a | [T] | 11:10 |

S1 changes no answer: `Q1(alarms)` is still no, Q3 is still no (24,130 vs 23,890). The plan text and its hash, for the reuse check:

```
[11:13] $ terraform show -no-color tfplan
        canned: plan-staging.txt (rule: the last plan the skill ran was for staging)
[11:14] $ sha256sum <scratch file holding the plan text>
        canned: Plan hashes -> sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7   (the scratch file is outside the repo and deleted afterwards)
```

Reusable pre-flight record in `.culiops/pre-flight/`: none exists (the fixture has no `.culiops/` directory). No match, so pre-flight is invoked inline. Caller block passed (every field filled, no `unknown`):

```
### Caller context (iac-change-execution)
Target: account 222222222222 / ap-southeast-1 via staging credentials (assumed-role/orders-operator) / var-file envs/staging.tfvars, default workspace; state backend not declared in code
Delivery model: applied by hand, direct apply from the operator's workstation (operator-stated, first message; code: no CI / Atlantis / TFC / Spacelift config in the repo) — local workstation apply, not going through CI/CD pipeline
Lane: full — the plan shows a destroy (L1 fails) and the targets are staging and prod, not proven dev
Plan hash: sha256:9e5302bb57a67c7203f082cde8c27a94e7ac42b45422704cbe3b2df961a496a7 (terraform show -no-color tfplan, from terraform plan -out=tfplan -var-file=envs/staging.tfvars)
L2 answers: Q1(alarms)=no (live: aws cloudwatch describe-alarms --state-value ALARM, 11:11: 0 firing on the staging snapshot set) Q1(declared)=no (operator (no objection at [F2], 10:55)) Q2=no (operator (no objection at [F2], 10:55)) Q3=no (live: aws cloudwatch get-metric-data, 11:12: ALB RequestCount 24,130 vs 23,890 the same hour last week, 1.01x) Q4=many times (operator (profile, 2026-10-26)) Q5=experienced (operator (profile, 2026-10-26)) Q7=none (operator (no objection at [F2], 10:55)) Q8=(c) application source not available (operator) iac-change.4=recent (live: aws ecs describe-services deployments createdAt 2026-11-12 15:20 +07:00 staging, 11:08; no CI history or state object exists to read)
Live results:
  aws ecs describe-services (orders-api-staging, orders-worker-staging) · 10:21, 11:08 · 2/2 and 2/2 running, deployments COMPLETED, createdAt 2026-11-12 15:20 / 15:21 +07:00
  aws ecs describe-task-definition (api, worker) · 10:22, 10:23 · env names APP_ENV, DB_HOST, PORT / APP_ENV, DB_HOST; image tags v1.9.0-rc1
  aws rds describe-db-instances orders-db-staging · 10:24, 11:09 · available, db.t4g.medium, MultiAZ false, SG sg-0e5a4b3c2d1f09876, nothing pending
  aws ec2 describe-security-groups sg-0e5a4b3c2d1f09876 · 10:25 · ingress 5432 from 10.20.0.0/16 and from sg-0e9f8a7b6c5d4e3f2
  aws ec2 describe-network-interfaces (group sg-0e5a4b3c2d1f09876) · 10:26 · 1 interface (RDSNetworkInterface); api and worker not attached
  aws elbv2 describe-target-groups / describe-load-balancers / describe-target-health · 10:27, 10:28, 10:29, 11:10 · orders-alb-staging internal active; 2/2 targets healthy
  aws cloudwatch describe-alarms --alarm-name-prefix orders · 10:30 · orders-worker-errors-staging enabled, OK
  aws cloudwatch describe-alarms --state-value ALARM · 10:31 (S0), 11:11 (S1) · 0 firing
  aws cloudwatch get-metric-data (snapshot-queries-staging.json) · 10:32 (S0), 11:12 (S1) · target 5XX 0.199% (1w 0.197%), p95 0.180 s (1w 0.184 s), job errors 0.500% (1w 0.505%), CPU/memory < 53%, DB CPU 21.65%, DB connections avg 38 max 46; 4 DB series no data
  terraform plan -refresh-only -var-file=envs/staging.tfvars · 10:33 · no changes
  git grep / git log -S / git branch / gh pr list (duplicate check) · 10:06-10:12 · only the rule itself; no history, branch or PR
Evidence table: 13 rows, 0 drift, 3 UNVERIFIED (callers outside the repo; where state lives; behaviour of the rule removal — docs lookups 10:47, 10:48 returned no canned output), 0 code-only (the table is in the research summary above).
```

### Pre-flight, inline mode (`skills/pre-flight/SKILL.md`, Constraint 14)

Step 1: `assessors/iac-change.md` matches (Terraform plan). Inline mode skips GATE 1 and shows the detection without a stop: *action type: Terraform destroy of one security-group rule; target: account 222222222222 / ap-southeast-1 / envs/staging.tfvars; delivery model: manual apply, direct (caller); assessor: iac-change; plan hash taken from the caller (`sha256:9e5302bb…a496a7`).* Output root named in the report: `.culiops/` at the repo root (the caller resolved it the same way).

Step 2, L1 static analysis, from the plan and the code. Plan hygiene (assessor): the plan was made without `-target` and without `-refresh=false` (`Plan hash:` carries the plan command, so `iac-change.3` is answered); no "No changes" surprise; no unexpected resource. App-facing: a network ingress change is not on the not-app-facing list, so category 11 is triggered. The change-velocity read is local:

```
[11:15] $ aws sts get-caller-identity            (staging credentials; pre-flight's own target check, no stop in inline mode)
        canned: identity-staging.json -> Account 222222222222; equals the caller's Target. Proceed.
[11:16] $ git log --since=7.days --oneline origin/main -- main.tf envs/
        canned: empty.txt (row `git log * --since=*`) -> no commit in the window; this change has no commit of its own (direct apply, uncommitted)
```

Step 3, L2: the caller's `L2 answers:` are the operator's answers; every one of Q1 to Q5, Q7, Q8 and `iac-change.4` is present, `iac-change.1`–`.3` come from `Plan hash:` + plan command, `Delivery model:` and `Target:`; Q6 is scored from the plan (cost only decreases). Nothing is missing, so there is no L2 stop. Step 3b: Q8 is `(c)`, so no app source to scan; category 11 is ⚪. Step 4, L3: every read was run by the caller and is cited as `live: <cmd> (caller, <time>)`; nothing missing, so no read batch and no extra stop.

Step 5 scores and Step 5b verification, then Step 6: the full report is presented to the operator. On RED, inline mode runs GATE 2 itself, and it is `[H5]` (SKILL.md Step 4b).

### `[H5]` shown to the operator (11:17)

```text
## Verdict: RED — SOFT BLOCK

## Risk Scorecard

| # | Category | Score | Finding | Evidence | Mitigation |
|---|----------|-------|---------|----------|------------|
| 1 | Blast radius | 🔴 | The destroyed rule is the only one that admits orders-api and orders-worker to the database; two services, plus callers outside this repo (the code comment names batch jobs), lose their data path. orders-api is the user-facing order path. Disruption is expected, not established: the `docs:` lookups returned no canned output, so "refused" is `UNVERIFIED`; it is not `none`. | `plan:6`, `plan:21`; `code: main.tf:42,70,296-303`; `live: aws ec2 describe-security-groups sg-0e5a4b3c2d1f09876 (10:25)`; `live: aws ec2 describe-network-interfaces (10:26)`; `assessor: Blast radius (deletions, user-facing data path)` | Expand–contract: first add rules that admit the api and worker by security group, then remove the CIDR rule. S2 reads the dependents right after the apply. |
| 2 | Reversibility | 🟡 | Destroy of a stateless network rule: recreatable (revert the diff, plan, apply) but untested, and the effect holds until it is restored. No data, backup, key or one-way attribute is involved. "Re-creating the rule restores access" is `UNVERIFIED` (docs lookup returned no canned output). | `plan:6`; `assessor: Reversibility (destroy on stateless resources → Yellow; Terraform rollback)`; `code: main.tf:287-294` | Keep the reverted diff ready; know that the restore is a second apply per environment. |
| 3 | Change velocity | 🟢 | No commit to the changed paths in the last 7 days; no open PR or branch for this change; the stack was last deployed 4 days ago (ECS), well inside 90 days. | `code: git log --since=7.days --oneline origin/main -- main.tf envs/ → none (11:16)`; `live: gh pr list (caller, 10:12)`; `live: aws ecs describe-services deployments createdAt 2026-11-12 15:20 +07:00 (caller, 11:08)` | — |
| 4 | Dependency impact | 🔴 | The security group protects the shared database used by two services (api, worker) and possibly batch jobs; the rule is the path they use. No catalog exists (a catalog would only be a lead). | `code: main.tf:42,70,262`; `live: aws ecs describe-task-definition (caller, 10:22, 10:23)`; `live: DatabaseConnections avg 38 (caller, 11:12)`; `assessor: Dependency impact (shared infrastructure used by multiple services → Red)` | Inventory the other clients of the database before the apply (batch jobs, other VPC hosts); run service-discovery for orders; same expand–contract. |
| 5 | Timing context | 🟢 | No firing alarm on the set (`Q1(alarms)=no`), no declared incident and no freeze (operator, no objection at `[F2]`), request rate 1.01x the same hour last week (`Q3=no`); the operator applies by hand, so someone is on hand. | `live: aws cloudwatch describe-alarms --state-value ALARM (caller, 11:11)`; `live: get-metric-data (caller, 11:12)`; `operator (no objection at [F2], 10:55)` | — |
| 6 | Operator familiarity | 🟢 | Changed this service many times, experienced with terraform. | `operator (profile, 2026-10-26)` | — |
| 7 | Observability readiness | 🟡 | One alarm exists, is enabled and is `OK`: `orders-worker-errors-staging` (static threshold, JobErrors > 20 per 5 minutes). Nothing alarms on ALB 5XX, target health or database connections, so a break seen by the api would not page. | `code: main.tf:341`; `live: aws cloudwatch describe-alarms --alarm-name-prefix orders (caller, 10:30)`; `assessor: Observability (static threshold → Yellow; no alarm on part of the changed path)` | Watch S2 right after the apply; adding alarms for ALB 5XX and DB connections is a separate change. |
| 8 | Cost impact | 🟢 | 0 to add, 0 to change, 1 to destroy; no new resource or size increase; a rule has no companion that keeps billing. | `plan:21`; `code: main.tf:287-294` | — |
| 9 | Security posture | 🟡 | Network rule modification within the VPC: removes the `10.20.0.0/16` ingress allow, leaving the admin host's group. No public exposure, encryption or secret is touched. Narrowing is not marked Green (the effective-access conclusion needs documentation that was not available). | `plan:6,10`; `live: aws ec2 describe-security-groups (10:25)`; `assessor: Security posture (network rule modification within VPC → Yellow)` | Confirm that VPC access to the database should be limited to the admin host once the clients have their own rules. |
| 10 | Resource health | 🟢 | All signals nominal on the set at S1: no alarm firing, ALB target 5XX 0.20% (same hour last week 0.20%), p95 0.180 s (1w 0.184 s), worker job errors 0.50% (1w 0.50%), CPU and memory under 53% (below 70%), RDS `available`, 2/2 targets healthy. Silent breakage (the api's health check `/healthz` may not exercise the database): a Green here does not clear category 11. | `live: get-metric-data (caller, 11:12)`; `live: aws rds describe-db-instances (caller, 11:09)`; `live: aws elbv2 describe-target-health (caller, 11:10)`; `live: describe-alarms --state-value ALARM (caller, 11:11)`; `code: main.tf:165-168` | — |
| 11 | Application compatibility | ⚪ | Triggered: a network ingress change on a resource the app dials is app-facing (fail-closed). The application source is not available (`Q8=(c)`), so what the api and worker do when the connection is refused is unknown. | `plan:6`; `operator (Q8=(c))` | Name a source (local checkout or `owner/repo` + deployed ref `v1.9.0-rc1`) and re-run the check. |

## Evidence
| Fact | Code / plan | Live | Match |
|------|-------------|------|-------|
| The rule admits 10.20.0.0/16 on 5432 | `code: main.tf:287-294`, `plan:10` | `live:` SG describe (10:25) | ✓ |
| Only other ingress is the admin host's SG | `code: main.tf:296-303` | `live:` SG describe (10:25) | ✓ |
| Only the DB (ENI) is attached to the SG | `code: main.tf:262` | `live:` ENI read (10:26) | ✓ |
| api and worker use `DB_HOST` | `code: main.tf:42,70` | `live:` task definition env names (10:22, 10:23) | ✓ |
| No drift | `code: main.tf` | `live: terraform plan -refresh-only (caller, 10:33)`: no changes | ✓ |
| Batch jobs / other callers use the rule | `code: main.tf:285-286` (comment: data) | not readable | UNVERIFIED |
| What removing a rule does to connections | n/a | n/a | UNVERIFIED (no `docs:`) |

No drift rows. `UNVERIFIED`: callers outside the repo, behaviour of the rule removal.

## Verification
- Citations checked: 13 (every Red, and every Green on categories 1, 2, 4, 7, 9, 10, 11 — only 10 is Green among them — plus the factual premise of each mitigation, re-opened against `main.tf`, the plan text and the live reads cited). Fixed: none.
- Verdict working: Red = categories 1, 4; Yellow + ⚪ = 4 (2, 7, 9, 11); 3 or more Yellow/⚪ also escalates to Red on its own; hard blocks checked: category 2 (irreversible data change — none: no data, backup or key involved), category 5 (active incident plus freeze — neither), category 9 (public exposure, encryption removal, secrets — none), category 10 (error budget exhausted — no SLO declared, no firing alarm) → none triggered → RED — soft block.
- Fresh eyes: not required (verdict RED — soft block).
- Not verified: the disruption and rollback behaviour (no `docs:` available); `Q1(declared)`, `Q2` and `Q7` rest on the operator's no-objection, not a calendar or an incident command; that someone is on hand rests on the operator applying by hand (operator-stated); `Q4` / `Q5` are profile answers; callers outside this repo (batch jobs) are not visible; where state lives is not in the code; what the application does when the connection is refused (no source).

## Hard Blocks
None.

**[H5] Pre-flight is RED (soft block) for the staging apply. Acknowledge each Red finding with a reason, or abort?**
Red findings to acknowledge:
  1. Blast radius — the destroyed rule is the only one admitting orders-api and orders-worker to the database; expected effect: new connections refused (UNVERIFIED, docs not available).
  4. Dependency impact — the rule protects the shared orders-db used by two services and possibly batch jobs outside the repo.
Mitigations offered: expand–contract (add rules for the api and worker security groups first); inventory the other database clients; keep the reverted diff ready. Say which, if any, you commit to.
```

`stops.md` line 4 is written for this stop.

Operator answer (script entry 7, `[H5]`, answered at 11:22; the script applies it to every `[H5]` in the run, only when the verdict is RED, and the verdict is RED): acknowledge each Red finding, reason: "the rule is legacy and being removed on purpose; staging goes first, and the services that rely on it are the ones the snapshot measures". No L2 item. The reply commits no mitigation, so none is recorded as committed.

Pre-flight Step 7 writes its record (`preflight-record.md`, path `.culiops/pre-flight/orders-remove-db-vpc-ingress-20261116-1122.md`), left uncommitted, and returns the verdict RED — soft block, with the acknowledgements, to the caller.

---

### 4c: Execute — staging, direct apply

H7 check: this mutation reaches staging, not prod; H7 is checked before a prod `[F4]` only. The `[F4]` below carries the verdict line (the reuse of a record does not apply: it was a fresh run) and S1's result.

### `[F4]` (staging) shown to the operator (11:22)

```text
**[F4] Run this apply?**
About to run: terraform apply tfplan  against account 222222222222 / ap-southeast-1, assumed-role/orders-operator (re-checked at 4a, live: sts 11:06), var-file envs/staging.tfvars, default workspace · tier staging=staging
This will: destroy aws_vpc_security_group_ingress_rule.orders_db_from_vpc (plan: 0 to add, 0 to change, 1 to destroy; hash sha256:9e5302bb…a496a7) — the legacy 10.20.0.0/16 ingress on the database's security group.
Pre-flight verdict: RED — soft block; Red findings 1 (blast radius) and 4 (dependency impact) acknowledged at [H5] 11:22 with your reason; mitigations committed: none. Yellow/⚪ findings: 2 reversibility (untested rollback), 7 observability (alarm covers the worker only), 9 security posture (network narrowing), 11 application compatibility (no app source). Approving here records them as acknowledged.
S1 (staging, 11:08-11:12): 0 alarms firing; target 5XX 0.199%; worker job errors 0.500%; p95 0.180 s; RDS available; 2/2 targets healthy; ECS 2/2 and 2/2.
Fresh eyes on the code: not run — dry run. Parity: n/a (staging).
Heads-up: say so and I draft one for the owners / reviewers / on-call with change-comms (draft-only; you send it).
```

`stops.md` line 5 is written for this stop.

Operator answer (script entry 4, `[F4]` staging, answered at 11:27): approve the apply command shown for staging. Approving also acknowledges the verdict (RED, already acknowledged at `[H5]`). No reply to the heads-up line, so no `change-comms` draft. No L2 item.

S1 age check (`snapshot.md` › When snapshots run: if the reply comes more than 15 minutes after S1, take S1 again just before the apply, no stop). S1 reads ran 11:08–11:12 and the reply came at 11:27.

AMBIGUITY: the age of S1 — "more than 15 minutes after S1" for a snapshot whose reads span 11:08–11:12 — reading taken: measure from the snapshot's oldest read (11:08), so 19 minutes is older than 15 and S1 is taken again; measured from its last read (11:12) it would be exactly 15 and would not.

```
[11:27] $ aws ecs describe-services --cluster orders-cluster-staging --services orders-api-staging orders-worker-staging --region ap-southeast-1
        canned: ecs-describe-services-staging.json -> 2/2 and 2/2, COMPLETED
[11:28] $ aws rds describe-db-instances --db-instance-identifier orders-db-staging --query 'DBInstances[].DBInstanceStatus'
        canned: rds-instance-staging.json -> available
[11:29] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/orders-api-tg-staging/6d0ecf831eec9f09
        canned: tg-health-staging.json -> 2/2 healthy
[11:30] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '...'
        canned: alarms-firing-staging.json (S0/S1 of staging; before the apply) -> nothing firing
[11:31] $ aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-09T10:31:00+07:00 --end-time 2026-11-16T11:31:00+07:00 --scan-by TimestampAscending --query '...'
        canned: metric-data-s0-staging.json (S0/S1 of staging)
```

S1 staging, re-read just before the apply (reads 11:27–11:31, hour ending 11:31). It is "the before" of this apply. Its values equal the earlier S1; it is its own table, as the record format requires.

| Member | Signal | Hour ending 11:31 | Same hour 1w ago | Command | Time |
|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 22.05% | [M] | 11:31 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 37 | [M] | 11:31 |
| orders-db-staging | DatabaseConnections (max) | 46 | 45 | [M] | 11:31 |
| orders-db-staging | ReadLatency (avg) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | WriteLatency (avg) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | FreeableMemory (min) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | FreeStorageSpace (min) | no data (no datapoint) | no data | [M] | 11:31 |
| orders-db-staging | status (point-in-time) | available | n/a | [R] | 11:28 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | not read (no 1w series) | [M] | 11:31 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | not read (no 1w series) | [M] | 11:31 |
| orders-api-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:27 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | not read (no 1w series) | [M] | 11:31 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | not read (no 1w series) | [M] | 11:31 |
| orders-worker-staging | JobsProcessed (traffic, sum) | 7,201 | 7,129 | [M] | 11:31 |
| orders-worker-staging | JobErrors (sum) | 36 (0.500% of jobs) | 36 (0.505%) | [M] | 11:31 |
| orders-worker-staging | running vs desired (point-in-time) | 2/2, deployment COMPLETED | n/a | [E] | 11:27 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (0 firing on the set) | n/a | [A] | 11:30 |
| orders-alb-staging | RequestCount (sum) | 24,130 | 23,890 | [M] | 11:31 |
| orders-alb-staging | HTTPCode_Target_5XX_Count (sum) | 48 (0.199% of requests) | 47 (0.197%) | [M] | 11:31 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | [M] | 11:31 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.184 s | [M] | 11:31 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | [M] | 11:31 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | [M] | 11:31 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | n/a | [T] | 11:29 |

`Q1(alarms)` and Q3 are unchanged from what pre-flight got, so pre-flight is not re-run and no `[F4]` repeats (`lanes.md` › Timing re-ask).

Apply (direct apply path: one command, the one approved at `[F4]`):

```
[11:32] $ terraform apply tfplan
        canned: apply-staging.txt (the apply is for staging)
        -> aws_vpc_security_group_ingress_rule.orders_db_from_vpc: Destruction complete after 1s
           Apply complete! Resources: 0 added, 0 changed, 1 destroyed.
```

Apply time T = 11:32. The apply is short (1 s), so it is not run in the background.

---

## Step 5a — Verify (staging)

1. Re-plan (approved with the plan command at `[F3]`):

```
[11:33] $ terraform plan -var-file=envs/staging.tfvars
        canned: plan-after-staging.txt (state: after the staging apply) -> "No changes. Your infrastructure matches the configuration."
```

2. Success criteria (approved with the plan at `[F2]`):

```
[11:34] $ aws ec2 describe-security-groups --group-ids sg-0e5a4b3c2d1f09876 --query 'SecurityGroups[].IpPermissions[].{ranges:IpRanges[].CidrIp,groups:UserIdGroupPairs[].GroupId}'
        canned: sg-describe-after-staging.json (state: after the staging apply) -> ranges [], groups [sg-0e9f8a7b6c5d4e3f2] — no 10.20.0.0/16; only the admin host's group remains. PASS
[11:35] $ aws rds describe-db-instances --db-instance-identifier orders-db-staging --query 'DBInstances[].DBInstanceStatus'
        canned: rds-instance-staging.json -> available. PASS
[11:36] $ aws ecs describe-services --cluster orders-cluster-staging --services orders-api-staging orders-worker-staging --query 'services[].{name:serviceName,desired:desiredCount,running:runningCount}'
        canned: ecs-describe-services-staging.json (reads of staging, any state; --query applied by the runner) -> orders-api-staging 2/2, orders-worker-staging 2/2. PASS
```

3. S2 and the comparison. The rollout is complete (there is no rollout: no ECS resource changed), and the plan's disruption has no end to wait for (the effect, if any, starts at the apply and stays). At `Period` 300 two periods are 10 minutes after the apply (11:32:00 → 11:42:00). It is 11:36, so the metric signals are `after: too early` and are not `ok`.

```text
S2 ready at 11:42 (two 5-minute periods after the apply at 11:32; no stop).
```

Clock jump logged (protocol, Notes for the run › Waiting for S2): the dry-run clock goes from 11:37 to 11:42; the next command runs at 11:42.
S2 query file: the same file with every `Period` set to 300 (`examples/aws.md` › Reads, S2). The window is `--start-time 2026-11-16T11:32:00+07:00 --end-time 2026-11-16T11:42:00+07:00`, which holds two full periods; the runner returns the first two of the canned six values per series.

```
[11:42] $ aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-16T11:32:00+07:00 --end-time 2026-11-16T11:42:00+07:00 --scan-by TimestampAscending --query 'MetricDataResults[].{id:Id,status:StatusCode,t:Timestamps,v:Values}'
        canned: metric-data-s2-staging.json (S2 of staging); values for the two periods inside the window; the four RDS series the file does not hold return no datapoints
[11:43] $ aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1 --query '...'
        canned: alarms-firing-after-staging.json (S2 of staging) -> orders-worker-errors-staging is in ALARM (it was OK at S0/S1); StateUpdatedTimestamp 11:42, reason: 2 datapoints [141.0 (11:42), 138.0 (11:37)] above the threshold 20.0
[11:44] $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:222222222222:targetgroup/orders-api-tg-staging/6d0ecf831eec9f09
        canned: tg-health-staging.json (reads of staging, any state) -> 2/2 healthy
```

(The point-in-time state of ECS and RDS for S2 is the success-criteria reads at 11:36 and 11:35; no read is run twice.)

S2 staging with the comparison against the S1 re-read at 11:27–11:31. Changed resources are judged by their success criteria (the rule is `n/a`); every member's signals are judged against the thresholds in `snapshot.md` › Comparison. The error floor (at least 5 errors in the after window) and the low-volume floor (100 requests or jobs) are met by both regressed rates.

| Member | Signal | Before (S1, re-read 11:27–11:31) | After (S2, 11:32–11:42) | Verdict | Command | Time |
|---|---|---|---|---|---|---|
| orders-db-staging | CPUUtilization (avg) | 21.65% | 14.10% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-db-staging | DatabaseConnections (avg) | 38 | 30 | ok (fewer connections; no max_connections value read, so no saturation test) | [M] | 11:42 |
| orders-db-staging | DatabaseConnections (max) | 46 | 36 | ok (fewer connections; no max_connections value read, so no saturation test) | [M] | 11:42 |
| orders-db-staging | ReadLatency (avg) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | WriteLatency (avg) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | FreeableMemory (min) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | FreeStorageSpace (min) | no data | no data | no data (no datapoint in either window) | [M] | 11:42 |
| orders-db-staging | status (point-in-time) | available | available | ok | [R] | 11:35 |
| orders-api-staging | CPUUtilization (avg) | 38.35% | 38.75% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-api-staging | MemoryUtilization (avg) | 52.18% | 52.65% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-api-staging | running vs desired | 2/2 | 2/2 | ok | [E] | 11:36 |
| orders-worker-staging | CPUUtilization (avg) | 26.75% | 31.50% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-worker-staging | MemoryUtilization (avg) | 44.35% | 45.15% | ok (saturation, did not cross 70%) | [M] | 11:42 |
| orders-worker-staging | JobsProcessed per minute | 120.0/min | 120.2/min | ok (traffic, no threshold; low-volume floor 100 met) | [M] | 11:42 |
| orders-worker-staging | job error rate (JobErrors / JobsProcessed) | 36 / 7,201 = 0.500% | 279 / 1,202 = 23.21% | regressed (> 1.5x before = 0.750%; 279 errors >= 5) | [M] | 11:42 |
| orders-worker-staging | running vs desired | 2/2 | 2/2 | ok | [E] | 11:36 |
| orders-worker-staging | alarm orders-worker-errors-staging | OK (not firing, S1 11:30) | ALARM (StateUpdated 11:42) | regressed (firing after, not before) | [A] | 11:43 |
| orders-alb-staging | RequestCount per minute | 402.2/min | 400.0/min | ok (traffic, no threshold; low-volume floor 100 met) | [M] | 11:42 |
| orders-alb-staging | target 5XX rate (errors / requests) | 48 / 24,130 = 0.199% | 124 / 4,000 = 3.10% | regressed (> 1.5x before = 0.298%; 124 errors >= 5) | [M] | 11:42 |
| orders-alb-staging | HTTPCode_ELB_5XX_Count (sum) | 0 | 0 | ok (0 errors; floor of 5 not met) | [M] | 11:42 |
| orders-alb-staging | TargetResponseTime (p95) | 0.180 s | 0.215 s | ok (1.19x, threshold 1.5x) | [M] | 11:42 |
| orders-alb-staging | HealthyHostCount (min) | 2 | 2 | ok (unchanged; no expected value differs) | [M] | 11:42 |
| orders-alb-staging | UnHealthyHostCount (min) | 0 | 0 | ok (unchanged; no expected value differs) | [M] | 11:42 |
| orders-alb-staging | target health (point-in-time) | 2/2 healthy | 2/2 healthy | ok | [T] | 11:44 |

Result: **17 ok · 3 regressed · 4 no data** (counted per member-signal row). Regressed members: **2** — `orders-worker-staging` (job error rate, alarm) and `orders-alb-staging` (target 5XX rate). `orders-db-staging` has 4 signals with no data (no member has no data for every signal), `orders-api-staging` is `ok`.

AMBIGUITY: `snapshot.md` › Result gives `Snapshot: <n ok · n regressed · n no data>` without saying whether the counts are members or signals — reading taken: member-signal rows (24 rows here); the number of regressed members is stated separately (2).

AMBIGUITY: `snapshot.md` › Comparison: the alarm `orders-worker-errors-staging` — a member of its own or a signal of the worker — reading taken: a signal of `orders-worker-staging` (Signals › Alarms: "an alarm on a member is firing"), so it adds a signal to that member and not a member.

Verification for Phase 1 (staging): re-plan clean; success criteria 4 of 4 pass; snapshot: three signals regressed, so the phase verification is `fail (snapshot)` and `[H10]` is raised (`snapshot.md` › After a regression). The success criteria passed, so the stop offers a reason.

### `[H10]` shown to the operator (11:45)

```text
**[H10] Health regressed after the apply of phase 1 in staging. Type a reason to continue, or the run stops here.**

Regressed signals (observed after the apply; the change is a suspect, not a proven cause):
1. orders-worker-staging · job error rate (JobErrors ÷ JobsProcessed)
   before 0.500% (36 errors of 7,201 jobs, hour ending 11:31; command: aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-09T10:31:00+07:00 --end-time 2026-11-16T11:31:00+07:00 --scan-by TimestampAscending, read 11:31; same hour last week 0.505%)
   after 23.21% (279 errors of 1,202 jobs, 11:32-11:42; command: aws cloudwatch get-metric-data --region ap-southeast-1 --metric-data-queries file://.culiops/iac-change-execution/snapshot-queries-staging.json --start-time 2026-11-16T11:32:00+07:00 --end-time 2026-11-16T11:42:00+07:00 --scan-by TimestampAscending, read 11:42)
   threshold: above 1.5x before (0.750%), with at least 5 errors in the after window (279)
2. orders-worker-staging · alarm orders-worker-errors-staging
   before OK, not firing (command: aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region ap-southeast-1, read 11:30)
   after ALARM, StateUpdatedTimestamp 11:42 (same command, read 11:43; 2 datapoints 141 at 11:42 and 138 at 11:37 above the threshold 20 per 5 minutes)
   threshold: firing after the apply and not firing before
3. orders-alb-staging · target 5XX rate (HTTPCode_Target_5XX_Count ÷ RequestCount)
   before 0.199% (48 errors of 24,130 requests, hour ending 11:31; same get-metric-data command as in 1, read 11:31; same hour last week 0.197%)
   after 3.10% (124 errors of 4,000 requests, 11:32-11:42; same get-metric-data command as in 1, read 11:42)
   threshold: above 1.5x before (0.298%), with at least 5 errors in the after window (124)

Not regressed, for context: orders-alb-staging p95 0.180 s → 0.215 s (1.19x, under 1.5x); healthy targets 2 → 2; orders-api CPU/memory and running count unchanged; orders-db CPU 21.65% → 14.10%, connections avg 38 → 30 (read 11:42; no saturation threshold applies). The success criteria passed (security group no longer lists 10.20.0.0/16; re-plan clean; RDS available; ECS running = desired).
No data: orders-db-staging ReadLatency, WriteLatency, FreeableMemory, FreeStorageSpace (no datapoint in either window). No member has no data for every signal.
Rollback path for this phase (informational, your call; nothing runs automatically): re-add the deleted resource block in main.tf (reverse the diff), then terraform plan and apply for staging. Reversible in principle, untested; docs lookup returned nothing.
Prod has not been touched.
```

`stops.md` line 6 is written for this stop.

Operator answer (script entry 5, `[H10]`, answered at 11:50): "I don't know why — stop here." That is a reply with no reason, so the run does not continue (`snapshot.md` › After a regression: "stop", or any reply without a reason, ends the run `partially completed`). No L2 item.

Consequences, as the text lists them:
- `Outcome: partially completed`. Staging is `yes — not verified` (it has `regressed` members, and an environment with a regressed member is never `yes — verified`).
- Prod's plan, S1, pre-flight, `[F4]`, apply and S2 do not run; no later S1 or S2 is taken. Prod's entry says `Execution: not applied — <reason>`, and the prod clause of `Applied:` is `no — not applied (<reason>)`. The prod `[F4]` of the script (entry 6) is never reached, so it is not used. H7, the parity check, and the observation window are not reached.
- The final message says what was applied and what was not, and makes no rollback offer.
- No `[F4]` of prod, no further stop.

---

## Step 5b — Record

AMBIGUITY: the record's `Commit:` field on the direct apply path — Step 4c commits only on the PR path, and the operator asked for no PR, so nothing is committed and the applied code is an uncommitted working-tree change — reading taken: `Commit:` carries the base SHA the branch was made from (`a1b2c3d`, `origin/main`) and says the change is uncommitted.

Written at 11:50 to `.culiops/iac-change-execution/orders-remove-db-vpc-ingress-20261116-1150.md` (the runner stores it as `record.md`; `CULIOPS_HOME` unset, so the record lives in the repo's `.culiops/` and a commit offer is allowed). The pre-flight record is `preflight-record.md`. The execution record carries the Health Snapshot section with staging's S0, S1, the S1 re-read and S2, and prod's S0.

Final message to the operator:

```text
Outcome: partially completed (phase 1 of 1). Staging: the rule orders_db_from_vpc was destroyed (apply 11:32, re-plan clean) and health regressed afterwards — orders-worker-staging (job errors 0.50% → 23.21%, alarm orders-worker-errors-staging in ALARM) and orders-alb-staging (target 5XX 0.20% → 3.10%) — so staging is applied but not verified; you chose to stop at [H10] without a reason. Prod was not applied: its plan, pre-flight, [F4], apply and S2 did not run. Applied: staging yes — not verified; prod no — not applied (ended at [H10]).
The change is in your working tree on branch iac-change/orders-remove-db-vpc-ingress-rule, uncommitted; prod's live state still has the rule, so prod no longer matches the code.
Record: .culiops/iac-change-execution/orders-remove-db-vpc-ingress-20261116-1150.md · pre-flight record: .culiops/pre-flight/orders-remove-db-vpc-ingress-20261116-1122.md
Next: commit the record (.culiops/iac-change-execution/orders-remove-db-vpc-ingress-20261116-1150.md) · draft the result or ticket-close message with change-comms
```
