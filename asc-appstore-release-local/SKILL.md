---
name: asc-release-workflow
description: |
  Release an app version to the App Store using `asc` CLI. Guides the agent through: bump version, archive, upload, update metadata, and submit.
  Use this skill when:
  (1) User says "release", "ship", "submit to App Store", "publish new version"
  (2) User says "bump version and upload"
  (3) User says "prepare release for iOS/macOS"
  (4) User says "update What's New and submit"
---

# App Release Workflow

## How it works

The project keeps a release config at `.asc/release.yml`. Read it first to get platform schemes, version file paths, and locale list.

## Workflow Steps

### Step 1: Determine what to release

Ask the user (if not clear):
- **Which platform?** (ios / macos / both)
- **New version number?** (or just bump build number for same version)
- **What's New text?** (in primary locale — you'll translate for others)

### Step 2: Bump version

Read the release config to find `version_file` and `version_pattern` for the target platform. Also bump `build_number_file`.

1. Read the version file, find the current version using the regex pattern
2. Replace with the new version string
3. Read the build number file, increment the build number
4. If multiple platforms share the same build number file, both get bumped

**Important:** Also update `CFBundleVersion` and `CURRENT_PROJECT_VERSION` if they are separate from the build number pattern. Check `Shared.swift` and `TargetExtensions.swift`.

### Step 3: Regenerate project (if needed)

Run any commands listed in `pre_archive` (e.g., `tuist generate`).

### Step 4: Archive, export, upload

```bash
# Get the next build number automatically
BUILD_NUMBER=$(asc builds next-number --app-id <APP_ID> --version <VERSION> --platform <PLATFORM>)

asc builds archive \
  --scheme <SCHEME> \
  --platform <PLATFORM> \
  --signing-style automatic \
  --team-id <TEAM_ID> \
  --upload \
  --app-id <APP_ID> \
  --version <VERSION> \
  --build-number "$BUILD_NUMBER"
```

### Step 5: Wait for build processing

Poll until complete:
```bash
asc builds uploads get --upload-id <UPLOAD_ID>
```

Check the `state` field. If `FAILED`, read the `errors` array and report to the user. Common failures:
- Missing icon → fix asset catalog
- Missing entitlements → add sandbox entitlement for macOS
- CFBundleVersion mismatch → ensure build number matches

### Step 6: Link build to version

```bash
# Find the version in PREPARE_FOR_SUBMISSION state for the platform
asc versions list --app-id <APP_ID>
# Filter for the target platform + PREPARE_FOR_SUBMISSION state

# Find the build
asc builds list --app-id <APP_ID>
# Match by build number

# Link them
asc versions set-build --version-id <VERSION_ID> --build-id <BUILD_ID>
```

### Step 7: Update What's New (skip for first version v1.0.0)

For each locale in the config:
```bash
asc version-localizations list --version-id <VERSION_ID>
# Get localization IDs for each locale

asc version-localizations update \
  --localization-id <LOC_ID> \
  --whats-new "<TRANSLATED_TEXT>"
```

Generate What's New text:
- Use the user-provided text as the en-US version
- Translate to each locale maintaining the same tone and formatting
- Keep it concise (2-4 sentences max)

### Step 8: Check readiness

```bash
asc versions check-readiness --version-id <VERSION_ID>
```

Report the result to the user. If `isReadyToSubmit` is true, ask if they want to submit. If not, list what's missing (screenshots, description, etc).

### Step 9: Submit (if user confirms)

```bash
asc versions submit --version-id <VERSION_ID>
```

## First-time platform setup (one-time only)

If this is the first release for a platform (e.g., adding macOS to an existing iOS app), additional setup is needed BEFORE the regular workflow:

1. **Provisioning profile** — Check if one exists, create if not:
   ```bash
   asc bundle-ids list --identifier <BUNDLE_ID>
   asc certificates list --type MAC_APP_DISTRIBUTION  # or IOS_DISTRIBUTION
   asc profiles list --bundle-id-id <BID_ID>
   asc profiles create --name "Mac App Store: <BUNDLE_ID>" --type MAC_APP_STORE --bundle-id-id <BID_ID> --certificate-ids <CERT_ID>
   ```

2. **Entitlements** — macOS requires App Sandbox. Check for `.entitlements` file.

3. **App icon** — Verify the platform's asset catalog has icons assigned.

4. **Description** — Copy from existing platform if available, adapt for the new platform.

5. **Create version** — If no PREPARE_FOR_SUBMISSION version exists:
   ```bash
   asc versions create --app-id <APP_ID> --platform MAC_OS --version-string 1.0.0
   ```