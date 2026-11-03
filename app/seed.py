import os
import random
import sys

import psycopg
from psycopg.types.json import Jsonb

DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://admin:admin123@localhost:5432/ledgerline"
)

tenant, count = sys.argv[1], int(sys.argv[2])
rows = [
    (
        tenant,
        Jsonb(
            {
                "order": i,
                "amount": round(random.uniform(5, 500), 2),
                "sku": f"SKU-{random.randint(1, 999):03d}",
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
