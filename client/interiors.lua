ClientInteriors = ClientInteriors or {}
ClientInteriors.DisplayVehicles = ClientInteriors.DisplayVehicles or {}

local function parseCoords(value)
    if type(value) == 'vector3' then
        return value
    end

    if type(value) == 'vector4' then
        return value
    end

    if type(value) == 'table' and value.x then
        if value.w then
            return vector4(value.x, value.y, value.z, value.w)
        end

        return vector3(value.x, value.y, value.z)
    end

    return nil
end

function ClientInteriors.SpawnDisplayVehicle(data, garageId)
    if not Config.Property.InteriorDisplayVehicles then
        return nil
    end

    if not data.coordsReady then
        ClientUtils.Debug('Skipping interior display vehicle; slot coords not ready.', data)
        return nil
    end

    local coords = parseCoords(data.coords)

    if not coords then
        return nil
    end

    local model = data.model

    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsModelInCdimage(model) then
        return nil
    end

    lib.requestModel(model, 5000)

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, false, false)

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    SetEntityInvincible(vehicle, true)

    if data.props then
        ClientUtils.ApplyVehicleProperties(vehicle, data.props)
    end

    if data.fuel and Fuel and Fuel.SetFuel then
        Fuel.SetFuel(vehicle, data.fuel)
    end

    if data.engineHealth then
        SetVehicleEngineHealth(vehicle, data.engineHealth + 0.0)
    end

    if data.bodyHealth then
        SetVehicleBodyHealth(vehicle, data.bodyHealth + 0.0)
    end

    if data.dirtLevel then
        SetVehicleDirtLevel(vehicle, data.dirtLevel + 0.0)
    end

    ClientInteriors.DisplayVehicles[garageId] = ClientInteriors.DisplayVehicles[garageId] or {}
    ClientInteriors.DisplayVehicles[garageId][data.plate] = vehicle

    SetModelAsNoLongerNeeded(model)
    return vehicle
end

function ClientInteriors.LoadVehicles(payload)
    local garageId = payload.garageId

    ClientInteriors.Cleanup(garageId)

    for _, vehicleData in ipairs(payload.vehicles or {}) do
        ClientInteriors.SpawnDisplayVehicle(vehicleData, garageId)
    end
end

function ClientInteriors.RemoveDisplay(garageId, plate)
    local garageVehicles = ClientInteriors.DisplayVehicles[garageId]

    if not garageVehicles then
        return
    end

    local entity = garageVehicles[plate]

    if entity and DoesEntityExist(entity) then
        DeleteVehicle(entity)
    end

    garageVehicles[plate] = nil
end

function ClientInteriors.Cleanup(garageId)
    local garageVehicles = ClientInteriors.DisplayVehicles[garageId]

    if not garageVehicles then
        return
    end

    for plate, entity in pairs(garageVehicles) do
        if entity and DoesEntityExist(entity) then
            DeleteVehicle(entity)
        end

        garageVehicles[plate] = nil
    end

    ClientInteriors.DisplayVehicles[garageId] = nil
end

RegisterNetEvent(W2F_GARAGE.Events.PropertyEnter, function(payload)
    ClientProperty.InInterior = true
    ClientProperty.CurrentGarage = payload.garageId
    ClientProperty.CurrentFloor = payload.floorIndex or 1

    local property = PropertyGarages.Get(payload.garageId)
    local entry = parseCoords(payload.interiorEnterCoords)
        or (property and parseCoords(PropertyGarages.GetInteriorEnterCoords(property)))

    if entry then
        local ped = PlayerPedId()
        SetEntityCoords(ped, entry.x, entry.y, entry.z, false, false, false, false)

        if entry.w then
            SetEntityHeading(ped, entry.w)
        end

        if not payload.productionReady then
            ClientUtils.Notify(Locale.interior_base_enter, 'inform')
        end
    else
        ClientUtils.Notify(Locale.interior_coords_pending, 'inform')
    end

    ClientInteriors.LoadVehicles({
        garageId = payload.garageId,
        vehicles = payload.vehicles or {}
    })
end)

RegisterNetEvent(W2F_GARAGE.Events.PropertyExit, function(payload)
    ClientProperty.LocalExit(payload.garageId)

    local property = PropertyGarages.Get(payload.garageId)
    local exitCoords = property and parseCoords(property.exteriorEntryCoords)

    if exitCoords then
        local ped = PlayerPedId()
        SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
    end
end)

RegisterNetEvent(W2F_GARAGE.Events.InteriorLoadVehicles, function(payload)
    ClientInteriors.LoadVehicles(payload)
end)

RegisterNetEvent(W2F_GARAGE.Events.InteriorUnloadVehicles, function(payload)
    ClientInteriors.Cleanup(payload.garageId)
end)

RegisterNetEvent(W2F_GARAGE.Events.InteriorSpawnDisplay, function(payload)
    ClientInteriors.SpawnDisplayVehicle(payload, payload.garageId)
end)

RegisterNetEvent(W2F_GARAGE.Events.InteriorRemoveDisplay, function(payload)
    ClientInteriors.RemoveDisplay(payload.garageId, payload.plate)
end)
