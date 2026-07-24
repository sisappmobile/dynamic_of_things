---
name: offline-trigger-postgres-formula-gap
description: "f_dynamic_table_trigger_action_detail column_key/column_value templates can contain raw Postgres-only SQL (TO_CHAR/fn_get_id/^) that has no SQLite equivalent and no safe offline reimplementation - handled by falling back to NULL, not by translating"
metadata:
  node_type: memory
  type: project
  originSessionId: 8adf3d1a-e5f4-4984-902a-829bcd83527d
  modified: 2026-07-24T09:30:19.836Z
---

`Offlines.buildKey`/`Offlines.buildValue` (lib/helper/offlines.dart) resolve `f_dynamic_table_trigger_action_detail.column_key`/`column_value` templates by substituting `$key.$value`-style placeholders (`new.field`, `old.field`, `<variableName>.field` via `extractAllTableColumn`'s bare `identifier.identifier` regex — no `$` prefix required, unlike the pseudo_code/field-script `$header.`/`$detail.` convention) and embedding the result directly as SQL text into a trigger-generated INSERT/UPDATE. Some of these templates are hand-written Postgres formulas for auto-generating document numbers, e.g. (real example, `m_sales_visit_note`'s insert trigger):

```
'SVN' || b.bu_code || (cast(TO_CHAR(now(), 'yyMM') as numeric) * cast(10 ^ (9 - length(b.bu_code)) as numeric)) + fn_get_id('id2_svnsc'||new.bu_id||TO_CHAR(now()::timestamp without time zone, 'yy_MM'))
```

This crashed offline with `SQLiteException: unrecognized token: "^"` (`^` isn't a SQLite operator at all) — but `^` was only the visible symptom; `TO_CHAR(...)` and `fn_get_id(...)` are equally unsupported.

**Why NOT translated to a SQLite equivalent (unlike e.g. `PgToSqliteConverter`'s segment-report query translation):** `fn_get_id(sequenceName)` is a Postgres PL/pgSQL function (`pg_get_functiondef` confirms this) that does `NEXTVAL(sequence) * 1000 + s_parameter.value_string WHERE param_id='PRESS_MACHINE_ID'` — i.e. it guarantees document-number uniqueness **across concurrent server instances** via a fixed per-server salt. That guarantee is meaningless offline: many independent mobile devices generate documents concurrently, and reimplementing this with a local `_sequences` counter (even salted by salesunit_id) would only reduce, not eliminate, cross-device collision risk for a value the business likely treats as a unique document number.

**Resolution (confirmed with the user 2026-07-24, deliberately scoped to ALL such formulas, not just this one table):** rather than attempting any translation, `Offlines.buildKey`/`buildValue` now detect known-unsupported Postgres constructs (`_isUnsupportedPostgresFormula`: contains `to_char(`, `fn_get_id(`, or a literal `^`, checked case-insensitively after placeholder substitution) and return the SQL literal `NULL` in their place — same return convention already used elsewhere in these two methods for a genuinely-null value. The destination column is left NULL in the offline row; the server is expected to compute the real value (running its own trigger with the genuine Postgres formula) when the row syncs up. Verified this pattern exists in exactly 7 rows across the whole `f_dynamic_table_trigger_action_detail` table (checked via direct Postgres query), all using this same `TO_CHAR`/`fn_get_id`/`^` combination for different document-number schemes (SVN/JRN/C prefixes) - the detection is intentionally generic across all of them, not hardcoded to one table.

**How to apply:** if a *different* unsupported Postgres construct turns up in a future column_key/column_value template (not just these three), add it to `_isUnsupportedPostgresFormula`'s check rather than trying to hand-translate it — translating auto-numbering formulas offline is the wrong instinct here specifically because of the cross-device uniqueness problem, even though it's usually the right instinct for read-only report queries (see `PgToSqliteConverter`).
