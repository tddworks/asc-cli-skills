# Submitting in-app purchases and subscriptions with an app version

Apple reviews a **first-time** in-app purchase or subscription only together with an app version: `asc iap submit` / `asc subscriptions submit` on its own fails for them. Products have *review versions* (like app versions), and a review submission can carry the app version plus those product versions, so the whole thing is one submission. This works with the normal API key — no iris web session needed (requires asc with appstoreconnect-swift-sdk 4.4.3+, i.e. the release that added `versions submit --with-products`).

## When to use it

- The app has IAPs or subscriptions that have never been approved, and you're submitting an app version → use `--with-products`.
- Established products (already approved once) can still go alone with `asc iap submit` / `asc subscriptions submit`; `--with-products` also handles them if they're `READY_TO_SUBMIT`.

## One command

```bash
# 1. See exactly what would go to review — submits nothing
asc versions submit --version-id <VERSION_ID> --with-products --dry-run --output table

# 2. Submit the app version and every ready product together
asc versions submit --version-id <VERSION_ID> --with-products
```

What gets included: the app version first; every IAP in `READY_TO_SUBMIT` with a submittable version; for each subscription group with a `READY_TO_SUBMIT` subscription, the group's version then those subscriptions' versions. Products still `MISSING_METADATA` (no price, localization, or review screenshot) are left out — the dry run makes that visible, so check it lists every product the user expects before submitting. Submitting sends the app to App Review, so confirm with the user after showing the dry run.

## Step by step

Use this when you need control over which products go in:

```bash
asc iap versions list --iap-id <IAP_ID>                          # → version id + state
asc subscriptions versions list --subscription-id <SUB_ID>
asc subscription-groups versions list --group-id <GROUP_ID>     # first subscription in a group needs the group too

SUB=$(asc review-submissions create --app-id <APP_ID> | jq -r '.data[0].id')   # reuses the open draft
asc review-submissions items add --submission-id $SUB --version-id <VERSION_ID>
asc review-submissions items add --submission-id $SUB --subscription-group-version-id <ID>
asc review-submissions items add --submission-id $SUB --subscription-version-id <ID>
asc review-submissions items add --submission-id $SUB --iap-version-id <ID>
asc review-submissions items list --submission-id $SUB --output table   # check before sending
asc review-submissions submit --submission-id $SUB
```

A version can be added while its state is `PREPARE_FOR_SUBMISSION`, `REJECTED` or `DEVELOPER_REJECTED` — those versions carry an `addToSubmission` affordance. `asc review-submissions items remove --item-id <ID>` takes an item back out before submitting. Apple keeps one open draft per app and platform and doesn't allow deleting it; `create` reuses it.

## When Apple refuses

Refusals list Apple's actual reasons:

```
Error: Apple refused the review submission: This resource cannot be reviewed, please check associated errors to see why.
  - A screenshot for one of the following types is required but was not provided: APP_IPAD_PRO_3GEN_129
  - You must provide a value for the attribute 'contentRightsDeclaration' with this request
  - You must have published answers to your app's data usages.
  - App is not eligible for submission until pricing has been set.
```

Relay each reason to the user as something to fix: content rights → `asc apps update --app-id <id> --content-rights-declaration <USES_THIRD_PARTY_CONTENT|DOES_NOT_USE_THIRD_PARTY_CONTENT>` (ask the user which is true — it's a legal declaration); app pricing → `asc apps price-points list --app-id <id>` then `asc apps prices set --app-id <id> --base-territory USA --price-point-id <id>` (ask the user the price; the `0.0` point makes it free); availability not set up → `asc app-availability create --app-id <id> --all-territories --available-in-new-territories`; **App Privacy data usages → App Store Connect web page** (App Privacy has no public API at all; the `/v1/appDataUsages` path in the error only works with a web session). `asc versions check-readiness` doesn't cover all of these yet (device screenshot sizes, content rights, App Privacy answers, app pricing), so a green readiness check can still be refused here. If the app version is refused, nothing was submitted; items already added stay in the draft.

REST (`asc web-server`): `POST /api/v1/versions/:id/submit?with-products=true&dry-run=true`, `GET /api/v1/{iap,subscriptions,subscription-groups}/:id/versions`, `POST /api/v1/apps/:appId/review-submissions`, `POST /api/v1/review-submissions/:id/items`, `DELETE /api/v1/review-submissions/items/:itemId`, `POST /api/v1/review-submissions/:id/submit`.
