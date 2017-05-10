
-- toggle LED
function toggleLED() 
  gpio.mode(4, gpio.OUTPUT)
  gpio.write(4, gpio.read(4) == gpio.HIGH and gpio.LOW or gpio.HIGH)
end

-- get all ssids
function listap(t)
    for k,v in pairs(t) do
	if string.find(k, "ESP.*") then 
	  local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
          print(k.." : "..rssi)
	  blinky = tmr.create()
	  blinky:register(20*rssi*rssi / rssi, tmr.ALARM_SINGLE, toggleLED)
	  tmr.start()
	else 
	  print("no ping, no pong")
        end
    end
    aplist = tmr.create()
    aplist:register(5000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
    aplist:start()
end

wifi.setmode(wifi.STATIONAP)
wifi.sta.getap(listap)
