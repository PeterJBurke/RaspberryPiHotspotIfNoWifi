# RaspberryPiHotspotIfNoWifi

Automatically create a WiFi hotspot on your Raspberry Pi if it fails to connect to any of your preferred WiFi networks. Works on Raspbian "Bookworm" and Raspberry Pi Zero 2 W (should work on other models as well).

## Features
- Tries to connect to up to three specified WiFi networks (each with its own password).
- If none connect, automatically creates a WiFi hotspot using NetworkManager.
- Designed for headless setup (no monitor/keyboard required).

## Setup Steps
1. **Install Raspbian**: Flash Raspbian "Bookworm" to an SD card. Enable SSH and configure a username/password. [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. **Boot and SSH**: Insert SD card into Pi, boot, and wait ~10 minutes for setup. Find its IP from your router or try:
   ```sh
   ssh username@hostname.local
   # or
   ssh username@192.168.1.xxx
   ```
3. **Download the scripts**:
   ```sh
   sudo curl -L https://raw.githubusercontent.com/PeterJBurke/RaspberryPiHotspotIfNoWifi/refs/heads/main/check_wifi.sh | sudo tee /usr/local/bin/check_wifi.sh > /dev/null
   sudo chmod +x /usr/local/bin/check_wifi.sh
   sudo curl -L https://raw.githubusercontent.com/PeterJBurke/RaspberryPiHotspotIfNoWifi/refs/heads/main/check_wifi.service | sudo tee /etc/systemd/system/check_wifi.service > /dev/null
   ```
4. **Edit `check_wifi.sh`**: Open the script and configure your WiFi SSIDs and passwords, and your hotspot SSID/password.
   ```sh
   sudo nano /usr/local/bin/check_wifi.sh
   # Set DESIRED_SSID1, DESIRED_SSID1_PASSWORD, etc.
   # Set HOTSPOT_SSID and HOTSPOT_PASSWORD
   ```
5. **Enable the service**:
   ```sh
   sudo systemctl enable check_wifi.service
   sudo systemctl start check_wifi.service
   ```
6. **Reboot**:
   ```sh
   sudo reboot now
   ```
7. **Usage**:
   - If Pi connects to your WiFi: use as normal.
   - If not, it will create a hotspot (default IP: 10.42.0.1). Connect to this from your device and SSH in:
     ```sh
     ssh username@10.42.0.1
     ```

## How It Works
- The script checks if the Pi is connected to any of the three specified SSIDs.
- If not, it tries to connect to each SSID in order, using its password.
- If all fail, it creates a hotspot using NetworkManager.

## Troubleshooting
- **NetworkManager must be installed and manage your WiFi interface.**
  - Install with: `sudo apt install network-manager`
  - Disable dhcpcd if needed: `sudo systemctl disable dhcpcd`
- **Your WiFi adapter must support AP (Access Point) mode.**
- **Check script logs**:
  - The script logs to stdout/stderr. If run as a service, check logs with:
    ```sh
    sudo journalctl -u check_wifi.service -f
    ```
- **Check NetworkManager logs**:
    ```sh
    sudo journalctl -u NetworkManager -f
    ```
- **Check WiFi status**:
    ```sh
    nmcli device status
    nmcli connection show
    nmcli device wifi list
    ```
- **Debug connection attempts**:
    - Try connecting manually:
      ```sh
      sudo nmcli dev wifi connect "SSID" password "PASSWORD" ifname wlan0
      ```
- **Hotspot doesn’t start?**
    - Make sure no other connection is active on the WiFi interface.
    - Try bringing down existing connections:
      ```sh
      sudo nmcli con down id <connection_name>
      ```
    - Delete old hotspot profiles if needed:
      ```sh
      sudo nmcli con delete id <connection_name>
      ```
- **Permissions**: Script must be run as root (sudo).

## Customization
- Change the number of SSIDs by editing the script and adding/removing DESIRED_SSID/PASSWORD pairs.
- Adjust hotspot SSID/password as desired.

## Credits
- Inspired by community solutions for Raspberry Pi WiFi fallback and hotspot automation.

---

If you encounter issues, please open an issue on the GitHub repository.
