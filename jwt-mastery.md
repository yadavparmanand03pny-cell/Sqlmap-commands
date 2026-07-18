# JWT (JSON Web Token) — Complete Mastery Guide

> Root cause: Application JWT ke claims (payload) ko blindly trust karta hai without properly verifying signature, algorithm, ya key source.

---

## 1. JWT Structure Recap

```
HEADER.PAYLOAD.SIGNATURE
```

- **Header** (base64url): `{"alg":"HS256","typ":"JWT"}`
- **Payload** (base64url): claims — `{"user_id":123,"role":"user"}`
- **Signature**: `HMACSHA256(base64(header)+"."+base64(payload), secret)`

Sab kuch base64url-encoded hai, **encrypted nahi** — koi bhi decode kar sakta hai (jwt.io pe). Security sirf signature verification pe depend karti hai.

---

## 2. JWT Attack Vectors — Master Table

| # | Attack | Root Cause | Test Method |
|---|---|---|---|
| 1 | **alg:none** | Server `none` algorithm accept kar leta hai (no signature needed) | Header mein `alg:"none"`, signature empty/remove karo |
| 2 | **Weak Secret (HS256 brute-force)** | Weak/guessable HMAC secret | hashcat/jwt_tool se wordlist attack |
| 3 | **Algorithm Confusion (RS256→HS256)** | Server public key ko HMAC secret ki tarah use kar leta hai | Public key nikalo, usi se HS256 sign karo |
| 4 | **kid (Key ID) Injection** | `kid` header attacker-controlled file path/SQL query mein use hota hai | SQLi/path traversal try karo `kid` field mein |
| 5 | **jku/x5u Header Manipulation** | Server attacker-hosted JWK URL se key fetch kar leta hai | Apna JWKS host karo, `jku` header mein apna URL do |
| 6 | **jwk Header Injection** | Public key directly token ke header mein embed, server usi se verify karta hai | Apni key-pair generate karo, `jwk` header mein apni public key daalo, usi se sign karo |
| 7 | **Signature Stripping** | Server signature verify hi nahi karta | Signature part hata do (trailing dot ke saath), payload tamper karo |
| 8 | **Expired Token Reuse** | `exp` claim server-side check nahi hoti | Expired token replay karo |
| 9 | **Claim Tampering (role/user_id)** | Server payload claims ko blindly trust karta hai after basic verify | `role:"user"` → `role:"admin"` change karo (signature bhi forge karna padega — pehle upar wale attacks try karo) |
| 10 | **Token Sidejacking** | Token kahin leak ho raha hai (URL, logs, Referer header) | Network traffic/logs mein token leak check karo |
| 11 | **No Audience/Issuer Validation** | Token ek service ke liye bana, doosri service accept kar leti hai | Cross-service token replay try karo |

---

## 3. Step-by-Step Testing Methodology

1. **Token capture karo** Burp mein, jwt.io pe decode karo — header + payload dekho
2. **Algorithm check karo** — `alg` field kya hai (HS256/RS256/none)
3. **alg:none try karo sabse pehle** (fastest win agar exist karta hai):
   ```
   {"alg":"none","typ":"JWT"}.{payload}.
   ```
4. **Weak secret brute-force** (agar HS256 hai):
   ```
   jwt_tool <token> -C -d /usr/share/wordlists/rockyou.txt
   ```
5. **Algorithm confusion try karo** (agar RS256 use ho raha hai aur public key kahin available hai):
   - Public key dhoondo (`/jwks.json`, `.well-known/jwks.json`, ya SSH/TLS cert se)
   - Us public key se HS256 sign karke forge karo
6. **kid header manipulation:**
   - `kid` value ko `../../../../dev/null` (path traversal) ya SQLi payload se replace karo
7. **jku/jwk header injection try karo** — apna JWK host karke check karo server fetch karta hai kya
8. **Claim tampering** — `role`, `user_id`, `is_admin`, `exp` fields modify karke dekho server validate karta hai ya nahi

---

## 4. Tools

| Tool | Purpose |
|---|---|
| **jwt_tool** | All-in-one JWT attack tool — alg:none, brute-force, kid injection, all automated |
| **jwt.io** | Manual decode/encode (offline debugging, browser mein hi use karo, sensitive tokens paste na karo production ke) |
| **hashcat** | Weak HMAC secret cracking (`-m 16500` mode for JWT) |
| **Burp Suite JWT Editor extension** | Signature forging, key generation, embedded JWK attacks — sabse powerful GUI option |
| **jwt-cracker** | Simple brute-force alternative |

---

## 5. jwt_tool Command Cheat Sheet

```bash
# Basic scan — auto detect vulnerabilities
python3 jwt_tool.py <token>

# alg:none attack
python3 jwt_tool.py <token> -X a

# Weak secret brute-force with wordlist
python3 jwt_tool.py <token> -C -d rockyou.txt

# Tamper claims interactively
python3 jwt_tool.py <token> -T

# RS256 to HS256 algorithm confusion attack
python3 jwt_tool.py <token> -X k -pk public_key.pem

# kid injection (SQLi/path traversal fuzzing)
python3 jwt_tool.py <token> -T -I -hc kid -hv "' OR '1'='1"
```

---

## 6. Burp Suite JWT Editor Extension Workflow

1. Extension install karo (BApp Store se)
2. Request mein JWT highlight karo → right-click → "JSON Web Token" tab
3. **New Symmetric Key / New RSA Key** generate karo (attacks ke liye)
4. Header/payload tamper karke **"Sign"** button se resign karo
5. Embedded JWK attack: header mein "Embedded JWK" option select karo — Burp automatically apni key attach karke sign kar dega

---

## 7. Advanced Concepts

### 7.1 Algorithm Confusion — Deep Dive
Jab server `verify(token, key)` call karta hai bina explicitly `algorithms=['RS256']` specify kiye, aur library `alg` header pe hi trust kar leti hai — to attacker `alg:HS256` bhej sakta hai aur server ka **public key hi HMAC secret ban jaata hai** (kyunki public key string ke roop mein available hai, jo attacker ke paas bhi hai).

### 7.2 JWK Confusion Attack
Server agar `jwk` header ko accept karta hai (poora public key hi token ke andar embedded), to attacker apna khud ka key-pair bana ke, apni public key ko header mein daal ke, usi se sign kar sakta hai — server "trust" karega kyunki verification uss embedded key se hi hoga.

### 7.3 Refresh Token Vulnerabilities
Refresh tokens usually longer-lived hote hain — check karo:
- Reuse detection hai ya nahi (same refresh token dobara use karne pe purane access tokens revoke hote hain kya)
- Refresh token binding to device/session hai ya nahi

### 7.4 Token Revocation Gaps
Logout ke baad bhi token valid rehta hai kya (agar server-side blacklist/revocation list nahi hai) — stateless JWT ka common design flaw.

---

## 8. Practice Labs

- PortSwigger Web Security Academy → "JWT" category (sabse best, saare major attacks covered hands-on)
- HackerOne Hacktivity → search "JWT" tag
- `jwt_tool` GitHub repo README mein practice examples

---

## 9. Reporting Tips

- Signature bypass PoC dikhate waqt clearly dikhao: original token vs forged token, aur forged token se kya access mila (screenshot/response)
- Agar algorithm confusion hai, explain karo public key kahan se mila (public exposure bhi ek separate finding ho sakta hai)
