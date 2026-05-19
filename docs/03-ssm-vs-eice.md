# SSM vs EICE

Both reach a private EC2 without a public IP and without a bastion.
They solve slightly different problems.

## SSM Session Manager

- Agent-based: the SSM agent runs on the instance and holds an
  outbound connection to the SSM service. The control plane sends
  commands down that channel.
- No SSH involved. You get a shell through the AWS CLI
  (`aws ssm start-session`).
- Instance needs the SSM agent, an instance profile with
  `AmazonSSMManagedInstanceCore`, and reachability to SSM endpoints
  (either through a NAT gateway or via three VPC interface endpoints:
  ssm, ssmmessages, ec2messages).
- Supports arbitrary TCP port forwarding
  (`AWS-StartPortForwardingSession`).
- Session logs can be streamed to S3 and CloudWatch, which auditors
  like.
- Works on Windows and Linux.

## EICE (EC2 Instance Connect Endpoint)

- Endpoint-based: an AWS-managed ENI in your VPC. No agent on the
  instance beyond stock `ec2-instance-connect`.
- Uses real SSH underneath. You get OpenSSH behaviour (known_hosts,
  config file, ProxyJump, `scp`, `sftp`).
- Instance needs an SSH daemon and `ec2-instance-connect` (bundled
  into AL2/AL2023 and recent Ubuntu).
- Port forwarding only via SSH's `-L` inside the EICE tunnel; not a
  general TCP forwarder.
- Session auditing happens through CloudTrail
  (`OpenTunnel` events) and the instance's own `sshd` logs.

## Which to pick

| Situation                                | Pick  |
|------------------------------------------|-------|
| You want `scp`, `rsync`, SSH keys, SFTP  | EICE  |
| Fleet of servers, no sshd, Windows mixed | SSM   |
| Audit requirement: record every keystroke | SSM   |
| Running on an AMI where you cannot install agents | EICE |
| Just want to port-forward to an RDS endpoint through a jump host | SSM port forwarding is simpler |
| You care about keeping the attack surface literally zero in IAM: only `ec2-instance-connect:OpenTunnel`, not the full SSM API | EICE |

In practice I use both. SSM for "run this command on 40 instances",
EICE for "I need to actually sit on this one box for 20 minutes and
debug". The Terraform in this repo does EICE because it is the piece
most teams don't know about yet.
