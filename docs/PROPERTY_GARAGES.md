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
- **Pending:** marked `TODO_COORDS` or `TODO_COORDS_VEC4` until exact positions are supplied

A garage is **production-ready** only when `PropertyGarages.IsProductionReady(garageId)` returns true (all required coords + slot layout filled).

## Lifecycle (server-authoritative)

1. Buy garage → `w2f-garage:server:buyGarage`
2. Enter → routing bucket + interior load + display vehicles
3. Spawn vehicle out → state `out`, exterior spawn
4. Store at exterior → slot assign, state `stored`, delete world entity

## Public mode

Set `Config.Property.PublicMode = true` to allow storing in garages without ownership (still validates vehicle ownership).
