provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "bastionless-ec2-ssh"
      Owner   = "emad"
    }
  }
}
