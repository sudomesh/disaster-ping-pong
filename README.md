# disaster-ping-pong
helps locate friendly ssids  
Specifically, this repository uses an ESP8266 wifi microcontroller to detect the signal strength of a certain, pre-determined SSID.
It does this by filtering avaible SSIDs for the desired SSID, then finding the RSSI (signal strength) associated with that SSID.
The ESP8266 will then blink an LED based on the RSSI value it detects.  
However, if a client connects to your ESP8266's access point, it with stop blinking the LED and leave it on constantly.  
In its most exicting implementation, two ESP8266 can be flashed with this firmware and be made to detect one another's presence.  

# prerequisites 
* an ESP8266 (preferably on a dev board)  
* an LED to blink (preferably already on the dev board)  
* NodeMCU firmware (located in the firmware directory)  
* esptool.py (pip install esptool)  
* nodemcu-uploader (sudo pip install nodemcu-uploader)  

# steps 
Flash the NodeMCU firmware contained within the firmware directory, or build your own at https://nodemcu-build.com.
The lua script used in this implementation only requires the most basic packages (gpio and wifi), so it should work with
almost any firmware build. To flash, follow the guide at https://github.com/sudomesh/disaster-radio-nodemcu/wiki#flashing-nodemcu.   

To upload and begin running the lua script, run the following 
```
./upload.sh
```
It may be necesary to reset your esp8266 after uploading the lua script. To do thise, press the screen button or unplug the board from
your computer and plug it back in.  

Expected outcome is that the blue LED blink frequency will increase when it gets close to another esp8266   

By default, this script looks for an SSID starting with "ESP_". This was chosen since the NodeMCU firmware defaults
to an SSID formatted something like "ESP_12BD5". So it is just looking for a friend, another ESP. This could be easily 
modified in the script to look for SSID of your choosing, say "DisasterRadio*" or "peoplesopen.net".  

Note, this firmware and lua script have only been tested with an ESP-12F on a WeMos D1 mini development board.
There are countless other dev board and ESP chip combinations out there, for more information regarding tested boards
refer to our wiki, https://github.com/sudomesh/disaster-radio-nodemcu/wiki. 

