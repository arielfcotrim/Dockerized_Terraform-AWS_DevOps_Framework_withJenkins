terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "server" {
  ami           = "ami-0c94855ba95c574c8"
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 3000:3000 $DOCKER_USERNAME/$SERVER_IMAGE
              EOF
}

resource "aws_instance" "frontend" {
  ami           = "ami-0c94855ba95c574c8"
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 3000:3000 $DOCKER_USERNAME/$FRONTEND_IMAGE
              EOF
}
