#!/bin/bash

set -euo pipefail

upstream="${OMARCHY_PATH:-/usr/share/omarchy}/shell/plugins/lock/Service.qml"
expected="3f0a265a09f7957e8f5d74666595d3136ec64899c414426190460f9e2098e701"

[[ -f "$upstream" ]] || {
  echo "Orbital Lock: upstream lock service not found at $upstream" >&2
  exit 1
}

actual=$(sha256sum "$upstream" | awk '{print $1}')
if [[ "$actual" != "$expected" ]]; then
  echo "Orbital Lock: Omarchy's lock service changed." >&2
  echo "Review and merge upstream authentication/recovery changes before publishing an update." >&2
  echo "Expected: $expected" >&2
  echo "Actual:   $actual" >&2
  exit 1
fi

echo "Orbital Lock: upstream Omarchy lock service matches the reviewed 4.0.1 baseline."
