output "web_public_ips" {
  value = module.infrastructure.web_public_ips
}

output "first_web_public_ip" {
  value = module.infrastructure.first_web_public_ip
}

output "web_instance_ids" {
  value = module.infrastructure.web_instance_ids
}

output "security_group_id" {
  value = module.infrastructure.security_group_id
}

output "web_urls" {
  value = module.infrastructure.web_urls
}

output "environment" {
  value = module.infrastructure.environment
}

output "application_secret_name" {
  description = "Application secret parameter name"
  value       = module.infrastructure.application_secret_name
}

output "application_secret_version" {
  description = "Application secret parameter version"
  value       = module.infrastructure.application_secret_version
}

output "cpu_alarm_names" {
  description = "Names of CPU utilization alarms"
  value       = module.infrastructure.cpu_alarm_names
}
