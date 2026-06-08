ServerUtils = ServerUtils or {}

function ServerUtils.Debug(message, data)
    if not Config.Debug then
        return
    end

    if data ~= nil and json and json.encode then
        print(('%s [server] %s %s'):format(Config.DebugPrefix or '[w2f-garage]', message, json.encode(data)))
        return
    end

    print(('%s [server] %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
end

function ServerUtils.Trim(value)
    if type(value) ~= 'string' then
        return value
    end

    return value:gsub('^%s*(.-)%s*$', '%1')
end

function ServerUtils.NormalizePlate(plate)
    if type(plate) ~= 'string' then
        return nil
    end

    local normalized = ServerUtils.Trim(plate):upper()

    if normalized == '' or #normalized > 16 then
        return nil
    end

    return normalized
end

function ServerUtils.ToNumber(value, fallback)
    local number = tonumber(value)

    if number == nil then
        return fallback
    end

    return number
end

function ServerUtils.GetGarage(garageId)
    if type(garageId) ~= 'string' then
        return nil
    end

    if BasicPublicGarages and BasicPublicGarages.Get(garageId) then
        return BasicPublicGarages.Enrich(garageId)
    end

    if PropertyGarages and PropertyGarages.Get(garageId) then
        return PropertyGarages.Enrich(garageId)
    end

    return Garages and Garages.Get and Garages.Get(garageId) or nil
end

function ServerUtils.TableCount(sourceTable)
    local count = 0

    for _ in pairs(sourceTable or {}) do
        count = count + 1
    end

    return count
end

function ServerUtils.VectorToTable(value)
    if type(value) == 'vector3' then
        return { x = value.x, y = value.y, z = value.z }
    end

    if type(value) == 'vector4' then
        return { x = value.x, y = value.y, z = value.z, w = value.w }
    end

    if type(value) == 'table' then
        local output = {}

        for key, nested in pairs(value) do
            output[key] = ServerUtils.VectorToTable(nested)
        end

        return output
    end

    return value
end

function ServerUtils.SanitizeGarage(garage)
    if not garage then
        return nil
    end

    local sanitized = ServerUtils.VectorToTable(garage)
    sanitized.serverOnly = nil

    return sanitized
end

function ServerUtils.Success(data, message)
    return {
        success = true,
        message = message,
        data = data
    }
end

function ServerUtils.Failure(code, message, data)
    return {
        success = false,
        code = code or 'failed',
        message = message or Locale.not_implemented,
        data = data
    }
end
