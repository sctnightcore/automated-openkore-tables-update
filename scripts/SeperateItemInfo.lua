inputFolder = arg[1]
outputFolder = arg[2]
importFile =  arg[1] .. "/iteminfo.lub"

dofile(importFile)

function reverseMap(map)
    local newMap = {}
    
    for k, v in pairs(map) do
        newMap[v] = k
    end
    
    return newMap
end

function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

items = io.open(outputFolder .. "/idnum2itemdisplaynametable.txt", "w")
itemsdescriptions = io.open(outputFolder .. "/idnum2itemdesctable.txt", "w")
itemslotcounttable = io.open(outputFolder .. "/itemslotcounttable.txt", "w")

for ItemID, DESC in pairsByKeys(tbl) do
    if next(DESC.identifiedDescriptionName) ~= nil then
        local itemsString = ItemID .. "#" .. DESC.identifiedDisplayName .. "#\n"
        local itemsdescriptionsString = ItemID .. "#\n"
        local itemslotcounttableString = ItemID .. "#" .. DESC.slotCount .. "#\n"
        
        for i, desc in ipairs(DESC.identifiedDescriptionName) do
            itemsdescriptionsString = itemsdescriptionsString .. desc .. "\n"
        end
        itemsdescriptionsString = itemsdescriptionsString .. "#\n"
        
        items:write(itemsString)
        itemsdescriptions:write(itemsdescriptionsString)
        if (DESC.slotCount > 0) then
            itemslotcounttable:write(itemslotcounttableString)
        end
    end
end

items:close()
itemsdescriptions:close()
itemslotcounttable:close()    