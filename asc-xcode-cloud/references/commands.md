# asc xcode-cloud — Full Command Reference

## asc xcode-cloud products list

List Xcode Cloud products. Each app enrolled in Xcode Cloud has one product.

```bash
asc xcode-cloud products list [--app-id <APP_ID>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--app-id` | String | *(optional)* | Filter by App Store Connect app ID |
| `--output` | String | `json` | `json` \| `table` \| `markdown` |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Name · Type

**Example:**
```bash
asc xcode-cloud products list --pretty
asc xcode-cloud products list --app-id 1234567890 --output table
```

---

## asc xcode-cloud workflows list

List CI workflows defined for an Xcode Cloud product.

```bash
asc xcode-cloud workflows list --product-id <PRODUCT_ID> [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--product-id` | String | *(required)* | Xcode Cloud product ID |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Name · Enabled · Locked

**Example:**
```bash
asc xcode-cloud workflows list --product-id prod-abc --pretty
```

**Affordances:**
- `listBuildRuns` — always present
- `listWorkflows` — always present
- `startBuild` — **only when `isEnabled` is `true`**

---

## asc xcode-cloud builds list

List build runs for a workflow, sorted by most recent first.

```bash
asc xcode-cloud builds list --workflow-id <WORKFLOW_ID> [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--workflow-id` | String | *(required)* | Workflow ID |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Number · Progress · Status

**Example:**
```bash
asc xcode-cloud builds list --workflow-id wf-xyz --output table
```

---

## asc xcode-cloud builds get

Get a specific build run by ID.

```bash
asc xcode-cloud builds get --build-run-id <BUILD_RUN_ID> [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--build-run-id` | String | *(required)* | Build run ID |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Example:**
```bash
asc xcode-cloud builds get --build-run-id run-42 --pretty
```

**Tip:** Get the ID from the `getBuildRun` affordance in `asc xcode-cloud builds list` output.

---

## asc xcode-cloud builds start

Start a new build run for a workflow.

```bash
asc xcode-cloud builds start --workflow-id <WORKFLOW_ID> [--clean] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--workflow-id` | String | *(required)* | Workflow ID to start a build for |
| `--clean` | Bool flag | `false` | Perform a clean build (removes derived data before building) |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Output:** JSON with the new `XcodeCloudBuildRun` in `PENDING` state.

**Example:**
```bash
# Standard build
asc xcode-cloud builds start --workflow-id wf-xyz

# Clean build (removes derived data)
asc xcode-cloud builds start --workflow-id wf-xyz --clean --pretty
```

**Tip:** Get `--workflow-id` from the `startBuild` affordance in `asc xcode-cloud workflows list` output. This affordance only appears on enabled workflows.

---

## Execution Progress

| Value | Description | Semantic |
|---|---|---|
| `PENDING` | Queued, not started | `isPending == true` |
| `RUNNING` | Actively building | `isRunning == true` |
| `COMPLETE` | Finished (check `completionStatus`) | `isComplete == true` |

## Completion Status

| Value | Description | Semantic |
|---|---|---|
| `SUCCEEDED` | All actions passed | `isSucceeded == true` |
| `FAILED` | One or more actions failed | `hasFailed == true` |
| `ERRORED` | Infrastructure error | `hasFailed == true` |
| `CANCELED` | Manually cancelled | — |
| `SKIPPED` | Build was skipped | — |

## Start Reason

| Value | Trigger |
|---|---|
| `GIT_REF_CHANGE` | Branch or tag push |
| `MANUAL` | Manually started via API or Xcode |
| `MANUAL_REBUILD` | Re-run of an existing build |
| `PULL_REQUEST_OPEN` | PR opened |
| `PULL_REQUEST_UPDATE` | PR updated |
| `SCHEDULE` | Scheduled trigger |