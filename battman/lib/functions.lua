local thread = require("thread")
local component = require("component")
local se = require("serialization")
local sides = require("sides")

local batteryManager = {}

function batteryManager.start(self)
    self.canRun = true

    local worker = thread.create(
        function()
            print("Starting battman daemon")
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
            print("Ending battman daemon")
        end
    )
    self.thread = worker
    worker:detach()
end

function batteryManager.loop(self)
    local lowestPrimary
    local combinedPrimary = 0

    for address, bool in pairs(self.config.primaryBatteries)
    do
        local battery = component.proxy(address)
        local energy = battery:getStoredEnergy()

        if(energy == 0) then
            -- panic
        end

        if((lowestPrimary == nil) or (lowestPrimary > energy)) then
            lowestPrimary = energy
        end

        combinedPrimary = combinedPrimary + energy
    end

    local difference = combinedPrimary - self.lastPrimaryEnergy
    self.lastPrimaryEnergy = combinedPrimary

    for address, bool in pairs(self.config.overflowBatteries)
    do
        local battery = component.proxy(address)
        local redstoneData = self.config.bat2redstone[address]
        local energy = battery:getStoredEnergy()
        if(redstoneData and redstoneData.address) then
            local entity = component.proxy(redstoneData.address)
            if(energy < lowestPrimary) then
                -- shut off
                entity.setOutput(sides[redstoneData.dir], 0)
                self.config.overflowBatteries[address] = "off"
            else
                -- turn on
                entity.setOutput(sides[redstoneData.dir], 15)
                self.config.overflowBatteries[address] = "on"
            end
        else
            self.config.overflowBatteries[address] = "off"
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

function batteryManager.detectRedstone(self)
    for address, type in pairs(component.list("redstone", true))
    do
        if(not self.config.redstone[address]) then
            self.config.newRedstone[address] = true
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
    self:removeRedstone(redstoneAddress)

    self.config.bat2redstone = self.config.redstone or {}
    self.config.bat2redstone[batteryAddress] = {}
    self.config.bat2redstone[batteryAddress].address = redstoneAddress
    self.config.bat2redstone[batteryAddress].dir = dir

    self.config.redstone = self.config.redstone or {}
    self.config.redstone[redstoneAddress] = batteryAddress
    
    return true
end

function batteryManager.removeRedstone(self, redstoneAddress)
    if(self.config.newRedstone and self.config.newRedstone[redstoneAddress]) then
        self.config.newRedstone[redstoneAddress] = nil
        return
    end

    if((not self.config["redstone"]) or (not self.config.redstone[redstoneAddress])) then
        return false
    end
    local batteryAddress = self.config.redstone[redstoneAddress]
    
    self.config.redstone[redstoneAddress] = nil
    self.config.bat2redstone[batteryAddress] = nil
    return true
end

function batteryManager.readConfig(self)
    local configFile = io.open(self.configLocation, "r")
    
    if(configFile == nil) then
        return
    end

    local newconfig = se.unserialize(configFile:read("*all"))
    if(newconfig == nil) then
        return
    end

    configFile:close()

    -- We don't just assign the result because that would make blank fields not even have the table
    for key, value in pairs(newconfig)
    do
        self.config[key] = value
    end

    self:cleanup()
end

function batteryManager.writeConfig(self)
    local configFile = io.open(self.configLocation, "w")

    configFile:write(se.serialize(self.config))
    io.close(configFile)
end

function batteryManager.handleError(self, err)
    self.errorCount = self.errorCount + 1
    if(self.errorCount >= 10) then -- This means it threw an error 10 times in a row
        self.canRun = false
    end

    pcall(self.cleanup, self)

    print("ERROR!:", err)
    print(tostring(debug.traceback()))
end

function batteryManager.cleanup(self)
    for address, bool in pairs(self.config.newBatteries)
    do
        if(component.proxy(address) == nil) then
            self:removeBattery(address)
        end
    end

    for address, bool in pairs(self.config.primaryBatteries)
    do
        if(component.proxy(address) == nil) then
            self:removeBattery(address)
        end
    end

    for address, bool in pairs(self.config.overflowBatteries)
    do
        if(component.proxy(address) == nil) then
            self:removeBattery(address)
        end
    end

    for address, bool in pairs(self.config.newRedstone)
    do
        if(component.proxy(address) == nil) then
            self:removeRedstone(address)
        end
    end

    for address, bool in pairs(self.config.redstone)
    do
        if(component.proxy(address) == nil) then
            self:removeRedstone(address)
        end
    end

    for address, bool in pairs(self.config.bat2redstone)
    do
        if(component.proxy(address) == nil) then
            self:removeBattery(address)
        end

        local redstoneData = self.config.bat2redstone[address]
        if(redstoneData.address and (component.proxy(redstoneData.address) == nil)) then
            self:removeRedstone(redstoneData.address)
        end
    end
end

return batteryManager