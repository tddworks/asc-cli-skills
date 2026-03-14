---
name: asc-app-shots
description: |
  App Store screenshot generation skill with two workflows:
  (A) AI-powered: fetches app metadata via `asc` CLI, analyzes screenshots with Claude vision,
  writes a ScreenPlan JSON, then generates final marketing screenshots via Gemini (`asc app-shots generate`),
  and optionally translates them (`asc app-shots translate`).
  (B) HTML-based (deterministic): writes a CompositionPlan JSON with precise device placement,
  text overlays, and backgrounds, then runs `asc app-shots html` to produce a self-contained HTML
  page with real device mockup frames and client-side PNG export — no AI needed.
  Use this skill when:
  (1) User asks to "create App Store screenshots" or "generate screenshot plan"
  (2) User asks to "make an HTML screenshot page" or "compose screenshots with mockups"
  (3) User mentions "asc-app-shots", "app-shots html", "composition plan", or screenshot marketing
  (4) User wants deterministic, reproducible screenshot layouts with device mockups
  (5) User wants AI-generated screenshots via Gemini
---

# asc-app-shots: App Store Screenshot Generator

Two workflows for creating App Store screenshots:

| | Workflow A: AI (Gemini) | Workflow B: HTML (Deterministic) |
|---|---|---|
| **Plan format** | `ScreenPlan` (app-shots-plan.json) | `CompositionPlan` (composition-plan.json) |
| **Command** | `asc app-shots generate` | `asc app-shots html` |
| **Output** | PNG files via Gemini | Self-contained HTML with export |
| **Mockup** | AI-rendered device frame | Real PNG mockup frame (bundled) |
| **Reproducible** | No (AI varies each run) | Yes (same plan = same output) |
| **Requires API key** | Yes (Gemini) | No |
| **Multi-device** | One per screen | Multiple per screen |

---

## Workflow B — HTML-based (Deterministic)

Use this when the user wants precise control, reproducibility, or no AI dependency.

### Step 1 — Write a CompositionPlan

See `references/composition-plan-schema.md` for the full schema.

The CompositionPlan uses **normalized 0–1 coordinates** so the same plan works at any resolution.

```json
{
  "appName": "MyApp",
  "canvas": { "width": 1320, "height": 2868, "displayType": "APP_IPHONE_69" },
  "defaults": {
    "background": { "type": "gradient", "from": "#2A1B5E", "to": "#000000", "angle": 180 },
    "textColor": "#FFFFFF",
    "subtextColor": "#A8B8D0",
    "accentColor": "#4A7CFF",
    "font": "Inter"
  },
  "screens": [
    {
      "texts": [
        { "content": "APP MANAGEMENT", "x": 0.065, "y": 0.028, "fontSize": 0.028, "fontWeight": 700, "color": "#B8A0FF" },
        { "content": "All your apps,\none dashboard.", "x": 0.065, "y": 0.055, "fontSize": 0.075, "fontWeight": 800, "color": "#FFFFFF" }
      ],
      "devices": [
        { "screenshotFile": "screenshot-1.png", "mockup": "iPhone 17 Pro Max", "x": 0.5, "y": 0.65, "scale": 0.88 }
      ]
    }
  ]
}
```

#### Design patterns (Helm / premium App Store style)

Follow these patterns for professional-looking screenshots:

**Single device screen:**
- Small uppercase category label at top: `y: 0.028`, `fontSize: 0.028`, colored to match gradient
- Bold 2-line heading below: `y: 0.055`, `fontSize: 0.075`, `fontWeight: 800`, white
- Large phone: `scale: 0.88`, `y: 0.65` — fills space below text, overflows bottom
- Each screen gets a unique gradient vibe (purple, blue, teal) fading to black

**Two-device screen:**
- Center-aligned text: `x: 0.5`, `textAlign: "center"`
- Back phone: `x: 0.34`, `y: 0.58`, `scale: 0.50`
- Front phone: `x: 0.66`, `y: 0.64`, `scale: 0.50`
- Front phone rendered on top (listed second in `devices` array)

**Color vibes (each screen different):**
- Purple: `{ "from": "#2A1B5E", "to": "#000000" }` with label `#B8A0FF`
- Blue: `{ "from": "#1B3A5E", "to": "#000000" }` with label `#7BC4FF`
- Teal: `{ "from": "#1A4A3E", "to": "#000000" }` with label `#7BFFC4`

### Step 2 — Run html command

```bash
# Auto-discover screenshots from plan directory
asc app-shots html --plan composition-plan.json --output-dir output

# Explicit screenshot paths
asc app-shots html --plan composition-plan.json --output-dir output screenshot-1.png screenshot-2.png

# Disable mockup frame (screenshots only, no device frame)
asc app-shots html --plan composition-plan.json --output-dir output --mockup none
```

The command auto-detects the plan format (CompositionPlan vs ScreenPlan).

Output: a single `app-shots.html` file with:
- All screenshots embedded as base64 data URIs
- Real device mockup frame (bundled iPhone 17 Pro Max - Deep Blue by default)
- Client-side PNG export via html-to-image CDN
- "Export All" button to download each screen as a PNG

### Device mockup system

The bundled default is **iPhone 17 Pro Max - Deep Blue** (`mockups.json`). Users can:
- Use the default: omit `--mockup`
- Disable: `--mockup none`
- Use custom PNG: `--mockup /path/to/frame.png --screen-inset-x 80 --screen-inset-y 70`
- Add custom mockups: place `mockups.json` + PNG files in `~/.asc/mockups/`

The `mockup` field in each device slot refers to a device name in `mockups.json`:
```json
{
  "iPhone 17 Pro Max - Deep Blue": {
    "category": "iPhone",
    "model": "iPhone 17 Pro Max",
    "displayType": "APP_IPHONE_67",
    "outputWidth": 1470, "outputHeight": 3000,
    "screenInsetX": 75, "screenInsetY": 66,
    "file": "iPhone 17 Pro Max - Deep Blue - Portrait.png",
    "default": true
  }
}
```

### HTML command flags

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Path to plan JSON |
| `--output-dir` | `.asc/app-shots/output` | Output directory |
| `--output-width` | `1320` | Canvas width (overridden by plan's `canvas.width`) |
| `--output-height` | `2868` | Canvas height (overridden by plan's `canvas.height`) |
| `--device-type` | — | Named device type, overrides width/height |
| `--mockup` | *(bundled default)* | Device name, file path, or `"none"` |
| `--screen-inset-x` | — | Override screen inset X from mockups.json |
| `--screen-inset-y` | — | Override screen inset Y from mockups.json |

---

## Workflow A — AI-powered (Gemini)

Three-step workflow:
1. **This skill** — fetch metadata + analyze screenshots → write `app-shots-plan.json`
2. **`asc app-shots generate`** — read plan + call Gemini image generation → output `screen-{n}.png`
3. **`asc app-shots translate`** *(optional)* — translate generated screenshots into other locales

### Step 1 — Detect CLI command

```bash
which asc
```

- **If found** → use `asc` directly
- **If not found** → use `swift run asc`

### Step 2 — Gather inputs

See [project-context.md](../shared/project-context.md) for the app ID resolution order.

- **App ID** — read from `.asc/project.json` first; if not present, run `asc apps list`
- **Version ID** — run `asc versions list --app-id <APP_ID>` and use the first result
- **Locale** — default: `en-US`
- **Screenshot files** — check `.asc/app-shots/` first; only ask user if no files found

### Step 3 — Fetch App Store metadata

See `references/commands.md` for the full command reference.

```bash
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')
asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq '.data[] | select(.locale == "<LOCALE>") | {name, subtitle}'

VERSION_ID=$(asc versions list --app-id <APP_ID> | jq -r '.data[0].id')
asc version-localizations list --version-id "$VERSION_ID" \
  | jq '.data[] | select(.locale == "<LOCALE>") | {description, keywords}'
```

Summarize `description` to 2-3 sentences (≤200 chars) for `appDescription`.

### Step 4 — Analyze screenshots with vision

Read each screenshot file. Extract:
- **Colors**: primary, accent, text, subtext hex values
- **Per-screen**: heading (2-5 words), subheading (6-12 words), layoutMode, visualDirection, imagePrompt
- **Tone**: minimal / playful / professional / bold / elegant

See `references/plan-schema.md` for the full ScreenPlan schema and imagePrompt formula.

### Step 5 — Write plan and generate

Write to `.asc/app-shots/app-shots-plan.json`, then immediately run:

```bash
asc app-shots generate
```

Gemini API key resolution: `--gemini-api-key` → `$GEMINI_API_KEY` → `~/.asc/app-shots-config.json`

### Step 6 — Translate (optional)

```bash
asc app-shots translate --to zh --to ja
```

See `references/commands.md` for all translate flags.

---

## Gemini API key management

```bash
asc app-shots config --gemini-api-key AIzaSy...    # save key
asc app-shots config                                # show current key (masked) + source
asc app-shots config --remove                       # delete saved key
```