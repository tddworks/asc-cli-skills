# asc performance — Full Command Reference

## asc perf-metrics list

List performance metrics for an app (aggregated across versions) or a specific build.

```bash
asc perf-metrics list --app-id <APP_ID> [--metric-type <TYPE>] [--pretty] [--output <FORMAT>]
asc perf-metrics list --build-id <BUILD_ID> [--metric-type <TYPE>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--app-id` | String | *(one required)* | App ID — get app-level aggregated metrics |
| `--build-id` | String | *(one required)* | Build ID — get build-specific metrics |
| `--metric-type` | String | *(optional)* | Filter: `HANG`, `LAUNCH`, `MEMORY`, `DISK`, `BATTERY`, `TERMINATION`, `ANIMATION` |
| `--output` | String | `json` | `json` \| `table` \| `markdown` |
| `--pretty` | Bool | `false` | Pretty-print JSON |

Either `--app-id` or `--build-id` is required (mutually exclusive).

**Table output columns:** ID · Category · Metric · Value · Unit · Goal

**Example:**
```bash
# App-level metrics
asc perf-metrics list --app-id 123456789 --pretty

# Build-specific launch metrics
asc perf-metrics list --build-id build-abc --metric-type LAUNCH --pretty

# Table view
asc perf-metrics list --app-id 123456789 --output table
```

**Affordances:**
- When `parentType == "app"`: `listAppMetrics` → `asc perf-metrics list --app-id {parentId}`
- When `parentType == "build"`: `listBuildMetrics` → `asc perf-metrics list --build-id {parentId}`

---

## asc diagnostics list

List diagnostic signatures for a build. Signatures represent recurring issues ranked by weight (percentage of occurrences).

```bash
asc diagnostics list --build-id <BUILD_ID> [--diagnostic-type <TYPE>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--build-id` | String | *(required)* | Build ID |
| `--diagnostic-type` | String | *(optional)* | Filter: `DISK_WRITES`, `HANGS`, `LAUNCHES` |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Type · Signature · Weight · Trend

**Example:**
```bash
# All diagnostics
asc diagnostics list --build-id build-abc --pretty

# Hangs only
asc diagnostics list --build-id build-abc --diagnostic-type HANGS --pretty

# Table view
asc diagnostics list --build-id build-abc --output table
```

**Affordances:**
- `listLogs` → `asc diagnostic-logs list --signature-id {id}` — always present
- `listSignatures` → `asc diagnostics list --build-id {buildId}` — always present

---

## asc diagnostic-logs list

List diagnostic logs (call stacks and device metadata) for a specific signature.

```bash
asc diagnostic-logs list --signature-id <SIGNATURE_ID> [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--signature-id` | String | *(required)* | Diagnostic signature ID |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Bundle ID · Version · OS · Device · Event

**Example:**
```bash
asc diagnostic-logs list --signature-id sig-1 --pretty
```

**Tip:** Get `--signature-id` from the `listLogs` affordance in `asc diagnostics list` output.

**Affordances:**
- `listLogs` → `asc diagnostic-logs list --signature-id {signatureId}` — always present

---

## Domain Models

### PerformanceMetric

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Synthetic: `{parentId}-{category}-{metricIdentifier}` |
| `parentId` | String | App ID or Build ID (injected by infrastructure) |
| `parentType` | String | `"app"` or `"build"` |
| `platform` | String? | e.g. `"IOS"` |
| `category` | String | `HANG`, `LAUNCH`, `MEMORY`, `DISK`, `BATTERY`, `TERMINATION`, `ANIMATION` |
| `metricIdentifier` | String | e.g. `"launchTime"`, `"peakMemory"` |
| `unit` | String? | e.g. `"s"`, `"MB"` |
| `latestValue` | Double? | Most recent data point |
| `latestVersion` | String? | App version of latest point |
| `goalValue` | Double? | Apple's recommended goal |

### DiagnosticSignatureInfo

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Signature ID from API |
| `buildId` | String | Parent build ID (injected) |
| `diagnosticType` | String | `DISK_WRITES`, `HANGS`, `LAUNCHES` |
| `signature` | String | Human-readable description |
| `weight` | Double | Percentage of occurrences (0-100) |
| `insightDirection` | String? | `"UP"` (worsening), `"DOWN"` (improving), `"UNDEFINED"` |

### DiagnosticLogEntry

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Synthetic: `{signatureId}-{productIndex}-{logIndex}` |
| `signatureId` | String | Parent signature ID (injected) |
| `bundleId` | String? | App bundle identifier |
| `appVersion` | String? | App version |
| `buildVersion` | String? | Build number |
| `osVersion` | String? | OS version |
| `deviceType` | String? | Device model identifier |
| `event` | String? | Event type |
| `callStackSummary` | String? | Top 5 frames joined with ` > ` |

---

## API Endpoints

| Endpoint | Repository Method |
|----------|-------------------|
| `GET /v1/apps/{id}/perfPowerMetrics` | `PerfMetricsRepository.listAppMetrics(appId:metricType:)` |
| `GET /v1/builds/{id}/perfPowerMetrics` | `PerfMetricsRepository.listBuildMetrics(buildId:metricType:)` |
| `GET /v1/builds/{id}/diagnosticSignatures` | `DiagnosticsRepository.listSignatures(buildId:diagnosticType:)` |
| `GET /v1/diagnosticSignatures/{id}/logs` | `DiagnosticsRepository.listLogs(signatureId:)` |
