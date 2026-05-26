ClientProperty = ClientProperty or {}
ClientProperty.CurrentGarage = nil
ClientProperty.CurrentFloor = 1
ClientProperty.InInterior = false

function ClientProperty.OpenDashboard(garageId)
    SetNuiFocus(true, true)

    local dashboard = lib.callback.await(W2F_GARAGE.Callbacks.GetPropertyDashboard, false)

    Nui.Send('openPropertyGarage', {
        garageId = garageId,
        dashboard = dashboard and dashboard.data or dashboard,
        config = {
            title = 'Property Garages',
            subtitle = 'Dynasty 8 Real Estate',
            accent = Config.UI.DefaultAccent
        }
    })
end

function ClientProperty.Buy(garageId)
    local result = lib.callback.await(W2F_GARAGE.Callbacks.BuyGarage, false, garageId)
    ClientUtils.Notify(result and result.message or Locale.not_implemented, result and result.success and 'success' or 'error')

    if result and result.success then
        ClientProperty.RefreshDashboard()
    end

    return result
end

function ClientProperty.Enter(garageId, floorIndex)
    local result = lib.callback.await(W2F_GARAGE.Callbacks.EnterGarage, false, {
        garageId = garageId,
        floorIndex = floorIndex or 1
    })

    if not result or not result.success then
        ClientUtils.Notify(result and result.message or Locale.access_denied, 'error')
        return false
    end

    ClientProperty.CurrentGarage = garageId
    ClientProperty.CurrentFloor = floorIndex or 1
    ClientProperty.InInterior = true
    return true
end

function ClientProperty.LocalExit(garageId)
    ClientInteriors.Cleanup(garageId)
    ClientProperty.CurrentGarage = nil
    ClientProperty.InInterior = false
end

function ClientProperty.Exit(garageId)
    lib.callback.await(W2F_GARAGE.Callbacks.ExitGarage, false, garageId)
    ClientProperty.LocalExit(garageId)
end

function ClientProperty.RefreshDashboard()
    local dashboard = lib.callback.await(W2F_GARAGE.Callbacks.GetPropertyDashboard, false)
    Nui.Send('setPropertyDashboard', dashboard and dashboard.data or dashboard)
end

function ClientProperty.StoreAtGarage(garageId)
    local vehicle = cache.vehicle or GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle == 0 then
        ClientUtils.Notify(Locale.no_vehicle_nearby, 'error')
        return
    end

    local plate = ClientUtils.GetVehiclePlate(vehicle)
    local props = ClientUtils.GetVehicleProperties(vehicle)

    local result = lib.callback.await(W2F_GARAGE.Callbacks.PropertyStoreVehicle, false, {
        garageId = garageId,
        plate = plate,
        model = props and props.model or GetEntityModel(vehicle),
        props = props,
        fuel = Fuel and Fuel.GetFuel and Fuel.GetFuel(vehicle) or 100.0,
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        locked = GetVehicleDoorLockStatus(vehicle) ~= 1
    })

    ClientUtils.Notify(result and result.message or Locale.not_implemented, result and result.success and 'success' or 'error')

    if result and result.success then
        if Config.Features.RemoveKeysOnStore and Keys and Keys.RemoveKeys then
            Keys.RemoveKeys(plate, vehicle)
        end

        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end
end

function ClientProperty.InitBlips()
    if not Config.Property or not Config.Property.Enabled then
        return
    end

    ClientProperty.Blips = ClientProperty.Blips or {}

    for garageId, garage in pairs(PropertyGarages.GetAll()) do
        if garage.blip and garage.blip.enabled and garage.exteriorEntryCoords and not PropertyGarages.IsTodoCoords(garage.exteriorEntryCoords) then
            local coords = garage.exteriorEntryCoords
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

            SetBlipSprite(blip, garage.blip.sprite or 473)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale or 0.65)
            SetBlipColour(blip, garage.blip.colour or 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(garage.label or Config.Property.DefaultBlipLabel)
            EndTextCommandSetBlipName(blip)

            ClientProperty.Blips[#ClientProperty.Blips + 1] = blip
        end
    end
end

function ClientProperty.DestroyBlips()
    for _, blip in ipairs(ClientProperty.Blips or {}) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    ClientProperty.Blips = {}
end
