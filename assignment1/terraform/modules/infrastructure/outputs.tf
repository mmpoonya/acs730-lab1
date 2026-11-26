output "web_public_ips" {
  description = "Public IP addresses of the web servers"
  value       = aws_instance.web[*].public_ip
}

output "first_web_public_ip" {
  description = "Public IP address of the first web server"
  value       = aws_instance.web[0].public_ip
}

output "web_instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web.id
}

output "web_urls" {
  description = "HTTP URLs of the web servers"

  value = [
    for instance in aws_instance.web :
    "http://${instance.public_ip}"
  ]
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "application_secret_name" {
  description = "SSM parameter name for the application secret"
  value       = data.aws_ssm_parameter.db_password.name
}

output "application_secret_version" {
  description = "Version of the application secret in SSM"
  value       = data.aws_ssm_parameter.db_password.version
}

output "cpu_alarm_names" {
  description = "Names of EC2 CPU utilization alarms"
  value       = aws_cloudwatch_metric_alarm.high_cpu[*].alarm_name
}
