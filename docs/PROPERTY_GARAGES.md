# Property Garages

`w2f-garage` property garages are defined in `shared/propertyGarages.lua`.

## Tiers

| Class | Vehicles | Bicycles | Template |
|-------|----------|----------|----------|
| low-end | 2 | 1 | `low_2_car_garage` |
| medium | 6 | 2 | `medium_6_car_garage` |
| high-end | 10 | 3 | `highend_10_car_garage` |
| high-end-custom | 50 (5×10 floors) | 0 | `eclipse_50_car_garage` |

## Coordinate policy

- **Confirmed:** `exteriorEntryCoords` (blip / interaction)
- **Template interior:** `interiorBaseCoords` per tier (shared GTA Online garage shell)
- **Pending capture:** `TODO_CAPTURE` / `TODO_CAPTURE_VEC4` for store, spawn, entry/exit offsets, and slot vec4s

| Tier | `interiorBaseCoords` |
|------|----------------------|
| low-end | `vec3(173.2903, -1003.6000, -99.6571)` |
| medium | `vec3(197.8153, -1002.2930, -99.6575)` |
| high-end | `vec3(229.9559, -981.7928, -99.6607)` |

`PropertyGarages.CanEnterInterior(garageId)` is true when `interiorBaseCoords` or captured `interiorEntryCoords` exist.

**Production-ready** (`PropertyGarages.IsProductionReady`) requires all capture fields and full slot layout — not just the shared base.

## Lifecycle (server-authoritative)

1. Buy garage → `w2f-garage:server:buyGarage`
2. Enter → routing bucket + interior load + display vehicles
3. Spawn vehicle out → state `out`, exterior spawn
4. Store at exterior → slot assign, state `stored`, delete world entity

## Public mode

Set `Config.Property.PublicMode = true` to allow storing in garages without ownership (still validates vehicle ownership).
