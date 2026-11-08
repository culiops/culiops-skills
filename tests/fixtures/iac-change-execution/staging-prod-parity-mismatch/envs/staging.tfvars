env                   = "staging"
region                = "ap-southeast-1"
aws_account_id        = "222222222222"
vpc_id                = "vpc-0f1e2d3c4b5a69788"
db_subnet_group_name  = "paymentapi-staging-db-subnet-group"
app_security_group_id = "sg-0f1e2d3c4b5a69788"
db_instance_class     = "db.t4g.medium"
db_storage_gb         = 20
db_max_storage_gb     = 100
db_multi_az           = false
db_engine_version     = "15.4"
# db_password comes from TF_VAR_db_password
