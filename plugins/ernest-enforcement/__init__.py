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

# Composio's Tool Router exposes GENERIC execution wrappers; the real action
# (e.g. GMAIL_SEND_EMAIL) rides in the ARGS, not the tool name — so name-only
# matching is bypassable. For these wrappers we inspect the action slug(s).
_COMPOSIO_EXEC_TOOLS = {
    "COMPOSIO_EXECUTE_TOOL",
    "COMPOSIO_MULTI_EXECUTE_TOOL",
    "COMPOSIO_EXECUTE_RECIPE",
}
# Remote code / proxy execution can hit arbitrary live APIs and escapes every
# name/arg/filesystem guard. Draft-first => blocked until the CEO approves.
_COMPOSIO_REMOTE_TOOLS = {
    "COMPOSIO_REMOTE_BASH_TOOL",
    "COMPOSIO_REMOTE_WORKBENCH",
}

# Defense in depth for any directly-named connector tools.
_DRAFT_BLOCK_PATTERNS = [
    re.compile(r"(?i)(outlook|gmail|email|mail|message).*(send|publish|reply|forward)"),
    re.compile(r"(?i)^send_(email|message|mail)$"),
    re.compile(r"(?i)hubspot_(create|update|delete|merge|write)"),
    re.compile(r"(?i)slack_(post|send|publish)"),
    re.compile(r"(?i)enrichment_(write|push|export_live)"),
]

# Action-slug verbs that mutate live systems. "DRAFT" always wins (drafting is
# the whole point); pure reads (GET/LIST/SEARCH/…) never match and pass.
_MUTATION_VERB_RE = re.compile(
    r"(?i)(?:^|_)(SEND|REPLY|FORWARD|PUBLISH|POST|CREATE|UPDATE|DELETE|REMOVE|"
    r"ARCHIVE|TRASH|MOVE|MERGE|ADD|SET|PATCH|PUT|INVITE|SCHEDULE|CANCEL|ACCEPT|"
    r"DECLINE|ASSIGN|CLOSE|COMPLETE|MARK|UPSERT|IMPORT|UPLOAD|REPLACE|CLEAR|PAY|"
    r"TRANSFER|SHARE)(?:_|$)"
)
_SLUG_SHAPE_RE = re.compile(r"^[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+$")
_SLUG_KEYS = {
    "tool_slug", "slug", "tool", "tool_name", "toolname", "action",
    "action_name", "recipe_slug", "name", "function", "function_name",
}


def _slug_is_mutation(slug: str) -> bool:
    s = (slug or "").upper()
    if "DRAFT" in s:  # CREATE_*_DRAFT etc. — drafting is allowed
        return False
    return bool(_MUTATION_VERB_RE.search(s))


def _collect_slugs(obj: Any, depth: int = 0) -> list:
    """Recursively pull candidate Composio action slugs out of nested args."""
    found: list = []
    if depth > 6:
        return found
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and (str(k).lower() in _SLUG_KEYS or _SLUG_SHAPE_RE.match(v)):
                found.append(v)
            else:
                found.extend(_collect_slugs(v, depth + 1))
    elif isinstance(obj, list):
        for item in obj:
            found.extend(_collect_slugs(item, depth + 1))
    elif isinstance(obj, str):
        if _SLUG_SHAPE_RE.match(obj):
            found.append(obj)
    return found


def _has_scope(d: Optional[str]) -> bool:
    """True if ``d`` is a profile root containing ernest.yaml (matches guard.load_scope)."""
    if not d:
        return False
    return os.path.isfile(os.path.join(d, "ernest.yaml")) or os.path.isfile(
        os.path.join(d, "profile", "ernest.yaml")
    )


def _profile_root() -> Optional[str]:
    """Resolve the Ernest PROFILE directory (where ernest.yaml lives).

    Must be the profile dir, not HERMES_HOME — guard.load_scope/to_ernest_relative
    are rooted there. We derive it from this plugin's own path so scope enforcement
    works even when no env vars are set (cron, gateway, multi-account).
    """
    # 1. Explicit override (tests / unusual installs) — only if it really holds scope.
    env_root = os.environ.get("ERNEST_ROOT")
    if _has_scope(env_root):
        return os.path.realpath(env_root)  # type: ignore[arg-type]

    # 2. Derive from <root>/plugins/ernest-enforcement/__init__.py — env-independent.
    here_root = os.path.dirname(os.path.dirname(_HERE))
    if _has_scope(here_root):
        return os.path.realpath(here_root)

    # 3. HERMES_HOME/profiles/<active profile>.
    home = os.environ.get("HERMES_HOME")
    if home:
        cand = os.path.join(home, "profiles", _active_profile())
        if _has_scope(cand):
            return os.path.realpath(cand)

    # 4. Last resort: an existing dir (legacy behavior; scope may be absent).
    for key in ("ERNEST_ROOT", "HERMES_HOME"):
        d = os.environ.get(key)
        if d and os.path.isdir(d):
            return os.path.realpath(d)
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


def _draft_only_block(
    tool_name: str,
    args: Optional[Dict[str, Any]] = None,
) -> Optional[Dict[str, str]]:
    name = tool_name or ""
    upper = name.upper()

    # 1. Remote code / proxy execution — unconditionally draft-gated.
    if upper in _COMPOSIO_REMOTE_TOOLS:
        return {
            "error": "draft_only",
            "tool": name,
            "reason": "Remote code/proxy execution can perform live actions; blocked until CEO approval.",
        }

    # 2. Composio execution wrappers — inspect the action slug(s) in the args.
    if upper in _COMPOSIO_EXEC_TOOLS:
        for slug in _collect_slugs(args or {}):
            if _slug_is_mutation(slug):
                return {
                    "error": "draft_only",
                    "tool": name,
                    "action": slug,
                    "reason": f"Live mutation '{slug}' blocked until CEO approval (draft-first).",
                }
        return None

    # 3. Directly-named connector tools (defense in depth).
    for pattern in _DRAFT_BLOCK_PATTERNS:
        if pattern.search(name):
            return {
                "error": "draft_only",
                "tool": name,
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
    block = _draft_only_block(tool_name, args)
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
