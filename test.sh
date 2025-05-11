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
DESIRED_SSIDS=("Network_1" "Network_2" "Network_3")

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
if [ ${#DESIRED_SSIDS[@]} -eq 0 ]; then
    log "ERROR: DESIRED_SSIDS array is empty. Please configure at least one target SSID."
    exit 1
fi
if [ ${#HOTSPOT_PASSWORD} -lt 8 ]; then
    log "ERROR: HOTSPOT_PASSWORD must be at least 8 characters long."
    exit 1
fi

log "Checking current WiFi connection for desired SSIDs..."

# Get the currently connected SSID using nmcli.
# -t for terse output, -f for fields ACTIVE and SSID, dev wifi for wifi devices.
# grep '^yes' filters for active connections.
# cut -d':' -f2 extracts the SSID part.
current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)

connected_to_desired=false
if [ -n "$current_ssid" ]; then # Check if current_ssid is not empty
    for desired_ssid_item in "${DESIRED_SSIDS[@]}"; do
        if [ "$current_ssid" == "$desired_ssid_item" ]; then
            log "SUCCESS: Currently connected to desired SSID '$current_ssid'."
            connected_to_desired=true
            break
        fi
    done
fi

if $connected_to_desired; then
    exit 0
else
    if [ -n "$current_ssid" ]; then
        log "INFO: Connected to '$current_ssid', which is not in the desired list."
    else
        log "INFO: Not connected to any WiFi network."
    fi
    log "Proceeding to configure and start a WiFi hotspot using nmcli."
fi

# --- Start Hotspot Procedure using nmcli ---
log "Attempting to start hotspot '$HOTSPOT_SSID' on interface $WIFI_IFACE..."

# First, try to turn WiFi on if it's off, as hotspot creation might fail otherwise.
log "Ensuring WiFi is enabled..."
nmcli radio wifi on

# Check if a hotspot with the same name is already configured.
# If so, nmcli might just activate it or fail if parameters differ.
# For simplicity, this script doesn't explicitly delete old hotspot connections,
# but 'nmcli con down <hotspot_name>' and 'nmcli con delete <hotspot_name>' could be used.

# Create and activate the hotspot.
# 'nmcli device wifi hotspot' creates a new connection profile if one doesn't exist
# with the given SSID, or reuses an existing one.
# The 'ifname $WIFI_IFACE' part is optional but good for specifying the interface.
# If you omit 'ifname $WIFI_IFACE', NetworkManager will pick a suitable WiFi interface.
# The 'con-name' parameter gives a specific name to the connection profile created by nmcli.
# This makes it easier to manage (e.g., 'nmcli con down MyPiHotspotConnection').
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
