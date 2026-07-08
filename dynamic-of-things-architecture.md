---
name: dynamic-of-things-architecture
description: "How dynamic_of_things relates to visitqu, dmsretail backend, and its postgres DB"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8adf3d1a-e5f4-4984-902a-829bcd83527d
---

`dynamic_of_things` is a Flutter package (server-driven dynamic forms/charts/reports/schedules engine) used as a git dependency by the `visitqu` app (an SFA/CRM). visitqu pubspec pins it by git ref to https://github.com/sisappmobile/dynamic_of_things.git. The host app calls `DotApis.getInstance().init(salt, baseUrl, sessionIdKey, interceptor)` and spreads `dotRoutes` into go_router.

- **Backend**: Java JAX-RS in `dmsretail`, package `com.sisapp.salesforce.api.rest.endpoint.v2` (DynamicFormService / DynamicReportService / DynamicChartService / DynamicScheduleService / SynchronizationService). All endpoints `@Authority2Filtered`. Data access via `com.crux.util.ListUtil` + `SQLAssembler` (not JPA).
- **DB**: postgres at 172.16.2.109:7654/pos_dms_retail_dynamic_form (user/pass postgres). It's the full DMS Retail DB (~1622 tables). Form-builder config lives in the `c_custom_form*` family — `c_custom_form` (forms), `c_field_custom_form` (fields), `c_custom_form_category`, `c_custom_report*`, `t_dynamic_chart*`. Dynamic table metadata in `f_dynamic_table` / `f_dynamic_table_detail`. No psql on this machine; use python3 `psycopg2`.
- **Auth**: header `sfa-security-code = sha256(salt + sfa-session-id + sfa-timestamp)`.
- **Offline**: SQLite mirror; `Pulls` (snapshot/pull, every 30s) + `Pushes` (push `_sync_queues`, every 5s); version tracked in pref `dot-sync-current-version`; `pg_to_sqlite_converter` translates SQL dialect; `json_script_engine.dart` evaluates pseudo_code form logic.
