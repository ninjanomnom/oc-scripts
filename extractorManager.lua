local component = require("component")
local sides = require("sides")

local args = {...}

if(#args == 0) then
    print("Usage: redstone <stage>")
    return
end

local extractor = component.extractor

local a, b, stageOneInput, d, e = extractor.getSlot(0)
if(stageOneInput == nil) then
    stageOneInput = 0
end

local a, b, stageTwoInput, d, e = extractor.getSlot(1)
if(stageTwoInput == nil) then
    stageTwoInput = 0
end

local a, b, stageThreeInput, d, e = extractor.getSlot(2)
if(stageThreeInput == nil) then
    stageThreeInput = 0
end

local a, b, stageFourInput, d, e = extractor.getSlot(3)
if(stageFourInput == nil) then
    stageFourInput = 0
end

local largestStackCount = math.max(stageOneInput, stageTwoInput, stageThreeInput, stageFourInput)

if(largestStackCount == 0) then
    redstone.setOutput(sides.top, 0)
    print("No inputs detected, disengaging.")
    return
end

local redstone = component.redstone
local chosenOutput = 0

if(stageOneInput == largestStackCount) then
    chosenOutput = 1
end
if(stageTwoInput == largestStackCount) then
    chosenOutput = 2
end
if(stageThreeInput == largestStackCount) then
    chosenOutput = 3
end
if(stageFourInput == largestStackCount) then
    chosenOutput = 4
end

print("Activating stage " .. chosenOutput .. " with stack of " .. largestStackCount .. " input items.")
redstone.setOutput(sides.top, chosenOutput)