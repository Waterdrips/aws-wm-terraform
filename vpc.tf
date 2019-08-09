# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_prefix}.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment_name} VPC"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment_name} IGW"
  }
}

# Public subnets
# These will get a 0/0 route to the IGW gateway as below
# The az_count variable determines how many subnets will be created
resource "aws_subnet" "public_subnet" {
  count = var.az_count
  vpc_id = aws_vpc.vpc.id
  cidr_block = "${var.vpc_cidr_prefix}.${count.index}.0/24"
  availability_zone = split(",", lookup(var.availability_zones, var.region))[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name} Public-subnet-${count.index}"
  }
}

# Public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment_name} public-rt"
  }
}

# Attach a 0/0 route to the public route table going to the IGW
resource "aws_route" "internet" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id

  depends_on = ["aws_internet_gateway.igw", "aws_route_table.public_rt"]
}

# Public subnet route table associations
# The az_count variable determines how many associations will be created (one per public subnet)
resource "aws_route_table_association" "public" {
  count = var.az_count
  subnet_id = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

# The public route needs to be the default one (so that the default
# route on the VPC goes to the IGW).
resource "aws_main_route_table_association" "public" {
  vpc_id = aws_vpc.vpc.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT gateway elastic IPs
# The az_count variable determines how many EIPs will be created (one per private subnet)
resource "aws_eip" "nat_gateway" {
  count = var.az_count
  vpc = true
}

# NAT gateways
# The az_count variable determines how many NAT gateways will be created (one per public subnet)
resource "aws_nat_gateway" "nat_gateway" {
  count = var.az_count
  allocation_id = aws_eip.nat_gateway.*.id[count.index]
  subnet_id = aws_subnet.public_subnet.*.id[count.index]
  depends_on = ["aws_internet_gateway.igw", "aws_eip.nat_gateway"]
}

# Private subnets
# The az_count variable determines how many subnets will be created
resource "aws_subnet" "private_subnet" {
  count = var.az_count
  vpc_id = aws_vpc.vpc.id
  cidr_block = "${var.vpc_cidr_prefix}.${50 + count.index}.0/24"
  availability_zone = split(",", lookup(var.availability_zones, var.region))[count.index]
  map_public_ip_on_launch = false

  tags =  {
    Name = "Private-subnet-${count.index + 1}"
  }
}
resource "aws_route_table" "private_rt" {
  count = var.az_count
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Private-rt-${count.index + 1}"
  }
}

# Attach 0/0 route to private route tables going to the NAT gateways
resource "aws_route" "nat" {
  count = var.az_count
  route_table_id = aws_route_table.private_rt.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.*.id[count.index]
}

# Associate the private route tables with the private subnets
resource "aws_route_table_association" "private" {
  count = var.az_count
  subnet_id = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = aws_route_table.private_rt.*.id[count.index]
}

# Security group allowing internal traffic (inside VPC)
resource "aws_security_group" "internal" {
  vpc_id = aws_vpc.vpc.id
  name = "${var.environment_name}-internal"
  description = "Allow internal traffic"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = aws_subnet.public_subnet.*.cidr_block
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = aws_subnet.private_subnet.*.cidr_block
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name} internal"
  }
}



# Security group allowing inbound HTTPS from anywhere
resource "aws_security_group" "external" {
  vpc_id = aws_vpc.vpc.id
  name = "inbound"
  description = "Allow inbound HTTPS traffic"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name} inbound"
  }
}