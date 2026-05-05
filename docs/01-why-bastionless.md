# Why bastionless

The standard "SSH into a private EC2" setup, for years, has been:

1. Put the real workload in a private subnet.
2. Put a small bastion/jump host in a public subnet.
3. SSH to the bastion, then SSH from there to the workload.

It works. It is also a bunch of moving pieces nobody really wants to
own:

- A public IP on the bastion that port scanners find within a minute
  of launch.
- Port 22 open to some CIDR you have to maintain (and which usually
  ends up being `0.0.0.0/0` in staging "temporarily").
- An SSH key on the bastion that half the team has copied to their
  laptop at some point and that never gets rotated.
- A second EC2 instance to patch, reboot, and pay for 24/7 for the
  five minutes a week you actually use it.
- A fallback plan for when the bastion itself is down and you cannot
  reach anything.

## What EICE changes

EC2 Instance Connect Endpoint (EICE) is an AWS-managed endpoint that
lives inside your VPC. You call it with the AWS CLI (your IAM
credentials), it opens a short-lived tunnel to the target instance's
private IP, and your local SSH client talks through that tunnel.

The target instance keeps:

- No public IP.
- No inbound rule for `0.0.0.0/0`.
- No long-lived SSH key you have to hand out.

The thing that opens the door is your IAM identity, which you
rotate/revoke in one place (IAM Identity Center, or your IAM user
console).

## What you give up

Not much, but be honest about it:

- EICE is only for SSH (port 22) and RDP (3389). If you need a random
  TCP port, SSM Session Manager port forwarding is the answer, not
  EICE. See [03-ssm-vs-eice.md](03-ssm-vs-eice.md).
- There is a per-session time limit (1 hour by default, 60 min max
  for SSH connections). Long-running tunnels need a reconnect loop.
- The endpoint itself has a small hourly cost. On most setups this
  is still cheaper than a `t3.nano` bastion running 24/7, but it is
  not zero.

## When to use what

| You want to                    | Use                         |
|--------------------------------|-----------------------------|
| SSH into one private EC2       | EICE                        |
| Shell without SSH at all       | SSM Session Manager         |
| Forward an arbitrary TCP port  | SSM port forwarding         |
| RDP into a Windows EC2         | EICE                        |
| Anything from a locked-down CI runner | SSM (IAM-only, no sockets open) |

If you landed here because you want to kill a bastion, read on; the
Terraform in this repo is the full minimum you need.
