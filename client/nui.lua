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

function Nui.OpenPublicGarage(garageId)
    local garage = BasicPublicGarages.Enrich(garageId)

    if not garage then
        ClientUtils.Notify(Locale.invalid_garage, 'error')
        return false
    end

    Nui.Open = true
    Nui.CurrentGarage = garageId
    Nui.CurrentMode = 'public'

    SetNuiFocus(true, true)

    if not (Config.PublicGarages and Config.PublicGarages.useMenuOnly) then
        Camera.FocusGarage(garage)
    end

    local vehicleResponse = lib.callback.await(W2F_GARAGE.Callbacks.GetPublicVehicles, false, garageId)

    Nui.Send('openPublicGarage', {
        garageId = garageId,
        garage = ClientUtils.ToPlainTable(garage),
        data = vehicleResponse and vehicleResponse.data or vehicleResponse,
        config = {
            title = garage.label or 'Public Garage',
            subtitle = Locale.public_unlimited_storage,
            accent = '#5ea8ff'
        }
    })

    return true
end

function Nui.OpenGarage(garageId)
    local garage = ClientUtils.GetGarage(garageId)

    if not garage then
        ClientUtils.Notify(Locale.invalid_garage, 'error')
        return false
    end

    Nui.Open = true
    Nui.CurrentGarage = garageId
    Nui.CurrentMode = 'garage'

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
    Nui.CurrentMode = nil
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
        local garageId = data.garageId or Nui.CurrentGarage

        if Nui.CurrentMode == 'public' or BasicPublicGarages.Get(garageId) then
            local result = lib.callback.await(W2F_GARAGE.Callbacks.SpawnPublicVehicle, false, {
                garageId = garageId,
                plate = data.plate
            })

            if result and result.success then
                Nui.CloseGarage()
            end

            return result
        end

        return Spawn.RequestVehicle(garageId, data.plate)
    end)

    nuiCallback('payPublicFee', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.PayPublicStorageFee, false, data)
    end)

    nuiCallback('refreshPublicGarage', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.GetPublicVehicles, false, data.garageId or Nui.CurrentGarage)
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

    nuiCallback('getPropertyDashboard', function()
        return lib.callback.await(W2F_GARAGE.Callbacks.GetPropertyDashboard, false)
    end)

    nuiCallback('buyGarage', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.BuyGarage, false, data.garageId)
    end)

    nuiCallback('sellGarage', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.SellGarage, false, data.garageId)
    end)

    nuiCallback('enterGarage', function(data)
        local result = lib.callback.await(W2F_GARAGE.Callbacks.EnterGarage, false, data)

        if result and result.success then
            SetNuiFocus(false, false)
            Nui.Open = false
        end

        return result
    end)

    nuiCallback('exitGarage', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.ExitGarage, false, data.garageId)
    end)

    nuiCallback('getGarageVehicles', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.GetGarageVehicles, false, data)
    end)

    nuiCallback('moveVehicleSlot', function(data)
        return lib.callback.await(W2F_GARAGE.Callbacks.MoveVehicleSlot, false, data)
    end)

    nuiCallback('propertySpawnVehicle', function(data)
        SetNuiFocus(false, false)
        Nui.Open = false
        return lib.callback.await(W2F_GARAGE.Callbacks.PropertySpawnVehicle, false, data)
    end)
end

RegisterNetEvent('w2f-garage:client:openPropertyGarage', function(garageId)
    ClientProperty.OpenDashboard(garageId)
end)

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
