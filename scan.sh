#!/bin/bash
# ===================================================================
# scan — Phased Recon Automation (Colorized)
# Phase 1: Host Discovery       -> Netdiscover
# Phase 2: Port/Service Scan    -> Nmap
# Phase 3: Web Tech Fingerprint -> WhatWeb
# Phase 4: Directory Brute-force-> Gobuster
# Phase 5: Vulnerability Scan   -> Nikto
#
# Usage: scan <target-domain-or-ip> [interface-for-netdiscover]
# Example: scan target.com
#          scan target.com eth0
#
# Sirf authorized scope (HackerOne program) pe hi chalao.
# ===================================================================

# ---------- Colors ----------
RESET='\033[0m'
BOLD='\033[1m'

RED='\033[1;31m'        # Phase 1 - Netdiscover
YELLOW='\033[1;33m'      # Phase 2 - Nmap
CYAN='\033[1;36m'        # Phase 3 - WhatWeb
MAGENTA='\033[1;35m'     # Phase 4 - Gobuster
BLUE='\033[1;34m'        # Phase 5 - Nikto
GREEN='\033[1;32m'       # Target / scanning-in-progress lines
WHITE='\033[1;37m'       # Banners / general info

TARGET=$1
IFACE=${2:-eth0}

if [ -z "$TARGET" ]; then
    echo -e "${RED}[!] Usage: scan <target> [interface]${RESET}"
    exit 1
fi

OUTDIR="recon_$TARGET"
mkdir -p "$OUTDIR"

echo -e "${WHITE}=========================================="
echo -e " Recon Started on: ${GREEN}${TARGET}${WHITE}"
echo -e " Results saving in: ${GREEN}${OUTDIR}/${WHITE}"
echo -e "==========================================${RESET}"

# ---------------- PHASE 1: Host Discovery ----------------
echo -e "\n${RED}[+] PHASE 1: Host Discovery (Netdiscover)${RESET}"
if [[ $TARGET =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    echo -e "${GREEN}    Scanning subnet: $TARGET ...${RESET}"
    sudo netdiscover -r "$TARGET" -i "$IFACE" -P > "$OUTDIR/1_netdiscover.txt"
    echo -e "${RED}    Saved: $OUTDIR/1_netdiscover.txt${RESET}"
else
    echo -e "${RED}    [skip] Target ek domain/single-IP hai, subnet range nahi — Netdiscover skip kiya${RESET}"
fi

# ---------------- PHASE 2: Port & Service Scan ----------------
echo -e "\n${YELLOW}[+] PHASE 2: Port & Service Scan (Nmap)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
nmap -sC -sV -T4 -p- "$TARGET" -oN "$OUTDIR/2_nmap.txt"
echo -e "${YELLOW}    Saved: $OUTDIR/2_nmap.txt${RESET}"

# ---------------- PHASE 3: Web Tech Fingerprinting ----------------
echo -e "\n${CYAN}[+] PHASE 3: Web Recon / Fingerprinting (WhatWeb)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
whatweb -v "$TARGET" > "$OUTDIR/3_whatweb.txt" 2>&1
echo -e "${CYAN}    Saved: $OUTDIR/3_whatweb.txt${RESET}"

# ---------------- PHASE 4: Directory/File Brute-force ----------------
echo -e "\n${MAGENTA}[+] PHASE 4: Directory Brute-force (Gobuster)${RESET}"
WORDLIST="/usr/share/wordlists/dirb/common.txt"
if [ -f "$WORDLIST" ]; then
    echo -e "${GREEN}    Scanning: http://$TARGET ...${RESET}"
    gobuster dir -u "http://$TARGET" -w "$WORDLIST" -o "$OUTDIR/4_gobuster.txt" -q
    echo -e "${MAGENTA}    Saved: $OUTDIR/4_gobuster.txt${RESET}"
else
    echo -e "${MAGENTA}    [!] Wordlist nahi mili at $WORDLIST — path check karo ya apna wordlist do${RESET}"
fi

# ---------------- PHASE 5: Vulnerability Scan ----------------
echo -e "\n${BLUE}[+] PHASE 5: Vulnerability Scan (Nikto)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
nikto -h "$TARGET" -o "$OUTDIR/5_nikto.txt"
echo -e "${BLUE}    Saved: $OUTDIR/5_nikto.txt${RESET}"

echo -e "\n${WHITE}=========================================="
echo -e " ${GREEN}✅ Recon Complete${WHITE} — sab results yahan hain: ${GREEN}$OUTDIR/${WHITE}"
echo -e "==========================================${RESET}"
