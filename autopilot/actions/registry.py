from __future__ import annotations

from typing import Any, Callable

from autopilot.models import Policy, Signal

ActionFn = Callable[[Signal, Policy, bool], dict[str, Any]]

_REGISTRY: dict[str, ActionFn] = {}


def action(name: str) -> Callable[[ActionFn], ActionFn]:
    def deco(fn: ActionFn) -> ActionFn:
        _REGISTRY[name] = fn
        return fn

    return deco


def get(name: str) -> ActionFn:
    if name not in _REGISTRY:
        raise KeyError(f"action not allowlisted: {name}")
    return _REGISTRY[name]


def names() -> list[str]:
    return sorted(_REGISTRY)


# Import side effects register actions.
from autopilot.actions import builtins as _builtins  # noqa: E402,F401
