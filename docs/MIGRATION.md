# Migration Guide

`w2f-garage` is intended to replace older garage systems, not run beside them as a second vehicle authority.

## Before migration

1. Back up your database.
2. Identify your current player vehicle table.
3. Identify current garage/state columns.
4. Review any impound/depot resources currently active.
5. Review fuel and key integrations.
6. Test on a staging server.

## Resources to stop

Stop old resources that control the same lifecycle:

- basic QB garage scripts
- basic QBX garage scripts
- default impound/depot resources
- duplicate job garage scripts
- any script that marks the same owned vehicles as out/stored

Only one resource should own storage/spawn state for the same vehicle set.

## Safe rollout checklist

- Confirm framework bridge selection.
- Confirm database table mappings.
- Import or create additive `w2f_garage_*` tables manually if needed.
- Test player ownership loading.
- Test garage access restrictions.
- Test spawn validation.
- Test store validation.
- Test impound/recovery behavior.
- Confirm duplicate spawn prevention.
- Monitor logs for invalid ownership or state warnings.

## Important rule

Do not overwrite existing player vehicle data without a tested migration plan. The foundation is designed to read existing data safely later and layer new state data on top where appropriate.
