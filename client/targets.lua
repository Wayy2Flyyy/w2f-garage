Targets = Targets or {}
Targets.Peds = Targets.Peds or {}
Targets.Zones = Targets.Zones or {}

local function targetReady()
    return Config.Target.UseTarget
        and Config.Target.Resource
        and GetResourceState(Config.Target.Resource) == 'started'
        and exports.ox_target ~= nil
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if not IsModelInCdimage(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(25)
    end

    if not HasModelLoaded(hash) then
        return nil
    end

    return hash
end

function Targets.CreatePed(garage)
    if not garage.ped or garage.ped.enabled == false or not garage.ped.coords then
        return nil
    end

    local hash = loadModel(garage.ped.model)

    if not hash then
        ClientUtils.Debug(('Unable to load ped model for garage %s.'):format(garage.id))
        return nil
    end

    local coords = garage.ped.coords
    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w or 0.0, false, true)

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if garage.ped.scenario then
        TaskStartScenarioInPlace(ped, garage.ped.scenario, 0, true)
    end

    Targets.Peds[#Targets.Peds + 1] = ped
    SetModelAsNoLongerNeeded(hash)
    return ped
end

function Targets.AddPedTarget(ped, garage)
    if not targetReady() or not ped then
        return false
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = ('w2f_garage_open_%s'):format(garage.id),
            icon = 'fa-solid fa-warehouse',
            label = ('Open %s'):format(garage.label),
            distance = Config.Target.InteractionDistance,
            onSelect = function()
                TriggerEvent(W2F_GARAGE.Events.OpenGarage, garage.id)
            end
        }
    })

    return true
end

function Targets.AddStoreTargets(garage)
    if not targetReady() then
        return false
    end

    for index, storeZone in ipairs(garage.storeZones or {}) do
        local zoneName = ('w2f_garage_store_%s_%s'):format(garage.id, index)

        exports.ox_target:addBoxZone({
            name = zoneName,
            coords = storeZone.coords,
            size = storeZone.size or vec3(5.0, 5.0, 4.0),
            rotation = storeZone.rotation or 0.0,
            debug = Config.Debug,
            options = {
                {
                    name = zoneName,
                    icon = 'fa-solid fa-square-parking',
                    label = ('Store at %s'):format(garage.label),
                    distance = Config.Target.InteractionDistance,
                    onSelect = function()
                        Store.RequestVehicle(garage.id)
                    end
                }
            }
        })

        Targets.Zones[#Targets.Zones + 1] = zoneName
    end

    return true
end

function Targets.InitPublic()
    if not targetReady() or not BasicPublicGarages.IsEnabled() then
        return false
    end

    for garageId, garage in pairs(BasicPublicGarages.GetAll()) do
        if garage.coords then
            local entryZone = ('w2f_public_entry_%s'):format(garageId)

            exports.ox_target:addSphereZone({
                name = entryZone,
                coords = garage.coords,
                radius = Config.Target.InteractionDistance or 2.5,
                debug = Config.Debug,
                options = {
                    {
                        name = entryZone .. '_open',
                        icon = 'fa-solid fa-warehouse',
                        label = garage.label,
                        onSelect = function()
                            ClientPublicGarage.Open(garageId)
                        end
                    }
                }
            })

            Targets.Zones[#Targets.Zones + 1] = entryZone
        end

        if garage.storeCoords then
            local storeZone = ('w2f_public_store_%s'):format(garageId)

            exports.ox_target:addSphereZone({
                name = storeZone,
                coords = garage.storeCoords,
                radius = Config.Target.InteractionDistance or 2.5,
                debug = Config.Debug,
                options = {
                    {
                        name = storeZone .. '_store',
                        icon = 'fa-solid fa-square-parking',
                        label = 'Store Vehicle',
                        onSelect = function()
                            ClientPublicGarage.Store(garageId)
                        end
                    }
                }
            })

            Targets.Zones[#Targets.Zones + 1] = storeZone
        end
    end

    return true
end

function Targets.InitProperty()
    if not targetReady() or not Config.Property or not Config.Property.Enabled then
        return false
    end

    for garageId, garage in pairs(PropertyGarages.GetAll()) do
        local coords = garage.exteriorEntryCoords

        if coords and not PropertyGarages.IsTodoCoords(coords) then
            local zoneName = ('w2f_property_entry_%s'):format(garageId)

            exports.ox_target:addSphereZone({
                name = zoneName,
                coords = coords,
                radius = Config.Target.InteractionDistance or 2.5,
                debug = Config.Debug,
                options = {
                    {
                        name = zoneName .. '_manage',
                        icon = 'fa-solid fa-building',
                        label = garage.label,
                        onSelect = function()
                            ClientProperty.OpenDashboard(garageId)
                        end
                    },
                    {
                        name = zoneName .. '_enter',
                        icon = 'fa-solid fa-door-open',
                        label = 'Enter Garage',
                        canInteract = function()
                            return garage.enterEnabled ~= false
                        end,
                        onSelect = function()
                            ClientProperty.Enter(garageId, 1)
                        end
                    },
                    {
                        name = zoneName .. '_store',
                        icon = 'fa-solid fa-square-parking',
                        label = 'Store Vehicle',
                        canInteract = function()
                            return garage.storeEnabled ~= false
                        end,
                        onSelect = function()
                            ClientProperty.StoreAtGarage(garageId)
                        end
                    }
                }
            })

            Targets.Zones[#Targets.Zones + 1] = zoneName
        end
    end

    return true
end

function Targets.Init()
    if not targetReady() then
        ClientUtils.Debug('ox_target is unavailable; target interactions skipped.')
        return false
    end

    for _, garage in pairs(Garages.GetEnabled()) do
        local ped = Targets.CreatePed(garage)

        if ped then
            Targets.AddPedTarget(ped, garage)
        end

        Targets.AddStoreTargets(garage)
    end

    ClientUtils.Debug(('Created %s target peds and %s target zones.'):format(#Targets.Peds, #Targets.Zones))
    return true
end

function Targets.Destroy()
    if GetResourceState(Config.Target.Resource) == 'started' then
        for _, ped in ipairs(Targets.Peds) do
            exports.ox_target:removeLocalEntity(ped)
        end

        for _, zoneName in ipairs(Targets.Zones) do
            exports.ox_target:removeZone(zoneName)
        end
    end

    for _, ped in ipairs(Targets.Peds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    Targets.Peds = {}
    Targets.Zones = {}
end
