# asc app-shots Commands

## Generate

Enhance a single screenshot into a marketing image using Gemini AI.

```bash
asc app-shots generate --file <FILE> [FLAGS]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--file` | *(required)* | Screenshot file to enhance |
| `--device-type` | — | Named device type — resizes output to exact App Store dimensions |
| `--gemini-api-key` | — | Gemini API key (→ env var → config file) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini model |
| `--output-dir` | `.asc/app-shots/output` | Output directory |
| `--style-reference` | — | Reference image — Gemini replicates its visual style |
| `--prompt` | *(auto-enhance)* | Custom enhancement instructions |

```bash
# Auto-enhance
asc app-shots generate --file screen.png

# With device type for exact dimensions
asc app-shots generate --file screen.png --device-type APP_IPHONE_67

# Style transfer
asc app-shots generate --file screen.png --style-reference inspiration.png

# Custom prompt
asc app-shots generate --file screen.png --prompt "warmer colors, deeper shadows"
```

**Default auto-enhance prompt** (when no `--prompt` given):
- Photorealistic iPhone 15 Pro mockup with reflections and shadows
- Breakout elements — UI panels popping out from device frame with drop shadows
- 1-2 small supporting elements (badges, icons) that reinforce the message
- Clean, bold background — no glows or noise
- Professional App Store agency quality

---

## Template commands

### List templates

```bash
asc app-shots templates list [--size portrait|landscape|portrait43|square] [--preview] [--pretty]
```

Returns template data with affordances. Use `--preview` to include self-contained HTML previews.

### Get template details

```bash
asc app-shots templates get --id <TEMPLATE_ID> [--preview]
```

Without `--preview`: returns JSON with template data and affordances.
With `--preview`: returns a self-contained HTML page — save to file and open in browser.

### Apply template to screenshot

```bash
asc app-shots templates apply \
  --id <TEMPLATE_ID> \
  --screenshot <FILE> \
  --headline <TEXT> \
  [--subtitle <TEXT>] \
  [--app-name <NAME>] \
  [--preview]
```

Without `--preview`: returns ScreenDesign JSON with affordances.
With `--preview`: returns self-contained HTML showing the template applied to the real screenshot.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID (e.g. `top-hero`) |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | *(required)* | Headline text |
| `--subtitle` | — | Subtitle text |
| `--app-name` | `My App` | App name |
| `--preview` | — | Output self-contained HTML preview |

---

## Metadata fetch commands

```bash
# Get app ID
asc apps list

# Get version ID
asc versions list --app-id <APP_ID>

# Get app name and subtitle
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')
asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq '.data[] | select(.locale == "en-US") | {name, subtitle}'

# Get description and keywords
asc version-localizations list --version-id <VERSION_ID> \
  | jq '.data[] | select(.locale == "en-US") | {description, keywords}'
```

---

## Config

```bash
asc app-shots config --gemini-api-key AIzaSy...   # save key
asc app-shots config                               # show current key + source
asc app-shots config --remove                      # delete saved key
```

---

## Device sizes

Use `--device-type` on `generate` to resize output to exact App Store dimensions.

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
