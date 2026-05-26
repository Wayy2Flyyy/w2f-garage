# Events and Callbacks

All event and callback names use the `w2f-garage:` prefix.

## Client events

- `w2f-garage:client:openGarage`
- `w2f-garage:client:closeGarage`
- `w2f-garage:client:spawnVehicle`
- `w2f-garage:client:storeVehicle`
- `w2f-garage:client:refreshGarage`

## Server events

- `w2f-garage:server:requestVehicles`
- `w2f-garage:server:storeVehicle`
- `w2f-garage:server:recoverVehicle`
- `w2f-garage:server:payImpound`

## Server callbacks

- `w2f-garage:server:getGarageData`
- `w2f-garage:server:getVehicles`
- `w2f-garage:server:getOwnedVehicles`
- `w2f-garage:server:spawnVehicle`
- `w2f-garage:server:storeVehicle`
- `w2f-garage:server:recoverVehicle`
- `w2f-garage:server:payImpound`
- `w2f-garage:server:adminSearchVehicle`

## Trust boundary

The client and NUI can request actions. The server validates:

- player identity
- vehicle ownership
- garage access
- job/gang restrictions
- payment availability
- vehicle state
- impound state
- duplicate-spawn risk
- admin permissions

The server response controls whether the action proceeds.
