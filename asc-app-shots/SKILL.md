---
name: asc-app-shots
description: |
  App Store screenshot design, theming, and generation skill with three workflows:
  (A) Template-based: browse templates, apply to screenshots, optionally enhance with Gemini AI.
  (B) Gallery mode: multi-screen coordinated sets from gallery templates.
  (C) Themed: apply visual themes (AI-generated ThemeDesign) on top of templates.
  Use this skill when:
  (1) User asks to "create App Store screenshots", "design screenshots", or "enhance screenshot"
  (2) User mentions "templates", "app-shots", "screenshot marketing", "compose screenshots"
  (3) User wants to browse/preview/apply screenshot templates or gallery templates
  (4) User wants to apply visual themes (cartoon, luxury, space, zen, neon, etc.) to screenshots
  (5) User asks about "ThemeDesign", "theme design", "apply theme", or "gallery templates"
---

# asc-app-shots: App Store Screenshot Designer

Three workflows:

| | A: Templates | B: Gallery | C: Themed |
|---|---|---|---|
| **Flow** | Browse → apply → generate | Gallery template → all screens | Template → ThemeDesign → apply |
| **Screens** | Single | Multi (hero + features) | Per-slide |
| **AI** | Optional (Gemini enhance) | Optional | 1 AI call for design, rest deterministic |

---

## Workflow A — Single Template

Browse templates, apply to a screenshot, optionally enhance with Gemini AI.

### Step 1 — Browse and apply

```bash
asc app-shots templates list --output table
asc app-shots templates get --id top-hero --preview > preview.html && open preview.html

# Apply to screenshot → HTML preview
asc app-shots templates apply \
  --id top-hero --screenshot screen.png --headline "Ship Faster" \
  --preview html > composed.html && open composed.html

# Apply to screenshot → PNG export
asc app-shots templates apply \
  --id top-hero --screenshot screen.png --headline "Ship Faster" \
  --preview image --image-output marketing.png
```

### Step 2 — Enhance with Gemini AI (optional)

```bash
asc app-shots generate --file marketing.png
asc app-shots generate --file marketing.png --device-type APP_IPHONE_67
asc app-shots generate --file marketing.png --style-reference inspiration.png
asc app-shots generate --file marketing.png --prompt "warmer colors, deeper shadows"
```

---

## Workflow B — Gallery Templates

Coordinated multi-screen sets (hero + feature screens).

```bash
# Browse gallery templates
asc app-shots gallery-templates list --output table

# Preview all screens in horizontal strip
asc app-shots gallery-templates get --id neon-pop --preview > gallery.html && open gallery.html

# Get gallery details (JSON with shots, template, palette)
asc app-shots gallery-templates get --id neon-pop --pretty
```

Gallery templates include sample content (headlines, badges, trust marks) ready to customize.

---

## Workflow C — Themed Screenshots

Apply visual themes on top of templates. Two-step flow: generate ThemeDesign once (1 AI call), then apply deterministically to any number of screenshots.

### Step 1 — Browse themes

```bash
asc app-shots themes list --output table
# → Cartoon, Joyful, Holiday, Zen, Neon, Nature, Retro, Space, Luxury

asc app-shots themes get --id luxury --pretty
asc app-shots themes get --id luxury --context   # AI prompt string
```

### Step 2 — Generate ThemeDesign (1 AI call, reusable)

```bash
asc app-shots themes design --id luxury > design.json
```

Returns JSON with `palette` (background + textColor) and `decorations` (floating elements with animations).

### Step 3 — Apply ThemeDesign (deterministic, no AI)

```bash
# HTML preview
asc app-shots themes apply-design \
  --design design.json --template top-hero \
  --screenshot screen.png --headline "Ship Faster" \
  --preview html > themed.html

# PNG export
asc app-shots themes apply-design \
  --design design.json --template top-hero \
  --screenshot screen.png --headline "Ship Faster" \
  --preview image --image-output themed.png
```

### Alternative: Full AI restyle (fallback)

```bash
asc app-shots themes apply \
  --theme luxury --template top-hero \
  --screenshot screen.png --headline "Ship Faster"
```

Per-slide AI restyle — slower but more creative. Falls back to this when `design` isn't available.

---

## Command Reference

See [references/commands.md](references/commands.md) for full flag tables.

### Templates
```bash
asc app-shots templates list [--size portrait] [--preview] [--output table]
asc app-shots templates get --id <ID> [--preview]
asc app-shots templates apply --id <ID> --screenshot <FILE> --headline <TEXT> [--preview html|image]
```

### Gallery Templates
```bash
asc app-shots gallery-templates list [--output table]
asc app-shots gallery-templates get --id <ID> [--preview]
```

### Themes
```bash
asc app-shots themes list [--output table]
asc app-shots themes get --id <ID> [--context]
asc app-shots themes design --id <ID>
asc app-shots themes apply-design --design <FILE> --template <ID> --screenshot <FILE> --headline <TEXT>
asc app-shots themes apply --theme <ID> --template <ID> --screenshot <FILE> --headline <TEXT>
```

### Generate (Gemini AI)
```bash
asc app-shots generate --file <FILE> [--device-type <TYPE>] [--style-reference <FILE>] [--prompt <TEXT>]
```

### Export & Config
```bash
asc app-shots export --html <FILE> --output <PNG>
asc app-shots config --gemini-api-key <KEY>
```

---

## Available Templates

| Category | Templates |
|----------|-----------|
| **Bold** | Top Hero, Bold CTA, Tilted Hero |
| **Minimal** | Minimal Light, Device Only |
| **Elegant** | Dark Premium, Sage Editorial, Cream Serif, Ocean Calm, Blush Editorial |
| **Professional** | Top & Bottom, Left Aligned, Bottom Text |
| **Playful** | Warm Sunset, Sky Soft, Cartoon Peach, Cartoon Mint, Cartoon Lavender |
| **Showcase** | Duo Devices (2), Triple Fan (3), Side by Side (2) |

## Available Themes

| Theme | Style |
|-------|-------|
| Cartoon | Bold outlines, bright solid colors, playful shapes |
| Joyful | Confetti, sparkles, warm gradients |
| Holiday | Festive decorations, snowflakes |
| Zen | Calm, minimal, drifting leaves |
| Neon | Dark backdrop, glowing neon accents |
| Nature | Organic shapes, petals, watercolor |
| Retro | Vintage palette, geometric, 80s/90s |
| Space | Cosmic backgrounds, twinkling stars |
| Luxury | Gold accents, dark backgrounds, elegance |

---

## Gemini API Key

Resolution order:
1. `--gemini-api-key` flag
2. `$GEMINI_API_KEY` environment variable
3. `~/.asc/app-shots-config.json` (via `asc app-shots config`)

## Device Sizes

| Device Type | Width × Height | Required |
|---|---|---|
| `APP_IPHONE_69` | 1320 × 2868 | ✅ |
| `APP_IPHONE_67` | 1290 × 2796 | ✅ |
| `APP_IPHONE_65` | 1260 × 2736 | ✅ |
| `APP_IPAD_PRO_129` | 2048 × 2732 | ✅ |
