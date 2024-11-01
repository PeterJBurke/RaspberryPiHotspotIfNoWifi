# RaspberryPiHotspotIfNoWifi
How to configure Raspberry Pi to make a hotspot if it fails to connect to WiFi.
This works on Raspbian "Bookworm" and Raspberry Pi Zero 2 W. It should work on other models also (untested).
If you follow these directions, it will work headless (i.e. you won't need to use an external keyboard an monitor, you can just ssh in).

Steps:
1. Install stock Raspbian "Bookworm" to an SD card. Make sure to use the options to enable ssh, and to have the local WiFi SSID and pwd burned to the card. Use website [link](https://www.raspberrypi.com/software/), download "Raspberry Pi Imager", and run it. Configure also the hostname and the username/pwd.
2. Insert SD card into Pi, and boot it up. Wait 10 minutes for the initial disk unpacking.
3. Find the IP address from your WiFi router (usually it is something like 192.168.1.xxx, where xxx is from 2 to 256). Or you can try hostname.local.
Try:
 ```
ssh username@hostname.local
```
Or:
 ```
ssh username@192.168.1.xxx
```
6. Within the terminal, get the two files you need:
Get the check if wifi connected script:
 ```
sudo curl -L https://raw.githubusercontent.com/PeterJBurke/RaspberryPiHotspotIfNoWifi/refs/heads/main/check_wifi.sh | sudo tee /usr/local/bin/check_wifi.sh > /dev/null;
sudo chmod +x /usr/local/bin/check_wifi.sh
```
Get the check if wifi connected check service file:
 ```
sudo curl https://raw.githubusercontent.com/PeterJBurke/RaspberryPiHotspotIfNoWifi/refs/heads/main/check_wifi.service > /etc/systemd/system/check_wifi.service
```
   
11. Edit the check_wifi.sh file to enter you SSID name(s). And the name you want for your WiFi hotspot and pwd if no SSID can be connected to. After editing, press control x and click yes to save and exit.
```
sudo nano /usr/local/bin/check_wifi.sh
```
13. Enable the service with
```
sudo systemctl enable check_wifi.service
```
16. Reboot the machine with
```
sudo reboot now
```
18. If you are on your local net, it should work as before.
19. If it creates a hotspot, connect to it with your WiFi on your laptop or smart phone/tablet. Then you can ssh to the default host IP address  as
```
ssh username@10.42.0.1
```

