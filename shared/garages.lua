Garages = Garages or {}

Garages.List = {
    legion_public = {
        id = 'legion_public',
        label = 'Legion Square Garage',
        type = W2F_GARAGE.GarageTypes.PUBLIC,
        enabled = true,
        coords = vec3(215.82, -810.06, 30.73),
        radius = 4.0,
        ped = {
            enabled = true,
            model = 's_m_m_autoshop_01',
            coords = vec4(215.82, -810.06, 30.73, 159.0),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        },
        blip = {
            enabled = true,
            sprite = 357,
            colour = 3,
            scale = 0.72,
            label = 'Public Garage'
        },
        spawnPoints = {
            vec4(229.45, -800.24, 30.56, 157.0),
            vec4(232.62, -801.38, 30.54, 157.0),
            vec4(235.75, -802.47, 30.53, 157.0)
        },
        storeZones = {
            {
                coords = vec3(218.84, -781.12, 30.74),
                size = vec3(14.0, 10.0, 4.0),
                rotation = 70.0
            }
        },
        restrictions = {
            jobs = {},
            gangs = {},
            minimumJobGrade = 0,
            minimumGangGrade = 0,
            vehicleClasses = {}
        },
        impoundFee = 0,
        camera = {
            coords = vec3(223.5, -804.7, 33.2),
            rotation = vec3(-12.0, 0.0, 40.0),
            fov = 48.0
        },
        ui = {
            accent = '#d7ff3f',
            theme = 'premium-dark'
        }
    },

    city_depot = {
        id = 'city_depot',
        label = 'City Depot',
        type = W2F_GARAGE.GarageTypes.DEPOT,
        enabled = true,
        coords = vec3(409.54, -1623.08, 29.29),
        radius = 4.0,
        ped = {
            enabled = true,
            model = 's_m_y_construct_01',
            coords = vec4(409.54, -1623.08, 29.29, 229.0),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        },
        blip = {
            enabled = true,
            sprite = 68,
            colour = 17,
            scale = 0.72,
            label = 'Vehicle Depot'
        },
        spawnPoints = {
            vec4(401.92, -1631.79, 29.29, 231.0),
            vec4(397.92, -1634.84, 29.29, 231.0)
        },
        storeZones = {
            {
                coords = vec3(397.44, -1642.69, 29.29),
                size = vec3(18.0, 12.0, 4.0),
                rotation = 50.0
            }
        },
        restrictions = {
            jobs = {},
            gangs = {},
            minimumJobGrade = 0,
            minimumGangGrade = 0,
            vehicleClasses = {}
        },
        impoundFee = 750,
        camera = {
            coords = vec3(407.4, -1637.4, 32.6),
            rotation = vec3(-12.0, 0.0, 42.0),
            fov = 50.0
        },
        ui = {
            accent = '#ffb347',
            theme = 'premium-dark'
        }
    },

    police_mission_row = {
        id = 'police_mission_row',
        label = 'Mission Row Fleet',
        type = W2F_GARAGE.GarageTypes.EMERGENCY,
        enabled = false,
        coords = vec3(441.05, -1013.13, 28.64),
        radius = 4.0,
        ped = {
            enabled = false,
            model = 's_m_y_cop_01',
            coords = vec4(441.05, -1013.13, 28.64, 90.0)
        },
        blip = {
            enabled = false,
            sprite = 357,
            colour = 29,
            scale = 0.65,
            label = 'Police Garage'
        },
        spawnPoints = {
            vec4(446.57, -1025.82, 28.21, 5.0)
        },
        storeZones = {},
        restrictions = {
            jobs = { police = true },
            gangs = {},
            minimumJobGrade = 0,
            minimumGangGrade = 0,
            vehicleClasses = {}
        },
        impoundFee = 0,
        camera = {
            coords = vec3(450.0, -1022.5, 31.2),
            rotation = vec3(-10.0, 0.0, 140.0),
            fov = 48.0
        },
        ui = {
            accent = '#5ea8ff',
            theme = 'premium-dark'
        }
    },

    grove_gang = {
        id = 'grove_gang',
        label = 'Grove Street Lockup',
        type = W2F_GARAGE.GarageTypes.GANG,
        enabled = false,
        coords = vec3(-63.25, -1839.52, 26.8),
        radius = 4.0,
        ped = {
            enabled = false,
            model = 'g_m_y_famdnf_01',
            coords = vec4(-63.25, -1839.52, 26.8, 316.0)
        },
        blip = {
            enabled = false,
            sprite = 357,
            colour = 25,
            scale = 0.65,
            label = 'Gang Garage'
        },
        spawnPoints = {
            vec4(-59.55, -1844.62, 26.32, 318.0)
        },
        storeZones = {},
        restrictions = {
            jobs = {},
            gangs = { families = true },
            minimumJobGrade = 0,
            minimumGangGrade = 0,
            vehicleClasses = {}
        },
        impoundFee = 0,
        camera = {
            coords = vec3(-55.5, -1841.5, 29.8),
            rotation = vec3(-12.0, 0.0, 130.0),
            fov = 48.0
        },
        ui = {
            accent = '#55ff88',
            theme = 'premium-dark'
        }
    }
}

function Garages.Get(id)
    return Garages.List[id]
end

function Garages.GetEnabled()
    local enabled = {}

    for id, garage in pairs(Garages.List) do
        if garage.enabled then
            enabled[id] = garage
        end
    end

    return enabled
end
