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

-- Bridge, server, client, and NUI entries are added as their foundation stages are implemented.
-- SQL migrations are intentionally not run from the manifest.
