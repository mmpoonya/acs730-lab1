data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  iam_instance_profile = local.iam_instance_profile

  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web-${count.index}"
      Role = "web"
    }
  )
}

