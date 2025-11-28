# Bastion Module Outputs

output "instance_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "instance_private_ip" {
  description = "Bastion private IP address"
  value       = aws_instance.bastion.private_ip
}

output "instance_public_ip" {
  description = "Bastion public IP address (null when using SSM)"
  value       = var.create_eip ? aws_eip.bastion[0].public_ip : null
}

output "security_group_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion.id
}

output "connect_command" {
  description = "Command to connect to bastion via SSM"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id}"
}

output "db_connection_info" {
  description = "Database connection information"
  value = {
    host     = var.db_host
    database = var.db_name
    username = var.db_username
    command  = "Run: ./check-admin.sh to check admin accounts"
  }
}
