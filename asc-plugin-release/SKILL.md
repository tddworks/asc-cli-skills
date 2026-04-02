---
name: asc-plugin-release
description: |
  Publish an ASC CLI plugin to the tddworks/asc-registry marketplace.
  Use this skill when:
  (1) User says "release plugin", "publish plugin", "upload plugin to registry"
  (2) User wants to make their plugin available via `asc plugins market list`
  (3) User built a .plugin bundle and wants to share it
  (4) User asks to update an existing plugin version in the registry
  Triggers on any mention of publishing, releasing, or submitting plugins to the asc-registry.
---

# Release Plugin to ASC Registry

Publish a `.plugin` bundle to the [tddworks/asc-registry](https://github.com/tddworks/asc-registry) so users can install it with `asc plugins install --name <id>`.

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- Write access to `tddworks/asc-registry` (or fork + PR workflow)
- Plugin has a `manifest.json` with at least `name`, `version`, `server`
- Plugin builds via `make build` or equivalent

## Workflow

### Step 1: Locate and read the manifest

Find the plugin's `manifest.json` (either in `plugin/manifest.json` or the built `.plugin/manifest.json`). Extract these fields:

| Field | Required | Used for |
|-------|----------|----------|
| `name` | Yes | Registry `name` field |
| `version` | Yes | Registry `version` + release tag |
| `description` | Yes | Registry `description` |
| `author` | No | Registry `author` |
| `repositoryURL` | No | Registry `repositoryURL` |
| `categories` | No | Registry `categories` |
| `server` | Yes | Validates the plugin has a dylib |

If `description`, `author`, or `categories` are missing from the manifest, ask the user to provide them before proceeding — these make the plugin discoverable in the marketplace.

### Step 2: Build the plugin

```bash
make build
```

Verify the `.plugin` directory exists and contains the dylib referenced in `manifest.json`:

```bash
ls -la .build/<Name>.plugin/
# Should contain: manifest.json, <Name>.dylib, and optionally ui/
```

### Step 3: Create the zip

```bash
cd .build && zip -r /tmp/<Name>.plugin.zip <Name>.plugin/
```

Verify the zip is reasonable size and contains the expected files:

```bash
unzip -l /tmp/<Name>.plugin.zip
```

### Step 4: Derive the registry entry

Construct the registry ID from the plugin name: lowercase, spaces → hyphens.

```
"ASC Pro" → "asc-pro"
"Hello Plugin" → "hello-plugin"
```

Build the registry entry JSON:

```json
{
  "id": "<derived-id>",
  "name": "<from manifest.name>",
  "version": "<from manifest.version>",
  "description": "<from manifest.description>",
  "author": "<from manifest.author>",
  "repositoryURL": "<from manifest.repositoryURL>",
  "downloadURL": "https://github.com/tddworks/asc-registry/releases/latest/download/<Name>.plugin.zip",
  "categories": ["<from manifest.categories>"]
}
```

Omit `author`, `repositoryURL`, `categories` if not present in the manifest.

### Step 5: Clone and update registry.json

```bash
# Clone the registry (or pull if already cloned)
cd /tmp && rm -rf asc-registry && git clone https://github.com/tddworks/asc-registry.git
cd /tmp/asc-registry
```

Read `registry.json`, then either:
- **New plugin**: append the entry to the `plugins` array
- **Existing plugin** (same `id`): replace the existing entry (update version, description, etc.)

Write the updated `registry.json` with proper formatting (2-space indent).

### Step 6: Upload zip to GitHub release

Check if a release already exists, then either upload to existing or create new:

```bash
# Check existing release
gh release view v<version> --repo tddworks/asc-registry 2>/dev/null

# If release exists, upload as additional asset (delete old asset with same name first)
gh release delete-asset v<version> <Name>.plugin.zip --repo tddworks/asc-registry --yes 2>/dev/null
gh release upload v<version> /tmp/<Name>.plugin.zip --repo tddworks/asc-registry

# If no release exists, create one
gh release create v<version> /tmp/<Name>.plugin.zip \
  --repo tddworks/asc-registry \
  --title "v<version> — <plugin name>" \
  --notes "<plugin description>"
```

### Step 7: Push the updated registry.json

```bash
cd /tmp/asc-registry
git add registry.json
git commit -m "feat: update <plugin-id> to v<version>"
git push
```

### Step 8: Verify

```bash
# Verify the registry is accessible
curl -s https://raw.githubusercontent.com/tddworks/asc-registry/main/registry.json | python3 -m json.tool

# Verify the download URL works
curl -sI "https://github.com/tddworks/asc-registry/releases/latest/download/<Name>.plugin.zip" | head -5
```

Report the result to the user:
- Registry URL: `https://github.com/tddworks/asc-registry`
- Install command: `asc plugins install --name <id>`
- Release URL: `https://github.com/tddworks/asc-registry/releases/tag/v<version>`

## Example: Publishing hello-plugin

```bash
# 1. Build
cd examples/hello-plugin && make build

# 2. Zip
cd .build && zip -r /tmp/HelloPlugin.plugin.zip HelloPlugin.plugin/

# 3. Read manifest → derive entry
# manifest.json: name="Hello Plugin", version="1.0" → id="hello-plugin"

# 4. Update registry
cd /tmp/asc-registry
# Add/update entry in registry.json with:
# "downloadURL": "https://github.com/tddworks/asc-registry/releases/latest/download/HelloPlugin.plugin.zip"

# 5. Upload + push
gh release upload v1.0 /tmp/HelloPlugin.plugin.zip --repo tddworks/asc-registry
git add registry.json && git commit -m "feat: update hello-plugin to v1.0" && git push
```

## Enriching manifest.json before release

If the manifest is missing marketplace fields, update it before building:

```json
{
  "name": "My Plugin",
  "version": "1.0",
  "description": "What the plugin does",
  "author": "your-name",
  "repositoryURL": "https://github.com/you/my-plugin",
  "categories": ["category1", "category2"],
  "server": "MyPlugin.dylib",
  "ui": ["ui/my-ui.js"]
}
```

These fields flow into the registry entry and appear in `asc plugins market list` and the Command Center Plugins page.
