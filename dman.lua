local dependencyManager = {}

function dependencyManager.import(...)
    local args = table.pack(...)

    if(#args == 0) then
        return
    end

    local results = {}

    for i = 1, #args
    do
        repeat
            local target = require(args[i])
            if(target == nil) then
                break
            end

            for name, func in pairs(target)
            do
                results[name] = func
            end
        until true
    end

    return results
end

return dependencyManager