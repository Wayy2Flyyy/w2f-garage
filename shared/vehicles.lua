Vehicles = Vehicles or {}

Vehicles.ClassLabels = {
    [0] = 'Compact',
    [1] = 'Sedan',
    [2] = 'SUV',
    [3] = 'Coupe',
    [4] = 'Muscle',
    [5] = 'Sports Classic',
    [6] = 'Sports',
    [7] = 'Super',
    [8] = 'Motorcycle',
    [9] = 'Off-road',
    [10] = 'Industrial',
    [11] = 'Utility',
    [12] = 'Van',
    [13] = 'Cycle',
    [14] = 'Boat',
    [15] = 'Helicopter',
    [16] = 'Plane',
    [17] = 'Service',
    [18] = 'Emergency',
    [19] = 'Military',
    [20] = 'Commercial',
    [21] = 'Train',
    [22] = 'Open Wheel'
}

Vehicles.StateLabels = {
    [W2F_GARAGE.VehicleStates.STORED] = Locale.status_stored,
    [W2F_GARAGE.VehicleStates.OUT] = Locale.status_out,
    [W2F_GARAGE.VehicleStates.IMPOUNDED] = Locale.status_impounded,
    [W2F_GARAGE.VehicleStates.DESTROYED] = Locale.status_destroyed,
    [W2F_GARAGE.VehicleStates.SEIZED] = Locale.status_seized,
    [W2F_GARAGE.VehicleStates.REPAIR] = Locale.status_repair,
    [W2F_GARAGE.VehicleStates.TRANSFERRED] = Locale.status_transferred,
    [W2F_GARAGE.VehicleStates.UNKNOWN] = Locale.status_unknown
}

function Vehicles.GetClassLabel(classId)
    return Vehicles.ClassLabels[classId] or 'Unknown'
end

function Vehicles.GetStateLabel(state)
    return Vehicles.StateLabels[state] or Vehicles.StateLabels[W2F_GARAGE.VehicleStates.UNKNOWN]
end

function Vehicles.BuildDisplayVehicle(data)
    data = data or {}

    return {
        plate = data.plate or 'UNKNOWN',
        model = data.model or data.vehicle or 'Unknown vehicle',
        garage = data.garage or data.garageId or 'unknown',
        state = data.state or W2F_GARAGE.VehicleStates.UNKNOWN,
        fuel = data.fuel or 0,
        engine = data.engine or data.engineHealth or 0,
        body = data.body or data.bodyHealth or 0,
        classLabel = Vehicles.GetClassLabel(data.class or data.classId),
        favourite = data.favourite == true
    }
end
