---
name: asc-beta-review
description: |
  Manage beta app review submissions and review contact details for TestFlight external testing using the `asc` CLI tool.
  Use this skill when:
  (1) Submitting a build for beta app review: "asc beta-review submissions create --build-id ID"
  (2) Checking beta review submission status: "asc beta-review submissions list --build-id ID"
  (3) Getting a specific submission: "asc beta-review submissions get --submission-id ID"
  (4) Getting beta review contact details: "asc beta-review detail get --app-id ID"
  (5) Updating beta review contact info or demo account: "asc beta-review detail update --detail-id ID ..."
  (6) User says "submit for beta review", "TestFlight review", "beta review status",
      "beta review contact", "external testing review", or any beta app review task
---

# Beta App Review with `asc`

Submit builds for TestFlight external testing review and manage beta review contact details. Apple requires beta app review before distributing builds to external testers via TestFlight.

## Authentication

Set up credentials before any beta review commands:
```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## CAEOAS — Affordances Guide Next Steps

Every JSON response includes `"affordances"` with ready-to-run commands:

**BetaAppReviewSubmission affordances:**
```json
{
  "id": "sub-abc123",
  "buildId": "build-42",
  "state": "WAITING_FOR_REVIEW",
  "affordances": {
    "getSubmission": "asc beta-review submissions get --submission-id sub-abc123",
    "listSubmissions": "asc beta-review submissions list --build-id build-42"
  }
}
```

**BetaAppReviewDetail affordances:**
```json
{
  "id": "d-xyz789",
  "appId": "app-1",
  "contactFirstName": "John",
  "contactEmail": "john@example.com",
  "demoAccountRequired": false,
  "affordances": {
    "getDetail": "asc beta-review detail get --app-id app-1",
    "updateDetail": "asc beta-review detail update --detail-id d-xyz789"
  }
}
```

Nil optional fields (`contactFirstName`, `contactLastName`, `contactPhone`, `contactEmail`, `demoAccountName`, `demoAccountPassword`, `notes`) are omitted from JSON output.

## Commands

### submissions list — list beta review submissions for a build

```bash
asc beta-review submissions list --build-id <BUILD_ID> [--pretty]
```

### submissions create — submit a build for beta review

```bash
asc beta-review submissions create --build-id <BUILD_ID> [--pretty]
```

Creates a new beta app review submission. The build enters `WAITING_FOR_REVIEW` state.

### submissions get — get a specific submission

```bash
asc beta-review submissions get --submission-id <SUBMISSION_ID> [--pretty]
```

### detail get — get beta review contact details for an app

```bash
asc beta-review detail get --app-id <APP_ID> [--pretty]
```

Returns the beta app review detail record (contact info and demo account) for the app. Each app has one beta review detail record.

### detail update — update beta review contact details

```bash
asc beta-review detail update --detail-id <DETAIL_ID> \
  [--contact-first-name <name>] \
  [--contact-last-name <name>] \
  [--contact-phone <phone>] \
  [--contact-email <email>] \
  [--demo-account-name <username>] \
  [--demo-account-password <password>] \
  [--demo-account-required] \
  [--notes <text>]
```

Only supplied flags are sent — unspecified fields are left unchanged.

## BetaReviewState

| State | Description |
|-------|-------------|
| `WAITING_FOR_REVIEW` | Submitted, waiting for Apple review |
| `IN_REVIEW` | Currently being reviewed |
| `APPROVED` | Approved for external testing |
| `REJECTED` | Rejected — fix issues and resubmit |

Semantic booleans: `isPending`, `isInReview`, `isApproved`, `isRejected`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')

# 1. Upload a build
asc builds upload --file MyApp.ipa

# 2. Add the build to an external beta group
BUILD_ID=$(asc builds list --app-id "$APP_ID" | jq -r '.data[0].id')
GROUP_ID=$(asc testflight groups list --app-id "$APP_ID" | jq -r '.data[] | select(.isInternalGroup == false) | .id' | head -1)
asc builds add-beta-group --build-id "$BUILD_ID" --beta-group-id "$GROUP_ID"

# 3. Set up beta review contact details (first time)
asc beta-review detail get --app-id "$APP_ID" --pretty
DETAIL_ID=$(asc beta-review detail get --app-id "$APP_ID" | jq -r '.data[0].id')
asc beta-review detail update --detail-id "$DETAIL_ID" \
  --contact-first-name "John" \
  --contact-last-name "Doe" \
  --contact-email "john@example.com" \
  --contact-phone "+1-555-0100"

# 4. Submit the build for beta app review
asc beta-review submissions create --build-id "$BUILD_ID" --pretty

# 5. Check submission status
asc beta-review submissions list --build-id "$BUILD_ID" --pretty
```

## Key Computed Properties (BetaAppReviewDetail)

| Property | Logic |
|----------|-------|
| `hasContact` | `contactEmail != nil && contactPhone != nil` |
| `demoAccountConfigured` | `!demoAccountRequired \|\| (name != nil && password != nil)` |

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Output Flags

```bash
--pretty          # Pretty-print JSON
--output table    # Table format
--output markdown # Markdown table
```