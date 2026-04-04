# asc Commands for Screenshot Design, Generation, and Translation

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

**Flags:**
| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID (e.g. `top-hero`) |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | *(required)* | Headline text |
| `--subtitle` | — | Subtitle text |
| `--app-name` | `My App` | App name |
| `--preview` | — | Output self-contained HTML preview |

---

## Generation commands

### Generate screenshots (Gemini AI)

```bash
asc app-shots generate [FLAGS] [screenshots...]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Path to ScreenshotDesign JSON |
| `--gemini-api-key` | — | Gemini API key (→ env var → config file) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini model |
| `--output-dir` | `.asc/app-shots/output` | Output directory |
| `--output-width` | `1320` | Output width in pixels |
| `--output-height` | `2868` | Output height in pixels |
| `--device-type` | — | Named device type (overrides width/height) |
| `--style-reference` | — | Reference image for visual style replication |

```bash
# Zero-argument happy path
asc app-shots generate

# With style reference
asc app-shots generate --style-reference ~/Downloads/competitor-shot.png

# Named device type
asc app-shots generate --device-type APP_IPHONE_69

# Multiple sizes
asc app-shots generate --device-type APP_IPHONE_69 --output-dir output/iphone-69
asc app-shots generate --device-type APP_IPHONE_67 --output-dir output/iphone-67
asc app-shots generate --device-type APP_IPAD_PRO_129 --output-dir output/ipad-13
```

### Translate screenshots

```bash
asc app-shots translate --to <LOCALE> [--to <LOCALE>...] [FLAGS]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Source design JSON |
| `--from` | `en` | Source locale |
| `--to` | *(required, repeatable)* | Target locale(s) |
| `--source-dir` | `.asc/app-shots/output` | Directory with existing screenshots |
| `--style-reference` | — | Reference image for consistent style |

```bash
asc app-shots translate --to zh --to ja
asc app-shots translate --to zh --to ja --style-reference ~/Downloads/inspiration.png
```

### Generate HTML page (no AI)

```bash
asc app-shots html [--plan <FILE>] [--mockup <NAME|PATH|none>]
```

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
