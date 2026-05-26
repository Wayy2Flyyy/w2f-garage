ClientUtils = ClientUtils or {}

function ClientUtils.Debug(message, data)
    if not Config.Debug then
        return
    end

    if data ~= nil and json and json.encode then
        print(('%s [client] %s %s'):format(Config.DebugPrefix or '[w2f-garage]', message, json.encode(data)))
        return
    end

    print(('%s [client] %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
end

function ClientUtils.Notify(message, notifyType, duration)
    if Notify and Notify.Client then
        Notify.Client(message, notifyType, duration)
        return
    end

    print(('%s %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
end

function ClientUtils.GetGarage(garageId)
    return Garages and Garages.Get and Garages.Get(garageId) or nil
end

function ClientUtils.ToPlainTable(value)
    if type(value) == 'vector3' then
        return { x = value.x, y = value.y, z = value.z }
    end

    if type(value) == 'vector4' then
        return { x = value.x, y = value.y, z = value.z, w = value.w }
    end

    if type(value) == 'table' then
        local output = {}

        for key, nested in pairs(value) do
            output[key] = ClientUtils.ToPlainTable(nested)
        end

        return output
    end

    return value
end

function ClientUtils.NormalizePlate(plate)
    if type(plate) ~= 'string' then
        return nil
    end

    local normalized = plate:gsub('^%s*(.-)%s*$', '%1'):upper()

    if normalized == '' or #normalized > 16 then
        return nil
    end

    return normalized
end

function ClientUtils.GetVehicleProperties(vehicle)
    if not vehicle or vehicle == 0 then
        return nil
    end

    local coords = GetEntityCoords(vehicle)

    return {
        plate = ClientUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle) or ''),
        model = GetEntityModel(vehicle),
        fuel = Fuel.GetFuel(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        location = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = GetEntityHeading(vehicle)
        },
        props = lib and lib.getVehicleProperties and lib.getVehicleProperties(vehicle) or {}
    }
end

function ClientUtils.ApplyVehicleProperties(vehicle, properties)
    if not vehicle or vehicle == 0 or type(properties) ~= 'table' then
        return false
    end

    if lib and lib.setVehicleProperties and properties.props then
        lib.setVehicleProperties(vehicle, properties.props)
    end

    if properties.fuel then
        Fuel.SetFuel(vehicle, properties.fuel)
    end

    if properties.engineHealth then
        SetVehicleEngineHealth(vehicle, properties.engineHealth)
    end

    if properties.bodyHealth then
        SetVehicleBodyHealth(vehicle, properties.bodyHealth)
    end

    if properties.dirtLevel then
        SetVehicleDirtLevel(vehicle, properties.dirtLevel)
    end

    return true
end

function ClientUtils.IsSpawnPointClear(coords, radius)
    radius = radius or 3.0

    if not coords then
        return false
    end

    return not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, radius)
end

function ClientUtils.GetClosestVehicle(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    return lib and lib.getClosestVehicle and lib.getClosestVehicle(coords, radius or 5.0, false) or GetVehiclePedIsIn(ped, false)
end
