# API Security — Advanced Reference
### Roz padhne wali reference file — API endpoints ko deeply samajhne ke liye

---

## PART 1 — API Kya Karta Hai (Quick Recap)

API endpoint = backend ka direct entry point, jahan UI ke restrictions bypass ho sakte hain.
Full detail: hidden functionality, auth gaps, version differences, info disclosure.

---

## PART 2 — Advanced API Concepts

### REST vs GraphQL — dono alag treat karo

**REST API** — har action ka apna URL hota hai (`/api/user/123`, `/api/orders`).
Testing approach: har endpoint ko individually explore karo, method (GET/POST/PUT/DELETE) badal ke dekho.

**GraphQL API** — sirf ek URL hota hai (`/graphql`), sab kuch query ke through hota hai.
Testing approach alag hai:
- **Introspection query** try karo — agar enabled hai to poora schema (saare fields, types, mutations) mil jaata hai
- Query: `{__schema{types{name,fields{name}}}}`
- Agar introspection disabled hai, to error messages se guess karo ya tools use karo (GraphQL Voyager, InQL Burp extension)

---

### API Versioning — Purana Version = Golden Opportunity

`/api/v1/`, `/api/v2/`, `/api/v3/` — company naya version banati hai lekin purana **deprecate karna bhool jaati hai** ya properly disable nahi karti.

Kya try karo:
- Agar `/api/v2/user/123` pe rate limiting hai, check karo `/api/v1/user/123` pe hai ya nahi
- Agar `/api/v2/` mein IDOR fix hua hai, `/api/v1/` mein wahi bug abhi bhi ho sakta hai
- Version number ko manually increment/decrement karke dekho — `v3`, `v0`, `v1.1` bhi try karo

---

### Rate Limiting Bypass Angles

Rate limit ek IP/account pe lagta hai — bypass ke common tareeke:
- Header add karo: `X-Forwarded-For: 127.0.0.1`, `X-Originating-IP`, `X-Client-IP`
- API version switch karo (v1 pe rate limit na ho)
- Request method change karo (GET se POST, ya case change: `/API/` vs `/api/`)
- Trailing slash ya extra characters: `/api/login/` vs `/api/login`

---

### Mass Assignment (API ka Sabse Common Bug)

API request body mein tum extra fields add karke bhej sakte ho jo form mein nahi the:

```
Original request:
{"username": "karan", "email": "karan@mail.com"}

Tumhara modified request:
{"username": "karan", "email": "karan@mail.com", "role": "admin", "isVerified": true}
```

Agar backend blindly saare fields accept kar raha hai (proper whitelist nahi hai), to `role` ya `isVerified` change ho sakta hai — bina kisi UI button ke.

---

### BOLA / IDOR API Mein (Sabse Common OWASP API Top 10 Issue)

API endpoints mein ID-based access sabse common vuln hai:

```
GET /api/v1/invoice/1001   → tumhara invoice
GET /api/v1/invoice/1002   → kisi aur ka invoice (agar access check missing hai)
```

Sirf numeric ID hi nahi — UUID, base64-encoded ID, ya hex ID bhi try karo. Kabhi kabhi UUID bhi predictable pattern follow karta hai.

---

### Excessive Data Exposure

API response mein aksar zyada data aata hai jo frontend display nahi karta. Response ko raw JSON mein poora padho, sirf jo UI pe dikh raha hai wahi mat dekho.

```
UI dikhata hai: naam aur profile picture

Actual API response:
{
  "name": "Karan",
  "email": "karan@mail.com",
  "phone": "98xxxxxxxx",
  "internal_user_id": "u_4471",
  "role": "user",
  "password_hash": "..."   ← ye bhi kabhi kabhi mil jaata hai (severe finding)
}
```

---

## PART 3 — Example: Ek Real-World-Style API Endpoint Walkthrough

Maan lo tumhe ye endpoint mila (Burp ya JS file se):

```
GET https://target.com/api/v2/user/45210/wallet/transactions?limit=10
Headers:
  Authorization: Bearer eyJhbGciOi...
```

**Step-by-step analysis (Part 2 wale framework se):**

1. **`45210`** — ye user ID hai, numeric, sequential lag raha hai
   → Try: `45211`, `45209` daal ke dekho — doosre ka transaction data aata hai kya (**IDOR**)

2. **`Bearer` token** — JWT hai
   → Decode karo (jwt.io ya CyberChef se), check karo `alg: none` accept hota hai kya, ya weak secret hai (**JWT Manipulation**)

3. **`v2`** version dikh raha hai
   → Try karo same endpoint `v1` mein exist karta hai kya, agar haan to wahan security check weak ho sakta hai

4. **`limit=10`** parameter
   → Try: `limit=1000` ya `limit=-1` — kabhi kabhi zyada data ek sath leak ho jaata hai (**Excessive Data Exposure / DoS**)

5. **Response JSON poora padho**
   → Sirf transaction amount hi nahi, dekho account number, IFSC, ya related user details bhi aa rahe hain kya

6. **Method change karke dekho**
   → `GET` ko `DELETE` ya `PUT` karke same URL pe try karo — kabhi kabhi backend accept kar leta hai bina proper check ke

**Isi ek endpoint se potential findings: IDOR, JWT issue, version-based bypass, data exposure, method-based access control bypass — 5 alag angles, ek hi request se.**

---

## PART 4 — Tools Recap (Quick Reference)

| Kaam | Tool |
|---|---|
| JS files se endpoints nikalna | LinkFinder, JSFScan |
| API bruteforce (paths) | Kiterunner, ffuf |
| GraphQL testing | InQL (Burp extension), GraphQL Voyager |
| JWT decode/test | jwt.io, CyberChef |
| Swagger/OpenAPI dhundhna | Manual paths: `/swagger-ui.html`, `/api-docs`, `/v2/api-docs` |

---

*Sath wali files: request-analysis-framework.md aur pattern-attack-recognition.md — ye teeno ek dusre ko complement karti hain. Naya API concept seekhoge to yahin add karunga.*
