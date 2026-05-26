# Configuration Guide

All primary configuration lives in `shared/config.lua` and `shared/garages.lua`.

## Framework

```lua
Config.Framework = 'auto'
```

Supported values:

- `auto`
- `qbcore`
- `qbox`
- `esx`

Main garage logic must not call framework APIs directly. Use bridge functions instead.

## Adapters

```lua
Config.Inventory = 'auto'
Config.Fuel = 'auto'
Config.Keys = 'auto'
Config.Notify = 'ox'
```

Adapters are intentionally configurable so server owners can use their preferred inventory, fuel, key, and notification resources.

## Database safety

```lua
Config.Database = {
    Enabled = false,
    AutoMigrate = false,
    SafeMode = true
}
```

`AutoMigrate` must remain false unless a future stage explicitly implements and documents controlled migrations. The current foundation never runs SQL automatically.

Existing player vehicle table mappings are intentionally blank until the server owner confirms table and column names.

## Garage schema

Each garage in `shared/garages.lua` supports:

- `id`
- `label`
- `type`
- `enabled`
- `coords`
- `radius`
- `ped`
- `blip`
- `spawnPoints`
- `storeZones`
- `restrictions`
- `impoundFee`
- `camera`
- `ui`

Garage types are defined in `shared/constants.lua`:

- `public`
- `job`
- `gang`
- `depot`
- `private`
- `business`
- `emergency`
- `hidden`

## Restrictions

```lua
restrictions = {
    jobs = { police = true },
    gangs = {},
    minimumJobGrade = 0,
    minimumGangGrade = 0,
    vehicleClasses = {}
}
```

Access is validated server-side. Client-side zones and targets are visual interaction helpers only.

## Debugging

```lua
Config.Debug = false
```

When enabled, the resource prints structured startup and safety information. Debug mode should not be required for production operation.
