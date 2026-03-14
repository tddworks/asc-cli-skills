---
name: asc-customer-reviews
description: |
  Manage customer reviews and developer responses using the `asc` CLI tool.
  Use this skill when:
  (1) Listing customer reviews for an app: "asc reviews list --app-id <id>"
  (2) Getting a specific review: "asc reviews get --review-id <id>"
  (3) Getting the response to a review: "asc review-responses get --review-id <id>"
  (4) Creating a response to a review: "asc review-responses create --review-id <id> --response-body <text>"
  (5) Deleting a response: "asc review-responses delete --response-id <id>"
  (6) User says "list reviews", "respond to review", "delete response", "check customer feedback",
      "reply to App Store review", or any customer review management task
---

# Customer Reviews & Review Responses with `asc`

Read customer reviews left on your App Store listing and manage developer responses — reply to feedback, revise responses, or delete them.

## Authentication

Set up credentials before any review commands:
```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## CAEOAS — Affordances Guide Next Steps

Every JSON response includes `"affordances"` with ready-to-run commands:

**CustomerReview affordances:**
```json
{
  "id": "rev-001",
  "appId": "123456789",
  "rating": 5,
  "title": "Great app!",
  "body": "Love using this app every day.",
  "reviewerNickname": "user123",
  "territory": "USA",
  "affordances": {
    "getResponse": "asc review-responses get --review-id rev-001",
    "respond": "asc review-responses create --review-id rev-001 --response-body \"\"",
    "listReviews": "asc reviews list --app-id 123456789"
  }
}
```

**CustomerReviewResponse affordances:**
```json
{
  "id": "resp-001",
  "reviewId": "rev-001",
  "responseBody": "Thank you for your feedback!",
  "state": "PUBLISHED",
  "affordances": {
    "delete": "asc review-responses delete --response-id resp-001",
    "getReview": "asc reviews get --review-id rev-001"
  }
}
```

Copy affordance commands directly — no need to look up IDs.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Commands

### reviews list — list all reviews for an app

```bash
asc reviews list --app-id <APP_ID> [--pretty] [--output table|markdown]
```

Returns reviews sorted by most recent first. Fields: `id`, `appId`, `rating` (1-5), `title?`, `body?`, `reviewerNickname?`, `createdDate?`, `territory?` (ISO 3166-1 alpha-3 code like "USA", "GBR").

Nil optional fields are omitted from JSON output.

### reviews get — get a single review

```bash
asc reviews get --review-id <REVIEW_ID> [--pretty]
```

Note: `appId` will be empty (`""`) because the single-GET API endpoint doesn't return the parent app ID.

### review-responses get — get the response to a review

```bash
asc review-responses get --review-id <REVIEW_ID> [--pretty]
```

Uses the review ID (not the response ID) to fetch the linked response.

### review-responses create — respond to a review

```bash
asc review-responses create --review-id <REVIEW_ID> --response-body "Thank you for your feedback!"
```

New responses start in `PENDING_PUBLISH` state — they go live within ~24 hours.

### review-responses delete — delete a response

```bash
asc review-responses delete --response-id <RESPONSE_ID>
```

To revise a response, delete the existing one and create a new one.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')
# If empty: ask user or run `asc apps list | jq -r '.data[0].id'`

# 1. List reviews for the app
asc reviews list --app-id "$APP_ID" --output table

# 2. Read a specific review in detail
asc reviews get --review-id rev-001 --pretty

# 3. Check if there is already a response
asc review-responses get --review-id rev-001

# 4. Respond to the review
asc review-responses create \
  --review-id rev-001 \
  --response-body "Thank you! We fixed the crash in v2.1."

# 5. To revise, delete and recreate
asc review-responses delete --response-id resp-001
asc review-responses create \
  --review-id rev-001 \
  --response-body "Updated response with more detail."
```

## Response State

| State | Meaning |
|-------|---------|
| `PUBLISHED` | Response is live on the App Store |
| `PENDING_PUBLISH` | Response submitted, awaiting publication (up to 24 hours) |

Semantic booleans: `isPublished`, `isPending`.

## Output Flags

```bash
--pretty          # Pretty-print JSON
--output table    # Table format
--output markdown # Markdown table
```
