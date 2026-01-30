data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  # Calculate subnet bits based on VPC CIDR size
  # For /24 VPC: use /28 subnets (16 IPs each, newbits=4)
  # For /16 VPC: use /24 subnets (256 IPs each, newbits=8)
  vpc_prefix_length = tonumber(split("/", var.vpc_cidr)[1])
  subnet_newbits    = local.vpc_prefix_length >= 24 ? 4 : 8
}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}


resource "aws_subnet" "public" {
  count = length(local.azs)

  vpc_id                  = aws_vpc.lab.id
  cidr_block              = cidrsubnet(var.vpc_cidr, local.subnet_newbits, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = var.enable_private_subnets ? length(local.azs) : 0

  vpc_id            = aws_vpc.lab.id
  cidr_block        = cidrsubnet(var.vpc_cidr, local.subnet_newbits, count.index + 8)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${local.azs[count.index]}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })

  depends_on = [aws_internet_gateway.lab]
}

resource "aws_nat_gateway" "lab" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = var.enable_private_subnets ? 1 : 0

  vpc_id = aws_vpc.lab.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway && var.enable_private_subnets ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab[0].id
}

resource "aws_route_table_association" "private" {
  count = var.enable_private_subnets ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_default_security_group" "lockdown" {
  vpc_id = aws_vpc.lab.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-locked"
  })
}

resource "aws_security_group" "ssh" {
  count = var.create_ssh_sg ? 1 : 0

  name        = "${var.name_prefix}-ssh"
  description = "SSH access from allowed IPs"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ssh-sg"
  })
}

resource "aws_security_group" "web" {
  count = var.create_web_sg ? 1 : 0

  name        = "${var.name_prefix}-web"
  description = "HTTP/HTTPS access from allowed IPs"
  vpc_id      = aws_vpc.lab.id

  dynamic "ingress" {
    for_each = var.web_ports
    content {
      description = "Port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_web_cidrs
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-sg"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.lab.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = var.enable_s3_endpoint ? 1 : 0

  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count = var.enable_s3_endpoint && var.enable_private_subnets ? 1 : 0

  route_table_id  = aws_route_table.private[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}