env                     = "prod"
region                  = "ap-southeast-1"
aws_account_id          = "333333333333"
vpc_id                  = "vpc-0c4d3c2b1a098765f"
api_subnets             = {
  a = { id = "subnet-0c1a2b3c4d5e6f701", cidr = "10.20.1.0/24" }
  b = { id = "subnet-0c2b3c4d5e6f70812", cidr = "10.20.2.0/24" }
}
worker_subnets          = {
  a = { id = "subnet-0c3c4d5e6f7081923", cidr = "10.20.8.0/24" }
  b = { id = "subnet-0c4d5e6f708192a34", cidr = "10.20.9.0/24" }
}
admin_security_group_id = "sg-0c9f8a7b6c5d4e3f2"
db_subnet_group_name    = "orders-prod-db-subnet-group"
db_instance_class       = "db.r6g.large"
execution_role_arn      = "arn:aws:iam::333333333333:role/orders-prod-ecs-execution"
task_role_arn           = "arn:aws:iam::333333333333:role/orders-prod-ecs-task"
ecr_repo                = "333333333333.dkr.ecr.ap-southeast-1.amazonaws.com/orders"
api_image_tag           = "v1.8.3"
worker_image_tag        = "v1.8.3"
api_desired_count       = 4
worker_desired_count    = 4
