local thread = require("thread")

function ItemsInSlot(slot)
    local component = require("component")
    local extractor = component.extractor
    
    local a, b, count, d, e = extractor.getSlot(slot)
    if(count == nil) then
        count = 0
    end
    return count
end

function Tick()
    local component = require("component")
    local redstone = component.redstone

    local sides = require("sides")

    local chosenSlot
    local chosenStackCount = 0
    for i = 0, 4 do
        local stackCount = ItemsInSlot(i)
        if(stackCount >= chosenStackCount) then
            chosenSlot = i
            chosenStackCount = stackCount
        end
    end

    if(chosenStackCount == 0) then
        redstone.setOutput(sides.top, 0)
        print("No inputs detected, disengaging.")
        return
    end

    local stage = chosenSlot + 1

    print("Activating stage " .. stage .. " with stack of " .. chosenStackCount .. " input items.")

    redstone.setOutput(sides.top, stage)
end

local worker = thread.create(
    function()
        while(true) do
            Tick()
            os.sleep(10)
        end
    end
)

worker:detach()