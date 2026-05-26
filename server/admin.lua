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
            reply(source, 'Use property garage UI at any Dynasty 8 location, or admin commands below.', 'inform')
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

            VehicleState.Recover(plate, 'admin_recover', source)

            if args[2] then
                Database.UpdateGarageSlotState(args[2], plate, W2F_GARAGE.VehicleStates.STORED)
            end

            reply(source, ('Recovered vehicle %s to stored state.'):format(plate), 'success')
        end)
    end, false)

    RegisterCommand('impoundvehicle', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])
            local fee = tonumber(args[2]) or 0

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            VehicleState.MarkImpounded(plate, {
                plate = plate,
                fee = fee,
                reason = 'admin_impound',
                impoundedBy = Bridge.GetIdentifier(source)
            }, source)

            reply(source, ('Impounded vehicle %s.'):format(plate), 'success')
        end)
    end, false)

    RegisterCommand('releasevehicle', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, Locale.invalid_plate, 'error')
                return
            end

            VehicleState.Recover(plate, 'admin_release', source)
            Database.UpdateImpoundStatus(plate, 'released')
            reply(source, ('Released vehicle %s.'):format(plate), 'success')
        end)
    end, false)

    RegisterCommand('movegarage', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])
            local fromGarage = args[2]
            local toGarage = args[3]
            local targetSource = tonumber(args[4]) or source
            local identifier = Bridge.GetIdentifier(targetSource)

            if not plate or not PropertyGarages.Get(toGarage) or not identifier then
                reply(source, 'Usage: /movegarage <plate> <fromGarageId> <toGarageId> [playerId]', 'error')
                return
            end

            local ok, reason = SlotManager.MoveToGarage(fromGarage, toGarage, identifier, plate)

            if ok then
                reply(source, ('Moved %s to %s.'):format(plate, toGarage), 'success')
            else
                reply(source, ('Move failed: %s'):format(reason or 'unknown'), 'error')
            end
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
            VehicleState.ActiveVehicles[plate] = nil
            reply(source, ('In-memory state reset for %s.'):format(plate), 'inform')
        end)
    end, false)

    RegisterCommand('givegarage', function(source, args)
        guardedCommand(source, function()
            local target = tonumber(args[1])
            local garageId = args[2]
            local property = PropertyGarages.Get(garageId)

            if not target or not property then
                reply(source, 'Usage: /givegarage <playerId> <garageId>', 'error')
                return
            end

            local identifier = Bridge.GetIdentifier(target)

            if not identifier then
                reply(source, Locale.invalid_player, 'error')
                return
            end

            Database.CreateOwnedGarage({
                garageId = garageId,
                ownerIdentifier = identifier,
                purchasePrice = 0,
                interiorTemplate = property.interiorTemplate,
                propertyClass = property.propertyClass
            })

            reply(source, ('Gave garage %s to player %s.'):format(garageId, target), 'success')
            Bridge.Notify(target, ('You received garage: %s'):format(property.label), 'success')
        end)
    end, false)

    RegisterCommand('removegarage', function(source, args)
        guardedCommand(source, function()
            local target = tonumber(args[1])
            local garageId = args[2]
            local identifier = Bridge.GetIdentifier(target)

            if not target or not garageId or not identifier then
                reply(source, 'Usage: /removegarage <playerId> <garageId>', 'error')
                return
            end

            Database.RemoveOwnedGarage(identifier, garageId)
            reply(source, ('Removed garage %s from player %s.'):format(garageId, target), 'success')
        end)
    end, false)

    RegisterCommand('resetgarageslots', function(source, args)
        guardedCommand(source, function()
            local garageId = args[1]
            local target = tonumber(args[2]) or source
            local identifier = Bridge.GetIdentifier(target)

            if not garageId or not identifier then
                reply(source, 'Usage: /resetgarageslots <garageId> [playerId]', 'error')
                return
            end

            local slots = Database.GetGarageSlots(garageId, identifier) or {}

            for _, slot in ipairs(slots) do
                Database.RemoveGarageSlot(garageId, slot.plate)
            end

            reply(source, ('Reset %s slots for garage %s.'):format(#slots, garageId), 'success')
        end)
    end, false)

    RegisterCommand('cleargaragefee', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, 'Usage: /cleargaragefee <plate>', 'error')
                return
            end

            PublicGarage.AdminClearFee(plate)
            reply(source, ('Cleared public storage fee for %s.'):format(plate), 'success')
        end)
    end, false)

    RegisterCommand('setgaragefee', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])
            local amount = tonumber(args[2])

            if not plate or amount == nil then
                reply(source, 'Usage: /setgaragefee <plate> <amount>', 'error')
                return
            end

            PublicGarage.AdminSetFee(plate, amount)
            reply(source, ('Set public storage fee for %s to $%s.'):format(plate, amount), 'success')
        end)
    end, false)

    RegisterCommand('checkgaragefee', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])

            if not plate then
                reply(source, 'Usage: /checkgaragefee <plate>', 'error')
                return
            end

            local fee, days, daily = PublicGarage.AdminGetFee(plate)

            if fee == nil then
                reply(source, ('No public storage record for %s.'):format(plate), 'error')
                return
            end

            reply(source, ('%s: $%s unpaid (%s full days @ $%s/day).'):format(plate, fee, days, daily), 'inform')
        end)
    end, false)

    RegisterCommand('garagebills', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1] or '')
            if plate and plate ~= '' then
                local bill = Database.GetPendingPublicGarageBill(plate)
                reply(source, bill and json.encode(bill) or ('No pending bill for %s.'):format(plate), bill and 'inform' or 'error')
                return
            end
            local target = tonumber(args[2]) or source
            local id = Bridge.GetIdentifier(target)
            reply(source, json.encode(Database.GetPublicGarageBillsByOwner(id, 'pending') or {}), 'inform')
        end)
    end, false)

    RegisterCommand('cleargaragebill', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])
            if not plate then reply(source, 'Usage: /cleargaragebill <plate>', 'error') return end
            PublicGarage.AdminClearFee(plate)
            Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_BILL_CANCELLED, source, plate, nil, { reason = 'admin_clear' })
            reply(source, ('Cleared public bill for %s.'):format(plate), 'success')
        end)
    end, false)

    RegisterCommand('markgaragebillpaid', function(source, args)
        guardedCommand(source, function()
            local plate = ServerUtils.NormalizePlate(args[1])
            if not plate then reply(source, 'Usage: /markgaragebillpaid <plate>', 'error') return end
            PublicGarage.MarkBillPaid(source, plate)
            Logs.GarageAction(W2F_GARAGE.LogActions.PUBLIC_BILL_PAID, source, plate, nil, { reason = 'admin_mark' })
            reply(source, ('Marked public bill as paid for %s.'):format(plate), 'success')
        end)
    end, false)

    Admin.Registered = true
    return true
end
