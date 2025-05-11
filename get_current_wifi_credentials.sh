#!/bin/bash

# Script to get current Wi-Fi SSID and password on a Raspberry Pi (using NetworkManager)

# Get the currently connected SSID
current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)

if [ -z "$current_ssid" ]; then
    echo "Error: Could not determine current Wi-Fi SSID. Are you connected to Wi-Fi?"
    exit 1
fi

echo "Current Wi-Fi SSID: $current_ssid"

# Attempt to determine the NetworkManager connection name for the active SSID
connection_name=""
echo "Searching for connection profile matching SSID: $current_ssid..."

# Iterate over all active connection *names*
# Suppress errors from nmcli if no active connections or if a name is problematic in the loop
for name in $(nmcli -t -f NAME connection show --active 2>/dev/null); do
    # For each active connection name, get its configured SSID
    # The property is '802-11-wireless.ssid'. Use -g for terse output.
    # Suppress errors if the property doesn't exist for a connection (e.g., VPN, Ethernet)
    profile_ssid=$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null)
    
    if [ "$profile_ssid" = "$current_ssid" ]; then
        connection_name="$name"
        echo "Found active connection profile: '$connection_name' for SSID '$current_ssid'"
        break
    fi
done

# Fallback if not found by iterating active connections with matching SSIDs
if [ -z "$connection_name" ]; then
    echo "Could not find an active connection profile with SSID '$current_ssid' by iterating."
    echo "Checking if a connection profile named '$current_ssid' is active..."
    # Check if a connection profile *named* as the current SSID exists and is active
    # GENERAL.STATE will output 'activated' or similar if active.
    if nmcli -t -f GENERAL.STATE connection show "$current_ssid" 2>/dev/null | grep -q "activated"; then
        connection_name="$current_ssid"
        echo "Found active connection profile named '$connection_name'."
    else
        echo "No active connection profile found with name '$current_ssid' either."
    fi
fi

if [ -z "$connection_name" ]; then
    echo "Warning: Could not definitively determine the NetworkManager connection name for SSID '$current_ssid'."
    echo "As a last resort, using SSID '$current_ssid' as the connection name for password retrieval."
    echo "This might not work if the profile name is different from the SSID."
    connection_name="$current_ssid" # Fallback to SSID itself
fi

# Get the password (PSK) for this connection
# This command usually requires sudo privileges
if command -v sudo >/dev/null 2>&1; then
    wifi_password=$(sudo nmcli -s -g 802-11-wireless-security.psk connection show "$connection_name" 2>/dev/null)
else
    echo "Warning: sudo command not found. Attempting to get password without sudo (likely to fail for protected fields)."
    wifi_password=$(nmcli -s -g 802-11-wireless-security.psk connection show "$connection_name" 2>/dev/null)
fi

if [ -n "$wifi_password" ]; then
    echo "Password for '$current_ssid' (Connection: '$connection_name'): $wifi_password"
elif [ "$(id -u)" -ne 0 ]; then
    echo "Could not retrieve password for '$current_ssid'."
    echo "Try running this script with sudo: sudo $0"
else
    echo "Could not retrieve password for '$current_ssid' (even with sudo)."
    echo "Check if the connection profile '$connection_name' exists and has a saved password."
fi
