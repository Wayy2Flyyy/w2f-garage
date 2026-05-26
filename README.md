# w2f-garage

`w2f-garage` is a framework-bridged FiveM vehicle garage and vehicle management resource. It is designed to become the central vehicle authority for storing, spawning, recovering, impounding, tracking, and managing player vehicles across QBCore, QBX/Qbox, and ESX servers.

This repository currently contains the foundation build. It is intentionally safe by default:

- no automatic database migrations
- no production vehicle data overwrites
- no destructive migration behavior
- no client-authoritative vehicle ownership/state decisions
- no framework-specific calls outside bridge files

## Foundation status

Implemented foundation targets:

- resource structure
- shared configuration
- garage configuration schema
- state/event/callback constants
- locale placeholders
- manual SQL install script
- installation, bridge, database, events, exports, and migration documentation

Planned next foundation targets:

- framework bridge implementations
- server callback and state-manager placeholders
- client zones, targets, and NUI open/close flow
- React/TypeScript/Vite NUI dashboard baseline
- validation and startup-safety checks

## Supported frameworks

Framework selection is controlled through `Config.Framework`:

- `auto`
- `qbcore`
- `qbox`
- `esx`

The main garage logic must call the normalized bridge API. Framework-specific APIs are isolated to framework bridge modules only.

## Recommended dependencies

- `ox_lib`
- `oxmysql`
- `ox_target` for garage interactions
- `ox_inventory` or framework inventory adapter
- configurable fuel resource
- configurable key resource

## Documentation

- [INSTALL.md](INSTALL.md)
- [Configuration Guide](docs/CONFIG_GUIDE.md)
- [Framework Bridge](docs/FRAMEWORK_BRIDGE.md)
- [Database](docs/DATABASE.md)
- [Events and Callbacks](docs/EVENTS.md)
- [Exports](docs/EXPORTS.md)
- [Migration](docs/MIGRATION.md)

## Safety warning

Do not run this alongside another garage resource that controls the same vehicle storage/spawn state in production. Running multiple authority systems can cause duplicates, broken vehicle states, and ownership issues. Read the migration guide before replacing an existing garage.