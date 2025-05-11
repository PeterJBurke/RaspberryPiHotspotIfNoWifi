#!/bin/bash

# Set your desired SSID and password
DESIRED_SSID1="Network_1"
DESIRED_SSID2="Network_2"
DESIRED_SSID3="Network_3"

HOTSPOT_SSID="hotspotname"
PASSWORD="hotspotpwd"


# Get the currently connected SSID
current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)


if [[ "$current_ssid" == "$DESIRED_SSID1" || "$current_ssid" == "$DESIRED_SSID2" || "$current_ssid" == "$DESIRED_SSID3" ]]; then
    echo "Connected to a desired Wi-Fi SSID: $current_ssid"
else
    echo "Not connected to any desired Wi-Fi SSID. Enabling hotspot..."
    nmcli device wifi hotspot ssid "$HOTSPOT_SSID" password "$PASSWORD"
fi
