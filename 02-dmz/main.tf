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

# Create dmz2internet route table association
resource "aws_route_table_association" "lab-dmz2internet" {
  subnet_id      = aws_subnet.lab-dmz.id
  route_table_id = aws_route_table.lab-2internet.id
}
