# Dry-run transcript: light-escalation-alarm-action (SKILL_SOURCE: working-tree)

Runner setup (not part of the skill's output):

- Skill text read from the working tree: `skills/iac-change-execution/SKILL.md`, `skills/iac-change-execution/lanes.md`, `skills/iac-change-execution/examples/aws.md`, `skills/pre-flight/SKILL.md`, `skills/pre-flight/assessors/iac-change.md`, `skills/pre-flight/examples/aws.md`. Kubernetes examples and `app-source.md` are not used (AWS only; Q8 is answered (c), so pre-flight Step 3b never starts).
- Operator script: `operator-script.md`, matched by stop ID. Its "Answers by meaning" section is ignored (new skill, stop IDs).
- Dry-run clock: starts 2026-11-09 10:00 +07:00 (03:00Z). One minute per command, five per operator answer. A command is stamped with the clock after its minute is added.
- `CULIOPS_HOME`: no canned row reads the environment. Treated as unset (the fixture sets none), so the output root is `.culiops/` at the repo root. Assumption recorded here.
- `.culiops/` in the fixture: none exists (no catalog, no earlier pre-flight record).
- fresh-eyes (diff): see Step 3. fresh-eyes (pre-flight): the verdict is RED soft block, so the skill says it is not required. No subagent was dispatched at any point.

---

## First message (operator)

"Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one."

---

## Step 1: Research

### Commands before the first stop

| # | Time | Command | Canned file / source | Output |
|---|------|---------|----------------------|--------|
| C1 | 10:01 | `aws sts get-caller-identity` (identity read, exempt from opt-in, first live command, SKILL.md:169) | `canned/identity-prod.json` (all environments read the same; one environment, prod) | Account `333333333333`, Arn `arn:aws:sts::333333333333:assumed-role/paymentapi-operator/operator` |
| C2 | 10:02 | `git branch --show-current` | `canned/git-branch.txt` | `main` (the default branch, `origin/HEAD -> origin/main` in `git-branches.txt`) |
| C3 | 10:03 | `git grep -n -F 'paymentapi-cpu-low'` (duplicate check, code) | grep -rn -F over fixture input files | no hits |
| C4 | 10:04 | `git grep -n -F 'cpu_low'` (the forms the repo uses: `paymentapi_cpu_low`) | grep -rn -F over fixture input files | no hits |
| C5 | 10:05 | `git log --all --oneline -S'paymentapi-cpu-low'` (duplicate check, history) | `canned/empty.txt` | (no output) |
| C6 | 10:06 | `git log --all --oneline -S'cpu_low'` | `canned/empty.txt` | (no output) |
| C7 | 10:07 | `git branch -a --list '*cpu-low*'` (in flight, branches) | `canned/empty.txt` | (no output) |
| C8 | 10:08 | `gh pr list --state open --search 'cpu-low'` (in flight, PRs) | `canned/gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

No ticket was given, so there is no `git log --grep='<KEY>'` (no key to search).

### Reads the skill did in the working tree (no command lookup)

- Code read from the working tree because the current branch is the default branch `main` (SKILL.md:173): `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `envs/prod.tfvars`.
- Catalog: `.culiops/service-discovery/paymentapi.md` does not exist. The skill suggests running service-discovery first and proceeds without it.
- Environment mapping: `envs/` holds one file, `prod.tfvars` (`env = "prod"`, `envs/prod.tfvars:1`). One environment, `prod`. No staging, no dev.
- Tier proof (`lanes.md` › Environment tier): the repo pins the account. `providers.tf:16` has `allowed_account_ids = [var.aws_account_id]` and `envs/prod.tfvars:3` sets `aws_account_id = "333333333333"`. The identity account from C1 equals it, exact match. prod=prod, proven (`live:` C1, `code: envs/prod.tfvars:3`, `code: providers.tf:16`).
- Delivery model: no CI config, no `atlantis.yaml`, no `Application` / `Kustomization`, no Makefile, no `backend` or `cloud` block in `providers.tf:1-10`. Nothing in the repo shows how a change reaches prod. Delivery model = `UNVERIFIED`; it is asked inside `[F2]` (SKILL.md:188), not as its own stop.
- Environment selection: `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1`, `code: providers.tf:12-17`). Workspace: no workspace or backend is configured in code, so the default workspace; stated by the operator later (`iac-change.3`).

### Duplicate check (verdict)

- Identifiers: `paymentapi-cpu-low-prod`, `paymentapi_cpu_low`, the scale-in policy `paymentapi-scale-in-prod` / `paymentapi_scale_in`.
- `code:` no hits for `paymentapi-cpu-low` or `cpu_low` (C3, C4). The scale-in policy exists in code with no alarm: `code: main.tf:212-230` ("Scale-in policy. No alarm drives it yet."), also `main.tf:3-4`.
- `git:` no commit added or removed either identifier (C5, C6).- In flight: no branch (C7), no open PR (C8).
- Verdict: **not done**. The live read B16 later confirms the alarm is absent in prod. The existing scale-in policy is not part of the request.

### Predict the lane (SKILL.md:190, `lanes.md` › Lane rule)

- Targets: one, prod (proven prod, not dev). So not dev.
- L1 (create only): the request implies one create. L2 (allowlist): `aws_cloudwatch_metric_alarm` create is on the allowlist (`lanes.md:77`, "none (E1 checks its actions)"). L3: one phase, one environment, duplicate check not done, no drift row known yet.
- E1 on the request and the code: the request says "wired like the CPU-high one". CPU-high is wired to two actions, `code: main.tf:250-253`: `aws_sns_topic.paymentapi_alerts.arn` and `aws_appautoscaling_policy.paymentapi_scale_out.arn`. The scale-in policy exists with no alarm (`code: main.tf:212-230`). The CPU-low twin's second action therefore resolves to `aws_appautoscaling_policy.paymentapi_scale_in.arn` (`code: main.tf:213`), an Application Auto Scaling policy, not an SNS topic. **E1 hit.**
- E2, E3: not run. An E1 hit already makes the change full, and `lanes.md:100` says the full lane does not require them.
- Lane rule line 1 (an escalation is recorded) → **full**. Stops are `[F1]`–`[F4]`.

### Skill message shown to the operator

> **[F1] Run these reads?**
>
> **Output root:** `.culiops/` at the repo root (`CULIOPS_HOME` unset). Records go to `.culiops/iac-change-execution/` and `.culiops/pre-flight/`.
>
> **Identity read (run first, exempt):** `aws sts get-caller-identity` at 10:01 → account `333333333333`, `assumed-role/paymentapi-operator`. Region `ap-southeast-1` (`code: envs/prod.tfvars:2`).
>
> **Targets and tiers:** one target. `prod` = prod, proven: identity account `333333333333` equals the repo pin (`code: envs/prod.tfvars:3`, set as `allowed_account_ids` at `code: providers.tf:16`). No staging or dev environment is defined (`code: envs/` holds only `prod.tfvars`).
>
> **Lane (predicted):** full. E1: the request says "wired like the CPU-high one"; CPU-high's `alarm_actions` include a scaling policy (`code: main.tf:250-253`), and the scale-in policy has no alarm yet (`code: main.tf:212-230`), so the new alarm's actions will include `aws_appautoscaling_policy.paymentapi_scale_in.arn`, which is not an SNS topic.
>
> **Duplicate check so far:** not done. No hits in code (`git grep` for `paymentapi-cpu-low`, `cpu_low`), history (`git log -S`), branches, or open PRs. The batch below confirms the alarm is absent live.
>
> **Delivery model:** `UNVERIFIED` (no CI config, controller object or backend in the repo). I will ask inside `[F2]`.
>
> **Read batch** (all read-only; each command shown; the first two run locally or read state through the provider, the rest are AWS reads in `ap-southeast-1`, account `333333333333`):
>
> 1. `terraform init -input=false` (needed by the drift check; may update `.terraform.lock.hcl`)
> 2. `terraform plan -refresh-only -input=false -no-color -var-file=envs/prod.tfvars` (drift check, never applied)
> 3. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{status:status,desired:desiredCount,running:runningCount,pending:pendingCount,deploy:deploymentConfiguration,tg:loadBalancers[].targetGroupArn,deployments:deployments[].{status:status,rollout:rolloutState,taskDef:taskDefinition,created:createdAt},events:events[:5].{at:createdAt,msg:message}}'`
> 4. `aws elbv2 describe-target-groups --names paymentapi-tg-prod --region ap-southeast-1 --query 'TargetGroups[].{arn:TargetGroupArn,lb:LoadBalancerArns,path:HealthCheckPath}'`
> 5. `aws elbv2 describe-target-health --target-group-arn <tg-arn from #3> --region ap-southeast-1 --query 'TargetHealthDescriptions[].{ip:Target.Id,az:Target.AvailabilityZone,state:TargetHealth.State}'`
> 6. `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --start-time <now-1h> --end-time <now> --period 300 --statistics Average Maximum --region ap-southeast-1`
> 7. the same call with `--metric-name MemoryUtilization`
> 8. `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count --dimensions Name=LoadBalancer,Value=<lb id from #4> --start-time <now-1h> --end-time <now> --period 300 --statistics Sum --region ap-southeast-1`
> 9. the same call with `--metric-name TargetResponseTime --statistics Average`
> 10. the same call with `--metric-name RequestCount --statistics Sum` (last hour)
> 11. the same call as #10 for the same hour a week ago (traffic baseline)
> 12. `aws cloudwatch describe-alarms --state-value ALARM --region ap-southeast-1`
> 13. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query '{metric:MetricAlarms[].{name:AlarmName,state:StateValue,enabled:ActionsEnabled},composite:CompositeAlarms[].AlarmName}'`
> 14. `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actionsEnabled:ActionsEnabled}'`
> 15. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-high-prod --region ap-southeast-1` (the alarm to copy)
> 16. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-low-prod --region ap-southeast-1` (does the new alarm already exist?)
> 17. `aws cloudwatch describe-alarm-history --alarm-name paymentapi-cpu-high-prod --history-item-type StateUpdate --start-date <now-24h> --end-date <now> --region ap-southeast-1`
> 18. `aws application-autoscaling describe-scalable-targets --service-namespace ecs --resource-ids service/paymentapi-cluster-prod/paymentapi-svc-prod --region ap-southeast-1`
> 19. `aws application-autoscaling describe-scaling-policies --service-namespace ecs --resource-id service/paymentapi-cluster-prod/paymentapi-svc-prod --region ap-southeast-1`
> 20. `aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/paymentapi-cluster-prod/paymentapi-svc-prod --region ap-southeast-1`
> 21. `aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod --region ap-southeast-1 --query 'Subscriptions[].Protocol'` (protocols only, never endpoints)
> 22. `aws sns get-topic-attributes --topic-arn arn:aws:sns:ap-southeast-1:333333333333:paymentapi-alerts-prod --region ap-southeast-1 --query 'Attributes.{confirmed:SubscriptionsConfirmed,pending:SubscriptionsPending}'`
> 23. `aws pricing get-products --region us-east-1 --service-code AmazonCloudWatch --filters Type=TERM_MATCH,Field=regionCode,Value=ap-southeast-1 Type=TERM_MATCH,Field=alarmType,Value=Standard --max-results 1` (price of one standard alarm; lookup date recorded)
>
> Not in the batch: no state-backend `head-object` read (the code declares no backend), no RDS or backup reads (nothing stateful changes). The plan command and the success-criteria reads are approved later, at `[F3]` and `[F2]`.

**STOP 1: F1.**

### Operator answer to [F1] (script entry 1)

"Approve the read batch: every command shown, the target check included." Clock +5 min → 10:13.

### Batch run (clock 10:14 to 10:36)

| # | Time | Command (as run) | Canned file | Output / query result |
|---|------|------------------|-------------|-----------------------|
| B1 | 10:14 | `terraform init -input=false` | `terraform-init.txt` | `Terraform has been successfully initialized!` (hashicorp/aws v5.74.0 reused from the lock file) |
| B2 | 10:15 | `terraform plan -refresh-only -input=false -no-color -var-file=envs/prod.tfvars` | `plan-refresh-only-prod.txt` | `No changes. Your infrastructure still matches the configuration.` No drift. |
| B3 | 10:16 | `aws ecs describe-services ... --query '...'` | `ecs-describe-services-prod.json` (prod; the command names `paymentapi-cluster-prod`) | status ACTIVE, desired 3, running 3, pending 0. deploy: circuit breaker off, maximumPercent 200, minimumHealthyPercent 100. tg `arn:aws:elasticloadbalancing:ap-southeast-1:333333333333:targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09`. deployments: one PRIMARY, COMPLETED, `paymentapi-prod:12`, created 2026-10-12T14:02:11Z. events: 2026-11-09T01:12:40Z "(service paymentapi-svc-prod) has reached a steady state." |
| B4 | 10:17 | `aws elbv2 describe-target-groups --names paymentapi-tg-prod ...` | `tg-describe-prod.json` | lb `arn:aws:elasticloadbalancing:ap-southeast-1:333333333333:loadbalancer/app/paymentapi-alb-prod/50dc6c495c0c9188` (so LoadBalancer dimension = `app/paymentapi-alb-prod/50dc6c495c0c9188`), path `/healthz` |
| B5 | 10:18 | `aws elbv2 describe-target-health --target-group-arn arn:...targetgroup/paymentapi-tg-prod/6d0ecf831eec9f09 ...` | `tg-health-prod.json` | 3 targets, all `healthy` (10.20.12.41 ap-southeast-1a, 10.20.13.87 ap-southeast-1b, 10.20.12.203 ap-southeast-1a) |
| B6 | 10:19 | CPUUtilization, window 02:19Z-03:19Z | `metric-cpu-prod.json` | 12 datapoints, Average 37.2 to 42.8 %, Maximum up to 52.8 % |
| B7 | 10:20 | MemoryUtilization | `metric-memory-prod.json` | Average 52 to 56 %, Maximum up to 66 % |
| B8 | 10:21 | HTTPCode_Target_5XX_Count (Sum) | `metric-alb-5xx-prod.json` | Sum 0 in all 12 periods |
| B9 | 10:22 | TargetResponseTime (Average) | `metric-alb-latency-prod.json` | Average 0.036 to 0.040 s, Maximum 0.14 s |
| B10 | 10:23 | RequestCount, last hour | `metric-alb-requests-prod.json` | 3400 to 3511 requests per 5 min |
| B11 | 10:24 | RequestCount, same hour a week ago | `metric-alb-requests-prod.json` (same file per INDEX) | 3400 to 3511 per 5 min. Ratio now / week ago = 1.0 |
| B12 | 10:25 | `describe-alarms --state-value ALARM` | `alarms-firing-prod.json` | `MetricAlarms: []`, `CompositeAlarms: []`. Nothing firing |
| B13 | 10:26 | `describe-alarms --alarm-name-prefix paymentapi --query ...` | `alarms-prefix-prod.json` (before the new alarm exists) | metric: [`paymentapi-cpu-high-prod`, OK, enabled true]. composite: [] |
| B14 | 10:27 | `describe-alarms-for-metric ... CPUUtilization ... --query ...` | `alarms-for-metric-cpu-prod.json` (before) | [`paymentapi-cpu-high-prod`, OK, actionsEnabled true]. Only one alarm on this metric |
| B15 | 10:28 | `describe-alarms --alarm-names paymentapi-cpu-high-prod` | `alarm-cpu-high-prod.json` | Threshold 70.0, GreaterThanThreshold, EvaluationPeriods 3, Period 300, Statistic Average, TreatMissingData `missing`, ActionsEnabled true, StateValue OK. AlarmActions: [`...:paymentapi-alerts-prod`, `...scalingPolicy:5b1f6a1e-...:policyName/paymentapi-scale-out-prod`]. OKActions: [SNS topic]. Dimensions ClusterName `paymentapi-cluster-prod`, ServiceName `paymentapi-svc-prod` |
| B16 | 10:29 | `describe-alarms --alarm-names paymentapi-cpu-low-prod` | `alarm-cpu-low-before-prod.json` (before) | `MetricAlarms: []`. The alarm does not exist |
| B17 | 10:30 | `describe-alarm-history --alarm-name paymentapi-cpu-high-prod ...` | `alarm-history-prod.json` | 4 StateUpdate items: ALARM 2026-11-08T08:48:51Z, OK 2026-11-08T09:03:51Z; ALARM 2026-11-05T05:02:51Z, OK 2026-11-05T05:17:51Z |
| B18 | 10:31 | `describe-scalable-targets ...` | `appautoscaling-targets-prod.json` | MinCapacity 2, MaxCapacity 6, DynamicScalingInSuspended false |
| B19 | 10:32 | `describe-scaling-policies ...` | `appautoscaling-policies-prod.json` | `paymentapi-scale-out-prod`: StepScaling, +1, cooldown 300, Alarms [`paymentapi-cpu-high-prod`]. `paymentapi-scale-in-prod`: StepScaling, -1 (MetricIntervalUpperBound 0), cooldown 300, **Alarms []** |
| B20 | 10:33 | `describe-scaling-activities ...` | `appautoscaling-activities-prod.json` | one activity: 2026-11-08T08:49:02Z "Setting desired count to 3.", caused by alarm `paymentapi-cpu-high-prod` triggering `paymentapi-scale-out-prod`, Successful |
| B21 | 10:34 | `sns list-subscriptions-by-topic ... --query 'Subscriptions[].Protocol'` | `sns-subscriptions-prod.json` | `["email", "email"]` (endpoints not read) |
| B22 | 10:35 | `sns get-topic-attributes ... --query ...` | `sns-attributes-prod.json` | confirmed 2, pending 0 |
| B23 | 10:36 | `aws pricing get-products ...` | `pricing-cloudwatch-alarm.json` | CloudWatch standard alarm, ap-southeast-1, USD 0.10 per alarm metric month (standard resolution), publication 2026-10-07. Lookup date 2026-11-09 |

Environment note: the fixture has one environment, so rule 1(b) of the protocol decided every lookup: prod.

### Evidence table (Constraint 9)

| # | Fact | Code evidence | Live evidence | Match |
|---|------|---------------|---------------|-------|
| E-1 | CPU-high alarm: threshold 70, 3 x 300 s, Average, actions [SNS, scale-out policy], enabled | `code: main.tf:234-260` | `live: B15 (10:28)` same values | match |
| E-2 | `paymentapi-cpu-low-prod` does not exist | `code: none` (C3, C4 no hits) | `live: B16 (10:29)` `MetricAlarms: []` | match (absent in both) |
| E-3 | Scale-in policy exists, -1, cooldown 300, no alarm drives it | `code: main.tf:213-230`, comment `main.tf:212` | `live: B19 (10:32)` `Alarms: []` | match |
| E-4 | Scale-out policy driven by cpu-high | `code: main.tf:193-210`, `main.tf:252` | `live: B19` Alarms [cpu-high] | match |
| E-5 | Scalable target min 2, max 6 | `code: main.tf:189-190` | `live: B18 (10:31)` Min 2, Max 6, scale-in not suspended | match |
| E-6 | Service desired count 3, not pinned by Terraform | `code: envs/prod.tfvars:11` (3), `code: main.tf:93-95` (`ignore_changes = [desired_count]`) | `live: B3 (10:16)` desired 3, running 3. `live: B20` last change was a scale-out to 3 on 2026-11-08 | match |
| E-7 | Alerts topic exists; subscribers are email only | `code: main.tf:174-181` | `live: B21 (10:34)` protocols email, email; `B22` 2 confirmed | match |
| E-8 | No drift | none | `live: B2 (10:15)` refresh-only "No changes" | match |
| E-9 | Delivery model: how a merge reaches prod | `code: none` | n/a | UNVERIFIED (asked at `[F2]`) |
| E-10 | What happens to in-flight requests on a task stopped by scale-in | `code: none` | n/a | UNVERIFIED (docs lookup D3 returned no canned output) |

Drift rows: 0. Unverified rows: 2 (E-9, E-10). Rows marked `code-only`: 0 (the batch was approved in full).

---

## Step 2: Plan

### Commands

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C9 | 10:37 | `git branch --show-current` | `git-branch.txt` | `main` |
| C10 | 10:38 | `git status --short` | `git-status-clean.txt` | (no output; clean) |
| C11 | 10:39 | `git rev-parse --short origin/main` | `git-rev-parse.txt` | `a1b2c3d` |

The current branch is not this change's branch, so the plan proposes `git fetch origin main` then `git switch -c iac-change/paymentapi-cpu-low-alarm origin/main`. The repo shows no branch-name pattern (only `main`, `git-branches.txt`), so the fallback `iac-change/<service>-<short-description>` is used. Full lane: these run after `[F2]`.

### Documentation lookups

- D1, claim "an alarm action can be an Application Auto Scaling policy": canned entry found. `docs: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html` (read 2026-11-09): "Step scaling policies are triggered by CloudWatch alarms: when the alarm breaches, Application Auto Scaling changes the scalable target's capacity by the policy's step adjustment, within the target's minimum and maximum capacity." (paraphrase in the canned file)
- D2, claim "the policy cooldown limits how soon it scales again": canned entry found, same URL, read 2026-11-09: "The cooldown period of a step scaling policy limits how soon the policy can scale again after a scaling activity."
- D3, claim "ECS drains in-flight requests on a task that scale-in stops": **no canned output.** The claim stays `UNVERIFIED`, so the plan does not state the scale-in disruption as `none` (SKILL.md:235).

### Alarm details the request leaves open

The request gives no threshold and no evaluation window. SKILL.md has no rule for a parameter the request leaves open. Reading relied on: SKILL.md:229-237 (the plan names the values it will write) plus Constraint 9 (no value without evidence). The plan therefore shows the threshold and window as open and asks for them inside `[F2]`, proposing CPU-high's window (3 x 300 s, `code: main.tf:237,240`). No separate stop. See "Ambiguities" at the end.

### Plan self-check (SKILL.md:249-257)

1. Every item cites evidence (`code:` / `live:` / `docs:`); no destroy, replace or resize: pass.
2. Deletes: none, so no bundle to list: pass.
3. Rollback and success criteria written as commands with expected output: pass.
4. Drift rows acknowledged: 0 rows (E-8): pass.
5. Execution path fits the delivery model: PR is the default and fits any model; the delivery model is `UNVERIFIED` and is asked in the plan: pass.
6. Every implied file and resource is in a phase, nothing extra: `main.tf` and one alarm: pass.
7. Lane basis cited: full, E1 with `code:` evidence: pass.
8. Staging precedes prod or the exception is recorded: exception (a), no staging environment, with `code:` evidence; observation window named (n/a): pass.

Result: 8/8.

### Skill message shown to the operator (research summary, then the plan)

> **Change requested:** Add a CPU-low alarm for paymentapi in prod, wired like the CPU-high one.
> **Service:** `paymentapi` / **Instance:** `prod`
> **IaC tool(s):** Terraform (`hashicorp/aws ~> 5.0`, v5.74.0 from the lock file) · **Delivery model:** `UNVERIFIED` (no CI config, controller object or backend in the repo; asked below) · **Env selection:** `-var-file=envs/prod.tfvars` (`code: envs/prod.tfvars:1`, `code: providers.tf:12-17`); default workspace (no workspace or backend in code; to confirm in L2)
> **Target:** account `333333333333` / region `ap-southeast-1` (from `aws sts get-caller-identity`, 10:01)
> **Environment tier:** `prod=prod` (proven: account `333333333333` equals the pin `code: envs/prod.tfvars:3`) · **Lane (predicted):** `full` — E1: the new alarm's actions include a scaling policy, `code: main.tf:250-253` (pattern to copy), `code: main.tf:213` (`aws_appautoscaling_policy.paymentapi_scale_in`)
> **Catalog used:** none — proceeding without catalog (consider running service-discovery first)
> **Duplicate check:** not done — `code:` no hits for `paymentapi-cpu-low` / `cpu_low`; `git:` no `-S` hits; no branch or open PR; `live:` alarm absent (B16)
> **Evidence table:** E-1 to E-10 above — drift rows: 0, unverified rows: 2 (delivery model; scale-in drain behaviour)
> **Gaps remaining:** delivery model (asked below); alarm threshold and evaluation window (asked below); how ECS drains in-flight requests when scale-in stops a task (`UNVERIFIED`, no docs read, not relied on); last successful apply time (no state backend declared, so no `head-object` read; answered by `iac-change.4`)
>
> **Change plan for `paymentapi` / `prod`:**
>
> **Phase 1 of 1: Add the CPU-low alarm**
> - Files: `main.tf` (modify: one new resource after the CPU-high alarm, line 260)
> - Resources affected: `+ create aws_cloudwatch_metric_alarm.paymentapi_cpu_low` (alarm `paymentapi-cpu-low-prod`, `AWS/ECS` `CPUUtilization`, `ClusterName` / `ServiceName` as CPU-high, `LessThanThreshold`). 0 changed, 0 destroyed. Actions: `alarm_actions` = [alerts SNS topic, `paymentapi_scale_in` policy], `ok_actions` = [alerts SNS topic], same tags as CPU-high. **Threshold and evaluation window are open: see below.**
> - Blast radius: one new alarm in one region. Once it exists it is the first thing to drive `paymentapi-scale-in-prod` (`live: B19`, `Alarms: []`): each breach removes one task, `-1` per 300 s cooldown (`code: main.tf:222,225-228`), never below `min_capacity` 2 (`code: main.tf:189`, `live: B18`). Today 3 tasks run, 3 healthy across two AZs (`live: B3`, `B5`). `docs: step-scaling-policies (2026-11-09)`: an alarm breach changes capacity by the step adjustment within the target's min and max.
> - Disruption: applying the change itself, `none` (`plan:` will show a create only; `code: main.tf` diff adds no change to an existing resource). After it exists, a breach reduces capacity by one task at a time down to 2. Whether in-flight requests on the stopped task are drained is `UNVERIFIED` (D3, no docs read), so it is not claimed to be `none`. With CPU now at 37 to 43 % (`live: B6`) the alarm is not near its threshold.
> - Rollback path: reversible. `git revert` the commit, plan, apply through the same path; the alarm is stateless (`code: main.tf`). It does not undo a scale-in that already happened: Terraform does not own the count (`code: main.tf:93-95`), so the scale-out policy or `aws ecs update-service` restores it. `untested` (nobody has tried it).
> - Evidence: E-1 to E-8.
> - Success criteria (run after the apply lands; approving this plan approves these reads):
>   1. `aws cloudwatch describe-alarms --alarm-names paymentapi-cpu-low-prod --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue,enabled:ActionsEnabled,threshold:Threshold,periods:EvaluationPeriods,actions:AlarmActions}'` → one alarm, `enabled: true`, the approved threshold and periods, `actions` = [alerts topic ARN, `paymentapi-scale-in-prod` policy ARN], state `OK` or `INSUFFICIENT_DATA`
>   2. `aws cloudwatch describe-alarms-for-metric --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=paymentapi-cluster-prod Name=ServiceName,Value=paymentapi-svc-prod --region ap-southeast-1 --query 'MetricAlarms[].AlarmName'` → `paymentapi-cpu-high-prod` and `paymentapi-cpu-low-prod`
>   3. `aws cloudwatch describe-alarms --alarm-name-prefix paymentapi --region ap-southeast-1 --query 'MetricAlarms[].{name:AlarmName,state:StateValue}'` → both alarms, none in `ALARM`
>   4. `aws ecs describe-services --cluster paymentapi-cluster-prod --services paymentapi-svc-prod --region ap-southeast-1 --query 'services[].{desired:desiredCount,running:runningCount,pending:pendingCount}'` → desired 3, running 3, pending 0 (applying the alarm does not scale anything)
>   5. `terraform plan -var-file=envs/prod.tfvars` → `No changes.`
>
> **Execution path:** PR (default). If you want me to apply directly, say so; it escalates pre-flight (anti-pattern A4, local workstation apply). If the repo's pipeline applies on merge, PR is the only path (see the delivery-model question).
> **Staging-first (H7):** (a) no staging env — `code: envs/` holds only `prod.tfvars`; no staging var-file, workspace or overlay is defined · **Observation window:** n/a (no staging phase)
> **Branch:** current `main` → `iac-change/paymentapi-cpu-low-alarm` from `origin/main` @ `a1b2c3d` (fetch + create)
> **Self-check:** 8/8 pass
> **Drift (H4):** none (B2 refresh-only: no changes; every row E-1 to E-8 matches)
> **Alarm details (not in the request):** threshold? evaluation window? CPU-high uses 70 % over 3 x 300 s Average; I propose the same window (3 x 300 s, Average, `treat_missing_data` default as CPU-high) and need your threshold.
> **For pre-flight (L2):**
> 1. Is there an active incident affecting this service or its dependencies? (yes/no)
> 2. Is there a deploy freeze or change window restriction? (yes/no)
> 3. Will the expected apply time be in peak traffic for this service? (yes/no/unsure — for CI delivery the apply happens at merge, not now)
> 4. Have you changed this service before? (many times / a few times / first time)
> 5. Have you used this IaC tool before? (experienced / some experience / first time)
> 7. Any other context I should know? (optional)
> 8. This change touches what the app depends on: the new alarm's scaling action (it changes the task count). Where is the application source? (a) a local checkout — give the path; (b) a GitHub repo through `gh` — give `owner/repo` and the deployed ref (choosing it approves only the four `GET` reads in pre-flight); (c) not available.
> `iac-change.4`: has this stack been applied successfully recently, or has it been a while? (recent / months ago / unsure)
> **Delivery model:** `UNVERIFIED` — nothing in the repo shows how this change reaches prod. How does it get applied (CI on merge, a GitOps controller, PR-driven plan and apply, or by hand)?
>
> **[F2] Approve this plan?**

**STOP 2: F2.**

### Operator answer to [F2] (script entry 2)

Clock +5 min → 10:44.

"Approve. Q1=no, Q2=no, Q3=no, Q4=many times, Q5=experienced, Q6=negligible, Q7=none, Q8=(c) the application source is not available, iac-change.1=yes, iac-change.2=PR, and a CI pipeline applies on merge, iac-change.3=no (default workspace; the env's own var-file), iac-change.4=recent. Alarm details: threshold 20 percent, 3 periods of 5 minutes, otherwise the same as CPU-high. Delivery model: PR, and a CI pipeline applies on merge."

(Entries said as the operator would: the L2 answers, plus the two `if asked` items because the plan asked for the alarm details and the delivery model.)

Effect on the run:

- Alarm values are now: threshold 20, `evaluation_periods` 3, `period` 300, `statistic` Average, otherwise as CPU-high. These fill the open slots; they do not change the plan's shape, so the plan is approved as shown with these values.
- Delivery model: `operator-stated`, "PR, then a CI pipeline applies on merge". CI applies on merge ⇒ PR path only (SKILL.md:243). Direct apply is no longer offered. Recorded as `UNVERIFIED in repo — operator-stated`.
- Q8 = (c) ⇒ pre-flight category 11 will be unknown.
- Gap closed: delivery model, alarm values. Still open: E-10.
- No drift to acknowledge, no exception justification needed (exception (a) is automatic).

---

## Step 3: Implement

### Branch commands (approved at [F2])

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C12 | 10:45 | `git fetch origin main` | `empty.txt` | (no output) |
| C13 | 10:46 | `git switch -c iac-change/paymentapi-cpu-low-alarm origin/main` | `git-switch.txt` | `Switched to a new branch 'iac-change/paymentapi-cpu-low-alarm'` |
| C14 | 10:47 | `git branch --show-current` | `git-branch-after-switch.txt` | `iac-change/paymentapi-cpu-low-alarm` |

The branch is confirmed before any file is written.

### Code written (diff)

```diff
--- a/main.tf
+++ b/main.tf
@@ -258,3 +258,33 @@ resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_high" {
     Environment = var.env
   }
 }
+
+# ── CloudWatch alarm (CPU low, scales in) ─────────────────────────────────────
+
+resource "aws_cloudwatch_metric_alarm" "paymentapi_cpu_low" {
+  alarm_name          = "paymentapi-cpu-low-${var.env}"
+  comparison_operator = "LessThanThreshold"
+  evaluation_periods  = 3
+  metric_name         = "CPUUtilization"
+  namespace           = "AWS/ECS"
+  period              = 300
+  statistic           = "Average"
+  threshold           = 20
+  alarm_description   = "CPU utilization below 20% for paymentapi ${var.env}"
+
+  dimensions = {
+    ClusterName = aws_ecs_cluster.paymentapi.name
+    ServiceName = aws_ecs_service.paymentapi.name
+  }
+
+  alarm_actions = [
+    aws_sns_topic.paymentapi_alerts.arn,
+    aws_appautoscaling_policy.paymentapi_scale_in.arn,
+  ]
+  ok_actions = [aws_sns_topic.paymentapi_alerts.arn]
+
+  tags = {
+    Service     = "paymentapi"
+    Environment = var.env
+  }
+}
```

New lines in the working tree: `main.tf:261-290` (resource at `main.tf:264`, `alarm_actions` at `main.tf:280-283`).

Canned plan versus code: the canned plan (`plan-prod.txt`) has `alarm_name paymentapi-cpu-low-prod`, `LessThanThreshold`, 3 x 300 s Average, threshold 20, description "CPU utilization below 20% for paymentapi prod", dimensions, the same two `alarm_actions`, one `ok_action`, the two tags, and `treat_missing_data = "missing"` (provider default). It matches the code written. No difference to note.

### Formatter and diff self-check

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C15 | 10:48 | `terraform fmt main.tf` (repo formatter, changed file only; shown before running) | `empty.txt` | (no output: already formatted) |
| C16 | 10:49 | `git status --short` | answered from the diff (protocol) | ` M main.tf` |
| C17 | 10:50 | `git diff` | answered from the diff (protocol) | the diff above |

1. Scope: only `main.tf`, which is the plan's one file, and it changed: pass.
2. Plan ↔ hunk: the one create maps to the one hunk, and the hunk maps to the plan item: pass.
3. Conventions: names, attribute order, `dimensions`, tags and the `alarm_actions` shape copy `code: main.tf:234-260`; the header comment copies `code: main.tf:232` at the same width: pass.
4. No silent safety changes: no `prevent_destroy`, `deletion_protection`, `ignore_changes`, `0.0.0.0/0` or IAM `*` in the hunk. The scale-in action is named in the approved plan: pass.
5. No secrets; `git status --short` lists only `main.tf` (`tfplan`, `.terraform/` are not in the tree status): pass.
6. Formatted: `terraform fmt` printed nothing: pass.

Result: 6/6.

E1 on the diff (the lane is already full, so this is a confirmation): `alarm_actions[0]` = `aws_sns_topic.paymentapi_alerts.arn` (`code: main.tf:174`, an SNS topic: ok); `alarm_actions[1]` = `aws_appautoscaling_policy.paymentapi_scale_in.arn` (`code: main.tf:213`, `aws_appautoscaling_policy`, not an SNS topic): **hit confirmed**; `ok_actions[0]` = the SNS topic: ok.

### Fresh eyes

Skip rule (SKILL.md:310): the phase is add-only (1 create, 0 change, 0 destroy) and touches none of access control, network exposure, DNS, data stores, secrets / KMS / encryption, or deletion-protection / lifecycle settings. "An example is adding an alarm." All the listed conditions hold, so the skill does not run a reviewer: `Fresh eyes: skipped — add-only, no sensitive types`. No reviewer is dispatched, so no `fresh-eyes: not run — dry run` line applies here. (Ambiguity: "If unsure, run it", see the end.)

### Skill message shown to the operator

> **Code changes for Phase 1 of 1:**
>
> **Modified:** `main.tf` — adds `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` after the CPU-high alarm (alarm `paymentapi-cpu-low-prod`, threshold 20, 3 x 300 s Average, actions: alerts topic + scale-in policy)
>
> **Plan ↔ hunk:** create `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` → `main.tf` `@@ -258,3 +258,33 @@` (new lines 261-290)
> **Self-check:** 6/6 pass · **Fresh eyes:** skipped — add-only, no sensitive types
> **Target:** `aws sts get-caller-identity` → account `333333333333` / `assumed-role/paymentapi-operator` / `ap-southeast-1` (10:01) · `-var-file=envs/prod.tfvars`, default workspace · tier `prod=prod`
> **Plan command (4a):** `terraform plan -out=tfplan -var-file=envs/prod.tfvars` (read-only against the cloud, uses the credentials above). `terraform init` already ran in the `[F1]` batch and the diff adds no provider or module, so it does not run again. Prod's plan runs on this approval (no staging).
>
> Full diff is in your working tree (`git diff` to review).
> **[F3] Approve these changes and the plan command?**

**STOP 3: F3.**

### Operator answer to [F3] (script entry 3)

"Approve the code." Clock +5 min → 10:55.

---

## Step 4: Execute

### 4a: Plan output

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C18 | 10:56 | `aws sts get-caller-identity` (target re-check, no stop) | `identity-prod.json` | account `333333333333`, `assumed-role/paymentapi-operator` |
| C19 | 10:57 | `terraform plan -out=tfplan -var-file=envs/prod.tfvars` | `plan-prod.txt` (before the simulated apply) | `Plan: 1 to add, 0 to change, 0 to destroy.` — create `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` |

Target re-check: C18 account `333333333333` equals the pin `code: envs/prod.tfvars:3`; var-file `envs/prod.tfvars` is the one read from the code; workspace default (operator-stated). Match, so the plan ran. No `[H1]`.

Plan text (summary only; the plan text itself is not stored): one create. `alarm_actions[0]` is the `paymentapi-alerts-prod` SNS ARN, `alarm_actions[1]` is the `paymentapi-scale-in-prod` scaling policy ARN. `ok_actions` is the SNS topic. Threshold 20, 3 x 300 s Average, tags `Environment=prod`, `Service=paymentapi`. No output changes. No "Objects have changed" block.

Cross-check against the evidence table: the only resource touched is the one in the approved phase. Its action (create) matches the approved disruption (`none` at apply). No destroy, no replace, no unnamed change, no drift: no `[H3]`, no `[H4]`, no revision.

Lane confirmation: the lane was full from Step 1 (E1) and never goes down. E1 on the plan: `alarm_actions[1]` is a known value that is not an SNS ARN (`arn:aws:autoscaling:...:policyName/paymentapi-scale-in-prod`), so the E1 hit is confirmed by `plan:` evidence. L1 to L3 would hold, L4 fails. No `plan-confirm` entry is needed because the lane was already recorded as full.

Parity check (H3): no staging phase ran (exception (a)), so `Parity check: n/a`.

### 4b: Pre-flight (H9)

Reusable record check: `.culiops/pre-flight/` does not exist in the fixture. No match. Pre-flight runs inline.

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C20 | 10:58 | `terraform show -no-color tfplan` (plan text for the hash and for pre-flight) | `plan-prod.txt` | the plan text above |
| C21 | 10:59 | `sha256sum <scratch plan file outside the repo>` | INDEX "Plan hashes" | `sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0` (scratch file deleted) |

Caller block passed to pre-flight (every field filled):

```
### Caller context (iac-change-execution)
Target: account 333333333333 / ap-southeast-1 | Terraform var-file envs/prod.tfvars, default workspace (operator-stated), no backend key declared
Delivery model: PR, then a CI pipeline applies on merge (UNVERIFIED in the repo — operator-stated: "PR, and a CI pipeline applies on merge")
Lane: full — E1: alarm_actions[1] is aws_appautoscaling_policy.paymentapi_scale_in.arn, not an SNS topic (code: main.tf:213, main.tf:250-253; plan: aws_cloudwatch_metric_alarm.paymentapi_cpu_low alarm_actions[1])
Plan hash: sha256:b59dde28d77c1abb738f01ef954c9e6686242ced73666210b4c2b990925116b0 (terraform show -no-color tfplan)
L2 answers: Q1=no Q2=no Q3=no Q4=many times Q5=experienced Q6=negligible Q7=none Q8=(c) iac-change.1=yes iac-change.2=PR; a CI pipeline applies on merge (operator-stated) iac-change.3=no (default workspace; the env's own var-file) iac-change.4=recent
Live results:
  aws sts get-caller-identity · 10:56 · account 333333333333, assumed-role/paymentapi-operator, matches Target
  terraform plan -refresh-only -var-file=envs/prod.tfvars · 10:15 · No changes (no drift)
  aws ecs describe-services (prod service) · 10:16 · ACTIVE, desired 3 / running 3 / pending 0, min healthy 100 %, max 200 %, circuit breaker off, last deployment 2026-10-12 COMPLETED, steady state 2026-11-09T01:12Z
  aws elbv2 describe-target-groups --names paymentapi-tg-prod · 10:17 · behind paymentapi-alb-prod (internal), health path /healthz
  aws elbv2 describe-target-health · 10:18 · 3 of 3 targets healthy (1a, 1b, 1a)
  CPUUtilization (AWS/ECS, 1h, 5 min) · 10:19 · Average 37.2-42.8 %, Maximum 52.8 %
  MemoryUtilization (AWS/ECS, 1h, 5 min) · 10:20 · Average 52-56 %, Maximum 66 %
  HTTPCode_Target_5XX_Count (1h, 5 min) · 10:21 · Sum 0 in all 12 periods
  TargetResponseTime (1h, 5 min) · 10:22 · Average 36-40 ms, Maximum 140 ms
  RequestCount (last hour) · 10:23 · 3400-3511 per 5 min
  RequestCount (same hour a week ago) · 10:24 · 3400-3511 per 5 min, ratio 1.0
  describe-alarms --state-value ALARM · 10:25 · none firing
  describe-alarms --alarm-name-prefix paymentapi · 10:26 · one alarm (paymentapi-cpu-high-prod, OK, enabled), no composite alarms
  describe-alarms-for-metric (CPUUtilization, this service) · 10:27 · only paymentapi-cpu-high-prod
  describe-alarms --alarm-names paymentapi-cpu-high-prod · 10:28 · 70 %, 3 x 300 s, actions SNS + scale-out policy, enabled, OK
  describe-alarms --alarm-names paymentapi-cpu-low-prod · 10:29 · does not exist
  describe-alarm-history (cpu-high) · 10:30 · ALARM 2026-11-08T08:48:51Z to OK 09:03:51Z; ALARM 2026-11-05T05:02:51Z to OK 05:17:51Z
  describe-scalable-targets · 10:31 · min 2, max 6, scale-in not suspended
  describe-scaling-policies · 10:32 · scale-out (+1, cooldown 300) driven by cpu-high; scale-in (-1, cooldown 300) has no alarm
  describe-scaling-activities · 10:33 · last: 2026-11-08T08:49:02Z scale-out to 3 by cpu-high, Successful
  sns list-subscriptions-by-topic (protocols) · 10:34 · email, email
  sns get-topic-attributes · 10:35 · 2 confirmed, 0 pending
  aws pricing get-products (CloudWatch standard alarm, ap-southeast-1) · 10:36 · USD 0.10 per alarm metric month, publication 2026-10-07, looked up 2026-11-09
Evidence table: E-1 to E-8 match code and live (drift rows: 0). E-9 delivery model: UNVERIFIED in the repo, operator-stated. E-10 task drain on scale-in: UNVERIFIED. Rows marked code-only: none. No staging evidence (no staging phase).
```

### Pre-flight, inline mode (skills/pre-flight/SKILL.md)

**Step 1.** Unsupported-stack check: Terraform on AWS, supported. Assessor `iac-change` matches (Terraform plan text with a `Plan:` line). Target, delivery model and plan hash are taken from the caller block; GATE 1 is skipped (inline). Detection shown without a stop: "Terraform plan, 1 create (`aws_cloudwatch_metric_alarm.paymentapi_cpu_low`) in account 333333333333 / ap-southeast-1, delivered by a CI pipeline on merge (operator-stated), assessor `iac-change`."

**Target check (inline: no stop, even though no other read is needed).**

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C22 | 11:00 | `aws sts get-caller-identity --query Account --output text` | `identity-prod.json` | `333333333333`; equals the caller's `Target:` account: continue |

**Step 2: L1.** Commands:

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C23 | 11:01 | `git log --since=7.days --oneline origin/main -- main.tf` (change velocity) | `empty.txt` | (no output) |
| C24 | 11:02 | `gh pr list --state open` (stacked changes: open PRs touching the same files) | `gh-pr-list-empty.txt` | `no pull requests match your search in acme/paymentapi-infra` |

Uncommitted changes to the same file: only this change's own (`git status --short` at C16: ` M main.tf`), excluded.

Changed attributes marked app-facing or not (assessor `### Application compatibility`): the alarm is not notify-only. `alarm_actions[1]` is an Application Auto Scaling policy, and "an alarm action that scales ... changes the system, so that alarm is app-facing". The SNS action alone would be notify-only (B21: protocols are all email), but the scaling action makes the alarm app-facing. Category 11 is triggered.

**Step 3: L2.** Inline: ask only what the caller block lacks. The block holds Q1-Q5, Q7, Q6 (cost is scored from the plan and the price lookup, so Q6 is not needed), Q8, and `iac-change.1` to `.4`. Q1 is no, so there is no Incident Context follow-up. Nothing is missing: **no L2 stop.**

**Step 3b: app source.** Q8 = (c): not available. Category 11 is unknown. No source is read.

**Step 4: L3.** Inline: the caller's `Live results:` are cited as `live: <cmd> (caller, <time>)`. Reads the assessor's L3 table asks for, checked against the caller's results: resource health (B3, B5 to B9, B12), blast radius softeners (B3 deployment settings, B18 min / max), dependency impact and observability (B13 to B16, B19), timing (B10, B11), change velocity (B3 deployments, B20), cost (B23), application compatibility, notify-only check (B21). Reversibility reads: not applicable, nothing stateful changes. The only read that cannot be made is the state-backend `head-object` for the last apply: no backend is declared in `code: providers.tf:1-10`, so the last-apply time rests on `iac-change.4=recent` (`operator-stated`) and `live: B3` (last ECS deployment 2026-10-12, 28 days). Nothing is missing that a batch could fetch: **no L3 stop.**

**Step 5: score.**

| # | Category | Score | Basis |
|---|----------|-------|-------|
| 1 | Blast radius | Yellow | first alarm to drive scale-in; capacity can fall from 3 to 2 tasks (assessor: capacity reduction is at least Yellow); disruption on stop not established |
| 2 | Reversibility | Green | create only, revert + plan + apply; stateless |
| 3 | Change velocity | Green | no commit in 7 days; no open PR; last ECS deployment 28 days ago |
| 4 | Dependency impact | Green | new resource, nothing consumes it |
| 5 | Timing context | Green | Q1 no, Q2 no; Q3 no cross-checked live (ratio 1.0) |
| 6 | Operator familiarity | Green | Q4 many times, Q5 experienced |
| 7 | Observability readiness | Yellow | static CPU thresholds only; no SLO, dashboard, 5xx or latency alarm |
| 8 | Cost impact | Green | one standard alarm, USD 0.10 per month, priced 2026-11-09 |
| 9 | Security posture | Green | no IAM, network, encryption or secret change |
| 10 | Resource health | Green | live signals nominal |
| 11 | Application compatibility | Unknown | app-facing (scaling action), no app source (Q8 = c) |

Hard-block conditions checked: category 2 (no irreversible data change), 5 (Q1 no and Q2 no, so no incident + freeze), 9 (no public exposure, encryption removal or secret), 10 (no error budget; nothing firing): none triggered. Yellow + unknown = 3 (categories 1, 7, 11) → multi-Yellow escalation → **RED — soft block.**

**Step 5b: verify.**

- Citation check: re-opened the cited lines for categories 1, 2, 4, 7, 9, 10 and 11: `plan:` line `Plan: 1 to add, 0 to change, 0 to destroy.`; `code: main.tf:189`, `main.tf:213-230`, `main.tf:93-95`; B3, B5, B13, B14, B15, B16, B18, B19. All support their findings. One fix: category 4 first rested on B12 for "no composite alarm", but B12 lists only alarms in `ALARM` state, so composites in other states are not shown. The citation was changed to B13 (all alarms with the prefix, `composite: []`) plus `live: B16` (the new alarm does not exist yet) and `code:` (no references). Citations checked: 22 (fixed: 1).
- Source conflicts: none between catalog, code and live. (No catalog.)
- Verdict arithmetic: Red = none; Yellow + unknown = 3 (1, 7, 11); hard blocks checked: 2, 5, 9, 10, none → RED — soft block.
- Fresh eyes: not required (verdict RED — soft block). No reviewer dispatched.
- Not verified: delivery model (operator-stated); Q3 (operator-stated, supported by B10 / B11); last apply time (`iac-change.4=recent`, operator-stated; no state backend declared); how ECS drains in-flight requests when scale-in stops a task (D3, no docs read, not relied on); how the app handles a stopped task (no source); alarm threshold and window (operator-supplied); whether someone is on hand at the merge time (not asked).

**Step 6: report presented to the operator, ending in the inline GATE 2, which is `[H5]`.**

> **Pre-flight report: `paymentapi` / `prod`, add CPU-low alarm.** Mode: inline (caller: iac-change-execution). Assessor: `iac-change`. Layers: L1 + L2 + L3 (caller's reads and the target check). Plan hash `sha256:b59dde28...116b0`. Output root `.culiops/`.
>
> **Verdict: RED — soft block** (no Red category; 3 Yellow or unknown categories escalate to RED).
>
> | # | Category | Score | Finding | Evidence |
> |---|----------|-------|---------|----------|
> | 1 | Blast radius | YELLOW | One create, but its second action is the scale-in policy, which nothing drives today. Capacity can fall 3 → 2 tasks, one task per 300 s, floor `min_capacity` 2. Whether in-flight requests on the stopped task are drained is not established (so disruption is not `none`). | `plan: Plan: 1 to add, 0 to change, 0 to destroy`; `code: main.tf:189,213-230`; `live: B3, B5, B18, B19`; `docs: step-scaling-policies (2026-11-09)`; `assessor: Blast radius, capacity reductions` |
> | 2 | Reversibility | GREEN | Create only; `git revert` + plan + apply removes it. Does not undo a scale-in that already ran; Terraform does not own the count. | `plan: 1 to add`; `code: main.tf:93-95`; `assessor: rollback, Terraform` |
> | 3 | Change velocity | GREEN | 0 commits on `main.tf` in 7 days; no open PR; last ECS deployment 2026-10-12 (28 days). | `git: log --since=7.days empty (C23)`; `gh pr list --state open (C24)`; `live: B3`; `operator-stated: iac-change.4=recent` |
> | 4 | Dependency impact | GREEN | The alarm is new, so nothing consumes it: no reference in code, no output or export changes, no composite alarm with this prefix. | `code: grep cpu_low none (C4)`; `plan: no output change`; `live: B13, B16` |
> | 5 | Timing context | GREEN | Q1 no, Q2 no; Q3 no, and live traffic equals the same hour last week (ratio 1.0, below 1.5x). | `operator: Q1, Q2`; `operator-stated + live: Q3, B10, B11` |
> | 6 | Operator familiarity | GREEN | Many times with this service, experienced with Terraform. | `operator: Q4, Q5` |
> | 7 | Observability readiness | YELLOW | CPU-high is live and enabled, and the new alarm adds a CPU-low, but both are static thresholds on one metric. No SLO, no dashboard, and no 5xx or latency alarm would catch under-capacity after a scale-in. | `code: main.tf (no dashboard or SLO resource)`; `live: B13, B14, B15`; `assessor: Observability readiness, static threshold` |
> | 8 | Cost impact | GREEN | One standard alarm, USD 0.10 per alarm metric month in ap-southeast-1. Scale-in would lower task-hours. | `live: B23 (pricing lookup 2026-11-09, publication 2026-10-07)`; `operator: Q6` |
> | 9 | Security posture | GREEN | No IAM, network, encryption, audit or secret change. | `plan: 1 add, alarm only`; `code: diff` |
> | 10 | Resource health | GREEN | 3/3 running, 3/3 healthy, steady state, nothing firing; CPU 37-43 %, memory 52-56 % (both under 70 %); target 5xx 0; latency 36-40 ms. | `live: B3, B5, B6, B7, B8, B9, B12` |
> | 11 | Application compatibility | UNKNOWN | The alarm has a scaling action, so it is app-facing (the SNS action alone would be notify-only: B21 protocols are all email). No app source (Q8 = c). If the app mishandles a stopped task, health checks and alarms will stay green. | `plan: alarm_actions[1] scaling policy`; `live: B21`; `assessor: Application compatibility`; `operator: Q8` |
>
> **Drift rows:** none.
>
> **Verification:** citations checked 22 (fixed: 1, category 4 composite-alarm claim moved from B12 to B13); verdict working: Red = none, Yellow + unknown = 3 (1, 7, 11), hard blocks checked 2, 5, 9, 10: none → RED — soft block; fresh eyes: not required (verdict RED — soft block); not verified: delivery model, Q3, last apply time, scale-in drain behaviour, app shutdown handling, alarm threshold and window, responders on hand at merge time.
>
> **Findings, mitigations (operator actions; pre-flight runs none of them):**
> 1. **Blast radius (YELLOW).** Found: first alarm that drives scale-in; 3 → 2 tasks possible (`live: B18, B19`). Why it matters: a payments service loses a task and its in-flight requests whenever CPU stays under 20 % for 15 minutes, and drain behaviour is unverified. Mitigation: after the apply lands, watch desired / running count and target health for the first scale-in; scale-in can stop at 2 tasks at most (min 2), and the scale-out policy (+1) is unchanged.
> 2. **Observability readiness (YELLOW).** Found: only CPU static-threshold alarms. Why: if scale-in leaves too little capacity, nothing but CPU-high reacts, and only after the fact. Mitigation: after the apply, confirm the new alarm leaves `INSUFFICIENT_DATA`; consider a separate change adding an ALB 5xx or latency alarm.
> 3. **Application compatibility (UNKNOWN).** Found: no app source (Q8 = c). Why: whether the app drains in-flight work on SIGTERM decides whether a scale-in drops requests silently. Mitigation (evidence that would resolve it): give pre-flight a local checkout or the deployed ref (Q8 a or b), or accept that this stays unknown.
>
> **[H5] RED — soft block. Acknowledge each finding (1, 2, 3) with a reason, or abort?**

**STOP 4: H5.**

### Operator answer to [H5] (script entry 5)

Clock +5 min → 11:07.

"Acknowledge each Red finding, reason: 'scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged'." Applied to findings 1, 2 and 3 as the stated reason for each. The operator gave no mitigation commitments, so the record shows none committed.

Pre-flight Step 7: record written to `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1107.md` (shown in `preflight-record.md`). The report, the verdict and the acknowledgements go back to the caller.

### 4c: Execute (PR path)

H7 before `[F4]` (the mutation, a PR whose merge applies prod): no staging environment, exception (a) is recorded with its evidence. No `[H7]`.

Delivery: CI applies on merge (operator-stated) ⇒ PR path only. No direct apply is offered.

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C25 | 11:08 | `git add main.tf` (explicit path, so the prompt can show the status after staging, SKILL.md:388) | `empty.txt` | (no output) |
| C26 | 11:09 | `git status --short` | answered from the diff (protocol) | `M  main.tf` |

> **[F4] Open the PR?** On branch `iac-change/paymentapi-cpu-low-alarm` (from `origin/main` @ `a1b2c3d`), about to stage **only** these files: `main.tf`, commit, push, and open a PR.
> `git status` after staging: `M  main.tf` — no `tfplan` / state / `.terraform/` / unrelated files.
> Target: account `333333333333` / `ap-southeast-1`, re-checked at 10:56 (and again by pre-flight at 11:00) · `-var-file=envs/prod.tfvars`
> **Plan output:** `Plan: 1 to add, 0 to change, 0 to destroy`: create `aws_cloudwatch_metric_alarm.paymentapi_cpu_low`; `sha256:b59dde28...116b0`
> **Pre-flight verdict:** RED — soft block, acknowledged at `[H5]` (operator, 11:07): "scale-in is bounded by min_capacity 2 and the scale-out policy is unchanged". Findings: Blast radius YELLOW (first alarm driving scale-in, 3 → 2 tasks, floor 2); Observability readiness YELLOW (static CPU thresholds only); Application compatibility UNKNOWN (no app source). Mitigations: watch the first scale-in; confirm the alarm leaves `INSUFFICIENT_DATA`; consider an ALB 5xx / latency alarm in a separate change; give the app source to resolve category 11.
> PR will include: change summary, evidence table, pre-flight verdict, the `Staging-first:` line (`n/a — no staging env (code: envs/ holds only prod.tfvars)`), execution record link.
> *Heads-up: say so and I draft one for the payments on-call and reviewers with `change-comms` (draft-only; you send it).*

**STOP 5: F4.**

### Operator answer to [F4] (script entry 4)

Clock +5 min → 11:14.

"Approve: open the PR. Approving also acknowledges a YELLOW verdict, if one is shown." The verdict shown is RED, already acknowledged at `[H5]`; no YELLOW to acknowledge. The optional heads-up line is skipped (the operator says nothing about it).

### PR path commands

| # | Time | Command | Canned file | Output |
|---|------|---------|-------------|--------|
| C27 | 11:15 | `git commit -m "paymentapi: add cpu-low alarm wired to scale-in policy"` (style of `git-log-recent.txt`: `paymentapi: <lowercase summary>`) | `git-commit.txt` | `[iac-change/paymentapi-cpu-low-alarm 7f3a9c1] paymentapi: add cpu-low alarm wired to scale-in policy` / ` 1 file changed, 30 insertions(+), 0 deletions(-)` |
| C28 | 11:16 | `git push -u origin iac-change/paymentapi-cpu-low-alarm` | `git-push.txt` | `remote: Create a pull request for 'iac-change/paymentapi-cpu-low-alarm' on GitHub by visiting:` / `remote:   https://github.com/acme/paymentapi-infra/pull/new/iac-change/paymentapi-cpu-low-alarm` / `To github.com:acme/paymentapi-infra.git` / ` * [new branch]      iac-change/paymentapi-cpu-low-alarm -> iac-change/paymentapi-cpu-low-alarm` |
| C29 | 11:17 | `gh pr create --title "paymentapi: add cpu-low alarm wired to scale-in policy" --body <summary, evidence table, pre-flight verdict, Staging-first line, record link>` (no PR template in the repo) | `gh-pr-create.txt` | `https://github.com/acme/paymentapi-infra/pull/142` |

PR body carries: `**Staging-first:** n/a — no staging env (code: envs/ holds only prod.tfvars)`; the pre-flight verdict line (RED — soft block, acknowledged at `[H5]`); the plan summary and hash; the record path `.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1117.md` (local, uncommitted). `tfplan` and `.terraform/` are not in the PR.

---

## Step 5: Verify and record

### 5a

PR path, CI applies on merge (operator-stated). Message to the operator: "PR https://github.com/acme/paymentapi-infra/pull/142 created. After merge, the CI pipeline applies it." The operator has not said an apply landed, so the success criteria are not run (no new read needs approval) and nothing is verified: `Applied: no — PR open`.

### 5b

Execution record written to `.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1117.md` (shown in `record.md`).

### Final message

> Outcome: PR opened, not applied. PR https://github.com/acme/paymentapi-infra/pull/142 adds `aws_cloudwatch_metric_alarm.paymentapi_cpu_low` (alarm `paymentapi-cpu-low-prod`, below 20 % for 3 x 5 minutes, actions: alerts topic + scale-in policy). Lane full (E1). Pre-flight RED — soft block, acknowledged at `[H5]`. The execution record is `.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1117.md`; the pre-flight record is `.culiops/pre-flight/paymentapi-add-cpu-low-alarm-20261109-1107.md`.
>
> Next: commit the record (.culiops/iac-change-execution/paymentapi-add-cpu-low-alarm-20261109-1117.md) · draft the result or ticket-close message with change-comms · tell me when the apply lands and I run the success criteria

End of run.

---

## Ambiguities in the skill text and the reading taken

1. **Lane prediction at Step 1 (SKILL.md:190).** The request says "wired like the CPU-high one" but not which actions. The E1 hit rests on the request plus `code: main.tf:250-253` and `main.tf:212-230`. Taken: predict full at Step 1, which makes `[F1]` the first stop. The diff (Step 3) and the plan (4a) confirm the hit with `code:` and `plan:` evidence.
2. **Research summary with `[F1]` or `[F2]` (SKILL.md:199, 217).** The full-lane read batch is `[F1]` and runs before Step 2, but the summary needs its live results and "is shown with the lane's next stop (`[F2]`)". Taken: `[F1]` shows the output root, identity, tiers, predicted lane and batch; the full summary goes with `[F2]`.
3. **A parameter the request leaves open (threshold, window).** No line covers it. Taken: ask inside `[F2]` (SKILL.md:229-237, Constraint 9), no extra stop. The operator's `[F2]` answer both supplies the values and approves.
4. **Fresh eyes on the diff (SKILL.md:309-310).** The skip list (add-only, none of the sensitive types) holds, and its example is "adding an alarm". "If unsure, run it" pulls the other way because this alarm's action reduces capacity, which is not on the list. Taken: skip, recorded `skipped — add-only, no sensitive types`. If the other reading is wanted, the dry run would record `fresh-eyes: not run — dry run` at `[F3]`.
5. **`git status` after staging in the `[F4]` prompt (SKILL.md:388 vs 391).** Step 2 of the PR path shows the status "after staging" in the prompt, but step 3 stages "on approval". Taken: stage with `git add main.tf` just before the prompt so the shown status is real (C25, C26), then commit on approval. Staging is local and reversible.
6. **E2 and E3 not run.** `lanes.md:100` says the full lane does not require them, and the E1 hit makes the lane full at Step 1.
7. **`terraform init` in the `[F1]` batch (SKILL.md:349).** The refresh-only drift check needs an initialised directory, so init is listed in the batch with its lock-file note. At 4a it is not repeated because no provider or module changed.
8. **`terraform validate` is not run.** SKILL.md:333 allows only the formatter by name, so only `terraform fmt` ran (C15). The canned `terraform-validate.txt` was not used.
9. **`no canned output`:** one documentation lookup (D3, ECS scale-in drain behaviour). No command lookup failed.
