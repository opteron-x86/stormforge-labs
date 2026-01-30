output "webapp_url" {
  description = "URL of the threat intelligence feed aggregator"
  value       = "http://${aws_instance.webapp.public_ip}:8080"
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.webapp.public_ip}"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.webapp.id
}

output "instance_role_arn" {
  description = "EC2 instance role ARN"
  value       = aws_iam_role.webapp.arn
}

output "rds_endpoint" {
  description = "RDS endpoint (internal)"
  value       = aws_db_instance.intel_db.endpoint
  sensitive   = true
}

output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "attack_hint" {
  description = "Starting point for exploitation"
  value       = "The feed aggregator fetches external threat intelligence. What URLs can it access?"
}
