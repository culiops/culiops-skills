env                   = "prod"
region                = "ap-southeast-1"
aws_account_id        = "333333333333"
vpc_id                = "vpc-0abc123def456"
db_subnet_group_name  = "paymentapi-prod-db-subnet-group"
app_security_group_id = "sg-0a1b2c3d4e5f6a7b8"
db_instance_class     = "db.r6g.large"
db_storage_gb         = 100
db_max_storage_gb     = 500
db_multi_az           = true
db_engine_version     = "14.9"
# db_password comes from TF_VAR_db_password
