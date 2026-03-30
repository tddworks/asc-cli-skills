---
name: asc-appstore-release
description: |
  GitHub Actions workflow templates for uploading builds and releasing to the App Store using the `asc` CLI.
  Use this skill when:
  (1) Setting up a CI/CD pipeline that uploads a signed IPA/PKG to App Store Connect
  (2) Automating App Store submission from GitHub Actions using `asc`
  (3) Adding TestFlight distribution steps (add beta group, update "What's New")
  (4) User asks "how do I release to the App Store from CI", "create a GitHub Actions workflow for App Store submission"
  (5) Wiring `asc builds upload`, `asc versions set-build`, `asc versions submit` into a pipeline
  (6) Adding a pre-submission readiness gate using `asc versions check-readiness`
---

# App Store Release with `asc` in GitHub Actions

Two paths depending on your build setup:

**Option A: Archive from source** — `asc` handles everything (archive + export + upload)
```
Xcode project
  → asc builds next-number            # auto-resolve build number
  → asc builds archive --upload        # archive, export, upload in one step
  → asc builds add-beta-group          # optional: TestFlight distribution
  → asc builds update-beta-notes       # optional: "What's New" text
  → asc versions set-build             # link build to App Store version
  → asc versions check-readiness       # gate: verify all checks pass
  → asc versions submit                # submit for App Store review
```

**Option B: Upload pre-built IPA** — you already have a signed binary (from Xcode, Fastlane, etc.)
```
Signed IPA/PKG (from your build step)
  → asc builds next-number            # auto-resolve build number
  → asc builds upload --wait           # upload + wait for Apple processing
  → asc builds add-beta-group          # optional: TestFlight distribution
  → asc builds update-beta-notes       # optional: "What's New" text
  → asc versions set-build             # link build to App Store version
  → asc versions check-readiness       # gate: verify all checks pass
  → asc versions submit                # submit for App Store review
```

See [workflow-template.md](references/workflow-template.md) for complete copy-paste workflows.

## Mac App Store Certificate Setup

Before the first CI run, you need `APPLE_MAS_CERTIFICATE_P12` and `APPLE_MAS_CERTIFICATE_PASSWORD`.
Run the interactive setup script:

```bash
.claude/skills/asc-appstore-release/scripts/setup-mas-certs.sh
```

The script walks through the full mental model:
```
Generate CSR
  → asc certificates create MAC_APP_DISTRIBUTION  (automated)
  → Apple portal: Mac Installer Distribution cert  (one browser step)
  → Export both as P12 via Keychain Access
  → Print base64 values ready to paste into GitHub Secrets
```

## Install `asc` in GitHub Actions

```yaml
- name: Install asc CLI
  run: |
    brew tap tddworks/tap
    brew install asccli
```

Or download a specific version directly:

```yaml
- name: Install asc CLI
  run: |
    VERSION="0.1.3"
    ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/arm64/arm64/')
    curl -sL "https://github.com/tddworks/asc-cli/releases/download/v${VERSION}/asc_${VERSION}_macOS_${ARCH}" \
      -o /usr/local/bin/asc && chmod +x /usr/local/bin/asc
```

## Auth Setup

`asc` reads credentials from environment variables automatically:

```yaml
env:
  ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
  ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
  ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}   # PEM content, NOT a path
```

Required GitHub Secrets:

| Secret | Value |
|--------|-------|
| `ASC_KEY_ID` | App Store Connect API Key ID (e.g. `6X3CMK22CY`) |
| `ASC_ISSUER_ID` | Issuer ID (UUID format) |
| `ASC_PRIVATE_KEY` | Full PEM content of the `.p8` file |

To get the PEM content from your `.p8` file:
```bash
cat AuthKey_XXXXXX.p8 | pbcopy   # paste as the secret value
```

## Core Commands

### Option A: Archive from source (recommended for `asc`-only workflows)

```bash
# 1. Get the next build number
BUILD_NUMBER=$(asc builds next-number --app-id $APP_ID --version $VERSION --platform ios)

# 2. Archive, export, and upload in one command
asc builds archive \
  --scheme $SCHEME \
  --platform ios \
  --upload \
  --app-id $APP_ID \
  --version $VERSION \
  --build-number $BUILD_NUMBER

# 3. Get the processed build ID
BUILD_ID=$(asc builds list --app-id $APP_ID --version $VERSION --platform ios | jq -r '.data[0].id')
```

### Option B: Upload pre-built IPA/PKG

```bash
# 1. Get the next build number
BUILD_NUMBER=$(asc builds next-number --app-id $APP_ID --version $VERSION --platform ios)

# 2. Upload IPA (auto-detects iOS from .ipa, macOS from .pkg)
asc builds upload \
  --app-id $APP_ID \
  --file MyApp.ipa \
  --version $VERSION \
  --build-number $BUILD_NUMBER \
  --wait

# 3. Get the processed build ID
BUILD_ID=$(asc builds list --app-id $APP_ID --version $VERSION --platform ios | jq -r '.data[0].id')
```

### Common steps (after either option)

```bash
# 4. TestFlight: add to beta group
asc builds add-beta-group --build-id $BUILD_ID --beta-group-id $GROUP_ID

# 5. TestFlight: set "What's New" notes
asc builds update-beta-notes \
  --build-id $BUILD_ID \
  --locale en-US \
  --notes "Bug fixes and improvements."

# 6. App Store: link build to version
VERSION_ID=$(asc versions list --app-id $APP_ID --pretty | jq -r '.data[0].id')
asc versions set-build --version-id $VERSION_ID --build-id $BUILD_ID

# 7. App Store: gate — verify all checks pass before submitting
READINESS=$(asc versions check-readiness --version-id $VERSION_ID)
IS_READY=$(echo "$READINESS" | jq -r '.data[0].isReadyToSubmit')
if [ "$IS_READY" != "true" ]; then
  echo "Version is NOT ready to submit:"
  echo "$READINESS" | jq '.data[0] | {stateCheck, buildCheck, pricingCheck}'
  exit 1
fi

# 8. App Store: submit for review
asc versions submit --version-id $VERSION_ID
```

## Finding Your IDs

```bash
# App ID (do this once, store as a secret or env var)
asc apps list --pretty | jq -r '.data[] | "\(.name): \(.id)"'

# Beta group ID
asc testflight groups list --app-id $APP_ID --pretty | jq -r '.data[0].id'

# Current version ID (latest editable version)
asc versions list --app-id $APP_ID --pretty | jq -r '.data[0].id'
```
