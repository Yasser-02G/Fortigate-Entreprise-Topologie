#!/bin/bash

echo "=================================================="
echo "   SUITE DE TESTS - LAB FORTI-OS 7.6.7"
echo "=================================================="

MODE=$1
if [[ "$MODE" != "lan" && "$MODE" != "wan" ]]; then
    echo "Usage: ./04-run-validation-tests.sh [lan|wan]"
    exit 1
fi

if [ "$MODE" == "lan" ]; then
    GW="10.10.10.1"
    EXPECTED_DNS="10.20.20.10"
else
    GW="192.168.75.132"
    EXPECTED_DNS="192.168.75.132"
fi

echo -n "[1/4] Test connectivité passerelle FortiGate ($GW)... "
ping -c 2 -W 2 "$GW" > /dev/null 2>&1 && echo "PASS" || echo "FAIL"

echo -n "[2/4] Test résolution DNS Split-Horizon (www.monlab.local -> $EXPECTED_DNS)... "
RESOLVED_IP=$(getent hosts www.monlab.local | awk '{print $1}')
if [ "$RESOLVED_IP" == "$EXPECTED_DNS" ]; then
    echo "PASS ($RESOLVED_IP)"
else
    echo "FAIL (Obtenu: ${RESOLVED_IP:-Aucune réponse})"
fi

echo -n "[3/4] Test accès HTTP par IP directe ($EXPECTED_DNS)... "
HTTP_CODE_IP=$(curl -s -o /dev/null -w "\%{http_code}" --connect-timeout 3 "http://$EXPECTED_DNS")
[ "$HTTP_CODE_IP" == "200" ] && echo "PASS (HTTP 200)" \vert{}\vert{} echo "FAIL (Code: $HTTP_CODE_IP)"

echo -n "[4/4] Test accès HTTP par nom de domaine (http://www.monlab.local)... "
HTTP_CODE_DOM=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://www.monlab.local")
[ "$HTTP_CODE_DOM" == "200" ] && echo "PASS (HTTP 200)" \vert{}\vert{} echo "FAIL (Code: $HTTP_CODE_DOM)"

echo "=================================================="