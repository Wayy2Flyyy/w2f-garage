W2F_GARAGE = W2F_GARAGE or {}

W2F_GARAGE.RESOURCE = GetCurrentResourceName and GetCurrentResourceName() or 'w2f-garage'

W2F_GARAGE.VehicleStates = {
    STORED = 'stored',
    OUT = 'out',
    IMPOUNDED = 'impounded',
    DESTROYED = 'destroyed',
    SEIZED = 'seized',
    IN_REPAIR = 'in_repair',
    TRANSFERRED = 'transferred',
    UNKNOWN = 'unknown'
}

-- Legacy alias
W2F_GARAGE.VehicleStates.REPAIR = W2F_GARAGE.VehicleStates.IN_REPAIR

W2F_GARAGE.GarageTypes = {
    PUBLIC = 'public',
    JOB = 'job',
    GANG = 'gang',
    DEPOT = 'depot',
    PRIVATE = 'private',
    BUSINESS = 'business',
    EMERGENCY = 'emergency',
    HIDDEN = 'hidden',
    PROPERTY = 'property'
}

W2F_GARAGE.PropertyClasses = {
    LOW_END = 'low-end',
    MEDIUM = 'medium',
    HIGH_END = 'high-end',
    HIGH_END_CUSTOM = 'high-end-custom'
}

W2F_GARAGE.Events = {
    OpenGarage = 'w2f-garage:client:openGarage',
    CloseGarage = 'w2f-garage:client:closeGarage',
    EnterGarage = 'w2f-garage:client:enterGarage',
    ExitGarage = 'w2f-garage:client:exitGarage',
    SpawnVehicle = 'w2f-garage:client:spawnVehicle',
    StoreVehicle = 'w2f-garage:client:storeVehicle',
    RefreshGarage = 'w2f-garage:client:refreshGarage',
    PropertyEnter = 'w2f-garage:client:propertyEnter',
    PropertyExit = 'w2f-garage:client:propertyExit',
    InteriorLoadVehicles = 'w2f-garage:client:interiorLoadVehicles',
    InteriorUnloadVehicles = 'w2f-garage:client:interiorUnloadVehicles',
    InteriorSpawnDisplay = 'w2f-garage:client:interiorSpawnDisplay',
    InteriorRemoveDisplay = 'w2f-garage:client:interiorRemoveDisplay',
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
    AdminSearchVehicle = 'w2f-garage:server:adminSearchVehicle',
    GetPropertyGarages = 'w2f-garage:server:getPropertyGarages',
    GetOwnedGarages = 'w2f-garage:server:getOwnedGarages',
    BuyGarage = 'w2f-garage:server:buyGarage',
    SellGarage = 'w2f-garage:server:sellGarage',
    EnterGarage = 'w2f-garage:server:enterGarage',
    ExitGarage = 'w2f-garage:server:exitGarage',
    MoveVehicleSlot = 'w2f-garage:server:moveVehicleSlot',
    GetGarageVehicles = 'w2f-garage:server:getGarageVehicles',
    PropertySpawnVehicle = 'w2f-garage:server:propertySpawnVehicle',
    PropertyStoreVehicle = 'w2f-garage:server:propertyStoreVehicle',
    GetPropertyDashboard = 'w2f-garage:server:getPropertyDashboard'
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
    SECURITY_WARNING = 'security_warning',
    GARAGE_PURCHASED = 'garage_purchased',
    GARAGE_SOLD = 'garage_sold',
    GARAGE_ENTER = 'garage_enter',
    GARAGE_EXIT = 'garage_exit',
    SLOT_ASSIGNED = 'slot_assigned',
    SLOT_MOVED = 'slot_moved'
}

W2F_GARAGE.ValidFrameworks = {
    auto = true,
    qbcore = true,
    qbox = true,
    esx = true
}

W2F_GARAGE.SlotTypes = {
    VEHICLE = 'vehicle',
    BICYCLE = 'bicycle'
}
