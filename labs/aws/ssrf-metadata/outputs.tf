# Outputs
output "service_url" {
  description = "URL Inspector Service endpoint"
  value       = "http://${aws_instance.webapp.public_ip}:8080"
}

output "ssh_connection" {
  description = "SSH connection string for maintenance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.webapp.public_ip}"
}

output "data_bucket" {
  description = "S3 bucket for customer data storage"
  value       = aws_s3_bucket.sensitive_data.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.webapp.id
}

output "instance_role" {
  description = "IAM role attached to the instance"
  value       = aws_iam_role.webapp_instance.name
}

/*
output "cloudtrail_bucket" {
  description = "S3 bucket containing audit logs"
  value       = var.enable_audit_logging ? module.audit_logging[0].s3_bucket_name : "disabled"
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = var.enable_audit_logging ? module.audit_logging[0].trail_name : "disabled"
}
*/

output "attack_chain_hint" {
  description = "Starting point for the lab"
  value       = "Begin by exploring the URL Inspector service on port 8080"
}