local dependencyManager = {}

function dependencyManager.import(...)
    if(#arg == 0) then
        return
    end

    local results = {}

    for i = 1, #arg
    do
        repeat
            local target = require(arg[i])
            if(target == nil) then
                break
            end

            for name, func in target
            do
                result[name] = func
            end
        until true
    end

    return results
end

return dependencyManager