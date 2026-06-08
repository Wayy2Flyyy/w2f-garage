Callbacks = Callbacks or {}
Callbacks.Registered = false

local function localeMessage(code)
    local messages = {
        invalid_garage = Locale.invalid_garage,
        garage_disabled = Locale.garage_disabled,
        access_denied = Locale.access_denied,
        invalid_plate = Locale.invalid_plate,
        invalid_player = Locale.invalid_player,
        vehicle_already_out = Locale.vehicle_out,
        not_implemented = Locale.not_implemented,
        vehicle_not_found = Locale.no_vehicles,
        property_disabled = Locale.property_disabled,
        coords_not_ready = Locale.coords_not_ready,
        garage_full = Locale.garage_full,
        public_disabled = Locale.public_disabled,
        not_enough_money = Locale.not_enough_money
    }

    return messages[code] or code or Locale.not_implemented
end

local function register(name, handler)
    return Bridge.RegisterCallback(name, function(source, ...)
        local ok, result = pcall(handler, source, ...)

        if ok then
            return result
        end

        Logs.Warn(('Callback "%s" failed.'):format(name), { error = result })
        return ServerUtils.Failure('callback_error', 'Garage callback failed safely.')
    end)
end

function Callbacks.Register()
    if Callbacks.Registered then
        return true
    end

    register(W2F_GARAGE.Callbacks.GetGarageData, function(source, garageId)
        if garageId then
            local access, reason = Security.ValidateGarageAccess(source, garageId)

            if not access then
                return ServerUtils.Failure(reason, localeMessage(reason))
            end

            return ServerUtils.Success(ServerUtils.SanitizeGarage(ServerUtils.GetGarage(garageId)))
        end

        local garages = {}

        for id, garage in pairs(Garages.GetEnabled()) do
            local access = Security.ValidateGarageAccess(source, id)

            if access then
                garages[id] = ServerUtils.SanitizeGarage(garage)
            end
        end

        return ServerUtils.Success(garages)
    end)

    register(W2F_GARAGE.Callbacks.GetVehicles, function(source, garageId)
        if BasicPublicGarages.Get(garageId) then
            return PublicGarage.GetVehicles(source, garageId)
        end

        local access, reason = Security.ValidateGarageAccess(source, garageId)

        if not access then
            return ServerUtils.Failure(reason, localeMessage(reason), { vehicles = {} })
        end

        local identifier = Bridge.GetIdentifier(source)

        if not identifier then
            return ServerUtils.Success({}, Locale.no_vehicles)
        end

        local vehicles = Database.GetVehiclesByGarage(identifier, garageId)
        return ServerUtils.Success(vehicles or {})
    end)

    register(W2F_GARAGE.Callbacks.GetOwnedVehicles, function(source)
        local validPlayer, reason = Security.ValidatePlayer(source)

        if not validPlayer then
            return ServerUtils.Failure(reason, localeMessage(reason), { vehicles = {} })
        end

        local identifier = Bridge.GetIdentifier(source)

        if not identifier then
            return ServerUtils.Success({}, Locale.no_vehicles)
        end

        return ServerUtils.Success(Database.GetPlayerVehicles(identifier) or {})
    end)

    register(W2F_GARAGE.Callbacks.SpawnVehicle, function(source, data)
        data = data or {}
        local plate = ServerUtils.NormalizePlate(data.plate)
        local garageId = data.garageId

        if BasicPublicGarages.Get(garageId) then
            return PublicGarage.SpawnVehicle(source, garageId, plate)
        end

        if PropertyGarages.Get(garageId) then
            return Property.SpawnVehicle(source, garageId, plate, data.floorIndex)
        end

        local valid, reason = Security.ValidateSpawnRequest(source, garageId, plate)

        if not valid then
            return ServerUtils.Failure(reason, localeMessage(reason))
        end

        return ServerUtils.Failure('not_implemented', Locale.not_implemented, {
            approved = false,
            garageId = garageId,
            plate = plate
        })
    end)

    register(W2F_GARAGE.Callbacks.StoreVehicle, function(source, data)
        data = data or {}
        local plate = ServerUtils.NormalizePlate(data.plate)
        local garageId = data.garageId

        if BasicPublicGarages.Get(garageId) then
            return PublicGarage.StoreVehicle(source, garageId, data)
        end

        if PropertyGarages.Get(garageId) then
            return Property.StoreVehicle(source, garageId, data)
        end

        local valid, reason = Security.ValidateStoreRequest(source, garageId, plate)

        if not valid then
            return ServerUtils.Failure(reason, localeMessage(reason))
        end

        return ServerUtils.Failure('not_implemented', Locale.not_implemented, {
            approved = false,
            garageId = garageId,
            plate = plate
        })
    end)

    register(W2F_GARAGE.Callbacks.RecoverVehicle, function(source, data)
        data = data or {}
        local plate = ServerUtils.NormalizePlate(data.plate)

        if not plate then
            return ServerUtils.Failure('invalid_plate', Locale.invalid_plate)
        end

        local admin = Security.ValidateAdmin(source)

        if not admin then
            return ServerUtils.Failure('permission_denied', Locale.admin_denied)
        end

        VehicleState.Recover(plate, 'admin_recover', source)
        return ServerUtils.Success({ plate = plate, recovered = true })
    end)

    register(W2F_GARAGE.Callbacks.PayImpound, function(source, data)
        data = data or {}
        local plate = ServerUtils.NormalizePlate(data.plate)
        local valid, reason = Security.ValidateImpoundPayment(source, plate, data.garageId)

        if not valid then
            return ServerUtils.Failure(reason, localeMessage(reason))
        end

        return ServerUtils.Failure('not_implemented', Locale.not_implemented, {
            approved = false,
            plate = plate
        })
    end)

    register(W2F_GARAGE.Callbacks.AdminSearchVehicle, function(source, data)
        local admin, reason = Security.ValidateAdmin(source)

        if not admin then
            return ServerUtils.Failure(reason, Locale.admin_denied)
        end

        local query = data and data.query
        local plate = ServerUtils.NormalizePlate(query)

        if plate then
            return ServerUtils.Success({
                plate = plate,
                state = VehicleState.Get(plate),
                slot = Database.GetGarageSlot(data.garageId, plate)
            })
        end

        return ServerUtils.Failure('invalid_query', Locale.invalid_plate)
    end)

    register(W2F_GARAGE.Callbacks.GetPropertyGarages, function(source)
        if not Property.IsEnabled() then
            return ServerUtils.Failure('property_disabled', Locale.property_disabled)
        end

        local list = {}

        for id, garage in pairs(PropertyGarages.GetAll()) do
            list[id] = PropertyGarages.Enrich(id, {
                owned = Property.PlayerOwnsGarage(Bridge.GetIdentifier(source), id)
            })
        end

        return ServerUtils.Success(list)
    end)

    register(W2F_GARAGE.Callbacks.GetOwnedGarages, function(source)
        if not Property.IsEnabled() then
            return ServerUtils.Failure('property_disabled', Locale.property_disabled)
        end

        return ServerUtils.Success(Database.GetOwnedGarages(Bridge.GetIdentifier(source)) or {})
    end)

    register(W2F_GARAGE.Callbacks.GetPropertyDashboard, function(source)
        if not Property.IsEnabled() then
            return ServerUtils.Failure('property_disabled', Locale.property_disabled)
        end

        return ServerUtils.Success(Property.GetDashboard(source))
    end)

    register(W2F_GARAGE.Callbacks.BuyGarage, function(source, garageId)
        return Property.BuyGarage(source, garageId)
    end)

    register(W2F_GARAGE.Callbacks.SellGarage, function(source, garageId)
        if not Property.IsEnabled() or not Config.Property.AllowSell then
            return ServerUtils.Failure('sell_disabled', Locale.sell_disabled)
        end

        local identifier = Bridge.GetIdentifier(source)

        if not Property.PlayerOwnsGarage(identifier, garageId) then
            return ServerUtils.Failure('not_owner', Locale.access_denied)
        end

        local property = PropertyGarages.Get(garageId)
        local refund = math.floor((property.price or 0) * (Config.Property.SellRefundPercent or 0.5))

        Database.RemoveOwnedGarage(identifier, garageId)

        if refund > 0 then
            Bridge.AddMoney(source, Config.Property.PurchaseAccount or 'bank', refund, 'w2f-garage sell')
        end

        Bridge.Notify(source, Locale.garage_sold:format(property.label), 'success')
        return ServerUtils.Success({ garageId = garageId, refund = refund })
    end)

    register(W2F_GARAGE.Callbacks.EnterGarage, function(source, data)
        data = data or {}
        return Property.EnterGarage(source, data.garageId, data.floorIndex)
    end)

    register(W2F_GARAGE.Callbacks.ExitGarage, function(source, garageId)
        return Property.ExitGarage(source, garageId)
    end)

    register(W2F_GARAGE.Callbacks.GetGarageVehicles, function(source, data)
        data = data or {}
        return Property.GetGarageVehicles(source, data.garageId, data.floorIndex)
    end)

    register(W2F_GARAGE.Callbacks.MoveVehicleSlot, function(source, data)
        data = data or {}
        return Property.MoveVehicleSlot(source, data.garageId, data.plate, data.slotIndex, data.floorIndex)
    end)

    register(W2F_GARAGE.Callbacks.PropertySpawnVehicle, function(source, data)
        data = data or {}
        return Property.SpawnVehicle(source, data.garageId, data.plate, data.floorIndex)
    end)

    register(W2F_GARAGE.Callbacks.PropertyStoreVehicle, function(source, data)
        data = data or {}
        return Property.StoreVehicle(source, data.garageId, data)
    end)

    register(W2F_GARAGE.Callbacks.GetPublicGarageData, function(source, garageId)
        return PublicGarage.GetGarageData(garageId)
    end)

    register(W2F_GARAGE.Callbacks.GetPublicVehicles, function(source, garageId)
        return PublicGarage.GetVehicles(source, garageId)
    end)

    register(W2F_GARAGE.Callbacks.StorePublicVehicle, function(source, data)
        data = data or {}
        return PublicGarage.StoreVehicle(source, data.garageId, data)
    end)

    register(W2F_GARAGE.Callbacks.SpawnPublicVehicle, function(source, data)
        data = data or {}
        return PublicGarage.SpawnVehicle(source, data.garageId, data.plate)
    end)

    register(W2F_GARAGE.Callbacks.PayPublicStorageFee, function(source, data)
        data = data or {}
        return PublicGarage.PayStorageFee(source, data.garageId, data.plate)
    end)
    register(W2F_GARAGE.Callbacks.GetPublicGarageBills, function(source)
        return PublicGarage.GetBills(source)
    end)
    register(W2F_GARAGE.Callbacks.GetOutstandingPublicGarageFee, function(source, data)
        data = data or {}
        return PublicGarage.RefreshBill(source, data.plate)
    end)
    register(W2F_GARAGE.Callbacks.OpenBillingApp, function(source)
        return Billing.OpenBillingApp(source)
    end)
    register(W2F_GARAGE.Callbacks.RefreshPublicGarageBillStatus, function(source, data)
        data = data or {}
        return PublicGarage.RefreshBill(source, data.plate)
    end)

    Callbacks.Registered = true
    return true
end
