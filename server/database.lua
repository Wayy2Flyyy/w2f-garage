Database = Database or {}


function Database.ApplyPreset()
    if not Config or not Config.Database then
        return false
    end

    local presetName = Config.Database.Preset or 'auto'

    if presetName == 'custom' then
        if Config.Debug then
            ServerUtils.Debug('Database preset is custom; preserving manual mappings.')
        end
        return true
    end

    if presetName == 'auto' then
        local framework = Bridge and Bridge.ActiveFramework or 'none'
        if framework == 'qbox' then
            presetName = 'qbox'
        elseif framework == 'qbcore' then
            presetName = 'qbcore'
        elseif framework == 'esx' then
            presetName = 'esx'
        else
            if Config.Debug then
                ServerUtils.Debug('Database preset auto-detect failed; no framework preset applied.', { framework = framework })
            end
            return false
        end
    end

    local preset = Config.Database.Presets and Config.Database.Presets[presetName]
    if not preset then
        if Config.Debug then
            ServerUtils.Debug('Database preset not found.', { preset = presetName })
        end
        return false
    end

    Config.Database.ExistingVehicleTable = preset.table
    Config.Database.Columns = Config.Database.Columns or {}
    Config.Database.Columns.owner = preset.owner
    Config.Database.Columns.plate = preset.plate
    Config.Database.Columns.vehicle = preset.vehicle
    Config.Database.Columns.properties = preset.properties
    Config.Database.Columns.garage = preset.garage
    Config.Database.Columns.state = preset.state
    Config.Database.Columns.fuel = preset.fuel
    Config.Database.Columns.engine = preset.engine
    Config.Database.Columns.body = preset.body

    if Config.Debug then
        ServerUtils.Debug('Applied database preset.', { preset = presetName, table = preset.table })
    end

    return true
end

Database.ApplyPreset()

local function enabled()
    return Config.Database and Config.Database.Enabled == true
end

local function safeMode()
    return not Config.Database or Config.Database.SafeMode ~= false
end

local function hasOxMySQL()
    return MySQL and MySQL.query and MySQL.query.await
end

local function tableName()
    return Config.Database and Config.Database.ExistingVehicleTable
end

local function column(name)
    return Config.Database and Config.Database.Columns and Config.Database.Columns[name]
end

local function canReadOwnership()
    return enabled()
        and hasOxMySQL()
        and type(tableName()) == 'string'
        and type(column('owner')) == 'string'
        and type(column('plate')) == 'string'
end

local function encode(value)
    if value == nil then
        return nil
    end

    if type(value) == 'string' then
        return value
    end

    return json and json.encode(value) or nil
end

function Database.IsSafeMode()
    return safeMode()
end

function Database.IsPropertyEnabled()
    return Config.Property and Config.Property.Enabled == true
end

function Database.UsePropertyPersistence()
    return Database.IsPropertyEnabled() and enabled() and hasOxMySQL() and not safeMode()
end

local function propertyTables()
    local tables = Config.Database.W2FTables
    return {
        owned = tables.ownedGarages or 'w2f_owned_garages',
        slots = tables.garageSlots or 'w2f_garage_slots',
        interiors = tables.garageInteriors or 'w2f_garage_interiors',
        positions = tables.garageVehiclePositions or 'w2f_garage_vehicle_positions',
        purchaseLogs = tables.purchaseLogs or 'w2f_garage_purchase_logs'
    }
end

function Database.GetPlayerVehicles(identifier, options)
    options = options or {}

    if not canReadOwnership() then
        ServerUtils.Debug('GetPlayerVehicles returned empty data because database mappings are not configured.')
        return {}
    end

    local garageColumn = column('garage')
    local stateColumn = column('state')
    local vehicleColumn = column('vehicle')
    local fuelColumn = column('fuel')
    local query = ('SELECT * FROM `%s` WHERE `%s` = ?'):format(tableName(), column('owner'))
    local params = { identifier }

    if options.garageId and garageColumn then
        query = query .. (' AND `%s` = ?'):format(garageColumn)
        params[#params + 1] = options.garageId
    end

    local rows = MySQL.query.await(query, params) or {}
    local vehicles = {}

    for _, row in ipairs(rows) do
        vehicles[#vehicles + 1] = {
            owner = row[column('owner')],
            plate = row[column('plate')],
            model = vehicleColumn and row[vehicleColumn] or 'unknown',
            garage = garageColumn and row[garageColumn] or options.garageId,
            state = stateColumn and row[stateColumn] or W2F_GARAGE.VehicleStates.UNKNOWN,
            fuel = fuelColumn and row[fuelColumn] or 0,
            raw = row
        }
    end

    return vehicles
end

function Database.GetVehiclesByGarage(identifier, garageId)
    return Database.GetPlayerVehicles(identifier, { garageId = garageId })
end

function Database.GetVehicleByPlate(plate)
    plate = ServerUtils.NormalizePlate(plate)

    if not plate or not canReadOwnership() then
        return nil
    end

    local query = ('SELECT * FROM `%s` WHERE `%s` = ? LIMIT 1'):format(tableName(), column('plate'))
    return MySQL.single.await(query, { plate })
end

function Database.UpdateVehicleState(plate, state, metadata)
    if safeMode() or not enabled() or not hasOxMySQL() then
        ServerUtils.Debug('UpdateVehicleState skipped in safe mode.', { plate = plate, state = state })
        return false
    end

    local tables = Config.Database.W2FTables
    local query = ('INSERT INTO `%s` (`plate`, `state`, `updated_at`) VALUES (?, ?, CURRENT_TIMESTAMP) ON DUPLICATE KEY UPDATE `state` = VALUES(`state`), `updated_at` = CURRENT_TIMESTAMP'):format(tables.stateOverrides)
    local affected = MySQL.update.await(query, { plate, state })

    Database.SaveVehicleHistory({
        plate = plate,
        toState = state,
        reason = metadata and metadata.reason or nil,
        metadata = metadata
    })

    return (affected or 0) > 0
end

function Database.UpdateVehicleGarage(plate, garageId)
    if safeMode() or not enabled() or not hasOxMySQL() then
        ServerUtils.Debug('UpdateVehicleGarage skipped in safe mode.', { plate = plate, garageId = garageId })
        return false
    end

    local query = ('UPDATE `%s` SET `garage_id` = ?, `updated_at` = CURRENT_TIMESTAMP WHERE `plate` = ?'):format(Config.Database.W2FTables.stateOverrides)
    return (MySQL.update.await(query, { garageId, plate }) or 0) > 0
end

function Database.SaveVehicleProperties(plate, properties)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('UPDATE `%s` SET `vehicle_properties` = ?, `updated_at` = CURRENT_TIMESTAMP WHERE `plate` = ?'):format(Config.Database.W2FTables.stateOverrides)
    return (MySQL.update.await(query, { encode(properties), plate }) or 0) > 0
end

function Database.SaveFuel(plate, fuel)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('UPDATE `%s` SET `fuel` = ?, `updated_at` = CURRENT_TIMESTAMP WHERE `plate` = ?'):format(Config.Database.W2FTables.stateOverrides)
    return (MySQL.update.await(query, { fuel, plate }) or 0) > 0
end

function Database.SaveDamage(plate, damage)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('UPDATE `%s` SET `engine_health` = ?, `body_health` = ?, `dirt_level` = ?, `updated_at` = CURRENT_TIMESTAMP WHERE `plate` = ?'):format(Config.Database.W2FTables.stateOverrides)
    return (MySQL.update.await(query, { damage.engine, damage.body, damage.dirt, plate }) or 0) > 0
end

function Database.SaveLastLocation(plate, location)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('UPDATE `%s` SET `last_location` = ?, `updated_at` = CURRENT_TIMESTAMP WHERE `plate` = ?'):format(Config.Database.W2FTables.stateOverrides)
    return (MySQL.update.await(query, { encode(location), plate }) or 0) > 0
end

function Database.CreateGarageLog(entry)
    if not enabled() or safeMode() or not hasOxMySQL() then
        return true
    end

    local query = ('INSERT INTO `%s` (`action`, `player_identifier`, `player_name`, `plate`, `vehicle_model`, `garage_id`, `details`) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(Config.Database.W2FTables.logs)

    MySQL.insert.await(query, {
        entry.action,
        entry.identifier,
        entry.playerName,
        entry.plate,
        entry.vehicleModel,
        entry.garageId,
        encode(entry.details)
    })

    return true
end

function Database.CreateImpoundRecord(entry)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('INSERT INTO `%s` (`plate`, `owner_identifier`, `garage_id`, `fee`, `reason`, `status`, `impounded_by`) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(Config.Database.W2FTables.impounds)
    return MySQL.insert.await(query, {
        entry.plate,
        entry.ownerIdentifier,
        entry.garageId,
        entry.fee or 0,
        entry.reason,
        entry.status or 'active',
        entry.impoundedBy
    }) ~= nil
end

function Database.UpdateImpoundStatus(plate, status)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('UPDATE `%s` SET `status` = ?, `released_at` = CURRENT_TIMESTAMP WHERE `plate` = ? AND `status` = "active"'):format(Config.Database.W2FTables.impounds)
    return (MySQL.update.await(query, { status, plate }) or 0) > 0
end

function Database.SaveFavouriteVehicle(identifier, plate, favourite)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return false
    end

    local query = ('INSERT INTO `%s` (`owner_identifier`, `plate`, `favourite`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `favourite` = VALUES(`favourite`)'):format(Config.Database.W2FTables.favourites)
    return (MySQL.update.await(query, { identifier, plate, favourite and 1 or 0 }) or 0) > 0
end

function Database.SaveVehicleHistory(entry)
    if safeMode() or not enabled() or not hasOxMySQL() then
        return true
    end

    local query = ('INSERT INTO `%s` (`plate`, `owner_identifier`, `from_state`, `to_state`, `garage_id`, `reason`, `metadata`) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(Config.Database.W2FTables.history)

    MySQL.insert.await(query, {
        entry.plate,
        entry.ownerIdentifier,
        entry.fromState,
        entry.toState,
        entry.garageId,
        entry.reason,
        encode(entry.metadata)
    })

    return true
end

-- Property garage tables (in-memory fallback when DB disabled or safe mode)
Database._memoryOwned = Database._memoryOwned or {}
Database._memorySlots = Database._memorySlots or {}

local function memoryOwnedKey(identifier, garageId)
    return ('%s:%s'):format(identifier, garageId)
end

function Database.PlayerOwnsGarage(identifier, garageId)
    if not identifier or not garageId then
        return false
    end

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        local row = MySQL.single.await(
            ('SELECT `id` FROM `%s` WHERE `owner_identifier` = ? AND `garage_id` = ? AND `active` = 1 LIMIT 1'):format(tables.owned),
            { identifier, garageId }
        )
        return row ~= nil
    end

    return Database._memoryOwned[memoryOwnedKey(identifier, garageId)] ~= nil
end

function Database.GetOwnedGarages(identifier)
    if not identifier then
        return {}
    end

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return MySQL.query.await(
            ('SELECT * FROM `%s` WHERE `owner_identifier` = ? AND `active` = 1'):format(tables.owned),
            { identifier }
        ) or {}
    end

    local rows = {}

    for _, row in pairs(Database._memoryOwned) do
        if row.owner_identifier == identifier then
            rows[#rows + 1] = row
        end
    end

    return rows
end

function Database.CountOwnedGarages(identifier)
    return #(Database.GetOwnedGarages(identifier) or {})
end

function Database.CreateOwnedGarage(entry)
    entry = entry or {}

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        local id = MySQL.insert.await(
            ('INSERT INTO `%s` (`garage_id`, `owner_identifier`, `purchase_price`, `interior_template`, `property_class`, `active`) VALUES (?, ?, ?, ?, ?, 1)'):format(tables.owned),
            {
                entry.garageId,
                entry.ownerIdentifier,
                entry.purchasePrice or 0,
                entry.interiorTemplate,
                entry.propertyClass
            }
        )
        return id ~= nil
    end

    Database._memoryOwned[memoryOwnedKey(entry.ownerIdentifier, entry.garageId)] = {
        garage_id = entry.garageId,
        owner_identifier = entry.ownerIdentifier,
        purchase_price = entry.purchasePrice or 0,
        interior_template = entry.interiorTemplate,
        property_class = entry.propertyClass,
        active = 1,
        used_slots = 0,
        purchased_at = os.time()
    }

    return true
end

function Database.RemoveOwnedGarage(identifier, garageId)
    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return (MySQL.update.await(
            ('UPDATE `%s` SET `active` = 0 WHERE `owner_identifier` = ? AND `garage_id` = ?'):format(tables.owned),
            { identifier, garageId }
        ) or 0) > 0
    end

    Database._memoryOwned[memoryOwnedKey(identifier, garageId)] = nil
    return true
end

function Database.CreatePurchaseLog(entry)
    if not Database.UsePropertyPersistence() then
        return true
    end

    local tables = propertyTables()
    MySQL.insert.await(
        ('INSERT INTO `%s` (`garage_id`, `owner_identifier`, `price`, `action`) VALUES (?, ?, ?, ?)'):format(tables.purchaseLogs),
        { entry.garageId, entry.ownerIdentifier, entry.price or 0, entry.action or 'purchase' }
    )

    return true
end

function Database.GetGarageSlots(garageId, ownerIdentifier, floorIndex)
    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        local query = ('SELECT * FROM `%s` WHERE `garage_id` = ? AND `owner_identifier` = ?'):format(tables.slots)
        local params = { garageId, ownerIdentifier }

        if floorIndex then
            query = query .. ' AND `floor_index` = ?'
            params[#params + 1] = floorIndex
        end

        return MySQL.query.await(query, params) or {}
    end

    local rows = {}

    for _, slot in pairs(Database._memorySlots) do
        if slot.garage_id == garageId and slot.owner_identifier == ownerIdentifier then
            if not floorIndex or (slot.floor_index or 1) == floorIndex then
                rows[#rows + 1] = slot
            end
        end
    end

    return rows
end

function Database.GetGarageSlot(garageId, plate)
    plate = ServerUtils.NormalizePlate(plate)

    if not plate then
        return nil
    end

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return MySQL.single.await(
            ('SELECT * FROM `%s` WHERE `garage_id` = ? AND `plate` = ? LIMIT 1'):format(tables.slots),
            { garageId, plate }
        )
    end

    for _, slot in pairs(Database._memorySlots) do
        if slot.garage_id == garageId and slot.plate == plate then
            return slot
        end
    end

    return nil
end

function Database.GetGarageSlotByIndex(garageId, ownerIdentifier, slotIndex, floorIndex)
    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return MySQL.single.await(
            ('SELECT * FROM `%s` WHERE `garage_id` = ? AND `owner_identifier` = ? AND `slot_index` = ? AND `floor_index` = ? LIMIT 1'):format(tables.slots),
            { garageId, ownerIdentifier, slotIndex, floorIndex or 1 }
        )
    end

    for _, slot in pairs(Database._memorySlots) do
        if slot.garage_id == garageId
            and slot.owner_identifier == ownerIdentifier
            and slot.slot_index == slotIndex
            and (slot.floor_index or 1) == (floorIndex or 1) then
            return slot
        end
    end

    return nil
end

function Database.GetOccupiedSlotIndexes(garageId, ownerIdentifier, floorIndex)
    local slots = Database.GetGarageSlots(garageId, ownerIdentifier, floorIndex) or {}
    local indexes = {}

    for _, slot in ipairs(slots) do
        indexes[#indexes + 1] = slot.slot_index
    end

    return indexes
end

function Database.CountGarageSlots(garageId, ownerIdentifier, slotType)
    local slots = Database.GetGarageSlots(garageId, ownerIdentifier) or {}
    local count = 0

    for _, slot in ipairs(slots) do
        if not slotType or slot.slot_type == slotType then
            count = count + 1
        end
    end

    return count
end

function Database.PlateExistsInGarage(garageId, plate)
    return Database.GetGarageSlot(garageId, plate) ~= nil
end

function Database.AssignGarageSlot(entry)
    entry.plate = ServerUtils.NormalizePlate(entry.plate)

    if not entry.plate then
        return false
    end

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        local props = encode(entry.vehicleProps)
        MySQL.insert.await(
            ('INSERT INTO `%s` (`garage_id`, `owner_identifier`, `plate`, `model`, `slot_index`, `floor_index`, `slot_type`, `vehicle_props`, `fuel`, `engine_health`, `body_health`, `dirt_level`, `locked`, `state`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(tables.slots),
            {
                entry.garageId,
                entry.ownerIdentifier,
                entry.plate,
                entry.model,
                entry.slotIndex,
                entry.floorIndex or 1,
                entry.slotType or W2F_GARAGE.SlotTypes.VEHICLE,
                props,
                entry.fuel,
                entry.engineHealth,
                entry.bodyHealth,
                entry.dirtLevel,
                entry.locked and 1 or 0,
                entry.state or W2F_GARAGE.VehicleStates.STORED
            }
        )
        return true
    end

    Database._memorySlots[entry.plate] = {
        garage_id = entry.garageId,
        owner_identifier = entry.ownerIdentifier,
        plate = entry.plate,
        model = entry.model,
        slot_index = entry.slotIndex,
        floor_index = entry.floorIndex or 1,
        slot_type = entry.slotType or W2F_GARAGE.SlotTypes.VEHICLE,
        vehicle_props = entry.vehicleProps,
        fuel = entry.fuel,
        engine_health = entry.engineHealth,
        body_health = entry.bodyHealth,
        dirt_level = entry.dirtLevel,
        locked = entry.locked,
        state = entry.state or W2F_GARAGE.VehicleStates.STORED
    }

    return true
end

function Database.RemoveGarageSlot(garageId, plate)
    plate = ServerUtils.NormalizePlate(plate)

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return (MySQL.update.await(
            ('DELETE FROM `%s` WHERE `garage_id` = ? AND `plate` = ?'):format(tables.slots),
            { garageId, plate }
        ) or 0) > 0
    end

    Database._memorySlots[plate] = nil
    return true
end

function Database.UpdateGarageSlotState(garageId, plate, state)
    plate = ServerUtils.NormalizePlate(plate)

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return (MySQL.update.await(
            ('UPDATE `%s` SET `state` = ? WHERE `garage_id` = ? AND `plate` = ?'):format(tables.slots),
            { state, garageId, plate }
        ) or 0) > 0
    end

    local slot = Database._memorySlots[plate]

    if slot then
        slot.state = state
        return true
    end

    return false
end

function Database.UpdateGarageSlotData(garageId, plate, data)
    plate = ServerUtils.NormalizePlate(plate)

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return (MySQL.update.await(
            ('UPDATE `%s` SET `model` = ?, `vehicle_props` = ?, `fuel` = ?, `engine_health` = ?, `body_health` = ?, `dirt_level` = ?, `locked` = ?, `state` = ? WHERE `garage_id` = ? AND `plate` = ?'):format(tables.slots),
            {
                data.model,
                encode(data.props),
                data.fuel,
                data.engineHealth,
                data.bodyHealth,
                data.dirtLevel,
                data.locked and 1 or 0,
                W2F_GARAGE.VehicleStates.STORED,
                garageId,
                plate
            }
        ) or 0) > 0
    end

    local slot = Database._memorySlots[plate]

    if slot then
        slot.model = data.model or slot.model
        slot.vehicle_props = data.props or slot.vehicle_props
        slot.fuel = data.fuel or slot.fuel
        slot.engine_health = data.engineHealth or slot.engine_health
        slot.body_health = data.bodyHealth or slot.body_health
        slot.dirt_level = data.dirtLevel or slot.dirt_level
        slot.state = W2F_GARAGE.VehicleStates.STORED
        return true
    end

    return false
end

function Database.UpdateGarageSlotIndex(garageId, plate, slotIndex, floorIndex)
    plate = ServerUtils.NormalizePlate(plate)

    if Database.UsePropertyPersistence() then
        local tables = propertyTables()
        return (MySQL.update.await(
            ('UPDATE `%s` SET `slot_index` = ?, `floor_index` = ? WHERE `garage_id` = ? AND `plate` = ?'):format(tables.slots),
            { slotIndex, floorIndex or 1, garageId, plate }
        ) or 0) > 0
    end

    local slot = Database._memorySlots[plate]

    if slot then
        slot.slot_index = slotIndex
        slot.floor_index = floorIndex or slot.floor_index
        return true
    end

    return false
end

function Database.UpdateGarageSlotFloor(garageId, plate, floorIndex)
    local slot = Database.GetGarageSlot(garageId, plate)

    if not slot then
        return false
    end

    return Database.UpdateGarageSlotIndex(garageId, plate, slot.slot_index, floorIndex)
end

function Database.SwapGarageSlots(garageId, plateA, plateB)
    local slotA = Database.GetGarageSlot(garageId, plateA)
    local slotB = Database.GetGarageSlot(garageId, plateB)

    if not slotA or not slotB then
        return false
    end

    Database.UpdateGarageSlotIndex(garageId, plateA, slotB.slot_index, slotB.floor_index)
    Database.UpdateGarageSlotIndex(garageId, plateB, slotA.slot_index, slotA.floor_index)
    return true
end

function Database.UpdateGarageSlotTimestamps(garageId, plate, flags)
    if not Database.UsePropertyPersistence() then
        return true
    end

    local tables = propertyTables()
    local sets = {}

    if flags.lastStoredAt then
        sets[#sets + 1] = '`last_stored_at` = CURRENT_TIMESTAMP'
    end

    if flags.lastSpawnedAt then
        sets[#sets + 1] = '`last_spawned_at` = CURRENT_TIMESTAMP'
    end

    if #sets == 0 then
        return true
    end

    MySQL.update.await(
        ('UPDATE `%s` SET %s WHERE `garage_id` = ? AND `plate` = ?'):format(tables.slots, table.concat(sets, ', ')),
        { garageId, plate }
    )

    return true
end

-- Public garage storage (separate from property garages)
Database._memoryPublic = Database._memoryPublic or {}

local function publicTable()
    return Config.Database.W2FTables.publicGarageVehicles or 'w2f_public_garage_vehicles'
end

function Database.UsePublicPersistence()
    return Config.PublicGarages and Config.PublicGarages.enabled
        and enabled()
        and hasOxMySQL()
        and not safeMode()
end

function Database.GetPublicVehicle(plate)
    plate = ServerUtils.NormalizePlate(plate)

    if not plate then
        return nil
    end

    if Database.UsePublicPersistence() then
        return MySQL.single.await(
            ('SELECT * FROM `%s` WHERE `plate` = ? LIMIT 1'):format(publicTable()),
            { plate }
        )
    end

    return Database._memoryPublic[plate]
end

function Database.GetPublicVehiclesByOwner(identifier, garageId, sharedStorage)
    if not identifier then
        return {}
    end

    if Database.UsePublicPersistence() then
        local query = ('SELECT * FROM `%s` WHERE `owner_identifier` = ? AND `state` = ?'):format(publicTable())
        local params = { identifier, W2F_GARAGE.VehicleStates.STORED_PUBLIC }

        if not sharedStorage and garageId then
            query = query .. ' AND `garage_id` = ?'
            params[#params + 1] = garageId
        end

        return MySQL.query.await(query, params) or {}
    end

    local rows = {}

    for _, row in pairs(Database._memoryPublic) do
        if row.owner_identifier == identifier and row.state == W2F_GARAGE.VehicleStates.STORED_PUBLIC then
            if sharedStorage or not garageId or row.garage_id == garageId then
                rows[#rows + 1] = row
            end
        end
    end

    return rows
end

function Database.UpsertPublicVehicle(entry)
    entry.plate = ServerUtils.NormalizePlate(entry.plate)

    if not entry.plate then
        return false
    end

    local now = os.time()

    if Database.UsePublicPersistence() then
        MySQL.insert.await(
            ([[INSERT INTO `%s`
                (`plate`, `owner_identifier`, `garage_id`, `garage_type`, `model`, `vehicle_props`, `fuel`, `engine_health`, `body_health`, `dirt_level`, `state`, `stored_at`, `last_fee_calculated_at`, `unpaid_fee`, `daily_fee`, `paid_until`)
              VALUES (?, ?, ?, 'public', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE
                `owner_identifier` = VALUES(`owner_identifier`),
                `garage_id` = VALUES(`garage_id`),
                `model` = VALUES(`model`),
                `vehicle_props` = VALUES(`vehicle_props`),
                `fuel` = VALUES(`fuel`),
                `engine_health` = VALUES(`engine_health`),
                `body_health` = VALUES(`body_health`),
                `dirt_level` = VALUES(`dirt_level`),
                `state` = VALUES(`state`),
                `stored_at` = VALUES(`stored_at`),
                `last_fee_calculated_at` = VALUES(`last_fee_calculated_at`),
                `unpaid_fee` = VALUES(`unpaid_fee`),
                `daily_fee` = VALUES(`daily_fee`),
                `paid_until` = VALUES(`paid_until`)]]):format(publicTable()),
            {
                entry.plate,
                entry.ownerIdentifier,
                entry.garageId,
                entry.model,
                encode(entry.vehicleProps),
                entry.fuel,
                entry.engineHealth,
                entry.bodyHealth,
                entry.dirtLevel,
                entry.state or W2F_GARAGE.VehicleStates.STORED_PUBLIC,
                entry.storedAt or now,
                entry.lastFeeCalculatedAt or now,
                entry.unpaidFee or 0,
                entry.dailyFee or 700,
                entry.paidUntil
            }
        )

        return true
    end

    Database._memoryPublic[entry.plate] = {
        plate = entry.plate,
        owner_identifier = entry.ownerIdentifier,
        garage_id = entry.garageId,
        garage_type = 'public',
        model = entry.model,
        vehicle_props = entry.vehicleProps,
        fuel = entry.fuel,
        engine_health = entry.engineHealth,
        body_health = entry.bodyHealth,
        dirt_level = entry.dirtLevel,
        state = entry.state or W2F_GARAGE.VehicleStates.STORED_PUBLIC,
        stored_at = entry.storedAt or now,
        last_fee_calculated_at = entry.lastFeeCalculatedAt or now,
        unpaid_fee = entry.unpaidFee or 0,
        daily_fee = entry.dailyFee or 700,
        paid_until = entry.paidUntil,
        last_spawned_at = entry.lastSpawnedAt
    }

    return true
end

function Database.UpdatePublicVehicleState(plate, state, extra)
    plate = ServerUtils.NormalizePlate(plate)
    extra = extra or {}

    if Database.UsePublicPersistence() then
        local querySets = { '`state` = ?' }
        local params = { state }

        if extra.unpaidFee ~= nil then
            querySets[#querySets + 1] = '`unpaid_fee` = ?'
            params[#params + 1] = extra.unpaidFee
        end

        if extra.lastFeeCalculatedAt then
            querySets[#querySets + 1] = '`last_fee_calculated_at` = ?'
            params[#params + 1] = extra.lastFeeCalculatedAt
        end

        if extra.paidUntil then
            querySets[#querySets + 1] = '`paid_until` = ?'
            params[#params + 1] = extra.paidUntil
        end

        if extra.lastSpawnedAt then
            querySets[#querySets + 1] = '`last_spawned_at` = ?'
            params[#params + 1] = extra.lastSpawnedAt
        end

        if extra.garageId then
            querySets[#querySets + 1] = '`garage_id` = ?'
            params[#params + 1] = extra.garageId
        end

        params[#params + 1] = plate

        return (MySQL.update.await(
            ('UPDATE `%s` SET %s WHERE `plate` = ?'):format(publicTable(), table.concat(querySets, ', ')),
            params
        ) or 0) > 0
    end

    local row = Database._memoryPublic[plate]

    if not row then
        return false
    end

    row.state = state

    if extra.unpaidFee ~= nil then
        row.unpaid_fee = extra.unpaidFee
    end

    if extra.lastFeeCalculatedAt then
        row.last_fee_calculated_at = extra.lastFeeCalculatedAt
    end

    if extra.paidUntil then
        row.paid_until = extra.paidUntil
    end

    if extra.lastSpawnedAt then
        row.last_spawned_at = extra.lastSpawnedAt
    end

    return true
end

function Database.SetPublicUnpaidFee(plate, fee, lastCalculatedAt, paidUntil)
    plate = ServerUtils.NormalizePlate(plate)
    lastCalculatedAt = lastCalculatedAt or os.time()

    if Database.UsePublicPersistence() then
        return (MySQL.update.await(
            ('UPDATE `%s` SET `unpaid_fee` = ?, `last_fee_calculated_at` = ?, `paid_until` = COALESCE(?, `paid_until`) WHERE `plate` = ?'):format(publicTable()),
            { fee, lastCalculatedAt, paidUntil, plate }
        ) or 0) > 0
    end

    local row = Database._memoryPublic[plate]

    if row then
        row.unpaid_fee = fee
        row.last_fee_calculated_at = lastCalculatedAt
        if paidUntil then
            row.paid_until = paidUntil
        end
        return true
    end

    return false
end

function Database.DeletePublicVehicle(plate)
    plate = ServerUtils.NormalizePlate(plate)

    if Database.UsePublicPersistence() then
        return (MySQL.update.await(
            ('DELETE FROM `%s` WHERE `plate` = ?'):format(publicTable()),
            { plate }
        ) or 0) > 0
    end

    Database._memoryPublic[plate] = nil
    return true
end
