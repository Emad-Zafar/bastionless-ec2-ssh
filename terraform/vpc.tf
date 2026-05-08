# Minimum VPC for the demo: two AZs, one private subnet in each, and
# nothing else. The target EC2 lives here. No IGW, no NAT, no public
# subnets. For a real environment you will already have a VPC and
# will not use this file.

data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = var.name }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = data.aws_availability_zones.this.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)

  tags = { Name = "${var.name}-private-${count.index}" }
}

# EICE needs to reach EC2 and EC2 Instance Connect control plane. The
# instance itself does NOT need internet access for SSH to work; this
# VPC endpoint is here so SSM / package installs have a path if you
# enable them later. Delete it if you really want zero egress.
resource "aws_vpc_endpoint" "ssm" {
  count             = 0 # off by default; set to 1 if you want SSM too
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id

  private_dns_enabled = true

  tags = { Name = "${var.name}-ssm-endpoint" }
}
