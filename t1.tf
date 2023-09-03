resource "aws_instance" "backend_instace" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t2.micro"             
}

data "aws_instance" "backend" {
  instance_id = aws_instance.backend_instace.id
}


resource "aws_instance" "second_instance" {
  ami           = "ami-0123456789abcdef1" 
  instance_type = "t2.micro"              
  user_data     = <<-EOF
    #!/bin/bash
    echo "set BACKEND_IP=${data.aws_instance.backend.private_ip}"
  EOF 
  
}
