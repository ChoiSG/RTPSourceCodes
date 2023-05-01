# Create the VPC, Subnet, Internet Gateway, and Route Table for a red team engagement 

resource "aws_vpc" "redteam_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.projectname}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.redteam_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.projectname}-public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.redteam_vpc.id
  tags = {
    Name = "${var.projectname}-gw"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.redteam_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.projectname}-public-route"
  }
}

resource "aws_route_table_association" "route_public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}