---
name: asc-new-app-release
description: |
  Handle the first App Store release for a brand new app with the `asc` CLI: register a bundle ID,
  create the App Store Connect app, configure metadata/compliance/pricing, upload a build, and submit
  for review. Use this when the app does not exist yet in App Store Connect and the user asks for a
  first release, initial submission, or setup from zero. Do not use it for later releases of an
  existing app; use `asc-release-workflow` for that.
---

# First-Time App Store Release

This workflow takes a brand new app from zero to submitted on the App Store. It handles everything the regular release workflow (`asc-release-workflow`) doesn't — all the one-time setup that only happens for the very first submission.

## Before You Start

Gather this info from the user (or derive from the project):

| Info | Where to find it | Example |
|------|-------------------|---------|
| **Bundle ID** | Xcode project or `.xcconfig` | `com.mycompany.myapp` |
| **App name** | What the user wants on the App Store | `My Cool App` |
| **Platform** | iOS, macOS, or both | `ios` |
| **Category** | See [categories reference](references/categories.md) | `EDUCATION` |
| **Description** | User provides or you draft | Feature list paragraph |
| **Support URL** | GitHub repo, website, etc. | `https://github.com/...` |
| **Pricing** | Free or paid | Free |
| **SKU** | Unique string (generate if not provided) | `myapp-ios-2026` |

## Workflow Overview

```
Phase 1: Identity        → Bundle ID + App creation
Phase 2: Metadata        → Category, description, keywords, URLs
Phase 3: Compliance      → Age rating, pricing, privacy labels, review contact
Phase 4: Build           → Archive, upload, link to version
Phase 5: Readiness       → Check all requirements, fix gaps
Phase 6: Submit          → Submit for App Review
```

---

## Phase 1: Identity

### Step 1.1: Register Bundle ID

Check if the bundle ID already exists:
```bash
asc bundle-ids list
```

If not found, register it:
```bash
asc bundle-ids create \
  --name "<APP_NAME>" \
  --identifier "<BUNDLE_ID>" \
  --platform IOS   # or UNIVERSAL for iOS + macOS
```

### Step 1.2: Create App on App Store Connect

Use the iris API (private API via web session) since it creates app + version + localizations in one call:
```bash
asc iris apps create \
  --name "<APP_NAME>" \
  --bundle-id "<BUNDLE_ID>" \
  --sku "<SKU>"
```

Save the returned **App ID** — you'll need it for every subsequent command.

If the name is taken (409 error with `DUPLICATE.DIFFERENT_ACCOUNT`), ask the user for an alternative. Common fixes: add "App", "Studio", "AI", or a distinguishing word.

If iris isn't available (no web session), fall back to the REST API:
```bash
# This requires the bundle ID to already be registered
asc apps create \
  --name "<APP_NAME>" \
  --bundle-id-id "<BUNDLE_ID_RESOURCE_ID>" \
  --sku "<SKU>" \
  --primary-locale "en-US"
```

### Step 1.3: Verify App and Get IDs

```bash
# Get app info ID (needed for categories, localizations)
asc app-infos list --app-id <APP_ID>
# Save: APP_INFO_ID

# Get version ID (needed for screenshots, build linking)
asc versions list --app-id <APP_ID>
# Save: VERSION_ID (the one in PREPARE_FOR_SUBMISSION state)

# Get version localization ID (needed for description, keywords)
asc version-localizations list --version-id <VERSION_ID>
# Save: LOCALIZATION_ID
```

---

## Phase 2: Metadata

### Step 2.1: Set Category

Ask the user what category fits best. See [categories reference](references/categories.md) for the full list.

```bash
asc app-infos update \
  --app-info-id <APP_INFO_ID> \
  --primary-category <CATEGORY>
```

Common categories: `EDUCATION`, `DEVELOPER_TOOLS`, `PRODUCTIVITY`, `UTILITIES`, `BUSINESS`, `ENTERTAINMENT`, `PHOTO_AND_VIDEO`.

### Step 2.2: Set Version Metadata

Write the description, keywords, and URLs:

```bash
asc version-localizations update \
  --localization-id <LOCALIZATION_ID> \
  --description "<DESCRIPTION>" \
  --keywords "<COMMA_SEPARATED_KEYWORDS>" \
  --support-url "<SUPPORT_URL>" \
  --marketing-url "<MARKETING_URL>"
```

**Description tips:**
- First line is the hook — make it compelling
- List 5-7 key features with bullet points (use `•`)
- Keep under 4000 characters
- No pricing info, no competitor names

**Keywords tips:**
- Max 100 characters total, comma-separated
- Don't repeat the app name (it's already indexed)
- Use singular forms ("photo" not "photos")
- 8-12 keywords is a good target

**Note:** Don't set `--whats-new` for the first version — Apple doesn't allow it. That field is for updates only.

### Step 2.3: Set App-Level Metadata (optional)

Subtitle and privacy policy URL are set on the app info localization (not the version):

```bash
# List app info localizations
asc app-info-localizations list --app-info-id <APP_INFO_ID>
# Save: APP_INFO_LOC_ID

# Update subtitle and privacy URL
asc app-info-localizations update \
  --localization-id <APP_INFO_LOC_ID> \
  --subtitle "<SHORT_SUBTITLE>" \
  --privacy-policy-url "<PRIVACY_POLICY_URL>"
```

---

## Phase 3: Compliance

### Step 3.1: Age Rating

A new app has no saved questionnaire (App Store Connect shows "Set Up Age Ratings"). Apple refuses the first `update` unless it answers **every** question at once, naming each missing one in a 409 `ENTITY_ERROR.ATTRIBUTE.REQUIRED`. The answers are a declaration about the app's content: ask the user, or copy them from a sibling app they point to (`asc age-rating get` on that app).

```bash
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')
asc age-rating get --app-info-id "$APP_INFO_ID"   # its "id" is the declaration ID

# First save — an app with none of this content (4+):
asc age-rating update --declaration-id <DECLARATION_ID> \
  --advertising false --age-assurance false --dating-and-relationships false --gambling false \
  --health-or-wellness-topics false --loot-box false --messaging-and-chat false --parental-controls false \
  --shared-location false --social-media false --unrestricted-web-access false --user-generated-content false \
  --alcohol-tobacco-drugs NONE --contests NONE --gambling-simulated NONE --guns-weapons NONE \
  --horror-fear NONE --mature-suggestive NONE --medical-treatment NONE --profanity NONE \
  --sexual-content-graphic NONE --sexual-content NONE --violence-cartoon NONE --violence-realistic NONE \
  --violence-realistic-prolonged NONE
```

- Booleans take `true`/`false`; intensities take `NONE`, `INFREQUENT_OR_MILD`, `FREQUENT_OR_INTENSE`.
- `--social-media true` also needs `--social-media-age-restricted <bool>`.
- After the first save, `update` is a partial PATCH: pass only what changes.
- To force a rating: `--age-rating-override NINE_PLUS|THIRTEEN_PLUS|SIXTEEN_PLUS|EIGHTEEN_PLUS|UNRATED`.
- `asc versions check-readiness` reports any question still unanswered.

### Step 3.2: Pricing, availability and content rights

A submission is refused until the app has a price, and a new app isn't sold anywhere until its availability is set up. Ask the user the price (Free is the usual choice when the app earns through in-app purchases or subscriptions) and where to sell it (usually everywhere).

```bash
# Price: pick a point in the base territory; Apple equalizes the rest. customerPrice 0.0 = Free.
FREE=$(asc apps price-points list --app-id <APP_ID> | jq -r '.data[] | select(.customerPrice == "0.0") | .id')
asc apps prices set --app-id <APP_ID> --base-territory USA --price-point-id "$FREE"

# Availability (App Store Connect's "Set Up Availability")
asc app-availability create --app-id <APP_ID> --all-territories --available-in-new-territories

# Content rights — a legal declaration, so ask the user which is true
asc apps update --app-id <APP_ID> --content-rights-declaration DOES_NOT_USE_THIRD_PARTY_CONTENT   # or USES_THIRD_PARTY_CONTENT
```

Before release every territory reports `CANNOT_SELL` + `AVAILABLE_FOR_SALE_UNRELEASED_APP`; that's expected.

### Step 3.3: Review Contact Info

```bash
asc version-review-detail update \
  --version-id <VERSION_ID> \
  --contact-email "<EMAIL>" \
  --contact-phone "<PHONE>"
```

Ask the user for their contact email and phone number. This is required for App Review to reach them if there are questions.

### Step 3.4: Privacy Nutrition Labels

App Privacy answers have **no public App Store Connect API**; `asc iris app-privacy` sets them through the web session (see [asc-iris](../asc-iris/SKILL.md)). Until they're published, the submission is refused with "You must have published answers to your app's data usages."

```bash
asc iris app-privacy get --app-id $APP_ID          # blocksSubmission: true until published
```

If the app collects no user data (confirm with the user):

```bash
asc iris app-privacy declare --app-id $APP_ID --not-collected
asc iris app-privacy publish --app-id $APP_ID
```

If the app does collect data, walk through each data type with the user, write them to a `privacy.json` (`{"collectedData": [...]}`), then `declare --file privacy.json` and `publish`. See the [Apple privacy documentation](https://developer.apple.com/app-store/app-privacy-details/) for what each category means.

---

## Phase 4: Build

### Step 4.1: Archive and Upload

```bash
# Get the next build number
BUILD_NUMBER=$(asc builds next-number \
  --app-id <APP_ID> \
  --version <VERSION_STRING> \
  --platform <PLATFORM>)

# Archive + upload in one step
asc builds archive \
  --scheme <SCHEME> \
  --platform <PLATFORM> \
  --signing-style automatic \
  --team-id <TEAM_ID> \
  --upload \
  --app-id <APP_ID> \
  --version <VERSION_STRING> \
  --build-number "$BUILD_NUMBER"
```

If the user already has an IPA/PKG:
```bash
asc builds upload \
  --app-id <APP_ID> \
  --file <PATH_TO_IPA> \
  --version <VERSION_STRING> \
  --build-number "$BUILD_NUMBER" \
  --wait
```

### Step 4.2: Wait for Processing

```bash
asc builds uploads get --upload-id <UPLOAD_ID>
```

Poll until `state` is `COMPLETE`. Common failures:
- **Missing icon** → Fix the asset catalog
- **Missing entitlements** → macOS needs App Sandbox
- **CFBundleVersion mismatch** → Build number in binary must match

### Step 4.3: Link Build to Version

```bash
# Find the build (match by build number)
asc builds list --app-id <APP_ID>

# Link to the version
asc versions set-build \
  --version-id <VERSION_ID> \
  --build-id <BUILD_ID>
```

---

## Phase 5: Readiness Check

```bash
asc versions check-readiness --version-id <VERSION_ID>
```

Review the output carefully. For a first-time app, common missing items:

| Check | Likely Status | How to Fix |
|-------|---------------|-----------|
| `stateCheck` | Pass | Should be PREPARE_FOR_SUBMISSION |
| `buildCheck` | Fail if not uploaded yet | Upload and link a build (Phase 4) |
| `pricingCheck` | Fail | `asc apps prices set` (Step 3.2) |
| `reviewContactCheck` | Fail | `asc version-review-detail update` (Step 3.3) |
| `localizationCheck` | Fail if screenshots missing | Upload screenshots |
| `screenshotSetCount: 0` | Fail | Need at least one screenshot set per device |

### Screenshots

Screenshots are required for the first submission. If the user has a screenshot skill or automation:
```bash
# Create screenshot set for a device
asc screenshot-sets create \
  --localization-id <LOCALIZATION_ID> \
  --display-type APP_IPHONE_67

# Upload screenshot
asc screenshots create \
  --screenshot-set-id <SET_ID> \
  --file <PATH_TO_SCREENSHOT>
```

Required display types depend on the platform. At minimum for iOS:
- `APP_IPHONE_67` (6.7" — iPhone Pro Max)
- `APP_IPHONE_61` (6.1" — iPhone Pro) — may be generated from 6.7"

For macOS: `APP_DESKTOP`

---

## Phase 6: Submit

Once `isReadyToSubmit` is true:

A new app's in-app purchases and subscriptions are first-time products, so they must go to review with this version. Preview, confirm with the user, then submit:

```bash
asc versions submit --version-id <VERSION_ID> --with-products --dry-run --output table
asc versions submit --version-id <VERSION_ID> --with-products
```

Check the dry run lists every product the user expects — ones still `MISSING_METADATA` are left out. If Apple refuses, the error lists each reason (missing device screenshots, content rights, App Privacy answers, pricing); see [submit-with-products.md](../shared/submit-with-products.md).

Tell the user: "Your app has been submitted for review! Apple typically reviews within 24-48 hours. You'll receive an email when it's approved (or if there are issues to address)."

---

## Quick Reference: Full Command Sequence

For a free iOS app with no data collection:

```bash
# 1. Register bundle ID
asc bundle-ids create --name "My App" --identifier "com.me.myapp" --platform IOS

# 2. Create app
asc iris apps create --name "My App" --bundle-id "com.me.myapp" --sku "myapp-2026"
# → APP_ID

# 3. Get IDs
asc app-infos list --app-id $APP_ID           # → APP_INFO_ID
asc versions list --app-id $APP_ID             # → VERSION_ID
asc version-localizations list --version-id $VERSION_ID  # → LOC_ID

# 4. Category
asc app-infos update --app-info-id $APP_INFO_ID --primary-category EDUCATION

# 5. Description + keywords
asc version-localizations update --localization-id $LOC_ID \
  --description "..." --keywords "..." --support-url "..." --marketing-url "..."

# 5b. Price (free), availability, content rights, App Privacy
FREE=$(asc apps price-points list --app-id $APP_ID | jq -r '.data[] | select(.customerPrice == "0.0") | .id')
asc apps prices set --app-id $APP_ID --base-territory USA --price-point-id "$FREE"
asc app-availability create --app-id $APP_ID --all-territories --available-in-new-territories
asc apps update --app-id $APP_ID --content-rights-declaration DOES_NOT_USE_THIRD_PARTY_CONTENT
asc iris app-privacy declare --app-id $APP_ID --not-collected   # only if the user confirms it collects nothing
asc iris app-privacy publish --app-id $APP_ID

# 6. Review contact
asc version-review-detail update --version-id $VERSION_ID \
  --contact-email "dev@me.com" --contact-phone "+1-555-0100"

# 7. Archive + upload
BUILD=$(asc builds next-number --app-id $APP_ID --version 1.0 --platform IOS)
asc builds archive --scheme MyApp --platform ios --signing-style automatic \
  --team-id XXXXXXXXXX --upload --app-id $APP_ID --version 1.0 --build-number $BUILD

# 8. Link build
asc versions set-build --version-id $VERSION_ID --build-id $BUILD_ID

# 9. Check readiness
asc versions check-readiness --version-id $VERSION_ID

# 10. Submit, with any in-app purchases and subscriptions (first-time products)
asc versions submit --version-id $VERSION_ID --with-products --dry-run
asc versions submit --version-id $VERSION_ID --with-products
```
