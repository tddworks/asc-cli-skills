---
name: asc-app-previews
description: |
  Manage App Store app preview video sets and uploads using the `asc` CLI tool.
  Use this skill when:
  (1) Listing preview sets for a localization: "asc app-preview-sets list --localization-id ID"
  (2) Creating a preview set: "asc app-preview-sets create --localization-id ID --preview-type IPHONE_67"
  (3) Listing previews in a set: "asc app-previews list --set-id ID"
  (4) Uploading a preview video: "asc app-previews upload --set-id ID --file preview.mp4"
  (5) User says "upload app preview", "add preview video", "create preview set", or "list previews"
---

# asc App Previews

Manage App Store preview video sets and video uploads via the `asc` CLI.

## Commands

### List preview sets for a localization

```bash
asc app-preview-sets list --localization-id <LOCALIZATION_ID>
```

### Create a preview set

```bash
asc app-preview-sets create \
  --localization-id <LOCALIZATION_ID> \
  --preview-type <PREVIEW_TYPE>
```

**`--preview-type`** raw values have **no `APP_` prefix** — unlike screenshot display types.
Common values: `IPHONE_67`, `IPHONE_65`, `IPAD_PRO_3GEN_129`, `APPLE_TV`, `APPLE_VISION_PRO`, `DESKTOP`.

See [preview-types.md](references/preview-types.md) for all valid values grouped by device.

### List previews in a set

```bash
asc app-previews list --set-id <SET_ID>
```

### Upload a preview video

```bash
asc app-previews upload \
  --set-id <SET_ID> \
  --file path/to/preview.mp4 \
  [--preview-frame-time-code 00:00:05]
```

- Accepted formats: `.mp4`, `.mov`, `.m4v`
- `--preview-frame-time-code` sets the poster frame shown in the App Store
- Upload is a 3-step API flow: POST reserve → PUT chunks → PATCH MD5 confirm

## State Fields

`AppPreview` has two independent state fields (unlike screenshots which only have one):

| Field | States | Meaning |
|-------|--------|---------|
| `assetDeliveryState` | `AWAITING_UPLOAD`, `UPLOAD_COMPLETE`, `COMPLETE`, `FAILED` | Upload progress |
| `videoDeliveryState` | `AWAITING_UPLOAD`, `UPLOAD_COMPLETE`, `PROCESSING`, `COMPLETE`, `FAILED` | Video encoding |

`videoDeliveryState: "COMPLETE"` = video ready. `PROCESSING` is unique to previews (absent on screenshots).

Nil fields are omitted from JSON output. `mimeType` values containing `/` are escaped as `\/` by JSONEncoder (e.g. `"video\/mp4"`).

## CAEOAS Affordances

Every JSON response includes `affordances` with ready-to-run follow-up commands:

**AppPreviewSet:**
```json
{
  "affordances": {
    "listPreviews":    "asc app-previews list     --set-id <SET_ID>",
    "listPreviewSets": "asc app-preview-sets list --localization-id <LOCALIZATION_ID>"
  }
}
```

**AppPreview:**
```json
{
  "affordances": {
    "listPreviews": "asc app-previews list --set-id <SET_ID>"
  }
}
```

## Typical Workflow

```bash
# 1. Find the localization ID
asc version-localizations list --version-id <VERSION_ID> --output table

# 2. Create a preview set for the target device
asc app-preview-sets create \
  --localization-id <LOCALIZATION_ID> \
  --preview-type IPHONE_67

# 3. Upload the video (copy --set-id from affordances in step 2)
asc app-previews upload \
  --set-id <SET_ID> \
  --file preview.mp4 \
  --preview-frame-time-code 00:00:05

# 4. Check processing state
asc app-previews list --set-id <SET_ID> --pretty
```