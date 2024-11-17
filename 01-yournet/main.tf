terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-west-1"
}

# Create VPC
resource "aws_vpc" "lab-net" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "lab-net"
  }
}

