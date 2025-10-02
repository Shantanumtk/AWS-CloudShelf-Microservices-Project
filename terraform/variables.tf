variable "project" {
  description = "Project/name prefix for resources"
  type        = string
  default     = "tf-solo"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "az" {
  description = "Availability Zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair in the target region"
  type        = string
  default     = "my-key-pair-2"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH (22). Use your IP with /32 when possible."
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_web_cidr" {
  description = "CIDR allowed to access app ports (3000, 3001)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 50
}
variable "ssh_private_key_path" {
  description = "Path to the local PEM private key that matches the EC2 key pair"
  type        = string
  default     = " /Users/shantanu/Downloads/my-key-pair-2.pem"
}

variable "local_script_path" {
  description = "Path to the local script you want to run on the instance"
  type        = string
  default     = "/Users/shantanu/AWS-CloudShelf-CPSC-465/install_resources.sh"
}



