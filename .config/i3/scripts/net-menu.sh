#!/bin/bash
# =============================================================
# Network Toggle Menu - dmenu launcher
# =============================================================

SCRIPTS_DIR="$HOME/scripts"

CHOICE=$(printf "Tor On\nTor Off\nVPN On\nVPN Off" \
    | dmenu -p "Network:")

case "$CHOICE" in
    "Tor On")
        alacritty -e bash -c "$SCRIPTS_DIR/tor_on.sh; echo; read -p 'Press enter to close...'" &
        ;;
    "Tor Off")
        alacritty -e bash -c "$SCRIPTS_DIR/tor_off.sh; echo; read -p 'Press enter to close...'" &
        ;;
    "VPN On")
        alacritty -e bash -c "$SCRIPTS_DIR/vpn_on.sh; echo; read -p 'Press enter to close...'" &
        ;;
    "VPN Off")
        alacritty -e bash -c "$SCRIPTS_DIR/vpn_off.sh; echo; read -p 'Press enter to close...'" &
        ;;
esac
