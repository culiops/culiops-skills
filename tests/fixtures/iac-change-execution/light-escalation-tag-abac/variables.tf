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
