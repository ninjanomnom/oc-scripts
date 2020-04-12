local filesystem = require("filesystem")

print("This is a massive hack and you may want to backup your data before continuing")
print("Make sure this file and associated files are alone on an unconfigured raid drive")
io.write("Enter 'fuckmeup' to continue: ")
local continue = io.read()
if(continue ~= "fuckmeup") then
    return
end

io.write("What drive will you be using (path, not label)? ")
local location = filesystem.canonical(io.read())
local master = filesystem.get(location)
if(not master) then
    print(location .. " is not a valid path: " .. (master or "nil"))
    return
end

io.write("Preparing Overrides...")

local currentTarget
local firstRun = true -- We ignore the files in the first directory, we don't need to move startup.lua
local nextTargets = {location}
local foundTargets = {}
while(#nextTargets > 0)
do
    currentTarget = table.remove(nextTargets, #nextTargets)
    for path in filesystem.list(currentTarget)
    do
        if(filesystem.isDirectory(path)) then
            table.insert(nextTargets, path)
            print(path)
        elseif(not firstRun) then
            table.insert(foundTargets, currentTarget .. path)
            print(currentTarget .. path)
        end
    end
end