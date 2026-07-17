# Account Takeover — Advance Tricks & Techniques

## 1. Password Reset Flow Attacks
| Trick | Detail |
|---|---|
| **Host Header Injection in reset link** | `Host:` header ko attacker-controlled domain se replace karo — agar app reset link banate waqt Host header use karta hai, victim ke email mein attacker ka domain wala link jaayega |
| **Token predictability** | Reset token sequential/timestamp-based hai kya — Burp Sequencer se randomness analyze karo |
| **Token not invalidated after use** | Same token dobara use karke check karo expire hua ya nahi |
| **Token leakage via Referer header** | Reset page pe click karne ke baad agar external resource load ho, Referer header mein token leak ho sakta hai |
| **Response manipulation** | Invalid token pe bhi response `"valid":true` mein tamper karke aage badhna |
| **Race condition on reset** | Same time pe multiple reset requests bhejke token collision/bypass try karna |
| **Parameter pollution** | `email=victim@x.com&email=attacker@x.com` — kuch backend last/first value use karte hain |

---

## 2. Login Response Manipulation
| Trick | Detail |
|---|---|
| **Status code/body tamper** | `"success":false` ko Burp Repeater se `"success":true"` karke response manipulate karna |
| **HTTP status manipulation** | 401/403 response ko intercept karke 200 OK mein badalna (client-side check based apps mein kaam karta hai) |
| **Missing server-side validation** | Login form bypass karke seedha authenticated endpoint hit karna |

---

## 3. Session Token Attacks
| Trick | Detail |
|---|---|
| **Session fixation** | Login se pehle ka session ID login ke baad bhi valid rehta hai kya — attacker apna session victim ko force karwa sakta hai |
| **Session token in URL** | Token URL mein expose hone se Referer/logs/history se leak |
| **No session invalidation on logout** | Logout ke baad bhi purana token kaam karta hai kya check karo |
| **Predictable session ID** | Burp Sequencer se entropy check — agar low randomness hai toh brute-forceable |
| **Concurrent session abuse** | Ek hi account multiple devices pe login allow karke session hijack detect karna mushkil banana |

---

## 4. OTP / 2FA Bypass Tricks
| Trick | Detail |
|---|---|
| **No rate limiting** | OTP field pe Burp Intruder se brute force (0000-9999) |
| **OTP reusability** | Same OTP dobara use karke check karo expire hota hai ya nahi |
| **Response-based bypass** | OTP verify request ka response intercept karke `false` ko `true` mein badalna |
| **Skip 2FA step entirely** | Login ke baad directly authenticated endpoint/dashboard URL hit karke 2FA step skip karna |
| **OTP leaked in response** | Kabhi-kabhi backend response mein hi OTP value accidentally return ho jaata hai (debug info) |
| **Weak OTP generation** | 4-digit numeric OTP ho toh bahut jaldi brute-force ho sakta hai |

---

## 5. IDOR-based Account Takeover
| Trick | Detail |
|---|---|
| **User ID manipulation in profile update** | `user_id=123` ko `124` karke doosre ka email/password change karna |
| **Email change without re-auth** | Password/email change endpoint pe current-password verification missing check karna |
| **Password change without old password** | Kai apps naye password set karte waqt purana password verify nahi karte |

---

## 6. JWT-based Account Takeover
| Trick | Detail |
|---|---|
| **alg: none attack** | JWT header mein `"alg":"none"` set karke signature hata dena — server verify na kare toh accept ho jaata hai |
| **Role/user_id tampering** | Payload mein `"role":"user"` ko `"admin"` ya `user_id` change karna (agar signature verify nahi horaha) |
| **Algorithm confusion (RS256 → HS256)** | Public key ko HMAC secret ki tarah use karke fake signed token banana |
| **Weak secret brute force** | HS256 signed JWT ka secret weak ho toh `jwt_tool`/hashcat se crack karna |
| **JWT expiry not checked** | Expired token dobara use karke access try karna |

---

## 7. OAuth Misconfiguration Tricks
| Trick | Detail |
|---|---|
| **redirect_uri manipulation** | `redirect_uri=attacker.com` set karke authorization code/token apne server pe chura lena |
| **Missing state parameter** | CSRF-like attack — victim ko attacker ke OAuth flow mein force karke account link karwa dena |
| **Authorization code reuse** | Ek hi code dobara use karke token generate karna |
| **Insecure redirect_uri validation** | `target.com.evil.com` jaisa subdomain trick se whitelist bypass |

---

## 8. Credential Stuffing & Brute Force Tricks
| Trick | Detail |
|---|---|
| **No CAPTCHA/rate limit on login** | Burp Intruder se common password lists try karna |
| **Username enumeration** | "User not found" vs "Wrong password" jaise different error messages se valid emails identify karna |
| **Case-insensitive email bypass** | `Victim@x.com` vs `victim@x.com` treat differently ho sakta hai kuch systems mein |

---

## Practical Burp Workflow
1. Login/reset/OTP request Repeater mein bhejo
2. Response manipulate karke bypass try karo (Point 2 wale tricks)
3. Sequencer se token/OTP randomness check karo
4. Intruder se rate-limiting test karo (brute force attempt)
5. JWT mile toh Decoder se decode karke role/alg tamper karo
6. OAuth flow ho toh redirect_uri aur state parameter manually manipulate karke test karo

---

## Notes
- Yeh tricks sirf authorized scope ([[banco-plata-target]], [[syfe-target]]) ke andar hi try karna.
- Successful bypass payloads [[burp-suite-mastery]] notes mein likhte jao future reference ke liye.
