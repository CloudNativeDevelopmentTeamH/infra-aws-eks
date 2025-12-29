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
