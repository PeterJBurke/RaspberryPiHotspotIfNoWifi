#!/bin/bash

# ==============================================================================
# Raspberry Pi WiFi Check & Hotspot Script (using nmcli)
#
# Description:
#   Checks if the Raspberry Pi is connected to one of several specified TARGET_SSIDs.
#   If not connected to any of them, it attempts to create a WiFi hotspot
#   using NetworkManager's nmcli command.
#
# Requirements:
#   - NetworkManager installed and active (common on many Raspberry Pi OS desktop versions)
#   - nmcli (command-line tool for NetworkManager)
#   - Run as root (sudo ./script.sh)
#
# !!! IMPORTANT !!!
#   - CONFIGURE THE VARIABLES IN THE "Configuration" SECTION BELOW.
#   - Internet sharing behavior with 'nmcli device wifi hotspot' depends on
#     NetworkManager's configuration and other active connections. It often
#     tries to share an existing internet connection automatically.
# ==============================================================================

# --- Configuration ---
# !!! EDIT THESE VALUES !!!
# List of desired SSIDs to check for an existing connection.
# Add or remove SSIDs as needed.
# Example: DESIRED_SSIDS=("MyHomeNetwork" "WorkNetwork" "AnotherNetwork")
DESIRED_SSID1="Network_1"
DESIRED_SSID1_PASSWORD="password1"
DESIRED_SSID2="Network_2"
DESIRED_SSID2_PASSWORD="password2"
DESIRED_SSID3="Network_3"
DESIRED_SSID3_PASSWORD="password3"

# Hotspot Configuration (when no DESIRED_SSID is connected)
HOTSPOT_SSID="PiHotspotNM"        # SSID for the NetworkManager hotspot.
HOTSPOT_PASSWORD="raspberrypi"    # Password for the hotspot (min. 8 characters).
WIFI_IFACE="wlan0"                # Your WiFi interface (usually wlan0). Optional for nmcli hotspot,
                                  # but good to specify if you have multiple WiFi cards.

# --- Helper Functions ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [HotspotScriptNM] $1"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR: This script must be run as root. Example: 'sudo $0'"
        exit 1
    fi
}

check_nmcli() {
    log "Checking for nmcli..."
    if ! command -v nmcli &> /dev/null; then
        log "ERROR: nmcli command not found. NetworkManager might not be installed or in PATH."
        log "       Please install NetworkManager (e.g., sudo apt install network-manager) and ensure nmcli is available."
        exit 1
    fi
    log "nmcli found."
}

# --- Main Logic ---
log "Script started."
check_root
check_nmcli

# Validate configuration
if [ -z "$DESIRED_SSID1" ] || [ -z "$DESIRED_SSID2" ] || [ -z "$DESIRED_SSID3" ]; then
    log "ERROR: Please configure all three DESIRED_SSID variables."
    exit 1
fi
if [ -z "$DESIRED_SSID1_PASSWORD" ] || [ -z "$DESIRED_SSID2_PASSWORD" ] || [ -z "$DESIRED_SSID3_PASSWORD" ]; then
    log "ERROR: Please configure all three DESIRED_SSID passwords."
    exit 1
fi
if [ ${#HOTSPOT_PASSWORD} -lt 8 ]; then
    log "ERROR: HOTSPOT_PASSWORD must be at least 8 characters long."
    exit 1
fi

log "Checking current WiFi connection for desired SSIDs..."

current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)

if [[ "$current_ssid" == "$DESIRED_SSID1" || "$current_ssid" == "$DESIRED_SSID2" || "$current_ssid" == "$DESIRED_SSID3" ]]; then
    log "SUCCESS: Currently connected to desired SSID '$current_ssid'."
    exit 0
else
    log "Not connected to any desired SSID. Attempting to connect to each in order..."
    for i in 1 2 3; do
        ssid_var="DESIRED_SSID${i}"
        pass_var="DESIRED_SSID${i}_PASSWORD"
        ssid="${!ssid_var}"
        pass="${!pass_var}"
        log "Trying to connect to SSID '$ssid'..."
        # Delete all existing connection profiles with this SSID to ensure password is updated
        profile_ids=$(nmcli -t -f NAME,TYPE,UUID connection show | awk -F: '$2=="802-11-wireless"{print $1}' | while read -r name; do
            ssid_match=$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null)
            if [ "$ssid_match" = "$ssid" ]; then
                echo "$name"
            fi
        done)
        if [ -n "$profile_ids" ]; then
            for prof in $profile_ids; do
                log "Deleting existing NetworkManager profile '$prof' for SSID '$ssid' to update password."
                nmcli connection delete "$prof"
            done
        fi
        # Use a unique connection name to force nmcli to use the provided password
        unique_con_name="temp-${ssid}-$(date +%s)"
        nmcli dev wifi connect "$ssid" password "$pass" ifname "$WIFI_IFACE" name "$unique_con_name" >/dev/null 2>&1
        sleep 7
        # Check if connected
        new_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)
        if [ "$new_ssid" == "$ssid" ]; then
            log "SUCCESS: Connected to '$ssid'."
            exit 0
        else
            log "Failed to connect to '$ssid'."
        fi
    done
    log "Could not connect to any desired SSID. Proceeding to create hotspot."
fi

# --- Start Hotspot Procedure using nmcli ---
log "Attempting to start hotspot '$HOTSPOT_SSID' on interface $WIFI_IFACE..."

log "Ensuring WiFi is enabled..."
nmcli radio wifi on

HOTSPOT_CON_NAME="Hotspot-${HOTSPOT_SSID}" # A descriptive connection name

log "Creating/Activating hotspot with SSID: '$HOTSPOT_SSID', Password: '********', Connection Name: '$HOTSPOT_CON_NAME'"
if nmcli device wifi hotspot ifname "$WIFI_IFACE" con-name "$HOTSPOT_CON_NAME" ssid "$HOTSPOT_SSID" password "$HOTSPOT_PASSWORD"; then
    log "SUCCESS: Hotspot '$HOTSPOT_SSID' should now be active."
    log "         Connection profile name: '$HOTSPOT_CON_NAME'"
    log "         Clients can connect with Password: '$HOTSPOT_PASSWORD'"
    log "         IP address and DHCP are managed by NetworkManager."
    log "         Internet sharing may be active if another connection (e.g., eth0) has internet."
else
    log "ERROR: Failed to start hotspot using nmcli."
    log "       Check NetworkManager logs for details: journalctl -u NetworkManager -f"
    log "       Ensure your WiFi adapter supports AP mode and isn't blocked (e.g., rfkill unblock wifi)."
    exit 1
fi

log "--------------------------------------------------------------------"
log "To stop this hotspot later, you can try:"
log "  sudo nmcli con down '$HOTSPOT_CON_NAME'"
log "To bring up a regular WiFi connection again (example):"
log "  sudo nmcli con up 'YourRegularWiFiConnectionName'"
log "To delete the hotspot connection profile:"
log "  sudo nmcli con delete '$HOTSPOT_CON_NAME'"
log "--------------------------------------------------------------------"

exit 0
