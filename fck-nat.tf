# fck-nat implementation for cost-optimized outbound internet access
# Based on https://fck-nat.dev/stable/

data "aws_availability_zones" "available" {
  state = "available"
}

# Use Amazon Linux 2 AMI for NAT functionality (more reliable than hunting for fck-nat AMI)
data "aws_ami" "amazon_linux" {
  count       = var.enable_fck_nat ? 1 : 0
  most_recent = true
  owners      = ["amazon"] 

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get public subnets for fck-nat instances (they need internet access)
data "aws_subnets" "public" {
  count = var.enable_fck_nat ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Look for subnets with routes to internet gateway (public subnets)
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

# If no subnets found by tag, get all subnets and filter by route table
data "aws_route_tables" "vpc_routes" {
  count  = var.enable_fck_nat ? 1 : 0
  vpc_id = var.vpc_id
}

# Create security group for fck-nat instances
resource "aws_security_group" "fck_nat" {
  count       = var.enable_fck_nat ? 1 : 0
  name        = "${var.resource_prefix}fck-nat${var.resource_suffix}"
  description = "Security group for fck-nat instances"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic to internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  # Allow inbound traffic from private subnets
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Inbound traffic from VPC"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Inbound UDP traffic from VPC"
  }

  # Allow ICMP for debugging
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "ICMP from VPC"
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}fck-nat${var.resource_suffix}"
  })
}

# Create IAM role for fck-nat instances
resource "aws_iam_role" "fck_nat" {
  count = var.enable_fck_nat ? 1 : 0
  name  = "${var.resource_prefix}fck-nat-role${var.resource_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Create instance profile for fck-nat instances
resource "aws_iam_instance_profile" "fck_nat" {
  count = var.enable_fck_nat ? 1 : 0
  name  = "${var.resource_prefix}fck-nat-profile${var.resource_suffix}"
  role  = aws_iam_role.fck_nat[0].name
}

# Attach CloudWatch agent policy for monitoring (optional)
resource "aws_iam_role_policy_attachment" "fck_nat_cloudwatch" {
  count      = var.enable_fck_nat ? 1 : 0
  role       = aws_iam_role.fck_nat[0].name
  policy_arn = "arn:${var.iam_partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Allow fck-nat instances to modify their own source/dest check
resource "aws_iam_role_policy" "fck_nat_ec2_permissions" {
  count = var.enable_fck_nat ? 1 : 0
  name  = "fck-nat-ec2-permissions"
  role  = aws_iam_role.fck_nat[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

# Determine which subnets to use for fck-nat instances
# fck-nat instances need public subnets (with IGW routes) to access the internet
# We'll assume there are public subnets in the same VPC, or create them
locals {
  # For now, we'll use the provided subnets and assume they can route to internet
  # In a production setup, you'd want dedicated public subnets for fck-nat
  fck_nat_subnets = var.enable_fck_nat ? [var.subnet1_id, var.subnet2_id] : []
  fck_nat_azs     = var.enable_fck_nat ? slice(data.aws_availability_zones.available.names, 0, 2) : []
}

# Create fck-nat instances in multiple AZs for high availability
resource "aws_instance" "fck_nat" {
  count                       = var.enable_fck_nat ? length(local.fck_nat_subnets) : 0
  ami                        = data.aws_ami.amazon_linux[0].id
  instance_type              = var.fck_nat_instance_type
  subnet_id                  = local.fck_nat_subnets[count.index]
  vpc_security_group_ids     = [aws_security_group.fck_nat[0].id]
  iam_instance_profile       = aws_iam_instance_profile.fck_nat[0].name
  associate_public_ip_address = true
  source_dest_check          = false  # Critical for NAT functionality

  user_data = base64encode(templatefile("${path.module}/fck-nat-user-data.sh", {
    instance_id = "${var.resource_prefix}fck-nat-${count.index + 1}${var.resource_suffix}"
  }))

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}fck-nat-${count.index + 1}${var.resource_suffix}"
    Type = "fck-nat"
    AZ   = local.fck_nat_azs[count.index]
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Create Elastic IPs for fck-nat instances (optional for static IPs)
resource "aws_eip" "fck_nat" {
  count    = var.enable_fck_nat ? length(local.fck_nat_subnets) : 0
  instance = aws_instance.fck_nat[count.index].id
  vpc      = true

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}fck-nat-eip-${count.index + 1}${var.resource_suffix}"
  })

  depends_on = [aws_instance.fck_nat]
}

# Output fck-nat instance information
output "fck_nat_instance_ids" {
  description = "IDs of the fck-nat instances"
  value       = var.enable_fck_nat ? aws_instance.fck_nat[*].id : []
}

output "fck_nat_private_ips" {
  description = "Private IP addresses of the fck-nat instances"
  value       = var.enable_fck_nat ? aws_instance.fck_nat[*].private_ip : []
}

output "fck_nat_public_ips" {
  description = "Public IP addresses of the fck-nat instances"
  value       = var.enable_fck_nat ? aws_eip.fck_nat[*].public_ip : []
}

# Data source to get route tables for private subnets
data "aws_route_table" "private_subnet1" {
  count     = var.enable_fck_nat ? 1 : 0
  subnet_id = var.subnet1_id
}

data "aws_route_table" "private_subnet2" {
  count     = var.enable_fck_nat ? 1 : 0
  subnet_id = var.subnet2_id
}

# Create routes to fck-nat instances for private subnets
# Route for subnet1 -> fck-nat instance 1
resource "aws_route" "private_subnet1_to_fck_nat" {
  count                  = var.enable_fck_nat ? 1 : 0
  route_table_id         = data.aws_route_table.private_subnet1[0].id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.fck_nat[0].id

  # Ensure fck-nat instance is ready before creating route
  depends_on = [aws_instance.fck_nat]
}

# Route for subnet2 -> fck-nat instance 2 (or 1 if only one instance)
resource "aws_route" "private_subnet2_to_fck_nat" {
  count                  = var.enable_fck_nat ? 1 : 0
  route_table_id         = data.aws_route_table.private_subnet2[0].id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = length(aws_instance.fck_nat) > 1 ? aws_instance.fck_nat[1].id : aws_instance.fck_nat[0].id

  # Ensure fck-nat instance is ready before creating route
  depends_on = [aws_instance.fck_nat]
}