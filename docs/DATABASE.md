# Database Design

Database logic is isolated to `server/database.lua`.

## Safety principles

- No automatic migrations.
- No production data modifications during startup.
- No assumptions about existing player vehicle table names.
- No destructive changes to framework vehicle tables.
- Manual SQL only.

## Manual SQL

Review `sql/install.sql` before running it. The file creates additive `w2f_garage_*` tables for future state, history, logs, impounds, transfers, insurance, mileage, and favourites.

It does not alter existing vehicle ownership tables.

## Existing vehicle tables

Different frameworks and servers use different table schemas. Configure these only after checking your database:

```lua
Config.Database.ExistingVehicleTable = nil
Config.Database.Columns = {
    owner = nil,
    plate = nil,
    vehicle = nil,
    garage = nil,
    state = nil
}
```

Until mappings are configured, vehicle-loading callbacks may return safe empty data.

## Planned wrapper functions

`server/database.lua` owns these functions:

- `GetPlayerVehicles`
- `GetVehiclesByGarage`
- `GetVehicleByPlate`
- `UpdateVehicleState`
- `UpdateVehicleGarage`
- `SaveVehicleProperties`
- `SaveFuel`
- `SaveDamage`
- `SaveLastLocation`
- `CreateGarageLog`
- `CreateImpoundRecord`
- `UpdateImpoundStatus`
- `SaveFavouriteVehicle`
- `SaveVehicleHistory`

Raw SQL should not appear in client files or normal server logic.
