output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_az1" {
  description = "Public subnet in AZ 1"
  value       = aws_subnet.public_az1.id
}

output "public_subnet_az2" {
  description = "Public subnet in AZ 2"
  value       = aws_subnet.public_az2.id
}

output "private_subnet_az1" {
  description = "Private subnet in AZ 1"
  value       = aws_subnet.private_az1.id
}

output "private_subnet_az2" {
  description = "Private subnet in AZ 2"
  value       = aws_subnet.private_az2.id
}

output "web_server_az1_id" {
  description = "Web server AZ1 instance ID"
  value       = aws_instance.web_az1.id
}

output "web_server_az2_id" {
  description = "Web server AZ2 instance ID"
  value       = aws_instance.web_az2.id
}

output "web_server_az1_private_ip" {
  description = "Web server AZ1 private IP"
  value       = aws_instance.web_az1.private_ip
}

output "web_server_az2_private_ip" {
  description = "Web server AZ2 private IP"
  value       = aws_instance.web_az2.private_ip
}