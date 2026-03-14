#!/bin/bash
# setup-mas-certs.sh
#
# Generates Mac App Store signing certificates and exports them as a P12
# ready to paste into GitHub Secrets.
#
# Usage:
#   ./setup-mas-certs.sh
#
# What it does:
#   1. Generate a CSR (Certificate Signing Request)
#   2. Create "Mac App Distribution" cert via `asc`
#   3. Create "Mac Installer Distribution" cert via `asc`
#   4. Install both certs + the private key in your keychain
#   5. Export as P12 → print base64 for GitHub Secrets
#
# Prerequisites:
#   brew install asccli        (or asc auth login already done)
#   asc auth check             (credentials must be configured)

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

step()  { echo -e "\n${BOLD}${BLUE}▶ $*${NC}"; }
ok()    { echo -e "${GREEN}✓ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
die()   { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
pause() { echo -e "\n${YELLOW}Press Enter when done...${NC}"; read -r; }

# ── Workdir ───────────────────────────────────────────────────────────────────
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
CSR_PATH="$WORKDIR/mac-distribution.csr"
KEY_PATH="$WORKDIR/mac-distribution.key"
APP_CERT_PATH="$WORKDIR/mac-app-dist.cer"
INSTALLER_CERT_PATH="$WORKDIR/mac-installer-dist.cer"
P12_PATH="$HOME/Desktop/APPLE_MAS_CERTIFICATE.p12"

# ── Prerequisites ─────────────────────────────────────────────────────────────
step "Checking prerequisites"

command -v asc  >/dev/null 2>&1 || die "'asc' not found. Run: brew tap tddworks/tap && brew install asccli"
command -v jq   >/dev/null 2>&1 || die "'jq' not found. Run: brew install jq"
command -v openssl >/dev/null 2>&1 || die "'openssl' not found."

asc auth check >/dev/null 2>&1 || die "asc credentials not set up. Run: asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>"
ok "Prerequisites met"

# ── CSR ───────────────────────────────────────────────────────────────────────
step "Generating Certificate Signing Request (CSR)"

echo -n "Your name (for the certificate): "
read -r CERT_NAME
echo -n "Your email: "
read -r CERT_EMAIL

openssl req -nodes -newkey rsa:2048 \
  -keyout "$KEY_PATH" \
  -out "$CSR_PATH" \
  -subj "/emailAddress=${CERT_EMAIL}/CN=${CERT_NAME}/C=US" \
  2>/dev/null

ok "CSR generated at $CSR_PATH"

# ── Mac App Distribution cert (via asc) ───────────────────────────────────────
step "Creating Mac App Distribution certificate via asc"
echo "  (This is the '3rd Party Mac Developer Application' cert that signs your .app)"

CERT_RESPONSE=$(asc certificates create \
  --type MAC_APP_DISTRIBUTION \
  --csr-path "$CSR_PATH")

CERT_CONTENT=$(echo "$CERT_RESPONSE" | jq -r '.data[0].certificateContent // empty')

if [ -z "$CERT_CONTENT" ]; then
  die "Failed to create MAC_APP_DISTRIBUTION certificate. Check: asc certificates list --type MAC_APP_DISTRIBUTION"
fi

echo "$CERT_CONTENT" | base64 --decode > "$APP_CERT_PATH"
security import "$APP_CERT_PATH" -k ~/Library/Keychains/login.keychain-db 2>/dev/null || \
security import "$APP_CERT_PATH" 2>/dev/null || true
ok "Mac App Distribution cert created and installed"

# ── Mac Installer Distribution cert (via asc) ────────────────────────────────
step "Creating Mac Installer Distribution certificate via asc"
echo "  (This is the '3rd Party Mac Developer Installer' cert that signs your .pkg)"

INSTALLER_CERT_RESPONSE=$(asc certificates create \
  --type MAC_INSTALLER_DISTRIBUTION \
  --csr-path "$CSR_PATH")

INSTALLER_CERT_CONTENT=$(echo "$INSTALLER_CERT_RESPONSE" | jq -r '.data[0].certificateContent // empty')

if [ -z "$INSTALLER_CERT_CONTENT" ]; then
  die "Failed to create MAC_INSTALLER_DISTRIBUTION certificate. Check: asc certificates list --type MAC_INSTALLER_DISTRIBUTION"
fi

echo "$INSTALLER_CERT_CONTENT" | base64 --decode > "$INSTALLER_CERT_PATH"
security import "$INSTALLER_CERT_PATH" -k ~/Library/Keychains/login.keychain-db 2>/dev/null || \
security import "$INSTALLER_CERT_PATH" 2>/dev/null || true
ok "Mac Installer Distribution cert created and installed"

# ── Create P12 ────────────────────────────────────────────────────────────────
step "Creating P12 from private key + both certificates"
echo ""
echo -n "Set a P12 password (you'll need this for APPLE_MAS_CERTIFICATE_PASSWORD): "
read -rs P12_PASSWORD
echo ""

APP_CERT_PEM="$WORKDIR/mac-app-dist.pem"
INSTALLER_CERT_PEM="$WORKDIR/mac-installer-dist.pem"

# Convert DER → PEM for openssl pkcs12
openssl x509 -inform DER -in "$APP_CERT_PATH"       -out "$APP_CERT_PEM"
openssl x509 -inform DER -in "$INSTALLER_CERT_PATH" -out "$INSTALLER_CERT_PEM"

# Bundle: private key + App Distribution cert + Installer Distribution cert → P12
openssl pkcs12 -export \
  -inkey "$KEY_PATH" \
  -in "$APP_CERT_PEM" \
  -certfile "$INSTALLER_CERT_PEM" \
  -out "$P12_PATH" \
  -password "pass:$P12_PASSWORD" 2>/dev/null || \
openssl pkcs12 -legacy -export \
  -inkey "$KEY_PATH" \
  -in "$APP_CERT_PEM" \
  -certfile "$INSTALLER_CERT_PEM" \
  -out "$P12_PATH" \
  -password "pass:$P12_PASSWORD"

ok "P12 created at $P12_PATH"

# ── Output GitHub Secrets ─────────────────────────────────────────────────────
step "GitHub Secrets values"
echo ""
echo "  Add these to your repo: Settings → Secrets and variables → Actions"
echo ""
echo -e "  ${BOLD}APPLE_MAS_CERTIFICATE_P12${NC}"
echo "  ─────────────────────────────────────────────────────"
base64 -i "$P12_PATH" | tr -d '\n'
echo ""
echo ""
echo -e "  ${BOLD}APPLE_MAS_CERTIFICATE_PASSWORD${NC}"
echo "  ─────────────────────────────────────────────────────"
echo "  $P12_PASSWORD"
echo ""
ok "Done! P12 also saved to: $P12_PATH (keep it safe)"
