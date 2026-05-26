# w2f-garage

Production-oriented FiveM property garage framework for **QBCore**, **Qbox**, and **ESX**.

## Features

- Framework bridge (no direct `QBCore` / `ESX` calls in garage logic)
- Dynasty 8 property garages (low / medium / high-end + future Eclipse 50-car)
- Server-authoritative purchase, store, spawn, slots, and state
- Interior abstraction with physical display vehicles when coords are configured
- Slot manager (assign, swap, move floor, move garage, anti-duplicate plates)
- ox_lib, ox_target, oxmysql, configurable fuel/keys/notify/inventory bridges
- Premium dark NUI (public garages + property dashboard)
- Admin recovery commands
- Additive SQL only (manual install)

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_target](https://github.com/overextended/ox_target) (recommended)

## Quick start

1. Import `sql/install.sql` manually (after backup).
2. Configure `shared/config.lua` (framework, database table mapping, property options).
3. Add `ensure w2f-garage` after ox_lib, oxmysql, and your framework.
4. Build UI: `cd web && npm install && npm run build`.

## Documentation

- [INSTALL.md](INSTALL.md)
- [docs/CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md)
- [docs/PROPERTY_GARAGES.md](docs/PROPERTY_GARAGES.md)
- [docs/INTERIORS.md](docs/INTERIORS.md)
- [docs/FRAMEWORK_BRIDGE.md](docs/FRAMEWORK_BRIDGE.md)
- [docs/DATABASE.md](docs/DATABASE.md)
- [docs/EVENTS.md](docs/EVENTS.md)
- [docs/EXPORTS.md](docs/EXPORTS.md)
- [docs/MIGRATION.md](docs/MIGRATION.md)

## TODO_COORDS

Most property garages ship with exact **entry** coords only. Store, spawn, interior entry/exit, and slot positions use `TODO_COORDS` until mapped. The resource starts safely; full drive-in interiors require completing coordinates per [docs/PROPERTY_GARAGES.md](docs/PROPERTY_GARAGES.md).
