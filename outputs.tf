output "jump_server_public_ip" {
  value       = aws_instance.jump_server.public_ip
  description = "Public IP of the jump server"
}

output "jump_server_ssh_command" {
  value       = "ssh -i ${var.cluster_name}-jump-server-key.pem ec2-user@${aws_instance.jump_server.public_ip}"
  description = "SSH command to connect to jump server"
}

output "private_key_path" {
  value       = "${path.module}/${var.cluster_name}-jump-server-key.pem"
  description = "Path to the private key file"
}

output "ecr_access_role_arn" {
  value       = aws_iam_role.ecr_access_role.arn
  description = "IAM role ARN for ECR access (use this in Helm values.yaml)"
}

output "ssl_certificate_arn" {
  value       = aws_acm_certificate.self_signed.arn
  description = "ARN of the self-signed SSL certificate (for development/testing only)"
}

output "ssl_certificate_domain" {
  value       = tls_self_signed_cert.self_signed.subject[0].common_name
  description = "Common Name of the self-signed certificate"
}
