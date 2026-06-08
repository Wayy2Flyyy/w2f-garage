# w2f-garage Installation

This foundation build is safe by default and does not run database migrations automatically.

## Required resources

Start these before `w2f-garage`:

```cfg
ensure ox_lib
ensure oxmysql
```

Recommended optional resources:

```cfg
ensure ox_target
ensure ox_inventory
```

Start your selected framework before `w2f-garage`:

```cfg
# QBCore
ensure qb-core

# or Qbox
ensure qbx_core

# or ESX
ensure es_extended
```

Then start the garage:

```cfg
ensure w2f-garage
```

## Framework selection

Edit `shared/config.lua`:

```lua
Config.Framework = 'auto'
```

Supported values:

- `auto`
- `qbcore`
- `qbox`
- `esx`

Use manual mode if auto-detection is ambiguous.

## Database setup

The SQL file in `sql/install.sql` is manual only.

Before running any SQL:

1. Back up your database.
2. Confirm your existing player vehicle table and column names.
3. Review every statement in `sql/install.sql`.
4. Run it manually only when ready.

This resource will not execute migrations from the manifest or startup scripts.

## Existing garage migration

Do not run multiple garage authority resources at the same time. Stop legacy garage resources in a staging environment first, test ownership/spawn/store behavior, then migrate production.

Read `docs/MIGRATION.md` before going live.

## NUI build

The React/Vite NUI baseline is built in a later foundation stage. Once available:

```bash
cd web
npm install
npm run build
```

The FiveM manifest should point at the built `web/dist/index.html` output once the NUI has been generated.
