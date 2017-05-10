
-- get all ssids
function listap(t)
    for k,v in pairs(t) do
        print(k.." : "..v)
    end
    aplist = tmr.create()
    aplist:register(5000, tmr.ALARM_SINGLE, function() wifi.sta.getap(listap) end) 
    aplist:start()
end

wifi.setmode(wifi.STATIONAP)
wifi.sta.getap(listap)
