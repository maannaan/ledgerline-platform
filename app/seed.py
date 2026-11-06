import os
import secrets
import sys

import psycopg
from psycopg.types.json import Jsonb

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    raise SystemExit("DATABASE_URL is required (no hardcoded lab password in seed.py)")

tenant, count = sys.argv[1], int(sys.argv[2])
rows = [
    (
        tenant,
        Jsonb(
            {
                "order": i,
                "amount": round(secrets.SystemRandom().uniform(5, 500), 2),
                "sku": f"SKU-{secrets.randbelow(999) + 1:03d}",
            }
        ),
    )
    for i in range(count)
]

with psycopg.connect(DATABASE_URL) as conn:
    with conn.cursor() as cur:
        cur.executemany(
            "INSERT INTO records (tenant_id, payload) VALUES (%s, %s)", rows
        )
    conn.commit()

print(f"seeded {count} records for {tenant}")
