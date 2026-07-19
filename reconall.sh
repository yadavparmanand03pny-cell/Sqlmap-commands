#!/bin/bash
# ===================================================================
# reconall.sh — Phased Recon Automation
# Phase 1: Host Discovery      -> Netdiscover
# Phase 2: Port/Service Scan   -> Nmap
# Phase 3: Web Tech Fingerprint-> WhatWeb
# Phase 4: Directory Brute-force -> Gobuster
# Phase 5: Vulnerability Scan  -> Nikto
#
# Usage: reconall <target-domain-or-ip> [interface-for-netdiscover]
# Example: reconall target.com
#          reconall target.com eth0
#
# ⚠️ Sirf authorized scope (HackerOne program) pe hi chalao.
# ===================================================================

TARGET=$1
IFACE=${2:-eth0}

if [ -z "$TARGET" ]; then
    echo "[!] Usage: reconall <target> [interface]"
    exit 1
fi

OUTDIR="recon_$TARGET"
mkdir -p "$OUTDIR"

echo "=========================================="
echo " Recon Started on: $TARGET"
echo " Results saving in: $OUTDIR/"
echo "=========================================="

# ---------------- PHASE 1: Host Discovery ----------------
echo -e "\n[+] PHASE 1: Host Discovery (Netdiscover)"
echo "    (Netdiscover sirf local network/subnet pe kaam karta hai — skip agar remote target hai)"
if [[ $TARGET =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    sudo netdiscover -r "$TARGET" -i "$IFACE" -P > "$OUTDIR/1_netdiscover.txt"
    echo "    Saved: $OUTDIR/1_netdiscover.txt"
else
    echo "    [skip] Target ek domain/single-IP hai, subnet range nahi — Netdiscover skip kiya"
fi

# ---------------- PHASE 2: Port & Service Scan ----------------
echo -e "\n[+] PHASE 2: Port & Service Scan (Nmap)"
nmap -sC -sV -T4 -p- "$TARGET" -oN "$OUTDIR/2_nmap.txt"
echo "    Saved: $OUTDIR/2_nmap.txt"

# ---------------- PHASE 3: Web Tech Fingerprinting ----------------
echo -e "\n[+] PHASE 3: Web Recon / Fingerprinting (WhatWeb)"
whatweb -v "$TARGET" > "$OUTDIR/3_whatweb.txt" 2>&1
echo "    Saved: $OUTDIR/3_whatweb.txt"

# ---------------- PHASE 4: Directory/File Brute-force ----------------
echo -e "\n[+] PHASE 4: Directory Brute-force (Gobuster)"
WORDLIST="/usr/share/wordlists/dirb/common.txt"
if [ -f "$WORDLIST" ]; then
    gobuster dir -u "http://$TARGET" -w "$WORDLIST" -o "$OUTDIR/4_gobuster.txt" -q
    echo "    Saved: $OUTDIR/4_gobuster.txt"
else
    echo "    [!] Wordlist nahi mili at $WORDLIST — path check karo ya apna wordlist do"
fi

# ---------------- PHASE 5: Vulnerability Scan ----------------
echo -e "\n[+] PHASE 5: Vulnerability Scan (Nikto)"
nikto -h "$TARGET" -o "$OUTDIR/5_nikto.txt"
echo "    Saved: $OUTDIR/5_nikto.txt"

echo -e "\n=========================================="
echo " ✅ Recon Complete — sab results yahan hain: $OUTDIR/"
echo "=========================================="
