module "infrastructure" {
  source = "../modules/infrastructure"

  environment      = "dev"
  instance_count   = 1
  instance_type    = "t3.micro"
  http_cidr_blocks = ["0.0.0.0/0"]

  additional_tags = {
    Purpose = "Development"
  }

  cpu_alarm_threshold = 90
}

