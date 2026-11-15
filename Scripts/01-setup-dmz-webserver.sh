#!/bin/bash
set -e

IFACE="eth0"
IP_ADDR="10.20.20.10/24"
GATEWAY="10.20.20.1"

echo "[+] Configuration réseau du serveur DMZ ($IP_ADDR)..."
ip addr flush dev "$IFACE"
ip addr add "$IP_ADDR" dev "$IFACE"
ip link set "$IFACE" up
ip route replace default via "$GATEWAY"
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "[+] Installation de Nginx..."
apt-get update -qq && apt-get install -y -qq nginx

echo "[+] Déploiement du portail Web NexaCloud..."
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexaCloud Infrastructure | Portail des Services Hébergés</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; color: #1e293b; margin: 0; }
        header { background: #0f172a; color: #fff; padding: 20px 5%; display: flex; justify-content: space-between; align-items: center; }
        .badge { background: #10b981; color: #fff; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; }
        .hero { background: #1e293b; color: #fff; text-align: center; padding: 60px 5%; }
        .container { max-width: 1000px; margin: 40px auto; padding: 0 5%; display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; }
        .card { background: #fff; padding: 25px; border-radius: 8px; border: 1px solid #e2e8f0; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
        footer { text-align: center; padding: 20px; color: #64748b; font-size: 0.9rem; }
    </style>
</head>
<body>
    <header>
        <strong>NexaCloud Infrastructure</strong>
        <span class="badge">DMZ Opérationnelle</span>
    </header>
    <section class="hero">
        <h1>Portail des Services Hébergés</h1>
        <p>Architecture sécurisée par FortiGate 100F NGFW (NAT / VIP / Split-Horizon DNS)</p>
    </section>
    <main class="container">
        <div class="card"><h3>Hébergement Web</h3><p>Serveur Nginx isolé dans la DMZ (10.20.20.10).</p></div>
        <div class="card"><h3>Protection IPS</h3><p>Filtrage des vulnérabilités critiques en temps réel.</p></div>
        <div class="card"><h3>DNS Split-Horizon</h3><p>Résolution interne (Shadow) et externe (Public) sur monlab.local.</p></div>
    </main>
    <footer>&copy; 2026 NexaCloud Infrastructure — www.monlab.local</footer>
</body>
</html>
EOF

systemctl restart nginx
echo "[OK] Serveur Web DMZ prêt sur http://10.20.20.10"