Notify = Notify or {}

local function detectNotify()
    if Config.Notify and Config.Notify ~= 'auto' then
        return Config.Notify
    end

    if GetResourceState and GetResourceState('ox_lib') == 'started' then
        return 'ox'
    end

    if Bridge and Bridge.ActiveFramework and Bridge.ActiveFramework ~= 'none' then
        return Bridge.ActiveFramework
    end

    return 'native'
end

local function normalizeNotification(message, notifyType, duration)
    return {
        title = Config.UI and Config.UI.Title or 'Garage',
        description = message,
        type = notifyType or 'inform',
        duration = duration or 5000
    }
end

function Notify.Send(source, message, notifyType, duration)
    local mode = detectNotify()

    if IsDuplicityVersion and IsDuplicityVersion() then
        if mode == 'ox' then
            TriggerClientEvent('ox_lib:notify', source, normalizeNotification(message, notifyType, duration))
            return true
        end

        if mode == 'qbcore' then
            TriggerClientEvent('QBCore:Notify', source, message, notifyType or 'primary', duration or 5000)
            return true
        end

        if mode == 'qbox' then
            TriggerClientEvent('qbx_core:client:Notify', source, message, notifyType or 'primary', duration or 5000)
            return true
        end

        if mode == 'esx' then
            TriggerClientEvent('esx:showNotification', source, message, notifyType or 'info')
            return true
        end

        if mode == 'custom' and Config.CustomNotifyServer then
            Config.CustomNotifyServer(source, message, notifyType, duration)
            return true
        end

        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Garage', message }
        })
        return true
    end

    return Notify.Client(message, notifyType, duration)
end

function Notify.Client(message, notifyType, duration)
    local mode = detectNotify()

    if mode == 'ox' and lib and lib.notify then
        lib.notify(normalizeNotification(message, notifyType, duration))
        return true
    end

    if mode == 'qbcore' then
        TriggerEvent('QBCore:Notify', message, notifyType or 'primary', duration or 5000)
        return true
    end

    if mode == 'qbox' then
        TriggerEvent('qbx_core:client:Notify', message, notifyType or 'primary', duration or 5000)
        return true
    end

    if mode == 'esx' then
        TriggerEvent('esx:showNotification', message, notifyType or 'info')
        return true
    end

    if mode == 'custom' and Config.CustomNotifyClient then
        Config.CustomNotifyClient(message, notifyType, duration)
        return true
    end

    print(('%s [notify] %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
    return true
end
