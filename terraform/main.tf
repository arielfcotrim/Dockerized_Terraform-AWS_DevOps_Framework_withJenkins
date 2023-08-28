# Variable definitions
variable "DOCKER_USERNAME" {}
variable "SERVER_IMAGE" {}
variable "FRONTEND_IMAGE" {}

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
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  enable_dns_support   = true  # Enables DNS resolution
  enable_dns_hostnames = true  # Enables DNS hostnames
}

# Create a public subnet for the frontend
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create a private subnet for the backend/server
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {}

# Create NAT Gateway in the public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Route Table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

# Associate the public route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

# Create a security group which is configured to allow access for React, Express, and MongoDB within the VPC
resource "aws_security_group" "my_security_group" {
  name        = "my_security_group"
  description = "Allows access for React, Express, MongoDB"
  vpc_id      = aws_vpc.main.id
}

# Rule to allow SSH access
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "SSH access from anywhere"
}

# Rule to allow HTTP access
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "HTTP access from anywhere"
}

# Rule to allow HTTPS access
resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "HTTPS access from anywhere"
}

# Rule to allow React app access
resource "aws_security_group_rule" "react" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "App access from anywhere"
}

# Rule to allow Express server access
resource "aws_security_group_rule" "express" {
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "App access from anywhere"
}

# Rule to allow MongoDB access
resource "aws_security_group_rule" "mongodb" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "DB access from anywhere"
}

# Rule to allow all outbound traffic
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_security_group.id
  description       = "Allow all outbound traffic"
}

# Define the EC2 instance for the server/backend
resource "aws_instance" "server" {
  # Specify the Amazon Machine Image ID
  ami           = "ami-040d60c831d02d41c"
  # Define the instance type
  instance_type = "t3.micro"
  # Define the SSH key for the instance
  key_name = "red_project_ssh_key"
  # Associate the instance with the private subnet
  subnet_id     = aws_subnet.private_subnet.id
  # Assign the custom security group to this instance
  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  # User data script to bootstrap the instance on startup
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker pull ${var.DOCKER_USERNAME}/${var.SERVER_IMAGE}
              sudo docker run -d -p 3001:3001 ${var.DOCKER_USERNAME}/${var.SERVER_IMAGE}
              EOF

  tags = {
    Name = "Server"
  }
}

# Define the EC2 instance for the frontend
resource "aws_instance" "frontend" {
  # Specify the Amazon Machine Image ID
  ami           = "ami-040d60c831d02d41c"
  # Define the instance type
  instance_type = "t3.micro"
  # Define the SSH key for the instance
  key_name = "red_project_ssh_key"
  # Associate the instance with the public subnet
  subnet_id     = aws_subnet.public_subnet.id
  # Assign the custom security group to this instance
  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  # User data script to bootstrap the instance on startu
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker pull ${var.DOCKER_USERNAME}/${var.FRONTEND_IMAGE}
              sudo docker run -d -p 3000:3000 ${var.DOCKER_USERNAME}/${var.SERVER_IMAGE}
              EOF

  tags = {
    Name = "Frontend"
  }
}
