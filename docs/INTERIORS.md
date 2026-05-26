# Interiors

Interior behaviour is abstracted in `shared/interiors.lua`.

## Supported modes

- Native IPL (set `ipl` on template)
- Shell / MLO (`shellModel`, `type = 'shell'`)
- Custom mapped interiors (`type = 'custom'`)

## Slot positions

Add exact `vec4` entries to:

- `Interiors.Templates.<template>.slotLayout`
- Per-floor: `floors[n].vehicleSlots` (Eclipse)

Until coords exist, interior display vehicles are skipped (`coordsReady = false`).

## Routing buckets

Each session uses `Interiors.GetRoutingBucket(templateId, instanceId)` for isolated interior instances when `Config.Property.UseRoutingBuckets` is enabled.
