SlotManager = SlotManager or {}

local function normalizePlate(plate)
    return ServerUtils.NormalizePlate(plate)
end

function SlotManager.GetGarageCapacity(garageId)
    local property = PropertyGarages.Get(garageId)

    if property then
        return property.vehicleCapacity or 0, property.bicycleCapacity or 0
    end

    return 0, 0
end

function SlotManager.GetUsedCount(garageId, ownerIdentifier, slotType)
    if not Database.IsPropertyEnabled() then
        return 0
    end

    return Database.CountGarageSlots(garageId, ownerIdentifier, slotType)
end

function SlotManager.HasCapacity(garageId, ownerIdentifier, slotType)
    local vehicleCap, bicycleCap = SlotManager.GetGarageCapacity(garageId)
    local cap = slotType == W2F_GARAGE.SlotTypes.BICYCLE and bicycleCap or vehicleCap
    local used = SlotManager.GetUsedCount(garageId, ownerIdentifier, slotType)

    return used < cap, cap - used, cap
end

function SlotManager.FindEmptySlot(garageId, ownerIdentifier, options)
    options = options or {}
    local slotType = options.slotType or W2F_GARAGE.SlotTypes.VEHICLE
    local floorIndex = options.floorIndex or 1
    local hasCapacity, freeSlots = SlotManager.HasCapacity(garageId, ownerIdentifier, slotType)

    if not hasCapacity then
        return nil, 'garage_full'
    end

    local vehicleCap = select(1, SlotManager.GetGarageCapacity(garageId))
    local occupied = Database.GetOccupiedSlotIndexes(garageId, ownerIdentifier, floorIndex) or {}
    local occupiedMap = {}

    for _, index in ipairs(occupied) do
        occupiedMap[index] = true
    end

    local maxSlots = slotType == W2F_GARAGE.SlotTypes.BICYCLE
        and (PropertyGarages.Get(garageId) and PropertyGarages.Get(garageId).bicycleCapacity or 0)
        or vehicleCap

    for index = 1, maxSlots do
        if not occupiedMap[index] then
            return {
                slotIndex = index,
                floorIndex = floorIndex,
                slotType = slotType,
                freeSlots = freeSlots
            }
        end
    end

    return nil, 'no_slot_available'
end

function SlotManager.AssignVehicle(garageId, ownerIdentifier, plate, options)
    plate = normalizePlate(plate)
    options = options or {}

    if not plate then
        return false, 'invalid_plate'
    end

    if Database.PlateExistsInGarage(garageId, plate) then
        return false, 'duplicate_plate'
    end

    local slot, reason = SlotManager.FindEmptySlot(garageId, ownerIdentifier, options)

    if not slot then
        return false, reason
    end

    local saved = Database.AssignGarageSlot({
        garageId = garageId,
        ownerIdentifier = ownerIdentifier,
        plate = plate,
        slotIndex = options.slotIndex or slot.slotIndex,
        floorIndex = options.floorIndex or slot.floorIndex,
        slotType = options.slotType or slot.slotType,
        model = options.model,
        vehicleProps = options.vehicleProps,
        fuel = options.fuel,
        engineHealth = options.engineHealth,
        bodyHealth = options.bodyHealth,
        dirtLevel = options.dirtLevel,
        locked = options.locked,
        state = options.state or W2F_GARAGE.VehicleStates.STORED
    })

    if saved then
        Logs.GarageAction(W2F_GARAGE.LogActions.SLOT_ASSIGNED, 0, plate, garageId, slot)
    end

    return saved, saved and slot or reason
end

function SlotManager.RemoveVehicle(garageId, plate)
    plate = normalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    return Database.RemoveGarageSlot(garageId, plate)
end

function SlotManager.SwapSlots(garageId, ownerIdentifier, plateA, plateB)
    plateA = normalizePlate(plateA)
    plateB = normalizePlate(plateB)

    if not plateA or not plateB then
        return false, 'invalid_plate'
    end

    local slotA = Database.GetGarageSlot(garageId, plateA)
    local slotB = Database.GetGarageSlot(garageId, plateB)

    if not slotA or not slotB then
        return false, 'slot_not_found'
    end

    if slotA.owner_identifier ~= ownerIdentifier or slotB.owner_identifier ~= ownerIdentifier then
        return false, 'not_owner'
    end

    local ok = Database.SwapGarageSlots(garageId, plateA, plateB)

    if ok then
        Logs.GarageAction(W2F_GARAGE.LogActions.SLOT_MOVED, 0, plateA, garageId, {
            swappedWith = plateB
        })
    end

    return ok
end

function SlotManager.MoveToFloor(garageId, ownerIdentifier, plate, floorIndex)
    plate = normalizePlate(plate)
    local slot = Database.GetGarageSlot(garageId, plate)

    if not slot or slot.owner_identifier ~= ownerIdentifier then
        return false, 'slot_not_found'
    end

    return Database.UpdateGarageSlotFloor(garageId, plate, floorIndex)
end

function SlotManager.MoveToGarage(fromGarageId, toGarageId, ownerIdentifier, plate, options)
    plate = normalizePlate(plate)
    options = options or {}

    local existing = Database.GetGarageSlot(fromGarageId, plate)

    if not existing or existing.owner_identifier ~= ownerIdentifier then
        return false, 'slot_not_found'
    end

    local hasCapacity = SlotManager.HasCapacity(toGarageId, ownerIdentifier, existing.slot_type or W2F_GARAGE.SlotTypes.VEHICLE)

    if not hasCapacity then
        return false, 'garage_full'
    end

    local targetSlot = SlotManager.FindEmptySlot(toGarageId, ownerIdentifier, {
        slotType = existing.slot_type,
        floorIndex = options.floorIndex or 1
    })

    if not targetSlot then
        return false, 'no_slot_available'
    end

    Database.RemoveGarageSlot(fromGarageId, plate)

    return SlotManager.AssignVehicle(toGarageId, ownerIdentifier, plate, {
        slotIndex = targetSlot.slotIndex,
        floorIndex = targetSlot.floorIndex,
        slotType = existing.slot_type,
        model = existing.model,
        vehicleProps = existing.vehicle_props,
        fuel = existing.fuel,
        engineHealth = existing.engine_health,
        bodyHealth = existing.body_health,
        dirtLevel = existing.dirt_level,
        locked = existing.locked,
        state = existing.state
    })
end

function SlotManager.GetGarageVehicles(garageId, ownerIdentifier, floorIndex)
    return Database.GetGarageSlots(garageId, ownerIdentifier, floorIndex)
end

function SlotManager.BuildInteriorPayload(garageId, ownerIdentifier, floorIndex)
    local vehicles = SlotManager.GetGarageVehicles(garageId, ownerIdentifier, floorIndex) or {}
    local property = PropertyGarages.Get(garageId)
    local template = property and Interiors.Get(property.interiorTemplate) or nil
    local payload = {}

    for _, vehicle in ipairs(vehicles) do
        local coords = Interiors.GetSlotCoords(
            property and property.interiorTemplate,
            vehicle.slot_index,
            vehicle.floor_index or 1
        )

        payload[#payload + 1] = {
            plate = vehicle.plate,
            model = vehicle.model,
            slotIndex = vehicle.slot_index,
            floorIndex = vehicle.floor_index or 1,
            slotType = vehicle.slot_type,
            coords = coords,
            props = vehicle.vehicle_props,
            fuel = vehicle.fuel,
            engineHealth = vehicle.engine_health,
            bodyHealth = vehicle.body_health,
            dirtLevel = vehicle.dirt_level,
            locked = vehicle.locked == 1 or vehicle.locked == true,
            state = vehicle.state,
            coordsReady = coords ~= nil and not PropertyGarages.IsTodoCoords(coords)
        }
    end

    return payload, template
end
