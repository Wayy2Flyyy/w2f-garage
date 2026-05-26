# Framework Bridge

The framework bridge is the boundary between main garage logic and QBCore, QBX/Qbox, or ESX APIs.

## Rule

Main garage files must call:

```lua
Bridge.GetPlayer(source)
Bridge.GetIdentifier(source)
Bridge.GetJob(source)
```

Main garage files must not call:

```lua
QBCore.Functions.GetPlayer(source)
exports.qbx_core:GetPlayer(source)
ESX.GetPlayerFromId(source)
```

Framework-specific calls belong only in:

- `bridge/qbcore.lua`
- `bridge/qbox.lua`
- `bridge/esx.lua`

## Startup order

The bridge avoids registration races:

1. `bridge/main.lua` creates `_G.W2FGarageBridge` and `Bridge`.
2. `bridge/main.lua` exposes `Bridge.RegisterFramework(name, adapter)`.
3. `bridge/qbcore.lua`, `bridge/qbox.lua`, and `bridge/esx.lua` register adapters.
4. `server/main.lua` calls `Bridge.Initialize()` after all adapters are loaded.

`bridge/main.lua` must not select the active adapter during top-level file load.

## Standard bridge contract

Adapters should provide:

- `GetPlayer(source)`
- `GetIdentifier(source)`
- `GetPlayerName(source)`
- `GetJob(source)`
- `GetGang(source)`
- `GetJobGrade(source)`
- `GetGangGrade(source)`
- `HasPermission(source, permission)`
- `AddMoney(source, account, amount, reason)`
- `RemoveMoney(source, account, amount, reason)`
- `HasMoney(source, account, amount)`
- `Notify(source, message, type, duration)`
- `GetVehicleOwnerData(plate)`
- `GetPlayerSource(identifier)`
- `IsPlayerOnline(identifier)`

Missing framework data should return safe `nil` or `false` values rather than crashing.

## Manual vs auto framework mode

`Config.Framework = 'auto'` detects running resources. Manual modes force one adapter:

- `qbcore`
- `qbox`
- `esx`

If manual mode is selected but the adapter cannot be registered, the bridge should enter safe fallback mode and print a clear warning.
