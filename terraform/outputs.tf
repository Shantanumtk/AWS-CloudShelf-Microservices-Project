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
  value       = "ssh -i ${path.module}/../.ssh/cloudshelf-key ubuntu@${aws_instance.cloudshelf_instance.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.cloudshelf_vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.cloudshelf_public_subnet.id
}