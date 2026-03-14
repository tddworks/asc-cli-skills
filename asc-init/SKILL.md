---
name: asc-init
description: |
  Initialise a project's App Store Connect context using the `asc init` command.
  Use this skill when:
  (1) Saving app context to a project directory: "asc init", "pin my app ID", "set up project context"
  (2) Auto-detecting the app from an Xcode project: user says "run asc init in my project folder"
  (3) Searching by app name: "asc init --name 'My App'"
  (4) Explaining what .asc/project.json is used for
  (5) Reading saved project context to avoid running asc apps list every session
---

# asc init — Project Context Initialisation

Saves the app ID, name, and bundle ID to `.asc/project.json` in the current directory. Future commands and agents read this file instead of calling `asc apps list` every session.

## Commands

### init — pin project context

```bash
# Direct (no API list call)
asc init --app-id <id> [--pretty]

# By name (case-insensitive search)
asc init --name "My App" [--pretty]

# Auto-detect from *.xcodeproj/project.pbxproj in cwd
asc init [--pretty]
```

Priority: `--app-id` > `--name` > auto-detect.

## What Gets Saved

`./.asc/project.json`:

```json
{
  "appId":    "1234567890",
  "appName":  "My App",
  "bundleId": "com.example.myapp"
}
```

## JSON Output

```json
{
  "data": [
    {
      "affordances": {
        "checkReadiness": "asc versions check-readiness --version-id <id>",
        "listAppInfos":   "asc app-infos list --app-id 1234567890",
        "listBuilds":     "asc builds list --app-id 1234567890",
        "listVersions":   "asc versions list --app-id 1234567890"
      },
      "appId":    "1234567890",
      "appName":  "My App",
      "bundleId": "com.example.myapp"
    }
  ]
}
```

## Typical Workflow

```bash
# 1. Run once per project directory
cd /path/to/MyApp
asc init --pretty

# 2. In subsequent sessions, read the saved context
APP_ID=$(jq -r '.appId' .asc/project.json)

# 3. Use normally — no need for asc apps list
asc versions list --app-id "$APP_ID"
asc builds list   --app-id "$APP_ID"
```

## Auto-detect Logic

When no flags are given, `asc init` scans `*.xcodeproj/project.pbxproj` files in the current directory and extracts `PRODUCT_BUNDLE_IDENTIFIER` values. It then matches those bundle IDs against your App Store Connect apps.

Variable references like `$(PRODUCT_BUNDLE_IDENTIFIER)` are skipped — only literal values are matched.

## Error Cases

| Situation | Error |
|-----------|-------|
| `--name` given but no app matches | `No app named '…'. Run asc apps list to see available apps.` |
| Auto-detect: no `.xcodeproj` found | `No Xcode project found. Use --app-id or --name.` |
| Auto-detect: bundle IDs don't match any ASC app | `No ASC app matched bundle IDs: com.example.app` |

## See Also

- Full feature doc: `docs/features/init.md`
- Follow affordances from the output to list versions, builds, or app infos without knowing the app ID