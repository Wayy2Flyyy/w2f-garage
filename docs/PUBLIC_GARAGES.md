# Public Garages

City garages with **no ownership**, **unlimited storage**, and **$700/day per vehicle** (configurable).

Separate from purchasable property garages in `shared/propertyGarages.lua`.

## Config

- `Config.PublicGarages` — billing, payment, shared storage behaviour
- `Config.BasicPublicGarages` — locations, coords, spawn points (edit freely)

## Billing

- Server calculates fees from `stored_at` unix timestamp
- `chargeOnlyFullDays = true` → under 24h = $0, 25h = $700, 49h = $1,400
- Fees apply only while state is `stored_public`
- Spawn blocked until paid when `requirePaymentBeforeSpawn = true`

## Shared storage

When `sharedPublicStorage = true`, vehicles stored at any public garage appear at all public garage UIs. Spawn still uses the interacting garage's spawn point.

## States

| State | Meaning |
|-------|---------|
| `stored_public` | In public storage, fees accrue |
| `out` | Driven out, no fees |

## Admin

- `/cleargaragefee [plate]`
- `/setgaragefee [plate] [amount]`
- `/checkgaragefee [plate]`

## Database

Table: `w2f_public_garage_vehicles` (see `sql/install.sql`)
