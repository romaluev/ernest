"""Ernest enforcement plugin.

Registers ``pre_tool_call`` hooks that enforce:
  - Ernest profile filesystem scope (read/write/deny globs from ernest.yaml)
  - Draft-only external actions (block send/publish/write connectors)

Install: symlink into ~/.hermes/profiles/ernest/plugins/ernest-enforcement and
add ``ernest-enforcement`` to ``plugins.enabled`` in config.yaml.
"""

from __future__ import annotations

import importlib.util
import json
import logging
import os
import re
from datetime import datetime, timezone
from typing import Any, Dict, Optional

logger = logging.getLogger("ernest.enforcement")

_guard = None
_scope_cache: Dict[str, Optional[dict]] = {}
_HERE = os.path.dirname(os.path.abspath(__file__))

# Defense in depth: mock connectors omit send tools; this blocks live send paths.
_DRAFT_BLOCK_PATTERNS = [
    re.compile(r"(?i)(outlook|email|mail|message).*(send|publish)"),
    re.compile(r"(?i)^send_(email|message|mail)$"),
    re.compile(r"(?i)hubspot_(create|update|delete|merge|write)"),
    re.compile(r"(?i)slack_(post|send|publish)"),
    re.compile(r"(?i)enrichment_(write|push|export_live)"),
]


def _profile_root() -> Optional[str]:
    for key in ("HERMES_HOME", "ERNEST_ROOT"):
        root = os.environ.get(key)
        if root and os.path.isdir(root):
            return os.path.realpath(root)
    return None


def _ernest_root() -> Optional[str]:
    return _profile_root()


def _load_guard():
    global _guard
    if _guard is not None:
        return _guard
    guard_path = os.path.join(_HERE, "guard.py")
    spec = importlib.util.spec_from_file_location("ernest_scope_guard", guard_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    _guard = mod
    return _guard


def _active_profile() -> str:
    try:
        from hermes_cli.profiles import get_active_profile  # type: ignore

        name = get_active_profile()
        if name:
            return str(name)
    except Exception:
        pass
    name = os.environ.get("HERMES_PROFILE")
    if name:
        return name
    home = os.environ.get("HERMES_HOME", "")
    if "profiles" in home:
        return os.path.basename(home.rstrip("/"))
    return "ernest"


def _get_scope(guard, profile: str, ernest_root: str) -> Optional[dict]:
    if profile not in _scope_cache:
        try:
            _scope_cache[profile] = guard.load_scope(profile, ernest_root)
        except Exception as exc:  # pragma: no cover
            logger.warning("ernest-enforcement: load_scope(%s) failed: %s", profile, exc)
            _scope_cache[profile] = None
    return _scope_cache[profile]


def _audit(ernest_root: str, profile: str, tool: str, decision: str, reason: str) -> None:
    try:
        log_path = os.path.join(ernest_root, "logs", "enforcement-audit.log")
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        with open(log_path, "a", encoding="utf-8") as fh:
            fh.write(f"{ts}|{profile}|{tool}|{decision}|{reason}\n")
    except Exception as exc:  # pragma: no cover
        logger.debug("ernest-enforcement: audit write failed: %s", exc)


def _draft_only_block(tool_name: str) -> Optional[Dict[str, str]]:
    for pattern in _DRAFT_BLOCK_PATTERNS:
        if pattern.search(tool_name or ""):
            return {
                "error": "draft_only",
                "tool": tool_name,
                "reason": "External publish/send/write blocked until CEO approval.",
            }
    return None


def _scope_pre_tool_call(
    tool_name: str = "",
    args: Optional[Dict[str, Any]] = None,
    **_kw: Any,
) -> Optional[Dict[str, str]]:
    ernest_root = _ernest_root()
    if not ernest_root:
        return None

    guard = _load_guard()
    if tool_name not in guard.GUARDED_TOOLS:
        return None

    profile = _active_profile()
    scope = _get_scope(guard, profile, ernest_root)
    if scope is None:
        logger.warning(
            "ernest-enforcement: no scope for profile '%s' — allowing '%s'",
            profile,
            tool_name,
        )
        return None

    try:
        block = guard.evaluate(profile, tool_name, args or {}, ernest_root, scope=scope)
    except Exception as exc:  # pragma: no cover
        logger.warning("ernest-enforcement: evaluate error: %s", exc)
        return None

    if block is None:
        return None

    _audit(ernest_root, profile, tool_name, "DENY", block.get("reason", ""))
    block["tool"] = tool_name
    return {
        "action": "block",
        "message": "ERNEST SCOPE DENIED " + json.dumps(block, ensure_ascii=False),
    }


def _draft_pre_tool_call(
    tool_name: str = "",
    args: Optional[Dict[str, Any]] = None,
    **_kw: Any,
) -> Optional[Dict[str, str]]:
    block = _draft_only_block(tool_name)
    if block is None:
        return None
    ernest_root = _ernest_root()
    if ernest_root:
        _audit(ernest_root, _active_profile(), tool_name, "DRAFT_ONLY", block["reason"])
    return {
        "action": "block",
        "message": "ERNEST DRAFT ONLY " + json.dumps(block, ensure_ascii=False),
    }


def register(ctx) -> None:
    ctx.register_hook("pre_tool_call", _draft_pre_tool_call)
    ctx.register_hook("pre_tool_call", _scope_pre_tool_call)
    logger.debug("ernest-enforcement: registered draft-only + scope gate")
