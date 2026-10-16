local B47ANCEDPower=require "B47ANCEDPower/API"
local EventsAPI=B47ANCEDPower.InfrastructureEvents or require "B47ANCEDPower/InfrastructureEvents"
local function initialize()
    if ModData and ModData.getOrCreate then
        local ok,err=EventsAPI.attachStore(ModData.getOrCreate(EventsAPI.STORE_KEY))
        if not ok and print then print("[B47ANCE'd Power] Infrastructure event store unavailable: "..tostring(err))end
    end
end
local function catchUp()
    local ok,value=EventsAPI.catchUpWeather()
    if not ok and print then print("[B47ANCE'd Power] Weather event catch-up failed safely: "..tostring(value))end
end
if Events and Events.OnInitGlobalModData then Events.OnInitGlobalModData.Add(initialize)end
if Events and Events.OnGameStart then Events.OnGameStart.Add(catchUp)end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(catchUp)end
return EventsAPI
