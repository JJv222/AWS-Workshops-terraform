resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-igw" }
}

# Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.public_availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-subnet-${var.public_availability_zones[count.index]}" }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.private_availability_zones[count.index]
  tags = { Name = "${var.project_name}-private-subnet-${var.private_availability_zones[count.index]}" }
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Frontend Route - Internet Gateway
resource "aws_route" "internet_acess" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.this.id
}

# Subnet Associations
resource "aws_route_table_association" "frontend" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "backend" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}