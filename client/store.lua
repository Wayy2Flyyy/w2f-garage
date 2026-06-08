Store = Store or {}

function Store.RequestVehicle(garageId)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle == 0 then
        vehicle = ClientUtils.GetClosestVehicle(6.0)
    end

    if not vehicle or vehicle == 0 then
        local response = {
            success = false,
            code = 'no_vehicle',
            message = 'No vehicle found to store.'
        }

        ClientUtils.Notify(response.message, 'error')
        return response
    end

    local properties = ClientUtils.GetVehicleProperties(vehicle)

    if not properties or not properties.plate then
        local response = {
            success = false,
            code = 'invalid_plate',
            message = Locale.invalid_plate
        }

        ClientUtils.Notify(response.message, 'error')
        return response
    end

    local response = lib.callback.await(W2F_GARAGE.Callbacks.StoreVehicle, false, {
        garageId = garageId,
        plate = properties.plate,
        properties = properties
    })

    if response and response.success and response.data and response.data.approved then
        ClientUtils.Debug('Server approved store payload.', response.data)

        if Config.Features.RemoveKeysOnStore then
            Keys.RemoveKeys(GetPlayerServerId(PlayerId()), properties.plate, vehicle)
        end
    else
        ClientUtils.Notify(response and response.message or Locale.not_implemented, 'error')
    end

    return response
end
