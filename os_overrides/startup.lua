-- This is really a script for my own personal use but if you can make use of it go ahead
-- What this does is seamlessly integrate an external drive into your computer
-- In my case I chose a raid drive
-- Just make sure the label for the drive is "personalraid" and this should work fine

local home = filesystem.get("/home")
if(home:getLabel() == "LeaveMeAlone") then
    -- Well alright then
    return
end

local filesystem = require("filesystem")
local shell = require("shell")

filesystem.umount("/rd")
filesystem.mount("personalraid", "/rd")
shell.execute("mkdir /rd/home")
shell.execute("mount --bind /rd/home /home")
shell.execute("mkdir /rd/usr")
shell.execute("mount --bind /rd/usr /usr")
shell.execute("mkdir /rd/etc")
shell.execute("mount --bind /rd/etc /etc")
