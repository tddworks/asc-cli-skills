---
name: asc-app-shots
description: |
  App Store screenshot design and generation skill with two workflows:
  (A) Template-based: browse templates, apply to screenshots, then enhance with Gemini AI.
  (B) AI-powered: Claude analyzes screenshots and generates a targeted prompt for Gemini.
  Use this skill when:
  (1) User asks to "create App Store screenshots", "design screenshots", or "enhance screenshot"
  (2) User mentions "templates", "app-shots", "screenshot marketing", "compose screenshots"
  (3) User wants to browse/preview/apply screenshot templates
  (4) User wants AI-generated marketing screenshots
---

# asc-app-shots: App Store Screenshot Designer

Two workflows — pick the best fit:

| | A: Templates + AI | B: AI-only |
|---|---|---|
| **Flow** | Browse templates → apply → generate | Analyze screenshot → generate with prompt |
| **Output** | PNG via Gemini | PNG via Gemini |
| **Templates** | Yes (23 built-in) | No |
| **Preview** | `--preview` flag | No |
| **Requires API key** | Yes (Gemini) | Yes (Gemini) |

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

### Step 4 — Enhance with AI

Three modes:

```bash
# Auto-enhance — photorealistic device frame, breakout elements, pro polish
asc app-shots generate --file .asc/app-shots/output/screen-0.png

# With exact App Store dimensions
asc app-shots generate --file .asc/app-shots/output/screen-0.png --device-type APP_IPHONE_67

# Style transfer — match another screenshot's visual style
asc app-shots generate --file .asc/app-shots/output/screen-0.png \
  --style-reference ~/Downloads/inspiration.png

# Custom prompt — describe exactly what you want
asc app-shots generate --file .asc/app-shots/output/screen-0.png \
  --prompt "add warm glow, deepen shadows, make text pop"
```

The default auto-enhance prompt:
- Replaces flat device frames with photorealistic iPhone 15 Pro mockups
- Optionally adds breakout elements — UI panels popping out from the device with drop shadows
- Adds 1-2 subtle supporting elements (badges, icons) if they reinforce the message
- Keeps background clean and bold — no glows or noise
- Professional App Store agency quality

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

## Workflow B — AI-powered (prompt-driven)

Best for: users who want Claude to analyze their screenshot and generate a targeted prompt.

### Step 1 — Use the asc-app-shots-prompt skill

In Claude Code, ask:
> "Analyze this screenshot and generate a prompt for app-shots"

Claude reads the screenshot, identifies:
- App type, purpose, target audience
- Dominant color scheme, UI components
- Best breakout candidate (most compelling UI panel)
- Marketing headline and subtitle

Then outputs a ready-to-run command with a targeted `--prompt`.

### Step 2 — Generate

```bash
asc app-shots generate \
  --file screen.png \
  --prompt '<generated prompt>' \
  --device-type APP_IPHONE_67
```

---

## Command Reference

### Generate

```bash
asc app-shots generate --file <FILE> [--device-type <TYPE>] [--style-reference <FILE>] [--prompt <TEXT>]
```

### Templates

```bash
asc app-shots templates list [--size portrait] [--preview]
asc app-shots templates get --id <ID> [--preview]
asc app-shots templates apply --id <ID> --screenshot <FILE> --headline <TEXT> [--preview]
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

Use `--device-type` on `generate` to resize output to exact App Store dimensions.

| Device Type | Width × Height | Required |
|---|---|---|
| `APP_IPHONE_69` | 1320 × 2868 | ✅ |
| `APP_IPHONE_67` | 1290 × 2796 | ✅ |
| `APP_IPHONE_65` | 1260 × 2736 | ✅ |
| `APP_IPAD_PRO_129` | 2048 × 2732 | ✅ |

Generate multiple sizes:
```bash
asc app-shots generate --file screen.png --device-type APP_IPHONE_69 --output-dir output/69
asc app-shots generate --file screen.png --device-type APP_IPHONE_67 --output-dir output/67
asc app-shots generate --file screen.png --device-type APP_IPAD_PRO_129 --output-dir output/ipad
```
