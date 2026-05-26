ClientPublicGarage = ClientPublicGarage or {}
ClientPublicGarage.Blips = ClientPublicGarage.Blips or {}
ClientPublicGarage.CurrentGarage = nil

function ClientPublicGarage.Open(garageId)
    if not BasicPublicGarages.IsEnabled() then
        ClientUtils.Notify(Locale.public_disabled, 'error')
        return false
    end

    local garage = BasicPublicGarages.Get(garageId)

    if not garage then
        ClientUtils.Notify(Locale.invalid_garage, 'error')
        return false
    end

    ClientPublicGarage.CurrentGarage = garageId
    Nui.OpenPublicGarage(garageId)
    return true
end

function ClientPublicGarage.Store(garageId)
    local vehicle = cache.vehicle or GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle == 0 then
        vehicle = ClientUtils.GetClosestVehicle(8.0)
    end

    if not vehicle or vehicle == 0 then
        ClientUtils.Notify(Locale.no_vehicle_nearby, 'error')
        return
    end

    local plate = ClientUtils.GetVehiclePlate(vehicle)
    local props = ClientUtils.GetVehicleProperties(vehicle)

    local result = lib.callback.await(W2F_GARAGE.Callbacks.StorePublicVehicle, false, {
        garageId = garageId,
        plate = plate,
        model = props and props.model or GetEntityModel(vehicle),
        props = props and props.props or props,
        fuel = props and props.fuel or 100.0,
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle)
    })

    if result and result.success then
        if Config.Features.RemoveKeysOnStore and Keys and Keys.RemoveKeys then
            Keys.RemoveKeys(plate, vehicle)
        end

        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    else
        ClientUtils.Notify(result and result.message or Locale.access_denied, 'error')
    end
end

function ClientPublicGarage.InitBlips()
    if not BasicPublicGarages.IsEnabled() then
        return
    end

    for garageId, garage in pairs(BasicPublicGarages.GetAll()) do
        if garage.blip and garage.coords then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, 357)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.7)
            SetBlipColour(blip, 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(garage.label or 'Public Garage')
            EndTextCommandSetBlipName(blip)
            ClientPublicGarage.Blips[#ClientPublicGarage.Blips + 1] = blip
        end
    end
end

function ClientPublicGarage.DestroyBlips()
    for _, blip in ipairs(ClientPublicGarage.Blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    ClientPublicGarage.Blips = {}
end

RegisterNetEvent(W2F_GARAGE.Events.OpenPublicGarage, function(garageId)
    ClientPublicGarage.Open(garageId)
end)
