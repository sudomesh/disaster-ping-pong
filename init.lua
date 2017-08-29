-- toggle LED
--[[function toggleLED() 
  gpio.mode(4, gpio.OUTPUT)
  gpio.write(4, gpio.read(4) == gpio.HIGH and gpio.LOW or gpio.HIGH)
end

-- hold LED high
function holdLED()
  gpio.mode(4, gpio.OUTPUT)
  gpio.write(4, gpio.HIGH)  
end
--]]

--SCANNING STATE 
function startscan()

    wifi.setmode(wifi.STATIONAP)

    -- unregister callbacks
    udpSocket:on("sent", function() end)
    udpSocket:on("receive", function() end)
    wifi.eventmon.unregister(wifi.eventmon.STA_CONNECTED) 
    wifi.eventmon.unregister(wifi.eventmon.AP_STACONNECTED) 

    -- re-register callbacks
    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
        print("connected to " .. T.SSID) 
        routingStates:Change("transmitting")
    end)
    wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
        wifi.sta.disconnect()
        wifi.sta.autoconnect(0)
        print("I'M AN AP - STATION CONNECTED")
        routingStates:Change("receiveTransmit")
    end)

    -- enter scanning loop
    scan:register(2000, tmr.ALARM_SINGLE,  function() wifi.sta.getap(listAPs) end)
    scan:start()

end

function listAPs(t)

    --SSIDtable = wifi.sta.getap()
    --if has_index(t, "ESP*") then
      -- local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
      -- print(k.." : "..rssi) TODO generalize has_index to return values

    print("scanning?")
    for k, v in pairs(has_index(t, "ESP*")) do
        if has_value(routes, k) then
            print("already found") 
            for i,j in pairs(routes) do
                print(i)
            end
            print("look for someone else")
            scan:register("2000", tmr.ALARM_SINGLE, function() wifi.sta.getap(listAPs) end)
            scan:start()
        else
            stationconnect(k)
            --signal = -1*rssi < 20 and 20 or -1*rssi
            --blinky:register(signal*signal/2, tmr.ALARM_AUTO, toggleLED)
            --blinky:start()
        end
    end
end

function stationconnect(AP)
    print("trying to connect to ".. AP)
    sta_cfg.ssid = AP 
    sta_cfg.auto = true
    wifi.sta.config(sta_cfg)

end

function stopscan()
    scan:unregister()
    -- unregister callbacks
    wifi.eventmon.unregister(wifi.eventmon.STA_CONNECTED)
    wifi.eventmon.unregister(wifi.eventmon.AP_STACONNECTED)

end
--END SCANNING STATE

--TRANSMIT STATE
function setupTransmit()

    wifi.setmode(wifi.STATION)

    -- register callback
    udpSocket:on("sent", function()
        print("sent hello")
        --state_counter = state_counter + 1
        stateswitch:register(2000, tmr.ALARM_SINGLE, function() routingStates:Change("receiveResponse") end)
        stateswitch:start()
    end)

    if wifi.sta.getip() == nil then
        route:register(2000, tmr.ALARM_SINGLE, setupTransmit) 
        route:start() -- TODO add retry timeout

    else -- enter routing
        print("trying to route")
        route:register(2000, tmr.ALARM_SINGLE, udpTransmit) 
        route:start()
    end 

end

function stopTransmit()

    -- unregister callback    
    udpSocket:on("sent", function() end)
    route:unregister()
    wifi.sta.disconnect()

end
-- END TRANSMIT STATE

-- RECEIVE TRANMISSION STATE
function setupReceiveT()

    wifi.setmode(wifi.SOFTAP)

    udpSocket:on("receive", function(s, data, port, ip)
        print(string.format("hello from %s on %s:%d", data, ip, port))

        routes[data] = 1

        -- THIS IS A REALLY TERRIBLE WAY OF DOING THIS
        wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
            print("connected!") 
            response = tmr.create()
            response:register(4000, tmr.ALARM_SINGLE, udpResponse) 
            response:start()
        end)
        stationconnect(data)
        -- TODO MOVE THIS CALLBACK AND CONNECT TO RESPONSE STATE

        routingStates:Change("responding") 
    end)

    print("waiting for hello")

end

function udpTransmit() --generalize for both init and response

    ip, nm, gw = wifi.sta.getip()
    print("sending my SSID, ".. SSID .. ", to " .. gw)
    udpSocket:send(UDPport, gw, SSID)

end

function stopReceiveT()

    --unregister callback
    udpSocket:on("receive", function() end)

end
-- END RECEIVE TRANSMISSION STATE

-- RESPOND STATE
function setupResponse()

    -- set udp callback
    if state_counter == 0 then
        udpSocket:on("sent", function()
            print("sent ihu")
            state_counter = 1
            routingStates:Change("transmitting")
        end)
    else
        udpSocket:on("sent", function()
            print("sent ihu")
            state_counter = 0
            wifi.sta.autoconnect(0)
            wifi.sta.disconnect()
            routingStates:Change("scanning")
        end)
    end


end

function udpResponse()

  ip, nm, gw = wifi.sta.getip()
  if wifi.sta.getip() == nil then
    return udpResponse  -- TODO add retry counter
  else
    udpSocket:send(UDPport, gw, "ihu") --.. ap_cfg.ssid)
  end

end

function stopResponse()

    udpSocket:on("sent", function() end)

end
-- END RESPOND STATE

-- RECEIVE RESPONSE STATE
function setupReceiveR()

    -- register callbacks
    -- number of states passed through
    if state_counter == 0 then
        -- response is required
        udpSocket:on("receive", function(s, data, port, ip)
            print(string.format("%s from %s:%d", data, ip, port))
            state_counter = 1
            routingStates:Change("receiveTransmit")
        end)
    else
        udpSocket:on("receive", function(s, data, port, ip)
            print(string.format("%s from %s:%d", data, ip, port))
            state_counter = 0
            wifi.sta.autoconnect(0)
            wifi.sta.disconnect()
            routingStates:Change("scanning")
        end)
    end

    print("waiting for response")

end

function stopReceiveR()

    --unregister callback
    udpSocket:on("receive", function() end)

end
-- END RECEIVE RESPONSE STATE


-- UTILTY FUNCTIONS
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

function random_seed()

    mac = wifi.sta.getmac()
    mac = mac:gsub(":", "")
    -- only use last 7 chars so we don't overflow the int
    mac = "0x"..mac:sub(6)
    mac = tonumber(mac)
    math.randomseed(mac)

end
-- END UTILTY FUNCTIONS


function setup()

    wifi.setmode(wifi.STATIONAP)
    ip_cfg = {}
    sta_cfg = {}
    ap_cfg = {}

    node_ip = "192.168.".. math.random(1, 254) ..".1"
    ip_cfg =
    {
        ip = node_ip,
        netmask = "255.255.255.0",
        gateway = node_ip 
    }
    wifi.ap.setip(ip_cfg)

    ap_cfg.ssid = SSID 
    ap_cfg.max = 1
    wifi.ap.config(ap_cfg)


    sta_cfg.ssid = "ESP" 
    sta_cfg.auto = false 
    sta_cfg.save = false 
    wifi.sta.config(sta_cfg)

    udpSocket = net.createUDPSocket()
    udpSocket:listen(UDPport)
    port, ip = udpSocket:getaddr()

    print(string.format("%s local UDP socket address / port: %s:%d", SSID, node_ip, port))

end

UDPport = 9969
SSID = "ESP_" .. node.chipid()
routes = {}  

-- initialize but don't start timers
--blinky = tmr.create()
--aplist = tmr.create()
scan = tmr.create()
route = tmr.create()
--disconnect = tmr.create()
stateloop = tmr.create()
stateswitch = tmr.create()

stateMachine = {}
stateMachine.__index = stateMachine
function stateMachine:Create()
    local this =
    {
        mEmpty =  -- template for creating new states
        {
            HandleInput = function() end,
            Update = function() end,
            Enter = function() end,
            Exit = function() end
        },
        mCurrent = nil,
        mStates = {}
    }
    this.mCurrent = this.mEmpty
    setmetatable(this, self)
    return this
end

function stateMachine:Change(stateName) --TODO pass paramaters between states
    assert(self.mStates[stateName]) -- state must exist!
    self.mCurrent:Exit()
    self.mCurrent = self.mStates[stateName]
    stateswitch:register(1000, tmr.ALARM_SINGLE, function() self.mCurrent:Enter() end)
    stateswitch:start()
end

function stateMachine:Update() -- could also handle data transfer between updates 
    self.mCurrent:Update()
end

function stateMachine:Add(id, state)
    self.mStates[id] = state
end

function stateMachine:Remove(id)

    if self.mCurrent == self.mStates[id] then
        self.mCurrent = self.mEmpty
    end

    self.mStates[id] = nil
end

function stateMachine:Clear()
    self.mStates = {}
    self.mCurrent = self.mEmpty
end

routingStates = stateMachine:Create()

scanning = {
            HandleInput = function() end,
            Update = function() end,
            Enter = startscan,
            Exit = stopscan 
           }

transmitting = {
             HandleInput = function() end,
             Update = function() end,
             Enter = setupTransmit,
             Exit = stopTransmit 
            }

receiveTransmit = {
            HandleInput = function() end,
            Update = function() end,
            Enter = setupReceiveT,
            Exit = stopReceiveT 
           }

responding = {
             HandleInput = function() end,
             Update = function() end,
             Enter = setupResponse,
             Exit = stopResponse 
            }

receiveResponse = {
            HandleInput = function() end,
            Update = function() end,
            Enter = setupReceiveR,
            Exit = stopReceiveR 
           }

--function TransitionStates(new_state)

--end

--[[states = {
    SCAN = "scanning"
    TRANSMIT = "transmitting"
    RECEIVE_T = "receiving transmission"
    RESPOND = "responding"
    RECEIVE_R = "receiving response"
}--]]

-- should probably add timers in state transistions

routingStates:Add("scanning", scanning)
routingStates:Add("transmitting", transmitting)
routingStates:Add("receiveTransmit", receiveTransmit)
routingStates:Add("responding", responding)
routingStates:Add("receiveResponse", receiveResponse)

state_counter = 0 --once equals 4 (ie completed routing) return to scanning state

random_seed()
setup()
routingStates:Change("scanning")
