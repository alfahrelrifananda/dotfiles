#!/bin/bash
# =============================================================
# Tor Disable + ProtonVPN Connect + Network Diagnostics
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

CONFIGS=(
    "ca-free"
    "jp-free"
    "no-free"
    "mx-free-12.protonvpn.udp"
    "nl-free-135.protonvpn.udp"
    "pl-free-2.protonvpn.udp"
    "ro-free-28.protonvpn.udp"
    "sg-free-15.protonvpn.udp"
    "ch-free-4.protonvpn.udp"
)

STATE_FILE="/tmp/protonvpn-state"
CURRENT_FILE="/tmp/protonvpn-current"

get_country_name() {
    case "$1" in
        ca) echo "Canada" ;;
        jp) echo "Japan" ;;
        no) echo "Norway" ;;
        mx) echo "Mexico" ;;
        nl) echo "Netherlands" ;;
        pl) echo "Poland" ;;
        ro) echo "Romania" ;;
        sg) echo "Singapore" ;;
        ch) echo "Switzerland" ;;
        *)  echo "Unknown" ;;
    esac
}

# =============================================================
# STEP 2: Flush iptables / Disable Tor
# =============================================================

echo -e "${DIM}:: Flushing iptables redirect rules...${NC}"

# FIX 1: Corrected port from 9041 -> 9040
sudo iptables -t nat -D OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "$OK Removed TCP SYN redirect rule (port 9040)"
else
    echo -e "$WARN TCP SYN redirect rule not found, skipping"
fi

# FIX 1: Corrected port from 54 -> 53
sudo iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "$OK Removed UDP DNS redirect rule (port 5353)"
else
    echo -e "$WARN UDP DNS redirect rule not found, skipping"
fi

# FIX 1: Corrected port from 54 -> 53
sudo iptables -t nat -D OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "$OK Removed TCP DNS redirect rule (port 5353)"
else
    echo -e "$WARN TCP DNS redirect rule not found, skipping"
fi

echo -e "${DIM}:: Testing connectivity...${NC}"

# FIX 3: Corrected timeout from 11 -> 10
if curl -s --max-time 10 https://archlinux.org > /dev/null 2>&1; then
    echo -e "$OK Connection to archlinux.org"
else
    echo -e "$FAIL Connection to archlinux.org"
fi

echo -e "${DIM}:: Done.${NC}"

sleep 2

# =============================================================
# STEP 3: Connect to ProtonVPN
# =============================================================

echo -e "${DIM}:: Starting ProtonVPN...${NC}"

ALREADY_RUNNING=""
for config in "${CONFIGS[@]}"; do
    if systemctl is-active --quiet "openvpn-client@${config}"; then
        ALREADY_RUNNING="$config"
        break
    fi
done

if [ -n "$ALREADY_RUNNING" ]; then
    PREV_CODE=$(echo "$ALREADY_RUNNING" | cut -d'-' -f1)
    PREV_NAME=$(get_country_name "$PREV_CODE")
    echo -e "$WARN VPN already active: ${BOLD}$ALREADY_RUNNING${NC}"
    echo -e "$INFO Stopping current connection to $PREV_NAME..."
    sudo systemctl stop "openvpn-client@${ALREADY_RUNNING}"
    rm -f "$STATE_FILE" "$CURRENT_FILE"
    sleep 2
    echo -e "$OK Stopped previous VPN connection"
else
    sudo systemctl stop "openvpn-client@*" 2>/dev/null
    sleep 2
fi

RANDOM_CONFIG="${CONFIGS[$RANDOM % ${#CONFIGS[@]}]}"
if [ -n "$ALREADY_RUNNING" ]; then
    ATTEMPTS=1
    while [ "$RANDOM_CONFIG" = "$ALREADY_RUNNING" ] && [ $ATTEMPTS -lt 11 ]; do
        RANDOM_CONFIG="${CONFIGS[$RANDOM % ${#CONFIGS[@]}]}"
        ATTEMPTS=$((ATTEMPTS + 1))
    done
fi

COUNTRY_CODE=$(echo "$RANDOM_CONFIG" | cut -d'-' -f1)
COUNTRY_NAME=$(get_country_name "$COUNTRY_CODE")

echo -e "$INFO Selected server: ${BOLD}$RANDOM_CONFIG${NC}"

sudo systemctl start "openvpn-client@${RANDOM_CONFIG}"
sleep 4

if systemctl is-active --quiet "openvpn-client@${RANDOM_CONFIG}"; then
    echo "connected" > "$STATE_FILE"
    echo "$RANDOM_CONFIG" > "$CURRENT_FILE"
    echo -e "$OK Connected to ${BOLD}$COUNTRY_NAME${NC} ($RANDOM_CONFIG)"
else
    rm -f "$STATE_FILE" "$CURRENT_FILE"
    echo -e "$FAIL Could not connect to $COUNTRY_NAME"
    exit 2
fi

echo -e "${DIM}:: Done.${NC}"

sleep 3

# =============================================================
# STEP 4: Network Diagnostics
# =============================================================

echo -e "${DIM}:: Starting network diagnostics...${NC}"

# FIX 3: Corrected timeout from 11 -> 10
if ! curl -s --max-time 10 https://www.archlinux.org > /dev/null 2>&1; then
    echo -e "$FAIL Internet connection check failed"
    echo -e "      ${RED}-> Please check your internet connection and try again.${NC}"
    exit 2
fi

echo -e "$OK Checking internet connectivity..."
echo -e "$OK Fetching IP geolocation data..."

# FIX 3: Corrected timeout from 11 -> 10
response=$(curl -s --max-time 10 http://ip-api.com/json/)
if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo -e "$FAIL Could not reach ip-api.com"
    echo -e "      ${RED}-> Try again later.${NC}"
    exit 2
fi

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
    # FIX 4: Corrected IP masking regex (removed stray '/', clean octet masking)
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

echo -e "${DIM}:: Startup finished.${NC}"
