# orders — order API (ECS Fargate behind an internal ALB), order worker (ECS Fargate)
# and an RDS PostgreSQL database, ap-southeast-1, in two environments (staging and prod).
# This file represents the EXISTING state of the infrastructure.
# The change under test removes the legacy VPC-wide CIDR rule from the database
# security group: aws_vpc_security_group_ingress_rule.orders_db_from_vpc.

# ── ECS cluster ──────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "orders" {
  name = "orders-cluster-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

# ── Task definitions ─────────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "orders_api" {
  family                   = "orders-api-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name         = "orders-api"
      image        = "${var.ecr_repo}/orders-api:${var.api_image_tag}"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment = [
        { name = "APP_ENV", value = var.env },
        { name = "DB_HOST", value = aws_db_instance.orders.address },
        { name = "PORT", value = "8080" }
      ]
    }
  ])

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_ecs_task_definition" "orders_worker" {
  family                   = "orders-worker-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "orders-worker"
      image     = "${var.ecr_repo}/orders-worker:${var.worker_image_tag}"
      essential = true
      environment = [
        { name = "APP_ENV", value = var.env },
        { name = "DB_HOST", value = aws_db_instance.orders.address }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orders_worker.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

# ── ECS services ─────────────────────────────────────────────────────────────

resource "aws_ecs_service" "orders_api" {
  name            = "orders-api-${var.env}"
  cluster         = aws_ecs_cluster.orders.id
  task_definition = aws_ecs_task_definition.orders_api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in var.api_subnets : s.id]
    security_groups  = [aws_security_group.orders_api.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.orders_api.arn
    container_name   = "orders-api"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_ecs_service" "orders_worker" {
  name            = "orders-worker-${var.env}"
  cluster         = aws_ecs_cluster.orders.id
  task_definition = aws_ecs_task_definition.orders_worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in var.worker_subnets : s.id]
    security_groups  = [aws_security_group.orders_worker.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

# ── Application load balancer (in front of orders-api) ───────────────────────

resource "aws_lb" "orders" {
  name               = "orders-alb-${var.env}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.orders_alb.id]
  subnets            = [for s in var.api_subnets : s.id]

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_lb_target_group" "orders_api" {
  name        = "orders-api-tg-${var.env}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/healthz"
    matcher = "200"
  }

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_lb_listener" "orders_http" {
  load_balancer_arn = aws_lb.orders.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orders_api.arn
  }
}

# ── Security groups ──────────────────────────────────────────────────────────

resource "aws_security_group" "orders_alb" {
  name        = "orders-alb-sg-${var.env}"
  vpc_id      = var.vpc_id
  description = "orders ${var.env} load balancer security group"

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_security_group" "orders_api" {
  name        = "orders-api-sg-${var.env}"
  vpc_id      = var.vpc_id
  description = "orders ${var.env} api task security group"

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.orders_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_security_group" "orders_worker" {
  name        = "orders-worker-sg-${var.env}"
  vpc_id      = var.vpc_id
  description = "orders ${var.env} worker task security group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

# ── Database ─────────────────────────────────────────────────────────────────

resource "aws_db_instance" "orders" {
  identifier = "orders-db-${var.env}"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage = 50
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "orders"
  username                    = "orders_admin"
  manage_master_user_password = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.orders_db.id]

  multi_az                = var.env == "prod"
  backup_retention_period = 7
  deletion_protection     = true

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_security_group" "orders_db" {
  name        = "orders-db-sg-${var.env}"
  vpc_id      = var.vpc_id
  description = "orders ${var.env} database security group"

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

# Legacy: any host in the VPC may open a PostgreSQL connection. The api, the worker
# and the batch jobs all come in through this rule.
resource "aws_vpc_security_group_ingress_rule" "orders_db_from_vpc" {
  security_group_id = aws_security_group.orders_db.id
  description       = "PostgreSQL from the VPC (legacy)"
  cidr_ipv4         = "10.20.0.0/16"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "orders_db_from_admin" {
  security_group_id            = aws_security_group.orders_db.id
  description                  = "PostgreSQL from the admin host"
  referenced_security_group_id = var.admin_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# ── Worker logs, job metrics and alarm ───────────────────────────────────────

resource "aws_cloudwatch_log_group" "orders_worker" {
  name              = "/ecs/orders-worker-${var.env}"
  retention_in_days = 30

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_metric_filter" "orders_worker_jobs" {
  name           = "orders-worker-jobs-${var.env}"
  log_group_name = aws_cloudwatch_log_group.orders_worker.name
  pattern        = "\"job finished\""

  metric_transformation {
    name      = "JobsProcessed"
    namespace = "Orders/Worker"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "orders_worker_errors" {
  name           = "orders-worker-errors-${var.env}"
  log_group_name = aws_cloudwatch_log_group.orders_worker.name
  pattern        = "\"job failed\""

  metric_transformation {
    name      = "JobErrors"
    namespace = "Orders/Worker"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "orders_worker_errors" {
  alarm_name          = "orders-worker-errors-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "JobErrors"
  namespace           = "Orders/Worker"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  treat_missing_data  = "notBreaching"
  alarm_description   = "orders-worker job errors above 20 per 5 minutes for ${var.env}"

  alarm_actions = [aws_sns_topic.orders_alerts.arn]
  ok_actions    = [aws_sns_topic.orders_alerts.arn]

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}

# ── SNS topic (alerts) ───────────────────────────────────────────────────────

resource "aws_sns_topic" "orders_alerts" {
  name = "orders-alerts-${var.env}"

  tags = {
    Service     = "orders"
    Environment = var.env
  }
}
