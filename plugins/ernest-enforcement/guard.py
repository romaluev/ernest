"""Ernest scope-guard: pure path/scope matcher for the ernest-enforcement plugin.

Adapted from Titan's titan-scope-guard. No Hermes imports so unit tests can run
under system python3.
"""

from __future__ import annotations

import os
import re
from typing import Dict, List, Optional, Tuple

READ_TOOLS = {"read_file", "search_files", "list_files", "grep", "glob_file_search"}
WRITE_TOOLS = {"write_file", "edit_file", "patch", "apply_patch", "create_file"}
GUARDED_TOOLS = READ_TOOLS | WRITE_TOOLS

ERNEST_TOP_DIRS = (
    "skills/",
    "memory/",
    "seed/",
    "profile/",
    "connectors/",
    "demo/",
    "plugins/",
)

PATH_ARG_KEYS = (
    "path",
    "file_path",
    "filename",
    "file",
    "target",
    "directory",
    "dir",
    "paths",
    "files",
    "pattern",
)


def glob_to_regex(pattern: str) -> str:
    out: List[str] = ["^"]
    i, n = 0, len(pattern)
    while i < n:
        if pattern[i : i + 3] == "**/":
            out.append("(?:.*/)?")
            i += 3
        elif pattern[i : i + 2] == "**":
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        elif pattern[i] == "{":
            j = pattern.find("}", i)
            if j == -1:
                out.append(re.escape(pattern[i]))
                i += 1
            else:
                alts = pattern[i + 1 : j].split(",")
                out.append("(?:" + "|".join(re.escape(a.strip()) for a in alts) + ")")
                i = j + 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    out.append("$")
    return "".join(out)


def glob_match(rel_path: str, pattern: str) -> bool:
    return re.match(glob_to_regex(pattern), rel_path) is not None


def matches_any(rel_path: str, patterns: List[str]) -> bool:
    return any(glob_match(rel_path, p) for p in patterns)


def _scope_from_yaml(text: str) -> Optional[Dict[str, List[str]]]:
    try:
        import yaml  # type: ignore
    except Exception:
        return None
    try:
        data = yaml.safe_load(text) or {}
    except Exception:
        return None
    scope = data.get("scope") or {}
    if not isinstance(scope, dict):
        return {"read": [], "write": [], "deny": []}
    return {
        "read": [str(x) for x in (scope.get("read") or [])],
        "write": [str(x) for x in (scope.get("write") or [])],
        "deny": [str(x) for x in (scope.get("deny") or [])],
    }


_LIST_ITEM_RE = re.compile(r'^\s*-\s*["\']?([^"\'#]+?)["\']?\s*(?:#.*)?$')


def _scope_from_text(text: str) -> Dict[str, List[str]]:
    result: Dict[str, List[str]] = {"read": [], "write": [], "deny": []}
    lines = text.splitlines()
    in_scope = False
    scope_indent = 0
    section: Optional[str] = None
    for raw in lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        stripped = raw.strip()
        if not in_scope:
            if stripped == "scope:" or stripped.startswith("scope:"):
                in_scope = True
                scope_indent = indent
            continue
        if indent <= scope_indent and ":" in stripped and not stripped.endswith(":"):
            break
        if indent <= scope_indent and stripped.endswith(":"):
            break
        key = stripped.rstrip(":")
        if key in ("read", "write", "deny") and stripped.endswith(":"):
            section = key
            continue
        m = _LIST_ITEM_RE.match(raw)
        if m and section:
            result[section].append(m.group(1).strip())
    return result


def load_scope(profile_name: str, ernest_root: str) -> Optional[Dict[str, List[str]]]:
    """Load read/write/deny globs from ernest.yaml at profile root."""
    candidates = [
        os.path.join(ernest_root, "ernest.yaml"),
        os.path.join(ernest_root, "profile", "ernest.yaml"),
    ]
    for path in candidates:
        if not os.path.isfile(path):
            continue
        with open(path, "r", encoding="utf-8") as fh:
            text = fh.read()
        return _scope_from_yaml(text) or _scope_from_text(text)
    return None


def to_ernest_relative(arg: str, ernest_root: str) -> Tuple[Optional[str], bool]:
    if not isinstance(arg, str) or not arg:
        return None, False
    root = os.path.realpath(ernest_root)
    cleaned = arg.strip()

    looks_ernest = cleaned.startswith(ERNEST_TOP_DIRS)
    if cleaned.startswith("./"):
        cleaned = cleaned[2:]
        looks_ernest = cleaned.startswith(ERNEST_TOP_DIRS)

    if os.path.isabs(cleaned):
        abs_path = os.path.realpath(cleaned)
    elif cleaned.startswith(ERNEST_TOP_DIRS):
        abs_path = os.path.realpath(os.path.join(root, cleaned))
    else:
        abs_path = os.path.realpath(os.path.join(root, cleaned))

    inside = abs_path == root or abs_path.startswith(root + os.sep)
    if inside:
        rel = os.path.relpath(abs_path, root)
        return rel.replace(os.sep, "/"), False

    if looks_ernest or ".." in arg:
        return None, True
    return None, False


def _candidate_paths(args: Dict) -> List[str]:
    out: List[str] = []
    if not isinstance(args, dict):
        return out
    seen = set()

    def add(v: str) -> None:
        if v and v not in seen:
            seen.add(v)
            out.append(v)

    for k in PATH_ARG_KEYS:
        if k not in args:
            continue
        v = args[k]
        if isinstance(v, list):
            for item in v:
                if isinstance(item, str):
                    add(item)
        elif isinstance(v, str):
            add(v)

    for k, v in args.items():
        if k in PATH_ARG_KEYS:
            continue
        if isinstance(v, str) and ("/" in v or v.endswith((".md", ".yaml", ".json", ".csv"))):
            add(v)
        elif isinstance(v, list):
            for item in v:
                if isinstance(item, str) and ("/" in item or item.endswith(".md")):
                    add(item)
    return out


def decide_path(
    scope: Dict[str, List[str]],
    tool_name: str,
    rel_path: str,
) -> Optional[Dict[str, str]]:
    op = "write" if tool_name in WRITE_TOOLS else "read"
    if matches_any(rel_path, scope.get("deny", [])):
        return {"reason": "matches scope.deny", "scope": op, "path": rel_path}
    allow = scope.get(op, [])
    if not matches_any(rel_path, allow):
        return {"reason": f"not in scope.{op}", "scope": op, "path": rel_path}
    return None


def evaluate(
    profile_name: str,
    tool_name: str,
    args: Dict,
    ernest_root: str,
    scope: Optional[Dict[str, List[str]]] = None,
) -> Optional[Dict[str, str]]:
    if tool_name not in GUARDED_TOOLS:
        return None
    if scope is None:
        scope = load_scope(profile_name, ernest_root)
    if scope is None:
        return None

    for arg in _candidate_paths(args):
        rel, escaped = to_ernest_relative(arg, ernest_root)
        if escaped:
            return {
                "error": "scope_path_escape",
                "profile": profile_name,
                "path": arg,
                "scope": "write" if tool_name in WRITE_TOOLS else "read",
                "reason": "path escapes ERNEST_ROOT",
            }
        if rel is None:
            continue
        block = decide_path(scope, tool_name, rel)
        if block is not None:
            return {
                "error": "ernest_scope_denied",
                "profile": profile_name,
                "path": block["path"],
                "scope": block["scope"],
                "reason": block["reason"],
            }
    return None
