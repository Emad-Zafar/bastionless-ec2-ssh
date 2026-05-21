# Use cases

Where I actually use this instead of the older bastion pattern.

## 1. Emergency shell on a prod box

You get paged, the app on a private EC2 is misbehaving, nobody has
SSH set up because "you should never SSH into prod". Fine, you still
need to see what is going on. With EICE in place:

```bash
scripts/connect.sh prod-app-1
```

No "where is the bastion key" scramble. The IAM principal is your
regular IdC login, so revoking access later is free.

## 2. One-shot DB migrations through a tunnel

The DB is on a private RDS, not reachable from your laptop. The old
pattern: SSH to a bastion, run `psql` from there, hope `pg_dump`
finishes before SSH times out. The new one:

```bash
scripts/tunnel.sh db-jump-1 5432 15432
# in another tab:
psql -h localhost -p 15432 -U migrator mydb < migration.sql
```

The `db-jump-1` here is a small EC2 in the same VPC that can reach
RDS; the tunnel just gets your laptop onto it. For production you'd
tighten this further (dedicated migration user, audit logging), but
the mechanics are this simple.

## 3. GitHub Actions deploy without a self-hosted runner

The reference pattern in [../.github/workflows/deploy-example.yml](../.github/workflows/deploy-example.yml):
the hosted GitHub runner assumes an IAM role via OIDC and then runs
`aws ec2-instance-connect ssh ... --command "..."`. No static access
keys stored in GitHub, no VPC-connected self-hosted runner, no
public IP on the deploy target. Works as well for a `systemctl
restart` as it does for a full container pull-and-swap.

## 4. Pair debugging with a teammate

Both of you have IAM access. Both of you can connect at the same
time. No shared bastion key to coordinate on. If one of you leaves
the team, IAM is the kill switch — nothing else to rotate.

## 5. Short-lived QA environments

Spin a QA env up for a day, give the tester an IAM role that can
`OpenTunnel` only on that env's EICE endpoint id, scoped to port 22
with the condition in [gotchas.md](gotchas.md). When the env is torn
down, the policy can stay — it references an endpoint id that no
longer exists, so it does nothing.

## Where it is NOT the right fit

- An on-call engineer who only has mobile internet and needs a shell
  through a locked-down network that blocks WebSockets. SSM Session
  Manager through the AWS console is a better fallback.
- A chatty continuous port forward (metrics scraper, log tail).
  Use an endpoint + a small daemon on the instance that pushes to
  CloudWatch/S3 instead.
- Anything on-prem / non-AWS. EICE is an AWS-only mechanism.
