Database = Database or {}

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
