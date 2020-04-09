local DEFAULT_SIZE = 512.0

local comp = require("component")
local shell = require("shell")
local fs = require("filesystem")

local primaryPath
local emptyPath

local primaryStorage = comp.filesystem

for drive, path in fs.mounts()
do
    if (drive.spaceUsed() == DEFAULT_SIZE) and (drive.getLabel() == nil) then
        emptyPath = path
        break
    end
end

if not emptyPath then
    print("No empty unlabeled drive could be found, are you sure you put it in?")
    return
end

print("Copying '/' to '" .. emptyPath .. "'...")
shell.execute("cp -rox / " .. emptyPath)
