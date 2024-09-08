terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "kubespray_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kubespray-vpc"
    project = var.project_tag
  }

}

# Subnet
resource "aws_subnet" "kubespray_subnet" {
  vpc_id     = aws_vpc.kubespray_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "kubespray-subnet"
    project = var.project_tag
  }
}

# Internet Gateway
resource "aws_internet_gateway" "kubespray_igw" {
  vpc_id = aws_vpc.kubespray_vpc.id
  tags = {
    Name = "kubespray-internet-gateway"
    project = var.project_tag
  }
}

# Route Table
resource "aws_route_table" "kubespray_route_table" {
  vpc_id = aws_vpc.kubespray_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubespray_igw.id
  }

  tags = {
    Name = "kubespray-route-table"
    project = var.project_tag
  }
}

# Route Table Association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.kubespray_subnet.id
  route_table_id = aws_route_table.kubespray_route_table.id
}

# Security Group to allow SSH from a specific IP
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.kubespray_vpc.id
  name   = "allow_ssh_from_specific_ip"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_public_ip}/32"]  # Replace with your public IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-sg"
    project = var.project_tag
  }
}

# Key Pair (Make sure you already have a key or create one via AWS Console)
resource "aws_key_pair" "kubespray_key" {
  key_name   = "kubespray-key"
  public_key = file("./private_admin_id_ed25519.pub")
}

# EC2 Instances
resource "aws_instance" "kubespray_instance" {
  count         = 4
  # ami           = "ami-0c6da69dd16f45f72"  # Amazon Linux 2023 AMI
  ami           = "ami-01427dce5d2537266" # Debian 12
  # instance_type = "t3.micro" # TODO later try if two micro instances can be used with two small.½
  instance_type = "t3.small" # Minimum for control plane nodes: https://github.com/kubernetes-sigs/kubespray/blob/master/README.md
  subnet_id     = aws_subnet.kubespray_subnet.id
  key_name      = aws_key_pair.kubespray_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "kubespray-instance-${count.index}"
    project = var.project_tag
  }
}

resource "aws_instance" "installer_instance" {
  ami           = "ami-01427dce5d2537266" # Debian 12
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.kubespray_subnet.id
  key_name      = aws_key_pair.kubespray_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "installer-instance"
    project = var.project_tag
  }
}
