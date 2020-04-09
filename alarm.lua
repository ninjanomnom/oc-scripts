local component = require("component")

local alarm = component.os_alarm

if (not alarm) then
    print("You need an alarm to be attached")
    return
end

local alarmTypes = alarm.listSounds()

for index, soundfile in pairs(alarmTypes)
do
    print(index, soundfile)
end

io.write("Enter the alarm number to test: ")
local chosenAlarm = alarmTypes[io.read("*n")]
for substr in string.gmatch(chosenAlarm, "[^%.]+")
do
    chosenAlarm = substr
    break
end
if(not pcall(io.write, "You chose " .. chosenAlarm)) then
    return
end
alarm.setAlarm(chosenAlarm)

alarm.activate()
os.sleep(5)
alarm.deactivate()