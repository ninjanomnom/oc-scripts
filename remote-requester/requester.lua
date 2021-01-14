local component = require("component")
local event = require("event")
local serialization = require("serialization")
local shell = require("shell")

local args, options = shell.parse(...)

local tunnel = component.tunnel

local s = serialization.serialize

local name
if(#args == 0) then
	print("Enter name query: ")
	name = io.read()
else
	name = args[1]
end

local from_idx = 1

local deserialized = nil
local which = nil

while true do
	tunnel.send(s({cmd="query", name=name, from_idx=from_idx}))

	local _, _, _, _, _, message = event.pull(20, "modem_message")
	deserialized = serialization.unserialize(message)

	for i,v in ipairs(deserialized.results) do
		local str = string.format("[%d] %s (x %d)", i, v.name, v.size)
		if v.is_craftable then
			str = str .. " C"
		end
		print(str)
	end

	print(string.format("Showing results %d-%d/%d",
	 	deserialized.from_idx,
	  	deserialized.from_idx + #deserialized.results - 1,
	   	deserialized.totalCount))

	print("Which item or next page (n):")
	which = io.read()

	if not which then
		return
	end

	-- > Lua doesn't have a continue statement
	if which ~= "n" then
		which = tonumber(which)
		break
	end

	from_idx = deserialized.from_idx + #deserialized.results
end

print("Request count:")
local count = tonumber(io.read())

local selected = deserialized.results[which]
local fingerprint = selected.fingerprint

tunnel.send(s({cmd="export", fingerprint=fingerprint, amount=count}))
