# asc users & user-invitations — Full Command Reference

## asc users list

List all App Store Connect team members, optionally filtered by role.

```bash
asc users list [--role <ROLE>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--role` | String | *(optional)* | Filter by role (uppercase, e.g. `ADMIN`, `DEVELOPER`) |
| `--output` | String | `json` | `json` \| `table` \| `markdown` |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Username · Name · Roles · All Apps

**Example:**
```bash
asc users list --pretty
asc users list --role DEVELOPER --output table
```

---

## asc users update

Replace a team member's roles. This **replaces all current roles** — include every role you want the member to keep.

```bash
asc users update --user-id <USER_ID> --role <ROLE> [--role <ROLE> ...] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--user-id` | String | *(required)* | User resource ID |
| `--role` | String | *(required, repeatable)* | Role to assign. Repeat for multiple roles |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Example:**
```bash
# Grant App Manager + Developer (replaces whatever they had before)
asc users update --user-id u-abc123 --role APP_MANAGER --role DEVELOPER
```

**Tip:** The `updateRoles` affordance in `asc users list` output is pre-filled with the member's current roles — a convenient starting point for modifications.

---

## asc users remove

Revoke a team member's access to App Store Connect immediately.

```bash
asc users remove --user-id <USER_ID>
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--user-id` | String | *(required)* | User resource ID |

**Output:** No output on success (returns exit code 0).

**Tip:** Get `--user-id` from the `"remove"` affordance in `asc users list` output, or by filtering by username:
```bash
asc users list | jq -r '.data[] | select(.username == "user@example.com") | .id'
```

---

## asc user-invitations list

List pending (not yet accepted) team invitations.

```bash
asc user-invitations list [--role <ROLE>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--role` | String | *(optional)* | Filter by role (e.g. `ADMIN`, `DEVELOPER`) |
| `--output` | String | `json` | `json` \| `table` \| `markdown` |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Email · Name · Roles · All Apps

**Note:** Only shows invitations that haven't been accepted yet. Accepted invitations appear in `asc users list`.

---

## asc user-invitations invite

Send an invitation email to join App Store Connect.

```bash
asc user-invitations invite \
  --email <EMAIL> \
  --first-name <NAME> \
  --last-name <NAME> \
  --role <ROLE> [--role <ROLE> ...] \
  [--all-apps-visible] \
  [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--email` | String | *(required)* | Invitee's email address |
| `--first-name` | String | *(required)* | Invitee's first name |
| `--last-name` | String | *(required)* | Invitee's last name |
| `--role` | String | *(required, repeatable)* | Role to assign on acceptance. Repeat for multiple |
| `--all-apps-visible` | Flag | `false` | When set, grants access to all apps (current and future) |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Output:** JSON with the new `UserInvitationRecord` including the `cancel` affordance.

**Example:**
```bash
asc user-invitations invite \
  --email new-hire@example.com \
  --first-name Alex \
  --last-name Smith \
  --role DEVELOPER \
  --role APP_MANAGER \
  --pretty
```

---

## asc user-invitations cancel

Cancel a pending invitation. The invitee will no longer be able to accept it.

```bash
asc user-invitations cancel --invitation-id <INVITATION_ID>
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--invitation-id` | String | *(required)* | User invitation resource ID |

**Output:** No output on success (returns exit code 0).

**Tip:** Get `--invitation-id` from the `"cancel"` affordance in `asc user-invitations list` output.

---

## Available Roles

| Display Name | Raw value (use with `--role`) |
|---|---|
| Admin | `ADMIN` |
| Finance | `FINANCE` |
| Account Holder | `ACCOUNT_HOLDER` |
| Sales | `SALES` |
| Marketing | `MARKETING` |
| App Manager | `APP_MANAGER` |
| Developer | `DEVELOPER` |
| Access to Reports | `ACCESS_TO_REPORTS` |
| Customer Support | `CUSTOMER_SUPPORT` |
| Create Apps | `CREATE_APPS` |
| Cloud Managed Developer ID | `CLOUD_MANAGED_DEVELOPER_ID` |
| Cloud Managed App Distribution | `CLOUD_MANAGED_APP_DISTRIBUTION` |
| Generate Individual Keys | `GENERATE_INDIVIDUAL_KEYS` |