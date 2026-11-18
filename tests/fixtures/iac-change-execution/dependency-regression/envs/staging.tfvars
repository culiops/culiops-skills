env                     = "staging"
region                  = "ap-southeast-1"
aws_account_id          = "222222222222"
vpc_id                  = "vpc-0e4d3c2b1a098765f"
api_subnets             = {
  a = { id = "subnet-0e1a2b3c4d5e6f701", cidr = "10.20.1.0/24" }
  b = { id = "subnet-0e2b3c4d5e6f70812", cidr = "10.20.2.0/24" }
}
worker_subnets          = {
  a = { id = "subnet-0e3c4d5e6f7081923", cidr = "10.20.8.0/24" }
  b = { id = "subnet-0e4d5e6f708192a34", cidr = "10.20.9.0/24" }
}
admin_security_group_id = "sg-0e9f8a7b6c5d4e3f2"
db_subnet_group_name    = "orders-staging-db-subnet-group"
db_instance_class       = "db.t4g.medium"
execution_role_arn      = "arn:aws:iam::222222222222:role/orders-staging-ecs-execution"
task_role_arn           = "arn:aws:iam::222222222222:role/orders-staging-ecs-task"
ecr_repo                = "222222222222.dkr.ecr.ap-southeast-1.amazonaws.com/orders"
api_image_tag           = "v1.9.0-rc1"
worker_image_tag        = "v1.9.0-rc1"
api_desired_count       = 2
worker_desired_count    = 2
