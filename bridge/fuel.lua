Fuel = Fuel or {}

local fuelResources = {
    'ox_fuel',
    'LegacyFuel',
    'cdn-fuel'
}

local function detectFuel()
    if Config.Fuel and Config.Fuel ~= 'auto' then
        return Config.Fuel
    end

    for _, resourceName in ipairs(fuelResources) do
        if GetResourceState and GetResourceState(resourceName) == 'started' then
            return resourceName
        end
    end

    return 'native'
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

function Fuel.GetFuel(vehicle)
    if not vehicle or vehicle == 0 then
        return 0.0
    end

    local resourceName = detectFuel()

    if resourceName == 'ox_fuel' then
        return Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
    end

    if resourceName == 'LegacyFuel' then
        return safeExport('LegacyFuel', 'GetFuel', vehicle) or GetVehicleFuelLevel(vehicle)
    end

    if resourceName == 'cdn-fuel' then
        return safeExport('cdn-fuel', 'GetFuel', vehicle) or GetVehicleFuelLevel(vehicle)
    end

    if resourceName == 'custom' and Config.CustomFuelGet then
        return Config.CustomFuelGet(vehicle)
    end

    return GetVehicleFuelLevel(vehicle)
end

function Fuel.SetFuel(vehicle, fuel)
    if not vehicle or vehicle == 0 then
        return false
    end

    fuel = tonumber(fuel) or 0.0

    local resourceName = detectFuel()

    if resourceName == 'ox_fuel' then
        Entity(vehicle).state:set('fuel', fuel, true)
        SetVehicleFuelLevel(vehicle, fuel)
        return true
    end

    if resourceName == 'LegacyFuel' then
        local result = safeExport('LegacyFuel', 'SetFuel', vehicle, fuel)
        SetVehicleFuelLevel(vehicle, fuel)
        return result ~= nil
    end

    if resourceName == 'cdn-fuel' then
        local result = safeExport('cdn-fuel', 'SetFuel', vehicle, fuel)
        SetVehicleFuelLevel(vehicle, fuel)
        return result ~= nil
    end

    if resourceName == 'custom' and Config.CustomFuelSet then
        Config.CustomFuelSet(vehicle, fuel)
        return true
    end

    SetVehicleFuelLevel(vehicle, fuel)
    return true
end
