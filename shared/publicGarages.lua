BasicPublicGarages = BasicPublicGarages or {}

Config.BasicPublicGarages = Config.BasicPublicGarages or {
    ['legion_square'] = {
        label = 'Legion Square Public Garage',
        type = 'public',
        unlimitedStorage = true,
        dailyVehicleFee = 700,
        coords = vec3(215.12, -810.34, 30.73),
        storeCoords = vec3(216.43, -785.21, 30.81),
        spawn = vec4(229.54, -800.12, 30.57, 160.0),
        blip = true,
    },

    ['pillbox_hill'] = {
        label = 'Pillbox Hill Public Garage',
        type = 'public',
        unlimitedStorage = true,
        dailyVehicleFee = 700,
        coords = vec3(276.15, -344.01, 44.91),
        storeCoords = vec3(283.21, -342.15, 44.92),
        spawn = vec4(285.32, -335.11, 44.91, 160.0),
        blip = true,
    },

    ['vespucci_beach'] = {
        label = 'Vespucci Beach Public Garage',
        type = 'public',
        unlimitedStorage = true,
        dailyVehicleFee = 700,
        coords = vec3(-1184.85, -1509.92, 4.65),
        storeCoords = vec3(-1186.41, -1492.27, 4.38),
        spawn = vec4(-1190.33, -1485.54, 4.38, 305.0),
        blip = true,
    },

    ['sandy_shores'] = {
        label = 'Sandy Shores Public Garage',
        type = 'public',
        unlimitedStorage = true,
        dailyVehicleFee = 700,
        coords = vec3(1737.59, 3710.20, 34.14),
        storeCoords = vec3(1737.84, 3718.12, 34.05),
        spawn = vec4(1730.31, 3712.66, 34.16, 20.0),
        blip = true,
    },

    ['paleto_bay'] = {
        label = 'Paleto Bay Public Garage',
        type = 'public',
        unlimitedStorage = true,
        dailyVehicleFee = 700,
        coords = vec3(105.35, 6613.58, 31.84),
        storeCoords = vec3(112.42, 6607.24, 31.86),
        spawn = vec4(120.13, 6605.82, 31.86, 270.0),
        blip = true,
    },

    ['airport'] = {
        label = 'Airport Public Garage',
        type = 'public',
        unlimitedStorage = true,
        dailyVehicleFee = 700,
        coords = vec3(-938.76, -2607.91, 13.98),
        storeCoords = vec3(-950.22, -2604.71, 13.83),
        spawn = vec4(-955.54, -2608.12, 13.83, 60.0),
        blip = true,
    },
}

function BasicPublicGarages.IsEnabled()
    return Config.PublicGarages and Config.PublicGarages.enabled == true
end

function BasicPublicGarages.Get(id)
    return Config.BasicPublicGarages[id]
end

function BasicPublicGarages.GetAll()
    return Config.BasicPublicGarages
end

function BasicPublicGarages.GetSpawn(garageId)
    local garage = BasicPublicGarages.Get(garageId)
    return garage and garage.spawn
end

function BasicPublicGarages.GetDailyFee(garageId)
    local garage = BasicPublicGarages.Get(garageId)
    local settings = Config.PublicGarages or {}

    if garage and garage.dailyVehicleFee then
        return garage.dailyVehicleFee
    end

    return settings.dailyVehicleFee or 700
end

function BasicPublicGarages.Enrich(id)
    local garage = BasicPublicGarages.Get(id)

    if not garage then
        return nil
    end

    local settings = Config.PublicGarages or {}

    return {
        id = id,
        label = garage.label,
        type = garage.type or 'public',
        unlimitedStorage = garage.unlimitedStorage ~= false,
        dailyVehicleFee = BasicPublicGarages.GetDailyFee(id),
        coords = garage.coords,
        storeCoords = garage.storeCoords,
        spawn = garage.spawn,
        blip = garage.blip,
        sharedPublicStorage = settings.sharedPublicStorage == true,
        maxVehicles = settings.maxVehicles,
        billingMode = settings.billingMode or 'realtime',
    }
end
