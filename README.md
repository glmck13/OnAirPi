# OnAirPi
Project to create a streaming Internet Radio service using a portable Pi microphone, an AWS-hosted IceCast server, and an Alexa Skills App  
<img src=https://github.com/glmck13/OnAirPi/blob/master/docs/OnAirPi90.jpg height=250>
<img src=https://github.com/glmck13/OnAirPi/blob/master/docs/AlexaSkill.png width=250>  

## Parts List
Description | Amazon DP# | Price
--- | --- | ---
| Lithium Battery Pack & Expansion Board | [B06W9LRGRS](https://www.amazon.com/dp/B06W9LRGRS) | 17.99
| GPIO 1x3 Expansion Board | [B06WWRZ7PS](https://www.amazon.com/dp/B06WWRZ7PS) | $8.99
| IR Infrared Transceiver Expansion Board & Remote Control | [B076BDR34K](https://www.amazon.com/dp/B076BDR34K) | $10.99
| Traffic Light | [B00RIIGD30](https://www.amazon.com/dp/B00RIIGD30) | $11.99
| USB Conference Microphone | [B076ZVZWC4](https://www.amazon.com/dp/B076ZVZWC4) | $59.99  

## Pi Microphone
First, assemble the various components you purchased.  Mount your Pi on the battery stand, install the GPIO expansion board, insert the IR board on the middle set of pins, and the traffic light on BCM_GPIO pins 2..6 (alternatively labeled as SDA1, SCL1, P04, & GND on the header).  Insert the USB microphone into one of the Pi's USB slots.

Next, install & configure software on the Pi. I'm running Raspbian stretch, with the following set of packages:  
 - apache2 & gridsite-clients (to host a Wifi config page)
 - lirc version 0.9.4c-9 (to process IR controls)
 - sox & libsox-fmt-mp3 (to capture/record audio)
 - ezstream (to stream audio to IceCast server)  

Follow the instructions provided under my "MyVitals" wiki to configure the Apache web server.  As regards configuring lirc, follow the instructions for the Raspian *stretch* release provided here: http://shallowsky.com/blog/hardware/raspberry-pi-ir-remote-stretch.html.  The osoyoo.conf file in the repository contains codes for the remote control supplied with IR header.  Drop this file into /etc/lirc/lircd.conf.d.  The repository also contains codes for a "nooelec" remote, which is the one I'm currently using, and is depicted in the figure above.  

Next mkdir ~pi/bin, and drop radioClient.sh under that directory.  In order to start the utility on reboot, add the following line to the pi user's crontab:
```
@reboot /home/pi/bin/radioClient.sh
```
Lastly, copy client-index.cgi to /var/www/html/index.cgi.  The page provides a primitive interface for adding/deleting WiFi networks on the Pi when it's running headless:  
<img src=https://github.com/glmck13/OnAirPi/blob/master/docs/wifisetup.png>  
So how is this page accessed if the Pi is headless and it's not connected to any network?  In my case, I enable the hotspot on my iPhone, and tether the iPhone directly to the Pi using one of the Pi's USB ports.  In this configuration, the Pi is assigned address 172.20.10.4, and you can navigate directly to that address using Safari.  If for some reason the Pi fails to connect to the iPhone, follow the "iPhone tethering" instructions listed under https://github.com/glmck13/MobilePi/blob/master/client-config/README.md (you van omit the hotplug entry in /etc/network/interfaces, since we won't be turning up an IPsec tunnel).  And lastly, make sure to add user pi to the www-data & netdev groups:
```
usermod -a -G www-data pi
usermod -a -G netdev pi
```

## Icasecast Server
## Alexa App
## Station Web App
