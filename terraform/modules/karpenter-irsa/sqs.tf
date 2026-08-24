###############################################################################
# Karpenter IRSA Module — SQS Queue + EventBridge Rules
#
# When AWS is about to reclaim a spot instance (or an instance changes state),
# EventBridge catches the event and pushes it to this SQS queue.
# Karpenter polls the queue and proactively drains the node before it dies.
###############################################################################


# SQS Queue — Karpenter polls this for interruption warnings
resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${var.cluster_name}-karpenter-interruption"
  message_retention_seconds = 300 # 5 min — interruptions are time-sensitive
  sqs_managed_sse_enabled   = true

  tags = merge(var.tags, { Name = "${var.cluster_name}-karpenter-interruption" })
}

# Allow EventBridge to push messages into this queue
resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["events.amazonaws.com", "sqs.amazonaws.com"]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}


# EventBridge Rules — catch EC2 lifecycle events
# Spot interruption warning (2-minute heads up)
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.cluster_name}-spot-interruption"
  description = "EC2 Spot Instance Interruption Warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-spot-interruption" })
}

resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "karpenter-interruption-queue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

# Instance rebalance recommendation (earlier warning than interruption)
resource "aws_cloudwatch_event_rule" "rebalance" {
  name        = "${var.cluster_name}-instance-rebalance"
  description = "EC2 Instance Rebalance Recommendation"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-instance-rebalance" })
}

resource "aws_cloudwatch_event_target" "rebalance" {
  rule      = aws_cloudwatch_event_rule.rebalance.name
  target_id = "karpenter-interruption-queue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

# Instance state change (terminated, stopped — cleanup signal)
resource "aws_cloudwatch_event_rule" "state_change" {
  name        = "${var.cluster_name}-instance-state-change"
  description = "EC2 Instance State-change Notification"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-instance-state-change" })
}

resource "aws_cloudwatch_event_target" "state_change" {
  rule      = aws_cloudwatch_event_rule.state_change.name
  target_id = "karpenter-interruption-queue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}
