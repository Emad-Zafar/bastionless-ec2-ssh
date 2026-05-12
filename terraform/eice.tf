# The EICE endpoint itself is an AWS-managed ENI in the subnet you
# pick. It only needs egress to the target SG on 22. The target SG
# gets the mirroring ingress rule.

resource "aws_security_group" "eice" {
  name_prefix = "${var.name}-eice-"
  description = "EICE endpoint ENI"
  vpc_id      = aws_vpc.this.id

  egress {
    description     = "SSH to targets in this VPC"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.target.id]
  }

  tags = { Name = "${var.name}-eice" }
}

resource "aws_security_group_rule" "target_from_eice" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eice.id
  security_group_id        = aws_security_group.target.id
  description              = "SSH from EICE endpoint"
}

resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = aws_subnet.private[0].id
  security_group_ids = [aws_security_group.eice.id]

  # Preserve client source IP when it reaches sshd. Useful so audit
  # logs on the instance show your laptop's egress IP instead of the
  # endpoint ENI's private IP.
  preserve_client_ip = true

  tags = { Name = "${var.name}-eice" }
}
