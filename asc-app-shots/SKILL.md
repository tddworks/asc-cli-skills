---
name: asc-app-shots
description: |
  App Store screenshot design and generation skill with three workflows:
  (A) Template-based: browse templates, apply to screenshots, then generate with Gemini AI.
  (B) AI-powered: Claude analyzes screenshots, writes a ScreenshotDesign JSON, Gemini generates final images.
  (C) HTML-based: deterministic CompositionPlan with device mockups, no AI needed.
  Use this skill when:
  (1) User asks to "create App Store screenshots", "design screenshots", or "generate screenshot plan"
  (2) User mentions "templates", "app-shots", "screenshot marketing", "compose screenshots"
  (3) User wants to browse/preview/apply screenshot templates
  (4) User wants AI-generated or deterministic screenshot layouts
---

# asc-app-shots: App Store Screenshot Designer

Three workflows — pick the best fit:

| | A: Templates + AI | B: AI-only | C: HTML (no AI) |
|---|---|---|---|
| **Flow** | Browse templates → apply → generate | Skill writes plan → generate | Skill writes plan → html |
| **Plan** | `ScreenshotDesign` | `ScreenshotDesign` | `CompositionPlan` |
| **Output** | PNG via Gemini | PNG via Gemini | HTML with export |
| **Templates** | Yes (23 built-in) | No | No |
| **Preview** | `--preview` flag | No | Browser preview |
| **Requires API key** | Yes (Gemini) | Yes (Gemini) | No |

---

## Workflow A — Template-based (Recommended)

Best for: users who want a polished design fast. Browse templates, pick one, apply to screenshots, then generate.

### Step 1 — Browse templates

```bash
# List all available templates
asc app-shots templates list

# Filter by screen orientation
asc app-shots templates list --size portrait

# Include visual previews (saves HTML files you can open)
asc app-shots templates list --preview
```

Each template has affordances:
```json
{
  "affordances": {
    "preview": "asc app-shots templates get --id top-hero --preview",
    "apply": "asc app-shots templates apply --id top-hero --screenshot screen.png",
    "detail": "asc app-shots templates get --id top-hero"
  }
}
```

### Step 2 — Preview a template

```bash
# Get self-contained HTML preview — open in browser
asc app-shots templates get --id top-hero --preview > preview.html
open preview.html
```

### Step 3 — Apply template to screenshot

```bash
# Apply and preview the result
asc app-shots templates apply \
  --id top-hero \
  --screenshot .asc/app-shots/screen1.png \
  --headline "Ship Faster" \
  --preview > composed.html
open composed.html

# Apply without preview — get design JSON
asc app-shots templates apply \
  --id top-hero \
  --screenshot .asc/app-shots/screen1.png \
  --headline "Ship Faster" \
  --app-name "MyApp"
```

The result is a `ScreenDesign` with affordances pointing to next steps:
```json
{
  "affordances": {
    "generate": "asc app-shots generate --design design.json",
    "preview": "asc app-shots templates apply --id top-hero --screenshot ... --headline ...",
    "changeTemplate": "asc app-shots templates list"
  }
}
```

### Step 4 — Generate final images

```bash
asc app-shots generate
```

### Step 5 — Translate (optional)

```bash
asc app-shots translate --to zh --to ja
```

### Available templates

Templates are provided by plugins. The Blitz Screenshots plugin provides 23 built-in templates:

| Category | Templates |
|----------|-----------|
| **Bold** | Top Hero, Bold CTA, Tilted Hero, Midnight Bold |
| **Minimal** | Minimal Light, Device Only |
| **Elegant** | Dark Premium, Sage Editorial, Cream Serif, Ocean Calm, Blush Editorial |
| **Professional** | Top & Bottom, Left Aligned, Bottom Text |
| **Playful** | Warm Sunset, Sky Soft, Cartoon Peach, Cartoon Mint, Cartoon Lavender |
| **Showcase** | Duo Devices, Triple Fan, Side by Side |
| **Custom** | Custom Blank |

Each template defines:
- Background gradient/solid color
- Text slot positions (heading, subheading, tagline) with font sizes and styles
- Device slot positions (phone placement, scale, rotation)
- Supported screen sizes (portrait, landscape, etc.)

---

## Workflow B — AI-powered (Gemini)

Best for: users who want Claude to design the plan automatically.

### Step 1 — Gather inputs

See [project-context.md](../shared/project-context.md) for app ID resolution.

- **App ID** — from `.asc/project.json` or `asc apps list`
- **Version ID** — from `asc versions list --app-id <APP_ID>`
- **Screenshot files** — check `.asc/app-shots/` directory

### Step 2 — Fetch metadata

```bash
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')
APP_NAME=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .name')

VERSION_ID=$(asc versions list --app-id <APP_ID> | jq -r '.data[0].id')
DESCRIPTION=$(asc version-localizations list --version-id "$VERSION_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .description')
```

### Step 3 — Analyze screenshots with vision

Read each screenshot. Extract:
- **Colors**: primary, accent, text, subtext hex values
- **Per-screen**: heading (2-5 words), subheading, layoutMode, imagePrompt
- **Tone**: minimal / playful / professional / bold / elegant

### Step 4 — Write plan and generate

Write `ScreenshotDesign` JSON to `.asc/app-shots/app-shots-plan.json`:

```json
{
  "appId": "6736834466",
  "appName": "MyApp",
  "tagline": "Ship Faster",
  "appDescription": "A brief summary for AI context",
  "tone": "bold",
  "colors": { "primary": "#0A0F1E", "accent": "#4A90E2", "text": "#FFFFFF", "subtext": "#94B8D4" },
  "screens": [
    {
      "index": 0,
      "screenshotFile": "screen1.png",
      "heading": "Ship Faster",
      "subheading": "Your App Store, One Command Away",
      "layoutMode": "center",
      "visualDirection": "Dashboard showing app list",
      "imagePrompt": "Create a marketing screenshot..."
    }
  ]
}
```

Then generate:

```bash
asc app-shots generate
```

### Step 5 — Translate (optional)

```bash
asc app-shots translate --to zh --to ja
```

---

## Workflow C — HTML-based (Deterministic)

Best for: precise control, reproducibility, no AI dependency.

### Step 1 — Write CompositionPlan

See `references/composition-plan-schema.md` for the full schema. Uses **normalized 0–1 coordinates**.

```json
{
  "appName": "MyApp",
  "canvas": { "width": 1320, "height": 2868 },
  "defaults": {
    "background": { "type": "gradient", "from": "#2A1B5E", "to": "#000000", "angle": 180 },
    "textColor": "#FFFFFF", "subtextColor": "#A8B8D0", "accentColor": "#4A7CFF", "font": "Inter"
  },
  "screens": [{
    "texts": [
      { "content": "APP MANAGEMENT", "x": 0.065, "y": 0.028, "fontSize": 0.028, "fontWeight": 700, "color": "#B8A0FF" },
      { "content": "All your apps,\none dashboard.", "x": 0.065, "y": 0.055, "fontSize": 0.075, "fontWeight": 800, "color": "#FFFFFF" }
    ],
    "devices": [
      { "screenshotFile": "screenshot-1.png", "mockup": "iPhone 17 Pro Max", "x": 0.5, "y": 0.65, "scale": 0.88 }
    ]
  }]
}
```

### Step 2 — Generate HTML

```bash
asc app-shots html --plan composition-plan.json --output-dir output
```

---

## Command Reference

### Template commands

```bash
asc app-shots templates list [--size portrait] [--preview]
asc app-shots templates get --id <ID> [--preview]
asc app-shots templates apply --id <ID> --screenshot <FILE> --headline <TEXT> [--preview]
```

### Generation commands

```bash
asc app-shots generate [--plan <FILE>] [--style-reference <FILE>] [--device-type <TYPE>]
asc app-shots translate --to <LOCALE> [--to <LOCALE>...] [--style-reference <FILE>]
asc app-shots html [--plan <FILE>] [--mockup <NAME|PATH|none>]
```

### Config

```bash
asc app-shots config --gemini-api-key <KEY>   # save
asc app-shots config                           # show
asc app-shots config --remove                  # delete
```

---

## Gemini API key

Resolution order:
1. `--gemini-api-key` flag
2. `$GEMINI_API_KEY` environment variable
3. `~/.asc/app-shots-config.json` (via `asc app-shots config`)

---

## Device sizes

| Device Type | Width × Height | Required |
|---|---|---|
| `APP_IPHONE_69` | 1320 × 2868 | ✅ |
| `APP_IPHONE_67` | 1290 × 2796 | ✅ |
| `APP_IPHONE_65` | 1260 × 2736 | ✅ |
| `APP_IPAD_PRO_129` | 2048 × 2732 | ✅ |

Generate multiple sizes:
```bash
asc app-shots generate --device-type APP_IPHONE_69 --output-dir output/iphone-69
asc app-shots generate --device-type APP_IPHONE_67 --output-dir output/iphone-67
asc app-shots generate --device-type APP_IPAD_PRO_129 --output-dir output/ipad-13
```
