local thread = require("thread")
local component = require("component")
local se = require("serialization")
local shell = require("shell")

local batteryManager = {}

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

    return newguy
end

function batteryManager.start(self)
    self:readConfig()
    self:detectBatteries()

    self.canRun = true

    local worker = thread.create(
        function()
            print("Starting daemon")
            while(self.canRun)
            do
                print("Daemon tick")
                xpcall(
                    function()
                        self:loop()
                    end, 
                    function(err)
                        self:handleError(err)
                    end
                )
                os.sleep(5)
            end
        end
    )
    worker:detach()
end

function batteryManager.loop(self)
    local lowestPrimary
    local combinedPrimary = 0

    for address, bool in pairs(self.config.primaryBatteries)
    do
        local battery = component.proxy(address)
        if(battery == nil) then
            self.config.primaryBatteries[address] = nil
        end

        local energy = battery:getStoredEnergy()

        if(energy == 0) then
            -- panic
        end

        if((lowestPrimary == nil) or (lowestPrimary > energy)) then
            lowestPrimary = energy
        end

        combinedPrimary = combinedPrimary + energy
    end

    self.lastPrimaryEnergy = combinedPrimary

    for address, bool in pairs(self.config.overflowBatteries)
    do
        local battery = component.proxy(address)
        if(battery == nil) then
            self.config.overflowBatteries[address] = nil
        end

        local energy = battery:getStoredEnergy()

        if(energy < lowestPrimary) then
            print("Shut off " .. address)
            -- shut off
        else
            print("Turn on " .. address)
            -- turn on
        end
    end
end

function batteryManager.detectBatteries(self)
    for address, type in pairs(component.list("battery", true))
    do
        if((self.config.primaryBatteries[address] == nil) and (self.config.overflowBatteries[address] == nil)) then
            self.config.newBatteries[address] = true
        end
    end
end

function batteryManager.removeBattery(self, address)
    self.config.newBatteries[address] = nil
    self.config.overflowBatteries[address] = nil
    self.config.primaryBatteries[address] = nil
end

function batteryManager.addPrimary(self, address)
    print("Adding primary")
    self:removeBattery(address)
    self.config.primaryBatteries[address] = true
end

function batteryManager.addOverflow(self, address)
    print("Adding secondary")
    self:removeBattery(address)
    self.config.overflowBatteries[address] = true
end

function batteryManager.readConfig(self)
    local configFile = io.open(self.configLocation, "r")
    
    if(configFile == nil) then
        return
    end

    self.config = se.unserialize(configFile:read("*all"))
    configFile:close()
end

function batteryManager.writeConfig(self)
    local configFile = io.open(self.configLocation, "w")

    configFile:write(se.serialize(self.config))
    configfile:flush()
    configFile:close()
end

function batteryManager.handleError(self, err)
    errorCount = errorCount + 1
    if(errorCount >= 10) then -- This means it threw an error 10 times in a row
        self.canRun = false
    end
    print("ERROR:", err)
end

-- Called by command line to view configuration/etc
function batteryManager.view(self, args, options)
    local all = "all"
    local new = "new"
    local primary = "primary"
    local overflow = "overflow"
    local redstone = "redstone"

    local category
    if(#args <= 1) then
        category = all
    else
        category = args[2]
    end

    if((category == all) or (category == new)) then
        print("Uncategorized/New batteries")
        for address, bool in pairs(self.config.newBatteries)
        do
            print(address)
        end
        print("-----")
    end
    if((category == all) or (category == primary)) then
        print("Primary batteries")
        for address, bool in pairs(self.config.primaryBatteries)
        do
            print(address)
        end
        print("-----")
    end
    if((category == all) or (category == overflow)) then
        print("Overflow batteries")
        for address, bool in pairs(self.config.overflowBatteries)
        do
            print(address)
        end
        print("-----")
    end
    if((category == all) or (category == redstone)) then
        print("Redstone IO controllers")
        for address, bool in pairs(self.config.redstone)
        do
            print(address)
        end
        print("-----")
    end
end

function batteryManager.newIfDead()
    if(batteryManager.primaryInstance == nil) then
        batteryManager.primaryInstance = batteryManager.new()
    end

    return batteryManager.primaryInstance
end

-- Called by command line to configure the manager
function batteryManager.set(self, args, options)
end

-- Called by command line to start the manager
function batteryManager.start(self, args, options)
end

-- Called by command line to stop the manager
function batteryManager.stop(self, args, options)
end

-- Called by command line to debug the code
function batteryManager.test(self, args, options)
    print("Creating a new battery manager")
    local manager = batteryManager.new()
    print("Starting the battery manager")
    manager:start()
    os.sleep()
    for address, bool in pairs(manager.config.newBatteries)
    do
        local battery = component.proxy(address)
        local x, y, z = battery:getCoords()
        if(z < 1022) then
            manager:addOverflow(address)
        else
            manager:addPrimary(address)
        end
    end
    print("Waiting 10 seconds for the battery manager to run for a while...")
    os.sleep(10)
    print("The last total amount of energy in the primary batteries was: " .. manager.lastPrimaryEnergy)
    print("Shutting down")
    manager.canRun = false
end

local args, options = shell.parse(...)

if(#args == 0) then
    print("Usage: battman <action>")
    
    print("battman view <new|primary|overflow|redstone|all>")
    print("Displays all of the specified devices.")
    
    print("battman set <new|primary|overflow|redstone> <battery address> [side]")
    print("Sets the device at the address to the specified category. Redstone IO requires a side.")

    print("battman start")
    print("Starts up the manager")
    return
end

local actions = {}
actions["view"] = batteryManager.view
actions["set"] = batteryManager.set
actions["start"] = batteryManager.start
actions["stop"] = batteryManager.stop
actions["test"] = batteryManager.test

local action = string.lower(args[1])
actions[action](batteryManager.newIfDead(), args, options)