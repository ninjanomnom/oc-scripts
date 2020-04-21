local dependencyManager = {}

function dependencyManager.import(...)
    local args = table.pack(...)

    if(#args == 0) then
        return
    end

    local results = {}

    for key, package in pairs(args)
    do
        if(key == "n") then
            break
        end

        repeat
            local target = require(package)
            if(target == nil) then
                break
            end

            for name, func in pairs(target)
            do
                if(name == "n") then
                    break
                end
                results[name] = func
            end
        until true
    end

    return results
end

return dependencyManager