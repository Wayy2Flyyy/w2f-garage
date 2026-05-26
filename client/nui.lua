Nui = Nui or {}
Nui.Open = false
Nui.CurrentGarage = nil

local function nuiCallback(name, handler)
    RegisterNUICallback(name, function(data, cb)
        local ok, result = pcall(handler, data or {})

        if ok then
            cb(result or { success = true })
            return
        end

        ClientUtils.Debug(('NUI callback "%s" failed.'):format(name), result)
        cb({
            success = false,
            code = 'nui_error',
            message = 'NUI callback failed safely.'
        })
    end)
end

function Nui.Send(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

function Nui.LoadGarageData(garageId)
    local garageResponse = lib.callback.await(W2F_GARAGE.Callbacks.GetGarageData, false, garageId)
    local vehicleResponse = lib.callback.await(W2F_GARAGE.Callbacks.GetVehicles, false, garageId)

    Nui.Send('setGarageData', garageResponse and garageResponse.data or {})
    Nui.Send('setVehicles', vehicleResponse and vehicleResponse.data or {})
end

function Nui.OpenGarage(garageId)
    local garage = ClientUtils.GetGarage(garageId)

    if not garage then
        ClientUtils.Notify(Locale.invalid_garage, 'error')
        return false
    end

    Nui.Open = true
    Nui.CurrentGarage = garageId

    SetNuiFocus(true, true)
    Camera.FocusGarage(garage)

    Nui.Send('openGarage', {
        garageId = garageId,
        garage = ClientUtils.ToPlainTable(garage),
        config = {
            title = Config.UI.Title,
            subtitle = Config.UI.Subtitle,
            accent = garage.ui and garage.ui.accent or Config.UI.DefaultAccent
        }
    })

    Nui.LoadGarageData(garageId)
    return true
end

function Nui.CloseGarage()
    Nui.Open = false
    Nui.CurrentGarage = nil
    SetNuiFocus(false, false)
    Camera.Destroy()
    Nui.Send('closeGarage')
end

function Nui.RegisterCallbacks()
    nuiCallback('close', function()
        Nui.CloseGarage()
        return { success = true }
    end)

    nuiCallback('getGarageData', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.GetGarageData, false, data.garageId)
    end)

    nuiCallback('getVehicles', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.GetVehicles, false, data.garageId or Nui.CurrentGarage)
    end)

    nuiCallback('spawnVehicle', function(data)
        return Spawn.RequestVehicle(data.garageId or Nui.CurrentGarage, data.plate)
    end)

    nuiCallback('storeVehicle', function(data)
        return Store.RequestVehicle(data.garageId or Nui.CurrentGarage)
    end)

    nuiCallback('recoverVehicle', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.RecoverVehicle, false, data)
    end)

    nuiCallback('payImpound', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.PayImpound, false, data)
    end)
end

RegisterNetEvent(W2F_GARAGE.Events.OpenGarage, function(garageId)
    Nui.OpenGarage(garageId)
end)

RegisterNetEvent(W2F_GARAGE.Events.CloseGarage, function()
    Nui.CloseGarage()
end)

RegisterNetEvent(W2F_GARAGE.Events.RefreshGarage, function()
    if Nui.CurrentGarage then
        Nui.LoadGarageData(Nui.CurrentGarage)
    end
end)
