"""Connection helpers with timeouts and explicit transactions."""

from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

import psycopg
from psycopg.rows import tuple_row
from psycopg_pool import ConnectionPool

from config import Settings

_pool: ConnectionPool | None = None
_settings: Settings | None = None


def init_pool(settings: Settings) -> ConnectionPool:
    global _pool, _settings
    _settings = settings
    if _pool is not None:
        return _pool
    _pool = ConnectionPool(
        conninfo=settings.database_url,
        min_size=1,
        max_size=settings.db_pool_max_size,
        timeout=settings.db_connect_timeout_s,
        kwargs={
            "connect_timeout": max(1, int(settings.db_connect_timeout_s)),
            "row_factory": tuple_row,
            "options": f"-c statement_timeout={settings.db_statement_timeout_ms}",
        },
        open=True,
    )
    return _pool


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        _pool = None


def get_pool() -> ConnectionPool:
    if _pool is None:
        raise RuntimeError("Database pool is not initialized")
    return _pool


@contextmanager
def connection(*, autocommit: bool = False) -> Iterator[psycopg.Connection]:
    pool = get_pool()
    with pool.connection() as conn:
        conn.autocommit = autocommit
        try:
            yield conn
            if not autocommit:
                conn.commit()
        except Exception:
            if not autocommit:
                conn.rollback()
            raise


def ping() -> bool:
    with connection(autocommit=True) as conn:
        conn.execute("SELECT 1")
    return True
