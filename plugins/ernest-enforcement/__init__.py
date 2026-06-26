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
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set

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
    r"TRANSFER|SHARE|LABEL|UNLABEL|COMMENT|DUPLICATE|CHARGE|REFUND|CAPTURE|BILL|"
    r"PAYOUT|SUBSCRIBE|UNSUBSCRIBE|RENAME|EDIT|GRANT|REVOKE|APPROVE|REJECT|BOOK|"
    r"ORDER|SUBMIT|DEPLOY|INSTALL|EXECUTE|RUN|TRIGGER|DISPATCH|ENABLE|DISABLE|"
    r"REACT|PIN|UNPIN|JOIN|LEAVE|KICK|BAN)(?:_|$)"
)
_READ_VERB_RE = re.compile(
    r"(?i)(?:^|_)(GET|LIST|SEARCH|FETCH|READ|FIND|QUERY|RETRIEVE|SCROLL|VIEW|"
    r"WATCH|DOWNLOAD|EXPORT|RESOLVE|CHECK|ANALYZE|DISPLAY|HEALTH|COUNT|EXIST|"
    r"LOOKUP|SHOW|DESCRIBE|INSPECT|STATUS|BALANCE|POLL)(?:_|$)"
)
# Domains that make an unknown/ambiguous action sensitive -> deny-by-default.
_SENSITIVE_HINTS = (
    "gmail", "outlook", "mail", "email", "slack", "teams", "discord", "telegram",
    "whatsapp", "sms", "twilio", "phone", "call", "hubspot", "salesforce", "crm",
    "pipedrive", "calendar", "event", "meeting", "contact", "deal", "lead",
    "notion", "linear", "asana", "jira", "monday", "clickup", "trello", "github",
    "gitlab", "intercom", "zendesk", "pylon", "sheet", "drive", "box", "dropbox",
    "stripe", "paypal", "bank", "invoice", "payment", "wire", "payout", "ads",
    "campaign", "tweet", "twitter", "facebook", "instagram", "linkedin", "publish",
    "canva", "wordpress", "shopify", "airtable", "confluence",
)
_SLUG_SHAPE_RE = re.compile(r"^[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+$")


def _norm_slug(slug: str) -> str:
    return re.sub(r"[\s\-]+", "_", (slug or "").strip()).upper()


def _slug_is_read(slug: str) -> bool:
    s = _norm_slug(slug)
    return bool(_READ_VERB_RE.search(s)) and not _MUTATION_VERB_RE.search(s)


def _slug_is_draft_safe(slug: str) -> bool:
    s = _norm_slug(slug)
    if not re.search(r"(?:^|_)DRAFT$", s):
        return False
    # ends with DRAFT but carries a transmit verb (e.g. SEND_DRAFT) -> not safe
    return not (set(s.split("_")) & {"SEND", "PUBLISH", "POST", "FORWARD", "REPLY", "DELETE"})


def _name_is_sensitive(name: str) -> bool:
    blob = (name or "").lower()
    return any(h in blob for h in _SENSITIVE_HINTS)
_SLUG_KEYS = {
    "tool_slug", "slug", "tool", "tool_name", "toolname", "action",
    "action_name", "recipe_slug", "name", "function", "function_name",
}

# HubSpot hygiene — sole bounded auto-write exception (mechanical fields only).
_HYGIENE_JOB_ID = "ernest-hubspot-hygiene"
_HYGIENE_ALLOWED_SLUGS = {"HUBSPOT_UPDATE_CONTACT"}
_HYGIENE_FORBIDDEN_SLUG_RE = re.compile(
    r"(?i)HUBSPOT_(CREATE|DELETE|MERGE|ASSOCIATE|IMPORT|BATCH)"
)
_HYGIENE_PROP_KEYS = {
    "properties", "property", "fields", "field", "data", "payload", "contact_properties",
}
_hygiene_policy_cache: Optional[Dict[str, Any]] = None


def _parse_yaml_bool(val: str) -> bool:
    return val.strip().lower() in ("true", "yes", "1")


def _parse_yaml_list_block(text: str, key: str) -> List[str]:
    """Extract `- item` lines under ``key:`` in a yaml-ish block."""
    items: List[str] = []
    lines = text.splitlines()
    in_block = False
    base_indent = 0
    for raw in lines:
        if not in_block:
            if re.match(rf"^\s*{re.escape(key)}\s*:", raw):
                in_block = True
                base_indent = len(raw) - len(raw.lstrip())
            continue
        if not raw.strip():
            continue
        indent = len(raw) - len(raw.lstrip())
        if indent <= base_indent and ":" in raw.strip():
            break
        m = re.match(r"^\s*-\s+(.+?)\s*$", raw)
        if m:
            items.append(m.group(1).strip().strip('"').strip("'"))
    return items


def _load_hygiene_policy(ernest_root: Optional[str] = None) -> Dict[str, Any]:
    global _hygiene_policy_cache
    if _hygiene_policy_cache is not None:
        return _hygiene_policy_cache
    default: Dict[str, Any] = {
        "job_id": _HYGIENE_JOB_ID,
        "dry_run": True,
        "approved": False,
        "mechanical_fields": {"company", "firstname", "lastname", "jobtitle"},
        "active_run_marker": "logs/hygiene-active-run.json",
    }
    root = ernest_root or _ernest_root()
    if not root:
        _hygiene_policy_cache = default
        return default
    path = os.path.join(root, "ernest.yaml")
    if not os.path.isfile(path):
        _hygiene_policy_cache = default
        return default
    try:
        text = open(path, "r", encoding="utf-8").read()
    except OSError:
        _hygiene_policy_cache = default
        return default

    policy = dict(default)
    m = re.search(r"^\s*dry_run\s*:\s*(\S+)", text, re.MULTILINE)
    if m:
        policy["dry_run"] = _parse_yaml_bool(m.group(1))
    m = re.search(r"^\s*approved\s*:\s*(\S+)", text, re.MULTILINE)
    if m:
        policy["approved"] = _parse_yaml_bool(m.group(1))
    m = re.search(r'^\s*active_run_marker\s*:\s*["\']?([^"\']+)["\']?', text, re.MULTILINE)
    if m:
        policy["active_run_marker"] = m.group(1).strip()
    fields = _parse_yaml_list_block(text, "mechanical_fields")
    if fields:
        policy["mechanical_fields"] = set(f.lower() for f in fields)
    _hygiene_policy_cache = policy
    return policy


def _hygiene_active_run_valid(policy: Dict[str, Any], ernest_root: str) -> bool:
    marker_rel = policy.get("active_run_marker", "logs/hygiene-active-run.json")
    marker_path = os.path.join(ernest_root, marker_rel)
    if not os.path.isfile(marker_path):
        return False
    try:
        with open(marker_path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return False
    if data.get("job_id") != policy.get("job_id", _HYGIENE_JOB_ID):
        return False
    if not data.get("mechanical_only"):
        return False
    started = data.get("started_at", "")
    try:
        ts = datetime.fromisoformat(started.replace("Z", "+00:00"))
        age = time.time() - ts.timestamp()
        if age > 3600:
            return False
    except (ValueError, TypeError):
        return False
    return True


def _collect_property_names(obj: Any, depth: int = 0) -> Set[str]:
    """Pull HubSpot property/field names from nested execute-tool args."""
    names: Set[str] = set()
    if depth > 8:
        return names
    if isinstance(obj, dict):
        for k, v in obj.items():
            kl = str(k).lower()
            if kl in _HYGIENE_PROP_KEYS and isinstance(v, dict):
                for pk in v:
                    if isinstance(pk, str):
                        names.add(pk.lower())
            elif kl in ("property", "field", "name") and isinstance(v, str):
                names.add(v.lower())
            else:
                names |= _collect_property_names(v, depth + 1)
    elif isinstance(obj, list):
        for item in obj:
            names |= _collect_property_names(item, depth + 1)
    return names


def _hygiene_may_auto_apply(
    tool_name: str,
    args: Optional[Dict[str, Any]] = None,
) -> bool:
    """True only when a mechanical HubSpot hygiene update may bypass draft-only."""
    upper = (tool_name or "").upper()
    if upper not in _COMPOSIO_EXEC_TOOLS:
        return False

    slugs = [s.upper() for s in _collect_slugs(args or {})]
    if not slugs:
        return False
    for slug in slugs:
        if _HYGIENE_FORBIDDEN_SLUG_RE.search(slug):
            return False
        if slug not in _HYGIENE_ALLOWED_SLUGS:
            return False

    ernest_root = _ernest_root()
    if not ernest_root:
        return False

    policy = _load_hygiene_policy(ernest_root)
    if policy.get("dry_run", True) or not policy.get("approved", False):
        return False

    cron_job = os.environ.get("ERNEST_CRON_JOB", "")
    if cron_job != policy.get("job_id", _HYGIENE_JOB_ID):
        return False

    if not _hygiene_active_run_valid(policy, ernest_root):
        return False

    allowed_fields = policy.get("mechanical_fields") or set()
    if not isinstance(allowed_fields, set):
        allowed_fields = {str(x).lower() for x in allowed_fields}

    prop_names = _collect_property_names(args or {})
    if prop_names and not prop_names.issubset(allowed_fields):
        return False

    return True


def _slug_is_mutation(slug: str) -> bool:
    if _slug_is_draft_safe(slug):  # CREATE_*_DRAFT etc. — drafting is allowed
        return False
    s = _norm_slug(slug)
    if _slug_is_read(slug):
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
        if _hygiene_may_auto_apply(name, args):
            return None
        for slug in _collect_slugs(args or {}):
            if _slug_is_mutation(slug):
                return {
                    "error": "draft_only",
                    "tool": name,
                    "action": slug,
                    "reason": f"Live mutation '{slug}' blocked until CEO approval (draft-first).",
                }
        return None

    # 3. Directly-named connector tools — DENY-BY-DEFAULT on connector domains.
    #    Filesystem tools (write_file/edit_file/...) contain mutation verbs too but
    #    are handled by the scope guard, NOT here — so only connector-domain
    #    (sensitive) names get the mutation/deny-by-default treatment.
    if _name_is_sensitive(name):
        for slug in [name] + list(_collect_slugs(args or {})):
            if _slug_is_draft_safe(slug):
                continue
            if _slug_is_mutation(slug):
                return {
                    "error": "draft_only",
                    "tool": name,
                    "action": slug,
                    "reason": f"Live mutation '{slug}' blocked until CEO approval (draft-first).",
                }
        if not _slug_is_read(name) and not _slug_is_draft_safe(name):
            return {
                "error": "draft_only",
                "tool": name,
                "reason": f"Unrecognized action on sensitive connector '{name}' blocked "
                          "(deny-by-default) until CEO approval.",
            }
        return None

    # 4. Non-connector tools: defense-in-depth name patterns only.
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


def _onboarded_marker_path() -> Optional[str]:
    """Path to Ernest/.onboarded in the Obsidian vault."""
    vault = os.environ.get("OBSIDIAN_VAULT_PATH", "")
    if not vault:
        env_path = os.path.join(_profile_root() or "", ".env")
        if env_path and os.path.isfile(env_path):
            try:
                for line in open(env_path, encoding="utf-8"):
                    if line.startswith("OBSIDIAN_VAULT_PATH="):
                        vault = line.split("=", 1)[1].strip().strip('"').strip("'")
                        break
            except OSError:
                pass
    if not vault:
        vault = os.path.expanduser("~/ErnestVault")
    return os.path.join(vault, "Ernest", ".onboarded")


def _is_onboarded() -> bool:
    marker = _onboarded_marker_path()
    return bool(marker and os.path.isfile(marker))


_START_RE = re.compile(r"^/start(?:@\w+)?\s*$", re.IGNORECASE)

_FULL_ONBOARD_KICKOFF = (
    "[CEO pressed Start — first contact. Run first-contact onboarding per SOUL: "
    "be warm, concise, and genuinely useful. Greet as Ernest; convey your full "
    "range in plain language (inbox, follow-ups, CRM, calendar, sourcing, Slack); "
    "send HubSpot/Outlook/Slack connect links via COMPOSIO_MANAGE_CONNECTIONS; "
    "ask who they are and what they want off their plate. Draft-first always.]"
)

_WELCOME_BACK = (
    "[CEO pressed Start — already onboarded. Greet them briefly, remind them you "
    "watch and draft on ask, and ask what they want to work on today.]"
)


def _start_pre_gateway_dispatch(
    event=None,
    gateway=None,
    session_store=None,
    **_kw: Any,
) -> Optional[Dict[str, str]]:
    """Rewrite Telegram /start into Ernest onboarding kickoff (before unknown-command guard)."""
    try:
        text = (getattr(event, "text", None) or "").strip()
        if not _START_RE.match(text):
            return None

        source = getattr(event, "source", None)
        platform = getattr(getattr(source, "platform", None), "value", None)
        if platform and platform != "telegram":
            return None

        if _is_onboarded():
            logger.info("ernest-enforcement: /start -> welcome-back (onboarded)")
            return {"action": "rewrite", "text": _WELCOME_BACK}

        logger.info("ernest-enforcement: /start -> full onboarding kickoff")
        return {"action": "rewrite", "text": _FULL_ONBOARD_KICKOFF}
    except Exception as exc:
        logger.warning("ernest-enforcement: pre_gateway_dispatch error: %s", exc)
        return None


def register(ctx) -> None:
    ctx.register_hook("pre_tool_call", _draft_pre_tool_call)
    ctx.register_hook("pre_tool_call", _scope_pre_tool_call)
    ctx.register_hook("pre_gateway_dispatch", _start_pre_gateway_dispatch)
    logger.debug("ernest-enforcement: registered draft-only + scope gate + /start hook")
