PropertyGarages = PropertyGarages or {}

local LOW_INTERIOR_BASE = vec3(173.2903, -1003.6000, -99.6571)
local MEDIUM_INTERIOR_BASE = vec3(197.8153, -1002.2930, -99.6575)
local HIGH_INTERIOR_BASE = vec3(229.9559, -981.7928, -99.6607)

local function propertyDefaults()
    return {
        purchaseEnabled = true,
        storeEnabled = true,
        enterEnabled = true,
        interiorEnabled = true,
        publicMode = false,
        blip = {
            enabled = true,
            sprite = 473,
            colour = 3,
            scale = 0.65,
        },
        exteriorVehiclePreviewCoords = 'TODO_CAPTURE',
        slotLayout = 'default',
        ownershipState = 'unowned',
        storedVehicles = {},
        usedSlots = 0,
        freeSlots = 0,
        exteriorStoreCoords = 'TODO_CAPTURE',
        exteriorVehicleSpawn = 'TODO_CAPTURE_VEC4',
        interiorEntryCoords = 'TODO_CAPTURE_VEC4',
        interiorExitCoords = 'TODO_CAPTURE_VEC4',
        interiorVehicleSlots = {},
        bicycleSlots = {},
        cameraCoords = 'TODO_CAPTURE',
    }
end

local function merge(base, overrides)
    local result = {}

    for key, value in pairs(base) do
        result[key] = value
    end

    for key, value in pairs(overrides) do
        result[key] = value
    end

    return result
end

local function lowEnd(overrides)
    return merge(propertyDefaults(), merge({
        propertyClass = 'low-end',
        vehicleCapacity = 2,
        bicycleCapacity = 1,
        interiorTemplate = 'low_2_car_garage',
        interiorBaseCoords = LOW_INTERIOR_BASE,
        exteriorStoreCoords = 'TODO_CAPTURE',
        exteriorVehicleSpawn = 'TODO_CAPTURE_VEC4',
        interiorEntryCoords = 'TODO_CAPTURE_VEC4',
        interiorExitCoords = 'TODO_CAPTURE_VEC4',
        interiorVehicleSlots = {},
        bicycleSlots = {},
    }, overrides))
end

local function medium(overrides)
    return merge(propertyDefaults(), merge({
        propertyClass = 'medium',
        vehicleCapacity = 6,
        bicycleCapacity = 2,
        interiorTemplate = 'medium_6_car_garage',
        interiorBaseCoords = MEDIUM_INTERIOR_BASE,
        exteriorStoreCoords = 'TODO_CAPTURE',
        exteriorVehicleSpawn = 'TODO_CAPTURE_VEC4',
        interiorEntryCoords = 'TODO_CAPTURE_VEC4',
        interiorExitCoords = 'TODO_CAPTURE_VEC4',
        interiorVehicleSlots = {},
        bicycleSlots = {},
    }, overrides))
end

local function highEnd(overrides)
    return merge(propertyDefaults(), merge({
        propertyClass = 'high-end',
        vehicleCapacity = 10,
        bicycleCapacity = 3,
        interiorTemplate = 'highend_10_car_garage',
        interiorBaseCoords = HIGH_INTERIOR_BASE,
        exteriorStoreCoords = 'TODO_CAPTURE',
        exteriorVehicleSpawn = 'TODO_CAPTURE_VEC4',
        interiorEntryCoords = 'TODO_CAPTURE_VEC4',
        interiorExitCoords = 'TODO_CAPTURE_VEC4',
        interiorVehicleSlots = {},
        bicycleSlots = {},
    }, overrides))
end

Config.PropertyGarages = Config.PropertyGarages or {
    -- =========================================================
    -- LOW-END GARAGES / 2 CAR GARAGES
    -- Interior Template Base: vec3(173.2903, -1003.6000, -99.6571)
    -- Capacity: 2 vehicles / 1 bicycle
    -- =========================================================

    ['142_paleto_blvd'] = lowEnd({
        label = '142 Paleto Blvd',
        price = 26500,
        exteriorEntryCoords = vec3(-68.7020, 6426.1479, 30.4389),
    }),

    ['1920_senora_way'] = lowEnd({
        label = '1920 Senora Way',
        price = 32000,
        exteriorEntryCoords = vec3(2461.2202, 1589.2552, 32.0443),
    }),

    ['197_route_68'] = lowEnd({
        label = '197 Route 68',
        price = 29000,
        exteriorEntryCoords = vec3(218.0665, 2601.8171, 44.7668),
    }),

    ['1932_grapeseed_ave'] = lowEnd({
        label = '1932 Grapeseed Ave',
        price = 27500,
        exteriorEntryCoords = vec3(2554.1653, 4668.0591, 33.0233),
    }),

    ['1200_route_68'] = lowEnd({
        label = '1200 Route 68',
        price = 28000,
        exteriorEntryCoords = vec3(639.4500, 2771.2000, 41.2000),
    }),

    ['1_strawberry_ave'] = lowEnd({
        label = '1 Strawberry Ave',
        price = 26000,
        exteriorEntryCoords = vec3(-245.5158, 6239.0479, 30.4892),
    }),

    ['2000_great_ocean_highway'] = lowEnd({
        label = '2000 Great Ocean Highway',
        price = 31500,
        exteriorEntryCoords = vec3(-2203.3350, 4244.4272, 47.3305),
    }),

    ['unit_124_popular_st'] = lowEnd({
        label = 'Unit 124 Popular St',
        price = 25000,
        exteriorEntryCoords = vec3(727.7570, -1189.8367, 23.2765),
    }),

    ['0754_roy_lowenstein_blvd'] = lowEnd({
        label = '0754 Roy Lowenstein Blvd',
        price = 29500,
        exteriorEntryCoords = vec3(528.8805, -1603.0293, 28.3225),
    }),

    ['12_little_bighorn_ave'] = lowEnd({
        label = '12 Little Bighorn Ave',
        price = 32000,
        exteriorEntryCoords = vec3(569.9441, -1570.2930, 27.5777),
    }),

    ['0897_mirror_park_blvd'] = lowEnd({
        label = '0897 Mirror Park Blvd',
        price = 35000,
        exteriorEntryCoords = vec3(899.8448, -147.5280, 75.5674),
    }),

    ['634_blvd_del_perro'] = lowEnd({
        label = '634 Blvd Del Perro',
        price = 33500,
        exteriorEntryCoords = vec3(-1241.5399, -259.8841, 37.9445),
    }),

    ['garage_innocence_blvd'] = lowEnd({
        label = 'Garage Innocence Blvd',
        price = 34000,
        exteriorEntryCoords = vec3(-342.5126, -1468.6746, 29.6107),
    }),

    -- =========================================================
    -- MEDIUM GARAGES / 6 CAR GARAGES
    -- Interior Template Base: vec3(197.8153, -1002.2930, -99.6575)
    -- Capacity: 6 vehicles / 2 bicycles
    -- =========================================================

    ['0552_roy_lowenstein_blvd'] = medium({
        label = '0552 Roy Lowenstein Blvd',
        price = 80000,
        exteriorEntryCoords = vec3(504.6782, -1492.8872, 28.2886),
    }),

    ['870_route_68_approach'] = medium({
        label = '870 Route 68 Approach',
        price = 62500,
        exteriorEntryCoords = vec3(186.1719, 2786.3425, 45.0144),
    }),

    ['8754_route_68'] = medium({
        label = '8754 Route 68',
        price = 65000,
        exteriorEntryCoords = vec3(-1130.9376, 2701.1333, 17.8004),
    }),

    ['unit_1_olympic_fwy'] = medium({
        label = 'Unit 1 Olympic Fwy',
        price = 70000,
        exteriorEntryCoords = vec3(842.1298, -1165.0754, 24.3046),
    }),

    ['unit_14_popular_st'] = medium({
        label = 'Unit 14 Popular St',
        price = 77500,
        exteriorEntryCoords = vec3(895.9359, -888.7846, 26.2485),
    }),

    ['4531_dry_dock_st'] = medium({
        label = '4531 Dry Dock St',
        price = 67500,
        exteriorEntryCoords = vec3(870.8577, -2232.3228, 29.5508),
    }),

    ['0432_davis_ave'] = medium({
        label = '0432 Davis Ave',
        price = 72500,
        exteriorEntryCoords = vec3(475.7058, -1547.1232, 28.2828),
    }),

    ['1905_davis_ave'] = medium({
        label = '1905 Davis Ave',
        price = 75000,
        exteriorEntryCoords = vec3(-10.9440, -1646.7601, 28.3125),
    }),

    -- =========================================================
    -- HIGH-END GARAGES / 10 CAR GARAGES
    -- Interior Template Base: vec3(229.9559, -981.7928, -99.6607)
    -- Capacity: 10 vehicles / 3 bicycles
    -- =========================================================

    ['331_supply_st'] = highEnd({
        label = '331 Supply St',
        price = 135000,
        exteriorEntryCoords = vec3(759.2387, -755.3151, 25.9151),
    }),

    ['unit_2_popular_st'] = highEnd({
        label = 'Unit 2 Popular St',
        price = 142500,
        exteriorEntryCoords = vec3(817.4531, -924.8551, 25.2430),
    }),

    ['0120_murrieta_heights'] = highEnd({
        label = '0120 Murrieta Heights',
        price = 150000,
        exteriorEntryCoords = vec3(963.4199, -1022.1301, 39.8474),
    }),

    ['unit_76_greenwich_parkway'] = highEnd({
        label = 'Unit 76 Greenwich Parkway',
        price = 120000,
        exteriorEntryCoords = vec3(-1088.6158, -2235.0977, 12.2182),
    }),

    ['1337_exceptionalists_way'] = highEnd({
        label = '1337 Exceptionalists Way',
        price = 112500,
        exteriorEntryCoords = vec3(-663.8541, -2380.3889, 12.9446),
    }),

    ['1623_south_shambles_st'] = highEnd({
        label = '1623 South Shambles St',
        price = 105000,
        exteriorEntryCoords = vec3(1024.2628, -2398.4036, 29.1261),
    }),

    -- FUTURE: Eclipse Blvd 50-car garage
    ['eclipse_blvd_garage'] = merge(propertyDefaults(), {
        label = 'Eclipse Blvd Garage',
        propertyClass = 'high-end-custom',
        price = 2740000,
        vehicleCapacity = 50,
        bicycleCapacity = 0,
        floorCount = 5,
        vehiclesPerFloor = 10,
        interiorTemplate = 'eclipse_50_car_garage',
        interiorBaseCoords = 'TODO_CAPTURE',
        exteriorEntryCoords = 'TODO_CAPTURE',
        exteriorStoreCoords = 'TODO_CAPTURE',
        exteriorVehicleSpawn = 'TODO_CAPTURE_VEC4',
        interiorEntryCoords = 'TODO_CAPTURE_VEC4',
        interiorExitCoords = 'TODO_CAPTURE_VEC4',
        interiorVehicleSlots = {},
        bicycleSlots = {},
        floorData = {},
        purchaseEnabled = false,
        enterEnabled = false,
        interiorEnabled = false,
    }),
}

function PropertyGarages.Get(id)
    return Config.PropertyGarages[id]
end

function PropertyGarages.GetAll()
    return Config.PropertyGarages
end

function PropertyGarages.IsPendingCoords(value)
    if value == nil then
        return true
    end

    if type(value) == 'string' then
        return value:find('TODO_', 1, true) ~= nil
    end

    if type(value) == 'table' and #value == 0 then
        return true
    end

    return false
end

--- Backwards-compatible alias.
PropertyGarages.IsTodoCoords = PropertyGarages.IsPendingCoords

function PropertyGarages.GetInteriorEnterCoords(garage)
    if not garage then
        return nil
    end

    if not PropertyGarages.IsPendingCoords(garage.interiorEntryCoords) then
        return garage.interiorEntryCoords
    end

    local base = garage.interiorBaseCoords

    if base and not PropertyGarages.IsPendingCoords(base) then
        if type(base) == 'vector3' then
            return vec4(base.x, base.y, base.z, 0.0)
        end

        if type(base) == 'vector4' then
            return base
        end

        if type(base) == 'table' and base.x then
            return vec4(base.x, base.y, base.z, base.w or 0.0)
        end
    end

    local template = garage.interiorTemplate and Interiors.Get(garage.interiorTemplate)

    if template and template.baseCoords and not PropertyGarages.IsPendingCoords(template.baseCoords) then
        local templateBase = template.baseCoords

        if type(templateBase) == 'vector3' then
            return vec4(templateBase.x, templateBase.y, templateBase.z, 0.0)
        end
    end

    return nil
end

function PropertyGarages.CanEnterInterior(garageId)
    local garage = PropertyGarages.Get(garageId)

    if not garage or garage.interiorEnabled == false or garage.enterEnabled == false then
        return false
    end

    return PropertyGarages.GetInteriorEnterCoords(garage) ~= nil
end

function PropertyGarages.IsProductionReady(garageId)
    local garage = PropertyGarages.Get(garageId)

    if not garage then
        return false
    end

    if PropertyGarages.IsPendingCoords(garage.exteriorEntryCoords) then
        return false
    end

    if PropertyGarages.IsPendingCoords(garage.exteriorStoreCoords) then
        return false
    end

    if PropertyGarages.IsPendingCoords(garage.exteriorVehicleSpawn) then
        return false
    end

    if PropertyGarages.IsPendingCoords(garage.interiorEntryCoords) then
        return false
    end

    if PropertyGarages.IsPendingCoords(garage.interiorExitCoords) then
        return false
    end

    local slots = garage.interiorVehicleSlots

    if type(slots) ~= 'table' or #slots < (garage.vehicleCapacity or 0) then
        return false
    end

    return true
end

function PropertyGarages.GetCapacity(garageId)
    local garage = PropertyGarages.Get(garageId)

    if not garage then
        return 0, 0
    end

    return garage.vehicleCapacity or 0, garage.bicycleCapacity or 0
end

function PropertyGarages.Enrich(id, runtime)
    local garage = PropertyGarages.Get(id)

    if not garage then
        return nil
    end

    local enriched = {}

    for key, value in pairs(garage) do
        enriched[key] = value
    end

    enriched.id = id
    enriched.productionReady = PropertyGarages.IsProductionReady(id)
    enriched.interiorEnterReady = PropertyGarages.CanEnterInterior(id)
    enriched.interiorEnterCoords = PropertyGarages.GetInteriorEnterCoords(garage)

    if runtime then
        for key, value in pairs(runtime) do
            enriched[key] = value
        end
    end

    return enriched
end
