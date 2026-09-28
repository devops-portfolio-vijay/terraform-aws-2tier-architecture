# ==========================================
# AWS PROVIDER
# ==========================================

provider "aws" {
  region = var.aws_region
}

# ==========================================
# VPC
# ==========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-2tier-vpc"
  }
}

# ==========================================
# PUBLIC SUBNET - AZ1
# ==========================================

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "2tier-public-az1"
  }
}

# ==========================================
# PUBLIC SUBNET - AZ2
# ==========================================

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "2tier-public-az2"
  }
}

# ==========================================
# PRIVATE SUBNET - AZ1
# ==========================================

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "2tier-private-az1"
  }
}

# ==========================================
# PRIVATE SUBNET - AZ2
# ==========================================

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "2tier-private-az2"
  }
}

# ==========================================
# INTERNET GATEWAY
# ==========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "2tier-internet-gateway"
  }
}

# ==========================================
# PUBLIC ROUTE TABLE
# ==========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "2tier-public-route-table"
  }
}

# ==========================================
# PUBLIC INTERNET ROUTE
# ==========================================

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# ==========================================
# PUBLIC SUBNET AZ1 ASSOCIATION
# ==========================================

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# PUBLIC SUBNET AZ2 ASSOCIATION
# ==========================================

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# ELASTIC IP - NAT AZ1
# ==========================================

resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = {
    Name = "2tier-nat-eip-az1"
  }
}

# ==========================================
# ELASTIC IP - NAT AZ2
# ==========================================

resource "aws_eip" "nat_az2" {
  domain = "vpc"

  tags = {
    Name = "2tier-nat-eip-az2"
  }
}

# ==========================================
# NAT GATEWAY - AZ1
# ==========================================

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "2tier-nat-gateway-az1"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# ==========================================
# NAT GATEWAY - AZ2
# ==========================================

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id

  tags = {
    Name = "2tier-nat-gateway-az2"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# ==========================================
# PRIVATE ROUTE TABLE - AZ1
# ==========================================

resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "2tier-private-route-table-az1"
  }
}

# ==========================================
# PRIVATE ROUTE - AZ1
# ==========================================

resource "aws_route" "private_az1_internet" {
  route_table_id         = aws_route_table.private_az1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az1.id
}

# ==========================================
# PRIVATE SUBNET AZ1 ASSOCIATION
# ==========================================

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_az1.id
}

# ==========================================
# PRIVATE ROUTE TABLE - AZ2
# ==========================================

resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "2tier-private-route-table-az2"
  }
}

# ==========================================
# PRIVATE ROUTE - AZ2
# ==========================================

resource "aws_route" "private_az2_internet" {
  route_table_id         = aws_route_table.private_az2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az2.id
}

# ==========================================
# PRIVATE SUBNET AZ2 ASSOCIATION
# ==========================================

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_az2.id
}

# ==========================================
# ALB SECURITY GROUP
# ==========================================

resource "aws_security_group" "alb" {
  name        = "2tier-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "2tier-alb-sg"
  }
}

# ==========================================
# ALB - HTTP INBOUND
# ==========================================

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# ==========================================
# ALB - OUTBOUND
# ==========================================

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ==========================================
# WEB SERVER SECURITY GROUP
# ==========================================

resource "aws_security_group" "web" {
  name        = "2tier-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "2tier-web-sg"
  }
}

# ==========================================
# WEB - HTTP FROM ALB ONLY
# ==========================================

resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# ==========================================
# WEB - SSH
# ==========================================

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# ==========================================
# WEB - OUTBOUND
# ==========================================

resource "aws_vpc_security_group_egress_rule" "web_all_outbound" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ==========================================
# DATABASE SECURITY GROUP
# ==========================================

resource "aws_security_group" "rds" {
  name        = "2tier-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "2tier-rds-sg"
  }
}

# ==========================================
# RDS - MYSQL FROM WEB SERVERS ONLY
# ==========================================

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_web" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# ==========================================
# RDS - OUTBOUND
# ==========================================

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ==========================================
# EC2 KEY PAIR
# ==========================================

resource "aws_key_pair" "web" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name = "terraform-2tier-key"
  }
}

# ==========================================
# UBUNTU AMI
# ==========================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================
# WEB SERVER - AZ1
# ==========================================

resource "aws_instance" "web_az1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_az1.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  key_name = aws_key_pair.web.key_name

  user_data = <<-EOF
    #!/bin/bash

    apt-get update -y
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker

    docker pull nginx:alpine

    mkdir -p /home/ubuntu/web

    cat > /home/ubuntu/web/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">

      <title>Terraform 2-Tier Application</title>

      <style>
        body {
          font-family: Arial, sans-serif;
          background: #0f172a;
          color: white;
          text-align: center;
          padding-top: 100px;
        }

        .card {
          max-width: 700px;
          margin: auto;
          padding: 40px;
          background: #1e293b;
          border-radius: 15px;
        }

        h1 {
          color: #38bdf8;
        }

        p {
          color: #cbd5e1;
          font-size: 18px;
        }
      </style>
    </head>

    <body>
      <div class="card">
        <h1>Terraform 2-Tier Application</h1>
        <p>Web Server: Private EC2 - Availability Zone 1</p>
        <p>Docker + Nginx</p>
        <p>Infrastructure provisioned using Terraform</p>
      </div>
    </body>
    </html>
    HTML

    docker run -d \
      --name nginx \
      --restart unless-stopped \
      -p 80:80 \
      -v /home/ubuntu/web:/usr/share/nginx/html:ro \
      nginx:alpine
  EOF

  tags = {
    Name = "2tier-web-server-az1"
  }
}

# ==========================================
# WEB SERVER - AZ2
# ==========================================

resource "aws_instance" "web_az2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_az2.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  key_name = aws_key_pair.web.key_name

  user_data = <<-EOF
    #!/bin/bash

    apt-get update -y
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker

    docker pull nginx:alpine

    mkdir -p /home/ubuntu/web

    cat > /home/ubuntu/web/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">

      <title>Terraform 2-Tier Application</title>

      <style>
        body {
          font-family: Arial, sans-serif;
          background: #0f172a;
          color: white;
          text-align: center;
          padding-top: 100px;
        }

        .card {
          max-width: 700px;
          margin: auto;
          padding: 40px;
          background: #1e293b;
          border-radius: 15px;
        }

        h1 {
          color: #38bdf8;
        }

        p {
          color: #cbd5e1;
          font-size: 18px;
        }
      </style>
    </head>

    <body>
      <div class="card">
        <h1>Terraform 2-Tier Application</h1>
        <p>Web Server: Private EC2 - Availability Zone 2</p>
        <p>Docker + Nginx</p>
        <p>Infrastructure provisioned using Terraform</p>
      </div>
    </body>
    </html>
    HTML

    docker run -d \
      --name nginx \
      --restart unless-stopped \
      -p 80:80 \
      -v /home/ubuntu/web:/usr/share/nginx/html:ro \
      nginx:alpine
  EOF

  tags = {
    Name = "2tier-web-server-az2"
  }
}

# ==========================================
# APPLICATION LOAD BALANCER
# ==========================================

resource "aws_lb" "web" {
  name               = "terraform-2tier-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  tags = {
    Name = "terraform-2tier-alb"
  }
}

# ==========================================
# ALB TARGET GROUP
# ==========================================

resource "aws_lb_target_group" "web" {
  name        = "terraform-2tier-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "terraform-2tier-web-target-group"
  }
}

# ==========================================
# REGISTER WEB SERVER AZ1
# ==========================================

resource "aws_lb_target_group_attachment" "web_az1" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_az1.id
  port             = 80
}

# ==========================================
# REGISTER WEB SERVER AZ2
# ==========================================

resource "aws_lb_target_group_attachment" "web_az2" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_az2.id
  port             = 80
}

# ==========================================
# ALB HTTP LISTENER
# ==========================================

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ==========================================
# DB SUBNET GROUP
# ==========================================

resource "aws_db_subnet_group" "main" {
  name = "terraform-2tier-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = {
    Name = "terraform-2tier-db-subnet-group"
  }
}

# ==========================================
# RDS MYSQL DATABASE
# ==========================================

resource "aws_db_instance" "mysql" {
  identifier = "terraform-2tier-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 0

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "terraform-2tier-mysql"
  }
}