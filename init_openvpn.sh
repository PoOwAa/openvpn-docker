#!/bin/bash

set -e  # Stop script on first error

# Check if VPS IP is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <VPS_IP>"
  exit 1
fi

VPS_IP="$1"

# Check if OpenVPN volume exists
VOLUME_NAME="ovpn-data"
if ! docker volume ls | grep -q "$VOLUME_NAME"; then
  echo "Creating OpenVPN data volume..."
  docker volume create $VOLUME_NAME
else
  echo "Volume $VOLUME_NAME already exists, skipping creation."
fi

# Generate OpenVPN configuration (only if missing)
if ! docker run --rm -v $VOLUME_NAME:/etc/openvpn kylemanna/openvpn ls /etc/openvpn/openvpn.conf >/dev/null 2>&1; then
  echo "Generating OpenVPN server configuration..."
  docker run --rm -v $VOLUME_NAME:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://$VPS_IP
else
  echo "OpenVPN configuration already exists, skipping generation."
fi

# Initialize PKI (only if missing)
if ! docker run --rm -v $VOLUME_NAME:/etc/openvpn kylemanna/openvpn ls /etc/openvpn/pki >/dev/null 2>&1; then
  echo "Initializing OpenVPN PKI..."
  docker run --rm -v $VOLUME_NAME:/etc/openvpn -it kylemanna/openvpn ovpn_initpki
else
  echo "PKI already initialized, skipping."
fi

echo "OpenVPN initialization completed!"