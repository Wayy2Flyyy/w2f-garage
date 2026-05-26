Admin = Admin or {}
Admin.Registered = false

local function reply(source, message, notifyType)
    if source == 0 then
        print(('%s %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
        return
    end

    Notify.Send(source, message, notifyType or 'inform')
end

local function guardedCommand(source, callback)
    local allowed = Security.ValidateAdmin(source)

    if not allowed then
        reply(source, Locale.admin_denied, 'error')
        return
    end

    callback()
end

function Admin.RegisterCommands()
    if Admin.Registered or not Config.Admin or Config.Admin.CommandsEnabled == false then
        return false
    end

    RegisterCommand('garageadmin', function(source)
        guardedCommand(source, function()
            reply(source, 'Garage admin panel placeholder is registered. NUI admin tools are reserved for a later stage.', 'inform')
        end)
    end, false)

    RegisterCommand('vehiclestate', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            reply(source, ('Vehicle %s state: %s'):format(plate, VehicleState.Get(plate)), 'inform')
        end)
    end, false)

    RegisterCommand('recovervehicle', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            reply(source, ('Recovery placeholder reached for %s. No production data was modified.'):format(plate), 'inform')
        end)
    end, false)

    RegisterCommand('impoundvehicle', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            reply(source, ('Impound placeholder reached for %s. No production data was modified.'):format(plate), 'inform')
        end)
    end, false)

    RegisterCommand('releasevehicle', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            reply(source, ('Release placeholder reached for %s. No production data was modified.'):format(plate), 'inform')
        end)
    end, false)

    RegisterCommand('movegarage', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])
            local garageId = args[2]

            if not plate or not ServerUtils.GetGarage(garageId) then
                reply(source, 'Usage: /movegarage <plate> <garageId>', 'error')
                return
            end

            reply(source, ('Move placeholder reached for %s to %s. No production data was modified.'):format(plate, garageId), 'inform')
        end)
    end, false)

    RegisterCommand('resetvehiclestate', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            VehicleState.MemoryStates[plate] = W2F_GARAGE.VehicleStates.UNKNOWN
            reply(source, ('In-memory state reset for %s. Database state was not modified.'):format(plate), 'inform')
        end)
    end, false)

    Admin.Registered = true
    return true
end
