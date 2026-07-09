# 1. Create the Main VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cell-dino-vpc"
  }
}

# 2. Internet Gateway for Public Subnets
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cell-dino-igw"
  }
}

# 3. Public Subnets (Required for the Application Load Balancer / Ingress)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "cell-dino-public-a"
    "kubernetes.io/role/elb"                  = "1" # Tells K8s ALB controller to use this subnet for public ALBs
    "kubernetes.io/cluster/cell-dino-cluster" = "shared"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "cell-dino-public-b"
    "kubernetes.io/role/elb"                  = "1"
    "kubernetes.io/cluster/cell-dino-cluster" = "shared"
  }
}

# 4. Private Subnets (for EKS Fargate pods running inference)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name                                      = "cell-dino-private-a"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/cell-dino-cluster" = "shared"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name                                      = "cell-dino-private-b"
    "kubernetes.io/role/internal-elb"         = "1"
    "kubernetes.io/cluster/cell-dino-cluster" = "shared"
  }
}

# 5. NAT Gateway Infrastructure (Allows private Fargate pods to securely download code/images from ECR)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Nat Gateway lives in public subnet

  depends_on = [aws_internet_gateway.gw]
}

# 6. Routing Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# 7. Route Table Associations
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}