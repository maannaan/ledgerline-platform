"""Fail-closed runtime configuration. No insecure defaults."""

from __future__ import annotations

import os
from dataclasses import dataclass


class ConfigError(RuntimeError):
    pass


def _require(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise ConfigError(f"Missing required environment variable: {name}")
    return value


@dataclass(frozen=True)
class Settings:
    database_url: str
    admin_token: str
    api_key_pepper: str
    db_connect_timeout_s: float = 5.0
    db_statement_timeout_ms: int = 10_000
    db_pool_max_size: int = 10


def load_settings() -> Settings:
    return Settings(
        database_url=_require("DATABASE_URL"),
        admin_token=_require("ADMIN_TOKEN"),
        api_key_pepper=_require("API_KEY_PEPPER"),
        db_connect_timeout_s=float(os.getenv("DB_CONNECT_TIMEOUT_S", "5")),
        db_statement_timeout_ms=int(os.getenv("DB_STATEMENT_TIMEOUT_MS", "10000")),
        db_pool_max_size=int(os.getenv("DB_POOL_MAX_SIZE", "10")),
    )
