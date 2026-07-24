# Memory Index

- [dynamic_of_things architecture](dynamic-of-things-architecture.md) — how it ties to visitqu, dmsretail backend, and its postgres DB
- [Mirror memory to working dir](mirror-memory-to-working-dir.md) — user wants memory files copied into the dynamic_of_things repo root (hook installed)
- [BEO detail form pseudo_code architecture](beo-detail-form-pseudo-code-architecture.md) — Field.readOnly is per-column not per-row; consolidated-script pattern + DSL gotchas
- [Offline trigger Postgres formula gap](offline-trigger-postgres-formula-gap.md) — trigger column_value formulas using TO_CHAR/fn_get_id/^ fall back to NULL offline instead of being translated (cross-device doc-number uniqueness)
