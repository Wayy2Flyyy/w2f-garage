# w2f-garage (Preview)

Production-oriented FiveM property garage framework for **QBCore**, **Qbox**, and **ESX**.

> Preview release: stable enough for testing and implementation, with ongoing improvements and documentation updates.

## 🎥 Video Preview

[![Watch the preview](asset/preview.mp4)

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

## TODO_CAPTURE

Property garages ship with exact **exterior entry** coords and tier **interior base** coords (shared shells). Store, spawn, per-garage interior offsets, and vehicle slot vec4s use `TODO_CAPTURE` until mapped. Players can enter the shared interior at the base while capture is in progress. See [docs/PROPERTY_GARAGES.md](docs/PROPERTY_GARAGES.md).
