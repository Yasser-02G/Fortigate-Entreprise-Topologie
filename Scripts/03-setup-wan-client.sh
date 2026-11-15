#!/bin/bash
set -e

IFACE="eth0"
IP_ADDR="192.168.75.50/24"
GATEWAY="192.168.75.2"
FGT_WAN_IP="192.168.75.132"

echo "[+] Configuration réseau du client WAN ($IP_ADDR)..."
ip addr flush dev "$IFACE"
ip addr add "$IP_ADDR" dev "$IFACE"
ip link set "$IFACE" up
ip route replace default via "$GATEWAY"

echo "[+] Configuration du DNS FortiGate WAN ($FGT_WAN_IP)..."
rm -f /etc/resolv.conf
echo "nameserver $FGT_WAN_IP" > /etc/resolv.conf

echo "[OK] Client WAN configuré."