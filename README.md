# Bastionless EC2 SSH

SSH into a private-subnet EC2 without a bastion host, without a
public IP on the box, and without a long-lived SSH key lying around.
It uses EC2 Instance Connect Endpoint (EICE), which AWS launched in
2023 and which most tutorials still have not caught up on.

What this repo gives you:

- A Terraform stack that stands up the whole thing — VPC, private
  subnet, EC2 target, EICE endpoint, SGs wired correctly. One
  `terraform apply`.
- Two shell scripts: `scripts/connect.sh` for a one-shot SSH, and
  `scripts/tunnel.sh` for a port-forward (e.g. onto a DB on the
  instance's localhost).
- A GitHub Actions example that deploys over EICE from a hosted
  runner using OIDC — no stored access keys, no self-hosted runner,
  no public IP on the target.
- Docs that explain the pieces and the sharp edges.

## Why I wrote this

I wanted to kill a bastion host at work and could not find a single
reference repo that put all of VPC + EICE + IAM + a working SSH
command together. The AWS docs cover each piece in isolation; the
glue is left to the reader. This is the glue.

## Try it

```bash
cd terraform
terraform init
terraform apply   # ~2 minutes
cd ..
./scripts/connect.sh "$(terraform -chdir=terraform output -raw instance_name)"
```

You need:

- Terraform ≥ 1.6, AWS CLI v2.
- An IAM identity with `ec2-instance-connect:OpenTunnel`,
  `ec2:DescribeInstances`, and enough EC2/VPC rights to apply the
  Terraform (admin on a sandbox is fine).

Tear down:

```bash
cd terraform && terraform destroy
```

## Read

- [docs/01-why-bastionless.md](docs/01-why-bastionless.md) — what's
  wrong with the bastion pattern and what EICE actually fixes.
- [docs/02-how-eice-works.md](docs/02-how-eice-works.md) — mental
  model: who talks to whom, what SGs need to allow, what IAM gates.
- [docs/03-ssm-vs-eice.md](docs/03-ssm-vs-eice.md) — when SSM
  Session Manager is the better choice and when EICE is.
- [docs/04-use-cases.md](docs/04-use-cases.md) — the handful of
  things I actually use this for.
- [docs/gotchas.md](docs/gotchas.md) — `preserve_client_ip`,
  package deps, the IAM `remotePort` condition, cost.

## Layout

```
terraform/   the whole stack, including EICE endpoint + SG wiring
scripts/     connect.sh and tunnel.sh
docs/        the docs above
.github/     GH Actions deploy example
```

## License

MIT.
