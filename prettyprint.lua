local prettyprint = {}

function prettyprint.printTable(target)
    for key, value in pairs(target)
    do
        print(tostring(key), tostring(value))
    end
end

function prettyprint.printArray(target)
    for i = 1, #target
    do
        print(i .. " = " .. tostring(target[i]))
    end
end

return prettyprint