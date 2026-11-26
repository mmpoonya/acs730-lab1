locals {
  name_prefix          = "acs730-a1-${var.environment}"
  iam_instance_profile = "LabInstanceProfile"

  common_tags = merge(
    var.additional_tags,
    {
      Project     = "acs730"
      Lab         = "assignment1"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

