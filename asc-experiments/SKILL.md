---
name: asc-experiments
description: |
  Manage App Store Product Page Optimization tests (A/B tests of icons, screenshots and previews) using the `asc` CLI.
  Use this skill whenever the user mentions product page optimization, PPO, A/B testing an app icon or screenshots,
  "treatments", "test my product page", "conversion test on the App Store", or the App Store Connect API's
  appStoreVersionExperiments — even if they don't say "experiment". Covers:
  (1) Listing / inspecting tests: "asc experiments list --app-id ID [--state STATE]", "asc experiments get --experiment-id ID"
  (2) Creating a test: "asc experiments create --app-id ID --name NAME --traffic-proportion 1-100 [--platform ios]"
  (3) Adding up to three treatments: "asc experiment-treatments create --experiment-id ID --name NAME [--app-icon-name ASSET]"
  (4) Choosing locales per treatment: "asc experiment-treatment-localizations create --treatment-id ID --locale en-US"
  (5) Running it: "asc experiments start|stop --experiment-id ID"
---

# asc Experiments (Product Page Optimization)

A **Product Page Optimization test** shows a share of App Store visitors one of up to three alternate product pages ("treatments") instead of the original, so you can measure which converts better. Apple's API calls these `appStoreVersionExperiments`; the CLI calls them `experiments`.

Hierarchy: `App → experiment → experiment-treatment → experiment-treatment-localization`.

Preconditions Apple enforces (the CLI surfaces them as 409 errors — don't retry, explain them):

- The app must have a version in **READY_FOR_DISTRIBUTION** (or pre-order ready) on the target platform. Otherwise `create` fails with `STATE_ERROR.PPO_CREATE_ONLY_ALLOWED_WITH_APP_STORE_DISTRIBUTION`. Check with `asc versions list --app-id <id>` first.
- A test runs for at most 90 days or until stopped.
- More treatments → longer to reach significance; `--traffic-proportion` is split evenly across treatments (30% with three treatments = 10% each).

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## List / inspect

```bash
asc experiments list --app-id <APP_ID> [--state APPROVED] [--limit N] [--pretty]
asc experiments list --app-id <APP_ID> --output table
asc experiments get --experiment-id <EXP_ID>
```

`--state` accepts any raw state value (case-insensitive): `PREPARE_FOR_SUBMISSION`, `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `ACCEPTED`, `APPROVED`, `REJECTED`, `COMPLETED`, `STOPPED`.

## Create a test

```bash
asc experiments create --app-id <APP_ID> --name "Icon test" --traffic-proportion 30 [--platform ios|macos|tvos|visionos]
```

`--name` is the reference name shown in App Analytics. `--traffic-proportion` is validated to 1–100 before the request is sent. Platform defaults to `ios`.

## Add treatments (max three)

```bash
asc experiment-treatments list   --experiment-id <EXP_ID>
asc experiment-treatments create --experiment-id <EXP_ID> --name "Blue icon" [--app-icon-name AppIcon-Blue]
asc experiment-treatments update --treatment-id <TRT_ID> [--name NAME] [--app-icon-name ASSET]
asc experiment-treatments delete --treatment-id <TRT_ID>
```

`--app-icon-name` is the name of an alternate icon asset bundled in the app — the way to A/B test icons. Screenshot / preview sets for a treatment hang off its localizations (not yet exposed by the CLI; see the doc's "Extending" section).

## Choose locales per treatment

```bash
asc experiment-treatment-localizations list   --treatment-id <TRT_ID>
asc experiment-treatment-localizations create --treatment-id <TRT_ID> --locale en-US
asc experiment-treatment-localizations delete --localization-id <LOC_ID>
```

Users whose storefront locale isn't included in the treatment are excluded from the test.

## Update, start, stop, delete

```bash
asc experiments update --experiment-id <EXP_ID> [--name NAME] [--traffic-proportion N]   # at least one flag
asc experiments start  --experiment-id <EXP_ID>   # only once approved (state ACCEPTED/APPROVED)
asc experiments stop   --experiment-id <EXP_ID>   # ends a running test
asc experiments delete --experiment-id <EXP_ID>
```

`start`/`stop` both go through `PATCH /v2/appStoreVersionExperiments/{id}` with `started: true|false`.

## State semantics

`AppStoreVersionExperimentState` exposes semantic booleans; the model adds two more from dates:

| Boolean | True when |
|---|---|
| `state.isEditable` | `PREPARE_FOR_SUBMISSION`, `READY_FOR_REVIEW`, `REJECTED` |
| `state.isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `state.isApproved` | `ACCEPTED`, `APPROVED` |
| `state.isFinished` | `COMPLETED`, `STOPPED` |
| `canStart` (in JSON) | approved and `startDate` is nil |
| `isRunning` (in JSON) | approved, `startDate` set, `endDate` nil |

## State-aware affordances

Follow the `affordances` in the JSON output rather than guessing what's legal next — mutations Apple would reject are simply not offered:

| Situation | Offered |
|---|---|
| editable (`isEditable`) | `createTreatment`, `update`, `delete` |
| approved, not started (`canStart`) | `start` |
| running (`isRunning`) | `stop` |
| in review / finished | only `listSiblings`, `listTreatments` |

```json
{
  "affordances": {
    "listSiblings":    "asc experiments list --app-id <APP_ID>",
    "listTreatments":  "asc experiment-treatments list --experiment-id <ID>",
    "createTreatment": "asc experiment-treatments create --experiment-id <ID> --name <name>",  // editable only
    "update":          "asc experiments update --experiment-id <ID>",                          // editable only
    "delete":          "asc experiments delete --experiment-id <ID>",                          // editable only
    "start":           "asc experiments start --experiment-id <ID>",                           // canStart only
    "stop":            "asc experiments stop --experiment-id <ID>"                             // isRunning only
  }
}
```

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')

# 0. Confirm a live version exists (otherwise create is rejected)
asc versions list --app-id "$APP_ID" --output table

# 1. Create the test
EXP_ID=$(asc experiments create --app-id "$APP_ID" --name "Icon test" --traffic-proportion 30 \
  | jq -r '.data[0].id')

# 2. Add a treatment with an alternate icon, and the locales it applies to
TRT_ID=$(asc experiment-treatments create --experiment-id "$EXP_ID" --name "Blue icon" --app-icon-name AppIcon-Blue \
  | jq -r '.data[0].id')
asc experiment-treatment-localizations create --treatment-id "$TRT_ID" --locale en-US

# 3. Submit for review (review-submissions), then poll until canStart is true
asc experiments get --experiment-id "$EXP_ID" | jq '.data[0] | {state, canStart, isRunning}'

# 4. Run it; stop once you have a winner
asc experiments start --experiment-id "$EXP_ID"
asc experiments stop  --experiment-id "$EXP_ID"
```

## REST

Every command is also served by `asc web-server`: `GET/POST /api/v1/apps/:appId/experiments`, `GET/PATCH/DELETE /api/v1/experiments/:id`, `POST /api/v1/experiments/:id/start|stop`, `GET/POST /api/v1/experiments/:id/experiment-treatments`, `PATCH/DELETE /api/v1/experiment-treatments/:id`, `GET/POST /api/v1/experiment-treatments/:id/experiment-treatment-localizations`, `DELETE /api/v1/experiment-treatment-localizations/:id`. Query params match CLI flags (`?state=&limit=`).

## Reference

For full domain-model, REST and architecture detail see [docs/features/product-page-optimization.md](../../docs/features/product-page-optimization.md).
