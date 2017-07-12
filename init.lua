
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

function disconnectWifi()
  wifi.sta.disconnect() 
    wifi.sta.clearconfig()
    print("disconnecting")
    --aplist:register(2000, tmr.ALARM_SINGLE, function() 
    --  wifi.sta.getap(listap)
    --end) 
    --aplist:start()
end

function udpRoute()
  ip, nm, gw = wifi.sta.getip()
  print(gw)
  if wifi.sta.getip() == nil then
    print("yes nil")
    disconnect = tmr.create()
    disconnect:register(4000, tmr.ALARM_SINGLE, disconnectWifi) 
    disconnect:start()
  else
    print("not nil")
    udpSocket:send(9969, gw, "hello")
  end
end

-- initialize blinky listener
blinky = tmr.create()
blinky:register(5000, tmr.ALARM_AUTO, toggleLED)
blinky:start()

-- setup wifi and initialize ap listener
wifi.setmode(wifi.STATIONAP)
--wifi.sta.clearconfig()

aplist = tmr.create()
aplist:register(5000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
aplist:start()

station_cfg = {}

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 
  --print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
  --T.BSSID.."\n\tChannel: "..T.channel)
  print("connected!") 

  route = tmr.create()
  route:register(4000, tmr.ALARM_SINGLE, udpRoute) 
  route:start()
     
end)

wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
  wifi.sta.disconnect()
  wifi.sta.autoconnect(0)
  print("AP - STATION CONNECTED")
end)

udpSocket = net.createUDPSocket()
udpSocket:listen(9969)

udpSocket:on("sent", function()
      print("sent")
      disconnect = tmr.create()
      disconnect:register(4000, tmr.ALARM_SINGLE, disconnectWifi) 
      disconnect:start()
end)

cfg =
{
    ip="192.168.5.1",
    netmask="255.255.255.0",
    gateway="192.168.5.1"
}
wifi.ap.setip(cfg)

ap_cfg = {}
ap_cfg.ssid = "ESP_" .. node.chipid()
wifi.ap.config(ap_cfg)

udpSocket:on("receive", function(s, data, port, ip)
    print(string.format("received '%s' from %s:%d", data, ip, port))
    aplist:register(2000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
    aplist:start()
end)
port, ip = udpSocket:getaddr()

print(string.format("local UDP socket address / port: %s:%d", ip, port))
-- main function entry point
--listclients()

