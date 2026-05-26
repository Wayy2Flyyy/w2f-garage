Security = Security or {}

function Security.ValidatePlayer(source)
    if not source or source <= 0 then
        return false, 'invalid_source'
    end

    if not Bridge.GetPlayer(source) and Bridge.ActiveFramework ~= 'none' then
        return false, 'player_not_found'
    end

    return true
end

function Security.ValidateGarageAccess(source, garageId)
    local validPlayer, playerReason = Security.ValidatePlayer(source)

    if not validPlayer then
        return false, playerReason
    end

    if BasicPublicGarages and BasicPublicGarages.Get(garageId) and BasicPublicGarages.IsEnabled() then
        return true
    end

    if PropertyGarages and PropertyGarages.Get(garageId) then
        local access, reason = Property.CanAccessGarage(source, garageId)
        return access, reason
    end

    local garage = ServerUtils.GetGarage(garageId)

    if not garage then
        return false, 'invalid_garage'
    end

    if garage.enabled == false then
        return false, 'garage_disabled'
    end

    local restrictions = garage.restrictions or {}
    local jobs = restrictions.jobs or {}
    local gangs = restrictions.gangs or {}
    local requiresJob = next(jobs) ~= nil
    local requiresGang = next(gangs) ~= nil

    if requiresJob then
        local job = Bridge.GetJob(source)

        if not job or not jobs[job.name] then
            return false, 'job_denied'
        end

        if (job.grade or 0) < (restrictions.minimumJobGrade or 0) then
            return false, 'job_grade_denied'
        end
    end

    if requiresGang then
        local gang = Bridge.GetGang(source)

        if not gang or not gangs[gang.name] then
            return false, 'gang_denied'
        end

        if (gang.grade or 0) < (restrictions.minimumGangGrade or 0) then
            return false, 'gang_grade_denied'
        end
    end

    return true
end

function Security.ValidateVehicleOwnership(source, plate)
    local validPlayer, playerReason = Security.ValidatePlayer(source)

    if not validPlayer then
        return false, playerReason
    end

    plate = ServerUtils.NormalizePlate(plate)

    if not plate then
        return false, 'invalid_plate'
    end

    local identifier = Bridge.GetIdentifier(source)

    if not identifier then
        return false, 'missing_identifier'
    end

    local vehicle = Database.GetVehicleByPlate(plate)

    if not vehicle then
        return false, 'vehicle_not_found'
    end

    local ownerColumn = Config.Database.Columns.owner

    if ownerColumn and vehicle[ownerColumn] == identifier then
        return true, nil, vehicle
    end

    Logs.Security(source, W2F_GARAGE.LogActions.INVALID_OWNERSHIP, {
        plate = plate,
        reason = 'owner_mismatch_or_unmapped'
    })

    return false, 'not_owner'
end

function Security.ValidateSpawnRequest(source, garageId, plate)
    local garageAccess, garageReason = Security.ValidateGarageAccess(source, garageId)

    if not garageAccess then
        return false, garageReason
    end

    local ownership, ownershipReason, vehicle = Security.ValidateVehicleOwnership(source, plate)

    if not ownership then
        return false, ownershipReason
    end

    if VehicleState.IsOut(plate) then
        Logs.Security(source, W2F_GARAGE.LogActions.DUPLICATE_ATTEMPT, {
            plate = plate,
            garageId = garageId
        })
        return false, 'vehicle_already_out'
    end

    return true, nil, vehicle
end

function Security.ValidateStoreRequest(source, garageId, plate)
    local garageAccess, garageReason = Security.ValidateGarageAccess(source, garageId)

    if not garageAccess then
        return false, garageReason
    end

    local ownership, ownershipReason, vehicle = Security.ValidateVehicleOwnership(source, plate)

    if not ownership then
        return false, ownershipReason
    end

    return true, nil, vehicle
end

function Security.ValidateImpoundPayment(source, plate, garageId)
    local garageAccess, garageReason = Security.ValidateGarageAccess(source, garageId)

    if not garageAccess then
        return false, garageReason
    end

    local garage = ServerUtils.GetGarage(garageId)
    local fee = garage and garage.impoundFee or 0

    if fee > 0 and not Bridge.HasMoney(source, 'bank', fee) then
        return false, 'not_enough_money'
    end

    return true
end

function Security.ValidateAdmin(source, permission)
    local required = permission or (Config.Admin and Config.Admin.Permission) or 'admin'

    if source == 0 then
        return true
    end

    if Bridge.HasPermission(source, required) then
        return true
    end

    Logs.Security(source, W2F_GARAGE.LogActions.ADMIN_ACTION, {
        reason = 'permission_denied',
        required = required
    })

    return false, 'permission_denied'
end
