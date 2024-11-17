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

# Create VPC
resource "aws_vpc" "lab-net" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "lab-net"
  }
}

