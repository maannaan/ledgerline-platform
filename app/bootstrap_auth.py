"""Upsert demo/tenant API key hashes. Prints plaintext keys once to stdout."""

from __future__ import annotations

import os
import sys

from auth import generate_api_key, hash_api_key
from config import load_settings
from db import close_pool, connection, init_pool
from schema import apply_schema


def upsert_key(tenant_id: str, raw_key: str, role: str, label: str, pepper: str) -> None:
    key_hash = hash_api_key(raw_key, pepper)
    with connection() as conn:
        conn.execute(
            """
            INSERT INTO api_keys (key_hash, tenant_id, role, label)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (key_hash) DO UPDATE
              SET tenant_id = EXCLUDED.tenant_id,
                  role = EXCLUDED.role,
                  label = EXCLUDED.label,
                  revoked_at = NULL
            """,
            (key_hash, tenant_id, role, label),
        )


def main() -> int:
    settings = load_settings()
    init_pool(settings)
    apply_schema()

    # SEED_API_KEYS=acme:key,brightpath:key  OR auto-generate if AUTO_GENERATE_KEYS=1
    raw = os.getenv("SEED_API_KEYS", "").strip()
    pairs: list[tuple[str, str]] = []
    if raw:
        for part in raw.split(","):
            tenant, _, key = part.partition(":")
            tenant, key = tenant.strip(), key.strip()
            if not tenant or not key:
                print(f"invalid SEED_API_KEYS entry: {part}", file=sys.stderr)
                return 1
            pairs.append((tenant, key))
    elif os.getenv("AUTO_GENERATE_KEYS", "").strip() == "1":
        for tenant in ("acme", "brightpath", "cobalt", "delta"):
            pairs.append((tenant, generate_api_key()))
    else:
        print("Set SEED_API_KEYS=tenant:key,... or AUTO_GENERATE_KEYS=1", file=sys.stderr)
        return 1

    print("tenant_id,api_key,role")
    for tenant, key in pairs:
        upsert_key(tenant, key, "tenant_user", f"{tenant}-default", settings.api_key_pepper)
        print(f"{tenant},{key},tenant_user")

    close_pool()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
