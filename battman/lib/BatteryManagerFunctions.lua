local thread = require("thread")
local component = require("component")
local se = require("serialization")

batteryManager = {}

function batteryManager.start(self)
    self:detectBatteries()

    self.canRun = true

    local worker = thread.create(
        function()
            print("Starting daemon")
            while(self.canRun)
            do
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
            -- shut off
        else
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
    self.config.redstone[address] = nil
end

function batteryManager.addPrimary(self, address)
    self:removeBattery(address)
    self.config.primaryBatteries[address] = true
end

function batteryManager.addOverflow(self, address)
    self:removeBattery(address)
    self.config.overflowBatteries[address] = true
end

function batteryManager.addRedstone(self, batteryAddress, dir, redstoneAddress)
    if(self.config.primaryBatteries[batteryAddress] == nil) then
        return false
    end
    if(self.config.overflowBatteries[batteryAddress] == nil) then
        return false
    end

    self.config.redstone = self.config.redstone or {}
    self.config.redstone[batteryAddress] = {}
    self.config.redstone[batteryAddress].address = redstoneAddress
    self.config.redstone[batteryAddress].dir = dir
    return true
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
    io.close(configFile)
end

function batteryManager.handleError(self, err)
    errorCount = errorCount + 1
    if(errorCount >= 10) then -- This means it threw an error 10 times in a row
        self.canRun = false
    end
    print("ERROR:", err)
end

-- Called by command line to view configuration/etc
function batteryManager.cmdView(self, args, options)
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
            local entity = component.proxy(address)
            print(address, type(entity.getBlock()))
        end
        print("-----")
    end
    if((category == all) or (category == primary)) then
        print("Primary batteries")
        for address, bool in pairs(self.config.primaryBatteries)
        do
            local entity = component.proxy(address)
            print(address, type(entity.getBlock()))
        end
        print("-----")
    end
    if((category == all) or (category == overflow)) then
        print("Overflow batteries")
        for address, bool in pairs(self.config.overflowBatteries)
        do
            local entity = component.proxy(address)
            print(address, type(entity.getBlock()))
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

-- Called by command line to configure the manager
function batteryManager.cmdSet(self, args, options)
    if(#args <= 2) then
        print("You must specify what to set")
        return
    end

    local actions = {}
    actions["primary"] = self.setPrimary
    actions["overflow"] = self.setOverflow
    actions["redstone"] = self.setRedstone

    local action = string.lower(args[2])
    actions[action](self, args, options)
end

function batteryManager.setPrimary(self, args, options)
    if(#args < 3) then
        print("You must specify what to set")
        return
    end

    local address = component.get(args[3])
    if(address == nil) then
        print("The address given could not be found")
        return
    end

    local entity = component.proxy(address)
    if(entity == nil) then
        print("The address given could not be found")
        return
    end

    if(entity.type ~= "battery") then
        print("The address given was not for a battery")
        return
    end

    self:addPrimary(address)
    self:writeConfig()
end

function batteryManager.setOverflow(self, args, options)
    if(#args < 3) then
        print("You must specify what to set")
        return
    end

    local address = component.get(args[3])
    if(address == nil) then
        print("The address given could not be found")
        return
    end

    local entity = component.proxy(address)
    if(entity == nil) then
        print("The address given could not be found")
        return
    end

    if(entity.type ~= "battery") then
        print("The address given was not for a battery")
        return
    end

    self:addOverflow(address)
    self:writeConfig()
end

function batteryManager.setRedstone(self, args, options)
    if(#args < 5) then
        print("You must specify what to set and in what direction the battery is and what battery it is")
        return
    end

    local redstoneAddress = component.get(args[3])
    if(redstoneAddress == nil) then
        print("The redstone address given could not be found")
        return
    end

    local entity = component.proxy(redstoneAddress)
    if(entity == nil) then
        print("The redstone address given could not be found")
        return
    end

    if(entity.type ~= "redstone") then
        print("The redstone address given was not for a redstone IO")
        return
    end

    local dir = args[4]

    local batteryAddress = component.get(args[5])
    if(batteryAddress == nil) then
        print("The battery address given could not be found")
        return
    end

    local entity = component.proxy(batteryAddress)
    if(entity == nil) then
        print("The battery address given could not be found")
        return
    end

    if(entity.type ~= "battery") then
        print("The battery address given was not for a battery")
        return
    end

    self:addRedstone(batteryAddress, dir, redstoneAddress)
    self:writeConfig()
end

-- Called by command line to start the manager
function batteryManager.cmdStart(self, args, options)
    self:start()
end

-- Called by command line to stop the manager
function batteryManager.cmdStop(self, args, options)
    self.canRun = false
end

-- Called by command line to debug the code
function batteryManager.cmdTest(self, args, options)
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

return batteryManager