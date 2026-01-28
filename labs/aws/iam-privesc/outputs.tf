# Outputs
output "developer_access_key_id" {
  description = "AWS Access Key ID for developer user"
  value       = aws_iam_access_key.developer.id
}

output "developer_secret_access_key" {
  description = "AWS Secret Access Key for developer user (sensitive)"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

output "developer_username" {
  description = "IAM username for the developer account"
  value       = aws_iam_user.developer.name
}

output "protected_bucket_name" {
  description = "S3 bucket containing protected data"
  value       = aws_s3_bucket.protected_data.id
}

output "aws_region" {
  description = "AWS region for lab resources"
  value       = var.aws_region
}

output "lab_instructions" {
  description = "Instructions for configuring AWS CLI"
  sensitive = true
  value       = <<-EOT
Configure your AWS CLI with these credentials:

aws configure set aws_access_key_id ${aws_iam_access_key.developer.id}
aws configure set aws_secret_access_key ${aws_iam_access_key.developer.secret}
aws configure set region ${var.aws_region}

To view secret access key after apply:
terraform output -raw developer_secret_access_key

Start by enumerating your IAM permissions:
aws iam get-user
aws iam list-user-policies --user-name ${aws_iam_user.developer.name}
aws iam get-user-policy --user-name ${aws_iam_user.developer.name} --policy-name <policy-name>
EOT
}

output "attack_chain_hint" {
  description = "Starting point for the lab"
  value       = "Begin by understanding what permissions your IAM user has. What can you modify?"
}