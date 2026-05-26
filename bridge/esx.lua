local adapter = {}
local ESX

local function getSharedObject()
    if ESX then
        return ESX
    end

    if GetResourceState and GetResourceState('es_extended') ~= 'started' then
        return nil
    end

    local ok, object = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok then
        ESX = object
    end

    return ESX
end

local function getPlayer(source)
    local object = getSharedObject()

    if not object or not object.GetPlayerFromId then
        return nil
    end

    return object.GetPlayerFromId(source)
end

function adapter.GetPlayer(source)
    return getPlayer(source)
end

function adapter.GetIdentifier(source)
    local player = getPlayer(source)

    return player and player.identifier
end

function adapter.GetPlayerName(source)
    local player = getPlayer(source)

    if player and player.getName then
        return player.getName()
    end

    return GetPlayerName(source)
end

function adapter.GetJob(source)
    local player = getPlayer(source)
    local job = player and player.getJob and player.getJob()

    return {
        name = job and job.name or 'unemployed',
        label = job and job.label or 'Unemployed',
        grade = job and job.grade or 0
    }
end

function adapter.GetGang()
    return {
        name = 'none',
        label = 'None',
        grade = 0
    }
end

function adapter.GetJobGrade(source)
    return adapter.GetJob(source).grade
end

function adapter.GetGangGrade()
    return 0
end

function adapter.HasPermission(source, permission)
    local player = getPlayer(source)

    if not player then
        return false
    end

    if player.getGroup then
        local group = player.getGroup()
        return group == permission or group == 'admin' or group == 'superadmin'
    end

    return false
end

function adapter.AddMoney(source, account, amount)
    local player = getPlayer(source)

    if not player then
        return false
    end

    if account == 'bank' and player.addAccountMoney then
        player.addAccountMoney('bank', amount or 0)
        return true
    end

    if player.addMoney then
        player.addMoney(amount or 0)
        return true
    end

    return false
end

function adapter.RemoveMoney(source, account, amount)
    local player = getPlayer(source)

    if not player then
        return false
    end

    if account == 'bank' and player.removeAccountMoney then
        player.removeAccountMoney('bank', amount or 0)
        return true
    end

    if player.removeMoney then
        player.removeMoney(amount or 0)
        return true
    end

    return false
end

function adapter.HasMoney(source, account, amount)
    local player = getPlayer(source)

    if not player then
        return false
    end

    if account == 'bank' and player.getAccount then
        local bank = player.getAccount('bank')
        return (bank and bank.money or 0) >= (amount or 0)
    end

    if player.getMoney then
        return (player.getMoney() or 0) >= (amount or 0)
    end

    return false
end

function adapter.Notify(source, message, notifyType)
    TriggerClientEvent('esx:showNotification', source, message, notifyType or 'info')
    return true
end

function adapter.GetVehicleOwnerData()
    return nil
end

function adapter.GetPlayerSource(identifier)
    local object = getSharedObject()

    if not object or not object.GetExtendedPlayers then
        return nil
    end

    for _, player in pairs(object.GetExtendedPlayers()) do
        if player.identifier == identifier then
            return player.source
        end
    end

    return nil
end

function adapter.IsPlayerOnline(identifier)
    return adapter.GetPlayerSource(identifier) ~= nil
end

Bridge.RegisterFramework('esx', adapter)
