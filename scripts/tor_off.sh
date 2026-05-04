#!/bin/bash
# =============================================================
# Tor Disable - Remove iptables redirect rules + stop Tor
# =============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

OK="[  ${GREEN}OK${NC}  ]"
FAIL="[${RED}FAILED${NC}]"
WARN="[ ${YELLOW}WARN${NC} ]"
INFO="[ ${CYAN}INFO${NC} ]"

# =============================================================
# STEP 1: Flush iptables redirect rules
# =============================================================

echo -e "${DIM}:: Flushing iptables redirect rules...${NC}"

sudo iptables -t nat -D OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "$OK Removed TCP SYN redirect rule (port 9040)"
else
    echo -e "$WARN TCP SYN redirect rule not found, skipping"
fi

sudo iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "$OK Removed UDP DNS redirect rule (port 5353)"
else
    echo -e "$WARN UDP DNS redirect rule not found, skipping"
fi

sudo iptables -t nat -D OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "$OK Removed TCP DNS redirect rule (port 5353)"
else
    echo -e "$WARN TCP DNS redirect rule not found, skipping"
fi

# =============================================================
# STEP 2: Stop Tor service
# =============================================================

echo -e "${DIM}:: Stopping Tor service...${NC}"

if systemctl is-active --quiet tor; then
    sudo systemctl stop tor
    sleep 1
    if ! systemctl is-active --quiet tor; then
        echo -e "$OK Tor service stopped"
    else
        echo -e "$FAIL Could not stop Tor service"
        exit 1
    fi
else
    echo -e "$WARN Tor service was not running, skipping"
fi

# =============================================================
# STEP 3: Test connectivity
# =============================================================

echo -e "${DIM}:: Testing connectivity...${NC}"

if curl -s --max-time 10 https://archlinux.org > /dev/null 2>&1; then
    echo -e "$OK Connection to archlinux.org"
else
    echo -e "$FAIL Connection to archlinux.org"
fi

echo -e "${DIM}:: Done.${NC}"
echo -e "$OK ${BOLD}Tor is now disabled${NC}"

# =============================================================
# STEP 4: Location Check
# =============================================================

echo -e "${DIM}:: Fetching IP geolocation data...${NC}"

response=$(curl -s --max-time 10 http://ip-api.com/json/)
if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo -e "$FAIL Could not reach ip-api.com"
else
    IP=$(echo "$response"        | sed -n 's/.*"query":"\([^"]*\)".*/\1/p')
    COUNTRY=$(echo "$response"   | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')
    CITY=$(echo "$response"      | sed -n 's/.*"city":"\([^"]*\)".*/\1/p')
    REGION=$(echo "$response"    | sed -n 's/.*"regionName":"\([^"]*\)".*/\1/p')
    POSTAL=$(echo "$response"    | sed -n 's/.*"zip":"\([^"]*\)".*/\1/p')
    TIMEZONE=$(echo "$response"  | sed -n 's/.*"timezone":"\([^"]*\)".*/\1/p')
    LATITUDE=$(echo "$response"  | sed -n 's/.*"lat":\([^,}]*\).*/\1/p')
    LONGITUDE=$(echo "$response" | sed -n 's/.*"lon":\([^,}]*\).*/\1/p')
    ISP=$(echo "$response"       | sed -n 's/.*"isp":"\([^"]*\)".*/\1/p')

    echo -e "${DIM}:: Resolving location fields...${NC}"

    if [ -n "$IP" ]; then
        MASKED_IP=$(echo "$IP" | sed 's/^\([0-9]*\)\.\([0-9]*\)\.[0-9]*\.[0-9]*$/\1.\2.***.***/')
        echo -e "$INFO IP Address:   ${BOLD}$MASKED_IP${NC}"
    else
        echo -e "$WARN IP Address:   ${BOLD}Not detected${NC}"
    fi

    [ -n "$COUNTRY"   ] && echo -e "$INFO Country:      ${BOLD}$COUNTRY${NC}"   || echo -e "$WARN Country:      ${BOLD}Not detected${NC}"
    [ -n "$CITY"      ] && echo -e "$INFO City:         ${BOLD}$CITY${NC}"      || echo -e "$WARN City:         ${BOLD}Not detected${NC}"
    [ -n "$REGION"    ] && echo -e "$INFO Region:       ${BOLD}$REGION${NC}"    || echo -e "$WARN Region:       ${BOLD}Not detected${NC}"
    [ -n "$POSTAL"    ] && echo -e "$INFO Postal Code:  ${BOLD}$POSTAL${NC}"    || echo -e "$WARN Postal Code:  ${BOLD}Not detected${NC}"
    [ -n "$TIMEZONE"  ] && echo -e "$INFO Timezone:     ${BOLD}$TIMEZONE${NC}"  || echo -e "$WARN Timezone:     ${BOLD}Not detected${NC}"

    if [ -n "$LATITUDE" ] && [ -n "$LONGITUDE" ]; then
        echo -e "$INFO Coordinates:  ${BOLD}$LATITUDE, $LONGITUDE${NC}"
    else
        echo -e "$WARN Coordinates:  ${BOLD}Not detected${NC}"
    fi

    [ -n "$ISP" ] && echo -e "$INFO ISP:          ${BOLD}$ISP${NC}" || echo -e "$WARN ISP:          ${BOLD}Not detected${NC}"
fi

echo -e "${DIM}:: Startup finished.${NC}"
