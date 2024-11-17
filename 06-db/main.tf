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

  # allow icmp
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = -1
    to_port = -1
    protocol = "icmp"
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
  
  tags = {
    "Name" = "lab-2nat"
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

### AWS RDS - DataBase server

# Create db subnet A and B
resource "aws_subnet" "lab-db-a" {
  vpc_id     = aws_vpc.lab-net.id
  cidr_block = "10.0.20.0/25"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "lab-db-a"
  }
}
resource "aws_subnet" "lab-db-b" {
  vpc_id     = aws_vpc.lab-net.id
  cidr_block = "10.0.20.128/25"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "lab-db-b"
  }
}

# Create db subnet to nat route table association
resource "aws_route_table_association" "lab-db-a2nat" {
  subnet_id = aws_subnet.lab-db-a.id
  route_table_id = aws_route_table.lab-nat.id
}
resource "aws_route_table_association" "lab-db-b2nat" {
  subnet_id = aws_subnet.lab-db-b.id
  route_table_id = aws_route_table.lab-nat.id
}

# Create security group for db server
resource "aws_security_group" "lab-db" {
  name = "lab-db-security-group"
  description = "lab-db-security-group"
  vpc_id = aws_vpc.lab-net.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
  }

  tags = {
    "Name" = "lab-db"
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "lab-db" {
  name       = "lab-db"
  subnet_ids = [aws_subnet.lab-db-a.id, aws_subnet.lab-db-b.id]

  tags = {
    Name = "lab-db"
  }
}

resource "aws_db_instance" "lab-db" {
  allocated_storage    = 10
  db_name              = "postgres"
  engine               = "postgres"
  engine_version       = "12.10"
  instance_class       = "db.t3.micro"
  username             = "postgres"
  password             = "postgres"
  skip_final_snapshot  = true
  
  db_subnet_group_name = aws_db_subnet_group.lab-db.id
  vpc_security_group_ids = [ aws_security_group.lab-db.id ]
}
