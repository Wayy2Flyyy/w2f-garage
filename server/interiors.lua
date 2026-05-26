ServerInteriors = ServerInteriors or {}
ServerInteriors.ActiveSessions = ServerInteriors.ActiveSessions or {}

local function sessionKey(source, garageId)
    return ('%s:%s'):format(source, garageId)
end

function ServerInteriors.GetBucket(garageId, ownerIdentifier)
    local property = PropertyGarages.Get(garageId)
    local templateId = property and property.interiorTemplate
    local instanceHash = joaat(('%s:%s'):format(garageId, ownerIdentifier or 'public'))
    local instanceId = math.abs(instanceHash) % 500

    return Interiors.GetRoutingBucket(templateId, instanceId)
end

function ServerInteriors.CanEnterInterior(garageId)
    if not Config.Property or not Config.Property.Enabled then
        return false, 'property_disabled'
    end

    local property = PropertyGarages.Get(garageId)

    if not property then
        return false, 'invalid_garage'
    end

    if property.interiorEnabled == false then
        return false, 'interior_disabled'
    end

    if Config.Property.RequireProductionCoords and not PropertyGarages.IsProductionReady(garageId) then
        return false, 'coords_not_ready'
    end

    return true
end

function ServerInteriors.Enter(source, garageId, ownerIdentifier, floorIndex)
    local canEnter, reason = ServerInteriors.CanEnterInterior(garageId)

    if not canEnter then
        return false, reason
    end

    floorIndex = floorIndex or 1
    local bucket = ServerInteriors.GetBucket(garageId, ownerIdentifier)

    if Config.Property.UseRoutingBuckets then
        SetPlayerRoutingBucket(source, bucket)
    end

    local vehicles, template = SlotManager.BuildInteriorPayload(garageId, ownerIdentifier, floorIndex)

    ServerInteriors.ActiveSessions[sessionKey(source, garageId)] = {
        source = source,
        garageId = garageId,
        ownerIdentifier = ownerIdentifier,
        floorIndex = floorIndex,
        bucket = bucket,
        enteredAt = os.time()
    }

    TriggerClientEvent(W2F_GARAGE.Events.PropertyEnter, source, {
        garageId = garageId,
        floorIndex = floorIndex,
        bucket = bucket,
        interiorTemplate = template and template.id or nil,
        vehicles = vehicles,
        coordsReady = PropertyGarages.IsProductionReady(garageId)
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.GARAGE_ENTER, source, nil, garageId, {
        floorIndex = floorIndex,
        bucket = bucket
    })

    return true, {
        bucket = bucket,
        vehicles = vehicles
    }
end

function ServerInteriors.Exit(source, garageId)
    local key = sessionKey(source, garageId)
    local session = ServerInteriors.ActiveSessions[key]

    if Config.Property.UseRoutingBuckets then
        SetPlayerRoutingBucket(source, 0)
    end

    ServerInteriors.ActiveSessions[key] = nil

    TriggerClientEvent(W2F_GARAGE.Events.PropertyExit, source, {
        garageId = garageId
    })

    TriggerClientEvent(W2F_GARAGE.Events.InteriorUnloadVehicles, source, {
        garageId = garageId
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.GARAGE_EXIT, source, nil, garageId, session)
    return true
end

function ServerInteriors.OnPlayerDropped(source)
    for key, session in pairs(ServerInteriors.ActiveSessions) do
        if session.source == source then
            ServerInteriors.ActiveSessions[key] = nil
        end
    end
end

AddEventHandler('playerDropped', function()
    ServerInteriors.OnPlayerDropped(source)
end)
