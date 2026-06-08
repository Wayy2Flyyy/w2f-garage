Spawn = Spawn or {}

function Spawn.GetClearSpawnPoint(garage)
    if not garage or type(garage.spawnPoints) ~= 'table' then
        return nil
    end

    for _, coords in ipairs(garage.spawnPoints) do
        if ClientUtils.IsSpawnPointClear(coords, 3.0) then
            return coords
        end
    end

    return nil
end

function Spawn.RequestVehicle(garageId, plate)
    plate = ClientUtils.NormalizePlate(plate)

    if not plate then
        return {
            success = false,
            code = 'invalid_plate',
            message = Locale.invalid_plate
        }
    end

    local garage = ClientUtils.GetGarage(garageId)

    if not garage then
        return {
            success = false,
            code = 'invalid_garage',
            message = Locale.invalid_garage
        }
    end

    local spawnPoint = Spawn.GetClearSpawnPoint(garage)

    if not spawnPoint then
        return {
            success = false,
            code = 'spawn_blocked',
            message = 'No clear spawn point is available.'
        }
    end

    local response = lib.callback.await(W2F_GARAGE.Callbacks.SpawnVehicle, false, {
        garageId = garageId,
        plate = plate,
        spawnPoint = {
            x = spawnPoint.x,
            y = spawnPoint.y,
            z = spawnPoint.z,
            w = spawnPoint.w
        }
    })

    if response and response.success and response.data and response.data.approved then
        ClientUtils.Debug('Server approved spawn payload.', response.data)
    else
        ClientUtils.Notify(response and response.message or Locale.not_implemented, 'error')
    end

    return response
end

RegisterNetEvent(W2F_GARAGE.Events.SpawnVehicle, function(payload)
    local model = payload.model

    if type(model) == 'string' then
        model = joaat(model)
    end

    local coords = payload.coords

    if not coords or not model then
        ClientUtils.Notify(Locale.coords_not_ready, 'error')
        return
    end

    lib.requestModel(model, 10000)

    local vehicle = CreateVehicle(
        model,
        coords.x,
        coords.y,
        coords.z,
        coords.w or 0.0,
        true,
        false
    )

    SetVehicleNumberPlateText(vehicle, payload.plate or '')
    ClientUtils.ApplyVehicleProperties(vehicle, payload)

    if Config.Features.GiveKeysOnSpawn and Keys and Keys.GiveKeys then
        Keys.GiveKeys(payload.plate, vehicle)
    end

    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetModelAsNoLongerNeeded(model)
    ClientUtils.Notify(Locale.vehicle_spawned, 'success')
end)
