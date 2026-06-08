Keys = Keys or {}

local knownKeyResources = {
    'qb-vehiclekeys',
    'qbx_vehiclekeys',
    'Renewed-Vehiclekeys',
    'mk_vehiclekeys'
}

local function detectKeys()
    if Config.Keys and Config.Keys ~= 'auto' then
        return Config.Keys
    end

    for _, resourceName in ipairs(knownKeyResources) do
        if GetResourceState and GetResourceState(resourceName) == 'started' then
            return resourceName
        end
    end

    return 'none'
end

local function safeExport(resourceName, method, ...)
    local args = { ... }
    local ok, result = pcall(function()
        return exports[resourceName][method](exports[resourceName], table.unpack(args))
    end)

    if ok then
        return result
    end

    ok, result = pcall(function()
        return exports[resourceName][method](table.unpack(args))
    end)

    if ok then
        return result
    end

    return nil
end

function Keys.GiveKeys(source, plate, vehicle)
    local resourceName = detectKeys()

    if resourceName == 'none' or resourceName == 'disabled' then
        return true
    end

    if resourceName == 'qb-vehiclekeys' then
        TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
        return true
    end

    if resourceName == 'qbx_vehiclekeys' then
        return safeExport('qbx_vehiclekeys', 'GiveKeys', source, plate, vehicle) ~= nil
    end

    if resourceName == 'Renewed-Vehiclekeys' then
        return safeExport('Renewed-Vehiclekeys', 'addKey', source, plate) ~= nil
    end

    if resourceName == 'mk_vehiclekeys' then
        return safeExport('mk_vehiclekeys', 'AddKey', source, plate) ~= nil
    end

    if resourceName == 'custom' and Config.CustomGiveKeys then
        Config.CustomGiveKeys(source, plate, vehicle)
        return true
    end

    return true
end

function Keys.RemoveKeys(source, plate, vehicle)
    local resourceName = detectKeys()

    if resourceName == 'none' or resourceName == 'disabled' then
        return true
    end

    if resourceName == 'qbx_vehiclekeys' then
        return safeExport('qbx_vehiclekeys', 'RemoveKeys', source, plate, vehicle) ~= nil
    end

    if resourceName == 'Renewed-Vehiclekeys' then
        return safeExport('Renewed-Vehiclekeys', 'removeKey', source, plate) ~= nil
    end

    if resourceName == 'mk_vehiclekeys' then
        return safeExport('mk_vehiclekeys', 'RemoveKey', source, plate) ~= nil
    end

    if resourceName == 'custom' and Config.CustomRemoveKeys then
        Config.CustomRemoveKeys(source, plate, vehicle)
        return true
    end

    return true
end

function Keys.HasKeys(source, plate, vehicle)
    local resourceName = detectKeys()

    if resourceName == 'none' or resourceName == 'disabled' then
        return true
    end

    if resourceName == 'qbx_vehiclekeys' then
        local result = safeExport('qbx_vehiclekeys', 'HasKeys', source, plate, vehicle)
        return result == true
    end

    if resourceName == 'custom' and Config.CustomHasKeys then
        return Config.CustomHasKeys(source, plate, vehicle) == true
    end

    return false
end
