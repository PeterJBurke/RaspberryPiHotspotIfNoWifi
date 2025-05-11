#!/bin/bash

# Script to get current Wi-Fi SSID and password on a Raspberry Pi (using NetworkManager)

# Get the currently connected SSID
current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)

if [ -z "$current_ssid" ]; then
    echo "Error: Could not determine current Wi-Fi SSID. Are you connected to Wi-Fi?"
    exit 1
fi

echo "Current Wi-Fi SSID: $current_ssid"

# Attempt to get the connection name associated with the active SSID.
# Often, the connection name is the same as the SSID, but it can be different.
# We'll find the active connection that matches the current_ssid.
connection_name=$(nmcli -t --fields NAME,802-11-WIRELESS.SSID c s --active | grep ":${current_ssid}$" | head -n 1 | cut -d':' -f1)

if [ -z "$connection_name" ]; then
    echo "Warning: Could not automatically determine the NetworkManager connection name for SSID '$current_ssid'."
    echo "Attempting to use SSID as connection name. This might not always work."
    connection_name="$current_ssid"
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
