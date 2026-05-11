data "aws_ami" "target" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Target SG: no ingress from the internet. We add the ingress rule
# that permits the EICE endpoint's SG separately in eice.tf so the
# two files can be read independently.
resource "aws_security_group" "target" {
  name_prefix = "${var.name}-target-"
  description = "Private EC2 reached only via EICE"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow outbound (package installs, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-target" }
}

resource "aws_instance" "target" {
  ami                         = data.aws_ami.target.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.target.id]
  associate_public_ip_address = false

  # AL2023 ships ec2-instance-connect already, so no user_data is
  # strictly required. Setting a hostname just makes the prompt
  # readable once you SSH in.
  user_data = <<-EOT
    #!/bin/bash
    hostnamectl set-hostname ${var.name}-target
  EOT

  tags = { Name = "${var.name}-target" }
}
