#!/usr/bin/env bash
# Structural verification for the Ernest distribution. No mock data, no network.
set -euo pipefail

ERNEST_ROOT="${ERNEST_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

required=(
  "README.md"
  "distribution.yaml"
  "SOUL.md"
  "config.yaml"
  "ernest.yaml"
  "cron/jobs.json"
  "scripts/install-skills.sh"
  "skills/_meta/ernest-bootstrap/SKILL.md"
  "skills/_meta/library-index/SKILL.md"
  "skills/_meta/use-case-author/SKILL.md"
  "plugins/ernest-enforcement/__init__.py"
  "plugins/ernest-enforcement/guard.py"
  "memory/company-core.md"
  "memory/ceo-persona.md"
  "memory/north-star.md"
  "memory/standing-concerns.md"
  "skills/_meta/ernest-watch/SKILL.md"
  "skills/playbooks/hubspot-hygiene/SKILL.md"
)
for f in "${required[@]}"; do
  [[ -f "$ERNEST_ROOT/$f" ]] || { echo "missing: $f" >&2; exit 1; }
done

python3 - "$ERNEST_ROOT" <<'PY'
import json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])

cfg = (root / "config.yaml").read_text()
for needle in ["composio", "obsidian", "curator:", "ernest-enforcement", "delegation:"]:
    if needle not in cfg:
        raise SystemExit(f"config.yaml missing: {needle}")

dist = (root / "distribution.yaml").read_text()
for needle in ["COMPOSIO_API_KEY", "OBSIDIAN_VAULT_PATH"]:
    if needle not in dist:
        raise SystemExit(f"distribution.yaml missing env requirement: {needle}")

jobs = json.loads((root / "cron" / "jobs.json").read_text())["jobs"]
if len(jobs) < 4:
    raise SystemExit("expected >=4 cron jobs")
for j in jobs:
    if "[SILENT]" not in j["prompt"] and j["id"] not in (
        "ernest-self-improve",
    ):
        raise SystemExit(f"ambient job should be quiet-by-default: {j['id']}")

# No mock/seed/garbage left behind
for bad in ["seed", "connectors", "skills/operating"]:
    if (root / bad).exists():
        raise SystemExit(f"leftover mock artifact: {bad}")

# Enforcement gate still loads and blocks send
import importlib.util
p = root / "plugins" / "ernest-enforcement" / "__init__.py"
spec = importlib.util.spec_from_file_location("ernest_plugin", p)
plugin = importlib.util.module_from_spec(spec); spec.loader.exec_module(plugin)
if plugin._draft_only_block("outlook_send_email") is None:
    raise SystemExit("draft-only gate must block outlook_send_email")
if plugin._draft_only_block("outlook_create_draft") is not None:
    raise SystemExit("draft-only gate must allow draft creation")

skills = list((root / "skills").glob("**/SKILL.md"))
print(f"verified: {len(skills)} Ernest skills, {len(jobs)} cron jobs, gate OK")
PY

echo "OK"
