# Exports

Exports are planned for future integrations. The foundation documents the target API but does not claim all production behavior is complete.

## Planned exports

- `OpenGarage`
- `GetVehicleState`
- `SetVehicleState`
- `IsVehicleOut`
- `ImpoundVehicle`
- `ReleaseVehicle`
- `GetGarageVehicles`
- `GetPlayerVehicles`
- `RegisterGarage`
- `RefreshGarage`

## Integration targets

These exports are intended to support:

- dealership scripts
- police impound systems
- mechanic scripts
- housing/property garages
- key systems
- insurance systems
- business fleet systems

## Security expectation

Any export that mutates vehicle state must validate permissions and ownership server-side. External resources should not directly change database state without going through the garage authority layer.
