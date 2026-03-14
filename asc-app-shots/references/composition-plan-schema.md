# CompositionPlan JSON Schema

The `CompositionPlan` is a deterministic layout format for `asc app-shots html`. Unlike `ScreenPlan` (AI generation), this format gives full control over device placement, text overlays, and backgrounds. The same plan always produces identical output.

## Full Schema

```json
{
  "appName": "string — app display name (used in HTML page title)",
  "canvas": {
    "width": "int — canvas width in pixels (e.g. 1320)",
    "height": "int — canvas height in pixels (e.g. 2868)",
    "displayType": "string? — optional App Store display type (e.g. 'APP_IPHONE_69')"
  },
  "defaults": {
    "background": "SlideBackground — default background for all screens",
    "textColor": "string — default heading color hex (e.g. '#FFFFFF')",
    "subtextColor": "string — default subtext color hex",
    "accentColor": "string — accent color hex",
    "font": "string — default font family (e.g. 'Inter')"
  },
  "screens": [
    {
      "background": "SlideBackground? — override per-screen (nil uses defaults)",
      "texts": ["TextOverlay — positioned text elements"],
      "devices": ["DeviceSlot — positioned device mockups with screenshots"]
    }
  ]
}
```

## SlideBackground

Two types:

```json
{ "type": "solid", "color": "#000000" }
{ "type": "gradient", "from": "#2A1B5E", "to": "#000000", "angle": 180 }
```

- `angle` defaults to 180 (top to bottom) if omitted

## TextOverlay

```json
{
  "content": "string — text content (supports \\n for line breaks)",
  "x": "double — horizontal position 0-1 (0=left, 1=right)",
  "y": "double — vertical position 0-1 (0=top, 1=bottom)",
  "fontSize": "double — relative to canvas width (0.1 = 10% of width)",
  "fontWeight": "int? — CSS font weight 100-900 (default: 700)",
  "color": "string — hex color",
  "font": "string? — font family override (nil uses defaults.font)",
  "textAlign": "string? — 'left' (default), 'center', or 'right'"
}
```

**Positioning:**
- `x` and `y` are normalized 0-1 relative to canvas dimensions
- When `textAlign: "center"`, the `x` position is the center anchor (uses `transform: translateX(-50%)`)
- When `textAlign: "right"`, the `x` position is the right edge anchor

## DeviceSlot

```json
{
  "screenshotFile": "string — filename of screenshot (e.g. 'screenshot-1.png')",
  "mockup": "string — device name from mockups.json (e.g. 'iPhone 17 Pro Max')",
  "x": "double — center X position 0-1",
  "y": "double — center Y position 0-1",
  "scale": "double — relative to canvas width (1.0 = full width)",
  "rotation": "double? — degrees (default: 0)",
  "contentMode": "string? — 'fit' (default) or 'fill'"
}
```

**Positioning:**
- `x` and `y` define the device **center point** (uses `transform: translate(-50%, -50%)`)
- `scale: 0.88` means device width = 88% of canvas width
- Devices are rendered in array order — last device is on top (highest z-index)

## Common Canvas Sizes

| Display Type | Width | Height |
|---|---|---|
| `APP_IPHONE_69` | 1320 | 2868 |
| `APP_IPHONE_67` | 1290 | 2796 |
| `APP_IPHONE_65` | 1260 | 2736 |
| `APP_IPAD_PRO_129` | 2048 | 2732 |

---

## Complete Example — Premium 3-screen plan

```json
{
  "appName": "AppNexus for App Store Connect",
  "canvas": { "width": 1320, "height": 2868, "displayType": "APP_IPHONE_69" },
  "defaults": {
    "background": { "type": "solid", "color": "#000000" },
    "textColor": "#FFFFFF",
    "subtextColor": "#A8B8D0",
    "accentColor": "#4A7CFF",
    "font": "Inter"
  },
  "screens": [
    {
      "background": { "type": "gradient", "from": "#2A1B5E", "to": "#000000", "angle": 180 },
      "texts": [
        { "content": "APP MANAGEMENT", "x": 0.065, "y": 0.028, "fontSize": 0.028, "fontWeight": 700, "color": "#B8A0FF" },
        { "content": "All your apps,\none dashboard.", "x": 0.065, "y": 0.055, "fontSize": 0.075, "fontWeight": 800, "color": "#FFFFFF" }
      ],
      "devices": [
        { "screenshotFile": "screenshot-1.png", "mockup": "iPhone 17 Pro Max", "x": 0.5, "y": 0.65, "scale": 0.88 }
      ]
    },
    {
      "background": { "type": "gradient", "from": "#1B3A5E", "to": "#000000", "angle": 180 },
      "texts": [
        { "content": "CONTROL HUB", "x": 0.065, "y": 0.028, "fontSize": 0.028, "fontWeight": 700, "color": "#7BC4FF" },
        { "content": "Info, screenshots,\nAI — one tap.", "x": 0.065, "y": 0.055, "fontSize": 0.075, "fontWeight": 800, "color": "#FFFFFF" }
      ],
      "devices": [
        { "screenshotFile": "screenshot-2.png", "mockup": "iPhone 17 Pro Max", "x": 0.5, "y": 0.65, "scale": 0.88 }
      ]
    },
    {
      "background": { "type": "gradient", "from": "#1A4A3E", "to": "#000000", "angle": 135 },
      "texts": [
        { "content": "DUAL VIEW", "x": 0.5, "y": 0.028, "fontSize": 0.028, "fontWeight": 700, "color": "#7BFFC4", "textAlign": "center" },
        { "content": "Two screens.\nOne powerful app.", "x": 0.5, "y": 0.055, "fontSize": 0.075, "fontWeight": 800, "color": "#FFFFFF", "textAlign": "center" }
      ],
      "devices": [
        { "screenshotFile": "screenshot-1.png", "mockup": "iPhone 17 Pro Max", "x": 0.34, "y": 0.58, "scale": 0.50 },
        { "screenshotFile": "screenshot-2.png", "mockup": "iPhone 17 Pro Max", "x": 0.66, "y": 0.64, "scale": 0.50 }
      ]
    }
  ]
}
```