from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any


@dataclass(frozen=True)
class Signal:
    name: str
    environment: str
    service: str
    severity: str = "warning"
    value: float | None = None
    attributes: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Signal":
        return cls(
            name=str(data["name"]),
            environment=str(data.get("environment", "staging")),
            service=str(data.get("service", "api")),
            severity=str(data.get("severity", "warning")),
            value=data.get("value"),
            attributes=dict(data.get("attributes") or {}),
        )


@dataclass(frozen=True)
class Policy:
    id: str
    description: str
    signal: str
    environments: list[str]
    services: list[str]
    action: str
    threshold: float | None = None
    duration_seconds: int = 0
    max_attempts: int = 1
    cooldown_seconds: int = 300
    max_capacity: int | None = None
    requires_approval: bool = False
    tenant_blast_radius: str = "platform"  # platform | single_tenant | none
    verification: str = "none"
    enabled: bool = True

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Policy":
        return cls(
            id=str(data["id"]),
            description=str(data.get("description", "")),
            signal=str(data["signal"]),
            environments=list(data.get("environments") or ["staging"]),
            services=list(data.get("services") or ["api"]),
            action=str(data["action"]),
            threshold=data.get("threshold"),
            duration_seconds=int(data.get("duration_seconds") or 0),
            max_attempts=int(data.get("max_attempts") or 1),
            cooldown_seconds=int(data.get("cooldown_seconds") or 300),
            max_capacity=data.get("max_capacity"),
            requires_approval=bool(data.get("requires_approval", False)),
            tenant_blast_radius=str(data.get("tenant_blast_radius", "platform")),
            verification=str(data.get("verification", "none")),
            enabled=bool(data.get("enabled", True)),
        )


@dataclass
class Decision:
    status: str  # dry_run | executed | blocked | skipped | error
    policy_id: str | None
    action: str | None
    reason: str
    idempotency_key: str
    details: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
