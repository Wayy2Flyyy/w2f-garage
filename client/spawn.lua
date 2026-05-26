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
