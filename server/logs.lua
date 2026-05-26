Logs = Logs or {}

local function prefix(level)
    return ('%s [%s]'):format(Config.DebugPrefix or '[w2f-garage]', level)
end

function Logs.Info(message, data)
    if Config.Logging and Config.Logging.Console == false then
        return
    end

    if data and json and json.encode then
        print(('%s %s %s'):format(prefix('info'), message, json.encode(data)))
        return
    end

    print(('%s %s'):format(prefix('info'), message))
end

function Logs.Warn(message, data)
    if data and json and json.encode then
        print(('%s %s %s'):format(prefix('warn'), message, json.encode(data)))
        return
    end

    print(('%s %s'):format(prefix('warn'), message))
end

function Logs.Debug(message, data)
    if not Config.Debug then
        return
    end

    Logs.Info(message, data)
end

function Logs.Security(source, action, details)
    local entry = {
        action = action or W2F_GARAGE.LogActions.SECURITY_WARNING,
        source = source,
        playerName = source and Bridge.GetPlayerName(source) or nil,
        identifier = source and Bridge.GetIdentifier(source) or nil,
        details = details or {}
    }

    Logs.Warn('Security event', entry)

    if Database and Database.CreateGarageLog then
        Database.CreateGarageLog({
            action = entry.action,
            source = source,
            playerName = entry.playerName,
            identifier = entry.identifier,
            details = entry.details
        })
    end
end

function Logs.GarageAction(action, source, plate, garageId, details)
    local entry = {
        action = action,
        source = source,
        playerName = source and Bridge.GetPlayerName(source) or nil,
        identifier = source and Bridge.GetIdentifier(source) or nil,
        plate = plate,
        garageId = garageId,
        details = details or {}
    }

    Logs.Info('Garage action', entry)

    if Database and Database.CreateGarageLog then
        Database.CreateGarageLog(entry)
    end
end

function Logs.Discord()
    if not Config.Logging or not Config.Logging.Discord or not Config.Logging.Discord.Enabled then
        return false
    end

    Logs.Debug('Discord logging placeholder reached; webhook transport is reserved for a later stage.')
    return false
end
