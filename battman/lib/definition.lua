local dman = require("dman")
local batteryManager = dman.import(
    "battman/functions",
    "battman/commands"
)

batteryManager.primaryInstance = nil

function batteryManager.new()
    local newguy = {}

    -- When this is false the loop will shut down and refuse to start
    newguy.canRun = false
    
    -- If it's running, the thread for the work loop is in here
    newguy.thread = nil

    -- Configuration
    newguy.config = {}
    newguy.configLocation = "/home/battery.config"

    -- We need these so we know which components on our network are for what
    newguy.config.newBatteries = {}
    newguy.config.primaryBatteries = {}
    newguy.config.overflowBatteries = {}
    newguy.config.bat2redstone = {}
    newguy.config.redstone = {}
    newguy.config.newRedstone = {}
    newguy.config.port = 0
    newguy.config.signalStrength = 0

    -- This is used to keep track of changes over time
    newguy.lastPrimaryEnergy = 0

    for name, funcOrVal in pairs(batteryManager)
    do
        newguy[name] = funcOrVal
    end

    newguy:readConfig()
    newguy:detectBatteries()
    newguy:detectRedstone()

    return newguy
end

function batteryManager.newIfDead()
    if(batteryManager.primaryInstance == nil) then
        batteryManager.primaryInstance = batteryManager.new()
    end

    return batteryManager.primaryInstance
end

return batteryManager