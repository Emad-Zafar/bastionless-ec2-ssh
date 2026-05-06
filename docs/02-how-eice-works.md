# How EICE works

A one-page mental model so the Terraform in this repo stops looking
like magic.

## The pieces

```
your laptop                AWS
+--------+                 +------------------------------------------+
|        |                 |  account                                 |
| aws    | --- HTTPS --->  |  +------------------------------------+ |
| CLI +  |  (SigV4,        |  |  VPC                                | |
| ssh    |   IAM creds)    |  |                                     | |
|        |                 |  |   +---------+       +-------------+ | |
+--------+                 |  |   |  EICE   | ----> |  private    | | |
                           |  |   | endpoint|  TCP  |  EC2 (:22)  | | |
                           |  |   +---------+       +-------------+ | |
                           |  |     (ENI in a subnet you pick)      | |
                           |  +------------------------------------+ |
                           +------------------------------------------+
```

1. The AWS CLI on your laptop opens an HTTPS connection to the EICE
   service and signs the request with your IAM credentials.
2. EICE checks that your IAM principal has
   `ec2-instance-connect:OpenTunnel` on this specific endpoint +
   instance id (and optionally osuser/private IP).
3. If the check passes, AWS opens a WebSocket tunnel from your laptop
   through the EICE ENI to the target instance's port 22 over the
   VPC's private network.
4. Your local `ssh` runs inside that tunnel through the OpenSSH
   `ProxyCommand` hook.

Only step 4 involves SSH. Everything before it is IAM and TLS.

## What has to be true in the account

- **The endpoint exists.** One per VPC is enough for most setups.
  It is an AWS-managed ENI inside a subnet you choose (private is
  fine; the ENI itself does not need internet access).
- **Target SG allows the endpoint SG on 22.** EICE traffic reaches
  the instance over the normal VPC data plane, so the target's
  security group still has to permit it. The rule is `tcp/22` from
  the EICE endpoint's security group.
- **Target has an SSH daemon listening.** Nothing about EICE sets up
  sshd for you. If your AMI does not run sshd, EICE is not the right
  tool.
- **IAM allows `ec2-instance-connect:OpenTunnel`.** The useful
  resource condition keys are
  `ec2-instance-connect:privateIpAddress` and
  `ec2-instance-connect:remotePort`, so a policy can say "this user
  may only tunnel to port 22".

## What does NOT have to be true

- The target instance does **not** need a public IP.
- The target subnet does **not** need an internet gateway or NAT.
- The target's SG does **not** need `0.0.0.0/0` on 22.
- The target does **not** need the SSM agent (that is SSM, not
  EICE).

## The one gotcha people miss

The temporary SSH public key that EICE pushes into the instance is
delivered via the **EC2 Instance Connect** feature (the thing older
than EICE, and separate from it). That feature is baked into Amazon
Linux and recent Ubuntu AMIs; on a stock Debian or a locked-down
custom AMI you may have to install `ec2-instance-connect` first, or
pre-provision your public key the normal way.

The flow is: EICE opens the TCP tunnel, EC2 Instance Connect pushes
the ephemeral key, sshd lets you in, the key expires 60s later.

## What the scripts in this repo do

- `scripts/connect.sh` — resolve the instance id from a Name tag, then
  `aws ec2-instance-connect ssh ...`. One command.
- `scripts/tunnel.sh` — open a port-forward (e.g. a DB on the
  instance's localhost) through the same mechanism for a tool that
  can only speak to `localhost:5432`.
