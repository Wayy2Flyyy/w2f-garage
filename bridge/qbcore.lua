local adapter = {}
local QBCore

local function getCore()
    if QBCore then
        return QBCore
    end

    if GetResourceState and GetResourceState('qb-core') ~= 'started' then
        return nil
    end

    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok then
        QBCore = core
    end

    return QBCore
end

local function getPlayer(source)
    local core = getCore()

    if not core or not core.Functions then
        return nil
    end

    return core.Functions.GetPlayer(source)
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
    local player = getPlayer(source)
    local playerData = player and player.PlayerData

    return playerData and (playerData.citizenid or playerData.license)
end

function adapter.GetPlayerName(source)
    local player = getPlayer(source)
    local playerData = player and player.PlayerData

    if playerData and playerData.charinfo then
        local firstName = playerData.charinfo.firstname or ''
        local lastName = playerData.charinfo.lastname or ''
        local fullName = (firstName .. ' ' .. lastName):gsub('^%s*(.-)%s*$', '%1')

        if fullName ~= '' then
            return fullName
        end
    end

    return GetPlayerName(source)
end

function adapter.GetJob(source)
    local player = getPlayer(source)
    local job = player and player.PlayerData and player.PlayerData.job

    return {
        name = job and job.name or 'unemployed',
        label = job and job.label or 'Unemployed',
        grade = getGrade(job)
    }
end

function adapter.GetGang(source)
    local player = getPlayer(source)
    local gang = player and player.PlayerData and player.PlayerData.gang

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
    local core = getCore()

    if not core or not core.Functions or not core.Functions.HasPermission then
        return false
    end

    return core.Functions.HasPermission(source, permission)
end

function adapter.AddMoney(source, account, amount, reason)
    local player = getPlayer(source)

    if not player or not player.Functions or not player.Functions.AddMoney then
        return false
    end

    return player.Functions.AddMoney(account or 'cash', amount or 0, reason or 'w2f-garage')
end

function adapter.RemoveMoney(source, account, amount, reason)
    local player = getPlayer(source)

    if not player or not player.Functions or not player.Functions.RemoveMoney then
        return false
    end

    return player.Functions.RemoveMoney(account or 'cash', amount or 0, reason or 'w2f-garage')
end

function adapter.HasMoney(source, account, amount)
    local player = getPlayer(source)

    if not player or not player.Functions or not player.Functions.GetMoney then
        return false
    end

    return (player.Functions.GetMoney(account or 'cash') or 0) >= (amount or 0)
end

function adapter.Notify(source, message, notifyType, duration)
    local core = getCore()

    if not core or not core.Functions or not core.Functions.Notify then
        return false
    end

    core.Functions.Notify(source, message, notifyType or 'primary', duration or 5000)
    return true
end

function adapter.GetVehicleOwnerData()
    return nil
end

function adapter.GetPlayerSource(identifier)
    local core = getCore()

    if not core or not core.Functions or not core.Functions.GetQBPlayers then
        return nil
    end

    for source, player in pairs(core.Functions.GetQBPlayers()) do
        if player.PlayerData and (player.PlayerData.citizenid == identifier or player.PlayerData.license == identifier) then
            return source
        end
    end

    return nil
end

function adapter.IsPlayerOnline(identifier)
    return adapter.GetPlayerSource(identifier) ~= nil
end

Bridge.RegisterFramework('qbcore', adapter)
