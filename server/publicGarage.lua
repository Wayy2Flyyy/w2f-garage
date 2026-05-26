PublicGarage = PublicGarage or {}

local function settings()
    return Config.PublicGarages or {}
end

function PublicGarage.IsEnabled()
    return settings().enabled == true
end

function PublicGarage.GetStoredTimestamp(record)
    if not record then
        return nil
    end

    if type(record.stored_at) == 'number' then
        return record.stored_at
    end

    if type(record.stored_at) == 'string' then
        return os.time()
    end

    return record.stored_at
end

function PublicGarage.CalculateBillableDays(storedAt, cfg)
    cfg = cfg or settings()

    if not storedAt then
        return 0
    end

    local now = os.time()
    local elapsed = math.max(0, now - storedAt)
    local hoursPerDay = cfg.realtimeDayHours or 24
    local secondsPerDay = hoursPerDay * 3600

    if cfg.chargeOnlyFullDays ~= false then
        return math.floor(elapsed / secondsPerDay)
    end

    return math.ceil(elapsed / secondsPerDay)
end

function PublicGarage.CalculateStorageFee(record, garageId)
    if not record or record.state ~= W2F_GARAGE.VehicleStates.STORED_PUBLIC then
        return 0, 0, 0
    end

    local cfg = settings()
    local storedAt = PublicGarage.GetStoredTimestamp(record)

    if type(storedAt) ~= 'number' then
        storedAt = os.time()
    end

    local dailyFee = record.daily_fee or BasicPublicGarages.GetDailyFee(garageId or record.garage_id)
    local days = PublicGarage.CalculateBillableDays(storedAt, cfg)
    local fee = days * dailyFee

    return fee, days, dailyFee
end

function PublicGarage.SyncUnpaidFee(record, garageId)
    local fee = PublicGarage.CalculateStorageFee(record, garageId)
    local plate = ServerUtils.NormalizePlate(record.plate)

    Database.SetPublicUnpaidFee(plate, fee, os.time())
    record.unpaid_fee = fee

    return fee
end

function PublicGarage.FormatVehicleForClient(record, garageId, locationLabel)
    local fee, days, dailyFee = PublicGarage.CalculateStorageFee(record, garageId)
    local storedAt = PublicGarage.GetStoredTimestamp(record) or os.time()
    local elapsed = math.max(0, os.time() - storedAt)
    local hours = math.floor(elapsed / 3600)

    return {
        plate = record.plate,
        model = record.model,
        garageId = record.garage_id,
        storedGarageLabel = locationLabel or record.garage_id,
        state = record.state,
        fuel = record.fuel,
        engineHealth = record.engine_health,
        bodyHealth = record.body_health,
        dirtLevel = record.dirt_level,
        storedAt = storedAt,
        storedForHours = hours,
        storedForDays = days,
        dailyFee = dailyFee,
        unpaidFee = fee,
        props = record.vehicle_props,
        canSpawn = fee <= 0 or not settings().requirePaymentBeforeSpawn
    }
end

function PublicGarage.GetGarageData(garageId)
    return ServerUtils.Success(BasicPublicGarages.Enrich(garageId))
end

function PublicGarage.GetVehicles(source, garageId)
    if not PublicGarage.IsEnabled() then
        return ServerUtils.Failure('public_disabled', Locale.public_disabled, { vehicles = {} })
    end

    local valid, reason = Security.ValidatePlayer(source)

    if not valid then
        return ServerUtils.Failure(reason, Locale.invalid_player, { vehicles = {} })
    end

    local identifier = Bridge.GetIdentifier(source)

    if not identifier then
        return ServerUtils.Failure('missing_identifier', Locale.invalid_player, { vehicles = {} })
    end

    if not BasicPublicGarages.Get(garageId) then
        return ServerUtils.Failure('invalid_garage', Locale.invalid_garage, { vehicles = {} })
    end

    local cfg = settings()
    local shared = cfg.sharedPublicStorage == true
    local rows = Database.GetPublicVehiclesByOwner(identifier, garageId, shared) or {}
    local vehicles = {}
    local totalFees = 0

    for _, row in ipairs(rows) do
        PublicGarage.SyncUnpaidFee(row, garageId)
        local location = BasicPublicGarages.Get(row.garage_id)
        local formatted = PublicGarage.FormatVehicleForClient(row, garageId, location and location.label)
        vehicles[#vehicles + 1] = formatted
        totalFees = totalFees + (formatted.unpaidFee or 0)
    end

    return ServerUtils.Success({
        vehicles = vehicles,
        garage = BasicPublicGarages.Enrich(garageId),
        unlimitedStorage = true,
        dailyVehicleFee = BasicPublicGarages.GetDailyFee(garageId),
        totalUnpaidFees = totalFees,
        sharedPublicStorage = shared
    })
end

function PublicGarage.StoreVehicle(source, garageId, vehicleData)
    if not PublicGarage.IsEnabled() then
        return ServerUtils.Failure('public_disabled', Locale.public_disabled)
    end

    local valid, reason = Security.ValidatePlayer(source)

    if not valid then
        return ServerUtils.Failure(reason, Locale.invalid_player)
    end

    if not BasicPublicGarages.Get(garageId) then
        return ServerUtils.Failure('invalid_garage', Locale.invalid_garage)
    end

    local plate = ServerUtils.NormalizePlate(vehicleData and vehicleData.plate)

    if not plate then
        return ServerUtils.Failure('invalid_plate', Locale.invalid_plate)
    end

    local ownership, ownershipReason = Security.ValidateVehicleOwnership(source, plate)

    if not ownership then
        return ServerUtils.Failure(ownershipReason, Locale.access_denied)
    end

    local existing = Database.GetPublicVehicle(plate)

    if existing and existing.state == W2F_GARAGE.VehicleStates.STORED_PUBLIC then
        return ServerUtils.Failure('already_stored', Locale.public_already_stored)
    end

    if VehicleState.IsOut(plate) then
        VehicleState.ActiveVehicles[plate] = nil
    end

    local identifier = Bridge.GetIdentifier(source)
    local now = os.time()
    local dailyFee = BasicPublicGarages.GetDailyFee(garageId)

    Database.UpsertPublicVehicle({
        plate = plate,
        ownerIdentifier = identifier,
        garageId = garageId,
        model = vehicleData.model,
        vehicleProps = vehicleData.props,
        fuel = vehicleData.fuel,
        engineHealth = vehicleData.engineHealth,
        bodyHealth = vehicleData.bodyHealth,
        dirtLevel = vehicleData.dirtLevel,
        state = W2F_GARAGE.VehicleStates.STORED_PUBLIC,
        storedAt = now,
        lastFeeCalculatedAt = now,
        unpaidFee = 0,
        dailyFee = dailyFee
    })

    VehicleState.ActiveVehicles[plate] = nil
    VehicleState.Set(plate, W2F_GARAGE.VehicleStates.STORED_PUBLIC, 'public_stored', source)

    TriggerClientEvent(W2F_GARAGE.Events.StoreVehicle, source, {
        garageId = garageId,
        plate = plate,
        garageType = 'public'
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_STORED, source, plate, garageId)
    Bridge.Notify(source, Locale.public_vehicle_stored, 'success')

    return ServerUtils.Success({ plate = plate, garageId = garageId })
end

function PublicGarage.ChargeFee(source, plate, fee)
    fee = math.floor(tonumber(fee) or 0)

    if fee <= 0 then
        return true, 0
    end

    local cfg = settings()
    local account = cfg.paymentAccount or 'bank'

    if cfg.allowNegativeBalance then
        Bridge.RemoveMoney(source, account, fee, 'w2f-garage public storage')
        return true, fee
    end

    if not Bridge.HasMoney(source, account, fee) then
        return false, 'not_enough_money'
    end

    if cfg.autoChargeOnSpawn ~= false then
        Bridge.RemoveMoney(source, account, fee, 'w2f-garage public storage')
    end

    return true, fee
end

function PublicGarage.SpawnVehicle(source, garageId, plate)
    if not PublicGarage.IsEnabled() then
        return ServerUtils.Failure('public_disabled', Locale.public_disabled)
    end

    plate = ServerUtils.NormalizePlate(plate)
    local valid, reason = Security.ValidatePlayer(source)

    if not valid then
        return ServerUtils.Failure(reason, Locale.invalid_player)
    end

    if not BasicPublicGarages.Get(garageId) or not plate then
        return ServerUtils.Failure('invalid_garage', Locale.invalid_garage)
    end

    local identifier = Bridge.GetIdentifier(source)
    local record = Database.GetPublicVehicle(plate)

    if not record or record.owner_identifier ~= identifier then
        return ServerUtils.Failure('not_owner', Locale.access_denied)
    end

    if record.state ~= W2F_GARAGE.VehicleStates.STORED_PUBLIC then
        return ServerUtils.Failure('invalid_state', Locale.invalid_vehicle_state)
    end

    local cfg = settings()

    if cfg.sharedPublicStorage ~= true and record.garage_id ~= garageId then
        return ServerUtils.Failure('wrong_garage', Locale.public_wrong_garage)
    end

    if VehicleState.IsOut(plate) then
        return ServerUtils.Failure('vehicle_already_out', Locale.vehicle_out)
    end

    local fee = PublicGarage.SyncUnpaidFee(record, garageId)

    if cfg.requirePaymentBeforeSpawn and fee > 0 then
        local paid, payReason = PublicGarage.ChargeFee(source, plate, fee)

        if not paid then
            return ServerUtils.Failure(payReason, Locale.not_enough_money, {
                unpaidFee = fee,
                plate = plate
            })
        end
    end

    local spawn = BasicPublicGarages.GetSpawn(garageId)

    if not spawn then
        return ServerUtils.Failure('invalid_spawn', Locale.invalid_garage)
    end

    local now = os.time()

    Database.UpdatePublicVehicleState(plate, W2F_GARAGE.VehicleStates.OUT, {
        unpaidFee = 0,
        lastFeeCalculatedAt = now,
        lastSpawnedAt = now,
        garageId = garageId
    })

    VehicleState.MarkOut(plate, garageId, source)

    TriggerClientEvent(W2F_GARAGE.Events.SpawnVehicle, source, {
        garageId = garageId,
        plate = plate,
        model = record.model,
        coords = ServerUtils.VectorToTable(spawn),
        props = record.vehicle_props,
        fuel = record.fuel,
        engineHealth = record.engine_health,
        bodyHealth = record.body_health,
        dirtLevel = record.dirt_level,
        garageType = 'public',
        feePaid = fee
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_SPAWNED, source, plate, garageId, { fee = fee })
    Bridge.Notify(source, fee > 0 and Locale.public_fee_paid:format(fee) or Locale.vehicle_spawned, 'success')

    return ServerUtils.Success({ plate = plate, approved = true, feePaid = fee })
end

function PublicGarage.PayStorageFee(source, garageId, plate)
    plate = ServerUtils.NormalizePlate(plate)
    local identifier = Bridge.GetIdentifier(source)
    local record = Database.GetPublicVehicle(plate)

    if not record or record.owner_identifier ~= identifier then
        return ServerUtils.Failure('not_owner', Locale.access_denied)
    end

    local fee = PublicGarage.SyncUnpaidFee(record, garageId)
    local paid, payReason = PublicGarage.ChargeFee(source, plate, fee)

    if not paid then
        return ServerUtils.Failure(payReason, Locale.not_enough_money)
    end

    Database.SetPublicUnpaidFee(plate, 0, os.time())
    Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_FEE_PAID, source, plate, garageId, { fee = fee })

    return ServerUtils.Success({ plate = plate, feePaid = fee })
end

function PublicGarage.AdminClearFee(plate)
    plate = ServerUtils.NormalizePlate(plate)
    Database.SetPublicUnpaidFee(plate, 0, os.time())
    return true
end

function PublicGarage.AdminSetFee(plate, amount)
    plate = ServerUtils.NormalizePlate(plate)
    Database.SetPublicUnpaidFee(plate, math.floor(tonumber(amount) or 0), os.time())
    return true
end

function PublicGarage.AdminGetFee(plate)
    plate = ServerUtils.NormalizePlate(plate)
    local record = Database.GetPublicVehicle(plate)

    if not record then
        return nil
    end

    return PublicGarage.CalculateStorageFee(record, record.garage_id)
end
