output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.cloudshelf_instance.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.cloudshelf_instance.public_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh -i ${path.module}/../.ssh/cloudshelf-key.pem ubuntu@${aws_instance.cloudshelf_instance.public_ip}"
}