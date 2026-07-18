# IDOR (Insecure Direct Object Reference) — Complete Mastery Guide

> Root cause: Application user-supplied identifier (ID, filename, key) ko directly object access ke liye use karta hai, bina proper authorization check ke.

---

## 1. IDOR Kya Hota Hai?

Jab application ek object (record, file, order, invoice) ko access karne ke liye ek identifier (numeric ID, UUID, filename) use karta hai, aur server-side ye check nahi karta ki **current logged-in user us specific object ko access karne ka authorized hai ya nahi** — to attacker sirf ID change karke doosre user ka data access/modify kar sakta hai.

**Mindset trigger:** Har jagah jahan URL/body/param mein koi ID dikhe — `user_id=123`, `order_id=456`, `file=invoice_2024.pdf` — poochho: *"Agar main ye number/value badal doon, kya server check karega ki ye mera hai ya nahi?"*

---

## 2. Types of IDOR — Master Table

| Type | Description | Example |
|---|---|---|
| **Direct Numeric IDOR** | Sequential/incrementing ID | `GET /api/user/1002` → `1003` try karo |
| **UUID/GUID IDOR** | Random-looking ID but leaked elsewhere | UUID kisi response/email/invite link mein leak ho raha hai |
| **Horizontal IDOR** | Same-privilege user ka data access | User A, User B ka profile/order dekh le |
| **Vertical IDOR (Privilege related)** | Lower-priv user, admin-only object access kare | Normal user, admin ka dashboard data fetch kare |
| **IDOR via HTTP Method Change** | GET pe blocked, but POST/PUT/DELETE pe check missing | `GET` blocked but `PUT /api/user/123` allowed |
| **IDOR in File Access** | Filename/path direct reference | `/download?file=invoice_1001.pdf` → `invoice_1002.pdf` |
| **IDOR in API/GraphQL** | Object ID directly query mein | GraphQL query mein `id` field manipulate karo |
| **Blind IDOR** | Response mein data nahi dikhta but side-effect confirm hota hai | Delete/update request success status se confirm |
| **Mass Assignment + IDOR** | Extra field (`user_id`, `role`) request body mein inject | `{"user_id":456, "role":"admin"}` add karke request bhejna |
| **IDOR via Parameter Pollution** | Multiple same-name params confuse backend | `?user_id=123&user_id=456` |

---

## 3. Where to Look — Endpoint Checklist

| Feature Area | What to Test |
|---|---|
| Profile/Account | View/edit other user's profile via ID swap |
| Orders/Invoices/Payments | Order ID sequential ho to doosre orders access |
| Messages/Chat | Conversation ID swap karke doosre ki chats padhna |
| File uploads/downloads | Direct file path/ID reference |
| Password/Email change | Object-level auth check without re-verifying session owner |
| Admin panels | Role/permission ID manipulate |
| API endpoints (REST/GraphQL) | Every `{id}` parameter — path, query, body, header |
| Export/PDF generation features | Export ID/token predictability |
| Notifications settings | Other user's notification prefs access/change |

---

## 4. Step-by-Step Testing Methodology

1. **Two test accounts banao** (mandatory) — User A aur User B, dono ke sessions/cookies alag rakho
2. **User A se ek action karo** (order place, profile update, message send) — us object ka ID note karo
3. **User B ke session/cookie se same ID access karo** — Burp mein request replay karke sirf cookie/token swap karo, baaki same rakho
4. **Response compare karo:**
   - Status code 200 with data = confirmed IDOR
   - Status code 403/401 = properly protected
   - Status code 200 but empty/generic data = false positive, check carefully
5. **Every HTTP method try karo** same endpoint pe — GET protected ho sakta hai but PUT/DELETE/PATCH nahi
6. **Autorize/Burp extension use karo** — automatically har request ko doosre user's session se replay karta hai aur flag karta hai

---

## 5. Tools

| Tool | Purpose |
|---|---|
| Burp Suite + Autorize extension | Automated authorization testing across two sessions |
| Burp Suite + Auth Analyzer | Similar — replays requests with different session tokens |
| Burp Intruder | Sequential ID enumeration (numeric IDOR at scale) |
| Postman/Insomnia | API-specific IDOR testing (easier header/token switching) |
| Custom Python scripts (requests lib) | Bulk enumeration + diffing responses |

---

## 6. Advanced IDOR Techniques

### 6.1 Indirect Object Reference Bypass
Kabhi app "safe" reference use karta hai (jaise session-mapped index) lekin agar wahi index doosre context mein reuse ho raha hai to bhi leak ho sakta hai — cross-endpoint correlation try karo.

### 6.2 IDOR via API Versioning
Naya API version (`/v2/`) IDOR fix kar sakta hai but purana version (`/v1/`) still active + unprotected ho sakta hai — dono versions check karo.

### 6.3 IDOR in Batch/Bulk Endpoints
Bulk operations (`/api/users/bulk-delete` with array of IDs) mein per-object authorization check missed ho sakta hai even if single-object endpoint protected hai.

### 6.4 Encoded/Hashed ID Reverse Engineering
Agar ID base64/hash lag raha hai, decode karke dekho actual pattern (sequential number encoded) — encoding security nahi hai.

### 6.5 IDOR Chained with Other Bugs
- IDOR + Mass Assignment → privilege escalation
- IDOR + Weak JWT → full account takeover
- IDOR + missing rate limit → mass data scraping (high severity)

---

## 7. Practice Labs

- PortSwigger Web Security Academy → "Access Control" category (IDOR labs included)
- HackerOne Hacktivity → search "IDOR" tag for real disclosed reports
- OWASP Juice Shop → multiple IDOR challenges built in

---

## 8. Reporting Tips (for Bug Bounty)

- Clearly show: victim account setup, attacker request, response proving data leak/modification
- Screenshot/video PoC with two different sessions side-by-side
- Highlight business impact (PII leak, financial data, account modification) — severity depends heavily on data sensitivity
