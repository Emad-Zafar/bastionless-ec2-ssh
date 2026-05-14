#!/usr/bin/env bash
# Open an SSH session to a private EC2 via its EICE endpoint.
#
# Usage: ./scripts/connect.sh <Name-tag or i-xxxx> [--user ec2-user]
#
# Needs: aws cli v2, an IAM identity with ec2-instance-connect:OpenTunnel.
# Does NOT need: a public IP, a pre-provisioned SSH key, a bastion.

set -euo pipefail

target="${1:-}"
user="ec2-user"

if [[ -z "$target" ]]; then
  echo "usage: $0 <Name-tag or i-xxxx> [--user <linuxuser>]" >&2
  exit 1
fi
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) user="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Resolve Name tag to instance id if needed.
if [[ "$target" != i-* ]]; then
  instance_id="$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${target}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)"
  if [[ -z "$instance_id" || "$instance_id" == "None" ]]; then
    echo "no running instance with Name=${target}" >&2
    exit 1
  fi
else
  instance_id="$target"
fi

echo "connecting to ${instance_id} as ${user}..."
exec aws ec2-instance-connect ssh \
  --instance-id "$instance_id" \
  --os-user "$user"
