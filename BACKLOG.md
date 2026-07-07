# BACKLOG.md - bus

Deferred work that is not part of the current active supervisor goal. Move an item back to PLAN.md only when the operator reactivates it.

## Deferred From PLAN.md - 2026-07-07 09:45:40 EEST

- [ ] Add dispatcher release metadata and child-resolution audit support end to end: expose stable text plus JSON version metadata with module name, version, commit, and build time for the `bus` dispatcher, and provide a non-secret way for Services freshness proof to record which `bus-*` executable a dispatcher invocation resolves for commands such as `bus api` and `bus integration`. Preserve dispatcher-first service profiles and first-word dispatch semantics; add unit/e2e coverage for metadata output and resolution evidence without turning `bus` into a build/install tool.
