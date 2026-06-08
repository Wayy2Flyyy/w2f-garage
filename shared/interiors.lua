Interiors = Interiors or {}

--- Interior abstraction: native IPL, shell/MLO, or custom mapped interiors.
--- Slot positions use TODO_CAPTURE until exact vec4 data is confirmed.
Interiors.Templates = {
    low_2_car_garage = {
        id = 'low_2_car_garage',
        label = 'Low-End 2-Car Garage',
        propertyClass = 'low-end',
        vehicleCapacity = 2,
        bicycleCapacity = 1,
        type = 'shell',
        routingBucketBase = 7000,
        baseCoords = vec3(173.2903, -1003.6000, -99.6571),
        ipl = nil,
        shellModel = nil,
        entryCoords = 'TODO_CAPTURE_VEC4',
        exitCoords = 'TODO_CAPTURE_VEC4',
        cameraCoords = 'TODO_CAPTURE',
        vehicleSlots = {},
        bicycleSlots = {},
        slotLayout = {
            { index = 1, type = 'vehicle', floor = 1, coords = 'TODO_CAPTURE_VEC4' },
            { index = 2, type = 'vehicle', floor = 1, coords = 'TODO_CAPTURE_VEC4' },
            { index = 3, type = 'bicycle', floor = 1, coords = 'TODO_CAPTURE_VEC4' },
        },
        style = 'basic',
    },

    medium_6_car_garage = {
        id = 'medium_6_car_garage',
        label = 'Medium 6-Car Garage',
        propertyClass = 'medium',
        vehicleCapacity = 6,
        bicycleCapacity = 2,
        type = 'shell',
        routingBucketBase = 7100,
        baseCoords = vec3(197.8153, -1002.2930, -99.6575),
        ipl = nil,
        shellModel = nil,
        entryCoords = 'TODO_CAPTURE_VEC4',
        exitCoords = 'TODO_CAPTURE_VEC4',
        cameraCoords = 'TODO_CAPTURE',
        vehicleSlots = {},
        bicycleSlots = {},
        slotLayout = {},
        style = 'medium',
    },

    highend_10_car_garage = {
        id = 'highend_10_car_garage',
        label = 'High-End 10-Car Garage',
        propertyClass = 'high-end',
        vehicleCapacity = 10,
        bicycleCapacity = 3,
        type = 'shell',
        routingBucketBase = 7200,
        baseCoords = vec3(229.9559, -981.7928, -99.6607),
        ipl = nil,
        shellModel = nil,
        entryCoords = 'TODO_CAPTURE_VEC4',
        exitCoords = 'TODO_CAPTURE_VEC4',
        cameraCoords = 'TODO_CAPTURE',
        vehicleSlots = {},
        bicycleSlots = {},
        slotLayout = {},
        style = 'premium',
    },

    eclipse_50_car_garage = {
        id = 'eclipse_50_car_garage',
        label = 'Eclipse 50-Car Multi-Floor Garage',
        propertyClass = 'high-end-custom',
        vehicleCapacity = 50,
        bicycleCapacity = 0,
        floorCount = 5,
        vehiclesPerFloor = 10,
        type = 'custom',
        routingBucketBase = 7300,
        ipl = nil,
        shellModel = nil,
        entryCoords = 'TODO_CAPTURE_VEC4',
        exitCoords = 'TODO_CAPTURE_VEC4',
        cameraCoords = 'TODO_CAPTURE',
        floorThemes = {
            [1] = 'showroom_dark',
            [2] = 'showroom_silver',
            [3] = 'showroom_white',
            [4] = 'showroom_gold',
            [5] = 'showroom_neon',
        },
        floors = {
            [1] = { label = 'Floor 1', vehicleSlots = {}, slotLayout = {} },
            [2] = { label = 'Floor 2', vehicleSlots = {}, slotLayout = {} },
            [3] = { label = 'Floor 3', vehicleSlots = {}, slotLayout = {} },
            [4] = { label = 'Floor 4', vehicleSlots = {}, slotLayout = {} },
            [5] = { label = 'Floor 5', vehicleSlots = {}, slotLayout = {} },
        },
        style = 'eclipse',
    },
}

function Interiors.Get(templateId)
    return Interiors.Templates[templateId]
end

function Interiors.GetSlotCoords(templateId, slotIndex, floorIndex)
    local template = Interiors.Get(templateId)

    if not template then
        return nil
    end

    floorIndex = floorIndex or 1

    if template.floors and template.floors[floorIndex] then
        local floor = template.floors[floorIndex]
        local slots = floor.vehicleSlots or floor.slotLayout or {}

        if slots[slotIndex] then
            return slots[slotIndex].coords or slots[slotIndex]
        end
    end

    local layout = template.slotLayout or {}

    for _, slot in ipairs(layout) do
        if slot.index == slotIndex and (slot.floor or 1) == floorIndex then
            return slot.coords
        end
    end

    local vehicleSlots = template.vehicleSlots or {}

    if vehicleSlots[slotIndex] then
        return vehicleSlots[slotIndex]
    end

    return nil
end

function Interiors.HasReadySlots(templateId)
    local template = Interiors.Get(templateId)

    if not template then
        return false
    end

    if template.floors then
        for _, floor in pairs(template.floors) do
            local slots = floor.vehicleSlots or floor.slotLayout or {}

            if #slots >= (template.vehiclesPerFloor or 0) then
                return true
            end
        end

        return false
    end

    local layout = template.slotLayout or template.vehicleSlots or {}

    return #layout >= (template.vehicleCapacity or 0)
        and not PropertyGarages.IsTodoCoords(layout[1])
end

function Interiors.GetRoutingBucket(templateId, instanceId)
    local template = Interiors.Get(templateId)
    local base = template and template.routingBucketBase or 7000
    instanceId = instanceId or 0

    return base + (instanceId % 500)
end
