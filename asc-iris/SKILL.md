---
name: asc-iris
description: |
  Use App Store Connect's private API (iris) with Apple ID cookie auth through the `asc` CLI, for what the public API can't do.
  Use this skill when:
  (1) Checking the iris session or cookie errors: "asc iris status", "am I logged in to iris", "No App Store Connect cookies found"
  (2) Listing or creating apps: "asc iris apps list", "asc iris apps create --name NAME --bundle-id ID --sku SKU", "create app", "register new app"
  (3) Reading App Review rejection messages: "asc iris resolution-center get --submission-id ID", "why was my app rejected", "resolution center"
  (4) Answering App Compliance (China mainland Security Assessment, AI generated content): "asc iris app-compliance list|declare", "Missing Info", "AIGC filing"
  (5) User mentions "iris", "private API", "cookie-based auth", or something the public API can't do
---

# asc iris — App Store Connect Private API

Access App Store Connect private API (iris) endpoints using cookie-based authentication. The iris API powers the ASC web UI and exposes capabilities not available through the public REST API, such as **app creation**.

## Authentication

Iris uses **browser cookies**, not JWT API keys. Two resolution methods:

1. **Browser auto-extraction** (default) — log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) in Chrome/Safari/Firefox. Cookies are extracted automatically via SweetCookieKit.
2. **Environment variable** — set `ASC_IRIS_COOKIES` for CI/CD:
   ```bash
   export ASC_IRIS_COOKIES="myacinfo=DAWT...; itctx=eyJ..."
   ```

The essential cookie is `myacinfo` (set on `.apple.com`). Additional cookies (`itctx`, `dqsid`, `wosid`) are collected from `appstoreconnect.apple.com`.

## How to Navigate (CAEOAS Affordances)

Every JSON response contains an `"affordances"` field with ready-to-run commands:

```json
{
  "source": "browser",
  "cookieCount": 5,
  "affordances": {
    "listApps": "asc iris apps list",
    "createApp": "asc iris apps create --name <name> --bundle-id <id> --sku <sku>"
  }
}
```

## Commands

### status — check iris session

```bash
asc iris status --pretty
```

**Output:**
```json
{
  "data": [{
    "affordances": {
      "createApp": "asc iris apps create --name <name> --bundle-id <id> --sku <sku>",
      "listApps": "asc iris apps list"
    },
    "cookieCount": 5,
    "source": "browser"
  }]
}
```

If cookies are not found, the error message will suggest logging in to appstoreconnect.apple.com or setting `ASC_IRIS_COOKIES`.

### apps list — list all apps

```bash
asc iris apps list --pretty
```

**Output:**
```json
{
  "data": [{
    "affordances": {
      "listAppInfos": "asc app-infos list --app-id 1234567890",
      "listVersions": "asc versions list --app-id 1234567890"
    },
    "bundleId": "com.example.app",
    "id": "1234567890",
    "name": "My App",
    "platforms": ["IOS"],
    "primaryLocale": "en-US",
    "sku": "MYSKU"
  }]
}
```

### apps create — create a new app

```bash
asc iris apps create \
  --name "My App" \
  --bundle-id com.example.app \
  --sku com.example.app \
  [--primary-locale en-US] \
  [--platforms IOS] \
  [--version 1.0] \
  --pretty
```

| Flag | Required | Default | Description |
|---|---|---|---|
| `--name` | ✅ | — | App name (shown on App Store) |
| `--bundle-id` | ✅ | — | Bundle identifier (must match a registered bundle ID) |
| `--sku` | ✅ | — | SKU identifier (unique within your account) |
| `--primary-locale` | ❌ | `en-US` | Primary locale |
| `--platforms` | ❌ | `IOS` | One or more: `IOS`, `MAC_OS` |
| `--version` | ❌ | `1.0` | Initial version string |

**Multi-platform example:**
```bash
asc iris apps create \
  --name "My Universal App" \
  --bundle-id com.example.universal \
  --sku com.example.universal \
  --platforms IOS MAC_OS \
  --version 2.0 \
  --pretty
```

**Important:** The `--bundle-id` must reference an already-registered bundle identifier. Register one first with `asc bundle-ids create --name NAME --identifier ID --platform ios` if needed.

### resolution-center get — read App Review's rejection message

The official API only reports *that* a submission has `UNRESOLVED_ISSUES`; the
reviewer's message text and guideline citations are iris-only. When a
submission or rejected item shows the `getResolutionDetails` affordance, run:

```bash
asc iris resolution-center get --submission-id <SUBMISSION_ID> --plain-text --pretty
asc iris resolution-center get --submission-id <SUBMISSION_ID> --out ./rc-attachments  # also download attachments
```

Returns the Resolution Center thread: `messages[]` (reviewer text, `fromActor`
APPLE/USER), `rejectionReasons[]` (guideline `section`/`code`/description),
and `attachments[]` when App Review attached files (`--out <dir>` downloads them).
Full docs: [docs/features/resolution-center/README.md](../../docs/features/resolution-center/README.md)

### app-compliance — the App Compliance page (China mainland)

Every app gets two requirements, Security Assessment and AI Generated or Synthetic
Content, each starting as `MISSING_INFO`. The list is the page's table; each row says
whether it can be declared (`declare` affordance: Missing Info, Active, Verification
Failed — never while `PENDING_VERIFICATION`).

```bash
asc iris app-compliance list --app-id <APP_ID> --output table

# No: the app doesn't offer the feature in China mainland (or it's disabled/geoblocked there)
asc iris app-compliance declare --app-id <APP_ID> --requirement-id <ID> --answer no

# Yes, Security Assessment: two files (.doc .docx .jpeg .jpg .pdf .png)
asc iris app-compliance declare --app-id <APP_ID> --requirement-id <ID> --answer yes --proof ./proof.pdf --report ./report.pdf

# Yes, AIGC: the filing, plus the agreement only when third-party technology powers it
asc iris app-compliance declare --app-id <APP_ID> --requirement-id <ID> --answer yes \
  --filing-type llm|algorithm --filing-name "<name>" --filing-number "<number>" [--third-party-authorization ./agreement.pdf]
```

A Yes goes to `PENDING_VERIFICATION` (`requiredActions: APP_BINARY_SUBMISSION`: Apple
checks it at the next submission) and is read-only until then. Only send real evidence:
Apple verifies the files and filing numbers. Missing evidence, a disallowed file type or a
pending row is refused before anything is sent.
Full docs: [docs/features/app-compliance/README.md](../../docs/features/app-compliance/README.md)

## Typical Workflow

```bash
# 1. Check if you're logged in
asc iris status --pretty

# 2. Create a new app
asc iris apps create \
  --name "My New App" \
  --bundle-id com.example.newapp \
  --sku com.example.newapp \
  --pretty

# 3. Continue with public API commands (use the app ID from step 2)
asc versions list --app-id <id>
asc app-infos list --app-id <id>
```

## Troubleshooting

**"No App Store Connect cookies found"**
- Make sure you're logged in to appstoreconnect.apple.com in your browser
- If using Chrome, the CLI needs Keychain access to decrypt cookies — grant access when prompted
- For CI/CD, set `ASC_IRIS_COOKIES` with the cookie string

**409 ENTITY_ERROR.INCLUDED.INVALID_ID**
- Placeholder IDs in the create request must use the `${local-id}` format — this is handled automatically by the CLI

**Empty results from `iris apps list`**
- This is normal if no apps have been created yet — create one with `asc iris apps create`
