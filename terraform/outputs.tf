# Application Access
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (use this to access the web app)"
  value       = aws_lb.alb.dns_name
  sensitive   = false
}

output "web_app_url" {
  description = "Full HTTP URL to access the Joget application"
  value       = "http://${aws_lb.alb.dns_name}"
  sensitive   = false
}

# Infrastructure Insights
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.hybrid_vpc.id
  sensitive   = false
}

output "web_instance_ids" {
  description = "EC2 Instance IDs for the Joget web servers"
  value       = aws_instance.web_app[*].id
  sensitive   = false
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (accessible only from web servers within VPC)"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = false # Endpoint is not secret; password is separate
}

# Connectivity & Debugging (Optional but helpful)
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
  sensitive   = false
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
  sensitive   = false
}

# Security
output "web_security_group_id" {
  description = "Security Group ID attached to web servers"
  value       = aws_security_group.web_sg.id
  sensitive   = false
}

output "db_security_group_id" {
  description = "Security Group ID attached to RDS"
  value       = aws_security_group.db_sg.id
  sensitive   = false
}