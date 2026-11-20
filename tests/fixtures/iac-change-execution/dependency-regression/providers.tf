terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Each environment's var-file sets aws_account_id. Terraform refuses to plan or
# apply when the active credentials belong to a different account.
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}
