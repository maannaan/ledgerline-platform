"""Tenant-aware metrics with controlled cardinality."""

from __future__ import annotations

from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

REQUEST_COUNT = Counter(
    "ledgerline_http_requests_total",
    "HTTP requests",
    ["endpoint", "method", "status_class", "tenant"],
)

REQUEST_LATENCY = Histogram(
    "ledgerline_http_request_duration_seconds",
    "HTTP request latency",
    ["endpoint", "method", "tenant"],
    buckets=(0.025, 0.05, 0.1, 0.2, 0.3, 0.5, 1.0, 2.5, 5.0, 10.0),
)


def observe_request(
    *,
    endpoint: str,
    method: str,
    status_code: int,
    tenant: str,
    duration_s: float,
) -> None:
    # Bound tenant label: unknown/unauthenticated collapse to avoid cardinality blow-ups.
    tenant_label = tenant if tenant and tenant != "-" else "none"
    status_class = f"{status_code // 100}xx"
    endpoint_label = endpoint if len(endpoint) < 64 else "other"
    REQUEST_COUNT.labels(endpoint_label, method, status_class, tenant_label).inc()
    REQUEST_LATENCY.labels(endpoint_label, method, tenant_label).observe(duration_s)


def metrics_payload() -> tuple[bytes, str]:
    return generate_latest(), CONTENT_TYPE_LATEST
