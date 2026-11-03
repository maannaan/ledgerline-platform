# Safe schema migrations (expand / contract)

## Rules

1. **Expand:** add nullable columns/tables/indexes first (online).
2. Deploy app that can read **old and new** shapes.
3. Backfill in batches with statement timeouts.
4. Switch reads/writes to new shape.
5. **Contract:** remove old columns only in a later release.

## Postgres tips

- Prefer `CREATE INDEX CONCURRENTLY` for large tables.
- Set `lock_timeout` / `statement_timeout` on migration sessions.
- Never ship a destructive drop in the same release that first requires the new column.

## Rollback

App rollback must remain possible until contract phase completes.
