---
name: asc-iris
description: |
  Manage App Store Connect private API (iris) with cookie-based authentication using the `asc` CLI tool.
  Use this skill when:
  (1) Checking iris session status: "asc iris status", "am I logged in to iris", "check iris cookies"
  (2) Listing apps via iris private API: "asc iris apps list", "list my apps with iris"
  (3) Creating a new app: "asc iris apps create --name NAME --bundle-id ID --sku SKU", "create app", "register new app", "add app to App Store Connect"
  (4) User mentions "iris", "private API", "cookie-based auth", "create app", "register app", "new app on App Store Connect"
  (5) User wants to do something that the public API cannot do (e.g. app creation)
  (6) Troubleshooting iris cookie errors or "No App Store Connect cookies found" messages
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

**Important:** The `--bundle-id` must reference an already-registered bundle identifier. Register one first with `asc bundle-ids register` if needed.

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
