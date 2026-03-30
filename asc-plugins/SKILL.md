---
name: asc-plugins
description: |
  Manage ASC plugins that extend the CLI with custom event handlers using the `asc` CLI tool.
  Use this skill when:
  (1) Listing installed plugins: "asc plugins list"
  (2) Installing a plugin: "asc plugins install PATH"
  (3) Removing a plugin: "asc plugins uninstall --name NAME"
  (4) Enabling or disabling plugins: "asc plugins enable/disable --name NAME"
  (5) Testing a plugin manually: "asc plugins run --name NAME --event EVENT"
  (6) User asks to "create a plugin", "add Slack notifications", "wire up a Telegram bot on build upload", or "extend the CLI with a custom handler"
  (7) Explaining the plugin protocol (manifest.json + run executable + JSON stdin/stdout)
---

# asc plugins

Install executable plugins in `~/.asc/plugins/<name>/` to handle ASC lifecycle events — send Slack messages, post to Telegram, trigger webhooks, or run any custom automation when builds upload or versions submit.

## Commands

### list — show all installed plugins

```bash
asc plugins list [--pretty]
```

### install — install from a local directory

```bash
asc plugins install <path>   # directory must contain manifest.json + run executable
```

### uninstall

```bash
asc plugins uninstall --name <name>
```

### enable / disable

```bash
asc plugins enable  --name <name>
asc plugins disable --name <name>   # leaves plugin installed, just suppressed
```

### run — manually test a plugin

```bash
asc plugins run --name <name> --event <event> \
  [--app-id <id>] [--version-id <id>] [--build-id <id>]
```

Events: `build.uploaded` · `version.submitted` · `version.approved` · `version.rejected`

## Plugin Protocol

A plugin is any directory with:

| File | Purpose |
|------|---------|
| `manifest.json` | Name, version, description, subscribed events |
| `run` | Executable (any language, `chmod +x`) |

**stdin → plugin:**
```json
{
  "event": "build.uploaded",
  "payload": {
    "event": "build.uploaded",
    "appId": "123456789",
    "buildId": "upload-42",
    "timestamp": "2026-03-01T12:00:00Z",
    "metadata": {}
  }
}
```

**plugin → stdout:**
```json
{"success": true, "message": "Slack notification sent"}
```

Exit code 0 = success. Non-zero = logged to stderr, other plugins continue unaffected.

## manifest.json

```json
{
  "name": "slack-notify",
  "version": "1.0.0",
  "description": "Send Slack notifications for App Store events",
  "author": "Your Name",
  "events": ["build.uploaded", "version.submitted"]
}
```

## Typical Workflow — Create & Install a Slack Plugin

```bash
# 1. Create plugin directory
mkdir ~/slack-notify
cat > ~/slack-notify/manifest.json <<'EOF'
{
  "name": "slack-notify",
  "version": "1.0.0",
  "description": "Slack notifications",
  "events": ["build.uploaded", "version.submitted"]
}
EOF

cat > ~/slack-notify/run <<'EOF'
#!/bin/bash
INPUT=$(cat)
EVENT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['event'])")
curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-type: application/json' \
  --data "{\"text\":\":rocket: ASC event: $EVENT\"}" > /dev/null
echo '{"success": true, "message": "Sent to Slack"}'
EOF
chmod +x ~/slack-notify/run

# 2. Install
asc plugins install ~/slack-notify

# 3. Test (dry-run before uploading a real build)
asc plugins run --name slack-notify --event build.uploaded \
  --app-id 123456789 --build-id test-build --pretty

# 4. Get next build number and upload — plugin fires automatically
BUILD_NUMBER=$(asc builds next-number --app-id 123456789 --version 1.0.0 --platform ios)
asc builds upload --app-id 123456789 --file MyApp.ipa --version 1.0.0 --build-number $BUILD_NUMBER

# 5. Manage
asc plugins list
asc plugins disable --name slack-notify
asc plugins enable  --name slack-notify
asc plugins uninstall --name slack-notify
```

## Auto-fired Events

| Command | Event emitted |
|---------|--------------|
| `asc builds upload` (success) | `build.uploaded` — includes `appId`, `buildId` |
| `asc versions submit` (success) | `version.submitted` — includes `appId`, `versionId` |

Individual plugin failures are logged to stderr and never block other plugins or the primary command output.

## JSON Output

```json
{
  "data": [
    {
      "affordances": {
        "disable":               "asc plugins disable --name slack-notify",
        "listPlugins":           "asc plugins list",
        "run.build.uploaded":    "asc plugins run --name slack-notify --event build.uploaded",
        "run.version.submitted": "asc plugins run --name slack-notify --event version.submitted",
        "uninstall":             "asc plugins uninstall --name slack-notify"
      },
      "author": "Your Name",
      "description": "Send Slack notifications for App Store events",
      "executablePath": "~/.asc/plugins/slack-notify/run",
      "id": "slack-notify",
      "isEnabled": true,
      "name": "slack-notify",
      "subscribedEvents": ["build.uploaded", "version.submitted"],
      "version": "1.0.0"
    }
  ]
}
```

Disabled plugins show `"enable"` affordance instead of `"disable"`.

## Plugin Storage

```
~/.asc/plugins/
└── slack-notify/
    ├── manifest.json
    ├── run              ← executable (chmod +x)
    └── .disabled        ← optional: present = disabled
```

## See Also

- Full feature doc: `docs/features/plugins.md`
- CAEOAS: follow `affordances.listPlugins` from any `asc plugins list` response