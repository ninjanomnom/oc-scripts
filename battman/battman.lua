local shell = require("shell")
local batteryManager = require("battman/definition")

local args, options = shell.parse(...)

if(#args == 0) then
    print("Usage: battman <action>")
    print("----")
    print("battman view <new|primary|overflow|redstone|all>")
    print("Displays all of the specified devices.")
    print("----")
    print("battman set <primary|overflow|redstone> <address> [side]")
    print("Sets the device at the address to the specified category. Redstone IO requires a side.")
    print("You may use an abbreviated form of the address")
    print("----")
    print("battman start")
    print("Starts up the manager")
    return
end

local actions = {}
actions["view"] = batteryManager.cmdView
actions["set"] = batteryManager.cmdSet
actions["start"] = batteryManager.cmdStart
actions["stop"] = batteryManager.cmdStop
actions["test"] = batteryManager.cmdTest

local action = string.lower(args[1])

local manager = batteryManager.newIfDead()
actions[action](manager, args, options)