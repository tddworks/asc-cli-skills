---
name: asc-xcode-cloud
description: |
  Manage Xcode Cloud CI/CD using the `asc` CLI tool.
  Use this skill whenever the user mentions anything related to Xcode Cloud or CI builds, including:
  - "trigger a build", "start a CI build", "kick off a pipeline", "run CI"
  - "check build status", "did my build pass", "my build failed", "CI is broken"
  - "list workflows", "list products", "show me my builds"
  - "xcode cloud", "CI build", "build run", "pipeline", "check if my PR triggered a build"
  - Any `asc xcode-cloud` command usage
---

# Xcode Cloud with `asc`

Manage Xcode Cloud products, workflows, and build runs through the App Store Connect API.

## Authentication

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## How to Navigate (CAEOAS Affordances)

Every JSON response contains an `"affordances"` field with ready-to-run commands — IDs already filled in. This means you never need to remember or copy-paste IDs manually: just run the command from the affordance of the previous response.

For example, after listing products, the response tells you exactly what to run next:

```json
{
  "id": "prod-abc123",
  "name": "My App",
  "affordances": {
    "listWorkflows": "asc xcode-cloud workflows list --product-id prod-abc123"
  }
}
```

And after listing workflows, the `startBuild` affordance appears — but **only when the workflow is enabled**. If `startBuild` is missing, the workflow is disabled (`isEnabled: false`) and cannot be triggered.

```json
{
  "id": "wf-xyz",
  "name": "CI Build",
  "isEnabled": true,
  "affordances": {
    "startBuild": "asc xcode-cloud builds start --workflow-id wf-xyz",
    "listBuildRuns": "asc xcode-cloud builds list --workflow-id wf-xyz"
  }
}
```

## Typical Workflows

### Trigger a build (step by step)

```bash
# 1. Find the Xcode Cloud product for your app
asc xcode-cloud products list --app-id 6443417124 --pretty

# 2. Copy the listWorkflows affordance from the response and run it
asc xcode-cloud workflows list --product-id prod-abc123 --pretty

# 3. Copy the startBuild affordance from the workflow you want and run it
asc xcode-cloud builds start --workflow-id wf-xyz --pretty
```

Or as a script:

```bash
PRODUCT_ID=$(asc xcode-cloud products list --app-id APP_ID | jq -r '.data[0].id')
WORKFLOW_ID=$(asc xcode-cloud workflows list --product-id "$PRODUCT_ID" \
  | jq -r '.data[] | select(.name == "CI Build") | .id')
asc xcode-cloud builds start --workflow-id "$WORKFLOW_ID"
```

### Check build status

```bash
asc xcode-cloud builds get --build-run-id run-99 --pretty
```

Look at `executionProgress` first: if it's `COMPLETE`, check `completionStatus` to see if it passed or failed.

### See recent builds at a glance

```bash
asc xcode-cloud builds list --workflow-id wf-xyz --output table
```

### Clean build (clears derived data)

```bash
asc xcode-cloud builds start --workflow-id wf-xyz --clean
```

## Reading Build Results

**`executionProgress`** — where is the build now?

| Value | Meaning |
|---|---|
| `PENDING` | Queued, not started yet |
| `RUNNING` | Actively building |
| `COMPLETE` | Done — check `completionStatus` |

**`completionStatus`** — did it succeed? (only set when `COMPLETE`)

| Value | Meaning | `hasFailed` |
|---|---|---|
| `SUCCEEDED` | All actions passed | false |
| `FAILED` | One or more actions failed | **true** |
| `ERRORED` | Infrastructure/system error | **true** |
| `CANCELED` | Manually cancelled | false |
| `SKIPPED` | Build was skipped | false |

## Full Command Reference

See [commands.md](references/commands.md) for all flags and examples.