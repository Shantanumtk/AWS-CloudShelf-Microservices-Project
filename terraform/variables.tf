variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.xlarge"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 24.04 x86_64"
  type        = string
  default     = "ami-0e2c8caa4b6378d8c"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = "cloudshelf-key"
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/Shantanumtk/AWS-CloudShelf-Microservices-Project"
}

variable "github_branch" {
  description = "GitHub branch"
  type        = string
  default     = "main"
}