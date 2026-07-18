# Account Takeover (ATO) — Complete Mastery Guide

> Aaj ka topic: **Account Takeover (OWASP A07 — Broken Authentication family)**
> Goal: Har ATO vector ko samajhna + practical testing checklist + Syfe/Banco Plata pe kaise apply karna hai

---

## 1. ATO Kya Hota Hai?

Account Takeover = attacker kisi **legit user ka account fully control** kar leta hai — password change, email change, session hijack, ya direct login bina credentials ke. Bug bounty programs mein ye **P1/Critical** category mein aata hai kyunki impact = full account compromise.

**Hacker Vulnerability Mindset laga ke socho:** Har authentication/session-related endpoint pe poochho — *"Yahan trust kis cheez pe based hai, aur main us trust ko kaise fake/bypass kar sakta hoon?"*

---

## 2. ATO Attack Vectors — Master Table

| # | Vector | Root Cause | Kaise Test Kare |
|---|--------|-----------|------------------|
| 1 | **Password Reset Poisoning** | Reset link ka domain `Host` header se generate hota hai | `Host` header ko attacker domain se replace karo (Burp Repeater), check karo reset link mein wahi domain aata hai kya |
| 2 | **Password Reset Token Leakage/Predictability** | Token weak/predictable ya Referer/response mein leak | Token entropy check karo, multiple requests karke pattern dekho, Referer header leakage check karo |
| 3 | **No Rate Limit on OTP/Reset** | Brute-force possible on 4-6 digit OTP | Intruder se OTP brute force try karo (authorized scope mein hi) |
| 4 | **IDOR in Account Endpoints** | `user_id`/`account_id` predictable, no authorization check | Apne account ka ID kisi doosre number se replace karke profile/email/password endpoints hit karo |
| 5 | **JWT Manipulation** | `alg:none`, weak secret, unsigned claim trust | `alg` ko `none` karo, weak secret brute force (jwt_tool/hashcat), `role`/`user_id` claim tamper karo |
| 6 | **OAuth Misconfiguration** | `redirect_uri` open, state param missing (CSRF), token leakage via Referer | `redirect_uri` ko apne domain se replace karo, `state` param remove/reuse karo |
| 7 | **Session Fixation** | Login ke baad session ID rotate nahi hota | Pre-login session ID note karo, login karo, check karo same ID persist hui kya |
| 8 | **CSRF on Sensitive Actions** | Email/password change endpoint pe anti-CSRF token nahi | CSRF PoC bana ke email-change request replay karo bina token ke |
| 9 | **2FA Bypass** | Response manipulation (`true`→`false`), missing server-side check on next step | 2FA verify response intercept karo, `"success":false` ko `true` mein badlo, ya seedha next-step URL directly hit karo |
| 10 | **Response Manipulation (Login)** | Client-side login validation | Failed login response mein status code/body manipulate karke dashboard redirect force karo |
| 11 | **Subdomain Takeover → ATO** | Dangling CNAME on auth-related subdomain | Subzy/dnsrecon se dangling CNAMEs, claim karke cookies/session steal | 
| 12 | **Email/Phone Change without Re-auth** | Sensitive action doesn't ask for current password | Email change endpoint test karo — current password required hai kya |
| 13 | **Registration Race Condition** | Duplicate account creation ya email-verification race | Same email se parallel signup requests (Turbo Intruder) |
| 14 | **Cookie/Session Token Predictability** | Weak session generation algo | Multiple session tokens collect karke entropy analyze karo |

---

## 3. Step-by-Step Testing Methodology

1. **Recon** — saare auth-related endpoints map karo: signup, login, forgot-password, reset-password, change-email, change-password, 2FA verify, OAuth callback
2. **Flow mapping in Burp** — har flow ka full HTTP history capture karo (Proxy → HTTP History filter by auth keywords)
3. **Password Reset Flow** — sabse pehle test karo (highest ROI):
   - Host header injection
   - Token entropy/leak
   - Token expiry/reuse
4. **JWT check** — agar JWT mil raha hai, jwt_tool se decode + alg confusion + secret brute-force
5. **IDOR sweep** — har account-scoped endpoint pe apna ID vs doosra ID try karo
6. **2FA/OTP flow** — rate limit + response manipulation + step-skipping
7. **OAuth (agar hai)** — redirect_uri, state param, token in URL leakage
8. **Session behavior** — fixation + concurrent session handling

---

## 4. Tools Cheat Sheet

| Purpose | Tool |
|---|---|
| Request manipulation | Burp Suite (Repeater + Intruder) |
| JWT attacks | jwt_tool, jwt.io (offline debugging) |
| Rate limit / brute force | Burp Intruder, Turbo Intruder |
| Subdomain takeover | Subzy, dnsrecon, `can-i-take-over-xyz` repo reference |
| Race conditions | Turbo Intruder (single-packet attack) |
| Session analysis | Burp Sequencer (entropy test) |

---

## 5. Apply Karo — Tumhare Live Targets Pe

- **Syfe:** `invest.syfe.com` pe pending subdomain takeover already hai — usko ATO angle se socho: agar claim ho jaye to kya session cookies scope match karte hain? Automated tools sirf UAT pe — manual Burp verification production subdomain pe allowed hai, scope dobara confirm kar lena.
- **Banco Plata:** Cloudflare WAF aggressive hai — direct header injection blocked ho chuka hai reset-flow pe try nahi kiya abhi. Password reset host-header poisoning ek fresh angle ho sakta hai jo abhi tak untested hai.

---

## 6. Practice Labs (Free)

- PortSwigger Web Security Academy → "Authentication" + "OAuth" categories (sabse best, real Burp labs)
- TryHackMe → "OWASP Top 10" room, broken auth section
- HackerOne public disclosed reports → search "account takeover" tag for real writeups

---

*Next milestone: Password Reset Poisoning ko deeply practice karo PortSwigger labs pe pehle, phir Syfe pe apply.*
