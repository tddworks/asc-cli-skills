---
name: asc-cli
description: |
  Use the `asc` CLI tool (App Store Connect CLI) to manage iOS/macOS apps on App Store Connect.
  Use this skill when:
  (1) User wants to manage App Store Connect resources from terminal or CI
  (2) User is migrating from fastlane, Xcode GUI, or manual App Store Connect workflows
  (3) User asks about submitting, uploading, TestFlight, metadata, screenshots, IAPs, subscriptions, code signing, or any ASC operation
  (4) User says "submit my app", "list my apps", "upload screenshots", "check builds", "update app name", "create IAP", "add subscription", "migrate from fastlane", etc.
  (5) Setting up authentication or managing multiple App Store Connect accounts
  (6) Building CI/CD pipelines for App Store releases
---

# asc CLI — App Store Command Center

A CLI for App Store Connect — automate builds, releases, TestFlight, subscriptions, and screenshots from your terminal or CI pipeline.

## Install & Authenticate

```bash
brew install tddworks/tap/asccli

asc auth login \
  --key-id YOUR_KEY_ID \
  --issuer-id YOUR_ISSUER_ID \
  --private-key-path ~/.asc/AuthKey_XXXXXX.p8

asc auth check
```

Get your API key from https://appstoreconnect.apple.com/access/integrations/api

## Discover Commands

```bash
asc --help                        # list all top-level commands
asc <command> --help              # list subcommands and flags
asc <command> <subcommand> --help # detailed usage for a specific action
```

Examples:
```bash
asc versions --help               # see: list, create, submit, set-build, check-readiness
asc builds --help                 # see: list, upload, archive, add-beta-group, ...
asc testflight --help             # see: groups, testers
asc iap --help                    # see: list, create, submit, price-points, prices
```

## Follow the Affordances

Every JSON response includes an `affordances` field with ready-to-run next commands. Always use these instead of constructing commands manually — they are state-aware.

```json
{
  "id": "6748760927",
  "name": "My App",
  "affordances": {
    "listVersions": "asc versions list --app-id 6748760927"
  }
}
```

## Output Formats

```bash
asc apps list                    # compact JSON (default)
asc apps list --pretty           # pretty-printed JSON
asc apps list --output table     # human-readable table
```
