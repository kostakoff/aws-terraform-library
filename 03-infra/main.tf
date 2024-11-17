terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.51.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
  access_key = ""
  secret_key = ""
}

# Create VPC local network
resource "aws_vpc" "lab-net" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "lab-net"
  }
}

# Create dmz subnet
resource "aws_subnet" "lab-dmz" {
  vpc_id     = aws_vpc.lab-net.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ca-central-1a"

  tags = {
    Name = "lab-dmz"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "lab-internet" {
  vpc_id = aws_vpc.lab-net.id

  tags = {
    Name = "lab-internet"
  }
}

# Create dmz route table
resource "aws_route_table" "lab-2internet" {
  vpc_id = aws_vpc.lab-net.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab-internet.id
  }

  tags = {
    Name = "lab-2internet"
  }
}

# Create dmz to internet route table association
resource "aws_route_table_association" "lab-dmz2internet" {
  subnet_id      = aws_subnet.lab-dmz.id
  route_table_id = aws_route_table.lab-2internet.id
}

# Create default security group for ec2
resource "aws_security_group" "lab-default" {
  name = "lab-default-security-group"
  description = "lab-default-security-group"
  vpc_id = aws_vpc.lab-net.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
  tags = {
    "Name" = "lab-default"
  }
}

# Create network interface for infra
resource "aws_network_interface" "lab-infra" {
  subnet_id       = aws_subnet.lab-dmz.id
  security_groups = [aws_security_group.lab-default.id]

  tags = {
    Name = "lab-infra"
  }
}

# Create infra public ip
resource "aws_eip" "lab-infra" {
  vpc = true
  network_interface = aws_network_interface.lab-infra.id
  depends_on = [
    aws_internet_gateway.lab-internet,
    aws_network_interface.lab-infra,
    aws_instance.lab-infra
  ]

  tags = {
    Name = "lab-infra"
  }
}

# Create infra server
resource "aws_instance" "lab-infra" {
  ami           = "ami-0dae3a932d090b3de"
  instance_type = "t2.micro"
  availability_zone = "ca-central-1a"
  key_name = "main-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.lab-infra.id
  }

  tags = {
    Name = "lab-infra"
  }
}


