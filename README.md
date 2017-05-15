# disaster-ping-pong
helps locate friendly ssids
Specifically, this repository uses an ESP8266 wifi microcontroller to detect the signal strength of a certain, pre-determined SSID.
It does this by filtering avaible SSIDs for the desired SSID, then finding the RSSI (signal strength) associated with that SSID.
The ESP8266 will then blink an LED based on the RSSI value it detects.  

In its most exicting implementation, two ESP8266 can be flashed with this firmware and be made to detect one another's presence.  

# pre-requistes  
* an ESP8266 (preferably on a dev board)  
* an LED to blink (preferably already on the dev board)  
* NodeMCU firmware (located in the firmware directory)  
* esptool.py (pip install esptool)  
* nodemcu-uploader (sudo apt-get install uploader)  
