Property = Property or {}

local function getIdentifier(source)
    return Bridge.GetIdentifier(source)
end

function Property.IsEnabled()
    return Config.Property and Config.Property.Enabled == true
end

function Property.PlayerOwnsGarage(identifier, garageId)
    if not identifier or not garageId then
        return false
    end

    return Database.PlayerOwnsGarage(identifier, garageId)
end

function Property.CanAccessGarage(source, garageId)
    local valid, reason = Security.ValidatePlayer(source)

    if not valid then
        return false, reason
    end

    local property = PropertyGarages.Get(garageId)

    if not property then
        return false, 'invalid_garage'
    end

    local identifier = getIdentifier(source)

    if not identifier then
        return false, 'missing_identifier'
    end

    if property.publicMode or (Config.Property and Config.Property.PublicMode) then
        return true, 'public_access', identifier
    end

    if Property.PlayerOwnsGarage(identifier, garageId) then
        return true, 'owner', identifier
    end

    if Bridge.HasPermission(source, Config.Admin.Permission) then
        return true, 'admin', identifier
    end

    return false, 'not_owner', identifier
end

function Property.GetDashboard(source)
    local identifier = getIdentifier(source)
    local owned = Database.GetOwnedGarages(identifier) or {}
    local ownedMap = {}
    local purchasable = {}
    local ownedList = {}

    for _, row in ipairs(owned) do
        ownedMap[row.garage_id] = row
    end

    for garageId, garage in pairs(PropertyGarages.GetAll()) do
        local runtime = ownedMap[garageId]
        local vehicleCap = garage.vehicleCapacity or 0
        local used = runtime and (runtime.used_slots or 0) or SlotManager.GetUsedCount(garageId, identifier)
        local enriched = PropertyGarages.Enrich(garageId, {
            owned = runtime ~= nil,
            active = runtime and runtime.active == 1,
            usedSlots = used,
            freeSlots = math.max(vehicleCap - used, 0),
            purchasePricePaid = runtime and runtime.purchase_price,
            purchasedAt = runtime and runtime.purchased_at,
            productionReady = PropertyGarages.IsProductionReady(garageId)
        })

        if runtime then
            ownedList[#ownedList + 1] = enriched
        elseif garage.purchaseEnabled ~= false then
            purchasable[#purchasable + 1] = enriched
        end
    end

    return {
        owned = ownedList,
        purchasable = purchasable,
        allowMultiple = Config.Property.AllowMultipleOwned,
        maxOwned = Config.Property.MaxOwnedGarages,
        publicMode = Config.Property.PublicMode
    }
end

function Property.BuyGarage(source, garageId)
    if not Property.IsEnabled() then
        return ServerUtils.Failure('property_disabled', Locale.property_disabled)
    end

    local validPlayer, playerReason = Security.ValidatePlayer(source)

    if not validPlayer then
        return ServerUtils.Failure(playerReason, Locale.invalid_player)
    end

    local identifier = getIdentifier(source)
    local property = PropertyGarages.Get(garageId)

    if not property then
        return ServerUtils.Failure('invalid_garage', Locale.invalid_garage)
    end

    if property.purchaseEnabled == false then
        return ServerUtils.Failure('purchase_disabled', Locale.purchase_disabled)
    end

    if Property.PlayerOwnsGarage(identifier, garageId) then
        return ServerUtils.Failure('already_owned', Locale.garage_already_owned)
    end

    local ownedCount = Database.CountOwnedGarages(identifier)

    if not Config.Property.AllowMultipleOwned and ownedCount > 0 then
        return ServerUtils.Failure('multiple_not_allowed', Locale.multiple_garages_denied)
    end

    if ownedCount >= (Config.Property.MaxOwnedGarages or 5) then
        return ServerUtils.Failure('max_garages', Locale.max_garages_reached)
    end

    local price = property.price or 0
    local account = Config.Property.PurchaseAccount or 'bank'

    if price > 0 and not Bridge.HasMoney(source, account, price) then
        return ServerUtils.Failure('not_enough_money', Locale.not_enough_money)
    end

    if price > 0 and not Bridge.RemoveMoney(source, account, price, ('w2f-garage purchase %s'):format(garageId)) then
        return ServerUtils.Failure('payment_failed', Locale.payment_failed)
    end

    local ok = Database.CreateOwnedGarage({
        garageId = garageId,
        ownerIdentifier = identifier,
        purchasePrice = price,
        interiorTemplate = property.interiorTemplate,
        propertyClass = property.propertyClass
    })

    if not ok then
        if price > 0 then
            Bridge.AddMoney(source, account, price, 'w2f-garage purchase rollback')
        end

        return ServerUtils.Failure('database_error', Locale.database_error)
    end

    Database.CreatePurchaseLog({
        garageId = garageId,
        ownerIdentifier = identifier,
        price = price,
        action = 'purchase'
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.GARAGE_PURCHASED, source, nil, garageId, {
        price = price,
        account = account
    })

    Bridge.Notify(source, Locale.garage_purchased:format(property.label), 'success')
    return ServerUtils.Success(PropertyGarages.Enrich(garageId, { owned = true }))
end

function Property.EnterGarage(source, garageId, floorIndex)
    local access, reason, identifier = Property.CanAccessGarage(source, garageId)

    if not access then
        return ServerUtils.Failure(reason, Locale.access_denied)
    end

    if reason ~= 'owner' and reason ~= 'admin' and reason ~= 'public_access' then
        if not Property.PlayerOwnsGarage(identifier, garageId) and not Config.Property.PublicMode then
            return ServerUtils.Failure('not_owner', Locale.access_denied)
        end
    end

    local property = PropertyGarages.Get(garageId)

    if property.enterEnabled == false then
        return ServerUtils.Failure('enter_disabled', Locale.enter_disabled)
    end

    local ok, data = ServerInteriors.Enter(source, garageId, identifier, floorIndex)

    if not ok then
        return ServerUtils.Failure(data, Locale.interior_not_ready)
    end

    return ServerUtils.Success(data)
end

function Property.ExitGarage(source, garageId)
    ServerInteriors.Exit(source, garageId)
    return ServerUtils.Success({ exited = true })
end

function Property.SpawnVehicle(source, garageId, plate, floorIndex)
    plate = ServerUtils.NormalizePlate(plate)
    local access, reason, identifier = Property.CanAccessGarage(source, garageId)

    if not access then
        return ServerUtils.Failure(reason, Locale.access_denied)
    end

    local slot = Database.GetGarageSlot(garageId, plate)

    if not slot or slot.owner_identifier ~= identifier then
        return ServerUtils.Failure('vehicle_not_in_garage', Locale.vehicle_not_in_garage)
    end

    if slot.state ~= W2F_GARAGE.VehicleStates.STORED then
        return ServerUtils.Failure('invalid_state', Locale.invalid_vehicle_state)
    end

    if VehicleState.IsOut(plate) then
        Logs.Security(source, W2F_GARAGE.LogActions.DUPLICATE_ATTEMPT, { plate = plate, garageId = garageId })
        return ServerUtils.Failure('vehicle_already_out', Locale.vehicle_out)
    end

    local property = PropertyGarages.Get(garageId)
    local spawnCoords = property.exteriorVehicleSpawn

    if PropertyGarages.IsTodoCoords(spawnCoords) then
        return ServerUtils.Failure('coords_not_ready', Locale.coords_not_ready)
    end

    Database.UpdateGarageSlotState(garageId, plate, W2F_GARAGE.VehicleStates.OUT)
    VehicleState.MarkOut(plate, garageId, source)

    Database.UpdateGarageSlotTimestamps(garageId, plate, { lastSpawnedAt = true })

    TriggerClientEvent(W2F_GARAGE.Events.InteriorRemoveDisplay, source, {
        garageId = garageId,
        plate = plate
    })

    TriggerClientEvent(W2F_GARAGE.Events.SpawnVehicle, source, {
        garageId = garageId,
        plate = plate,
        model = slot.model,
        coords = ServerUtils.VectorToTable(spawnCoords),
        props = slot.vehicle_props,
        fuel = slot.fuel,
        engineHealth = slot.engine_health,
        bodyHealth = slot.body_health,
        dirtLevel = slot.dirt_level
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.SPAWNED, source, plate, garageId)
    return ServerUtils.Success({ plate = plate, approved = true })
end

function Property.StoreVehicle(source, garageId, vehicleData)
    local access, reason, identifier = Property.CanAccessGarage(source, garageId)

    if not access then
        return ServerUtils.Failure(reason, Locale.access_denied)
    end

    if not Property.PlayerOwnsGarage(identifier, garageId) and not Config.Property.PublicMode then
        return ServerUtils.Failure('not_owner', Locale.access_denied)
    end

    local property = PropertyGarages.Get(garageId)

    if property.storeEnabled == false then
        return ServerUtils.Failure('store_disabled', Locale.store_disabled)
    end

    local plate = ServerUtils.NormalizePlate(vehicleData and vehicleData.plate)

    if not plate then
        return ServerUtils.Failure('invalid_plate', Locale.invalid_plate)
    end

    local ownership, ownershipReason = Security.ValidateVehicleOwnership(source, plate)

    if not ownership then
        return ServerUtils.Failure(ownershipReason, Locale.access_denied)
    end

    if VehicleState.IsOut(plate) == false and Database.GetGarageSlot(garageId, plate) then
        return ServerUtils.Failure('already_stored', Locale.already_stored)
    end

    local hasCapacity = SlotManager.HasCapacity(garageId, identifier, W2F_GARAGE.SlotTypes.VEHICLE)

    if not hasCapacity and not Database.GetGarageSlot(garageId, plate) then
        return ServerUtils.Failure('garage_full', Locale.garage_full)
    end

    local existing = Database.GetGarageSlot(garageId, plate)
    local slotResult

    if existing then
        Database.UpdateGarageSlotData(garageId, plate, vehicleData)
        slotResult = { slotIndex = existing.slot_index, floorIndex = existing.floor_index or 1 }
    else
        local ok, slot = SlotManager.AssignVehicle(garageId, identifier, plate, {
            model = vehicleData.model,
            vehicleProps = vehicleData.props,
            fuel = vehicleData.fuel,
            engineHealth = vehicleData.engineHealth,
            bodyHealth = vehicleData.bodyHealth,
            dirtLevel = vehicleData.dirtLevel,
            locked = vehicleData.locked,
            state = W2F_GARAGE.VehicleStates.STORED
        })

        if not ok then
            return ServerUtils.Failure(slot, Locale.garage_full)
        end

        slotResult = slot
    end

    VehicleState.MarkStored(plate, garageId, source)

    if Config.Features.SaveFuel and vehicleData.fuel then
        Database.SaveFuel(plate, vehicleData.fuel)
    end

    if Config.Features.SaveDamage then
        Database.SaveDamage(plate, {
            engine = vehicleData.engineHealth,
            body = vehicleData.bodyHealth,
            dirt = vehicleData.dirtLevel
        })
    end

    if Config.Features.SaveVehicleProperties and vehicleData.props then
        Database.SaveVehicleProperties(plate, vehicleData.props)
    end

    Database.UpdateGarageSlotTimestamps(garageId, plate, { lastStoredAt = true })

    TriggerClientEvent(W2F_GARAGE.Events.StoreVehicle, source, {
        garageId = garageId,
        plate = plate
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.STORED, source, plate, garageId, slotResult)
    return ServerUtils.Success({ plate = plate, slot = slotResult })
end

function Property.MoveVehicleSlot(source, garageId, plate, targetSlotIndex, floorIndex)
    plate = ServerUtils.NormalizePlate(plate)
    local access, _, identifier = Property.CanAccessGarage(source, garageId)

    if not access or not Property.PlayerOwnsGarage(identifier, garageId) then
        return ServerUtils.Failure('not_owner', Locale.access_denied)
    end

    local slot = Database.GetGarageSlot(garageId, plate)

    if not slot or slot.owner_identifier ~= identifier then
        return ServerUtils.Failure('vehicle_not_in_garage', Locale.vehicle_not_in_garage)
    end

    local occupied = Database.GetGarageSlotByIndex(garageId, identifier, targetSlotIndex, floorIndex or slot.floor_index)

    if occupied and occupied.plate ~= plate then
        return ServerUtils.Failure('slot_occupied', Locale.slot_occupied)
    end

    local ok = Database.UpdateGarageSlotIndex(garageId, plate, targetSlotIndex, floorIndex)

    if ok then
        Logs.GarageAction(W2F_GARAGE.LogActions.SLOT_MOVED, source, plate, garageId, {
            slotIndex = targetSlotIndex,
            floorIndex = floorIndex
        })
    end

    return ok and ServerUtils.Success({ plate = plate }) or ServerUtils.Failure('move_failed', Locale.move_failed)
end

function Property.GetGarageVehicles(source, garageId, floorIndex)
    local access, reason, identifier = Property.CanAccessGarage(source, garageId)

    if not access then
        return ServerUtils.Failure(reason, Locale.access_denied)
    end

    local vehicles = SlotManager.GetGarageVehicles(garageId, identifier, floorIndex)
    local property = PropertyGarages.Get(garageId)
    local vehicleCap = property and property.vehicleCapacity or 0
    local used = #vehicles

    return ServerUtils.Success({
        vehicles = vehicles,
        usedSlots = used,
        freeSlots = math.max(vehicleCap - used, 0),
        capacity = vehicleCap,
        floorIndex = floorIndex or 1,
        floors = property and property.floors
    })
end
