output "db_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.paymentapi.identifier
}

output "parameter_group_name" {
  description = "RDS parameter group name"
  value       = aws_db_parameter_group.paymentapi.name
}
