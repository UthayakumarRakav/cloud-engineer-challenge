variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zones" {
  description = "AZs for subnets"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI (eu-west-1)"
  type        = string
  default     = "ami-0ef0fafba270833fc"
}

variable "db_password" {
  description = "RDS root password"
  type        = string
  sensitive   = true
}