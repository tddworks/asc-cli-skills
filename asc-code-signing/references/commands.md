# Code Signing Command Reference

## `asc bundle-ids`

### list
```bash
asc bundle-ids list [--platform <ios|macos|universal>] [--identifier <string>] [--pretty]
```
| Flag | Description |
|------|-------------|
| `--platform` | Filter: `ios`, `macos`, `universal` |
| `--identifier` | Filter by bundle ID string (e.g. `com.example.app`) |

**Example:**
```bash
asc bundle-ids list --platform ios --pretty
asc bundle-ids list --identifier com.example.app
```

**Output fields:** `id`, `name`, `identifier`, `platform`, `seedID?`, `affordances`

### create
```bash
asc bundle-ids create --name <name> --identifier <id> --platform <ios|macos|universal>
```
| Flag | Required | Description |
|------|----------|-------------|
| `--name` | Yes | Display name |
| `--identifier` | Yes | Bundle ID string |
| `--platform` | Yes | `ios`, `macos`, or `universal` |

### delete
```bash
asc bundle-ids delete --bundle-id-id <id>
```

---

## `asc certificates`

### list
```bash
asc certificates list [--type <TYPE>] [--pretty]
```
| Flag | Description |
|------|-------------|
| `--type` | Filter: `IOS_DISTRIBUTION`, `IOS_DEVELOPMENT`, `MAC_APP_DISTRIBUTION`, etc. |

**Output fields:** `id`, `name`, `certificateType`, `displayName?`, `serialNumber?`, `platform?`, `expirationDate?`, `certificateContent?`, `affordances`

### create
```bash
asc certificates create --type <TYPE> --csr-content <pem>
```
| Flag | Required | Description |
|------|----------|-------------|
| `--type` | Yes | Certificate type (uppercase, e.g. `IOS_DISTRIBUTION`) |
| `--csr-content` | Yes | PEM-encoded CSR string |

**Tip:** Pass CSR from file: `--csr-content "$(cat MyApp.certSigningRequest)"`

### revoke
```bash
asc certificates revoke --certificate-id <id>
```

---

## `asc devices`

### list
```bash
asc devices list [--platform <ios|macos>] [--pretty]
```

**Output fields:** `id`, `name`, `udid`, `deviceClass`, `platform`, `status`, `model?`, `addedDate?`, `affordances`

### register
```bash
asc devices register --name <name> --udid <udid> --platform <ios|macos>
```
| Flag | Required | Description |
|------|----------|-------------|
| `--name` | Yes | Device display name |
| `--udid` | Yes | Unique Device Identifier |
| `--platform` | Yes | `ios` or `macos` |

---

## `asc profiles`

### list
```bash
asc profiles list [--bundle-id-id <id>] [--type <TYPE>] [--pretty]
```
| Flag | Description |
|------|-------------|
| `--bundle-id-id` | Filter by bundle ID resource ID (server-side via `/v1/bundleIds/{id}/profiles`) |
| `--type` | Filter by profile type (e.g. `IOS_APP_STORE`) |

**Output fields:** `id`, `name`, `profileType`, `profileState`, `bundleIdId`, `expirationDate?`, `uuid?`, `profileContent?`, `affordances`

### create
```bash
asc profiles create \
  --name <name> \
  --type <TYPE> \
  --bundle-id-id <id> \
  --certificate-ids <id1,id2> \
  [--device-ids <id1,id2>]
```
| Flag | Required | Description |
|------|----------|-------------|
| `--name` | Yes | Profile name |
| `--type` | Yes | Profile type (uppercase, e.g. `IOS_APP_STORE`) |
| `--bundle-id-id` | Yes | Bundle ID resource ID |
| `--certificate-ids` | Yes | Comma-separated cert resource IDs (min 1) |
| `--device-ids` | No | Comma-separated device IDs (needed for `*_DEVELOPMENT` / `*_ADHOC` types) |

### delete
```bash
asc profiles delete --profile-id <id>
```

---

## Quick Reference

| Goal | Command |
|------|---------|
| List iOS bundle IDs | `asc bundle-ids list --platform ios` |
| Register bundle ID | `asc bundle-ids create --name "App" --identifier com.x.app --platform ios` |
| List distribution certs | `asc certificates list --type IOS_DISTRIBUTION` |
| Create cert from CSR | `asc certificates create --type IOS_DISTRIBUTION --csr-content "$(cat app.csr)"` |
| Register device | `asc devices register --name "iPhone" --udid <udid> --platform ios` |
| List profiles for bundle ID | `asc profiles list --bundle-id-id <id>` |
| Create App Store profile | `asc profiles create --name "Prod" --type IOS_APP_STORE --bundle-id-id <id> --certificate-ids <id>` |
| Delete profile | `asc profiles delete --profile-id <id>` |