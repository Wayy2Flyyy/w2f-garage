Zones = Zones or {}
Zones.Created = Zones.Created or {}

local function addZone(zone)
    if zone then
        Zones.Created[#Zones.Created + 1] = zone
    end
end

local function showText(text)
    if lib and lib.showTextUI then
        lib.showTextUI(text)
    end
end

local function hideText()
    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end

function Zones.CreateGarageZone(garage)
    if not lib or not lib.zones or not garage.coords then
        return nil
    end

    return lib.zones.sphere({
        coords = garage.coords,
        radius = garage.radius or Config.Target.InteractionDistance,
        debug = Config.Debug,
        onEnter = function()
            showText(('[E] Open %s'):format(garage.label))
        end,
        onExit = function()
            hideText()
        end,
        inside = function()
            if IsControlJustReleased(0, 38) then
                TriggerEvent(W2F_GARAGE.Events.OpenGarage, garage.id)
            end
        end
    })
end

function Zones.CreateStoreZone(garage, zoneConfig)
    if not lib or not lib.zones or not zoneConfig.coords then
        return nil
    end

    return lib.zones.box({
        coords = zoneConfig.coords,
        size = zoneConfig.size or vec3(5.0, 5.0, 4.0),
        rotation = zoneConfig.rotation or 0.0,
        debug = Config.Debug,
        onEnter = function()
            showText(('[E] Store vehicle at %s'):format(garage.label))
        end,
        onExit = function()
            hideText()
        end,
        inside = function()
            if IsControlJustReleased(0, 38) then
                Store.RequestVehicle(garage.id)
            end
        end
    })
end

function Zones.InitProperty()
    if not Config.Property or not Config.Property.Enabled then
        return false
    end

    if Config.Target.UseTarget and GetResourceState(Config.Target.Resource) == 'started' and not Config.Target.FallbackZones then
        return true
    end

    if not lib or not lib.zones then
        return false
    end

    for garageId, garage in pairs(PropertyGarages.GetAll()) do
        local coords = garage.exteriorEntryCoords

        if coords and not PropertyGarages.IsTodoCoords(coords) then
            local pseudoGarage = {
                id = garageId,
                label = garage.label,
                coords = coords,
                radius = Config.Target.InteractionDistance
            }

            addZone(Zones.CreateGarageZone({
                id = garageId,
                label = garage.label,
                coords = coords,
                radius = Config.Target.InteractionDistance
            }))
        end
    end

    return true
end

function Zones.Init()
    if Config.Target.UseTarget and GetResourceState(Config.Target.Resource) == 'started' and not Config.Target.FallbackZones then
        ClientUtils.Debug('Skipping fallback zones because target interactions are active.')
        return true
    end

    if not lib or not lib.zones then
        ClientUtils.Debug('ox_lib zones are unavailable; no fallback zones created.')
        return false
    end

    for _, garage in pairs(Garages.GetEnabled()) do
        addZone(Zones.CreateGarageZone(garage))

        for _, storeZone in ipairs(garage.storeZones or {}) do
            addZone(Zones.CreateStoreZone(garage, storeZone))
        end
    end

    ClientUtils.Debug(('Created %s garage/store zones.'):format(#Zones.Created))
    return true
end

function Zones.Destroy()
    for _, zone in ipairs(Zones.Created) do
        if zone and zone.remove then
            zone:remove()
        end
    end

    Zones.Created = {}
    hideText()
end
