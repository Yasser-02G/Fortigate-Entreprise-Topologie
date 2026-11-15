# FortiGate Secure Network Architecture (LAN / WAN / DMZ) & NGFW Lab (FortiOS 7.6.7)

![FortiOS](https://img.shields.io/badge/FortiOS-7.6.7-EE3124?style=for-the-badge&logo=fortinet&logoColor=white)
![GNS3](https://img.shields.io/badge/Simulation-GNS3-0078D4?style=for-the-badge)
![Security](https://img.shields.io/badge/NGFW-IPS_%7C_SSL_Inspection_%7C_Split_DNS-10B981?style=for-the-badge)

This project demonstrates the full deployment of a perimeter enterprise network architecture in **GNS3** built around a **FortiGate** Next-Generation Firewall running **FortiOS 7.6.7**. It covers multi-zone segmentation (**LAN**, **WAN**, **DMZ**), Network Address Translation (**SNAT** and **DNAT / Virtual IP**), **Split-Horizon DNS** resolution, and advanced **NGFW / UTM** security profiles (IPS, AntiVirus, Web Filter, Application Control, and SSL/TLS inspection).

---

## 1. Network Architecture & Topology

![Schéma réseau FortiGate LAN-WAN-DMZ](./Architecture%20FortiGate%20LAN-WAN-DMZ.png)

> _Overview of allowed traffic flows (green), implicitly blocked traffic (red), and Virtual IP DNAT translations (dashed blue)._

### IP Addressing Plan & Zone Segmentation

| Security Zone | FortiGate Interface | Subnet                                        | Gateway / Interface IP  | Hosts & Roles                                                                                                                                                                 |
| :------------ | :------------------ | :-------------------------------------------- | :---------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LAN Zone**  | `Port2` (`LAN`)     | `10.10.10.0/24`                               | `10.10.10.1`            | • `USER-LINUX` (`10.10.10.10`): Internal client workstation<br>• `USER-ALPINET` (`10.10.10.11`): User endpoint<br>• `ADMIN-LINUX` (`10.10.10.20`): Administrator workstation  |
| **DMZ Zone**  | `Port3` (`DMZ`)     | `10.20.20.0/24`                               | `10.20.20.1`            | • `WEB-SERVER-1` (`10.20.20.10`): Primary Web Server (Nginx)<br>• `WEB-SERVER-2` (`10.20.20.11`): Secondary Web Server<br>• `DMZ-INT` (`10.20.20.20`): Internal DMZ test host |
| **WAN Zone**  | `Port1` (`WAN`)     | `192.0.2.0/24` _(Lab NAT: `192.168.75.0/24`)_ | DHCP (`192.168.75.132`) | • Internet Cloud & external clients (`WEB-USER`)                                                                                                                              |

---

## 2. Repository Structure

```text
Fortigate-Configuration/
├── Schéma réseau FortiGate LAN-WAN-DMZ.png   # Logical architecture & traffic flow diagram
├── README.md                                  # Complete project documentation
│
├── Fortigate-CLI/                             # Modular FortiOS 7.6.7 CLI configuration files
│   ├── 01-interfaces-routing.txt              # Physical interfaces, roles, and default static route
│   ├── 02-objects-vip-policies.txt            # Address objects, Virtual IP (DNAT), and Firewall Policies
│   ├── 03-split-horizon-dns.txt               # DNS Database configuration (Shadow & Public views)
│   └── 04-ngfw-security-profiles.txt          # IPS, AntiVirus, Web Filter, and SSL Inspection profiles
│
├── GNS3-Topologie/                            # Exportable GNS3 project files
│   ├── project.gns3                           # GNS3 topology file
│   └── project-files/                         # QEMU, Docker, Dynamips, and VPCS node files
│
├── Screenshots/                               # GUI configuration & validation screenshots
│   ├── Topologie.png                          # GNS3 workspace topology screenshot
│   ├── Config/                                # FortiGate GUI configuration evidence
│   │   ├── Addresses.png
│   │   ├── Antivirus.png
│   │   ├── APK Controle.png
│   │   ├── DNS Externe.png
│   │   ├── DNS Interne.png
│   │   ├── Interfaces.png
│   │   ├── LAN Interface.png
│   │   ├── LAN IPS.png
│   │   ├── LAN Policy.png
│   │   ├── Policy's.png
│   │   ├── Server IPS.png
│   │   ├── SSL SSH Inspection.png
│   │   ├── Statique Route.png
│   │   ├── VIP.png
│   │   └── WEB Filter.png
│   └── Tests/                                 # Traffic flow validation & testing screenshots
│       ├── Acces au Web server depuis le client WAN.png
│       └── Acces Internet depuis LAN.png
│
└── Scripts/                                   # Linux Bash automation scripts
    ├── 01-setup-dmz-webserver.sh              # Network setup & Nginx web portal deployment in DMZ
    ├── 02-setup-lan-client.sh                 # IP & internal DNS setup for LAN clients
    ├── 03-setup-wan-client.sh                 # IP & external DNS setup for WAN clients
    └── 04-run-validation-tests.sh             # Automated test suite (Ping, DNS, HTTP)
```

---

## 3. Firewall Policy Matrix

Following the **principle of least privilege**, any traffic not explicitly permitted is dropped by the default `Implicit Deny` rule (including any unsolicited inbound `WAN -> LAN` traffic).

| Flow  | Policy       | Incoming Interface | Outgoing Interface | Source                                    | Destination                                         | Service                | NAT                                      | NGFW Profiles                                      |
| :---- | :----------- | :----------------- | :----------------- | :---------------------------------------- | :-------------------------------------------------- | :--------------------- | :--------------------------------------- | :------------------------------------------------- |
| **1** | `LAN-TO-WAN` | `Port2` (LAN)      | `Port1` (WAN)      | `ADDR_LAN` (`10.10.10.0/24`)              | `all`                                               | `ALL`                  | **Enabled** (`SNAT` Outgoing Interface)  | AntiVirus, Web Filter, App Control, SSL Inspection |
| **2** | `WAN-TO-DMZ` | `Port1` (WAN)      | `Port3` (DMZ)      | `all`                                     | `VIP-WEB-SERVER` (`192.168.75.132` ➔ `10.20.20.10`) | `HTTP` / `HTTPS`       | **Disabled** _(handled by VIP DNAT)_     | IPS (`Server`), SSL Inspection                     |
| **3** | `LAN-TO-DMZ` | `Port2` (LAN)      | `Port3` (DMZ)      | `ADDR_ADMIN` (`10.10.10.20`) / `ADDR_LAN` | `ADDR_WEB_DMZ` (`10.20.20.10`)                      | `SSH`, `HTTP`, `HTTPS` | **Disabled** _(direct internal routing)_ | `no-inspection` / `certificate-inspection`         |

---

## 4. Key Implemented Features

### A. Network Address Translation: SNAT & Virtual IP (DNAT)

- **Outbound Internet Access (`SNAT`):** Internal LAN hosts (`10.10.10.0/24`) reach the Internet masqueraded behind the `Port1` (`WAN`) interface IP address.
- **Service Publishing (`VIP-WEB-SERVER`):** External traffic targeting the firewall's WAN IP on port `80` (`192.168.75.132:80`) is translated and forwarded to the internal DMZ web server (`10.20.20.10:80`).

### B. Split-Horizon DNS (`monlab.local`)

Running **FortiOS 7.6.7**, the FortiGate acts as both a recursive and locally authoritative DNS server on `Port1` and `Port2`, enabling seamless access to the web server using the single FQDN **`www.monlab.local`** regardless of client location:

- **`Shadow` View (LAN Clients):** `www.monlab.local` ➔ **`10.20.20.10`** (direct internal access without requiring Hairpin NAT).
- **`Public` View (WAN Clients):** `www.monlab.local` ➔ **`192.168.75.132`** (resolves to the public Virtual IP address).

### C. NGFW Inspection & Perimeter Security

- **IPS (Intrusion Prevention System):** Two dedicated sensors are enforced: `Server IPS` (protecting the DMZ web servers against server-side exploits on `WAN -> DMZ` flows) and `LAN IPS` (protecting client endpoints).
- **Web Filter & Application Control:** Category-based web filtering and granular Layer-7 application control on outbound `LAN -> WAN` traffic.
- **AntiVirus & SSL/TLS Inspection:** Inspects HTTP/HTTPS payloads to detect malware and validate server certificates.

---

## 5. Quick Deployment Guide

### Step 1: Import the GNS3 Topology

1. Open **GNS3** and load `GNS3-Topologie/project.gns3`.
2. Start all network nodes (`FortiGate-FW` running **FortiOS 7.6.7**, `SW-LAN`, `SW-WAN`, `SW-DMZ` switches, and Linux hosts).

### Step 2: Apply the FortiOS 7.6.7 Configuration

Connect to the FortiGate CLI console and execute the configuration blocks from `Fortigate-CLI/` in sequential order:

1. `01-interfaces-routing.txt`
2. `02-objects-vip-policies.txt`
3. `03-split-horizon-dns.txt`
4. `04-ngfw-security-profiles.txt`

### Step 3: Provision the Linux Hosts

Copy the scripts from `Scripts/` onto their respective virtual machines, grant execution permissions (`chmod +x *.sh`), and run them:

```bash
# On WEB-SERVER-1 (DMZ - 10.20.20.10): configures IP and deploys the NexaCloud web portal on Nginx
sudo ./Scripts/01-setup-dmz-webserver.sh

# On ADMIN-LINUX / USER-LINUX (LAN - 10.10.10.0/24): configures IP and internal DNS 10.10.10.1
sudo ./Scripts/02-setup-lan-client.sh

# On the external client (WAN): configures IP and external DNS 192.168.75.132
sudo ./Scripts/03-setup-wan-client.sh
```

---

## 6. Validation & Testing

The `Scripts/04-run-validation-tests.sh` script automates verification across 4 critical checks (gateway reachability, Split-Horizon DNS resolution, direct IP HTTP access, and FQDN HTTP access):

```bash
# Run validation tests from the LAN network
./Scripts/04-run-validation-tests.sh lan

# Run validation tests from the WAN network
./Scripts/04-run-validation-tests.sh wan
```

### Test Summary & Evidence Mapping

| Test Scenario                          | Expected Outcome                                           | Visual Evidence (`Screenshots/Tests/`)         |
| :------------------------------------- | :--------------------------------------------------------- | :--------------------------------------------- |
| **Internet Browsing from LAN**         | Outbound web access operational with SNAT translation      | `Acces Internet depuis LAN.png`                |
| **DMZ Web Server Access from WAN**     | Web portal rendered via Virtual IP (`192.168.75.132`)      | `Acces au Web server depuis le client WAN.png` |
| **Internal DNS Resolution (`Shadow`)** | `www.monlab.local` resolves directly to `10.20.20.10`      | `DNS Interne.png`                              |
| **`WAN -> LAN` Isolation**             | All unsolicited inbound traffic from WAN to LAN is dropped | `Policy's.png`                                 |

---

## 🛠️ Tools & Technologies

![FortiOS](https://img.shields.io/badge/FortiOS-7.6.7-2563EB?style=flat-square)
![GNS3](https://img.shields.io/badge/GNS3-Lab-65A30D?style=flat-square)
![FortiGuard](https://img.shields.io/badge/FortiGuard-IPS_%2F_AV-EA580C?style=flat-square)
![Split DNS](https://img.shields.io/badge/Split--Horizon-DNS-7C3AED?style=flat-square)
![Nginx](https://img.shields.io/badge/Nginx-Web_Server-059669?style=flat-square)
![Linux](https://img.shields.io/badge/Debian_%2F_Alpine-Linux-475569?style=flat-square)

---

## 📌 Key Concepts Covered

- Multi-zone network segmentation (`LAN` / `WAN` / `DMZ`)
- Stateful firewall policy design with implicit deny enforcement
- Source NAT (`SNAT`) and Destination NAT (`Virtual IP` port forwarding)
- Split-Horizon DNS architecture (`Shadow` internal view vs. `Public` external view)
- Next-Generation Firewall (`NGFW`) inspection: `IPS`, `AntiVirus`, `Web Filter`, and `Application Control`
- `SSL/TLS` certificate and deep traffic inspection
- Automated network provisioning and validation using Bash scripting
- Enterprise network topology simulation and packet sniffing in `GNS3`

---

## 👤 Author

**Yasser** — Network & Security Engineer

🔗 GitHub: [@Yasser-02G](https://github.com/Yasser-02G)

Feel free to open an _issue_ or a _pull request_ if you have suggestions to improve this project.

---

> ⚠️ **Disclaimer:** This lab is for educational purposes only. All configurations are simulated in an isolated virtual environment.
