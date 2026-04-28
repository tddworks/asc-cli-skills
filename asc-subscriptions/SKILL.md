---
name: asc-subscriptions
description: |
  Manage auto-renewable subscriptions using the `asc` CLI tool.
  Use this skill when:
  (1) Subscription groups: "asc subscription-groups list|create|update|delete"
  (2) Subscription group localizations (custom-app-name per locale): "asc subscription-group-localizations list|create|update|delete"
  (3) Subscriptions: "asc subscriptions list|create|update|delete|submit|unsubmit"
  (4) Subscription pricing: "asc subscriptions price-points list", "asc subscriptions prices set" (per-territory, with proceedsYear2)
  (5) Subscription localizations: "asc subscription-localizations list|create|update|delete"
  (6) Introductory offers: "asc subscription-offers list|create|delete" (FREE_TRIAL, PAY_AS_YOU_GO, PAY_UP_FRONT)
  (7) Promotional offers (in-app, with per-territory pricing): "asc subscription-promotional-offers list|create|delete", "asc subscription-promotional-offers prices list"
  (8) Win-back offers (lapsed subscribers): "asc win-back-offers list|create|update|delete", "asc win-back-offers prices list"
  (9) Offer codes (3 levels): "asc subscription-offer-codes list/create/update", "asc subscription-offer-codes prices list", custom codes, one-time codes (incl. `values` for redemption CSV)
  (10) Subscription review screenshot: "asc subscription-review-screenshot get|upload|delete"
  (11) User says "subscription group", "subscription tier", "promotional offer", "win-back offer", "lapsed subscriber", "subscription offer code", "custom code", "one-time codes", "free trial", "promo code", "review screenshot", "Custom App Name"
---

# asc Subscriptions

Manage auto-renewable subscription groups, tiers, localizations, pricing, offers, and review assets via the `asc` CLI.

## Subscription Groups

```bash
asc subscription-groups list   --app-id <APP_ID>
asc subscription-groups create --app-id <APP_ID> --reference-name "Premium Plans"
asc subscription-groups update --group-id <GROUP_ID> --reference-name "Premium"
asc subscription-groups delete --group-id <GROUP_ID>
```

### Group Localizations (display name + Custom App Name per locale)

```bash
asc subscription-group-localizations list   --group-id <GROUP_ID>
asc subscription-group-localizations create --group-id <GROUP_ID> --locale en-US --name "Premium Plans" [--custom-app-name "Premium App"]
asc subscription-group-localizations update --localization-id <LOC> [--name "..."] [--custom-app-name "..."]
asc subscription-group-localizations delete --localization-id <LOC>
```

## Subscriptions (lifecycle)

```bash
asc subscriptions list   --group-id <GROUP_ID>
asc subscriptions create --group-id <GROUP_ID> --name "Monthly Premium" \
  --product-id "com.app.monthly" --period ONE_MONTH \
  [--family-sharable] [--group-level 1]
asc subscriptions update --subscription-id <SUB_ID> \
  [--name "..."] [--family-sharable | --not-family-sharable] [--group-level <n>] [--review-note "..."]
asc subscriptions delete --subscription-id <SUB_ID>
asc subscriptions submit   --subscription-id <SUB_ID>          # state must be READY_TO_SUBMIT
asc subscriptions unsubmit --submission-id <SUBMISSION_ID>     # withdraw from review (manual Request<Void>)
```

`--period` ∈ `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`.

## Subscription Pricing (per-territory, with `proceedsYear2`)

```bash
asc subscriptions price-points list --subscription-id <SUB_ID> [--territory USA]

asc subscriptions prices set \
  --subscription-id <SUB_ID> \
  --territory USA \
  --price-point-id <PP> \
  [--start-date 2026-06-01] \
  [--preserve-current-price]
```

Subscriptions price **per-territory** (no base territory). Each price point includes `customerPrice`, `proceeds`, and `proceedsYear2`.

## Subscription Localizations

```bash
asc subscription-localizations list   --subscription-id <SUB_ID>
asc subscription-localizations create --subscription-id <SUB_ID> --locale en-US --name "Monthly Premium" [--description "..."]
asc subscription-localizations update --localization-id <LOC> [--name "..."] [--description "..."]
asc subscription-localizations delete --localization-id <LOC>
```

## Introductory Offers

```bash
asc subscription-offers list   --subscription-id <SUB_ID>

# Free trial
asc subscription-offers create --subscription-id <SUB_ID> \
  --duration ONE_MONTH --mode FREE_TRIAL --periods 1

# Paid intro offer — price-point-id required for PAY_AS_YOU_GO / PAY_UP_FRONT
asc subscription-offers create --subscription-id <SUB_ID> \
  --duration THREE_MONTHS --mode PAY_AS_YOU_GO --periods 3 \
  --territory USA --price-point-id <PP>

asc subscription-offers delete --offer-id <OFFER_ID>
```

`--duration` ∈ `THREE_DAYS`, `ONE_WEEK`, `TWO_WEEKS`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`. `--mode` ∈ `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT`.

## Promotional Offers (in-app, with per-territory pricing)

```bash
asc subscription-promotional-offers list   --subscription-id <SUB_ID>

asc subscription-promotional-offers create --subscription-id <SUB_ID> \
  --name "Loyalty25" --offer-code loyalty25 \
  --duration THREE_MONTHS --mode PAY_AS_YOU_GO --periods 3 \
  --price USA=spp-1 --price GBR=spp-2          # repeatable: TERRITORY=PRICE_POINT_ID

asc subscription-promotional-offers delete       --offer-id <OFFER_ID>
asc subscription-promotional-offers prices list  --offer-id <OFFER_ID>
```

`--price` is encoded inline using `${newPromoOfferPrice-N}` 1-based local IDs (matches the ASC web UI shape).

## Win-Back Offers (lapsed subscribers)

```bash
asc win-back-offers list --subscription-id <SUB_ID>

asc win-back-offers create --subscription-id <SUB_ID> \
  --reference-name "Lapsed Q4" --offer-id lapsedQ4 \
  --duration ONE_MONTH --mode FREE_TRIAL --periods 1 \
  --paid-months 3 --since-min 1 --since-max 6 --wait-months 2 \
  --start-date 2026-04-01 --end-date 2026-12-31 \
  --priority HIGH --promotion-intent USE_AUTO_GENERATED_ASSETS \
  [--price USA=spp-1 ...]

asc win-back-offers update --offer-id <OFFER_ID> \
  [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] \
  [--priority HIGH|NORMAL] [--promotion-intent NOT_PROMOTED|USE_AUTO_GENERATED_ASSETS] \
  [--paid-months <n>] [--since-min <n>] [--since-max <n>] [--wait-months <n>]

asc win-back-offers delete       --offer-id <OFFER_ID>
asc win-back-offers prices list  --offer-id <OFFER_ID>
```

Eligibility model: `--paid-months` (months as paid subscriber required), `--since-min..--since-max` (months since last subscribed range), `--wait-months` (gap between offers shown to the same customer). The win-back create body is encoded by hand because the generated SDK's `WinBackOfferPriceInlineCreate` is missing `territory` + `subscriptionPricePoint` relationships.

## Subscription Offer Codes (3-level hierarchy)

### Level 1 — offer code

```bash
asc subscription-offer-codes list   --subscription-id <SUB_ID>

asc subscription-offer-codes create --subscription-id <SUB_ID> \
  --name "SUMMER2026" \
  --duration ONE_MONTH --mode FREE_TRIAL --periods 1 \
  --eligibility NEW --eligibility LAPSED \
  --offer-eligibility STACKABLE \
  --price USA=spp-usa --price JPN=spp-jpn \
  --free-territory BRA \
  [--auto-renew true|false]

asc subscription-offer-codes update       --offer-code-id <OC> --active false
asc subscription-offer-codes prices list  --offer-code-id <OC>   # per-territory pricing (read-only)
```

**Pricing is set once, at creation** (`prices` is read-only after — see the IAP skill's note for details). Use `--auto-renew false` to create a non-renewing one-time offer; ASC only accepts `--mode FREE_TRIAL` in that case.

`--eligibility` (repeatable) ∈ `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`. `--offer-eligibility` ∈ `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`.

### Level 2 — custom redeemable codes

```bash
asc subscription-offer-code-custom-codes list   --offer-code-id <OC>
asc subscription-offer-code-custom-codes create --offer-code-id <OC> \
  --custom-code "SUMMER2026" --number-of-codes 1000 [--expiration-date 2026-12-31]
asc subscription-offer-code-custom-codes update --custom-code-id <CC> --active false
```

### Level 3 — one-time use code batches

```bash
asc subscription-offer-code-one-time-codes list   --offer-code-id <OC>
asc subscription-offer-code-one-time-codes create --offer-code-id <OC> \
  --number-of-codes 5000 --expiration-date 2026-12-31 [--environment production|sandbox]
asc subscription-offer-code-one-time-codes update --one-time-code-id <OTC> --active false

# Download the CSV of redemption codes (raw String — not JSON):
asc subscription-offer-code-one-time-codes values --one-time-code-id <OTC>
```

`--environment` defaults to `production`. Sandbox batches redeem against sandbox tester accounts (≈10,000/quarter ceiling); production batches against live accounts (≈150,000/quarter ceiling). Each `SubscriptionOfferCode` reports usage against both via `productionCodeCount` / `sandboxCodeCount`, and each one-time-use row carries its `environment` for filtering.

REST equivalents:

```bash
GET    /api/v1/subscription-offer-codes/{offerCodeId}/one-time-codes
POST   /api/v1/subscription-offer-codes/{offerCodeId}/one-time-codes   # body: {numberOfCodes, expirationDate, environment?}
PATCH  /api/v1/subscription-offer-code-one-time-codes/{oneTimeCodeId}  # body: {isActive: false}
```

## Subscription Review Screenshot (singleton)

```bash
asc subscription-review-screenshot get    --subscription-id <SUB_ID>          # empty data:[] when none
asc subscription-review-screenshot upload --subscription-id <SUB_ID> --file ./review.png
asc subscription-review-screenshot delete --screenshot-id <RS>                # suppressed while AWAITING_UPLOAD
```

Upload uses ASC's reserve → upload chunks → commit-with-MD5 protocol.

## CAEOAS Affordances

**SubscriptionGroup** advertises:
```json
{
  "affordances": {
    "createLocalization":  "asc subscription-group-localizations create --group-id <ID> --locale en-US --name <name>",
    "createSubscription":  "asc subscriptions create --group-id <ID> --name <name> --product-id <id> --period ONE_MONTH",
    "delete":              "asc subscription-groups delete --group-id <ID>",
    "listLocalizations":   "asc subscription-group-localizations list --group-id <ID>",
    "listSubscriptions":   "asc subscriptions list --group-id <ID>",
    "update":              "asc subscription-groups update --group-id <ID> --reference-name <name>"
  }
}
```

**Subscription** advertises (in addition to existing keys):
```json
{
  "createPromotionalOffer": "asc subscription-promotional-offers create --subscription-id <ID> ...",
  "delete":                 "asc subscriptions delete --subscription-id <ID>",
  "getReviewScreenshot":    "asc subscription-review-screenshot get --subscription-id <ID>",
  "listPromotionalOffers":  "asc subscription-promotional-offers list --subscription-id <ID>",
  "listWinBackOffers":      "asc win-back-offers list --subscription-id <ID>",
  "update":                 "asc subscriptions update --subscription-id <ID> --name <name>"
}
```

`submit` only when `state == READY_TO_SUBMIT`. `SubscriptionSubmission` advertises `unsubmit`. `SubscriptionLocalization` advertises `update` + `delete`. `SubscriptionGroupLocalization` advertises `update` + `delete`. `SubscriptionPricePoint` advertises `setPrice` only when `territory != nil`. `SubscriptionPromotionalOffer` advertises `delete` + `listPrices`. `WinBackOffer` advertises `update` + `delete` + `listPrices`. `SubscriptionReviewScreenshot` advertises `delete` only once `assetState.isComplete || hasFailed`. `*OfferCode*` custom & one-time codes advertise `deactivate` only when `isActive == true`.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')

# 1. Group + tier + group-localization
GROUP_ID=$(asc subscription-groups create --app-id "$APP_ID" --reference-name "Premium" \
  | jq -r '.data[0].id')
asc subscription-group-localizations create --group-id "$GROUP_ID" --locale en-US \
  --name "Premium Plans" --custom-app-name "Premium App"

SUB_ID=$(asc subscriptions create --group-id "$GROUP_ID" --name "Monthly Premium" \
  --product-id "com.app.monthly" --period ONE_MONTH | jq -r '.data[0].id')
asc subscription-localizations create --subscription-id "$SUB_ID" --locale en-US \
  --name "Monthly Premium" --description "Unlock everything"

# 2. Per-territory pricing
USA_PP=$(asc subscriptions price-points list --subscription-id "$SUB_ID" --territory USA \
  | jq -r '.data[] | select(.customerPrice == "9.99") | .id')
asc subscriptions prices set --subscription-id "$SUB_ID" --territory USA --price-point-id "$USA_PP"

# 3. Review screenshot + submit
asc subscription-review-screenshot upload --subscription-id "$SUB_ID" --file ./review.png
asc subscriptions submit --subscription-id "$SUB_ID"

# 4. Promotional offer with per-territory pricing
asc subscription-promotional-offers create --subscription-id "$SUB_ID" \
  --name "Loyalty25" --offer-code loyalty25 \
  --duration THREE_MONTHS --mode PAY_AS_YOU_GO --periods 3 \
  --price USA=$USA_PP

# 5. Win-back campaign
asc win-back-offers create --subscription-id "$SUB_ID" \
  --reference-name "Lapsed Q4" --offer-id lapsedQ4 \
  --duration ONE_MONTH --mode FREE_TRIAL --periods 1 \
  --paid-months 3 --since-min 1 --since-max 6 --wait-months 2 \
  --start-date 2026-04-01 --end-date 2026-12-31 \
  --priority HIGH --promotion-intent USE_AUTO_GENERATED_ASSETS

# 6. Offer code + one-time redemption batch
OC_ID=$(asc subscription-offer-codes create --subscription-id "$SUB_ID" \
  --name "SUMMER2026" --duration ONE_MONTH --mode FREE_TRIAL --periods 1 \
  --eligibility NEW --eligibility LAPSED --offer-eligibility STACKABLE \
  | jq -r '.data[0].id')
asc subscription-offer-code-one-time-codes create --offer-code-id "$OC_ID" \
  --number-of-codes 5000 --expiration-date 2026-12-31
# Distribute the codes:
asc subscription-offer-code-one-time-codes values --one-time-code-id <OTC_ID> > codes.csv
```

## State Semantics

`SubscriptionState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

`SubscriptionCustomerEligibility` ∈ `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`.
`SubscriptionOfferEligibility` ∈ `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`.
`WinBackOfferPriority` ∈ `HIGH`, `NORMAL`. `WinBackOfferPromotionIntent` ∈ `NOT_PROMOTED`, `USE_AUTO_GENERATED_ASSETS`.

`SubscriptionReviewScreenshot.AssetState` exposes `isComplete` and `hasFailed`.

Nil optional fields are omitted from JSON output. PATCH responses (update commands) return the resource with the parent id as `""` because ASC's PATCH responses don't include parent ids — refetch via `list` if you need the parent.

## Reference

For full domain-model and REST detail see [docs/features/iap-subscriptions.md](../../docs/features/iap-subscriptions.md) and the [iap-subscriptions/ subdocs](../../docs/features/iap-subscriptions/) (lifecycle, pricing, offer-codes, group-localizations, promotional-offers, win-back-offers, review-assets).
