---
name: asc-availability
description: |
  Manage app, IAP, and subscription territory availability with the `asc` CLI.
  Use this for `asc territories list`, `asc app-availability get`, `asc iap-availability get|create`,
  and `asc subscription-availability get|create`. Trigger on requests about app/IAP/subscription
  availability, which countries or markets are enabled, blocked territory/content status, pre-order
  territory status, enabling new territories, or restricting sales to specific regions.
---

# App, IAP & Subscription Territory Availability

Manage which App Store territories (countries/regions) an app, in-app purchase, or subscription is available in. This is essential for controlling regional distribution — for example, understanding why your app is blocked in certain countries, restricting a subscription to specific markets, or making an IAP available worldwide.

## App Availability (Per-Territory Status)

The richest availability view — shows every territory with `isAvailable` (true/false), blocking reasons via `contentStatuses`, `releaseDate`, and `isPreOrderEnabled`.

```bash
asc app-availability get --app-id <APP_ID> [--pretty]
```

This returns all ~175 territories with their status. Key `contentStatuses` values:
- `AVAILABLE` — selling normally
- `CANNOT_SELL_RESTRICTED_RATING` — age rating blocks sale in this territory
- `MISSING_RATING` — no age rating configured
- `ICP_NUMBER_MISSING` — China requires ICP number
- `BRAZIL_REQUIRED_TAX_ID` — Brazil requires tax ID
- `CANNOT_SELL_GAMBLING` / `CANNOT_SELL_CASINO` — gambling restrictions
- 30+ more specific blocking reasons

## List All Territories

Before setting availability, discover valid territory IDs. Apple has ~175 territories, each with an ISO-style ID (e.g. `USA`, `CHN`, `JPN`) and a currency code.

```bash
asc territories list [--output table] [--pretty]
```

Example output:
```
ID    Currency
USA   USD
CHN   CNY
JPN   JPY
GBR   GBP
DEU   EUR
...
```

## IAP Availability

### Get Current IAP Availability

Check which territories an IAP is currently available in. The response includes each territory's currency code.

```bash
asc iap-availability get --iap-id <IAP_ID> [--pretty]
```

Example JSON response:
```json
{
  "data": [
    {
      "id": "avail-1",
      "iapId": "iap-42",
      "isAvailableInNewTerritories": true,
      "territories": [
        { "id": "USA", "currency": "USD" },
        { "id": "CHN", "currency": "CNY" }
      ],
      "affordances": {
        "getAvailability": "asc iap-availability get --iap-id iap-42",
        "createAvailability": "asc iap-availability create --iap-id iap-42 ...",
        "listTerritories": "asc territories list"
      }
    }
  ]
}
```

### Create IAP Availability

Set which territories an IAP should be available in. Use `--territory` (repeatable) to specify each territory ID, and `--available-in-new-territories` to automatically include any new territories Apple adds in the future.

```bash
asc iap-availability create \
  --iap-id <IAP_ID> \
  --available-in-new-territories \
  --territory USA \
  --territory CHN \
  --territory JPN
```

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | Yes | IAP ID to set availability for |
| `--available-in-new-territories` | No | Auto-include new territories Apple adds |
| `--territory` | No | Territory ID (repeatable). Use `asc territories list` to find valid IDs |

## Subscription Availability

### Get Current Subscription Availability

```bash
asc subscription-availability get --subscription-id <SUB_ID> [--pretty]
```

### Create Subscription Availability

```bash
asc subscription-availability create \
  --subscription-id <SUB_ID> \
  --available-in-new-territories \
  --territory USA \
  --territory GBR
```

| Flag | Required | Description |
|------|----------|-------------|
| `--subscription-id` | Yes | Subscription ID to set availability for |
| `--available-in-new-territories` | No | Auto-include new territories Apple adds |
| `--territory` | No | Territory ID (repeatable) |

## CAEOAS Affordances

Every availability response includes ready-to-run follow-up commands:

```json
{
  "affordances": {
    "getAvailability": "asc iap-availability get --iap-id <ID>",
    "createAvailability": "asc iap-availability create --iap-id <ID> ...",
    "listTerritories": "asc territories list"
  }
}
```

The `InAppPurchase` and `Subscription` models also include a `getAvailability` affordance for navigation from the parent resource.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')

# 1. Discover territories
asc territories list --output table

# 2. List IAPs for the app
asc iap list --app-id "$APP_ID"

# 3. Check current availability
asc iap-availability get --iap-id "$IAP_ID" --pretty

# 4. Set availability to specific territories with auto-include for future ones
asc iap-availability create --iap-id "$IAP_ID" \
  --available-in-new-territories \
  --territory USA --territory GBR --territory DEU --territory JPN

# Same flow for subscriptions:
asc subscriptions list --group-id "$GROUP_ID"
asc subscription-availability get --subscription-id "$SUB_ID"
asc subscription-availability create --subscription-id "$SUB_ID" \
  --available-in-new-territories \
  --territory USA --territory CHN
```

## Key Concepts

- **Territory ID**: ISO-style country code used by App Store Connect (e.g. `USA`, `CHN`, `JPN`, `GBR`). Use `asc territories list` to see all valid IDs.
- **`isAvailableInNewTerritories`**: When `true`, Apple automatically makes the IAP/subscription available in any new territory they add. Recommended for most apps unless you need tight regional control.
- **Currency**: Each territory has an associated currency (e.g. `USD`, `CNY`). Shown alongside territory IDs in availability responses so you know the pricing context.
