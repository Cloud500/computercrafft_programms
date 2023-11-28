local FakeBridge = {}

function FakeBridge.importItemFromPeripheral(item, container)

end

function FakeBridge.exportItemToPeripheral(item, container)

end

function FakeBridge.getItem(item)
    return {
        name = item.name,
        amount = math.random(10, 100)
    }
end

function FakeBridge.getCraftingCPUs()
    local cpu = {}

    local busy = {
        true,
        false
    }

    for i = 1, math.random(1, 5) do
        table.insert(cpu,
            {
                name = string.format("Test CPU %02d", math.random(1, 99)),
                storage = math.random(100, 1000),
                coProcessors = math.random(0, 5),
                isBusy = busy[math.random(#busy)]
            }
        )
    end

    return cpu
end

function FakeBridge.isItemCraftable(item)
    local result = {
        true,
        false
    }

    return result[math.random(#result)]
end

function FakeBridge.isItemCrafting(item)
    local result = {
        true,
        false
    }

    return result[math.random(#result)]
end

function FakeBridge.craftItem(item)
    return true
end

return FakeBridge
