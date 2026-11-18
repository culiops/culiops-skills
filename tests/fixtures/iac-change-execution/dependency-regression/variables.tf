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
  description = "VPC ID (10.20.0.0/16) where the service is deployed"
  type        = string
}

variable "api_subnets" {
  description = "Private subnets for the api tasks and the load balancer, with their CIDR blocks"
  type        = map(object({ id = string, cidr = string }))
}

variable "worker_subnets" {
  description = "Private subnets for the worker tasks, with their CIDR blocks"
  type        = map(object({ id = string, cidr = string }))
}

variable "admin_security_group_id" {
  description = "Security group of the admin host that may reach the database"
  type        = string
}

variable "db_subnet_group_name" {
  description = "RDS subnet group name"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task IAM role"
  type        = string
}

variable "ecr_repo" {
  description = "ECR repository prefix (without image name or tag)"
  type        = string
}

variable "api_image_tag" {
  description = "Container image tag for orders-api"
  type        = string
}

variable "worker_image_tag" {
  description = "Container image tag for orders-worker"
  type        = string
}

variable "api_desired_count" {
  description = "Desired number of orders-api tasks"
  type        = number
  default     = 2
}

variable "worker_desired_count" {
  description = "Desired number of orders-worker tasks"
  type        = number
  default     = 2
}
