# Pattern → Attack Recognition Guide
### Roz padhne wali reference file — field dekh ke attack type turant dimag mein aane ke liye

---

## Core Rule (sabse pehle yaad rakho)

> Field ka **naam** batata hai "ye kis type ki cheez hai."
> Field ki **value** batata hai "ye kahan use ho rahi hogi."
> Dono ko match karo → attack type khud-ba-khud dimaag mein aayega.

---

## PART 1 — Parameter/Field NAME se Pehchano

### `id`, `uid`, `user_id`, `order_id`, `account_id`, `doc_id`
Ye kisi record ko point kar raha hai.
Try karo: number/UUID change karke doosre ka data aata hai kya.
**Attack: IDOR (Insecure Direct Object Reference)**

### `redirect`, `url`, `next`, `return`, `callback`, `dest`, `continue`
Ye kahin bhejega ya fetch karega.
Try karo: apni domain ya internal IP daal ke dekho.
**Attack: Open Redirect / SSRF**

### `file`, `path`, `doc`, `template`, `page`, `folder`, `include`
File system se kuch load ho raha hai.
Try karo: `../../` ya absolute path daal ke dekho.
**Attack: Path Traversal / Local File Inclusion (LFI)**

### `cmd`, `exec`, `command`, `run`, `ping`, `query`, `debug`
Backend kuch execute kar sakta hai.
Try karo: `;`, `|`, `&&` jaise separators daal ke.
**Attack: Command Injection**

### `search`, `filter`, `sort`, `category`, `q`
Database query bana raha hoga.
Try karo: `'`, `"`, `OR 1=1` jaise payloads.
**Attack: SQL Injection**

### `xml`, `data` (jo XML format mein ho), SOAP endpoints
XML parse ho raha hai.
Try karo: external entity reference daal ke.
**Attack: XXE (XML External Entity)**

### `isAdmin`, `role`, `is_verified`, `discount`, `price`, `quantity`, hidden fields jo form mein nahi dikhte the
Frontend ne hide kiya, backend accept kar sakta hai.
Try karo: field add/change karke bhejo jo response mein nahi tha.
**Attack: Mass Assignment / Business Logic Flaw**

### `token`, `otp`, `code`, `pin`, `captcha`
Verification step hai.
Try karo: baar-baar submit karo, limit hai ya nahi.
**Attack: Rate Limiting Absent / Brute Force**

### `email`, `username` jo password reset ya invite flow mein ho
Try karo: doosre ka email daal ke response/behavior dekho.
**Attack: Account Takeover / User Enumeration**

### `format`, `type`, `ext` (file upload ke sath)
File type control ho raha hai.
Try karo: `.php`, `.jsp` ya double extension upload karke.
**Attack: Unrestricted File Upload**

---

## PART 2 — VALUE ka "Shape" Dekh Ke Pehchano

### Free text jo kahin display hoga (comment, bio, review, name, search box)
User input HTML page mein reflect ya store ho sakta hai.
**Attack: XSS (Reflected/Stored)**

### Value jo ek doosre form field ka current state control karta hai (jaise state depend karta hai kisi cheez pe)
Server-side state ko client control kar raha ho sakta hai.
**Attack: CSRF (agar koi state-changing action hai bina proper token ke)**

### JSON/serialized data (base64, encoded blobs jo suspicious lagte hain)
Server ise deserialize kar sakta hai.
**Attack: Insecure Deserialization**

### Value jo kisi doosre internal service ka URL/IP jaisa dikhta hai
**Attack: SSRF**

### Numeric value jo price/amount/quantity represent karta hai
Client-side se manipulate karke logic todna.
**Attack: Business Logic Flaw / Price Tampering**

---

## PART 3 — Headers/Cookies se Pehchano

### `Host` header
Password reset links, cache keys isi se bante hain kai baar.
**Attack: Host Header Injection / Password Reset Poisoning**

### `Origin`, `Referer` (CORS response mein reflect ho raha ho)
Server agar Origin ko blindly trust kar raha hai.
**Attack: CORS Misconfiguration**

### `X-Forwarded-For`, `X-Real-IP`, `X-Forwarded-Host`
Agar server inhe trust karta hai IP-based access control ke liye.
**Attack: IP Spoofing / Access Control Bypass**

### Session cookie without `Secure`/`HttpOnly`/`SameSite` flags
**Attack: Session Hijacking / CSRF**

### JWT token (agar dikh raha ho)
Algorithm `none`, weak secret, ya signature verify na ho.
**Attack: JWT Manipulation**

---

## PART 4 — Response Mein Dikhne Wale Signals

### Verbose error, stack trace, SQL error message
**Attack: Information Disclosure** (aur aage SQLi confirm karne ka clue)

### Response time normal se zyada slow (specific input pe)
**Attack: Blind SQLi / Time-based Injection**

### Response mein extra fields jo request mein nahi maange the (jaise poora user object aa gaya)
**Attack: Excessive Data Exposure (API level)**

### Same endpoint different roles ke liye same response de raha (access control check missing)
**Attack: Broken Access Control / Privilege Escalation**

---

## PART 5 — Request METHOD/Behavior se Pehchano

### GET request jahan sensitive action ho raha hai (delete, update)
**Attack: CSRF ya Method-based Auth Bypass**

### Same request repeat allowed bina limit ke (login, OTP, payment, coupon)
**Attack: Rate Limiting Missing / Brute Force / Race Condition**

### Multiple requests ek sath bhejne pe unexpected result (jaise double discount apply)
**Attack: Race Condition**

---

*Sath wali file: request-analysis-framework.md — wo "kahan dekhna hai" sikhati hai, ye file "kya ho sakta hai" sikhati hai. Naya pattern seekhoge to yahin add karunga.*
