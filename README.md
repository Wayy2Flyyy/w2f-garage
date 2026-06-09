# w2f-garage (Preview)

Production-oriented FiveM property garage framework for **QBCore**, **Qbox**, and **ESX**.

> Preview release: stable enough for testing and implementation, with ongoing improvements and documentation updates.

## Preview

<img width="1486" height="842" alt="image" src="https://github.com/user-attachments/assets/7accf62f-a3ac-4fb7-9bdb-f74f0af7da9d" />
<img width="1484" height="843" alt="image" src="https://github.com/user-attachments/assets/f18a2123-63d5-4138-9844-4c2601014a98" />
<img width="1489" height="836" alt="image" src="https://github.com/user-attachments/assets/47ac0604-a472-4cc8-8dc2-1d8eb3466937" />


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

*Stay2Flyyy*
