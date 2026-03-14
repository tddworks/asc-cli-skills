---
name: asc-performance
description: |
  Manage power and performance metrics and diagnostic logs using the `asc` CLI tool.
  Use this skill when:
  (1) Listing performance metrics for an app: "asc perf-metrics list --app-id <id>"
  (2) Listing performance metrics for a build: "asc perf-metrics list --build-id <id>"
  (3) Filtering metrics by type: "asc perf-metrics list --app-id <id> --metric-type LAUNCH"
  (4) Listing diagnostic signatures for a build: "asc diagnostics list --build-id <id>"
  (5) Filtering diagnostics: "asc diagnostics list --build-id <id> --diagnostic-type HANGS"
  (6) Viewing diagnostic logs: "asc diagnostic-logs list --signature-id <id>"
  Also trigger when the user mentions: performance metrics, launch time, hang rate, disk writes,
  memory usage, battery life, termination, animation hitches, diagnostic signatures, call stacks,
  power metrics, app performance monitoring, "why is my app slow", "check hangs", "check launch time"
---

# Power & Performance with `asc`

Download performance metrics and diagnostic logs to monitor app performance indicators — launch time, hang rate, disk writes, memory use, battery life, termination, and animation hitches.

## Authentication

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## How to Navigate (CAEOAS Affordances)

Every JSON response contains an `"affordances"` field with ready-to-run commands — IDs already filled in. Follow the affordances to drill down from metrics to diagnostics to logs.

**App metrics → Diagnostics → Logs flow:**

```json
// 1. asc perf-metrics list --app-id app-1 → shows performance overview
{
  "id": "app-1-LAUNCH-launchTime",
  "category": "LAUNCH",
  "latestValue": 1.5,
  "affordances": {
    "listAppMetrics": "asc perf-metrics list --app-id app-1"
  }
}

// 2. asc diagnostics list --build-id build-1 → shows hotspots
{
  "id": "sig-1",
  "diagnosticType": "HANGS",
  "weight": 45.2,
  "affordances": {
    "listLogs": "asc diagnostic-logs list --signature-id sig-1",
    "listSignatures": "asc diagnostics list --build-id build-1"
  }
}

// 3. asc diagnostic-logs list --signature-id sig-1 → shows call stacks
{
  "id": "sig-1-0-0",
  "bundleId": "com.example.app",
  "callStackSummary": "main > UIKit > layoutSubviews",
  "affordances": {
    "listLogs": "asc diagnostic-logs list --signature-id sig-1"
  }
}
```

## Typical Workflows

### Check app performance at a glance

```bash
asc perf-metrics list --app-id 123456789 --pretty
```

### Investigate a specific metric type

```bash
# Launch time only
asc perf-metrics list --app-id 123456789 --metric-type LAUNCH --pretty

# Hang rate only
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty
```

### Compare build-specific metrics

```bash
asc builds list --app-id 123456789 --output table
asc perf-metrics list --build-id build-abc --pretty
```

### Diagnose hangs in a build

```bash
# 1. List diagnostic signatures (hang hotspots)
asc diagnostics list --build-id build-abc --diagnostic-type HANGS --pretty

# 2. Drill into the top signature's call stacks
asc diagnostic-logs list --signature-id sig-1 --pretty
```

### Full investigation pipeline

```bash
# Start from builds
BUILD_ID=$(asc builds list --app-id APP_ID | jq -r '.data[0].id')

# Check performance metrics
asc perf-metrics list --build-id "$BUILD_ID" --pretty

# Find hang hotspots
asc diagnostics list --build-id "$BUILD_ID" --diagnostic-type HANGS --pretty

# Get call stacks for the heaviest signature
SIG_ID=$(asc diagnostics list --build-id "$BUILD_ID" --diagnostic-type HANGS \
  | jq -r '.data | sort_by(-.weight) | .[0].id')
asc diagnostic-logs list --signature-id "$SIG_ID" --pretty
```

## Performance Metric Categories

| Category | `--metric-type` value | What it measures |
|----------|----------------------|------------------|
| Launch | `LAUNCH` | App launch time |
| Hang | `HANG` | Main thread hang rate |
| Memory | `MEMORY` | Peak and average memory use |
| Disk | `DISK` | Disk write volume |
| Battery | `BATTERY` | Energy impact |
| Termination | `TERMINATION` | Background/foreground terminations |
| Animation | `ANIMATION` | Animation hitch rate |

## Diagnostic Types

| Type | `--diagnostic-type` value | What it captures |
|------|--------------------------|------------------|
| Hangs | `HANGS` | Main thread hang signatures |
| Disk Writes | `DISK_WRITES` | Excessive disk write signatures |
| Launches | `LAUNCHES` | Slow launch signatures |

## Reading Results

**PerformanceMetric** — one row per metric identifier (e.g. `launchTime`, `peakMemory`), flattened from the nested Xcode Metrics API. Key fields:
- `category` — which metric group (LAUNCH, HANG, etc.)
- `latestValue` + `unit` — most recent measurement
- `goalValue` — Apple's recommended target
- `parentType` — `"app"` or `"build"` (tells you whether this came from app-level or build-level metrics)

**DiagnosticSignatureInfo** — a recurring issue pattern ranked by `weight` (% of occurrences). Higher weight = more impactful. `insightDirection` of `"UP"` means the issue is getting worse.

**DiagnosticLogEntry** — individual log with device metadata and `callStackSummary` (top 5 frames joined with ` > `).

## Full Command Reference

See [commands.md](references/commands.md) for all flags and examples.
