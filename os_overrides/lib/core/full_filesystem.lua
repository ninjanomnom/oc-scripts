local filesystem = require("filesystem")
local ffs = require("overriden_filesystem")

-- All those warnings against mucking with os files don't apply to us right?
local old_proxy = ffs.proxy

function ffs.proxy(filter, options)
    local proxy, reason = old_proxy(filter, options)
    if(not proxy) then
        return proxy, reason
    end
    if(proxy.type == "filesystem_bind") then
        local real = filesystem.bind(proxy.address)

        proxy.spaceUsed = real.spaceUsed
        proxy.spaceTotal = real.spaceTotal
    end
end