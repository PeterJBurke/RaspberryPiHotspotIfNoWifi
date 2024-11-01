# RaspberryPiHotspotIfNoWifi
How to configure Raspberry Pi to make a hotspot if it fails to connect to WiFi.
This works on Raspbian "Bookworm" and Raspberry Pi Zero 2 W. It should work on other models also (untested).
If you follow these directions, it will work headless (i.e. you won't need to use an external keyboard an monitor, you can just ssh in).

Steps:
1. Install stock Raspbian "Bookworm" to an SD card. Make sure to use the options to enable ssh, and to have the local WiFi SSID and pwd burned to the card. Use website xxx. Configure also the hostname and the username/pwd.
2. Insert SD card into Pi, and boot it up. Wait 10 minutes for the initial disk unpacking.
3. Find the IP address from your WiFi router (usually it is something like 192.168.1.xxx, where xxx is from 2 to 256). Or you can try hostname.local.
4. From a terminal, ssh into 192.168.1.xxx like this: ssh username@hostname.local or ssh username@192.168.1.xxx
5. Within the terminal, get the two files you need:
6. wget check_wifi.service
7. wget check_wifi.sh
8. Copy the files to their final destination and set their properties.
9. Edit the check_wifi.sh file to enter you SSID name(s). And the name you want for your WiFi hotspot and pwd if no SSID can be connected to.
10. Enable the service with sudo systemctl enable check_wifi.service
11. Reboot the machine with sudo reboot now.
12. If you are on your local net, it should work as before.
13. If it creates a hotspot, connect to it with your WiFi on your laptop or smart phone/tablet. Then you can ssh in as ssh username@xxx.xxx.
