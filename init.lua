
-- toggle LED
function toggleLED() 
  gpio.mode(4, gpio.OUTPUT)
  gpio.write(4, gpio.read(4) == gpio.HIGH and gpio.LOW or gpio.HIGH)
end

-- get all ssids
function listap(t)
    blinky:unregister()
    for k,v in pairs(t) do
	if string.find(k, "ESP.*") then 
	  local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
          print(k.." : "..rssi)
          signal = -1*rssi < 20 and 20 or -1*rssi
	  blinky:register(signal*signal/2, tmr.ALARM_AUTO, toggleLED)
	  blinky:start()
	--else 
	  --print("no ping, no pong")
        end
    end
    aplist = tmr.create()
    aplist:register(5000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
    aplist:start()
end


blinky = tmr.create()
blinky:register(5000, tmr.ALARM_AUTO, toggleLED)
blinky:start()

wifi.setmode(wifi.STATIONAP)
wifi.sta.getap(listap)
