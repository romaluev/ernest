#!/usr/bin/env python3
"""Adversarial tests for the Ernest enforcement gate.

Pure stdlib — runs under system python3, no Hermes import required. Loads the
real plugin code and hammers the draft-only matcher and filesystem scope with
hand-built attacks: "how would something trick Ernest into a live send or a
read of secrets?"  Exit non-zero on any failure.
"""
from __future__ import annotations

import importlib.util
import json
import os
import re
import sys
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN = os.path.join(ROOT, "plugins", "ernest-enforcement")


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


enf = _load("ernest_enf", os.path.join(PLUGIN, "__init__.py"))
guard = _load("ernest_guard", os.path.join(PLUGIN, "guard.py"))

failures: list[str] = []


def check(label, cond):
    mark = "ok  " if cond else "FAIL"
    print(f"  [{mark}] {label}")
    if not cond:
        failures.append(label)


def blocked(tool, args=None):
    return enf._draft_only_block(tool, args or {}) is not None


# ── Draft-only: live SENDS / mutations MUST be blocked ──────────────────────
print("draft-only — must BLOCK (live actions):")
MUST_BLOCK = [
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "GMAIL_SEND_EMAIL"}),               # the catastrophe
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "OUTLOOK_SEND_EMAIL"}),
    ("COMPOSIO_EXECUTE_TOOL", {"slug": "HUBSPOT_DELETE_CONTACT"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "HUBSPOT_CREATE_DEAL"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "GOOGLECALENDAR_CREATE_EVENT"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "SLACK_SEND_MESSAGE"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "gmail_send_email"}),              # lowercase via key
    ("COMPOSIO_EXECUTE_TOOL", {"arguments": {"tool_slug": "GMAIL_SEND_EMAIL"}}),  # nested
    ("COMPOSIO_EXECUTE_TOOL", {"x": {"y": {"input": {"tool_slug": "GMAIL_SEND_EMAIL"}}}}),  # deep
    ("COMPOSIO_MULTI_EXECUTE_TOOL", {"tools": [{"tool_slug": "GMAIL_FETCH_EMAILS"},
                                               {"tool_slug": "SLACK_SEND_MESSAGE"}]}),  # one bad in batch
    ("COMPOSIO_EXECUTE_TOOL", {"some_key": "GMAIL_SEND_EMAIL"}),               # bare slug by shape
    ("COMPOSIO_REMOTE_BASH_TOOL", {"code": "curl -X POST https://api ..."}),  # proxy bypass
    ("COMPOSIO_REMOTE_WORKBENCH", {"code": "requests.post(...)"}),
    ("OUTLOOK_SEND_EMAIL", {}),                                               # direct name
    ("send_email", {}),
    ("hubspot_update_deal", {}),
    ("slack_post_message", {}),
    ("gmail_reply", {}),
    # deny-by-default closers: directly-named connectors with no pattern match
    ("STRIPE_CHARGE", {}),                                                    # money verb
    ("STRIPE_CREATE_CHARGE", {}),
    ("NOTION_UPDATE_PAGE", {}),                                               # no old pattern matched it
    ("NOTION-UPDATE-PAGE", {}),                                              # hyphen variant normalized
    ("NOTION_DO_WEIRD_THING", {}),                                            # unknown verb on sensitive -> deny
    ("GMAIL_SEND_DRAFT", {}),                                                 # draft-laundering: sends a draft
    ("STRIPE_REFUND", {}),
]
for tool, args in MUST_BLOCK:
    check(f"{tool} {args}", blocked(tool, args))

# ── Draft-only: reads / drafts / onboarding MUST pass ───────────────────────
print("draft-only — must ALLOW (reads, drafts, onboarding):")
MUST_ALLOW = [
    ("COMPOSIO_SEARCH_TOOLS", {"use_case": "read inbox"}),
    ("COMPOSIO_MANAGE_CONNECTIONS", {"toolkits": ["hubspot", "outlook"]}),    # connect links in onboarding
    ("COMPOSIO_INITIATE_CONNECTION", {"toolkit": "gmail"}),
    ("COMPOSIO_WAIT_FOR_CONNECTION", {"toolkits": ["gmail"]}),
    ("COMPOSIO_CREATE_PLAN", {"use_case": "draft a follow-up"}),              # planning, not a live action
    ("COMPOSIO_GET_TOOL_SCHEMAS", {"slugs": ["GMAIL_SEND_EMAIL"]}),           # inspecting schema != sending
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "GMAIL_FETCH_EMAILS"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "HUBSPOT_LIST_CONTACTS"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "GMAIL_CREATE_EMAIL_DRAFT"}),     # drafting is the whole point
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "OUTLOOK_CREATE_DRAFT"}),
    ("COMPOSIO_EXECUTE_TOOL", {"tool_slug": "GOOGLECALENDAR_GET_EVENTS"}),
    ("read_file", {"path": "SOUL.md"}),                                       # governed by scope, not draft
    ("write_file", {"path": "memory/x.md"}),
    # directly-named connector reads + drafts still pass under deny-by-default
    ("STRIPE_GET_BALANCE", {}),
    ("NOTION_FETCH_PAGE", {}),
    ("HUBSPOT_SEARCH_CONTACTS", {}),
    ("GMAIL_CREATE_DRAFT", {}),
    ("GMAIL_CREATE_EMAIL_DRAFT", {}),
]
# NOTE: GET_TOOL_SCHEMAS args contain GMAIL_SEND_EMAIL as a *string to inspect*, not an
# execution — and the wrapper isn't an exec tool, so args aren't scanned. Must still allow.
for tool, args in MUST_ALLOW:
    check(f"{tool} {args}", not blocked(tool, args))

# ── Filesystem scope (uses the installed/real ernest.yaml at repo root) ─────
print("filesystem scope — read **, write memory/** + vault, deny secrets:")
scope = guard.load_scope("ernest", ROOT)
check("ernest.yaml scope loaded", scope is not None)


def scope_blocked(tool, path):
    return guard.evaluate("ernest", tool, {"path": path}, ROOT, scope=scope) is not None


SCOPE_BLOCK = [
    ("write_file", "config.yaml"),          # distribution file — not writable
    ("write_file", "SOUL.md"),
    ("write_file", "../../etc/passwd"),     # path escape
    ("write_file", "skills/_meta/x.md"),    # not in write globs
    ("read_file", ".env"),                  # deny **/.env
    ("read_file", "plugins/ernest-enforcement/.env"),
]
SCOPE_ALLOW = [
    ("write_file", "memory/company-core.md"),
    ("read_file", "SOUL.md"),
    ("read_file", "config.yaml"),
    ("read_file", "docs/install.md"),
]
for tool, path in SCOPE_BLOCK:
    check(f"BLOCK {tool} {path}", scope_blocked(tool, path))
for tool, path in SCOPE_ALLOW:
    check(f"ALLOW {tool} {path}", not scope_blocked(tool, path))

# ── Runtime root resolution: scope must NOT silently no-op in the real install ─
# Regression for the bug where _ernest_root() returned HERMES_HOME (~/.hermes)
# instead of the profile dir (~/.hermes/profiles/ernest), so load_scope found
# nothing and the whole filesystem gate went dark. Simulate the installed layout.
print("runtime root resolution — scope stays armed under install/cron/gateway:")
import shutil
import tempfile

_tmp = tempfile.mkdtemp(prefix="ernest_rt_")
try:
    hermes_home = os.path.join(_tmp, ".hermes")
    prof_dir = os.path.join(hermes_home, "profiles", "ernest")
    plug_dir = os.path.join(prof_dir, "plugins", "ernest-enforcement")
    os.makedirs(plug_dir)
    shutil.copy(os.path.join(PLUGIN, "ernest.yaml") if os.path.isfile(os.path.join(PLUGIN, "ernest.yaml")) else os.path.join(ROOT, "ernest.yaml"),
                os.path.join(prof_dir, "ernest.yaml"))
    shutil.copy(os.path.join(PLUGIN, "__init__.py"), os.path.join(plug_dir, "__init__.py"))
    shutil.copy(os.path.join(PLUGIN, "guard.py"), os.path.join(plug_dir, "guard.py"))

    _saved = {k: os.environ.get(k) for k in ("HERMES_HOME", "HERMES_PROFILE", "ERNEST_ROOT")}
    try:
        os.environ.pop("HERMES_PROFILE", None)   # cron/gateway: not set
        os.environ.pop("ERNEST_ROOT", None)
        os.environ["HERMES_HOME"] = hermes_home  # points at hermes home, NOT profile dir
        rt = _load("ernest_enf_rt", os.path.join(plug_dir, "__init__.py"))
        resolved = rt._ernest_root()
        check("root resolves to the profile dir (not HERMES_HOME)",
              resolved == os.path.realpath(prof_dir))
        check("scope loads from resolved root",
              guard.load_scope("ernest", resolved) is not None)
    finally:
        for k, v in _saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
finally:
    shutil.rmtree(_tmp, ignore_errors=True)

# ── Hygiene exception — bounded mechanical HubSpot auto-apply only ─────────────
print("hygiene exception — mechanical HubSpot only when fully armed:")
_hy_tmp = tempfile.mkdtemp(prefix="ernest_hy_")
try:
    hy_root = os.path.join(_hy_tmp, "prof")
    os.makedirs(os.path.join(hy_root, "logs"))
    hy_yaml = (ROOT + "/ernest.yaml")  # base copy
    import shutil as _sh
    _sh.copy(os.path.join(ROOT, "ernest.yaml"), os.path.join(hy_root, "ernest.yaml"))
    # Patch approved + dry_run in copied yaml
    hy_text = open(os.path.join(hy_root, "ernest.yaml"), "r").read()
    hy_text = re.sub(r"^\s*dry_run:\s*\S+", "  dry_run: false", hy_text, count=1, flags=re.M)
    hy_text = re.sub(r"^\s*approved:\s*\S+", "  approved: true", hy_text, count=1, flags=re.M)
    open(os.path.join(hy_root, "ernest.yaml"), "w").write(hy_text)

    marker = {
        "run_id": "test-run",
        "job_id": "ernest-hubspot-hygiene",
        "mechanical_only": True,
        "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    open(os.path.join(hy_root, "logs/hygiene-active-run.json"), "w").write(json.dumps(marker))

    _hy_saved = {
        "ERNEST_ROOT": os.environ.get("ERNEST_ROOT"),
        "ERNEST_CRON_JOB": os.environ.get("ERNEST_CRON_JOB"),
    }
    try:
        os.environ["ERNEST_ROOT"] = hy_root
        os.environ["ERNEST_CRON_JOB"] = "ernest-hubspot-hygiene"
        enf._hygiene_policy_cache = None

        mech_ok = {
            "tool_slug": "HUBSPOT_UPDATE_CONTACT",
            "properties": {"company": "Acme Corp", "firstname": "Jane"},
        }
        check("ALLOW mechanical HUBSPOT_UPDATE_CONTACT when armed",
              enf._hygiene_may_auto_apply("COMPOSIO_EXECUTE_TOOL", mech_ok))

        os.environ["ERNEST_CRON_JOB"] = "ernest-ambient-watch"
        enf._hygiene_policy_cache = None
        check("BLOCK mechanical update from wrong cron job",
              not enf._hygiene_may_auto_apply("COMPOSIO_EXECUTE_TOOL", mech_ok))

        os.environ["ERNEST_CRON_JOB"] = "ernest-hubspot-hygiene"
        hy_text2 = open(os.path.join(hy_root, "ernest.yaml"), "r").read()
        hy_text2 = re.sub(r"^\s*dry_run:\s*\S+", "  dry_run: true", hy_text2, count=1, flags=re.M)
        open(os.path.join(hy_root, "ernest.yaml"), "w").write(hy_text2)
        enf._hygiene_policy_cache = None
        check("BLOCK when dry_run true",
              not enf._hygiene_may_auto_apply("COMPOSIO_EXECUTE_TOOL", mech_ok))

        hy_text3 = open(os.path.join(hy_root, "ernest.yaml"), "r").read()
        hy_text3 = re.sub(r"^\s*dry_run:\s*\S+", "  dry_run: false", hy_text3, count=1, flags=re.M)
        open(os.path.join(hy_root, "ernest.yaml"), "w").write(hy_text3)
        enf._hygiene_policy_cache = None
        bad_field = {
            "tool_slug": "HUBSPOT_UPDATE_CONTACT",
            "properties": {"dealstage": "closedwon"},
        }
        check("BLOCK non-mechanical field dealstage",
              not enf._hygiene_may_auto_apply("COMPOSIO_EXECUTE_TOOL", bad_field))

        create_args = {"tool_slug": "HUBSPOT_CREATE_CONTACT", "properties": {"email": "a@b.co"}}
        check("BLOCK HUBSPOT_CREATE even when armed",
              blocked("COMPOSIO_EXECUTE_TOOL", create_args))
    finally:
        for k, v in _hy_saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        enf._hygiene_policy_cache = None
finally:
    shutil.rmtree(_hy_tmp, ignore_errors=True)

# ── Telegram /start pre_gateway_dispatch hook ───────────────────────────────
print("pre_gateway_dispatch — /start onboarding hook:")
import types
import tempfile

_start_checks = 0


def _mock_event(text, platform="telegram"):
    return types.SimpleNamespace(
        text=text,
        source=types.SimpleNamespace(
            platform=types.SimpleNamespace(value=platform)
        ),
    )


_vault_tmp = tempfile.mkdtemp(prefix="ernest-vault-")
try:
    os.environ["OBSIDIAN_VAULT_PATH"] = _vault_tmp
    os.makedirs(os.path.join(_vault_tmp, "Ernest"), exist_ok=True)

    r = enf._start_pre_gateway_dispatch(event=_mock_event("/start"))
    _start_checks += 1
    check("/start -> rewrite kickoff when not onboarded",
          isinstance(r, dict) and r.get("action") == "rewrite" and "first contact" in r["text"].lower())

    r2 = enf._start_pre_gateway_dispatch(event=_mock_event("/start@ernest_agibot"))
    _start_checks += 1
    check("/start@bot -> rewrite kickoff",
          isinstance(r2, dict) and r2.get("action") == "rewrite")

    r3 = enf._start_pre_gateway_dispatch(event=_mock_event("hello"))
    _start_checks += 1
    check("non-/start -> no rewrite", r3 is None)

    r4 = enf._start_pre_gateway_dispatch(event=_mock_event("/start", platform="slack"))
    _start_checks += 1
    check("/start on slack -> no rewrite (telegram only)", r4 is None)

    open(os.path.join(_vault_tmp, "Ernest", ".onboarded"), "w").write("ok\n")
    r5 = enf._start_pre_gateway_dispatch(event=_mock_event("/start"))
    _start_checks += 1
    check("/start when onboarded -> welcome-back",
          isinstance(r5, dict) and r5.get("action") == "rewrite" and "already onboarded" in r5["text"].lower())
finally:
    os.environ.pop("OBSIDIAN_VAULT_PATH", None)
    shutil.rmtree(_vault_tmp, ignore_errors=True)

print()
total = (
    len(MUST_BLOCK) + len(MUST_ALLOW) + len(SCOPE_BLOCK) + len(SCOPE_ALLOW) + 2 + 2 + 5 + _start_checks
)
if failures:
    print(f"FAILED {len(failures)}/{total}:")
    for f in failures:
        print(f"   - {f}")
    sys.exit(1)
print(f"PASS — {total} adversarial checks held")
