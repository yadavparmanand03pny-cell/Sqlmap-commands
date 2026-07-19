# Password Reset Token Leakage/Predictability — Advanced Methodology

## 1. Reconnaissance — Reset Flow Mapping

| Step | Kya karna hai |
|---|---|
| Flow trigger karo | "Forgot Password" click karke poora flow Burp History mein capture karo |
| Endpoints note karo | `/forgot-password`, `/reset-password`, `/verify-otp` — sab alag-alag ho sakte hain |
| Token delivery method | Email link? SMS OTP? In-app notification? Har method ka attack surface alag hota hai |
| Multi-step ya single-step | Kya reset ek hi request mein hota hai ya token verify → new password set do steps mein? |

## 2. Predictability Testing

| Technique | Method |
|---|---|
| Multiple token capture | Same account pe 10-20 baar reset request bhejo (rate limit se bacho, delay do), sab tokens Burp mein collect karo |
| Pattern analysis | Token length, charset (numeric/alphanumeric/hex) note karo |
| Timestamp correlation | Kya token = hash(email + current_time)? Server time approx pata hone se brute-force possible |
| Sequential ID check | Agar token ek incrementing number hai (rare but happens in legacy systems) |
| Entropy check | Burp Sequencer tool use karo — token capture karke "Analyze" karo, entropy score dekho (low entropy = predictable) |
| Algorithm guessing | Common weak patterns: MD5(email), SHA1(user_id+timestamp), Base64(email:timestamp) — decode karke check karo |

## 3. Leakage Vectors (Advanced)

| Vector | Kaise exploit karte hain |
|---|---|
| Referer header leakage | Reset link click karne ke baad load hone wale external resources (Google Fonts, analytics, CDN) ke request mein Referer header check karo — full URL with token chala jaata hai |
| Response body leakage | POST `/forgot-password` ke response JSON mein `token`, `reset_code`, `debug_token` fields dhoondo |
| Password Reset Poisoning (Host Header) | `Host` header ya `X-Forwarded-Host` header manipulate karke reset link mein apna malicious domain inject karo — victim ka token tumhare server pe aa jayega |
| GET-based token in logs | Agar token URL mein hai (GET request), toh proxy logs, browser history, server access logs, CDN logs mein reh jaata hai |
| Password reset via API leaking in mobile app | APK decompile karke check karo — kabhi API response token client-side log/console mein print ho jaata hai |
| Email/SMS gateway exposure | Third-party service (Twilio/SendGrid) ka status/webhook endpoint agar publicly accessible ho, token wahan expose ho sakta hai |

## 4. Host Header / Reset Poisoning — Step by Step

1. Reset request intercept karo Burp mein
2. `Host` header ko apne controlled domain se replace karo (e.g., `attacker.com`)
3. Agar app link generate karte waqt `Host` header use karta hai (bina validation ke), reset email mein link `https://attacker.com/reset?token=XXX` ban jayega
4. Victim link click karega → token tumhare server ke access log mein aa jayega
5. Us token ko legitimate domain pe replay karo → account takeover

## 5. Race Condition Angle

| Check | Kaise |
|---|---|
| Token reuse after use | Ek baar reset ho jaane ke baad wahi token dobara replay karke dekho — valid reh gaya kya? |
| Parallel requests | Turbo Intruder ya Burp Repeater se same token multiple parallel requests mein bhejo — race condition se double-processing ho sakta hai |
| Multiple valid tokens | Kya ek hi account ke liye purane tokens bhi valid rehte hain naya generate hone ke baad? |

## 6. Rate Limiting Bypass (OTP Brute-force ke liye)

| Bypass Technique | Detail |
|---|---|
| IP rotation | X-Forwarded-For, X-Real-IP headers spoof karo |
| Header manipulation | `X-Forwarded-For: 127.0.0.1` add karke dekho rate limit bypass hota hai kya |
| Case/encoding variation | Endpoint URL case change karo (`/Reset-Password` vs `/reset-password`) — kai WAFs case-sensitive rate limiting rakhte hain |
| Null byte / trailing slash | `/reset-password/` ya `/reset-password%00` try karo |
| Session/cookie rotation | Har request pe naya session cookie use karo agar rate limit session-based hai |
| Turbo Intruder for speed | 4-6 digit OTP ho aur rate limit weak ho, toh Turbo Intruder se fast brute-force feasible hai (10,000 combinations) |

## 7. Tools for This Vulnerability

| Tool | Use |
|---|---|
| Burp Sequencer | Token randomness/entropy analyze karne ke liye |
| Burp Repeater | Manual token testing, replay attacks |
| Burp Intruder / Turbo Intruder | OTP brute-force, rate-limit bypass testing |
| Burp Comparer | Multiple tokens side-by-side pattern compare karne ke liye |
| CyberChef | Token decode karna (Base64, Hex, hash identify) agar encoded lage |

## 8. Reporting Checklist (HackerOne ke liye)

- [ ] Token predictability proof (multiple samples + pattern explanation)
- [ ] PoC video/steps for leakage (Referer/response body screenshot)
- [ ] Host header poisoning working PoC with attacker-controlled domain
- [ ] Impact statement — full account takeover without victim interaction
- [ ] CVSS/severity justification (usually Critical/High for full ATO)

## 9. Real-World Disclosed Patterns (Common in Reports)

| Pattern | Frequency |
|---|---|
| Token in JSON response body | Very common — dev/debug leftover |
| Host header poisoning | Common on apps not validating Host header |
| Predictable OTP via weak rate limiting | Common on 4-6 digit numeric OTP systems |
| Referer leakage | Less common now, but still found on older/legacy apps |
| Token reuse (no expiry/invalidation) | Common oversight |

---
**Next practice step:** PortSwigger Web Security Academy labs — "Password reset poisoning via Host header", "Password reset poisoning via middleware", "Password reset broken logic" — inn teeno labs pe hands-on karo isi order mein.
