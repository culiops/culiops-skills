env                   = "prod"
region                = "ap-southeast-1"
aws_account_id        = "333333333333"
vpc_id                = "vpc-0abc123def456"
private_subnet_ids    = ["subnet-0a1b2c3d4e5f6a7b8", "subnet-0b2c3d4e5f6a7b8c9"]
alb_security_group_id = "sg-0a1b2c3d4e5f6a7b8"
execution_role_arn    = "arn:aws:iam::333333333333:role/paymentapi-prod-ecs-execution"
task_role_arn         = "arn:aws:iam::333333333333:role/paymentapi-prod-ecs-task"
ecr_repo              = "333333333333.dkr.ecr.ap-southeast-1.amazonaws.com/paymentapi"
image_tag             = "v2.4.1"
desired_count         = 3
task_cpu              = 512
task_memory           = 1024
db_host               = "paymentapi-prod-db.cluster-cxyz1234abcd.ap-southeast-1.rds.amazonaws.com"

# CPU alarm: only prod has one.
cpu_alarm_threshold = 80
