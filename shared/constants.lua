W2F_GARAGE = W2F_GARAGE or {}

W2F_GARAGE.RESOURCE = GetCurrentResourceName and GetCurrentResourceName() or 'w2f-garage'

W2F_GARAGE.VehicleStates = {
    STORED = 'stored',
    OUT = 'out',
    IMPOUNDED = 'impounded',
    DESTROYED = 'destroyed',
    SEIZED = 'seized',
    REPAIR = 'repair',
    TRANSFERRED = 'transferred',
    UNKNOWN = 'unknown'
}

W2F_GARAGE.GarageTypes = {
    PUBLIC = 'public',
    JOB = 'job',
    GANG = 'gang',
    DEPOT = 'depot',
    PRIVATE = 'private',
    BUSINESS = 'business',
    EMERGENCY = 'emergency',
    HIDDEN = 'hidden'
}

W2F_GARAGE.Events = {
    OpenGarage = 'w2f-garage:client:openGarage',
    CloseGarage = 'w2f-garage:client:closeGarage',
    SpawnVehicle = 'w2f-garage:client:spawnVehicle',
    StoreVehicle = 'w2f-garage:client:storeVehicle',
    RefreshGarage = 'w2f-garage:client:refreshGarage',
    RequestVehicles = 'w2f-garage:server:requestVehicles',
    ServerStoreVehicle = 'w2f-garage:server:storeVehicle',
    ServerRecoverVehicle = 'w2f-garage:server:recoverVehicle',
    ServerPayImpound = 'w2f-garage:server:payImpound'
}

W2F_GARAGE.Callbacks = {
    GetGarageData = 'w2f-garage:server:getGarageData',
    GetVehicles = 'w2f-garage:server:getVehicles',
    GetOwnedVehicles = 'w2f-garage:server:getOwnedVehicles',
    SpawnVehicle = 'w2f-garage:server:spawnVehicle',
    StoreVehicle = 'w2f-garage:server:storeVehicle',
    RecoverVehicle = 'w2f-garage:server:recoverVehicle',
    PayImpound = 'w2f-garage:server:payImpound',
    AdminSearchVehicle = 'w2f-garage:server:adminSearchVehicle'
}

W2F_GARAGE.LogActions = {
    SPAWNED = 'vehicle_spawned',
    STORED = 'vehicle_stored',
    IMPOUNDED = 'vehicle_impounded',
    RECOVERED = 'vehicle_recovered',
    STATE_RESET = 'vehicle_state_reset',
    DUPLICATE_ATTEMPT = 'possible_duplicate_attempt',
    INVALID_OWNERSHIP = 'invalid_ownership_attempt',
    ADMIN_ACTION = 'admin_action',
    TRANSFER = 'garage_transfer',
    IMPOUND_PAYMENT = 'impound_payment',
    SECURITY_WARNING = 'security_warning'
}

W2F_GARAGE.ValidFrameworks = {
    auto = true,
    qbcore = true,
    qbox = true,
    esx = true
}
