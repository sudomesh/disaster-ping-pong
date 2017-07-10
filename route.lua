
-- toggle LED
function toggleLED() 
  gpio.mode(4, gpio.OUTPUT)
  gpio.write(4, gpio.read(4) == gpio.HIGH and gpio.LOW or gpio.HIGH)
end

-- hold LED high
function holdLED()
  gpio.mode(4, gpio.OUTPUT)
  gpio.write(4, gpio.HIGH)  
end

-- get all ssids
function listap(t)
    blinky:unregister()
    print("scanning?")
    for k,v in pairs(t) do
	if string.find(k, "ESP*") then 
	  local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
          print(k.." : "..rssi)
          station_cfg.ssid = k
          station_cfg.auto=true
          wifi.sta.config(station_cfg)

          signal = -1*rssi < 20 and 20 or -1*rssi
	  blinky:register(signal*signal/2, tmr.ALARM_AUTO, toggleLED)
	  blinky:start()
	--else 
	  --print("no ping, no pong")
        end
    end
    
end

-- get all connected clients
function listclients()
    clientcount = 0
    for mac,ip in pairs(wifi.ap.getclient()) do
       print(mac,ip)
       clientcount = clientcount + 1 -- increment count of clients (future-proofing?)
    end
    if (clientcount > 0) then
      blinky:unregister()
      aplist:unregister()
      blinky:register(5000, tmr.ALARM_AUTO, holdLED)
      -- print("somebody ponged")
    else
      wifi.sta.getap(listap) 
      -- print("nobody ponged") 
    end
    clientlist = tmr.create()
    clientlist:register(5000, tmr.ALARM_SINGLE, function() listclients() end)
    clientlist:start()
end

function udpRoute()
  udpSocket = net.createUDPSocket()
  print(wifi.sta.getip())
  udpSocket:send("9969", "192.168.4.1", "hello")
  udpSocket:on("sent", function()
  disconnect = tmr.create()
  disconnect:register(4000, tmr.ALARM_SINGLE, function() 
    wifi.sta.disconnect() 
    wifi.sta.clearconfig()
    print("disconnecting")
    aplist:register(2000, tmr.ALARM_SINGLE, function() 
      wifi.sta.getap(listap) end) 
    aplist:start()
    end) 
  disconnect:start()
  end)

end

-- initialize blinky listener
blinky = tmr.create()
blinky:register(5000, tmr.ALARM_AUTO, toggleLED)
blinky:start()

-- setup wifi and initialize ap listener
wifi.setmode(wifi.STATIONAP)
wifi.sta.clearconfig()
station_cfg = {}

aplist = tmr.create()
aplist:register(5000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
aplist:start()

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 
     --print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
     --T.BSSID.."\n\tChannel: "..T.channel)
 
     -- set up connection to MQTT broker 5s from now (to allow time to get IP)
     route = tmr.create()
     route:register(4000, tmr.ALARM_SINGLE, udpRoute) 
     route:start()

     
   end)

--[[
ap_cfg = {}
ap_cfg.ssid = "ESP_" .. node.chipid()
wifi.ap.config(ap_cfg)
--]]

--[[udpSocket:listen(9969)
udpSocket:on("receive", function(s, data, port, ip)
    print(string.format("received '%s' from %s:%d", data, ip, port))
    s:send(port, ip, "echo: " .. data)
end)
port, ip = udpSocket:getaddr()
--]]


--print(string.format("local UDP socket address / port: %s:%d", ip, port))

-- main function entry point
--listclients()

