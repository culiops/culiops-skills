# Examples: AWS CLI Templates for `iac-change-execution`

Reference command templates for the `iac-change-execution` skill when the target infrastructure is AWS. The skill reads this file during Step 1 (Research gap-filling), Step 4c (Apply), and Step 5a (Verification), and for the health snapshot (S0 with the Step 1 batch, S1 before each apply, S2 after it).

Replace placeholders (`{cluster}`, `{service}`, `{region}`, `{T-1h}`, `{now}`, etc.) with the values resolved in Step 1 research or detected from the plan output.

## Prerequisites

**CLI tool:** AWS CLI v2 (`aws --version` >= 2.x).

**Authentication:** any of — named profile (`--profile` or `AWS_PROFILE`), AWS SSO (`aws sso login`), IAM role, or STS temporary credentials. Confirm identity: `aws sts get-caller-identity`.

**Least-privilege IAM — TWO tiers are required for this skill.**

- **Tier 1 (Steps 1 and 5 — read-only):** AWS-managed `ReadOnlyAccess`, or a scoped custom policy allowing `Describe*`, `List*`, `Get*` on relevant resource types, plus `cloudwatch:GetMetricStatistics`, `cloudwatch:GetMetricData`, `cloudwatch:DescribeAlarms` (scoped to `*`: composite alarms are visible only then), `logs:FilterLogEvents`. The health snapshot's `head-object` on the Terraform state object also needs `s3:GetObject` on that one key. IAM cannot separate it from reading the state, so the guard is the "never read the state" rule in Health Snapshot › Automation lag, not the role. Never use `PowerUserAccess` or `AdministratorAccess` for read-only operations.
  - `docs: https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/describe-alarms.html (read 2026-11-18)`: "You can’t return information about composite alarms if your `cloudwatch:DescribeAlarms` permission has a narrower scope."
  - `docs: https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html (read 2026-11-18)`: "To use `HEAD`, you must have the `s3:GetObject` permission."
- **Tier 2 (Step 4 — mutation only):** the minimum role that permits the specific mutation — e.g., `ecs:UpdateService` on the target service, or `lambda:UpdateFunctionCode` only on the target function ARN. Elevated permissions must be assumed immediately before the mutation and dropped after. Never hold an elevated session while running read-only queries.

**Cost awareness:** CloudWatch `GetMetric*` and `logs:FilterLogEvents` incur small per-call and per-GB-scanned charges. `GetMetricData` is billed by the number of metrics requested. `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-classic-getdata.html (read 2026-11-18)`: "$0.01 per 1,000 metrics requested through `GetMetricData`." A 60-query snapshot file is about $0.0006 per call (arithmetic from that price, not measured).

---

## Research Queries (Step 1 — Read-Only)

### ECS — current service state

- Service status and configuration: `aws ecs describe-services --cluster {cluster} --services {service} --region {region}`
- Running vs desired tasks: `aws ecs describe-services --cluster {cluster} --services {service} --query 'services[].{desired:desiredCount,running:runningCount,pending:pendingCount}' --region {region}`
- Current task definition: `aws ecs describe-services --cluster {cluster} --services {service} --query 'services[].taskDefinition' --region {region}`
- Recent deployments: `aws ecs describe-services --cluster {cluster} --services {service} --query 'services[].deployments' --region {region}`

### RDS / Aurora — current instance state

- Instance status and class: `aws rds describe-db-instances --db-instance-identifier {instance} --region {region}`
- Cluster status: `aws rds describe-db-clusters --db-cluster-identifier {cluster} --region {region}`
- Pending modifications: `aws rds describe-db-instances --db-instance-identifier {instance} --query 'DBInstances[].PendingModifiedValues' --region {region}`
- Parameter group: `aws rds describe-db-instances --db-instance-identifier {instance} --query 'DBInstances[].DBParameterGroups' --region {region}`

### Lambda — current function state

- Function configuration (avoid `get-function` / unfiltered `get-function-configuration`: both return environment variable **values**, which often hold secrets): `aws lambda get-function-configuration --function-name {function} --query '{Runtime:Runtime,Handler:Handler,MemorySize:MemorySize,Timeout:Timeout,Role:Role,Layers:Layers[].Arn}' --region {region}`
- Function state and last modified: `aws lambda get-function-configuration --function-name {function} --query '{State:State,LastModified:LastModified,Runtime:Runtime,MemorySize:MemorySize,Timeout:Timeout}' --region {region}`
- Current environment variables (names only, not values): `aws lambda get-function-configuration --function-name {function} --query 'keys(Environment.Variables)' --region {region}`
- Aliases and routing config: `aws lambda list-aliases --function-name {function} --region {region}`

### EC2 — current instance state

- Instance details: `aws ec2 describe-instances --instance-ids {instance} --region {region}`
- Instance type and state: `aws ec2 describe-instances --instance-ids {instance} --query 'Reservations[].Instances[].{Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone}' --region {region}`

### ALB / Security Groups — current config

- Load balancer details: `aws elbv2 describe-load-balancers --names {lb-name} --region {region}`
- Listener rules: `aws elbv2 describe-rules --listener-arn {listener-arn} --region {region}`
- Security group rules: `aws ec2 describe-security-groups --group-ids {sg-id} --region {region}`

### Parameter Store and Secrets Manager — names only, never content

- List parameters by path (names only): `aws ssm get-parameters-by-path --path {/service/env/} --query 'Parameters[].Name' --region {region}`
- Describe a specific parameter (metadata only): `aws ssm describe-parameters --filters "Key=Name,Values={parameter-name}" --region {region}`
- List secrets (names only): `aws secretsmanager list-secrets --query 'SecretList[].{Name:Name,LastChanged:LastChangedDate}' --region {region}`

**Never retrieve secret values or parameter values during research.** If the change requires knowing a value, ask the operator to provide it.

### Resource ownership (before any import — who owns this resource today?)

Detect the *current* owner before importing, to avoid the dual-ownership drift trap:
- Terraform: `terraform state list | grep {resource}` (and check other workspaces/state files).
- CloudFormation: `aws cloudformation describe-stack-resources --physical-resource-id {id} --region {region}` — if this returns a stack, the resource is CFN-owned.
- Serverless Framework: look for a `serverless.yml` / a CFN stack named `{service}-{stage}` that includes the resource.
- If an *active* CFN / Serverless stack owns it, STOP — have that owner relinquish (remove with a `DeletionPolicy: Retain` / equivalent) before importing into Terraform.

---

## Verification Checks (Step 5 — Read-Only)

### ECS — post-apply health

- Running vs desired (expect parity): `aws ecs describe-services --cluster {cluster} --services {service} --query 'services[].{desired:desiredCount,running:runningCount,pending:pendingCount}' --region {region}`
- Deployment state (expect PRIMARY only): `aws ecs describe-services --cluster {cluster} --services {service} --query 'services[].deployments[].{status:status,running:runningCount,desired:desiredCount}' --region {region}`
- CPU utilization (last 15m, expect within baseline): `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value={cluster} Name=ServiceName,Value={service} --start-time {T-15m} --end-time {now} --period 60 --statistics Average Maximum --region {region}`

### RDS / Aurora — post-apply health

- Instance status (expect `available`): `aws rds describe-db-instances --db-instance-identifier {instance} --query 'DBInstances[].DBInstanceStatus' --region {region}`
- Pending modifications (expect empty after apply): `aws rds describe-db-instances --db-instance-identifier {instance} --query 'DBInstances[].PendingModifiedValues' --region {region}`
- Parameter group status (expect `in-sync`): `aws rds describe-db-instances --db-instance-identifier {instance} --query 'DBInstances[].DBParameterGroups' --region {region}`

### CloudWatch Alarms — alarm state check

- Alarms in ALARM state for the service: `aws cloudwatch describe-alarms --state-value ALARM --alarm-name-prefix {service} --region {region}`
- All alarm states for the service: `aws cloudwatch describe-alarms --alarm-name-prefix {service} --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}' --region {region}`

### Lambda — post-apply state

- Function state (expect `Active`): `aws lambda get-function-configuration --function-name {function} --query '{State:State,LastModified:LastModified}' --region {region}`
- Recent errors (last 15m): `aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Errors --dimensions Name=FunctionName,Value={function} --start-time {T-15m} --end-time {now} --period 60 --statistics Sum --region {region}`

### ALB — target health post-apply

- Target group health (expect all `healthy`): `aws elbv2 describe-target-health --target-group-arn {tg-arn} --region {region}`
- Recent 5xx count: `aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name HTTPCode_ELB_5XX_Count --dimensions Name=LoadBalancer,Value={lb-id} --start-time {T-15m} --end-time {now} --period 60 --statistics Sum --region {region}`

---

## Health Snapshot (S0 / S1 / S2 — Read-Only)

Read templates for the health snapshot. The rules (the snapshot set, windows, waits, verdicts, and what each read feeds) are in `snapshot.md`; this section holds only the commands. Every command here is read-only and runs in a batch the operator already approves. Run the alarms read and the `get-metric-data` call once per region for the whole snapshot set, and each point-in-time read once per resource type.

### Firing alarms (one read per region)

- Everything firing in the region, projected. Filter it locally to the snapshot set by matching each alarm's dimension values to the members' identifiers: `aws cloudwatch describe-alarms --state-value ALARM --alarm-types MetricAlarm CompositeAlarm --region {region} --query '{metric:MetricAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,ns:Namespace,metric:MetricName,dims:Dimensions,math:Metrics[].MetricStat.Metric.Dimensions},composite:CompositeAlarms[].{name:AlarmName,updated:StateUpdatedTimestamp,rule:AlarmRule}}'`
- `--alarm-types` is needed. `docs: https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/describe-alarms.html (read 2026-11-18)`: "If you omit this parameter, only metric alarms are returned, even if composite alarms or log alarms exist in the account."
- A metric-math alarm has no `Namespace` or `MetricName` of its own. Its metrics are under `Metrics` (same page: "An array of MetricDataQuery structures, used in an alarm based on a metric math expression."), hence `math`. `updated` is `StateUpdatedTimestamp`, "The time stamp of the last update to the value of either the `StateValue` or `EvaluationState` parameters", so it can be later than the moment the alarm began firing.

### Metrics (one `get-metric-data` call per region)

One query file covers every member's signals in the region. Write it to `{output-root}/iac-change-execution/snapshot-queries-{env}.json`, never elsewhere in the repo tree. `{output-root}` is resolved once per run (SKILL.md Constraint 13): `.culiops`, or `$CULIOPS_HOME/<workspace>` when `CULIOPS_HOME` is set. The file holds metric identifiers only. `docs: https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-parameters-file.html (read 2026-11-18)`: "The file paths in the following examples are interpreted to be relative to the current working directory."

Example queries for one ALB (`Period` 3600 is the S0 / S1 form; the other forms are under Reads):

```json
[
  {"Id": "m_5xx_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "HTTPCode_Target_5XX_Count", "Dimensions": [{"Name": "LoadBalancer", "Value": "{lb-id}"}]}, "Period": 3600, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "err_alb", "Expression": "FILL(m_5xx_alb, 0)", "Label": "{lb-id} target 5xx count"},
  {"Id": "req_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "RequestCount", "Dimensions": [{"Name": "LoadBalancer", "Value": "{lb-id}"}]}, "Period": 3600, "Stat": "Sum"}, "Label": "{lb-id} request count"},
  {"Id": "p95_alb", "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": "TargetResponseTime", "Dimensions": [{"Name": "LoadBalancer", "Value": "{lb-id}"}]}, "Period": 3600, "Stat": "p95"}, "Label": "{lb-id} p95 seconds"}
]
```

- `err_alb` is a **count** series with `FILL(…, 0)` gap fill. The raw query is `ReturnData: false`; the expression is what is read. `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html (read 2026-11-18)`: FILL "Fills the missing values of a time series." Fill count series only, never a gauge (`snapshot.md › When snapshots run`).
- `req_alb` is the member's traffic count (requests, invocations or messages). It is read **unfilled** on purpose: its datapoints are the evidence that a filled 0 in another series of the same member is a real zero and not a late one (`snapshot.md › When snapshots run`). It is also the denominator of the error rate.
- `p95_alb` is latency, a gauge: no `FILL`. `Stat` `p95` is allowed: `docs: https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/get-metric-data.html (read 2026-11-18)`: "The statistic to return. It can include any CloudWatch statistic or extended statistic."
- Every `Id` is unique and starts with a lowercase letter, and every series carries its member in the `Id` (`err_<member>`), so each row of the record traces to a member. `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html (read 2026-11-18)`: "the **Id** field for all metrics and math expressions must start with a lowercase letter".
- One call takes up to 500 queries. `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_GetMetricData.html (read 2026-11-18)`: "A single `GetMetricData` call can include as many as 500 `MetricDataQuery` structures."

### Per-type metric list

| Member type | Namespace · dimensions | Count series (`Sum`, `FILL(…, 0)`) | Gauges and latency (`Stat` shown, never filled) |
|-------------|------------------------|------------------------------------|-------------------------------------------------|
| ALB | `AWS/ApplicationELB` · `LoadBalancer` = `{lb-id}`; health counts also `TargetGroup` = `{tg-dim}` | `RequestCount` (traffic, read unfilled), `HTTPCode_Target_5XX_Count`, `HTTPCode_ELB_5XX_Count` | `TargetResponseTime` (`p95`); `HealthyHostCount`, `UnHealthyHostCount` (`Minimum`) |
| ECS service | `AWS/ECS` · `ClusterName`, `ServiceName` | none: ECS publishes request metrics only with Service Connect, so traffic and errors come from the ALB in front | `CPUUtilization`, `MemoryUtilization` (`Average`); running vs desired is point-in-time (below) |
| RDS | `AWS/RDS` · `DBInstanceIdentifier` | none: no request or error counts | `CPUUtilization`, `DatabaseConnections`, `ReadLatency`, `WriteLatency` (`Average`); `FreeableMemory`, `FreeStorageSpace` (`Minimum`) |
| Lambda | `AWS/Lambda` · `FunctionName` | `Invocations` (traffic, read unfilled), `Errors`, `Throttles` | `Duration` (`p95`); `ConcurrentExecutions` (`Maximum`) |
| SQS | `AWS/SQS` · `QueueName` | `NumberOfMessagesSent` (traffic, read unfilled) | `ApproximateNumberOfMessagesVisible`, `ApproximateAgeOfOldestMessage` (`Maximum`) |

- ALB: `docs: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html (read 2026-11-18)` lists every metric above and the dimensions. `TargetResponseTime`: "The most useful statistics are `Average` and `pNN.NN` (percentiles)." `UnHealthyHostCount`: "We recommend you monitor for non-zero `UnHealthyHostCount` in the `Minimum` statistic". `RequestCount`: "Requests that are rejected before a target is chosen are not reflected in this metric", so a 5xx that the load balancer itself returns (`HTTPCode_ELB_5XX_Count`) can be missing from the request count (inferred). The `LoadBalancer` value is `app/<load-balancer-name>/<id>`, "the final portion of the load balancer ARN", and the `TargetGroup` value is `targetgroup/<target-group-name>/<id>`.
- ECS: `docs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/available-metrics.html (read 2026-11-18)`. Service-level `CPUUtilization` and `MemoryUtilization` use `ClusterName`, `ServiceName` and cover EC2 and Fargate. "If a cluster, service, or other resource has no running tasks, no metrics will be reported for that resource during that period." `RequestCount` "is only available if you have configured Amazon ECS Service Connect."
- RDS: `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html (read 2026-11-18)` for the metric names; `ReadLatency` and `WriteLatency` are in seconds, `FreeableMemory` and `FreeStorageSpace` in bytes. `docs: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/dimensions.html (read 2026-11-18)`: `DBInstanceIdentifier` "A specific DB instance."; "For Multi-AZ DB clusters, Amazon RDS publishes metrics for each DB instance in the cluster under the `DBInstanceIdentifier` dimension. Metrics aren't available under a DB cluster dimension such as `DBClusterIdentifier`." Query each instance of a cluster.
- Lambda: `docs: https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics-types.html (read 2026-11-18)`. Invocation metrics are viewed "with the `Sum` statistic"; "To calculate the error rate, divide the value of `Errors` by the value of `Invocations`."; "Throttled requests and other invocation errors don't count as either `Invocations` or `Errors`", so read `Throttles` beside `Errors`. "`Duration` also supports percentile (`p`) statistics." Concurrency metrics are viewed "with the `Max` statistic". `docs: https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics-view.html (read 2026-11-18)`: `FunctionName` aggregates "all versions and aliases of an Event Function"; "The timestamp on a metric reflects when the Event Function was invoked", so a long-timeout function's errors can land in an earlier period than the one in which they finished (inferred).
- SQS: `docs: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-available-cloudwatch-metrics.html (read 2026-11-18)`. "Amazon SQS metrics in CloudWatch use a single dimension: `QueueName`." "All metrics emit non-negative values only when the queue is active." For a dead-letter queue, "To monitor the state of a DLQ, use the `ApproximateNumberOfMessagesVisible` metric", because messages moved there by redrive are not counted in `NumberOfMessagesSent`.

### Reads

- **S0 and S1** (the hour ending now, and the same hour last week). One call reads 7 days and 1 hour of hourly points (`Period` 3600): the first point is the hour that ended 7 days ago, the last is the hour ending now.

  ```bash
  aws cloudwatch get-metric-data --region {region} \
    --metric-data-queries file://{output-root}/iac-change-execution/snapshot-queries-{env}.json \
    --start-time {T-7d-1h} --end-time {now} --scan-by TimestampAscending \
    --query 'MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]}'
  ```

  - Expect `t_week` = `{T-7d-1h}` and `t_now` = `{T-1h}`. Show each value with its timestamp. A value whose timestamp is not the expected bucket is not that window: it is `no data`, never a neighbouring hour's value. The docs do not say whether hourly buckets start at `--start-time` or on the clock hour, so read the timestamps and never assume.
  - `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_GetMetricData.html (read 2026-11-18)`: `StartTime` "is inclusive" and is rounded "down to the nearest whole minute" when less than 15 days ago; `EndTime` "is exclusive"; `ScanBy` `TimestampAscending` "returns the oldest data first"; `MaxDatapoints` "the default of 100,800" is "before paginating" (7 days of hourly points is 169 per query, so 500 queries fit in one page).
- **Peak hours** (PR / CI path, when Q3 needs `peak hours: HH–HH`). The same call and file, with one more key in the projection: the hourly series of every `req_*` query for the 7 days. The busiest hours come from it. Bucket start times are UTC. If they carry minutes (a bucket starting 10:41 straddles two clock hours), map each bucket to the clock hour that holds most of it. Label the result UTC, or convert it.

  ```bash
  aws cloudwatch get-metric-data --region {region} \
    --metric-data-queries file://{output-root}/iac-change-execution/snapshot-queries-{env}.json \
    --start-time {T-7d-1h} --end-time {now} --scan-by TimestampAscending \
    --query "{summary:MetricDataResults[].{id:Id,status:StatusCode,t_week:Timestamps[0],v_week:Values[0],t_now:Timestamps[-1],v_now:Values[-1]},hourly:MetricDataResults[?starts_with(Id, 'req_')].{id:Id,t:Timestamps,v:Values}}"
  ```

- **S2** (after the apply). Set every `Period` in the file to 300, then read from the end of the rollout or disruption to now. `{rollout-complete}` is that moment, seconds `00`. At `Period` 300, two periods are 10 minutes after it.

  ```bash
  aws cloudwatch get-metric-data --region {region} \
    --metric-data-queries file://{output-root}/iac-change-execution/snapshot-queries-{env}.json \
    --start-time {rollout-complete} --end-time {now} --scan-by TimestampAscending \
    --query 'MetricDataResults[].{id:Id,status:StatusCode,t:Timestamps,v:Values}'
  ```

- **"Before" on the PR / CI path** (read after the fact, ending at the apply time). The S0 / S1 file with `Period` 3600 and the S0 / S1 projection, over the hour before the apply: `--start-time {apply-time-1h} --end-time {apply-time}`. There is one point, so `v_week` and `v_now` are the same value: read `v_now`. Point-in-time state cannot be read back (`snapshot.md › When snapshots run`).
- **Retention bounds the read-back.** `docs: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html (read 2026-11-18)`: "Data points with a period of 60 seconds (1 minute) are available for 15 days"; "Data points with a period of 300 seconds (5 minutes) are available for 63 days"; "Data points with a period of 3600 seconds (1 hour) are available for 455 days (15 months)". The `Period` must fit the age of `--start-time`, or nothing comes back. `docs: https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/get-metric-data.html (read 2026-11-18)`: "Start time between 15 and 63 days ago - Use a multiple of 300 seconds (5 minutes)."; "Start time greater than 63 days ago - Use a multiple of 3600 seconds (1 hour)." The hourly S0 / S1 and "before" reads fit any age within 455 days; the 300-second S2 read fits a start time up to 63 days old.

### Point-in-time state

ECS running vs desired and its deployments, ALB target health, and RDS status are read with the commands in Verification Checks above (ECS and RDS post-apply health, ALB target health). They are not repeated here. Run them with the snapshot: S0, S1 and S2. `--services` takes up to 10 names, so one `describe-services` call per cluster covers every ECS member in it. `docs: https://docs.aws.amazon.com/cli/latest/reference/ecs/describe-services.html (read 2026-11-18)`: "You may specify up to 10 services to describe in a single operation."

### Wait before S2

- ECS: `aws ecs wait services-stable --cluster {cluster} --services {service} --region {region}`. `docs: https://docs.aws.amazon.com/cli/latest/reference/ecs/wait/services-stable.html (read 2026-11-18)`: "Wait until JMESPath query length(services[?!(length(deployments) == 1 && runningCount == desiredCount)]) == 0 returns True when polling with `describe-services`. It will poll every 15 seconds until a successful state has been reached. This will exit with a return code of 255 after 40 failed checks." A non-zero exit is not a completed rollout. Up to 10 services per call.
- RDS: re-run the status check in Verification Checks until the status is `available`.
- Kubernetes: `examples/kubernetes.md › Health Snapshot`.

### Automation lag (feeds `iac-change.4`)

- CI history: `gh run list --workflow {workflow-file} --limit 5 --json databaseId,status,conclusion,createdAt,updatedAt,headSha,url`
- Terraform state object, last modified time only: `aws s3api head-object --bucket {state-bucket} --key {state-key} --query LastModified`
- **Never** `terraform state pull`, `aws s3 cp` or `aws s3api get-object` on the state: it holds secrets in plaintext, and the role that can `head-object` it can also read it (Prerequisites).
- ECS deployment time: `aws ecs describe-services --cluster {cluster} --services {service} --region {region} --query 'services[].deployments[].{status:status,created:createdAt,taskDef:taskDefinition}'`
- Helm releases: `examples/kubernetes.md › Health Snapshot`.

### Sibling app-source search (only when Step 1 predicts an app-facing change)

Otherwise nothing is searched (`snapshot.md › L2 from evidence`). All three commands are read-only and shown in the batch like any other read.

- Local checkouts beside the target repo: `ls {parent-dir}`, then for each candidate whose directory name matches the service or the deployed image: `git -C {dir} remote get-url origin`
- Its version: `git -C {dir} rev-parse HEAD`
- The deployed ref to compare it with. ECS image, with nothing else from the container definitions (they can carry environment values): `aws ecs describe-task-definition --task-definition {task-def} --region {region} --query 'taskDefinition.containerDefinitions[].image'`. Kubernetes: Research Queries → Current image in `examples/kubernetes.md`.
- Never fetch, pull, check out or stash in that checkout (`snapshot.md › L2 from evidence`).

---

## Apply Commands (Step 4c — MUTATION)

Each command below changes cloud state. The skill presents each command to the operator and waits for explicit approval before running. Assume Tier 2 elevated IAM permissions are active.

### Terraform

**MUTATION** — `terraform apply tfplan`
- Blast radius: all resources in the plan output; varies by change. Review plan output before approving.
- Elevated permission required: IAM role or policy with create/update/delete rights on the specific resource types in the plan.
- Rollback path: revert the code change (`git revert`), then plan and apply the reverted code through the same reviewed path. **Never restore or `state push` an old state file as a rollback** — state records reality, it does not change it, and pushing stale state orphans or duplicates live resources. Destroyed data-bearing resources (databases, buckets, volumes) are not recoverable by any revert — only by restoring a backup/snapshot taken before the apply.
- Note: `tfplan` is the binary produced by `terraform plan -out=tfplan`. Never run `terraform apply` without the plan file.

### Standard pattern — import-to-manage-legacy (zero-mutation)

To bring an existing resource under Terraform **without changing it** — e.g. to adopt a legacy resource before managing or deleting it safely — use a config-driven `import` block plus `lifecycle { ignore_changes = all }`:

```hcl
import {
  to = aws_kinesis_stream.legacy_orders
  id = "orders-ingest"
}

resource "aws_kinesis_stream" "legacy_orders" {
  name = "orders-ingest"
  # ...minimal config to match reality...
  lifecycle {
    ignore_changes = all
  }
}
```

`terraform plan` then shows an import with **no diff** — the resource is adopted exactly as-is, no mutation. This is the standard, safe way to adopt legacy resources (verified against real retired-state imports). Drop `ignore_changes = all` only once you intend to converge config to reality. Pair with the ownership check above — never import a resource an active CFN / Serverless stack still owns.

### Lambda — lambroll deploy

**MUTATION** — `lambroll deploy --function-json {function.json}`
- Blast radius: single Lambda function; all invocations in flight at deploy time may receive the old or new code depending on provisioned concurrency configuration.
- Elevated permission required: `lambda:UpdateFunctionCode`, `lambda:UpdateFunctionConfiguration`, `lambda:PublishVersion` scoped to the target function ARN.
- Rollback path: `lambroll deploy` from the previous `function.json`, or `aws lambda update-alias` to point the alias back to the previous version.

### ECS — ecspresso deploy

**MUTATION** — `ecspresso deploy --config {ecspresso.yml}`
- Blast radius: single ECS service; rolling deployment replaces tasks gradually. If health checks fail, the deployment stalls (does not auto-rollback by default unless circuit breaker is enabled).
- Elevated permission required: `ecs:UpdateService`, `ecs:RegisterTaskDefinition`, `ecs:DescribeServices` scoped to the target cluster and service.
- Rollback path: `ecspresso rollback --config {ecspresso.yml}` (rolls back to the previous task definition revision), or `aws ecs update-service --cluster {cluster} --service {service} --task-definition {previous-task-def}`.

---

## Placeholder Reference

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{cluster}`, `{service}`, `{function}`, `{instance}` | Resource identifiers | `widgetapi-prod-eu-web` |
| `{tg-arn}`, `{lb-id}`, `{listener-arn}`, `{sg-id}` | AWS identifiers (ARN or ID). In a metric `Dimensions` value, `{lb-id}` is the final portion of the load balancer ARN | See the resource in the catalog; `app/orders-alb/50dc6c495c0c9188` |
| `{tg-dim}` | Target group as a metric dimension value: the final portion of the target group ARN | `targetgroup/orders-web/73e2d6bc24d8a067` |
| `{region}` | AWS region | `eu-west-1` |
| `{T-15m}`, `{T-1h}`, `{T-7d-1h}` | ISO-8601 time offsets (`{T-7d-1h}` is 7 days and 1 hour back); seconds `00` in `get-metric-data` calls | `2026-04-24T09:45:00Z` |
| `{now}` | Current time, ISO 8601 | `2026-04-24T10:00:00Z` |
| `{apply-time}`, `{apply-time-1h}`, `{rollout-complete}` | When the apply landed, one hour before it, and when its rollout or disruption ended (Health Snapshot) | `2026-04-24T10:00:00Z` |
| `{output-root}`, `{env}` | The output root (`.culiops`, or `$CULIOPS_HOME/<workspace>`; SKILL.md Constraint 13) and the environment name | `.culiops`, `prod` |
| `{state-bucket}`, `{state-key}` | Terraform S3 backend bucket and state object key | `acme-tfstate`, `payments/prod.tfstate` |
| `{workflow-file}` | CI workflow file name | `terraform-apply.yml` |
| `{parent-dir}`, `{dir}` | Directory holding the target repo, and a checkout in it | `..`, `../orders-api` |
| `{task-def}` | ECS task definition (family:revision or ARN) | `orders-api:42` |
