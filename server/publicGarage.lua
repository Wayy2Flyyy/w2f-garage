PublicGarage = PublicGarage or {}

local function settings()
    return Config.PublicGarages or {}
end

function PublicGarage.IsEnabled()
    return settings().enabled == true
end

function PublicGarage.GetStoredTimestamp(record)
    if not record then return nil end
    if type(record.stored_at) == 'number' then return record.stored_at end
    return os.time()
end

local function getBillingAnchor(record)
    local storedAt = PublicGarage.GetStoredTimestamp(record) or os.time()
    local paidUntil = tonumber(record and record.paid_until) or storedAt
    return math.max(storedAt, paidUntil), storedAt, paidUntil
end

function PublicGarage.CalculateBillableDays(anchor, cfg)
    cfg = cfg or settings()
    local elapsed = math.max(0, os.time() - (anchor or os.time()))
    local secondsPerDay = (cfg.realtimeDayHours or 24) * 3600
    if cfg.chargeOnlyFullDays ~= false then
        return math.floor(elapsed / secondsPerDay)
    end
    return math.ceil(elapsed / secondsPerDay)
end

function PublicGarage.CalculateStorageFee(record, garageId)
    if not record or record.state ~= W2F_GARAGE.VehicleStates.STORED_PUBLIC then return 0, 0, 0, os.time() end
    local anchor = getBillingAnchor(record)
    local dailyFee = record.daily_fee or BasicPublicGarages.GetDailyFee(garageId or record.garage_id)
    local days = PublicGarage.CalculateBillableDays(anchor)
    return days * dailyFee, days, dailyFee, anchor
end

function PublicGarage.EnsureBill(source, record, garageId)
    local fee, days, dailyFee, anchor = PublicGarage.CalculateStorageFee(record, garageId)
    local plate = ServerUtils.NormalizePlate(record.plate)

    if fee <= 0 then
        Database.SetPublicVehicleBill(plate, nil, 0, os.time())
        return fee, nil
    end

    local billing = Billing.CreateBill(source, { plate = plate, garageId = garageId or record.garage_id, amount = fee })
    local billId, created = Database.UpsertPublicGarageBill({
        ownerIdentifier = record.owner_identifier,
        plate = plate,
        garageId = garageId or record.garage_id,
        billType = 'public_garage_storage',
        amount = fee,
        dailyFee = dailyFee,
        billableDays = days,
        billingAnchor = anchor,
        paidUntil = tonumber(record.paid_until) or PublicGarage.GetStoredTimestamp(record),
        status = 'pending',
        provider = billing.provider or 'internal',
        providerBillId = billing.providerBillId
    })

    Database.SetPublicVehicleBill(plate, billId, fee, os.time())
    Logs.GarageAction(created and W2F_GARAGE.LogActions.PUBLIC_BILL_CREATED or W2F_GARAGE.LogActions.PUBLIC_BILL_UPDATED, source, plate, garageId or record.garage_id, { fee = fee, billableDays = days })
    return fee, billId
end

function PublicGarage.SyncUnpaidFee(record, garageId)
    return PublicGarage.EnsureBill(record and record.source or 0, record, garageId)
end

function PublicGarage.FormatVehicleForClient(record, garageId, locationLabel)
    local fee, days, dailyFee = PublicGarage.CalculateStorageFee(record, garageId)
    local storedAt = PublicGarage.GetStoredTimestamp(record) or os.time()
    return {
        plate = record.plate,
        model = record.model,
        garageId = record.garage_id,
        storedGarageLabel = locationLabel or record.garage_id,
        state = record.state,
        storedAt = storedAt,
        storedForHours = math.floor(math.max(0, os.time() - storedAt) / 3600),
        storedForDays = days,
        dailyFee = dailyFee,
        paidUntil = tonumber(record.paid_until),
        unpaidFee = fee,
        billingStatus = fee > 0 and 'pending' or 'paid',
        billProvider = settings().billingProvider or 'internal',
        currentBillId = record.current_bill_id,
        payInstruction = fee > 0 and Locale.public_pay_in_banking_app or nil,
        canSpawn = fee <= 0 or settings().allowSpawnWithUnpaidFees == true,
        props = record.vehicle_props,
        fuel = record.fuel,
        engineHealth = record.engine_health,
        bodyHealth = record.body_health,
        dirtLevel = record.dirt_level
    }
end

function PublicGarage.GetGarageData(garageId)
    return ServerUtils.Success(BasicPublicGarages.Enrich(garageId))
end

function PublicGarage.GetVehicles(source, garageId)
    if not PublicGarage.IsEnabled() then return ServerUtils.Failure('public_disabled', Locale.public_disabled, { vehicles = {} }) end
    local valid, reason = Security.ValidatePlayer(source)
    if not valid then return ServerUtils.Failure(reason, Locale.invalid_player, { vehicles = {} }) end

    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return ServerUtils.Failure('missing_identifier', Locale.invalid_player, { vehicles = {} }) end
    if not BasicPublicGarages.Get(garageId) then return ServerUtils.Failure('invalid_garage', Locale.invalid_garage, { vehicles = {} }) end

    local shared = settings().sharedPublicStorage == true
    local rows = Database.GetPublicVehiclesByOwner(identifier, garageId, shared) or {}
    local vehicles, totalFees = {}, 0

    for _, row in ipairs(rows) do
        PublicGarage.EnsureBill(source, row, garageId)
        local location = BasicPublicGarages.Get(row.garage_id)
        local formatted = PublicGarage.FormatVehicleForClient(row, garageId, location and location.label)
        vehicles[#vehicles + 1] = formatted
        totalFees = totalFees + (formatted.unpaidFee or 0)
    end

    return ServerUtils.Success({ vehicles = vehicles, garage = BasicPublicGarages.Enrich(garageId), totalUnpaidFees = totalFees, sharedPublicStorage = shared })
end

function PublicGarage.StoreVehicle(source, garageId, vehicleData)
    if not PublicGarage.IsEnabled() then return ServerUtils.Failure('public_disabled', Locale.public_disabled) end
    local valid, reason = Security.ValidatePlayer(source)
    if not valid then return ServerUtils.Failure(reason, Locale.invalid_player) end
    if not BasicPublicGarages.Get(garageId) then return ServerUtils.Failure('invalid_garage', Locale.invalid_garage) end

    local plate = ServerUtils.NormalizePlate(vehicleData and vehicleData.plate)
    if not plate then return ServerUtils.Failure('invalid_plate', Locale.invalid_plate) end

    local ownership, ownershipReason = Security.ValidateVehicleOwnership(source, plate)
    if not ownership then return ServerUtils.Failure(ownershipReason, ownershipReason == 'vehicle_ownership_not_configured' and Locale.vehicle_ownership_not_configured or Locale.access_denied) end

    local existing = Database.GetPublicVehicle(plate)
    if existing and existing.state == W2F_GARAGE.VehicleStates.STORED_PUBLIC then
        Logs.Security(source, W2F_GARAGE.LogActions.DUPLICATE_ATTEMPT, { plate = plate, garageId = garageId, context = 'public_store' })
        return ServerUtils.Failure('already_stored', Locale.public_already_stored)
    end

    local now = os.time()
    Database.UpsertPublicVehicle({
        plate = plate, ownerIdentifier = Bridge.GetIdentifier(source), garageId = garageId, model = vehicleData.model,
        vehicleProps = vehicleData.props, fuel = vehicleData.fuel, engineHealth = vehicleData.engineHealth, bodyHealth = vehicleData.bodyHealth,
        dirtLevel = vehicleData.dirtLevel, state = W2F_GARAGE.VehicleStates.STORED_PUBLIC, storedAt = now, lastFeeCalculatedAt = now,
        unpaidFee = 0, dailyFee = BasicPublicGarages.GetDailyFee(garageId), paidUntil = now, currentBillId = nil
    })

    VehicleState.ActiveVehicles[plate] = nil
    VehicleState.Set(plate, W2F_GARAGE.VehicleStates.STORED_PUBLIC, 'public_stored', source)
    Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_STORED, source, plate, garageId)
    TriggerClientEvent(W2F_GARAGE.Events.StoreVehicle, source, { garageId = garageId, plate = plate, garageType = 'public' })
    return ServerUtils.Success({ plate = plate, garageId = garageId })
end

function PublicGarage.SpawnVehicle(source, garageId, plate)
    if not PublicGarage.IsEnabled() then return ServerUtils.Failure('public_disabled', Locale.public_disabled) end
    plate = ServerUtils.NormalizePlate(plate)
    if not BasicPublicGarages.Get(garageId) or not plate then return ServerUtils.Failure('invalid_garage', Locale.invalid_garage) end

    local identifier = Bridge.GetIdentifier(source)
    local record = Database.GetPublicVehicle(plate)
    if not record or record.owner_identifier ~= identifier then return ServerUtils.Failure('not_owner', Locale.access_denied) end
    if record.state ~= W2F_GARAGE.VehicleStates.STORED_PUBLIC then return ServerUtils.Failure('invalid_state', Locale.invalid_vehicle_state) end
    if VehicleState.IsOut(plate) then
        Logs.Security(source, W2F_GARAGE.LogActions.DUPLICATE_ATTEMPT, { plate = plate, garageId = garageId, context = 'public_spawn' })
        return ServerUtils.Failure('vehicle_already_out', Locale.vehicle_out)
    end

    local fee = PublicGarage.EnsureBill(source, record, garageId)
    if fee > 0 and settings().allowSpawnWithUnpaidFees ~= true then
        Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_SPAWN_DENIED_UNPAID, source, plate, garageId, { fee = fee })
        return ServerUtils.Failure('garage_bill_unpaid', Locale.public_unpaid_fee_banking, { unpaidFee = fee, plate = plate })
    end

    local spawn = BasicPublicGarages.GetSpawn(garageId)
    if not spawn then return ServerUtils.Failure('invalid_spawn', Locale.invalid_garage) end

    local now = os.time()
    Database.UpdatePublicVehicleState(plate, W2F_GARAGE.VehicleStates.OUT, { unpaidFee = 0, lastFeeCalculatedAt = now, lastSpawnedAt = now, garageId = garageId })
    VehicleState.MarkOut(plate, garageId, source)
    TriggerClientEvent(W2F_GARAGE.Events.SpawnVehicle, source, {
        garageId = garageId, plate = plate, model = record.model, coords = ServerUtils.VectorToTable(spawn), props = record.vehicle_props,
        fuel = record.fuel, engineHealth = record.engine_health, bodyHealth = record.body_health, dirtLevel = record.dirt_level, garageType = 'public', feePaid = 0
    })

    Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_SPAWNED, source, plate, garageId, { fee = 0 })
    return ServerUtils.Success({ plate = plate, approved = true, feePaid = 0 })
end

function PublicGarage.PayStorageFee(source, garageId, plate)
    plate = ServerUtils.NormalizePlate(plate)
    local record = Database.GetPublicVehicle(plate)
    if not record or record.owner_identifier ~= Bridge.GetIdentifier(source) then return ServerUtils.Failure('not_owner', Locale.access_denied) end
    if settings().allowGarageUiPayment ~= true then return ServerUtils.Failure('external_billing_only', Locale.public_pay_in_banking_app) end

    local bill = Database.GetPendingPublicGarageBill(plate)
    if not bill then return ServerUtils.Failure('bill_not_found', Locale.public_pay_in_banking_app) end
    if not Billing.MarkPaid(bill.id) then return ServerUtils.Failure('payment_failed', Locale.payment_failed) end

    Database.SetPublicUnpaidFee(plate, 0, os.time(), os.time())
    Database.SetPublicVehicleBill(plate, nil, 0, os.time())
    Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_BILL_PAID, source, plate, garageId, { billId = bill.id, fee = bill.amount })
    return ServerUtils.Success({ plate = plate, feePaid = bill.amount, billPaid = true })
end

function PublicGarage.GetBills(source)
    return ServerUtils.Success({ bills = Billing.GetOutstandingBills(source) })
end

function PublicGarage.RefreshBill(source, plate)
    local record = Database.GetPublicVehicle(plate)
    if not record then return ServerUtils.Failure('vehicle_not_found', Locale.no_vehicle) end
    local fee = PublicGarage.EnsureBill(source, record, record.garage_id)
    return ServerUtils.Success({ plate = plate, unpaidFee = fee })
end

function PublicGarage.MarkBillPaid(source, plate)
    local bill = Database.GetPendingPublicGarageBill(plate)
    if not bill then return ServerUtils.Failure('bill_not_found', Locale.no_vehicle) end
    Billing.MarkPaid(bill.id)
    Database.SetPublicUnpaidFee(plate, 0, os.time(), os.time())
    Database.SetPublicVehicleBill(plate, nil, 0, os.time())
    return ServerUtils.Success({ plate = plate, billId = bill.id })
end

function PublicGarage.AdminClearFee(plate)
    Database.SetPublicUnpaidFee(plate, 0, os.time(), os.time())
    local bill = Database.GetPendingPublicGarageBill(plate)
    if bill then Database.UpdatePublicGarageBillStatus(bill.id, 'cancelled') end
    return true
end

function PublicGarage.AdminSetFee(plate, amount)
    local row = Database.GetPublicVehicle(plate)
    if not row then return false end
    local fee = math.floor(tonumber(amount) or 0)
    if fee <= 0 then return PublicGarage.AdminClearFee(plate) end
    local id = Database.UpsertPublicGarageBill({ ownerIdentifier = row.owner_identifier, plate = row.plate, garageId = row.garage_id, amount = fee, dailyFee = row.daily_fee or 700, billableDays = 0, billingAnchor = os.time(), paidUntil = row.paid_until, status = 'pending', provider = 'internal' })
    Database.SetPublicVehicleBill(plate, id, fee, os.time())
    return true
end

function PublicGarage.AdminGetFee(plate)
    local record = Database.GetPublicVehicle(plate)
    if not record then return nil end
    return PublicGarage.CalculateStorageFee(record, record.garage_id)
end
