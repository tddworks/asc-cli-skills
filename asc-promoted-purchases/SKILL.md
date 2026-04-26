---
name: asc-promoted-purchases
description: |
  Manage App Store product page promoted purchase slots using the `asc` CLI tool.
  Use this skill when:
  (1) Listing slots: "asc promoted-purchases list --app-id ID"
  (2) Promoting an IAP or subscription: "asc promoted-purchases create --app-id ID (--iap-id ID | --subscription-id ID)"
  (3) Updating visibility / enabled state: "asc promoted-purchases update --promoted-id ID --visible|--hidden --enabled|--disabled"
  (4) Deleting a slot: "asc promoted-purchases delete --promoted-id ID"
  (5) User says "promoted purchase", "promoted IAP", "feature on App Store", "App Store product page promotion", "promoted slot"
---

# asc Promoted Purchases

Manage App Store product page **Promoted In-App Purchases** — the featured IAPs / auto-renewable subscriptions surfaced under an app's product page on the App Store. Each slot promotes either an IAP or a subscription (mutually exclusive) and goes through App Review separately from the underlying product.

## List

```bash
asc promoted-purchases list --app-id <APP_ID> [--limit N] [--pretty]
```

## Create

Exactly one of `--iap-id` or `--subscription-id` is required (the command validates and rejects both/neither):

```bash
# Promote an in-app purchase
asc promoted-purchases create --app-id <APP_ID> --iap-id <IAP_ID> --visible --enabled

# Promote an auto-renewable subscription
asc promoted-purchases create --app-id <APP_ID> --subscription-id <SUB_ID> --hidden --disabled
```

`--visible` / `--hidden` flip `isVisibleForAllUsers`. `--enabled` / `--disabled` flip `isEnabled`. Defaults: `isVisibleForAllUsers=true`, `isEnabled` left unchanged when both flags omitted.

## Update

```bash
asc promoted-purchases update --promoted-id <PROMOTED_ID> [--visible | --hidden] [--enabled | --disabled]
```

Omitting a flag pair leaves that field unchanged.

## Delete

```bash
asc promoted-purchases delete --promoted-id <PROMOTED_ID>
```

## State semantics

`PromotedPurchaseState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isLocked` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` | `APPROVED` |

## State-aware affordances

JSON responses suppress mutations that ASC would reject as 409 conflicts:

| State | `update` link | `delete` link |
|-------|---------------|---------------|
| `approved` / `rejected` / `prepareForSubmission` / `developerActionNeeded` | shown | shown |
| `waitingForReview` / `inReview` (i.e. `state.isLocked`) | **suppressed** | **suppressed** |

```json
{
  "affordances": {
    "listSiblings": "asc promoted-purchases list --app-id <APP_ID>",
    "update":       "asc promoted-purchases update --promoted-id <ID>",   // omitted while in review
    "delete":       "asc promoted-purchases delete --promoted-id <ID>"    // omitted while in review
  }
}
```

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')

# Promote an IAP, visible to all users, slot enabled.
PROMO_ID=$(asc promoted-purchases create --app-id "$APP_ID" \
  --iap-id "iap-1" --visible --enabled \
  | jq -r '.data[0].id')

# Later: hide it temporarily without deleting
asc promoted-purchases update --promoted-id "$PROMO_ID" --hidden

# Or just remove the slot
asc promoted-purchases delete --promoted-id "$PROMO_ID"
```

## Reference

For full domain-model and REST detail see [docs/features/promoted-purchases.md](../../docs/features/promoted-purchases.md).
