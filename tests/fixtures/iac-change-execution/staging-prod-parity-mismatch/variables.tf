variable "env" {
  description = "Environment name (e.g. prod, staging)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID this environment lives in. The provider refuses any other account."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the database is deployed"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID of the application tier (ECS tasks)"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_storage_gb" {
  description = "Initial allocated storage in GB"
  type        = number
}

variable "db_max_storage_gb" {
  description = "Maximum allocated storage for autoscaling (GB)"
  type        = number
}

variable "db_multi_az" {
  description = "Whether the instance runs Multi-AZ"
  type        = bool
}

variable "db_engine_version" {
  description = "PostgreSQL engine version. The parameter group family follows its major version."
  type        = string
}

variable "db_password" {
  description = "RDS master password (set through TF_VAR_db_password, never in a var-file)"
  type        = string
  sensitive   = true
}
