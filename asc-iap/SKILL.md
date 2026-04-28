---
name: asc-iap
description: |
  Manage In-App Purchases (IAPs) using the `asc` CLI tool.
  Use this skill when:
  (1) Listing IAPs: "asc iap list --app-id ID"
  (2) Creating IAPs: "asc iap create --type consumable|non-consumable|non-renewing-subscription"
  (3) Updating an IAP: "asc iap update --iap-id ID" (referenceName / reviewNote / familySharable)
  (4) Deleting an IAP: "asc iap delete --iap-id ID"
  (5) Submitting / unsubmitting: "asc iap submit", "asc iap unsubmit --submission-id ID"
  (6) IAP localizations: "asc iap-localizations list|create|update|delete"
  (7) IAP pricing: "asc iap price-points list", "asc iap prices set"
  (8) IAP offer codes (3 levels): "asc iap-offer-codes list/create/update", "asc iap-offer-codes prices list", custom codes, one-time codes (incl. `values` for redemption CSV)
  (9) IAP review screenshot: "asc iap-review-screenshot get|upload|delete"
  (10) IAP promotional images (1024x1024): "asc iap-images list|upload|delete"
  (11) User says "create in-app purchase", "list IAPs", "submit IAP", "delete IAP", "unsubmit", "IAP offer code", "custom code", "one-time codes", "redemption codes", "review screenshot", "promotional image"
---

# asc In-App Purchases

Manage IAPs via the `asc` CLI.

## Lifecycle

### List

```bash
asc iap list --app-id <APP_ID> [--limit N] [--pretty]
```

### Create

```bash
asc iap create \
  --app-id <APP_ID> \
  --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" \
  --type consumable
```

`--type` ∈ `consumable`, `non-consumable`, `non-renewing-subscription`.

### Update

```bash
asc iap update --iap-id <ID> \
  [--reference-name "New Name"] \
  [--review-note "Notes for App Review"] \
  [--family-sharable | --not-family-sharable]
```

### Delete

```bash
asc iap delete --iap-id <ID>
```

### Submit / Unsubmit

```bash
asc iap submit --iap-id <ID>          # state must be READY_TO_SUBMIT (affordance gates this)
asc iap unsubmit --submission-id <ID> # withdraw from review; manual Request<Void>
```

## IAP Pricing

```bash
asc iap price-points list --iap-id <ID> [--territory USA]

asc iap prices set \
  --iap-id <ID> \
  --base-territory USA \
  --price-point-id <PP>
```

Apple auto-equalizes other territories from the base.

## IAP Localizations

```bash
asc iap-localizations list   --iap-id <ID>
asc iap-localizations create --iap-id <ID> --locale en-US --name "Gold Coins" [--description "In-game currency"]
asc iap-localizations update --localization-id <LOC> [--name "New"] [--description "..."]
asc iap-localizations delete --localization-id <LOC>
```

## IAP Offer Codes (3-level hierarchy)

### Level 1 — offer code

```bash
asc iap-offer-codes list   --iap-id <ID>
asc iap-offer-codes create --iap-id <ID> --name "FREEGEMS" \
  --eligibility NON_SPENDER --eligibility CHURNED_SPENDER
asc iap-offer-codes update --offer-code-id <OC> --active false
asc iap-offer-codes prices list --offer-code-id <OC>   # per-territory pricing (read-only)
```

`--eligibility` (repeatable) ∈ `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER`.

### Level 2 — custom redeemable codes

```bash
asc iap-offer-code-custom-codes list   --offer-code-id <OC>
asc iap-offer-code-custom-codes create --offer-code-id <OC> \
  --custom-code "FREEGEMS100" --number-of-codes 500 [--expiration-date 2026-12-31]
asc iap-offer-code-custom-codes update --custom-code-id <CC> --active false
```

### Level 3 — one-time use code batches

```bash
asc iap-offer-code-one-time-codes list   --offer-code-id <OC>
asc iap-offer-code-one-time-codes create --offer-code-id <OC> \
  --number-of-codes 3000 --expiration-date 2026-06-30 [--environment production|sandbox]
asc iap-offer-code-one-time-codes update --one-time-code-id <OTC> --active false

# Download the CSV of redemption codes (raw String — not JSON):
asc iap-offer-code-one-time-codes values --one-time-code-id <OTC>
```

`--environment` defaults to `production`. Sandbox batches redeem against sandbox tester accounts (≈10,000/quarter ceiling) — production batches against live App Store accounts (≈150,000/quarter ceiling). Each `InAppPurchaseOfferCode` reports usage against both ceilings via `productionCodeCount` / `sandboxCodeCount`, and each one-time-use code row carries its `environment` so you can filter:

```bash
asc iap-offer-code-one-time-codes list --offer-code-id <OC> \
  | jq '.data[] | select(.environment == "SANDBOX")'
```

## IAP Review Assets

### Review screenshot (singleton — one per IAP)

```bash
asc iap-review-screenshot get    --iap-id <ID>          # returns empty data:[] when none uploaded
asc iap-review-screenshot upload --iap-id <ID> --file ./review.png
asc iap-review-screenshot delete --screenshot-id <RS>   # suppressed while assetState == AWAITING_UPLOAD
```

Upload uses ASC's standard reserve → upload chunks → commit-with-MD5 protocol.

### Promotional images (1024×1024, multiple per IAP)

```bash
asc iap-images list   --iap-id <ID>
asc iap-images upload --iap-id <ID> --file ./promo-1024.png
asc iap-images delete --image-id <IMG>                  # suppressed while state.isPendingReview
```

## CAEOAS Affordances

Every IAP response embeds ready-to-run follow-up commands:

```json
{
  "affordances": {
    "createLocalization":  "asc iap-localizations create --iap-id <ID> --locale en-US --name <name>",
    "delete":              "asc iap delete --iap-id <ID>",
    "getReviewScreenshot": "asc iap-review-screenshot get --iap-id <ID>",
    "listImages":          "asc iap-images list --iap-id <ID>",
    "listLocalizations":   "asc iap-localizations list --iap-id <ID>",
    "listOfferCodes":      "asc iap-offer-codes list --iap-id <ID>",
    "listPricePoints":     "asc iap price-points list --iap-id <ID>",
    "submit":              "asc iap submit --iap-id <ID>",
    "update":              "asc iap update --iap-id <ID> --reference-name <name>"
  }
}
```

`submit` only appears when `state == READY_TO_SUBMIT`. Each price point includes `setPrice` only when territory is known.

**InAppPurchaseSubmission** advertises `unsubmit`. **InAppPurchaseLocalization** advertises `update` + `delete`. **InAppPurchasePromotionalImage** advertises `delete` only when `!state.isPendingReview`. **InAppPurchaseReviewScreenshot** advertises `delete` only once `assetState.isComplete || hasFailed`.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')

# 1. Create + localize
IAP_ID=$(asc iap create --app-id "$APP_ID" --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" --type consumable | jq -r '.data[0].id')
asc iap-localizations create --iap-id "$IAP_ID" --locale en-US --name "Gold Coins" --description "In-game currency"
asc iap-localizations create --iap-id "$IAP_ID" --locale zh-Hans --name "金币"

# 2. Set price (Tier 1 USA, Apple auto-equalizes)
PRICE_ID=$(asc iap price-points list --iap-id "$IAP_ID" --territory USA \
  | jq -r '.data[] | select(.customerPrice == "0.99") | .id')
asc iap prices set --iap-id "$IAP_ID" --base-territory USA --price-point-id "$PRICE_ID"

# 3. Add review screenshot + promo image
asc iap-review-screenshot upload --iap-id "$IAP_ID" --file ./review.png
asc iap-images upload --iap-id "$IAP_ID" --file ./promo-1024.png

# 4. Submit
asc iap submit --iap-id "$IAP_ID"

# 5. Optional: offer code + redemption batch
OC_ID=$(asc iap-offer-codes create --iap-id "$IAP_ID" --name "LAUNCH_PROMO" \
  --eligibility NON_SPENDER --eligibility CHURNED_SPENDER | jq -r '.data[0].id')
asc iap-offer-code-one-time-codes create --offer-code-id "$OC_ID" \
  --number-of-codes 5000 --expiration-date 2026-12-31
# Download the CSV for distribution:
asc iap-offer-code-one-time-codes values --one-time-code-id <OTC_ID> > codes.csv
```

## State Semantics

`InAppPurchaseState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

`IAPCustomerEligibility` ∈ `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER`.

`InAppPurchaseReviewScreenshot.AssetState` exposes `isComplete` (uploadComplete or complete) and `hasFailed`. `InAppPurchasePromotionalImage.ImageState` exposes `isApproved` and `isPendingReview`.

Nil optional fields are omitted from JSON output.

## Reference

For full domain-model and REST detail see [docs/features/iap-subscriptions.md](../../docs/features/iap-subscriptions.md) and the [iap-subscriptions/ subdocs](../../docs/features/iap-subscriptions/).
