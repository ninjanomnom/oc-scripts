local component = require("component")

local batteryManager = {}

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
            print(address)
        end
        print("-----")
    end
    if((category == all) or (category == primary)) then
        print("Primary batteries")
        for address, bool in pairs(self.config.primaryBatteries)
        do
            local entity = component.proxy(address)
            print(address)
        end
        print("-----")
    end
    if((category == all) or (category == overflow)) then
        print("Overflow batteries")
        for address, bool in pairs(self.config.overflowBatteries)
        do
            local entity = component.proxy(address)
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
    self:writeConfig()
end

function batteryManager.setCountCheck(args, num)
    if(#args < num) then
        print("You must specify what to set")
        return false
    end
    return true
end

function batteryManager.setCompCheck(args, index, name)
    local error = "The " .. name .. "address given could not be found"

    local address = component.get(args[index])
    if(address == nil) then
        print(error)
        return false
    end

    local entity = component.proxy(address)
    if(entity == nil) then
        print(error)
        return false
    end

    if(entity.type ~= name) then
        print("The address given was not for a " .. name)
        return false
    end
end

function batteryManager.setPrimary(self, args, options)
    if(batteryManager.setCountCheck(args, 3) or batteryManager.setCompCheck(args, 3, "battery")) then
        return
    end

    local address = component.get(args[3])

    self:addPrimary(address)
end

function batteryManager.setOverflow(self, args, options)
    if(batteryManager.setCountCheck(args, 3) or batteryManager.setCompCheck(args, 3, "battery")) then
        return
    end

    local address = component.get(args[3])

    self:addOverflow(address)
end

function batteryManager.setRedstone(self, args, options)
    if(
        batteryManager.setCountCheck(args, 5) or 
        batteryManager.setCompCheck(args, 3, battery) or
        batteryManager.setCompCheck(args, 5, redstone)
    ) then
        return
    end

    local batteryAddress = component.get(args[3])
    local dir = args[4]
    local redstoneAddress = component.get(args[5])

    self:addRedstone(batteryAddress, dir, redstoneAddress)
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