terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "cloudshelf_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cloudshelf-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cloudshelf_igw" {
  vpc_id = aws_vpc.cloudshelf_vpc.id

  tags = {
    Name = "cloudshelf-igw"
  }
}

# Public Subnet
resource "aws_subnet" "cloudshelf_public_subnet" {
  vpc_id                  = aws_vpc.cloudshelf_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudshelf-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "cloudshelf_public_rt" {
  vpc_id = aws_vpc.cloudshelf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudshelf_igw.id
  }

  tags = {
    Name = "cloudshelf-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "cloudshelf_public_rta" {
  subnet_id      = aws_subnet.cloudshelf_public_subnet.id
  route_table_id = aws_route_table.cloudshelf_public_rt.id
}

# Security Group
resource "aws_security_group" "cloudshelf_sg" {
  name        = "cloudshelf-sg"
  description = "Security group for CloudShelf EC2 instance"
  vpc_id      = aws_vpc.cloudshelf_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes NodePort range"
  }

  # Egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudshelf-sg"
  }
}

# EC2 Instance
resource "aws_instance" "cloudshelf_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cloudshelf_sg.id]
  subnet_id              = aws_subnet.cloudshelf_public_subnet.id

  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    github_repo   = var.github_repo
    github_branch = var.github_branch
  })

  tags = {
    Name = "cloudshelf-instance"
  }
  provisioner "remote-exec" {
    inline = [
      # 1. Wait for Cloud-Init to finish installing Docker/Minikube
      "echo 'Waiting for cloud-init to finish...'",
      "cloud-init status --wait",

      # 2. Docker Permissions
      "sudo apt-get update",
      "sudo apt-get install -y maven",
      "sudo usermod -aG docker ubuntu",

      # 3. Start Minikube
      "minikube start --driver=docker --memory=4096 --cpus=2 --force",
      
      # 4. Setup Code
      "rm -rf AWS-CloudShelf-Microservices-Project", # Clean up old runs
      "git clone https://github.com/Shantanumtk/AWS-CloudShelf-Microservices-Project.git",
      "cd AWS-CloudShelf-Microservices-Project/spring-microservices-bookstore-demo",
      "chmod +x deploy.sh",

      # 5. Run Deploy 
      "sg docker -c './deploy.sh'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/../.ssh/cloudshelf-key")
      host        = self.public_ip
    }
  }
}