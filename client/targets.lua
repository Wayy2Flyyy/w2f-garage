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
