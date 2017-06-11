# Build Your Own Diaster Ping-Pong! (BYODPP)

The Disaster Ping-Pong device is an intro kit for Disaster Radio Foundation's flagship project, Disaster Radio. 
By following this guide you will learn the basic concepts being used in the development of the Disaster Radio while also providing a physical demonstration ad-hoc mesh networks. 
But first, you will need to gather the necessary ingredients.

## Ingredients

* A friend to ping-pong with!
* A linux (or mac?) computer
* ESP8266 on a dev board (pictured)
* A micro USB cable (usually any phone charger cord will do)
* GPIO pin headers (if not already on dev board)
* Solder, soldering iron, and basic soldering skills
* AA or AAA ~5V battery holder, preferably with ON/OFF switch and wires already attached
* Three of the corresponding batteries

## Recipe 

After gathering the ingredients, you can start cooking up your own Disaster Ping-Pong.
1. First you will want to make sure your ESP8266 works properly, to do this, follow our guide located at 
2. Once you have verified that your ESP8266 operates properly, you can flash the NodeMCU firmware and upload the Disaster Ping-Pong script located at
3. If you don't have a friend with a second ESP8266, you can modify the code to look for your home Wifi, to do this open the init.lua file in a text editor and change the line that reads:  
```
if string.find(k, "ESP*") then
```  
replacing ```ESP*``` with the name of your home WiFi (or any WiFi netowrk you want to look for)
4. Once you have completed the Disaster Ping-Pong setup guide, try testing it by holding it closer (while it is still connected to your computer) to another ESP8266 also setup for Disaster Ping-Pong or an access point for the WiFi network you specified in step 3 (most likely, this will be your home wireless router)
5. Now you can make it portable by attaching the batteries! You may want to first test that the battery holder you bought works before soldering it directly to your ESP8266.
6. If your development board does not have pins sticking out of it, you may want to solder on header pins in case you get curious and want to play around with the other pins later.
7. Solder the red wire from your battery holder to the pin labeled 5V or Vin on the ESP8266 dev board and solder the black wire to the pin labeled G or GND on the ESP8266 dev board.
8. Insert three battries to the battery holder with the ON/OFF switch set to OFF.
9. Turn ON your battery holder, the ESP8266 should flash once and then begin operating just like it was connected to your computer.
10. Congratulations! You just built your first MESH NETWORK. This is just the beginning of Building your own Internet. Help build a bigger, better MESH by joining the Peoples Open Network!
