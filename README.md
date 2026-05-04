# Bastionless EC2 SSH

SSH into a private-subnet EC2 without a bastion host, without a public
IP on the box, without a long-lived SSH key on disk anywhere. Uses
EC2 Instance Connect Endpoint (EICE), which AWS launched in 2023 and
most tutorials still have not caught up on.

Start with [docs/01-why-bastionless.md](docs/01-why-bastionless.md).
