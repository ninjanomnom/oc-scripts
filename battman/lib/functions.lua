local thread = require("thread")
local component = require("component")
local se = require("serialization")

local batteryManager = {}

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

return batteryManager