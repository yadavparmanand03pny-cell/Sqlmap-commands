#!/bin/bash
# ===================================================================
# scan — Phased Recon Automation (Colorized)
# Phase 1: Subdomain Enumeration -> Amass
# Phase 2: Live Host Check       -> Httpx
# Phase 3: Port/Service Scan     -> Nmap
# Phase 4: SSL/TLS Check         -> Sslscan
# Phase 5: CMS Scan (optional)   -> WPScan
# Phase 6: Parameter Discovery   -> Arjun
# Phase 7: Vulnerability Scan    -> Nikto
#
# Usage: scan <target-domain-or-ip>
# Example: scan target.com
#
# Sirf authorized scope (HackerOne program) pe hi chalao.
# ===================================================================

# ---------- Colors ----------
RESET='\033[0m'

RED='\033[1;31m'        # Phase 1 - Amass (subdomain enum)
YELLOW='\033[1;33m'     # Phase 2 - Httpx (live check)
ORANGE='\033[1;38;5;208m' # Phase 3 - Nmap (ports)
CYAN='\033[1;36m'       # Phase 4 - Sslscan
PURPLE='\033[1;35m'     # Phase 5 - WPScan
MAGENTA='\033[1;95m'    # Phase 6 - Arjun
BLUE='\033[1;34m'       # Phase 7 - Nikto
GREEN='\033[1;32m'      # Target / scanning-in-progress lines
WHITE='\033[1;37m'      # Banners / general info

TARGET=$1

if [ -z "$TARGET" ]; then
    echo -e "${RED}[!] Usage: scan <target>${RESET}"
    exit 1
fi

OUTDIR="recon_$TARGET"
mkdir -p "$OUTDIR"

echo -e "${WHITE}=========================================="
echo -e " Recon Started on: ${GREEN}${TARGET}${WHITE}"
echo -e " Results saving in: ${GREEN}${OUTDIR}/${WHITE}"
echo -e "==========================================${RESET}"

# ---------------- PHASE 1: Subdomain Enumeration ----------------
echo -e "\n${RED}[+] PHASE 1: Subdomain Enumeration (Amass)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
amass enum -passive -d "$TARGET" -o "$OUTDIR/1_amass.txt"
echo -e "${RED}    Saved: $OUTDIR/1_amass.txt${RESET}"

# ---------------- PHASE 2: Live Host Check ----------------
echo -e "\n${YELLOW}[+] PHASE 2: Live Host Check (Httpx)${RESET}"
if [ -s "$OUTDIR/1_amass.txt" ]; then
    echo -e "${GREEN}    Checking discovered subdomains for live hosts ...${RESET}"
    cat "$OUTDIR/1_amass.txt" | httpx -silent -status-code -title -tech-detect -o "$OUTDIR/2_httpx.txt"
    echo -e "${YELLOW}    Saved: $OUTDIR/2_httpx.txt${RESET}"
else
    echo -e "${GREEN}    Checking target directly: $TARGET ...${RESET}"
    echo "$TARGET" | httpx -silent -status-code -title -tech-detect -o "$OUTDIR/2_httpx.txt"
    echo -e "${YELLOW}    Saved: $OUTDIR/2_httpx.txt${RESET}"
fi

# ---------------- PHASE 3: Port & Service Scan ----------------
echo -e "\n${ORANGE}[+] PHASE 3: Port & Service Scan (Nmap)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
nmap -sC -sV -T4 -p- "$TARGET" -oN "$OUTDIR/3_nmap.txt"
echo -e "${ORANGE}    Saved: $OUTDIR/3_nmap.txt${RESET}"

# ---------------- PHASE 4: SSL/TLS Check ----------------
echo -e "\n${CYAN}[+] PHASE 4: SSL/TLS Check (Sslscan)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
sslscan "$TARGET" > "$OUTDIR/4_sslscan.txt"
echo -e "${CYAN}    Saved: $OUTDIR/4_sslscan.txt${RESET}"

# ---------------- PHASE 5: CMS Scan (WPScan) ----------------
echo -e "\n${PURPLE}[+] PHASE 5: CMS Scan (WPScan)${RESET}"
echo -e "${GREEN}    Checking if $TARGET is WordPress ...${RESET}"
wpscan --url "http://$TARGET" --no-banner -o "$OUTDIR/5_wpscan.txt" 2>&1
echo -e "${PURPLE}    Saved: $OUTDIR/5_wpscan.txt (agar WordPress nahi hai toh result minimal hoga)${RESET}"

# ---------------- PHASE 6: Parameter Discovery ----------------
echo -e "\n${MAGENTA}[+] PHASE 6: Parameter Discovery (Arjun)${RESET}"
echo -e "${GREEN}    Scanning: http://$TARGET ...${RESET}"
arjun -u "http://$TARGET" -o "$OUTDIR/6_arjun.txt"
echo -e "${MAGENTA}    Saved: $OUTDIR/6_arjun.txt${RESET}"

# ---------------- PHASE 7: Vulnerability Scan ----------------
echo -e "\n${BLUE}[+] PHASE 7: Vulnerability Scan (Nikto)${RESET}"
echo -e "${GREEN}    Scanning: $TARGET ...${RESET}"
nikto -h "$TARGET" -o "$OUTDIR/7_nikto.txt"
echo -e "${BLUE}    Saved: $OUTDIR/7_nikto.txt${RESET}"

echo -e "\n${WHITE}=========================================="
echo -e " ${GREEN}✅ Recon Complete${WHITE} — sab results yahan hain: ${GREEN}$OUTDIR/${WHITE}"
echo -e "==========================================${RESET}"
