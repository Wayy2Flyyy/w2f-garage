Inventory = Inventory or {}

local function debugPrint(message)
    if Config and Config.Debug then
        print(('%s [inventory] %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
    end
end

local function usingOxInventory()
    if Config.Inventory ~= 'auto' and Config.Inventory ~= 'ox_inventory' then
        return false
    end

    return GetResourceState and GetResourceState('ox_inventory') == 'started'
end

function Inventory.HasItem(source, item, amount)
    amount = amount or 1

    if usingOxInventory() then
        return (exports.ox_inventory:Search(source, 'count', item) or 0) >= amount
    end

    local player = Bridge and Bridge.GetPlayer(source)

    if player and player.Functions and player.Functions.GetItemByName then
        local itemData = player.Functions.GetItemByName(item)
        return itemData and (itemData.amount or itemData.count or 0) >= amount
    end

    debugPrint(('HasItem fallback returned false for item "%s".'):format(item or 'unknown'))
    return false
end

function Inventory.AddItem(source, item, amount, metadata)
    amount = amount or 1

    if usingOxInventory() then
        return exports.ox_inventory:AddItem(source, item, amount, metadata) == true
    end

    local player = Bridge and Bridge.GetPlayer(source)

    if player and player.Functions and player.Functions.AddItem then
        return player.Functions.AddItem(item, amount, false, metadata)
    end

    debugPrint(('AddItem fallback returned false for item "%s".'):format(item or 'unknown'))
    return false
end

function Inventory.RemoveItem(source, item, amount, metadata)
    amount = amount or 1

    if usingOxInventory() then
        return exports.ox_inventory:RemoveItem(source, item, amount, metadata) == true
    end

    local player = Bridge and Bridge.GetPlayer(source)

    if player and player.Functions and player.Functions.RemoveItem then
        return player.Functions.RemoveItem(item, amount, false, metadata)
    end

    debugPrint(('RemoveItem fallback returned false for item "%s".'):format(item or 'unknown'))
    return false
end

function Inventory.GetItemCount(source, item)
    if usingOxInventory() then
        return exports.ox_inventory:Search(source, 'count', item) or 0
    end

    local player = Bridge and Bridge.GetPlayer(source)

    if player and player.Functions and player.Functions.GetItemByName then
        local itemData = player.Functions.GetItemByName(item)
        return itemData and (itemData.amount or itemData.count or 0) or 0
    end

    return 0
end

function Inventory.GetInventoryItem(source, item)
    if usingOxInventory() then
        return exports.ox_inventory:Search(source, 'slots', item)
    end

    local player = Bridge and Bridge.GetPlayer(source)

    if player and player.Functions and player.Functions.GetItemByName then
        return player.Functions.GetItemByName(item)
    end

    return nil
end
