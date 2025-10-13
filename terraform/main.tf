###############################
# Provider
###############################
provider "aws" {
  region = var.region
}

###############################
# VPC
###############################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project}-vpc"
    Project = var.project
  }
}

###############################
# Internet Gateway
###############################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
  }
}

###############################
# Public Subnet
###############################
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-public-subnet"
    Project = var.project
  }
}

###############################
# Route Table for Public Subnet
###############################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.project}-public-rt"
    Project = var.project
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################
# Security Group (SSH only)
###############################
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-ec2-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }
  ingress {
    description = "App 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_web_cidr]
  }

  ingress {
    description = "App 3001"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = [var.allowed_web_cidr]
  }

  ingress {
    description = "Gateway Port "
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_web_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-ec2-sg"
    Project = var.project
  }
}

###############################
# AMI (Ubuntu 24.04 LTS) via SSM Parameter Store
###############################
# Latest stable AMD64 (x86_64) Ubuntu Noble 24.04 AMI
data "aws_ssm_parameter" "ubuntu_2404_amd64" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

###############################
# EC2 Instance (50 GiB root volume)
###############################
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.ubuntu_2404_amd64.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  # Root volume: 50 GiB gp3
  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
    # Optional tuning:
    # iops       = 3000
    # throughput = 125
  }

  connection {
    type        = "ssh"
    host        = self.public_ip # or self.public_dns
    user        = "ubuntu"       # Ubuntu AMIs use 'ubuntu'
    private_key = file(pathexpand(trimspace(var.ssh_private_key_path)))
    # If you prefer SSH agent instead of private_key, use:
    # agent = true
  }

  # Upload your local script to the instance
  provisioner "file" {
    source      = var.local_script_path
    destination = "/home/ubuntu/install_resources.sh"
  }

  # Make it executable and run it (with sudo)
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install_resources.sh",
      "sudo /home/ubuntu/install_resources.sh"
    ]
  }

  tags = {
    Name    = "${var.project}-ec2"
    Project = var.project
  }
}
