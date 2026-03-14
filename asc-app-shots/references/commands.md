# asc Commands for Screenshot Planning, HTML Generation, and Translation

## List apps (get App ID)

```bash
asc apps list [--pretty]
# Returns: id, name, bundleId
```

## Get version ID

```bash
asc versions list --app-id <APP_ID> [--pretty]
# Returns: id, versionString, platform, state
# Filter for prepareForSubmission or readyForSale state
```

## Get app info localizations (name, subtitle)

```bash
# Step 1: Get the app info ID
asc app-infos list --app-id <APP_ID>
# Returns: id, appId

# Step 2: Get localizations for that app info
asc app-info-localizations list --app-info-id <APP_INFO_ID> [--locale en-US]
# Returns: id, locale, name, subtitle, privacyPolicyUrl
```

## Get version localizations (description, keywords)

```bash
asc version-localizations list --version-id <VERSION_ID> [--pretty]
# Returns: id, locale, description, keywords, marketingUrl, supportUrl, versionId
# Note: fields are flat — no .attributes wrapper
```

## Filter by locale with jq

```bash
# Get name for en-US locale
asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .name'

# Get description for en-US locale
asc version-localizations list --version-id "$VERSION_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .description'
```

## Full metadata fetch script

```bash
APP_ID="6736834466"
VERSION_ID="abc123def"
LOCALE="en-US"

# App info
APP_INFO_ID=$(asc app-infos list --app-id "$APP_ID" | jq -r '.data[0].id')
APP_NAME=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .name')
SUBTITLE=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .subtitle // ""')

# Version localization
VERSION_DATA=$(asc version-localizations list --version-id "$VERSION_ID")
DESCRIPTION=$(echo "$VERSION_DATA" | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .description // ""')
KEYWORDS=$(echo "$VERSION_DATA" | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .keywords // ""')

echo "App: $APP_NAME ($APP_ID)"
echo "Subtitle: $SUBTITLE"
echo "Description: $DESCRIPTION"
echo "Keywords: $KEYWORDS"
```

## Generate screenshots (English)

```bash
# Zero-argument happy path — iPhone 6.9" (APP_IPHONE_69) at 1320×2868 by default
asc app-shots generate

# Match visual style of a reference screenshot (competitor, inspiration, etc.)
asc app-shots generate --style-reference ~/Downloads/inspiration.png

# Named device type — preferred over raw dimensions
asc app-shots generate --device-type APP_IPHONE_69   # 1320×2868 Required
asc app-shots generate --device-type APP_IPHONE_67   # 1290×2796 Required
asc app-shots generate --device-type APP_IPHONE_65   # 1260×2736 Required
asc app-shots generate --device-type APP_IPHONE_55   # 1242×2208
asc app-shots generate --device-type APP_IPAD_PRO_129  # 2048×2732

# Style reference + device type combined
asc app-shots generate \
  --style-reference ~/Downloads/inspiration.png \
  --device-type APP_IPHONE_69

# Raw dimensions (alternative to --device-type)
asc app-shots generate --output-width 1320 --output-height 2868

# Explicit paths + device type
asc app-shots generate \
  --plan .asc/app-shots/app-shots-plan.json \
  --output-dir .asc/app-shots/output \
  --device-type APP_IPHONE_69 \
  screen1.png screen2.png

# With explicit API key
asc app-shots generate --gemini-api-key AIzaSy...
```

**`--style-reference`:** Pass any PNG or JPEG as a visual style guide. Gemini replicates its colors, typography, background gradients, and layout patterns — without copying the content. The reference image is sent as the first part in the Gemini request, before the app screenshot and imagePrompt.

**Output size note:** Gemini returns images at ~704×1520. The CLI automatically upscales to the target size using CoreGraphics with `.high` interpolation before saving. `--device-type` overrides `--output-width`/`--output-height` when both are specified.

**All supported device types:**
| Device Type | Width × Height | App Store |
|---|---|---|
| `APP_IPHONE_69` | 1320 × 2868 | ✅ Required |
| `APP_IPHONE_67` | 1290 × 2796 | ✅ Required |
| `APP_IPHONE_65` | 1260 × 2736 | ✅ Required |
| `APP_IPHONE_61` | 1179 × 2556 | Optional |
| `APP_IPHONE_58` | 1125 × 2436 | Optional |
| `APP_IPHONE_55` | 1242 × 2208 | Optional |
| `APP_IPHONE_47` | 750 × 1334 | Optional |
| `APP_IPHONE_40` | 640 × 1136 | Optional |
| `APP_IPHONE_35` | 640 × 960 | Optional |
| `APP_IPAD_PRO_129` | 2048 × 2732 | ✅ Required |
| `APP_IPAD_PRO_3GEN_11` | 1668 × 2388 | Optional |
| `APP_IPAD_105` | 1668 × 2224 | Optional |
| `APP_IPAD_97` | 1536 × 2048 | Optional |
| `APP_APPLE_TV` | 1920 × 1080 | — |
| `APP_DESKTOP` | 2560 × 1600 | — |
| `APP_APPLE_VISION_PRO` | 3840 × 2160 | — |

## Generate HTML page (deterministic, no AI)

```bash
# Auto-discover screenshots from plan directory
asc app-shots html --plan composition-plan.json --output-dir output

# Explicit screenshot paths
asc app-shots html --plan composition-plan.json --output-dir output screenshot-1.png screenshot-2.png

# With legacy ScreenPlan format (auto-detected)
asc app-shots html --plan app-shots-plan.json --output-dir output

# Disable mockup frame
asc app-shots html --plan composition-plan.json --output-dir output --mockup none

# Custom mockup
asc app-shots html --plan composition-plan.json --output-dir output \
  --mockup /path/to/frame.png --screen-inset-x 80 --screen-inset-y 70
```

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Path to plan JSON (CompositionPlan or ScreenPlan) |
| `--output-dir` | `.asc/app-shots/output` | Output directory for HTML file |
| `--output-width` | `1320` | Canvas width (overridden by CompositionPlan's `canvas.width`) |
| `--output-height` | `2868` | Canvas height (overridden by CompositionPlan's `canvas.height`) |
| `--device-type` | — | Named device type, overrides width/height |
| `--mockup` | *(bundled default)* | Device name, file path, or `"none"` to disable |
| `--screen-inset-x` | — | Override screen inset X from mockups.json |
| `--screen-inset-y` | — | Override screen inset Y from mockups.json |

**Output:** A single `app-shots.html` file with base64-embedded screenshots, real device mockup frames, and client-side PNG export via html-to-image CDN.

**Plan format auto-detection:** The command tries `CompositionPlan` first, falls back to `ScreenPlan`.

---

## Translate screenshots to other locales

```bash
# Translate to Chinese and Japanese — reads screen-*.png from output dir automatically
asc app-shots translate --to zh --to ja

# Translate with explicit paths
asc app-shots translate \
  --plan .asc/app-shots/app-shots-plan.json \
  --source-dir .asc/app-shots/output \
  --output-dir .asc/app-shots/output \
  --to zh --to ja --to ko

# Single locale
asc app-shots translate --to fr

# Output goes to:
# .asc/app-shots/output/zh/screen-0.png
# .asc/app-shots/output/ja/screen-0.png
```

**Flags:**
| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Source ScreenPlan JSON |
| `--from` | `en` | Source locale label (informational) |
| `--to` | *(required, repeatable)* | Target locale(s) |
| `--source-dir` | `.asc/app-shots/output` | Dir with existing `screen-*.png` files |
| `--output-dir` | `.asc/app-shots/output` | Base output dir; locale subdirs created automatically |
| `--output-width` | `1320` | Output PNG width in pixels |
| `--output-height` | `2868` | Output PNG height in pixels |
| `--device-type` | — | Named device type (e.g. `APP_IPHONE_69`) — overrides width/height |
| `--style-reference` | — | Reference image to replicate visual style (colors, typography, layout) |
| `--gemini-api-key` | — | API key (flag → env var → config file) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini model |

## Config (save Gemini API key once)

```bash
asc app-shots config --gemini-api-key AIzaSy...   # save key
asc app-shots config                               # show current key + source
asc app-shots config --remove                      # delete saved key
```