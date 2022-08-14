variable "cidr_block" {
  type = string
}

resource "aws_vpc" "main_vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "App VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "App VPC - Internet Gateway"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  for_each = { for idx, availability_zone_name in data.aws_availability_zones.available.names : idx => availability_zone_name }

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 4, each.key)
  availability_zone = each.value

  tags = {
    Name = "App VPC - Public subnet"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "App VPC - Public route table"
  }
}

resource "aws_route_table_association" "public_rt_subnet_association" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_main_route_table_association" "main_rt_association" {
  vpc_id         = aws_vpc.main_vpc.id
  route_table_id = aws_route_table.main_route_table.id
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "subnets" {
  value = aws_subnet.public_subnet
}