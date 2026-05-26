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
        vehicle_not_found = Locale.no_vehicles
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

        return ServerUtils.Failure('not_implemented', Locale.not_implemented, {
            approved = false,
            plate = plate
        })
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

        return ServerUtils.Failure('not_implemented', Locale.not_implemented, {
            query = data and data.query or nil
        })
    end)

    Callbacks.Registered = true
    return true
end
