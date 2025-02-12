#!/bin/bash

set -e  # Stop script on first error

# Check if VPS IP is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <VPS_IP>"
  exit 1
fi

VPS_IP="$1"
VOLUME_NAME="openvpn_ovpn-data"  # Adjust this if needed based on your stack name

echo "Initializing OpenVPN with VPS IP: $VPS_IP"

# Check if OpenVPN volume exists
if ! docker volume ls | grep -q "$VOLUME_NAME"; then
  echo "Creating OpenVPN data volume..."
  docker volume create "$VOLUME_NAME"
else
  echo "Volume $VOLUME_NAME already exists, skipping creation."
fi

# Generate OpenVPN configuration (only if missing)
if ! docker run --rm -v "$VOLUME_NAME":/etc/openvpn kylemanna/openvpn ls /etc/openvpn/openvpn.conf >/dev/null 2>&1; then
  echo "Generating OpenVPN server configuration..."
  docker run --rm -v "$VOLUME_NAME":/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://$VPS_IP
else
  echo "OpenVPN configuration already exists, skipping generation."
fi

# Ensure the management directive is present in the configuration file.
# Remove any existing management lines and add our desired one.
echo "Adding management directive to openvpn.conf..."
docker run --rm -v "$VOLUME_NAME":/etc/openvpn kylemanna/openvpn sh -c 'sed -i "/^management /d" /etc/openvpn/openvpn.conf && echo "management 0.0.0.0 5555" >> /etc/openvpn/openvpn.conf'

# Initialize PKI (only if missing)
if ! docker run --rm -v "$VOLUME_NAME":/etc/openvpn kylemanna/openvpn ls /etc/openvpn/pki >/dev/null 2>&1; then
  echo "Initializing OpenVPN PKI..."
  docker run --rm -v "$VOLUME_NAME":/etc/openvpn -it kylemanna/openvpn ovpn_initpki nopass
else
  echo "PKI already initialized, skipping."
fi

echo "OpenVPN initialization completed!"