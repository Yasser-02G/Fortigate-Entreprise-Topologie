#!/bin/bash
set -e

IFACE="eth0"
IP_ADDR="10.10.10.20/24"
GATEWAY="10.10.10.1"
DNS_SERVER="10.10.10.1"

echo "[+] Configuration réseau du client LAN ($IP_ADDR)..."
ip addr flush dev "$IFACE"
ip addr add "$IP_ADDR" dev "$IFACE"
ip link set "$IFACE" up
ip route replace default via "$GATEWAY"

echo "[+] Configuration du DNS interne FortiGate ($DNS_SERVER)..."
rm -f /etc/resolv.conf
echo "nameserver $DNS_SERVER" > /etc/resolv.conf

echo "[OK] Client LAN configuré. Testez : curl -I http://www.monlab.local"