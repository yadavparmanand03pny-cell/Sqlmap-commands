# Wireshark — Complete Reference Guide

> Network protocol analyzer — packet capture aur deep traffic inspection ke liye industry-standard tool.

---

## 1. Wireshark Kya Karta Hai

Network interface pe se guzarne wale **har packet ko capture** karta hai aur unko human-readable format mein dikhata hai — protocol layer by layer (Ethernet → IP → TCP/UDP → Application layer jaise HTTP/DNS/TLS).

**Use cases:** Traffic analysis, credential sniffing (unencrypted protocols), MITM verification, malware traffic analysis, protocol debugging, CTF challenges.

---

## 2. Interface & Basic Workflow

| Step | Action |
|---|---|
| 1 | Capture interface select karo (eth0, wlan0, etc.) |
| 2 | Capture filter laga sakte ho (optional, capture start hone se pehle) |
| 3 | Capture start karo (blue shark fin button) |
| 4 | Traffic generate hone do / already ho raha ho |
| 5 | Capture stop karo (red square button) |
| 6 | Display filter laga ke analyze karo |

---

## 3. Capture Filters vs Display Filters — Fark Samjho

| Type | Kab Apply Hota Hai | Syntax Style |
|---|---|---|
| **Capture Filter** | Capture shuru hone se **pehle** — sirf matching packets capture honge | BPF syntax (`host`, `port`, `net`) |
| **Display Filter** | Capture ke **baad**, already collected packets pe filter | Wireshark syntax (`ip.addr`, `http`, `tcp.port`) |

---

## 4. Capture Filters — Common Examples

| Filter | Kya Capture Karta Hai |
|---|---|
| `host 192.168.1.10` | Sirf us IP se/ko traffic |
| `net 192.168.1.0/24` | Poore subnet ka traffic |
| `port 80` | Sirf HTTP traffic |
| `port 443` | Sirf HTTPS traffic |
| `tcp` | Sirf TCP packets |
| `udp` | Sirf UDP packets |
| `host 192.168.1.10 and port 80` | Combine conditions |
| `not arp` | ARP packets exclude karo (bahut noise hota hai) |

---

## 5. Display Filters — Master Table

| Filter | Purpose |
|---|---|
| `ip.addr == 192.168.1.10` | Specific IP ka traffic (source ya destination) |
| `ip.src == 192.168.1.10` | Sirf source wale packets |
| `ip.dst == 192.168.1.10` | Sirf destination wale packets |
| `tcp.port == 80` | Specific port |
| `http` | Sirf HTTP traffic |
| `http.request.method == "POST"` | Sirf POST requests |
| `http contains "password"` | Payload mein "password" text dhoondo (plaintext creds) |
| `dns` | Sirf DNS queries/responses |
| `dns.qry.name contains "target.com"` | Specific domain ke DNS queries |
| `tcp.flags.syn == 1 and tcp.flags.ack == 0` | SYN packets (connection attempts, port scan detection) |
| `tcp.analysis.retransmission` | Retransmitted packets (network issues) |
| `ftp` | FTP traffic (often plaintext credentials) |
| `telnet` | Telnet traffic (plaintext) |
| `tls.handshake.type == 1` | TLS Client Hello (SNI dekhne ke liye — kis domain se connect ho raha hai) |
| `arp` | ARP traffic — spoofing detection ke liye useful |
| `icmp` | Ping/traceroute traffic |
| `eth.addr == aa:bb:cc:dd:ee:ff` | Specific MAC address |

---

## 6. Follow Stream — Sabse Useful Feature

Kisi bhi packet pe right-click → **Follow → TCP Stream** (ya UDP/HTTP Stream)

- Poori conversation ek readable format mein dikh jaati hai — request + response dono
- **Plaintext protocols (HTTP, FTP, Telnet) mein credentials seedhe dikh jaate hain** is feature se
- Color coding: red = client se server, blue = server se client

---

## 7. Practical Use Cases (Bug Bounty/Pentest Context)

### 7.1 Plaintext Credential Sniffing (Authorized Network Pe)
```
Filter: http.request.method == "POST" and http contains "password"
```
Follow HTTP Stream se pura login request/response dekh sakte ho.

### 7.2 DNS Exfiltration/Anomaly Detection
```
Filter: dns.qry.name and dns.qry.type == 16
```
Unusual TXT record queries suspicious data exfiltration indicate kar sakte hain.

### 7.3 TLS SNI Extraction (Domain Fronting Detection)
```
Filter: tls.handshake.extensions_server_name
```
Encrypted traffic mein bhi, TLS handshake ke Client Hello mein domain name (SNI) plaintext dikhta hai.

### 7.4 ARP Spoofing Detection
```
Filter: arp.duplicate-address-detected
```
Same IP ke multiple MAC addresses = possible ARP spoofing/MITM indicator.

---

## 8. Statistics Menu — Deep Analysis Tools

| Menu | Purpose |
|---|---|
| **Statistics → Protocol Hierarchy** | Kaunse protocols kitna traffic use kar rahe hain, overview |
| **Statistics → Conversations** | Kaunse hosts ke beech kitni communication hui |
| **Statistics → Endpoints** | Saare unique IPs/MACs jo traffic mein dikhe |
| **Statistics → HTTP → Requests** | Saare HTTP requests ka summary |
| **File → Export Objects → HTTP** | HTTP traffic se files (images, docs) directly extract karo |

---

## 9. Command-Line Version — tshark

GUI ke bina, terminal se capture/analyze karne ke liye:

```bash
# Live capture, specific interface
tshark -i eth0

# Capture aur file mein save
tshark -i eth0 -w capture.pcap

# Existing pcap read karo with display filter
tshark -r capture.pcap -Y "http.request"

# Sirf specific fields extract karo (jaise CSV export)
tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri
```

---

## 10. Advanced Techniques

### 10.1 Coloring Rules
View → Coloring Rules — custom rules bana sakte ho jaise saare packets jisme "password" text ho unko red highlight karna, taaki scroll karte waqt turant dikhe.

### 10.2 Decrypting TLS Traffic (Agar Key Available Hai)
Edit → Preferences → Protocols → TLS → "(Pre)-Master-Secret log filename" — agar tumhare paas SSLKEYLOGFILE hai (browser se export ki hui), to encrypted HTTPS traffic bhi decrypt karke dekh sakte ho.

```bash
# Browser environment variable set karo capture se pehle
export SSLKEYLOGFILE=~/sslkeys.log
```

### 10.3 Custom Lua Dissectors
Agar koi custom/proprietary protocol analyze karna ho jo Wireshark natively nahi samajhta, Lua scripting se apna dissector likh sakte ho (advanced, red team custom protocol analysis mein useful).

### 10.4 Ring Buffer Capture (Long-Duration Monitoring)
```bash
tshark -i eth0 -b filesize:10000 -b files:5 -w capture.pcap
```
Fixed size ki multiple files mein rotate karta hai — long capture sessions ke liye disk space manage karta hai.

---

## 11. Practice Labs

- Wireshark official sample captures: `wiki.wireshark.org/SampleCaptures`
- TryHackMe → "Wireshark" rooms (multiple difficulty levels)
- picoCTF → forensics category mein pcap analysis challenges

---

## 12. Ethical/Scope Reminder

- Sirf apne authorized network/lab environment pe capture karna — kisi doosre ke network traffic ko unauthorized sniff karna illegal hai
- Live bug bounty targets pe Wireshark generally applicable nahi hai (remote web apps ke liye) — ye zyada internal network pentest/red team engagements mein use hota hai
