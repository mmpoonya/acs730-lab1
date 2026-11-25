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

