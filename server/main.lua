local function startup()
    Bridge.Init()
    Callbacks.Register()
    Admin.RegisterCommands()
    VehicleState.RestartRecovery()

    Logs.Info('w2f-garage server started.', {
        framework = Bridge.ActiveFramework,
        publicGarages = ServerUtils.TableCount(Garages.List),
        propertyGarages = ServerUtils.TableCount(PropertyGarages.GetAll()),
        propertyEnabled = Config.Property and Config.Property.Enabled,
        databaseEnabled = Config.Database.Enabled,
        databaseSafeMode = Database.IsSafeMode(),
        inventory = Config.Inventory,
        fuel = Config.Fuel,
        keys = Config.Keys,
        notify = Config.Notify
    })
end

CreateThread(startup)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Logs.Info('w2f-garage server foundation stopped.')
end)

exports('GetVehicleState', function(plate)
    return VehicleState.Get(plate)
end)

exports('SetVehicleState', function(plate, state, reason)
    return VehicleState.Set(plate, state, reason or 'export', 0)
end)

exports('IsVehicleOut', function(plate)
    return VehicleState.IsOut(plate)
end)

exports('GetGarageVehicles', function(source, garageId)
    local identifier = Bridge.GetIdentifier(source)

    if not identifier then
        return {}
    end

    return Database.GetVehiclesByGarage(identifier, garageId)
end)

exports('GetPlayerVehicles', function(source)
    local identifier = Bridge.GetIdentifier(source)

    if not identifier then
        return {}
    end

    return Database.GetPlayerVehicles(identifier)
end)

exports('RegisterGarage', function(id, garage)
    if type(id) ~= 'string' or type(garage) ~= 'table' then
        return false
    end

    garage.id = garage.id or id
    Garages.List[id] = garage
    return true
end)

exports('RefreshGarage', function()
    return true
end)

exports('ImpoundVehicle', function(plate, data)
    return VehicleState.MarkImpounded(plate, data, 0)
end)

exports('ReleaseVehicle', function(plate)
    return VehicleState.Recover(plate, 'export_release', 0)
end)

exports('BuyPropertyGarage', function(source, garageId)
    return Property.BuyGarage(source, garageId)
end)

exports('PlayerOwnsGarage', function(source, garageId)
    return Property.PlayerOwnsGarage(Bridge.GetIdentifier(source), garageId)
end)

exports('GetPropertyDashboard', function(source)
    return Property.GetDashboard(source)
end)

exports('EnterPropertyGarage', function(source, garageId, floorIndex)
    return Property.EnterGarage(source, garageId, floorIndex)
end)
