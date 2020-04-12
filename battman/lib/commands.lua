local component = require("component")

local batteryManager = {}

-- Called by command line to view configuration/etc
function batteryManager.cmdView(self, args, options)
    local all = "all"
    local new = "new"
    local redstone = "redstone"
    local primary = "primary"
    local overflow = "overflow"

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
    if((category == all) or (category == redstone)) then
        print("Unassigned Redstone")
        for address, bool in pairs(self.config.newRedstone)
        do
            print(address)
        end
        print("-----")
    end
    if((category == all) or (category == primary)) then
        print("Primary batteries")
        print("Battery Address", "Redstone Address")
        for address, bool in pairs(self.config.primaryBatteries)
        do
            local redstone
            if((self.config.bat2redstone ~= nil) and (self.config.bat2redstone[address] ~= nil)) then
                redstone = self.config.bat2redstone[address].address
            end

            print(address, redstone)
        end
        print("-----")
    end
    if((category == all) or (category == overflow)) then
        print("Overflow batteries")
        print("Battery Address", "Redstone Address")
        for address, status in pairs(self.config.overflowBatteries)
        do
            local redstone
            local dir
            if((self.config.bat2redstone ~= nil) and (self.config.bat2redstone[address] ~= nil)) then
                local redstoneData = self.config.bat2redstone[address]
                redstone = redstoneData.address
                dir = redstoneData.dir
            end

            print(address, redstone, dir, status)
        end
        print("-----")
    end
end

-- Called by command line to configure the manager
function batteryManager.cmdSet(self, args, options)
    batteryManager.setCountCheck(args, 2)

    local actions = {}
    actions["primary"] = self.setPrimary
    actions["overflow"] = self.setOverflow
    actions["redstone"] = self.setRedstone

    local action = actions[string.lower(args[2])]
    
    if(not action) then
        print(args[2] .. " is not a valid set type")
        return
    end

    action(self, args, options)

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

    return true
end

function batteryManager.setPrimary(self, args, options)
    if((not batteryManager.setCountCheck(args, 3)) or (not batteryManager.setCompCheck(args, 3, "battery"))) then
        return
    end

    local address = component.get(args[3])

    self:addPrimary(address)
end

function batteryManager.setOverflow(self, args, options)
    if((not batteryManager.setCountCheck(args, 3)) or (not batteryManager.setCompCheck(args, 3, "battery"))) then
        return
    end

    local address = component.get(args[3])

    self:addOverflow(address)
end

function batteryManager.setRedstone(self, args, options)
    if(
        (not batteryManager.setCountCheck(args, 5)) or 
        (not batteryManager.setCompCheck(args, 3, "battery")) or
        (not batteryManager.setCompCheck(args, 5, "redstone"))
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

    if (options.f) then
        print("Force stopping the manager!")
        if(self.thread) then
            self.thread:kill()
        end
        batteryManager.primaryInstance = nil
    end
end

return batteryManager