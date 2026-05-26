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

Config.DebugCommands = {
    OpenGarage = true,
    PrintState = true
}
