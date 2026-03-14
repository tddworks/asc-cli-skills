---
name: asc-users
description: |
  Manage App Store Connect team members and user invitations using the `asc` CLI tool.
  Use this skill when:
  (1) Listing team members with their roles (`asc users list`)
  (2) Filtering members by role (`asc users list --role DEVELOPER`)
  (3) Updating or replacing a member's roles (asc users update --user-id ID --role ADMIN)
  (4) Revoking or removing access for a departing employee (asc users remove --user-id ID)
  (5) Listing pending invitations (asc user-invitations list)
  (6) Inviting a new team member by email (asc user-invitations invite)
  (7) Cancelling a pending invitation (asc user-invitations cancel)
  (8) User says "revoke access", "remove team member", "offboard user", "invite developer",
      "add someone to App Store Connect", "manage team roles", "who has admin access",
      "grant access", "onboard", or any team/user management task in App Store Connect
---

# Team Members & Invitations with `asc`

Manage your App Store Connect team: list members, assign roles, revoke access, and control pending invitations. Built for directory integration and automated access workflows.

## Authentication

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## CAEOAS — Affordances Guide Next Steps

Every JSON response includes `"affordances"` — ready-to-run commands with IDs pre-filled:

**TeamMember affordances:**
```json
{
  "id": "u-abc123",
  "username": "jdoe@example.com",
  "roles": ["DEVELOPER", "APP_MANAGER"],
  "affordances": {
    "remove":      "asc users remove --user-id u-abc123",
    "updateRoles": "asc users update --user-id u-abc123 --role DEVELOPER --role APP_MANAGER"
  }
}
```

**UserInvitationRecord affordances:**
```json
{
  "id": "inv-xyz789",
  "email": "new@example.com",
  "roles": ["DEVELOPER"],
  "affordances": {
    "cancel": "asc user-invitations cancel --invitation-id inv-xyz789"
  }
}
```

## Available Roles

Use uppercase values with `--role`:

`ADMIN` · `FINANCE` · `ACCOUNT_HOLDER` · `SALES` · `MARKETING` · `APP_MANAGER` · `DEVELOPER` · `ACCESS_TO_REPORTS` · `CUSTOMER_SUPPORT` · `CREATE_APPS` · `CLOUD_MANAGED_DEVELOPER_ID` · `CLOUD_MANAGED_APP_DISTRIBUTION` · `GENERATE_INDIVIDUAL_KEYS`

## Typical Workflows

### Offboard a departing employee

```bash
DEPARTED_EMAIL="former@example.com"

# Check for an active team member
USER_ID=$(asc users list | jq -r --arg e "$DEPARTED_EMAIL" \
  '.data[] | select(.username == $e) | .id')

if [ -n "$USER_ID" ]; then
  asc users remove --user-id "$USER_ID"
  echo "Access revoked."
else
  # Check for a pending invitation that hasn't been accepted yet
  INV_ID=$(asc user-invitations list | jq -r --arg e "$DEPARTED_EMAIL" \
    '.data[] | select(.email == $e) | .id')
  [ -n "$INV_ID" ] && asc user-invitations cancel --invitation-id "$INV_ID"
fi
```

### Onboard a new developer

```bash
asc user-invitations invite \
  --email new-hire@example.com \
  --first-name Alex \
  --last-name Smith \
  --role DEVELOPER
```

### Promote a developer to App Manager

```bash
# Get the user's ID first
USER_ID=$(asc users list | jq -r '.data[] | select(.username == "dev@example.com") | .id')

# Update replaces all roles — include every role you want them to keep
asc users update --user-id "$USER_ID" --role APP_MANAGER --role DEVELOPER
```

### Audit: list all admins

```bash
asc users list --role ADMIN --output table
```

## Output Flags

```bash
--pretty          # Pretty-print JSON
--output table    # Aligned table
--output markdown # Markdown table
```

## Full Command Reference

See [commands.md](references/commands.md) for all flags, filters, and examples.