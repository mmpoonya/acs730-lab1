resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.instance_count

  alarm_name = "${local.name_prefix}-web-${count.index}-high-cpu"

  alarm_description = "EC2 average CPU utilization exceeds the configured threshold"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_alarm_threshold

  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  treat_missing_data = "missing"

  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }

  tags = local.common_tags
}

