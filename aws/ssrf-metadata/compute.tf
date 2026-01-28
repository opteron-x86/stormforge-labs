resource "aws_instance" "webapp" {
  ami                    = module.ami.amazon_linux_2023_id
  instance_type          = local.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.vpc.ssh_security_group_id, module.vpc.web_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.webapp.name
  key_name               = var.ssh_key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    data_processor_role = aws_iam_role.data_processor.arn
  }))

  tags = merge(local.common_tags, {
    Name         = "${var.lab_prefix}-webapp"
    AutoShutdown = "4hours"
  })
  
  lifecycle {
    ignore_changes = [ami]
  }
}