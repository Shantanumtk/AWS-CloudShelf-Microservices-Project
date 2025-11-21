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

# SSH Key
resource "tls_private_key" "cloudshelf_key" {
  count     = fileexists("${path.module}/../.ssh/cloudshelf-key.pem") ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  count           = fileexists("${path.module}/../.ssh/cloudshelf-key.pem") ? 0 : 1
  content         = tls_private_key.cloudshelf_key[0].private_key_pem
  filename        = "${path.module}/../.ssh/cloudshelf-key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "cloudshelf_key" {
  key_name   = "cloudshelf-key"
  public_key = fileexists("${path.module}/../.ssh/cloudshelf-key.pem") ? file("${path.module}/../.ssh/cloudshelf-key.pub") : tls_private_key.cloudshelf_key[0].public_key_openssh

  tags = {
    Name = "cloudshelf-key"
  }
}

# EC2 Instance
resource "aws_instance" "cloudshelf_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.cloudshelf_key.key_name
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
}