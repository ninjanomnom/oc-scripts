local component = require("component")
local filesystem = require("filesystem")
local os = require("os")
local shell = require("shell")

local args = {...}

if(#args == 0) then
    print("Usage: cdoc <component type>")
    return
end

local compType = args[1]

if(not component.isAvailable(compType)) then
    print("The component could not be found attached to the network")
    return
end

local compId = component.get("", compType)
local compInstance = component.proxy(compId)

local temppath = "/tmp/tempfileprint.txt"
local newfile = assert(io.open(temppath, "wb"))

for methodname, randombool in pairs(component.methods(compInstance.address))
do
    newfile:write("§l".. methodname .."§r\n")
    newfile:write((component.doc(compInstance.address, methodname) or "no documentation found") .. "\n")
end

newfile:flush()
newfile:close()

local _ = shell.execute("print -g " .. temppath)