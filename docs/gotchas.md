# Gotchas

Things I hit while setting this up on a real account that are not
obvious from the AWS docs.

## `preserve_client_ip = true` requires an SG ingress for your IP

With `preserve_client_ip` on, the packet that lands on the target
EC2 has your laptop's public IP as its source, not the EICE ENI's
private IP. That is nicer for audit logs but breaks the obvious
"allow 22 from the EICE SG" rule — there is no SG in the path when
the source IP has been rewritten to a public one.

Two ways out:

1. Turn `preserve_client_ip` off (the default is fine for most
   teams). Traffic arrives from the EICE ENI and the SG-to-SG rule
   works as written.
2. Keep `preserve_client_ip` on and add a CIDR-based ingress rule for
   your office / VPN / laptop public IPs. Same auditability, but you
   now have an SG ingress for public IPs again. Usually not worth it.

I keep it off by default on team environments and on only when a
specific compliance ask forces it.

Note: the file in this repo keeps it ON to show the option exists;
flip it to `false` in your own copy unless you need it.

## Session timeout is 60 minutes

Hard cap for SSH sessions. If you are running a long migration,
either break it into chunks, or run it with `nohup`/`tmux` on the
instance and reconnect to re-attach.

## `ec2-instance-connect` package

On AL2 and AL2023 this is installed by default. On stock Debian,
Fedora Server, or a custom hardened AMI you may have to install it
first. Symptom: EICE opens the tunnel, OpenSSH starts, then the key
exchange fails because sshd never gets the ephemeral key.

Quick check on the instance:

```bash
systemctl list-units | grep ec2-instance-connect
```

## IAM — the `remotePort` condition

Put this on the policy that grants `OpenTunnel`:

```json
"Condition": {
  "NumericEquals": { "ec2-instance-connect:remotePort": 22 }
}
```

Without it, anyone with the policy can tunnel to _any_ port on the
instance (e.g. an internal admin port they are not supposed to
reach). The IAM docs show this condition but bury it.

## EICE endpoint in only one AZ

The endpoint resource takes a single `subnet_id`. If the target
instance is in a different AZ, the tunnel still works — EICE routes
across AZs for you — but you pay inter-AZ data transfer. For a
heavy use case put the endpoint in the AZ where the instance lives.

## CloudTrail

The audit record for an SSH session is split in two places: the
`OpenTunnel` event lands in CloudTrail (management events, no data
events needed), and the actual shell activity is in the instance's
`/var/log/secure` or systemd journal. Keep both if you care about
forensics.

## Cost

EICE endpoint is billed per hour the endpoint exists + per GB of
data through it. On a team where two people SSH in for half an hour
a day total, this is cents a month. On a team that runs a chatty
data pipeline through a port-forward 24/7, do the math before you
assume it is cheaper than a NAT gateway.

## Terraform resource name

The provider calls it `aws_ec2_instance_connect_endpoint` — note the
underscores and the word order. I lose 30 seconds every time I try
to guess it.
