VehicleState = VehicleState or {}
VehicleState.ActiveVehicles = VehicleState.ActiveVehicles or {}
VehicleState.MemoryStates = VehicleState.MemoryStates or {}

local validStates = {}

for _, state in pairs(W2F_GARAGE.VehicleStates) do
    validStates[state] = true
end

local function normalizePlate(plate)
    return ServerUtils.NormalizePlate(plate)
end

function VehicleState.IsValidState(state)
    return validStates[state] == true
end

function VehicleState.Get(plate)
    plate = normalizePlate(plate)

    if not plate then
        return W2F_GARAGE.VehicleStates.UNKNOWN
    end

    return VehicleState.MemoryStates[plate] or W2F_GARAGE.VehicleStates.UNKNOWN
end

function VehicleState.Set(plate, state, reason, source)
    plate = normalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    if not VehicleState.IsValidState(state) then
        state = W2F_GARAGE.VehicleStates.UNKNOWN
    end

    local previous = VehicleState.MemoryStates[plate]
    VehicleState.MemoryStates[plate] = state

    Database.UpdateVehicleState(plate, state, {
        reason = reason,
        source = source,
        previous = previous
    })

    Logs.GarageAction('state_changed', source, plate, nil, {
        from = previous,
        to = state,
        reason = reason
    })

    return true
end

function VehicleState.IsOut(plate)
    plate = normalizePlate(plate)

    if not plate then
        return false
    end

    return VehicleState.ActiveVehicles[plate] ~= nil or VehicleState.Get(plate) == W2F_GARAGE.VehicleStates.OUT
end

function VehicleState.CanSpawn(plate, garageId, source)
    if VehicleState.IsOut(plate) then
        return false, 'vehicle_already_out'
    end

    local valid, reason = Security.ValidateSpawnRequest(source, garageId, plate)

    if not valid then
        return false, reason
    end

    return true
end

function VehicleState.MarkOut(plate, garageId, source, netId)
    plate = normalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    VehicleState.ActiveVehicles[plate] = {
        source = source,
        garageId = garageId,
        netId = netId,
        markedAt = os.time()
    }

    VehicleState.Set(plate, W2F_GARAGE.VehicleStates.OUT, 'spawned', source)
    return true
end

function VehicleState.MarkStored(plate, garageId, source)
    plate = normalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    VehicleState.ActiveVehicles[plate] = nil
    VehicleState.Set(plate, W2F_GARAGE.VehicleStates.STORED, 'stored', source)
    Database.UpdateVehicleGarage(plate, garageId)
    return true
end

function VehicleState.MarkImpounded(plate, data, source)
    plate = normalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    VehicleState.ActiveVehicles[plate] = nil
    VehicleState.Set(plate, W2F_GARAGE.VehicleStates.IMPOUNDED, data and data.reason or 'impounded', source)
    Database.CreateImpoundRecord(data or { plate = plate })
    return true
end

function VehicleState.Recover(plate, reason, source)
    plate = normalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    VehicleState.ActiveVehicles[plate] = nil
    VehicleState.Set(plate, W2F_GARAGE.VehicleStates.STORED, reason or 'recovered', source)
    return true
end

function VehicleState.RestartRecovery()
    if not Config.RestartRecovery or not Config.RestartRecovery.Enabled then
        ServerUtils.Debug('Restart recovery is disabled.')
        return false
    end

    ServerUtils.Debug('Restart recovery placeholder reached; no destructive state changes were performed.')
    return true
end
