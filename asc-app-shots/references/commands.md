# asc app-shots Commands

## Templates

### List templates

```bash
asc app-shots templates list [--size portrait|landscape|portrait43|square] [--preview] [--output table]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--size` | — | Filter by size |
| `--preview` | — | Include self-contained HTML preview per template |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON |

### Get template

```bash
asc app-shots templates get --id <ID> [--preview]
```

Without `--preview`: JSON with affordances. With `--preview`: self-contained HTML page.

### Apply template

```bash
asc app-shots templates apply \
  --id <ID> --screenshot <FILE> --headline <TEXT> \
  [--subtitle <TEXT>] [--tagline <TEXT>] [--app-name <NAME>] \
  [--preview html|image] [--image-output <PATH>]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | *(required)* | Headline text |
| `--subtitle` | — | Subtitle text |
| `--tagline` | — | Tagline text (overrides template default) |
| `--preview` | — | `html` or `image` |
| `--image-output` | `.asc/app-shots/output/screen-0.png` | Output PNG path |

---

## Gallery Templates

### List gallery templates

```bash
asc app-shots gallery-templates list [--output table]
```

Returns gallery templates with app name, shot count, template name, and readiness status.

### Get gallery template

```bash
asc app-shots gallery-templates get --id <ID> [--preview] [--pretty]
```

Without `--preview`: JSON with all shots, template, palette, and affordances.
With `--preview`: self-contained HTML gallery preview (horizontal strip of all screens).

---

## Themes

### List themes

```bash
asc app-shots themes list [--output table]
```

9 themes: Cartoon, Joyful, Holiday, Zen, Neon, Nature, Retro, Space, Luxury.

### Get theme

```bash
asc app-shots themes get --id <ID> [--context] [--pretty]
```

Without `--context`: JSON with theme data and AI hints.
With `--context`: raw `buildContext()` prompt string for AI compose.

### Generate ThemeDesign (1 AI call)

```bash
asc app-shots themes design --id <ID>
```

Returns reusable ThemeDesign JSON:
```json
{
  "palette": {"id": "luxury", "name": "Luxury", "background": "linear-gradient(...)", "textColor": "#f5e6c8"},
  "decorations": [
    {"shape": {"label": "◆"}, "x": 0.12, "y": 0.15, "size": 0.05, "opacity": 0.6, "color": "#d4a853", "animation": "float"}
  ]
}
```

Save to file for reuse: `asc app-shots themes design --id luxury > design.json`

### Apply ThemeDesign (deterministic, no AI)

```bash
asc app-shots themes apply-design \
  --design <FILE> --template <ID> --screenshot <FILE> --headline <TEXT> \
  [--subtitle <TEXT>] [--tagline <TEXT>] \
  [--preview html|image] [--image-output <PATH>]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--design` | *(required)* | Path to ThemeDesign JSON file |
| `--template` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | `Your Headline` | Headline text |
| `--preview` | — | `html` or `image` |
| `--image-output` | `.asc/app-shots/output/screen-0.png` | Output PNG path |

### Apply theme (full AI restyle)

```bash
asc app-shots themes apply \
  --theme <ID> --template <ID> --screenshot <FILE> --headline <TEXT> \
  [--preview html|image] [--image-output <PATH>] \
  [--canvas-width 1320] [--canvas-height 2868]
```

Full per-slide AI restyle. Slower than design→apply-design but more creative.

---

## Generate (Gemini AI)

```bash
asc app-shots generate --file <FILE> [FLAGS]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--file` | *(required)* | Screenshot file to enhance |
| `--device-type` | — | Resize output to App Store dimensions |
| `--style-reference` | — | Reference image for style transfer |
| `--prompt` | *(auto-enhance)* | Custom enhancement instructions |
| `--gemini-api-key` | — | Gemini API key (→ env var → config) |

---

## Export

```bash
asc app-shots export --html <FILE> --output <PNG>
```

Renders HTML to PNG via WebKit at 1320×2868.

---

## Config

```bash
asc app-shots config --gemini-api-key AIzaSy...   # save
asc app-shots config                               # show
asc app-shots config --remove                      # delete
```

---

## Metadata Fetch

```bash
asc apps list
asc versions list --app-id <APP_ID>
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')
asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq '.data[] | select(.locale == "en-US") | {name, subtitle}'
```

---

## Device Sizes

| Device Type | Width × Height | Required |
|---|---|---|
| `APP_IPHONE_69` | 1320 × 2868 | ✅ Required |
| `APP_IPHONE_67` | 1290 × 2796 | ✅ Required |
| `APP_IPHONE_65` | 1260 × 2736 | ✅ Required |
| `APP_IPHONE_61` | 1179 × 2556 | Optional |
| `APP_IPHONE_55` | 1242 × 2208 | Optional |
| `APP_IPAD_PRO_129` | 2048 × 2732 | ✅ Required |
| `APP_IPAD_PRO_3GEN_11` | 1668 × 2388 | Optional |
| `APP_DESKTOP` | 2560 × 1600 | Mac |
| `APP_APPLE_VISION_PRO` | 3840 × 2160 | visionOS |
