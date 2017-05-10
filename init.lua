
-- get all ssids
function listap(t)
    for k,v in pairs(t) do
	local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
        print(k.." : "..rssi)
    end
    aplist = tmr.create()
    aplist:register(5000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
    aplist:start()
end

wifi.setmode(wifi.STATION)
wifi.sta.getap(listap)
