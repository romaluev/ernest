#!/usr/bin/env bash
# Deploy Ernest from your Mac. CEO uses Telegram (Slack optional via Composio).
#
# Easiest (any VPS provider, no API):
#   VPS_IP=... VPS_PASSWORD=... in secrets + bash scripts/deploy-ernest.sh --secrets ~/ernest.secrets.env
#
# Auto-create VPS:
#   DIGITALOCEAN_TOKEN=...  (often faster signup than Hetzner)
#   or HETZNER_API_TOKEN=...

set -euo pipefail

SECRETS=""
HOST=""
PASSWORD=""
SSH_KEY="${ERNEST_SSH_KEY:-$HOME/.ernest-deploy/id_ed25519}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secrets) SECRETS="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --ssh-key) SSH_KEY="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

command -v ssh >/dev/null || { echo "ERROR: ssh not found" >&2; exit 1; }
command -v scp >/dev/null || { echo "ERROR: scp not found" >&2; exit 1; }

[[ -f "$SECRETS" ]] || { echo "ERROR: copy scripts/ernest.secrets.env.example → ~/ernest.secrets.env" >&2; exit 1; }
# shellcheck disable=SC1090
set -a; source "$SECRETS"; set +a

need() { [[ -n "${!1:-}" ]] || { echo "ERROR: $1 missing in secrets" >&2; exit 1; }; }
need ANTHROPIC_API_KEY
need COMPOSIO_API_KEY TELEGRAM_BOT_TOKEN TELEGRAM_ALLOWED_USERS

HOST="${HOST:-${VPS_IP:-}}"
PASSWORD="${PASSWORD:-${VPS_PASSWORD:-}}"

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=20)
[[ -f "$SSH_KEY" ]] && SSH_OPTS+=(-i "$SSH_KEY")

ensure_sshpass() {
  command -v sshpass >/dev/null && return 0
  if command -v brew >/dev/null 2>&1; then
    echo "→ Installing sshpass (one time)…"
    brew install hudochenkov/sshpass/sshpass 2>/dev/null || brew install esolitos/ipa/sshpass 2>/dev/null || true
  fi
  command -v sshpass >/dev/null || {
    echo "ERROR: need sshpass for password login. Run: brew install hudochenkov/sshpass/sshpass" >&2
    exit 1
  }
}

ssh_run() {
  if [[ -n "$PASSWORD" ]]; then
    ensure_sshpass
    SSHPASS="$PASSWORD" sshpass -e ssh "${SSH_OPTS[@]}" "root@$HOST" "$@"
  else
    ssh "${SSH_OPTS[@]}" "root@$HOST" "$@"
  fi
}

scp_run() {
  local src="$1" dst="$2"
  if [[ -n "$PASSWORD" ]]; then
    ensure_sshpass
    SSHPASS="$PASSWORD" sshpass -e scp "${SSH_OPTS[@]}" "$src" "$dst"
  else
    scp "${SSH_OPTS[@]}" "$src" "$dst"
  fi
}

mkdir -p "$(dirname "$SSH_KEY")"
[[ -f "$SSH_KEY" ]] || ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "ernest-deploy" >/dev/null
PUBKEY="$(cat "${SSH_KEY}.pub")"

wait_ssh() {
  echo "→ $HOST — waiting for SSH…"
  for _ in $(seq 1 72); do
    ssh_run true 2>/dev/null && return 0
    sleep 5
  done
  echo "ERROR: cannot SSH to $HOST" >&2
  exit 1
}

create_digitalocean() {
  need DIGITALOCEAN_TOKEN
  echo "→ Creating DigitalOcean droplet…"
  KEY_ID="$(curl -fsS -X POST \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"ernest-deploy-$(date +%s)\",\"public_key\":\"${PUBKEY}\"}" \
    https://api.digitalocean.com/v2/account/keys \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['ssh_key']['id'])")"

  DROPLET="$(curl -fsS -X POST \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"ernest-ceo\",\"region\":\"fra1\",\"size\":\"s-2vcpu-4gb\",\"image\":\"ubuntu-24-04-x64\",\"ssh_keys\":[$KEY_ID],\"tags\":[\"ernest\"]}" \
    https://api.digitalocean.com/v2/droplets)"
  DROPLET_ID="$(echo "$DROPLET" | python3 -c "import sys,json; print(json.load(sys.stdin)['droplet']['id'])")"

  for _ in $(seq 1 60); do
    HOST="$(curl -fsS -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
      "https://api.digitalocean.com/v2/droplets/$DROPLET_ID" \
      | python3 -c "import sys,json; d=json.load(sys.stdin)['droplet']; print(next((n['ip_address'] for n in d['networks']['v4'] if n['type']=='public'),''))")"
    [[ -n "$HOST" ]] && break
    sleep 5
  done
  [[ -n "$HOST" ]] || { echo "ERROR: droplet has no IP yet" >&2; exit 1; }
}

create_hetzner() {
  need HETZNER_API_TOKEN
  echo "→ Creating Hetzner VPS…"
  hc() { curl -fsS -H "Authorization: Bearer $HETZNER_API_TOKEN" -H "Content-Type: application/json" "$@"; }
  SSH_KEY_ID="$(hc -d "{\"name\":\"ernest-$(date +%s)\",\"public_key\":\"${PUBKEY}\"}" \
    https://api.hetzner.cloud/v1/ssh_keys | python3 -c "import sys,json; print(json.load(sys.stdin)['ssh_key']['id'])")"
  HOST="$(hc -d "{\"name\":\"ernest-ceo\",\"server_type\":\"cpx21\",\"image\":\"ubuntu-24.04\",\"location\":\"fsn1\",\"ssh_keys\":[$SSH_KEY_ID],\"start_after_create\":true}" \
    https://api.hetzner.cloud/v1/servers | python3 -c "import sys,json; print(json.load(sys.stdin)['server']['public_net']['ipv4']['ip'])")"
}

if [[ -z "$HOST" ]]; then
  if [[ -n "${DIGITALOCEAN_TOKEN:-}" ]]; then
    create_digitalocean
  elif [[ -n "${HETZNER_API_TOKEN:-}" ]]; then
    create_hetzner
  else
    echo "ERROR: set VPS_IP+VPS_PASSWORD in secrets, or DIGITALOCEAN_TOKEN, or --host" >&2
    exit 1
  fi
  wait_ssh
elif [[ -n "$PASSWORD" ]]; then
  wait_ssh
else
  wait_ssh
fi

echo "→ Uploading + installing (10–15 min)…"
tar czf - -C "$REPO_ROOT" . | ssh_run 'mkdir -p /opt/ernest && tar xzf - -C /opt/ernest'
scp_run "$SECRETS" "root@$HOST:/root/ernest.secrets.env"
ssh_run 'chmod 600 /root/ernest.secrets.env && bash /opt/ernest/scripts/vps-production-bootstrap.sh --secrets /root/ernest.secrets.env --local-repo /opt/ernest'

echo ""
echo "ГОТОВО. VPS: $HOST"
echo "CEO: Telegram → DM @YourErnestBot → «Hi Ernest»"
