# Burp Request Analysis Framework
### Roz padhne wali reference file — dimag mein print karne ke liye

---

## PART 1 — Tunnel Vision Fix

**Problem:** Ek specific vuln (jaise IDOR) dhundhne ke goal se request dekhte ho → baaki 9 bugs ignore ho jaate hain kyunki wo current goal se match nahi karte.

**Fix — "Observe First, Hunt Second":**

1. Pehla pass mein sirf **observe** karo — koi attack mat karo. Poora request/response top se bottom padho.
2. Har request pe niche wala checklist (Part 2) mechanically apply karo — chahe tumhara goal kuch aur ho.
3. Jo bhi "ajeeb" lage lekin abhi test nahi kar rahe — note kar lo, baad mein wapas aao.
4. Alag session/din mein alag angle se same request test karo (ek din auth, ek din injection).

---

## PART 2 — Request Reading Checklist

Request intercept hote hi, top se bottom, har part pe ye sawaal khud se pucho:

### URL Path
Example: `/user/123/profile`

Sawaal: Ye number/ID predictable hai? 123 ko 124 karne se doosre ka data aayega kya?

Vuln angle: **IDOR**

---

### Query Parameters
Example: `?search=laptop&redirect=home.php`

Sawaal: Ye value backend mein query ya command mein use ho rahi hogi? Yahan `'` ya `<script>` daalu to kya hoga?

Vuln angle: **SQLi / XSS / Open Redirect**

---

### Headers
Example: `Host:`, `Referer:`, `X-Forwarded-For:`, `Origin:`

Sawaal: Ye header trust karke server koi decision le raha hai kya? (jaise Host header se password reset link banna)

Vuln angle: **Host Header Injection / CORS Misconfig / SSRF**

---

### Cookies
Example: `session=abc123`, `role=user`

Sawaal: Ye cookie client-side se manipulate ho sakti hai? `role=user` ko `role=admin` karu to?

Vuln angle: **Privilege Escalation / Session Issues**

---

### Request Method
Example: GET vs POST vs PUT vs DELETE

Sawaal: GET ko PUT/DELETE mein badalne se same endpoint pe auth check bypass hoga kya?

Vuln angle: **Auth Bypass / Method Tampering**

---

### Body / JSON Fields
Example: `{"user_id": 45, "amount": 100}`

Sawaal: Frontend jo fields hide kar raha hai, unme se koi field backend accept kar raha hai kya?

Vuln angle: **Mass Assignment**

---

## PART 3 — Daily Practice Rule

Har request pe ek line: **"Ye value agar main change karu to server confuse ho sakta hai kya?"**

Jawab "shayad" ho → highlight karo, chahe abhi test na karo.

Pehle 20-30 requests slow lagega. Fir automatic ho jayega.

---

*Last updated: 19 July 2026 — jab bhi naya point aayega, isi file mein add hoga.*
