local component = require("component")
local event = require("event")
local serialization = require("serialization")
local thread = require("thread")

local interface_id = "e626d558-b5aa-47c5-8c82-f2a663976bab"
local interface_chest_direction = "UP"

local me_interface = component.proxy(interface_id)
local page_size = 20

function compare_size(a, b)
	return a.size > b.size
end

function main_loop()
	while true do
		local ev_name, localAddr, _, _, _, message = event.pull("modem_message")
		
		print(">> " .. message)

		local deserialized = serialization.unserialize(message)

		if deserialized.cmd == "query" then
			do_cmd_query(localAddr, deserialized)
		elseif deserialized.cmd == "export" then
			do_cmd_export(localAddr, deserialized)
		end
	end
end

function do_cmd_query(addr, msg)
	local name_filter = msg.name
	local from_idx = msg.from_idx
	if not from_idx then
		from_idx = 1
	end

	if name_filter then
		name_filter = string.lower(name_filter)
	end

	local filtered = nil

	if name_filter == nil then
		filtered = me_interface.getAvailableItems()
	else
		-- searching by substring name is EXTREMELY hard.
		-- me_interface.getAvailableItems() does not return name immediately.
		-- while you CAN ask it to provide this info via "ALL" or "PROXY" detail,
		-- both of these OOM on the 2 MB memory on the test machine I was using for the ME network.
		-- asking for the name via me_interface.getItemDetail() for every item is too slow to be practical. 
		-- me_interface.getItemsInNetwork() DOES give names compactly, but we can't get fingerprints.
		-- What we do is search through me_interface.getItemsInNetwork(), store the ID and metadata in a set,
		-- then use that as a broadphase when filtering through me_interface.getAvailableItems()
		-- since we can get ID/metadata from the fingerprint before having to call me_interface.getItemDetail()		
		
		local potential_ids = {}

		for i,v in ipairs(me_interface.getItemsInNetwork()) do
			if string.find(string.lower(v.label), name_filter) then
				if not potential_ids[v.name] then
					potential_ids[v.name] = {}
				end

				potential_ids[v.name][v.damage] = true
			end
		end

		filtered = {}

		for i,v in ipairs(me_interface.getAvailableItems()) do
			if potential_ids[v.fingerprint.id] and potential_ids[v.fingerprint.id][v.fingerprint.dmg] then
				local name = me_interface.getItemDetail(v.fingerprint, false).display_name
				if string.find(string.lower(name), name_filter) then
					table.insert(filtered, v)
				end
			end

		end
	end

	-- Sort by count
	table.sort(filtered, compare_size)

	local item_count = math.min(page_size, #filtered - from_idx + 1)

	local output = {}

	for i=from_idx,item_count+from_idx-1 do
		local data = filtered[i]
		local detail = me_interface.getItemDetail(data.fingerprint, false)

		table.insert(output, {
			name=detail.display_name,
			size=data.size,
			fingerprint=data.fingerprint,
			is_craftable=data.is_craftable
		})
	end

	local serialized = serialization.serialize({totalCount=#filtered, results=output, from_idx=from_idx})
	print("done!")
	--print(serialized)
	component.invoke(addr, "send", serialized)
end

function do_cmd_export(addr, msg)
	local fingerprint = msg.fingerprint
	local amount = msg.amount

	local avail_count = me_interface.getItemDetail(fingerprint, false).qty

	local craft_amount = math.max(0, amount - avail_count)

	amount = amount - craft_amount

	thread.create(do_crafts, fingerprint, craft_amount)

	while amount > 0 do
		local status, ret = pcall(me_interface.exportItem, fingerprint, interface_chest_direction, amount)

		if not status or ret == nil or ret.size == 0 then
			-- Out of items or output inventory full, abort.
			break
		end

		amount = amount - ret.size
	end
end

function do_crafts(fingerprint, count)
	me_interface.requestCrafting(fingerprint, count)
	local sleeps_remaining = 30

	while count > 0 do
		local status, ret = pcall(me_interface.exportItem, fingerprint, interface_chest_direction, count)

		if not status or ret == nil or ret.size == 0 then
			os.sleep(1)
			sleeps_remaining = sleeps_remaining - 1
			if not sleeps_remaining then
				return
			end
		else
			count = count - ret.size
		end
	end
end

function start()
	print("Requester thread starting up")
	while(true)
	do
		xpcall(
			main_loop,
			function(err)
				handleErr(err)
			end
		)
	end
end

function handleErr(err)
	print("ERROR!:", err)
    print(tostring(debug.traceback()))
end

local worker = thread.create(start)
worker:detach()