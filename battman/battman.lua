local shell = require("shell")
local batteryManager = require("battman/BatteryManager")

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

local manager = batteryManager.newIfDead()
actions[action](manager, args, options)