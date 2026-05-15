#!/usr/bin/env bash
# Open a TCP tunnel from a local port to a port on a private EC2 via
# EICE. Useful when a GUI tool (DB client, admin UI) can only talk
# to localhost.
#
# Usage: ./scripts/tunnel.sh <Name-tag or i-xxxx> <remote-port> [local-port]
#
# Example:
#   ./scripts/tunnel.sh db-01 5432 15432
#   # then: psql -h localhost -p 15432 ...
#
# Note: EICE's port target is the SSH daemon's port (22). The actual
# port forwarding is done by SSH itself, inside the EICE tunnel. So
# the remote port here is the one your SSH daemon forwards to via
# -L — it doesn't bypass sshd.

set -euo pipefail

target="${1:-}"
remote_port="${2:-}"
local_port="${3:-$remote_port}"

if [[ -z "$target" || -z "$remote_port" ]]; then
  echo "usage: $0 <Name-tag or i-xxxx> <remote-port> [local-port]" >&2
  exit 1
fi

if [[ "$target" != i-* ]]; then
  instance_id="$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${target}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)"
else
  instance_id="$target"
fi

echo "forwarding localhost:${local_port} -> ${instance_id}:${remote_port} (Ctrl-C to quit)"

# -N: do not run a command, just forward.
# -L: local forward.
# -o ProxyCommand: route the whole SSH session through EICE's
# WebSocket. The 'aws ec2-instance-connect open-tunnel' subcommand
# speaks WebSocket on stdin/stdout, which is exactly what
# ProxyCommand needs.
exec ssh \
  -N \
  -L "${local_port}:localhost:${remote_port}" \
  -o "IdentitiesOnly=yes" \
  -o "ProxyCommand=aws ec2-instance-connect open-tunnel --instance-id ${instance_id}" \
  "ec2-user@${instance_id}"
