output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.orders.name
}

output "alb_dns_name" {
  description = "Internal DNS name of the load balancer in front of orders-api"
  value       = aws_lb.orders.dns_name
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.orders.address
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.orders_alerts.arn
}
