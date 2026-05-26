fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'w2f-garage'
author 'W2F'
version '0.1.0-foundation'
description 'Framework-bridged vehicle garage and management foundation for QBCore, Qbox, and ESX.'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/constants.lua',
    'shared/locales.lua',
    'shared/config.lua',
    'shared/garages.lua',
    'shared/vehicles.lua'
}

server_scripts {
    'bridge/main.lua',
    'bridge/qbcore.lua',
    'bridge/qbox.lua',
    'bridge/esx.lua',
    'bridge/inventory.lua',
    'bridge/fuel.lua',
    'bridge/keys.lua',
    'bridge/notify.lua',
    'server/utils.lua',
    'server/logs.lua',
    'server/database.lua',
    'server/security.lua',
    'server/vehicleState.lua',
    'server/callbacks.lua',
    'server/admin.lua',
    'server/main.lua'
}

client_scripts {
    'bridge/main.lua',
    'bridge/fuel.lua',
    'bridge/keys.lua',
    'bridge/notify.lua',
    'client/utils.lua',
    'client/camera.lua',
    'client/spawn.lua',
    'client/store.lua',
    'client/nui.lua',
    'client/zones.lua',
    'client/targets.lua',
    'client/main.lua'
}

-- NUI runtime entries are added once the React/Vite baseline is built.
-- SQL migrations are intentionally not run from the manifest.
