---
name: asc-code-signing
description: |
  Manage App Store Connect code signing resources using the `asc` CLI tool.
  Use this skill when:
  (1) Managing bundle identifiers — register, list, or delete (`asc bundle-ids`)
  (2) Managing signing certificates — create from CSR, list, or revoke (`asc certificates`)
  (3) Registering or listing test devices (`asc devices`)
  (4) Managing provisioning profiles — create, list, or delete (`asc profiles`)
  (5) Setting up the full code signing chain for CI/CD pipelines
  (6) User says "set up signing", "create a profile", "register my device", "revoke cert",
      "list certificates", "create bundle id", or any code-signing related task
---

# Code Signing with `asc`

Manage the full Apple code signing chain: bundle IDs → certificates → devices → profiles.

## Authentication

Set up credentials before any code signing commands:
```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## CAEOAS — Affordances Guide Next Steps

Every JSON response includes `"affordances"` with ready-to-run commands:

```json
{
  "id": "bid-1",
  "identifier": "com.example.app",
  "affordances": {
    "listProfiles": "asc profiles list --bundle-id-id bid-1",
    "delete": "asc bundle-ids delete --bundle-id-id bid-1"
  }
}
```

Copy affordance commands directly — no need to look up IDs.

## Typical CI/CD Signing Setup

```bash
# 1. Register bundle identifier
asc bundle-ids create \
  --name "My App" \
  --identifier "com.example.myapp" \
  --platform ios

# 2. Create distribution certificate from a CSR
asc certificates create \
  --type IOS_DISTRIBUTION \
  --csr-content "$(cat MyApp.certSigningRequest)"

# 3. Register test devices (development profiles only)
asc devices register --name "My iPhone" --udid "<udid>" --platform ios

# 4. Grab resource IDs
asc bundle-ids list --identifier com.example.myapp   # note the id
asc certificates list --type IOS_DISTRIBUTION        # note the id

# 5. Create provisioning profile
asc profiles create \
  --name "My App Store Profile" \
  --type IOS_APP_STORE \
  --bundle-id-id <bid-id> \
  --certificate-ids <cert-id>

# 6. Verify
asc profiles list --bundle-id-id <bid-id> --pretty
```

## Key Types

**Profile types:** `IOS_APP_STORE` · `IOS_APP_DEVELOPMENT` · `IOS_APP_ADHOC` · `MAC_APP_STORE` · `MAC_APP_DEVELOPMENT` · `MAC_APP_DIRECT`

**Certificate types:** `IOS_DISTRIBUTION` · `IOS_DEVELOPMENT` · `MAC_APP_DISTRIBUTION` · `MAC_APP_DEVELOPMENT` · `DEVELOPER_ID_APPLICATION`

**Platforms (CLI argument):** `ios` · `macos` · `universal`

## Output Flags

```bash
--pretty          # Pretty-print JSON
--output table    # Table format
--output markdown # Markdown table
```

## Full Command Reference

See [commands.md](references/commands.md) for all flags, filters, and examples for each command.