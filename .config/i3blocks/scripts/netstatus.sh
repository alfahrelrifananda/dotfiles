#!/bin/bash
TOR_ACTIVE=false
VPN_CONFIG=""
VPN_COUNTRY=""
TOR_COUNTRY=""

if [ -f /tmp/protonvpn-current ]; then
    VPN_CONFIG=$(cat /tmp/protonvpn-current)
fi

if [ -z "$VPN_CONFIG" ]; then
    for svc in $(systemctl list-units --state=active --no-legend 'openvpn-client@*' 2>/dev/null | awk '{print $1}'); do
        VPN_CONFIG=$(echo "$svc" | sed 's/openvpn-client@//;s/\.service//')
        break
    done
fi

if [ -z "$VPN_CONFIG" ]; then
    if sudo iptables -t nat -L OUTPUT 2>/dev/null | grep -q "9040"; then
        TOR_ACTIVE=true
        # Fetch exit node country via torsocks if available, else plain curl
        if command -v torsocks &>/dev/null; then
            response=$(torsocks curl -s --max-time 8 http://ip-api.com/json/ 2>/dev/null)
        else
            response=$(curl -s --max-time 8 http://ip-api.com/json/ 2>/dev/null)
        fi
        if [ -n "$response" ]; then
            TOR_COUNTRY=$(echo "$response" | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')
        fi
    fi
fi

if [ -n "$VPN_CONFIG" ]; then
    CODE=$(echo "$VPN_CONFIG" | cut -d'-' -f1)
    case "$CODE" in
        ca) VPN_COUNTRY="Canada" ;;
        jp) VPN_COUNTRY="Japan" ;;
        no) VPN_COUNTRY="Norway" ;;
        mx) VPN_COUNTRY="Mexico" ;;
        nl) VPN_COUNTRY="Netherlands" ;;
        pl) VPN_COUNTRY="Poland" ;;
        ro) VPN_COUNTRY="Romania" ;;
        sg) VPN_COUNTRY="Singapore" ;;
        ch) VPN_COUNTRY="Switzerland" ;;
        *)  VPN_COUNTRY="VPN" ;;
    esac
fi

if [ -n "$VPN_CONFIG" ]; then
    echo "<span color='#a6e3a1'> 󰕥 $VPN_COUNTRY </span>"
elif $TOR_ACTIVE; then
    if [ -n "$TOR_COUNTRY" ]; then
        echo "<span color='#7c3aed'>  Tor ($TOR_COUNTRY) </span>"
    else
        echo "<span color='#7c3aed'>  Tor </span>"
    fi
else
    echo "<span color='#f38ba8'> 󰦞 No VPN </span>"
fi
