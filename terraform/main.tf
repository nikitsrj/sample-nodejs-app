provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "tfstates3975050281564"
    key            = "ec2/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "your-lock-table"
    encrypt        = true
  }
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "githubcikey"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_app" {
  ami           = "ami-0ebfd941bbafe70c6"  # Replace with your AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name
  security_groups = [
    aws_security_group.allow_ssh_http.name,
  ]

  tags = {
    Name = "GitHub-CI-EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y nginx1
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
}

output "instance_public_ip" {
  value = aws_instance.web_app.public_ip
}

output "instance_public_dns" {
  value = aws_instance.web_app.public_dns
}

