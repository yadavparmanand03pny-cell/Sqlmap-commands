# Aircrack-ng — Complete Reference Guide

> WiFi security auditing suite — packet capture, WEP/WPA/WPA2 key cracking, deauth attacks. Ye ek suite hai, single tool nahi — multiple tools milke kaam karte hain.

---

## 1. Suite Ke Components

| Tool | Purpose |
|---|---|
| `airmon-ng` | Wireless interface ko **monitor mode** mein daalta hai |
| `airodump-ng` | Nearby networks aur clients scan/capture karta hai |
| `aireplay-ng` | Packet injection — deauth attacks, fake authentication |
| `aircrack-ng` | Actual key cracking (captured handshake se) |
| `airdecap-ng` | Encrypted capture file ko decrypt karta hai (key maalum hone ke baad) |
| `airbase-ng` | Fake access point banane ke liye (rogue AP/evil twin) |

---

## 2. Basic Workflow (WPA/WPA2 Handshake Crack Karna)

### Step 1 — Monitor Mode Enable Karo
```bash
airmon-ng check kill    # interfering processes (NetworkManager, wpa_supplicant) band karo
airmon-ng start wlan0
```
Isse interface ka naam change ho jaata hai (jaise `wlan0mon`).

> **Note:** Tumhe pehle bhi NetworkManager restart issue face hua tha `airmon-ng check kill` ke baad — agar wifi wapas chahiye baad mein, `airmon-ng stop wlan0mon` aur `systemctl restart NetworkManager` chalana padega.

### Step 2 — Nearby Networks Scan Karo
```bash
airodump-ng wlan0mon
```
Output mein BSSID (router MAC), channel, ESSID (network name), connected clients dikhte hain.

### Step 3 — Specific Target Pe Focus Karo
```bash
airodump-ng --bssid <target_BSSID> --channel <channel_number> --write capture wlan0mon
```
Ye specific network ka traffic capture karke `capture-01.cap` file mein save karta hai.

### Step 4 — Deauth Attack (Handshake Force Karne Ke Liye)
```bash
aireplay-ng --deauth 10 -a <target_BSSID> -c <client_MAC> wlan0mon
```
- Connected client ko network se forcefully disconnect karta hai
- Client automatically reconnect karta hai → is reconnection ke waqt **4-way handshake** capture ho jaata hai (jo cracking ke liye zaroori hai)
- `-c <client_MAC>` optional hai — na diya to broadcast deauth (sabko disconnect karega us network pe)

### Step 5 — Handshake Capture Confirm Karo
`airodump-ng` window mein top-right corner pe **"WPA handshake: <BSSID>"** dikhega jab successfully capture ho jaaye.

### Step 6 — Key Crack Karo
```bash
aircrack-ng -w /usr/share/wordlists/rockyou.txt capture-01.cap
```
Wordlist attack — agar password wordlist mein hai to crack ho jaayega, WPA/WPA2 mein brute-force practically infeasible hai (dictionary attack hi realistic hai).

---

## 3. Flags — Detailed Table

### airmon-ng
| Flag/Command | Purpose |
|---|---|
| `check` | Interfering processes list karo |
| `check kill` | Interfering processes (NetworkManager, wpa_supplicant) kill karo |
| `start <interface>` | Monitor mode enable karo |
| `stop <interface>` | Monitor mode disable karo, managed mode pe wapas |

### airodump-ng
| Flag | Purpose |
|---|---|
| `--bssid <MAC>` | Specific AP target karo |
| `--channel <num>` / `-c <num>` | Specific channel pe lock karo |
| `--write <name>` / `-w <name>` | Capture file mein save karo |
| `--essid <name>` | Network name se filter karo |
| `--output-format <type>` | Output format specify karo (pcap, csv, etc.) |

### aireplay-ng
| Flag | Purpose |
|---|---|
| `--deauth <count>` | Deauth packets bhejo (count = kitne packets, 0 = continuous) |
| `-a <BSSID>` | Target AP ka MAC |
| `-c <client_MAC>` | Specific client target karo (optional) |
| `--fakeauth <delay>` | Fake authentication (open networks/WEP ke liye) |
| `--arpreplay` | ARP replay attack (WEP cracking ke liye traffic generate karna) |

### aircrack-ng
| Flag | Purpose |
|---|---|
| `-w <wordlist>` | Dictionary/wordlist specify karo |
| `-b <BSSID>` | Specific network target karo (agar capture file mein multiple networks hain) |
| `-e <ESSID>` | Network name se target karo |
| `-p <num>` | Parallel threads/processes |

---

## 4. WEP vs WPA/WPA2 — Approach Alag Hai

| Encryption | Method |
|---|---|
| **WEP** | Traffic injection (ARP replay) se IVs collect karo, statistical attack se key directly crack ho jaati hai (no wordlist needed) — WEP fundamentally broken hai |
| **WPA/WPA2** | Sirf handshake capture + dictionary/brute-force attack — statistical crack possible nahi, password strength pe depend karta hai |
| **WPA3** | Aircrack-ng traditional methods largely ineffective — SAE (Simultaneous Authentication of Equals) offline dictionary attacks prevent karta hai |

---

## 5. Advanced Techniques

### 5.1 GPU-Accelerated Cracking (Hashcat Handoff)
Aircrack-ng CPU-based hai aur slow — capture ko hashcat-compatible format mein convert karke GPU se fast crack kar sakte ho:
```bash
# .cap ko .hccapx mein convert karo (hcxpcapngtool se)
hcxpcapngtool -o output.hccapx capture-01.cap

# hashcat se GPU crack
hashcat -m 22000 output.hccapx rockyou.txt
```
Ye modern approach hai — hashcat mode 22000 WPA/WPA2 ke liye.

### 5.2 PMKID Attack (Handshake Ke Bina Bhi Possible)
Kai routers PMKID (Pairwise Master Key Identifier) leak karte hain bina client ke deauth kiye:
```bash
hcxdumptool -i wlan0mon -o dump.pcapng --enable_status=1
hcxpcapngtool -o hash.22000 dump.pcapng
hashcat -m 22000 hash.22000 rockyou.txt
```
**Advantage:** Client ko deauth karne ki zaroorat nahi (stealthier), sirf AP se hi PMKID capture ho jaata hai agar vulnerable ho.

### 5.3 Rogue AP / Evil Twin (airbase-ng)
```bash
airbase-ng -e "Free_WiFi" -c 6 wlan0mon
```
Fake access point banata hai — captive portal phishing scenarios mein use hota hai (authorized red team engagements mein).

### 5.4 WPS Attack (Reaver Se, Separate Tool)
Agar router pe WPS enabled hai (separate vulnerability), `reaver` tool se PIN brute-force possible hai — aircrack-ng suite ka part nahi hai but commonly saath use hota hai.

---

## 6. Common Issues (Tumhare Setup Se Relevant)

| Issue | Fix |
|---|---|
| `airmon-ng check kill` ke baad WiFi/internet chala jaata hai | Normal hai — monitor mode mein normal connectivity nahi hoti. Wapas chahiye to: `airmon-ng stop wlan0mon` phir `systemctl restart NetworkManager` |
| Interface monitor mode support nahi karta | Wireless adapter chip check karo — kai built-in laptop WiFi cards monitor mode/injection support nahi karte, external USB adapter (Alfa cards common hain) chahiye ho sakta hai |
| Deauth kaam nahi kar raha | Kai modern routers/clients 802.11w (Management Frame Protection) use karte hain jo deauth attacks ko prevent karta hai |

---

## 7. Practice Setup

- Apna khud ka home router use karo practice ke liye (authorized — apna hi network)
- Virtual lab: WiFi Pineapple ya dedicated WiFi practice router setup
- **Kabhi bhi doosre logo ke WiFi networks pe try mat karna bina explicit written authorization ke — ye illegal hai most jurisdictions mein**

---

## 8. Ethical/Scope Reminder

- Sirf apna khud ka network ya explicitly authorized WiFi pentest scope pe use karna
- Deauth attacks doosron ki connectivity disrupt karte hain — bina authorization ke ye disruption illegal hai
- Bug bounty programs mein generally WiFi/physical security scope mein nahi hoti — ye zyada red team/physical pentest engagements ka part hai
