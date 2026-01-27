output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.lab.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = var.enable_private_subnets ? aws_subnet.private[*].id : []
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  value       = var.enable_private_subnets ? aws_subnet.private[*].cidr_block : []
}

output "internet_gateway_id" {
  description = "Internet gateway ID"
  value       = aws_internet_gateway.lab.id
}

output "nat_gateway_id" {
  description = "NAT gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.lab[0].id : null
}

output "ssh_security_group_id" {
  description = "SSH security group ID"
  value       = var.create_ssh_sg ? aws_security_group.ssh[0].id : null
}

output "web_security_group_id" {
  description = "Web security group ID"
  value       = var.create_web_sg ? aws_security_group.web[0].id : null
}

output "default_security_group_id" {
  description = "Default (locked down) security group ID"
  value       = aws_default_security_group.lockdown.id
}

output "s3_endpoint_id" {
  description = "S3 VPC endpoint ID"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}