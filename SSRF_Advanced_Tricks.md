Practical tip: Jab basic 127.0.0.1 block ho jaaye, upar wali tricks ek-ek karke try karo — zyada tar real-world apps sirf 1-2 layer ka filter lagate hain, saari tricks combine karke usually bypass mil jaata hai.

# SSRF — Advance Impacts & Tricks

## SSRF ke Effects (Impact)

| Impact | Kya hota hai |
|---|---|
| **Internal network access** | Attacker firewall ke peeche wale services access kar leta hai jo public se hidden hote hain |
| **Cloud credential theft** | AWS/Azure/GCP metadata se IAM keys leak — poora cloud account compromise ho sakta hai |
| **Data exfiltration** | Internal databases, config files, `/etc/passwd` jaisi sensitive files read ho sakti hain |
| **Admin panel takeover** | Internal-only admin panels access karke user delete/modify/create kar sakte ho |
| **RCE (Remote Code Execution)** | Redis/Memcached jaisi internal services ko gopher protocol se exploit karke command execute karna |
| **Port scanning / internal recon** | Poore internal network ka map bana sakte ho — kaunse services kaunse ports pe chal rahi hain |
| **DoS (Denial of Service)** | Internal services ko baar-baar request bhejke overload karna |
| **Bypass of IP-based access control** | Jo services sirf "internal IP se hi accessible" hoti hain, unko bypass kar lena |

---

## Advance Bypass Tricks

| Trick | Detail |
|---|---|
| **URL scheme confusion** | `https:evil.com` (no `//`) kuch parsers ko confuse karta hai |
| **Backslash trick** | `http:/\/\127.0.0.1/` — kuch parsers isko valid URL samajhte hain |
| **Unicode/UTF-8 encoding** | IP ya domain ko unicode chars se encode karke filter regex bypass karna |
| **Case manipulation** | `HTTP://127.0.0.1/`, `LoCaLhOsT` — case-sensitive filters bypass |
| **Double URL encoding** | `%2568ttp://127.0.0.1` — WAF pehli decode pe hi satisfy ho jaata hai |
| **Alternative loopback IPs** | `127.0.0.2`, `127.1.1.1` bhi loopback hi hote hain — sirf `127.0.0.1` block hone pe kaam aata hai |
| **CRLF injection with gopher** | Gopher payload mein `%0d%0a` daalke raw protocol commands inject karna (Redis/SMTP) |
| **Using URL shorteners** | `bit.ly/xyz` jo internal IP pe redirect kare — kuch weak filters shortener ko trust kar lete hain |
| **Multiple redirects chaining** | Ek redirect block ho toh 2-3 redirect chain banao — filter sirf first hop check karta hai |
| **Wrapping in JSON/XML payload** | Kuch apps SSRF param ko JSON body ke andar accept karte hain — normal URL field se filter miss ho sakta hai |

---

## Notes
- Yeh tricks sirf authorized scope ([[banco-plata-target]], [[syfe-target]]) ke andar hi try karna.
- Successful bypass payloads [[burp-suite-mastery]] notes mein likhte jao future reference ke liye.
