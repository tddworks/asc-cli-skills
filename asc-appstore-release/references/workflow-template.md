# GitHub Actions Workflow Templates

## Minimal: Upload + Submit

The simplest App Store release pipeline. Drop this into `.github/workflows/appstore-release.yml`.

```yaml
name: App Store Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version string (e.g. 1.2.0)'
        required: true
      build_number:
        description: 'Build number (e.g. 42)'
        required: true

env:
  APP_ID: ${{ vars.APP_ID }}   # set as a repo variable, not a secret

jobs:
  release:
    runs-on: macos-15

    steps:
      - uses: actions/checkout@v4

      # ── Your existing build step ──────────────────────────────────────────
      # Replace this with your actual build (Xcode, Fastlane, etc.)
      # It must produce a signed IPA/PKG at $GITHUB_WORKSPACE/MyApp.ipa
      - name: Build signed IPA
        run: echo "Your build step here — produces MyApp.ipa"
      # ─────────────────────────────────────────────────────────────────────

      - name: Install asc CLI
        run: brew tap tddworks/tap && brew install asccli

      - name: Upload to App Store Connect
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          asc builds upload \
            --app-id "$APP_ID" \
            --file MyApp.ipa \
            --version "${{ inputs.version }}" \
            --build-number "${{ inputs.build_number }}" \
            --wait

      - name: Get Build ID
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          BUILD_ID=$(asc builds list --app-id "$APP_ID" | jq -r '.data[0].id')
          echo "BUILD_ID=$BUILD_ID" >> $GITHUB_ENV

      - name: Link Build to Version
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          VERSION_ID=$(asc versions list --app-id "$APP_ID" | jq -r '.data[0].id')
          asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"
          echo "VERSION_ID=$VERSION_ID" >> $GITHUB_ENV

      - name: Check Submission Readiness
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          READINESS=$(asc versions check-readiness --version-id "$VERSION_ID")
          IS_READY=$(echo "$READINESS" | jq -r '.data[0].isReadyToSubmit')
          if [ "$IS_READY" != "true" ]; then
            echo "Version is NOT ready to submit:"
            echo "$READINESS" | jq '.data[0] | {stateCheck, buildCheck, pricingCheck}'
            exit 1
          fi

      - name: Submit for App Store Review
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          asc versions submit --version-id "$VERSION_ID"
```

---

## Full: TestFlight First, Then App Store

Upload → beta test → then promote to App Store review.

```yaml
name: App Store Release (with TestFlight)

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version string (e.g. 1.2.0)'
        required: true
      build_number:
        description: 'Build number'
        required: true
      whats_new:
        description: '"What''s New" notes for TestFlight'
        required: false
        default: 'Bug fixes and improvements.'
      submit_for_review:
        description: 'Submit to App Store after TestFlight?'
        type: boolean
        default: false

env:
  APP_ID: ${{ vars.APP_ID }}
  BETA_GROUP_ID: ${{ vars.BETA_GROUP_ID }}

jobs:
  release:
    runs-on: macos-15

    steps:
      - uses: actions/checkout@v4

      # Your build step here — produces MyApp.ipa
      - name: Build signed IPA
        run: echo "Your build step here"

      - name: Install asc CLI
        run: brew tap tddworks/tap && brew install asccli

      - name: Upload to App Store Connect
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          asc builds upload \
            --app-id "$APP_ID" \
            --file MyApp.ipa \
            --version "${{ inputs.version }}" \
            --build-number "${{ inputs.build_number }}" \
            --wait

      - name: Get Build ID
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          BUILD_ID=$(asc builds list --app-id "$APP_ID" | jq -r '.data[0].id')
          echo "BUILD_ID=$BUILD_ID" >> $GITHUB_ENV

      - name: Distribute to TestFlight
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          asc builds add-beta-group \
            --build-id "$BUILD_ID" \
            --beta-group-id "$BETA_GROUP_ID"

          asc builds update-beta-notes \
            --build-id "$BUILD_ID" \
            --locale en-US \
            --notes "${{ inputs.whats_new }}"

      - name: Submit for App Store Review
        if: ${{ inputs.submit_for_review }}
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
        run: |
          VERSION_ID=$(asc versions list --app-id "$APP_ID" | jq -r '.data[0].id')
          asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"

          READINESS=$(asc versions check-readiness --version-id "$VERSION_ID")
          IS_READY=$(echo "$READINESS" | jq -r '.data[0].isReadyToSubmit')
          if [ "$IS_READY" != "true" ]; then
            echo "Version is NOT ready to submit:"
            echo "$READINESS" | jq '.data[0] | {stateCheck, buildCheck, pricingCheck}'
            exit 1
          fi

          asc versions submit --version-id "$VERSION_ID"
```

---

## Required Secrets & Variables

Set in **GitHub repo → Settings → Secrets and variables → Actions**

### Secrets (sensitive)

| Secret | How to get it |
|--------|--------------|
| `ASC_KEY_ID` | App Store Connect → Users & Access → Keys → Key ID |
| `ASC_ISSUER_ID` | Same page → Issuer ID (UUID at the top) |
| `ASC_PRIVATE_KEY` | Content of `AuthKey_XXXX.p8` (open in text editor, copy all) |

### Variables (non-sensitive, visible in logs)

| Variable | How to get it |
|----------|--------------|
| `APP_ID` | `asc apps list` → the numeric ID column |
| `BETA_GROUP_ID` | `asc testflight groups list --app-id $APP_ID` → first group ID |
