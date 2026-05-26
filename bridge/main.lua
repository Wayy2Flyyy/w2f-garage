_G.W2FGarageBridge = _G.W2FGarageBridge or {}

Bridge = _G.W2FGarageBridge
Bridge.Frameworks = Bridge.Frameworks or {}
Bridge.ActiveFramework = Bridge.ActiveFramework or 'none'
Bridge.ActiveAdapter = Bridge.ActiveAdapter or nil
Bridge.Initialized = Bridge.Initialized or false

local function debugPrint(message)
    if Config and Config.Debug then
        print(('%s [bridge] %s'):format(Config.DebugPrefix or '[w2f-garage]', message))
    end
end

local function resourceStarted(resourceName)
    return GetResourceState and GetResourceState(resourceName) == 'started'
end

local function safeAdapterCall(method, fallback, ...)
    if not Bridge.Initialized then
        Bridge.Initialize()
    end

    local adapter = Bridge.ActiveAdapter

    if adapter and type(adapter[method]) == 'function' then
        return adapter[method](...)
    end

    return fallback
end

function Bridge.RegisterFramework(name, adapter)
    if type(name) ~= 'string' or type(adapter) ~= 'table' then
        debugPrint('Ignored invalid framework registration.')
        return false
    end

    Bridge.Frameworks[name] = adapter
    debugPrint(('Registered framework adapter: %s'):format(name))
    return true
end

function Bridge.DetectFramework()
    local requested = Config and Config.Framework or 'auto'

    if requested ~= 'auto' then
        return requested
    end

    if resourceStarted('qbx_core') then
        return 'qbox'
    end

    if resourceStarted('qb-core') then
        return 'qbcore'
    end

    if resourceStarted('es_extended') then
        return 'esx'
    end

    return 'none'
end

Bridge.Init = function()
    return Bridge.Initialize()
end

function Bridge.Initialize()
    if Bridge.Initialized then
        return Bridge.ActiveFramework, Bridge.ActiveAdapter
    end

    local selected = Bridge.DetectFramework()
    local adapter = Bridge.Frameworks[selected]

    if not adapter then
        if selected ~= 'none' then
            print(('%s [bridge] Framework "%s" was selected but no adapter was registered. Safe fallback mode active.'):format(Config.DebugPrefix or '[w2f-garage]', selected))
        else
            debugPrint('No supported framework detected. Safe fallback mode active.')
        end

        selected = 'none'
        adapter = nil
    end

    Bridge.ActiveFramework = selected
    Bridge.ActiveAdapter = adapter
    Bridge.Initialized = true

    debugPrint(('Bridge initialized with framework: %s'):format(Bridge.ActiveFramework))
    return Bridge.ActiveFramework, Bridge.ActiveAdapter
end

function Bridge.Reset()
    Bridge.ActiveFramework = 'none'
    Bridge.ActiveAdapter = nil
    Bridge.Initialized = false
end

function Bridge.GetPlayer(source)
    return safeAdapterCall('GetPlayer', nil, source)
end

function Bridge.GetIdentifier(source)
    return safeAdapterCall('GetIdentifier', nil, source)
end

function Bridge.GetPlayerName(source)
    return safeAdapterCall('GetPlayerName', GetPlayerName(source), source)
end

function Bridge.GetJob(source)
    return safeAdapterCall('GetJob', { name = 'unemployed', label = 'Unemployed', grade = 0 }, source)
end

function Bridge.GetGang(source)
    return safeAdapterCall('GetGang', { name = 'none', label = 'None', grade = 0 }, source)
end

function Bridge.GetJobGrade(source)
    return safeAdapterCall('GetJobGrade', 0, source)
end

function Bridge.GetGangGrade(source)
    return safeAdapterCall('GetGangGrade', 0, source)
end

function Bridge.HasPermission(source, permission)
    return safeAdapterCall('HasPermission', false, source, permission)
end

function Bridge.AddMoney(source, account, amount, reason)
    return safeAdapterCall('AddMoney', false, source, account, amount, reason)
end

function Bridge.RemoveMoney(source, account, amount, reason)
    return safeAdapterCall('RemoveMoney', false, source, account, amount, reason)
end

function Bridge.HasMoney(source, account, amount)
    return safeAdapterCall('HasMoney', false, source, account, amount)
end

function Bridge.Notify(source, message, notifyType, duration)
    if Notify and Notify.Send then
        return Notify.Send(source, message, notifyType, duration)
    end

    return safeAdapterCall('Notify', false, source, message, notifyType, duration)
end

function Bridge.RegisterCallback(name, handler)
    if lib and lib.callback and lib.callback.register then
        lib.callback.register(name, handler)
        return true
    end

    debugPrint(('Unable to register callback "%s"; ox_lib callback API is unavailable.'):format(name))
    return false
end

function Bridge.TriggerClientCallback(name, source, ...)
    if lib and lib.callback and lib.callback.await then
        return lib.callback.await(name, source, ...)
    end

    debugPrint(('Unable to trigger client callback "%s"; ox_lib callback API is unavailable.'):format(name))
    return nil
end

function Bridge.GetVehicleOwnerData(plate)
    return safeAdapterCall('GetVehicleOwnerData', nil, plate)
end

function Bridge.GetPlayerSource(identifier)
    return safeAdapterCall('GetPlayerSource', nil, identifier)
end

function Bridge.IsPlayerOnline(identifier)
    return safeAdapterCall('IsPlayerOnline', false, identifier)
end
