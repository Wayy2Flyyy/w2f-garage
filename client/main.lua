Client = Client or {}
Client.Blips = Client.Blips or {}
Client.Started = false

local function createBlips()
    for _, garage in pairs(Garages.GetEnabled()) do
        if garage.blip and garage.blip.enabled and garage.coords then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)

            SetBlipSprite(blip, garage.blip.sprite or 357)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale or 0.7)
            SetBlipColour(blip, garage.blip.colour or 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(garage.blip.label or garage.label)
            EndTextCommandSetBlipName(blip)

            Client.Blips[#Client.Blips + 1] = blip
        end
    end
end

local function removeBlips()
    for _, blip in ipairs(Client.Blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    Client.Blips = {}
end

function Client.Start()
    if Client.Started then
        return
    end

    Client.Started = true
    Nui.RegisterCallbacks()
    createBlips()
    ClientProperty.InitBlips()
    Targets.Init()
    Targets.InitProperty()
    Zones.Init()
    Zones.InitProperty()

    ClientUtils.Debug('w2f-garage client foundation started.', {
        garages = Garages and Garages.List and ClientUtils.ToPlainTable(Garages.List) or {},
        target = Config.Target.Resource
    })
end

function Client.Stop()
    if not Client.Started then
        return
    end

    Client.Started = false
    Nui.CloseGarage()
    Targets.Destroy()
    Zones.Destroy()
    Camera.Destroy()
    removeBlips()
    ClientProperty.DestroyBlips()
end

CreateThread(function()
    Wait(500)
    Client.Start()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Client.Stop()
end)

if Config.DebugCommands and Config.DebugCommands.OpenGarage then
    RegisterCommand('w2fgarageopen', function(_, args)
        TriggerEvent(W2F_GARAGE.Events.OpenGarage, args[1] or 'legion_public')
    end, false)
end

if Config.DebugCommands and Config.DebugCommands.PrintState then
    RegisterCommand('w2fgaragestate', function()
        ClientUtils.Debug('Client state', {
            open = Nui.Open,
            currentGarage = Nui.CurrentGarage,
            blips = #Client.Blips
        })
    end, false)
end
