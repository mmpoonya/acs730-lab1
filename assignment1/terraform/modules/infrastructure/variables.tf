variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )

    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Number of EC2 web servers"
  type        = number
  default     = 1

  validation {
    condition = (
      var.instance_count >= 1 &&
      var.instance_count <= 3 &&
      floor(var.instance_count) == var.instance_count
    )

    error_message = "Instance count must be an integer between 1 and 3."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed to access the web servers"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_tags" {
  description = "Additional environment-specific resource tags"
  type        = map(string)
  default     = {}
}

