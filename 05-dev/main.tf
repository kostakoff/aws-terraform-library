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

#### create base

# Create VPC local network
resource "aws_vpc" "lab-net" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "lab-net"
  }
}

data "aws_availability_zones" "available" {}

#### crate DMZ

# Create dmz subnet
resource "aws_subnet" "lab-dmz" {
  vpc_id     = aws_vpc.lab-net.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

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
  availability_zone = data.aws_availability_zones.available.names[0]
  key_name = "main-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.lab-infra.id
  }

  tags = {
    Name = "lab-infra"
  }
}

#### create DMZ NAT

# Create nat public ip
resource "aws_eip" "lab-nat" {
  vpc = true
  depends_on = [
    aws_internet_gateway.lab-internet
  ]

  tags = {
    Name = "lab-nat"
  }
}

# Create NAT gateway
resource "aws_nat_gateway" "lab-nat" {
  allocation_id = aws_eip.lab-nat.id
  subnet_id = aws_subnet.lab-dmz.id
  
  tags = {
    "Name" = "lab-nat"
  }
}

resource "aws_route_table" "lab-nat" {
  vpc_id = aws_vpc.lab-net.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab-nat.id
  }
}

### Dev subnet

# Create dev subnet
resource "aws_subnet" "lab-dev" {
  vpc_id     = aws_vpc.lab-net.id
  cidr_block = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "lab-dev"
  }
}

# Create dev to nat route table association
resource "aws_route_table_association" "lab-dev2nat" {
  subnet_id = aws_subnet.lab-dev.id
  route_table_id = aws_route_table.lab-nat.id
}

# Create network interface for default app server
resource "aws_network_interface" "lab-dev-app01" {
  subnet_id       = aws_subnet.lab-dev.id
  security_groups = [aws_security_group.lab-default.id]

  tags = {
    Name = "lab-dev-app01"
  }
}

# Create default app server
resource "aws_instance" "lab-dev-app01" {
  ami           = "ami-0dae3a932d090b3de"
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  key_name = "main-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.lab-dev-app01.id
  }

  tags = {
    "Name" = "lab-dev-app01"
  }
}