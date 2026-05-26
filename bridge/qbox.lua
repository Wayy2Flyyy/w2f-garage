local adapter = {}

local function qboxStarted()
    return GetResourceState and GetResourceState('qbx_core') == 'started'
end

local function safeExport(method, ...)
    if not qboxStarted() then
        return nil
    end

    local args = { ... }
    local ok, result = pcall(function()
        return exports.qbx_core[method](exports.qbx_core, table.unpack(args))
    end)

    if ok then
        return result
    end

    ok, result = pcall(function()
        return exports.qbx_core[method](table.unpack(args))
    end)

    if ok then
        return result
    end

    return nil
end

local function getPlayer(source)
    return safeExport('GetPlayer', source)
end

local function getPlayerData(source)
    local player = getPlayer(source)

    if player and player.PlayerData then
        return player.PlayerData
    end

    return safeExport('GetPlayerData', source)
end

local function getGrade(data)
    if type(data) ~= 'table' then
        return 0
    end

    if type(data.grade) == 'table' then
        return data.grade.level or data.grade.grade or 0
    end

    return data.grade or 0
end

function adapter.GetPlayer(source)
    return getPlayer(source)
end

function adapter.GetIdentifier(source)
    local data = getPlayerData(source)

    return data and (data.citizenid or data.license or data.identifier)
end

function adapter.GetPlayerName(source)
    local data = getPlayerData(source)

    if data and data.charinfo then
        local firstName = data.charinfo.firstname or ''
        local lastName = data.charinfo.lastname or ''
        local fullName = (firstName .. ' ' .. lastName):gsub('^%s*(.-)%s*$', '%1')

        if fullName ~= '' then
            return fullName
        end
    end

    return GetPlayerName(source)
end

function adapter.GetJob(source)
    local data = getPlayerData(source)
    local job = data and data.job

    return {
        name = job and job.name or 'unemployed',
        label = job and job.label or 'Unemployed',
        grade = getGrade(job)
    }
end

function adapter.GetGang(source)
    local data = getPlayerData(source)
    local gang = data and data.gang

    return {
        name = gang and gang.name or 'none',
        label = gang and gang.label or 'None',
        grade = getGrade(gang)
    }
end

function adapter.GetJobGrade(source)
    return adapter.GetJob(source).grade
end

function adapter.GetGangGrade(source)
    return adapter.GetGang(source).grade
end

function adapter.HasPermission(source, permission)
    return safeExport('HasPermission', source, permission) == true
end

function adapter.AddMoney(source, account, amount, reason)
    local player = getPlayer(source)

    if player and player.Functions and player.Functions.AddMoney then
        return player.Functions.AddMoney(account or 'cash', amount or 0, reason or 'w2f-garage')
    end

    return safeExport('AddMoney', source, account or 'cash', amount or 0, reason or 'w2f-garage') == true
end

function adapter.RemoveMoney(source, account, amount, reason)
    local player = getPlayer(source)

    if player and player.Functions and player.Functions.RemoveMoney then
        return player.Functions.RemoveMoney(account or 'cash', amount or 0, reason or 'w2f-garage')
    end

    return safeExport('RemoveMoney', source, account or 'cash', amount or 0, reason or 'w2f-garage') == true
end

function adapter.HasMoney(source, account, amount)
    local player = getPlayer(source)

    if player and player.Functions and player.Functions.GetMoney then
        return (player.Functions.GetMoney(account or 'cash') or 0) >= (amount or 0)
    end

    local balance = safeExport('GetMoney', source, account or 'cash')
    return (balance or 0) >= (amount or 0)
end

function adapter.Notify(source, message, notifyType, duration)
    TriggerClientEvent('qbx_core:client:Notify', source, message, notifyType or 'primary', duration or 5000)
    return true
end

function adapter.GetVehicleOwnerData()
    return nil
end

function adapter.GetPlayerSource(identifier)
    local players = safeExport('GetQBPlayers') or safeExport('GetPlayersData') or {}

    for source, data in pairs(players) do
        local playerData = data.PlayerData or data

        if playerData and (playerData.citizenid == identifier or playerData.license == identifier or playerData.identifier == identifier) then
            return source
        end
    end

    return nil
end

function adapter.IsPlayerOnline(identifier)
    return adapter.GetPlayerSource(identifier) ~= nil
end

Bridge.RegisterFramework('qbox', adapter)
