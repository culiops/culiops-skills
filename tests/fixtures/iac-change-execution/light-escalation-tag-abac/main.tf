# paymentapi exports — S3 bucket and tag-based read access, ap-southeast-1.
# This file represents the EXISTING state of the infrastructure.
# Read access to buckets is granted by tag: the policy below lets the
# payments engineers read any bucket whose `team` tag is "payments".
# Request metrics and two alarms (4xx, 5xx) watch the bucket.

# ── S3 bucket (exports) ───────────────────────────────────────────────────────

resource "aws_s3_bucket" "exports" {
  bucket = "paymentapi-exports-${var.env}"

  tags = {
    Service     = "paymentapi"
    Environment = var.env
    team        = "payments"
  }
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket = aws_s3_bucket.exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── IAM: tag-based read access ────────────────────────────────────────────────

resource "aws_iam_role" "payments_engineers" {
  name = "paymentapi-engineers-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}

resource "aws_iam_policy" "team_bucket_read" {
  name        = "paymentapi-team-bucket-read-${var.env}"
  description = "Read objects in buckets tagged for the payments team"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadTeamBuckets"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/team" = "payments"
          }
        }
      }
    ]
  })

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "payments_engineers_bucket_read" {
  role       = aws_iam_role.payments_engineers.name
  policy_arn = aws_iam_policy.team_bucket_read.arn
}

# ── Alerting ──────────────────────────────────────────────────────────────────
# Request metrics on the whole bucket feed two alarms. A tag or policy change
# that blocks readers shows up as 4xx errors.

resource "aws_s3_bucket_metric" "exports" {
  bucket = aws_s3_bucket.exports.id
  name   = "EntireBucket"
}

resource "aws_sns_topic" "exports_alerts" {
  name = "paymentapi-exports-alerts-${var.env}"

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "exports_4xx" {
  alarm_name          = "paymentapi-exports-4xx-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 25
  treat_missing_data  = "notBreaching"
  alarm_description   = "S3 4xx errors above 25 per 5 minutes on paymentapi-exports ${var.env}"

  dimensions = {
    BucketName = aws_s3_bucket.exports.bucket
    FilterId   = aws_s3_bucket_metric.exports.name
  }

  alarm_actions = [aws_sns_topic.exports_alerts.arn]
  ok_actions    = [aws_sns_topic.exports_alerts.arn]

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "exports_5xx" {
  alarm_name          = "paymentapi-exports-5xx-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_description   = "S3 5xx errors above 5 per 5 minutes on paymentapi-exports ${var.env}"

  dimensions = {
    BucketName = aws_s3_bucket.exports.bucket
    FilterId   = aws_s3_bucket_metric.exports.name
  }

  alarm_actions = [aws_sns_topic.exports_alerts.arn]
  ok_actions    = [aws_sns_topic.exports_alerts.arn]

  tags = {
    Service     = "paymentapi"
    Environment = var.env
  }
}
