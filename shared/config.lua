Config = Config or {}

Config.Framework = 'auto'
Config.Locale = 'en'
Config.Debug = false
Config.DebugPrefix = '[w2f-garage]'

Config.Inventory = 'auto'
Config.Fuel = 'auto'
Config.Keys = 'auto'
Config.Notify = 'ox'

Config.Target = {
    Resource = 'ox_target',
    UseTarget = true,
    FallbackZones = true,
    InteractionDistance = 2.5
}

Config.Database = {
    Enabled = false,

    Preset = 'auto',
    Presets = {
        qbox = {
            table = 'player_vehicles',
            owner = 'citizenid',
            plate = 'plate',
            vehicle = 'vehicle',
            properties = 'mods',
            garage = 'garage',
            state = 'state',
            fuel = 'fuel',
            engine = 'engine',
            body = 'body'
        },
        qbcore = {
            table = 'player_vehicles',
            owner = 'citizenid',
            plate = 'plate',
            vehicle = 'vehicle',
            properties = 'mods',
            garage = 'garage',
            state = 'state',
            fuel = 'fuel',
            engine = 'engine',
            body = 'body'
        },
        esx = {
            table = 'owned_vehicles',
            owner = 'owner',
            plate = 'plate',
            vehicle = 'vehicle',
            properties = 'vehicle',
            garage = 'garage',
            state = 'stored',
            fuel = nil,
            engine = nil,
            body = nil
        },
        custom = {
            table = nil,
            owner = nil,
            plate = nil,
            vehicle = nil,
            properties = nil,
            garage = nil,
            state = nil,
            fuel = nil,
            engine = nil,
            body = nil
        }
    },

    AutoMigrate = false,
    SafeMode = true,
    ExistingVehicleTable = nil,
    Columns = {
        owner = nil,
        plate = nil,
        vehicle = nil,
        garage = nil,
        state = nil,
        fuel = nil,
        engine = nil,
        body = nil,
        properties = nil
    },
    W2FTables = {
        logs = 'w2f_garage_logs',
        history = 'w2f_garage_vehicle_history',
        impounds = 'w2f_garage_impounds',
        stateOverrides = 'w2f_garage_state_overrides',
        transfers = 'w2f_garage_transfers',
        insurance = 'w2f_garage_insurance',
        mileage = 'w2f_garage_mileage',
        favourites = 'w2f_garage_favourites'
    }
}

Config.Security = {
    DenyUnknownStates = true,
    PreventDuplicateSpawns = true,
    RequireServerValidation = true,
    LogSuspiciousActions = true
}

Config.RestartRecovery = {
    Enabled = false,
    MarkOutVehiclesRecoverable = false,
    AdminOnly = true
}

Config.Admin = {
    Permission = 'admin',
    CommandsEnabled = true
}

Config.Logging = {
    Console = true,
    Discord = {
        Enabled = false,
        Webhook = '',
        Username = 'w2f-garage',
        AvatarUrl = ''
    }
}

Config.UI = {
    Title = 'Garage Control',
    Subtitle = 'Vehicle management dashboard',
    DefaultAccent = '#d7ff3f',
    BrowserPreview = true,
    MockDataInBrowser = true
}

Config.Features = {
    GiveKeysOnSpawn = true,
    RemoveKeysOnStore = false,
    SaveFuel = true,
    SaveDamage = true,
    SaveVehicleProperties = true,
    EnableImpoundPayments = false,
    EnableTransfers = false,
    EnableFavourites = true
}

Config.Property = {
    Enabled = true,
    PublicMode = false,
    AllowMultipleOwned = true,
    MaxOwnedGarages = 5,
    AllowSell = true,
    SellRefundPercent = 0.5,
    PurchaseAccount = 'bank',
    RequireProductionCoords = false,
    UseRoutingBuckets = true,
    RoutingBucketOffset = 0,
    AntiDuplication = true,
    InteriorDisplayVehicles = true,
    DefaultBlipLabel = 'Property Garage'
}

Config.Database.W2FTables.ownedGarages = 'w2f_owned_garages'
Config.Database.W2FTables.garageSlots = 'w2f_garage_slots'
Config.Database.W2FTables.garageInteriors = 'w2f_garage_interiors'
Config.Database.W2FTables.garageVehiclePositions = 'w2f_garage_vehicle_positions'
Config.Database.W2FTables.purchaseLogs = 'w2f_garage_purchase_logs'
Config.Database.W2FTables.publicGarageVehicles = 'w2f_public_garage_vehicles'

Config.PublicGarages = {
    enabled = true,
    sharedPublicStorage = true,
    maxVehicles = false,
    dailyVehicleFee = 700,
    billingMode = 'realtime',
    realtimeDayHours = 24,
    requirePaymentBeforeSpawn = true,
    autoChargeOnSpawn = true,
    allowNegativeBalance = false,
    chargeOnlyFullDays = true,
    useMenuOnly = true,
    paymentAccount = 'bank',
}

Config.DebugCommands = {
    OpenGarage = true,
    PrintState = true
}
