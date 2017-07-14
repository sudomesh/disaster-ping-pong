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
    --if has_index(t, "ESP*") then
      --local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
      -- print(k.." : "..rssi) TODO generalize has_index to return values
      for k, v in pairs(has_index(t, "ESP*")) do
        if has_value(routes, k) then
          print("already found, look for someone else") 
          print(routes)
        else
          wifi.eventmon.unregister(wifi.eventmon.STA_CONNECTED) 
          stationconnect()
          station_cfg.ssid = k
          station_cfg.auto=true
          wifi.sta.config(station_cfg)
          routes[k] = 1
          return 1 
        --signal = -1*rssi < 20 and 20 or -1*rssi
        --blinky:register(signal*signal/2, tmr.ALARM_AUTO, toggleLED)
        --blinky:start()
        end
      end
      return 0
end

function has_index (tab, val)
  match_tab = {}
  for index, value in pairs(tab) do
    if string.find(index, val) then
      match_tab[index] = 1
    end
  end
  return match_tab 
end

function has_value (tab, val)
  for index, value in pairs(tab) do
    if string.find(index, val) then
      return true
    end
  end
  return false
end

function iheardyou(ap)
  wifi.eventmon.unregister(wifi.eventmon.STA_CONNECTED) 
  responseconnect()
  --routes[ap] = 1
  station_cfg.ssid = ap
  station_cfg.auto=true
  wifi.sta.config(station_cfg)
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
  aplist:register(2000, tmr.ALARM_SINGLE, function() 
    wifi.sta.getap(listap)
  end) 
  aplist:start()
end

function udpRoute()
  ip, nm, gw = wifi.sta.getip()
  -- print(gw)
  if wifi.sta.getip() == nil then
    disconnect = tmr.create()
    disconnect:register(4000, tmr.ALARM_SINGLE, disconnectWifi) 
    disconnect:start()
  else
    udpSocket:send(9969, gw, ap_cfg.ssid)
  end
end

function udpResponse()
  ip, nm, gw = wifi.sta.getip()
  -- print(gw)
  if wifi.sta.getip() == nil then
    disconnect = tmr.create()
    disconnect:register(4000, tmr.ALARM_SINGLE, disconnectWifi) 
    disconnect:start()
  else
    udpSocket:send(9969, gw, "ifhy") --.. ap_cfg.ssid)
  end
end

function random_seed()
  mac = wifi.sta.getmac()
  mac = mac:gsub(":", "")
   -- only use last 7 chars so we don't overflow the int
  mac = "0x"..mac:sub(6)
  mac = tonumber(mac)
  math.randomseed(mac)
end

random_seed()

routes = {}  -- initialize routing table 
-- count = 0

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


function stationconnect()
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 
    print("connected!") 
    route = tmr.create()
    route:register(4000, tmr.ALARM_SINGLE, udpRoute) 
    route:start()
     
  end)
end
 
function responseconnect()
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 
    print("connected!") 
    response = tmr.create()
    response:register(4000, tmr.ALARM_SINGLE, udpResponse) 
    response:start()
     
  end)
end

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
      disconnect:register(2000, tmr.ALARM_SINGLE, disconnectWifi) 
      disconnect:start()
end)

node_ip = "192.168.".. math.random(1, 254) ..".1"

cfg =
{
    ip = node_ip,
    netmask = "255.255.255.0",
    gateway = node_ip 
}
wifi.ap.setip(cfg)

ap_cfg = {}
ap_cfg.ssid = "ESP_" .. node.chipid()
wifi.ap.config(ap_cfg)

udpSocket:on("receive", function(s, data, port, ip)
    if data == "ifhy" then
      print(string.format("%s on %s:%d", data, ip, port))
      aplist:register(2000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
      aplist:start()

    else
      print(string.format("hello from %s on %s:%d", data, ip, port))
      received = tmr.create()
      received:register(2000, tmr.ALARM_SINGLE, function() iheardyou(data) end) 
      received:start()
    end
end)

port, ip = udpSocket:getaddr()

print(string.format("local UDP socket address / port: %s:%d", node_ip, port))
-- main function entry point
--listclients()

