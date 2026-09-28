variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "key_name" {
  type    = string
  default = "terraform-2tier-key"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/terraform-2tier.pub"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}