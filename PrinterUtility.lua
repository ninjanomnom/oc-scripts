local printerUtility = {}
local maxChars
local maxLines

local printer = comp.openprinter
printer.clear()

local titleBase = emptyDrive.type .. " API - "
printer.setTitle(titleBase .. "Page 1")

local lineCount = 0
local pageCount = 1

for name, somerandombool in pairs(comp.methods(address))
do
    print(name)
    printer.writeln("§l".. name .."§r")
    printer.writeln(comp.doc(address, name))
    lineCount = lineCount + 2
    if (lineCount >= 20) then
        printer.print()
        lineCount = 0
        pageCount = pageCount + 1
        printer.setTitle(titleBase .. "Page " .. pageCount)
    end
end

print(pageCount)

if not (lineCount == 0) then
    printer.print()
end