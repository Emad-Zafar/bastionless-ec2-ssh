variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "name" {
  description = "Base name used in resource names and tags."
  type        = string
  default     = "eice-demo"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC this stack creates."
  type        = string
  default     = "10.40.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for the private target."
  type        = string
  default     = "t3.micro"
}

# Keep the demo portable: look up the latest Amazon Linux 2023 AMI
# at plan time instead of hardcoding an id.
variable "ami_owner" {
  type    = string
  default = "137112412989" # Amazon
}

variable "ami_name_filter" {
  type    = string
  default = "al2023-ami-2023.*-x86_64"
}
