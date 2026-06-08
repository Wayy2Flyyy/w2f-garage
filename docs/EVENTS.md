# Events & Callbacks

Prefix: `w2f-garage:`

## Client events

| Event | Description |
|-------|-------------|
| `w2f-garage:client:openGarage` | Open public garage NUI |
| `w2f-garage:client:closeGarage` | Close NUI |
| `w2f-garage:client:enterGarage` | Reserved |
| `w2f-garage:client:exitGarage` | Reserved |
| `w2f-garage:client:spawnVehicle` | Spawn approved vehicle (server payload) |
| `w2f-garage:client:storeVehicle` | Store cleanup client hook |
| `w2f-garage:client:propertyEnter` | Enter property interior session |
| `w2f-garage:client:propertyExit` | Exit property interior session |
| `w2f-garage:client:interiorLoadVehicles` | Spawn display vehicles in interior |
| `w2f-garage:client:interiorUnloadVehicles` | Remove display vehicles |
| `w2f-garage:client:openPropertyGarage` | Open property dashboard |

## Server callbacks (ox_lib)

| Callback | Purpose |
|----------|---------|
| `w2f-garage:server:getGarageData` | Public garage metadata |
| `w2f-garage:server:getVehicles` | Vehicles in public garage |
| `w2f-garage:server:spawnVehicle` | Spawn (public or property) |
| `w2f-garage:server:storeVehicle` | Store (public or property) |
| `w2f-garage:server:getPropertyDashboard` | Owned + purchasable property list |
| `w2f-garage:server:buyGarage` | Purchase property garage |
| `w2f-garage:server:sellGarage` | Sell owned garage |
| `w2f-garage:server:enterGarage` | Enter interior (property) |
| `w2f-garage:server:exitGarage` | Exit interior |
| `w2f-garage:server:getGarageVehicles` | Stored vehicles + slot info |
| `w2f-garage:server:moveVehicleSlot` | Reassign slot index |
| `w2f-garage:server:propertySpawnVehicle` | Drive out from property interior |
| `w2f-garage:server:propertyStoreVehicle` | Store at property exterior |
