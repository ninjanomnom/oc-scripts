local batteryManager = require("battman/BatteryManagerFunctions")

batteryManager.primaryInstance = nil

function batteryManager.new()
    local newguy = {}

    -- When this is false the loop will shut down and refuse to start
    newguy.canRun = false

    -- Configuration
    newguy.config = {}
    newguy.configLocation = "/home/battery.config"

    -- We need these so we know which components on our network are for what
    newguy.config.newBatteries = {}
    newguy.config.primaryBatteries = {}
    newguy.config.overflowBatteries = {}
    newguy.config.redstone = {}

    -- This is used to keep track of changes over time
    newguy.lastPrimaryEnergy = 0

    -- Finally starting the beast
    newguy.start = batteryManager.start
    newguy.loop = batteryManager.loop

    -- Config loading
    newguy.readConfig = batteryManager.readConfig
    newguy.writeConfig = batteryManager.writeConfig

    -- These are for command line mostly, feel free to use them if you want though
    newguy.view = batteryManager.view
    newguy.set = batteryManager.set
    newguy.start = batteryManager.start
    newguy.stop = batteryManager.stop
    
    -- Battery registration
    newguy.detectBatteries = batteryManager.detectBatteries
    newguy.removeBattery = batteryManager.removeBattery
    newguy.addPrimary = batteryManager.addPrimary
    newguy.addOverflow = batteryManager.addOverflow

    -- Error handling
    newguy.errorCount = 0
    newguy.handleError = batteryManager.handleError

    newguy:readConfig()

    return newguy
end

function batteryManager.newIfDead()
    if(batteryManager.primaryInstance == nil) then
        batteryManager.primaryInstance = batteryManager.new()
    end

    return batteryManager.primaryInstance
end

return batteryManager