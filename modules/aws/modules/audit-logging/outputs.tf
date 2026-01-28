output "trail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "CloudTrail name"
  value       = aws_cloudtrail.main.name
}

output "s3_bucket_name" {
  description = "S3 bucket containing CloudTrail logs"
  value       = aws_s3_bucket.logs.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "log_query_commands" {
  description = "Commands for querying CloudTrail logs"
  value = {
    list_logs = "aws s3 ls s3://${aws_s3_bucket.logs.id}/AWSLogs/"
    download  = "aws s3 cp s3://${aws_s3_bucket.logs.id}/AWSLogs/ . --recursive"
    query     = "gunzip *.json.gz && jq '.Records[] | select(.eventName == \"EVENT_NAME\")' *.json"
  }
}