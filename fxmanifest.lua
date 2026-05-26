fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'w2f-garage'
author 'W2F'
version '1.0.0'
description 'Production property garage framework with framework bridge for QBCore, Qbox, and ESX.'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/constants.lua',
    'shared/locales.lua',
    'shared/config.lua',
    'shared/interiors.lua',
    'shared/propertyGarages.lua',
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
    'server/slotManager.lua',
    'server/interiors.lua',
    'server/property.lua',
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
    'client/interiors.lua',
    'client/property.lua',
    'client/nui.lua',
    'client/zones.lua',
    'client/targets.lua',
    'client/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

-- SQL migrations are intentionally not run from the manifest.
