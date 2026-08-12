# Migration Notes

Use this folder to track consolidation and migration steps from the legacy infrastructure layout into the active repo structure.

Current migration posture to preserve in docs:

- The infra repository has moved from proof-of-concept GHCR validation to a validated app-consumed SSM deploy helper contract.
- The consolidated app repo now owns bootstrap and steady-state release wrappers around those generic helpers.
- The remaining migration gap is incremental production schema migration. The current schema init path in the app repo is bootstrap or DR only and must not be documented as steady-state migration.
- Any future Alembic or equivalent runner should be documented here and linked from the app/infra contract doc.
