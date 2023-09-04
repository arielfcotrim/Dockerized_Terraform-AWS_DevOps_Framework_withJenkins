# Variable Definitions
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
variable "DOCKER_USERNAME" {}
variable "BACKEND_IMAGE" {}
variable "FRONTEND_IMAGE" {}

# Additional variables for ALB setup
variable "alb_name" {
  description = "The name of the ALB"
  default     = "my-alb"
}

variable "alb_security_group_name" {
  description = "The name of the security group for the ALB"
  default     = "alb-sg"
}

variable "alb_internal" {
  description = "Determines if the ALB will be internal"
  default     = false
}

variable "alb_enable_deletion_protection" {
  description = "Enable or disable deletion protection for the ALB"
  default     = false
}

variable "alb_enable_cross_zone_load_balancing" {
  description = "Enable or disable cross-zone load balancing for the ALB"
  default     = true
}

# Set up the required provider and its version for the Terraform configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  enable_dns_support   = true  # Enables DNS resolution
  enable_dns_hostnames = true  # Enables DNS hostnames
}

# Create a public subnet for the frontend in AZ 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet AZ 1"
  }
}

# Create a public subnet for the frontend in AZ 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet AZ 2"
  }
}

# Create a private subnet for the backend in AZ 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "Private Subnet AZ 1"
  }
}

# Create a private subnet for the backend in AZ 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "Private Subnet AZ 2"
  }
}

# Create an Elastic IP for the NAT Gateway in AZ 1
resource "aws_eip" "nat_1" {}

# Create an Elastic IP for the NAT Gateway in AZ 2
resource "aws_eip" "nat_2" {}

# Create NAT Gateway in the first public subnet (AZ 1)
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

# Create NAT Gateway in the second public subnet (AZ 2)
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_subnet_2.id
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table for the public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Route Table for the first private subnet (AZ 1)
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
}

# Route Table for the second private subnet (AZ 2)
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
}

# Associate the public route table with the first public subnet (AZ 1)
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

# Associate the public route table with the second public subnet (AZ 2)
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

# Associate the first private route table with the first private subnet (AZ 1)
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_1.id
}

# Associate the second private route table with the second private subnet (AZ 2)
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_2.id
}

# Create a security group for the Elastic Load Balancer
resource "aws_security_group" "elb_security_group" {
  name        = "elb_security_group"
  description = "Allows incoming traffic for the Elastic Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow traffic on port 80 for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow traffic on port 3000 for React
  ingress {
    from_port   = 3000
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a security group for the VPC
resource "aws_security_group" "vpc_security_group" {
  name        = "vpc_security_group"
  description = "Allows access for React, Express, MongoDB"
  vpc_id      = aws_vpc.main.id
  # Allow incoming traffic on port 5000 (Express) only from ELB's security group
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [aws_security_group.elb_security_group.name]
  }
}

# Rule to allow internal VPC communication
resource "aws_security_group_rule" "internal_vpc" {
  type        = "ingress"
  from_port   = 0  # can be more specific
  to_port     = 65535  # can be more specific
  protocol    = "tcp"
  self        = true
  security_group_id = aws_security_group.vpc_security_group.id
  description = "Allow internal VPC communication"
}

# Rule to allow all outbound traffic
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_security_group.id
  description       = "Allow all outbound traffic"
}

# Backend Load Balancer (Application Load Balancer)
resource "aws_lb" "backend_lb" {
  name               = "backend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vpc_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "backend-lb"
  }
}

# Backend Load Balancer listener
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_lb.arn
  port              = 3001
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# Backend Target Group for the ALB
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_instance" "backend_instance_1" {
  ami           = "ami-0b4ab8a966e0c2b21"
  instance_type = "t3.micro"
  key_name      = "red_project_ssh_key"
  subnet_id     = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.vpc_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker pull ${var.DOCKER_USERNAME}/${var.BACKEND_IMAGE}
              sudo docker run -d -p 3001:3001 ${var.DOCKER_USERNAME}/${var.BACKEND_IMAGE}
              EOF

  tags = {
    Name = "Backend AZ 1"
  }
}

resource "aws_instance" "backend_instance_2" {
  ami           = "ami-0b4ab8a966e0c2b21"
  instance_type = "t3.micro"
  key_name      = "red_project_ssh_key"
  subnet_id     = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.vpc_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker pull ${var.DOCKER_USERNAME}/${var.BACKEND_IMAGE}
              sudo docker run -d -p 3001:3001 ${var.DOCKER_USERNAME}/${var.BACKEND_IMAGE}
              EOF

  tags = {
    Name = "Backend AZ 2"
  }
}

resource "aws_lb_target_group_attachment" "backend_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_instance_1.id
  port             = 3001
}

resource "aws_lb_target_group_attachment" "backend_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_instance_2.id
  port             = 3001
}


# Application Load Balancer (ELB) for the frontend
resource "aws_lb" "frontend_elb" {
  name               = "frontend-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_security_group.id]
  enable_deletion_protection = false
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_cross_zone_load_balancing   = true
  idle_timeout                       = 400
  enable_http2                       = true
}

# Listener for the ELB
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# Target group for the frontend
resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Define the EC2 instance for the frontend in AZ 1
resource "aws_instance" "frontend_1" {
  ami                    = "ami-0b4ab8a966e0c2b21"
  instance_type          = "t3.micro"
  key_name               = "red_project_ssh_key"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.vpc_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker pull ${var.DOCKER_USERNAME}/${var.FRONTEND_IMAGE}
              BACKEND_URL=http://${aws_lb.backend_lb.dns_name}:3001
              docker run -d -e BACKEND_URL=$BACKEND_URL -p 3000:3000 ${var.DOCKER_USERNAME}/${var.FRONTEND_IMAGE}
              EOF

  tags = {
    Name = "Frontend-AZ1"
  }
}

# Define the EC2 instance for the frontend in AZ 2
resource "aws_instance" "frontend_2" {
  ami                    = "ami-0b4ab8a966e0c2b21"
  instance_type          = "t3.micro"
  key_name               = "red_project_ssh_key"
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.vpc_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker pull ${var.DOCKER_USERNAME}/${var.FRONTEND_IMAGE}
              BACKEND_URL=http://${aws_lb.backend_lb.dns_name}:3001
              docker run -d -e BACKEND_URL=$BACKEND_URL -p 3000:3000 ${var.DOCKER_USERNAME}/${var.FRONTEND_IMAGE}
              EOF

  tags = {
    Name = "Frontend-AZ2"
  }
}

# Associate frontend EC2 instance from AZ 1 with the target group
resource "aws_lb_target_group_attachment" "frontend_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.frontend_1.id
  port             = 3000
}

# Associate frontend EC2 instance from AZ 2 with the target group
resource "aws_lb_target_group_attachment" "frontend_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.frontend_2.id
  port             = 3000
}
