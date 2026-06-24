# Ernest - one-line setup for Windows (PowerShell). Fully automated, cold start.
#
#   irm https://raw.githubusercontent.com/romaluev/ernest/main/setup.ps1 | iex
#
# Installs Hermes if missing, installs the Ernest profile, connects a model
# (one browser login), then opens onboarding. No prompts, no files to edit.
#
# Zero-touch provisioning: pre-seed env vars and nothing is asked -
#   $env:ERNEST_COMPOSIO_API_KEY = '...'; $env:ERNEST_VAULT = 'C:\ErnestVault'

$ErrorActionPreference = 'Stop'
# Note: do NOT name this $Profile — that collides with PowerShell's automatic $PROFILE.
$Repo        = if ($env:ERNEST_REPO) { $env:ERNEST_REPO } else { 'github.com/romaluev/ernest' }
$ProfileName = 'ernest'

function Bold($m) { Write-Host "`n$m" -ForegroundColor White }
function Dim($m)  { Write-Host $m -ForegroundColor DarkGray }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is required. Install it from https://git-scm.com/download/win and re-run."
  exit 1
}

# 1 - Hermes runtime
if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
  Bold "Installing Hermes (one time)..."
  try {
    irm https://hermes-agent.nousresearch.com/install.ps1 | iex
    $env:PATH = "$HOME\.local\bin;$env:PATH"
  } catch {
    Write-Error "Native Hermes install failed. On Windows the most reliable path is WSL: run 'wsl --install', open Ubuntu, then run the bash one-liner from the README."
    exit 1
  }
}
if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
  Write-Error "Hermes is not on PATH. Open a new terminal and re-run, or use WSL."
  exit 1
}

# 2 - Ernest profile (--force refreshes in place; .env / memories preserved)
Bold "Installing Ernest..."
hermes profile install $Repo --name $ProfileName --alias --yes --force
if ($LASTEXITCODE -ne 0) { Write-Error "Profile install failed - check network/git access to $Repo and re-run."; exit 1 }

# 3 - Memory + optional pre-seeded keys (no prompts)
$HermesHome = if ($env:HERMES_HOME) { $env:HERMES_HOME } else { "$HOME\.hermes" }
$EnvFile = Join-Path $HermesHome "profiles\$ProfileName\.env"
New-Item -ItemType Directory -Force -Path (Split-Path $EnvFile) | Out-Null
if (-not (Test-Path $EnvFile)) { New-Item -ItemType File -Force -Path $EnvFile | Out-Null }
function Put($k, $v) {
  if ($v -and -not (Select-String -Path $EnvFile -Pattern "^$k=" -Quiet)) {
    Add-Content -Path $EnvFile -Value "$k=$v"
  }
}
$Vault = if ($env:ERNEST_VAULT) { $env:ERNEST_VAULT } else { "$HOME\ErnestVault" }
New-Item -ItemType Directory -Force -Path $Vault | Out-Null
Put 'OBSIDIAN_VAULT_PATH' $Vault
Put 'COMPOSIO_API_KEY' $env:ERNEST_COMPOSIO_API_KEY

# 4 - Model (one browser login) + 5 - onboarding
Bold "Connect a model  (browser login - Codex, Anthropic, or Nous Portal)"
hermes -p $ProfileName model
Bold "Starting Ernest..."
hermes -p $ProfileName chat -s ernest-bootstrap
