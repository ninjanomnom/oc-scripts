local component = require("component")
local thread = require("thread")

local juke = component.jukebox
if(juke == nil) then
    print("No jukebox is attached!")
    return
end

local worker = thread.create(
    function()
        local juke = component.jukebox
        if(juke == nil) then
            return
        end
        while(true) 
        do
            juke:play()
            os.sleep(100)
        end
    end
)

worker:detach()