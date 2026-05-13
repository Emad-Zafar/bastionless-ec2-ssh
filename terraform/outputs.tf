output "instance_id" {
  description = "Pass this to scripts/connect.sh."
  value       = aws_instance.target.id
}

output "instance_name" {
  description = "Tag:Name value — scripts/connect.sh can resolve by this."
  value       = aws_instance.target.tags["Name"]
}

output "eice_endpoint_id" {
  description = "EICE endpoint id (for IAM policy conditions if you want them)."
  value       = aws_ec2_instance_connect_endpoint.this.id
}

output "connect_hint" {
  description = "Copy-paste to connect."
  value       = "scripts/connect.sh ${aws_instance.target.tags["Name"]}"
}
