local prettyprint = {}

function prettyprint.printTable(target)
    for key, value in target
    do
        print(key, value)
    end
end

function prettyprint.printArray(target)
    for i = 1, target
    do
        print(i .. " = " .. target[i])
    end
end

return prettyprint