#!/bin/bash
# =============================================================
# VPN Disable - Stop all ProtonVPN connections
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
# STEP 1: Find and stop active VPN
# =============================================================

echo -e "${DIM}:: Checking for active VPN connections...${NC}"

FOUND_ANY=false

for config in "${CONFIGS[@]}"; do
    if systemctl is-active --quiet "openvpn-client@${config}"; then
        CODE=$(echo "$config" | cut -d'-' -f1)
        COUNTRY=$(get_country_name "$CODE")
        echo -e "$INFO Found active connection: ${BOLD}$config${NC} ($COUNTRY)"
        sudo systemctl stop "openvpn-client@${config}"
        sleep 1
        if ! systemctl is-active --quiet "openvpn-client@${config}"; then
            echo -e "$OK Stopped $config"
        else
            echo -e "$FAIL Could not stop $config"
        fi
        FOUND_ANY=true
    fi
done

# Also stop any stray openvpn services not in our list
sudo systemctl stop "openvpn-client@*" 2>/dev/null

if [ "$FOUND_ANY" = false ]; then
    echo -e "$WARN No active VPN connections found"
fi

# =============================================================
# STEP 2: Clean up state files
# =============================================================

echo -e "${DIM}:: Cleaning up state files...${NC}"

if [ -f "$STATE_FILE" ] || [ -f "$CURRENT_FILE" ]; then
    rm -f "$STATE_FILE" "$CURRENT_FILE"
    echo -e "$OK State files removed"
else
    echo -e "$WARN No state files found, skipping"
fi

# =============================================================
# STEP 3: Test connectivity
# =============================================================

echo -e "${DIM}:: Testing connectivity...${NC}"

sleep 1

if curl -s --max-time 10 https://archlinux.org > /dev/null 2>&1; then
    echo -e "$OK Connection to archlinux.org"
else
    echo -e "$FAIL Connection to archlinux.org"
fi

echo -e "${DIM}:: Done.${NC}"
echo -e "$OK ${BOLD}VPN is now disconnected${NC}"

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
