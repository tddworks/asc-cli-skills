---
name: asc-builds-upload
description: |
  Upload IPA/PKG builds to App Store Connect and manage the full build distribution workflow.
  Use this skill when:
  (1) Uploading a build: "asc builds upload --app-id ... --file MyApp.ipa ..."
  (2) Checking or listing build upload records: "asc builds uploads list/get/delete"
  (3) Linking a build to an App Store version before submission: "asc versions set-build"
  (4) Adding or removing a beta group from a build for TestFlight distribution
  (5) Setting TestFlight "What's New" notes: "asc builds update-beta-notes"
  (6) Setting Apple's export-compliance answer (ITSAppUsesNonExemptEncryption): "asc builds set-encryption-compliance"
  (7) User says "upload my build", "distribute to TestFlight", "set what's new", "link build to version", "missing compliance", "encryption compliance", "ITSAppUsesNonExemptEncryption"
---

# asc Builds Upload

Upload and distribute builds via App Store Connect. See [workflow.md](references/workflow.md) for the full end-to-end flow and error handling.

## Commands

### Upload a build

```bash
asc builds upload \
  --app-id <APP_ID> \
  --file MyApp.ipa \
  --version 1.0.0 \
  --build-number 42 \
  [--platform ios|macos|tvos|visionos]  # auto-detected from extension
  [--wait]                               # poll until processing completes
```

Platform is auto-detected: `.pkg` → `macos`, everything else → `ios`.

### Poll status

```bash
asc builds uploads get --upload-id <UPLOAD_ID>
asc builds uploads list --app-id <APP_ID>
asc builds uploads delete --upload-id <UPLOAD_ID>
```

### TestFlight distribution

```bash
# Add build to a beta group
asc builds add-beta-group --build-id <BUILD_ID> --beta-group-id <GROUP_ID>

# Remove build from a beta group
asc builds remove-beta-group --build-id <BUILD_ID> --beta-group-id <GROUP_ID>

# Set "What's New" notes (creates or updates the localization)
asc builds update-beta-notes \
  --build-id <BUILD_ID> \
  --locale en-US \
  --notes "Bug fixes and improvements."
```

### Export-compliance answer (`ITSAppUsesNonExemptEncryption`)

When an IPA is uploaded **without** `ITSAppUsesNonExemptEncryption` in `Info.plist`, ASC marks the build "Missing Compliance" and TestFlight external testing is blocked. Set the answer post-upload:

```bash
asc builds set-encryption-compliance --build-id <BUILD_ID> --uses-non-exempt-encryption true|false
```

- `false` — exempt (most apps that only use HTTPS/TLS, Apple's default crypto, etc.).
- `true` — uses non-exempt encryption — you'll also need an `AppEncryptionDeclaration` (currently only manageable via App Store Connect web UI).

Builds in the missing-compliance state advertise the affordance:

```json
{
  "id": "build-1",
  "affordances": {
    "setEncryptionCompliance": "asc builds set-encryption-compliance --build-id build-1 --uses-non-exempt-encryption <true|false>"
  }
}
```

The affordance is suppressed once the answer is supplied (Build's `usesNonExemptEncryption` becomes non-nil).

### Link build to version

```bash
asc versions set-build --version-id <VERSION_ID> --build-id <BUILD_ID>
```

Required before submitting a version for App Store review.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')
# If empty: ask user or run `asc apps list | jq -r '.data[0].id'`

# 1. Get the next build number automatically
BUILD_NUMBER=$(asc builds next-number --app-id "$APP_ID" --version 1.2.0 --platform ios)

# 2. Upload and wait
asc builds upload --app-id "$APP_ID" --file MyApp.ipa \
  --version 1.2.0 --build-number "$BUILD_NUMBER" --wait

# 3. Get the processed build ID
BUILD_ID=$(asc builds list --app-id $APP_ID | jq -r '.data[0].id')

# 4. Distribute to beta group
asc builds add-beta-group --build-id $BUILD_ID --beta-group-id $GROUP_ID

# 5. Set notes
asc builds update-beta-notes --build-id $BUILD_ID --locale en-US --notes "..."

# 5b. Answer export compliance if Info.plist didn't carry ITSAppUsesNonExemptEncryption
asc builds set-encryption-compliance --build-id $BUILD_ID --uses-non-exempt-encryption false

# 6. Link to version and submit
asc versions set-build --version-id $VERSION_ID --build-id $BUILD_ID
asc versions submit --version-id $VERSION_ID
```

## CAEOAS Affordances

Upload responses include `affordances` with ready-to-run follow-up commands:

```json
{
  "data": [{
    "affordances": {
      "checkStatus": "asc builds uploads get --upload-id abc123",
      "listBuilds": "asc builds list --app-id 123456789"
    },
    "state": "COMPLETE"
  }]
}
```

`listBuilds` only appears when `state == "COMPLETE"`. Use affordances to navigate without memorizing IDs.

## Reference

See [workflow.md](references/workflow.md) for:
- Full 5-step upload API flow internals
- Build upload states and polling logic
- Error scenarios and troubleshooting
