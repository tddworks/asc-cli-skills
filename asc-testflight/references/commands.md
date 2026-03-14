# asc testflight — Full Command Reference

## asc testflight groups list

List beta groups, optionally filtered by app.

```bash
asc testflight groups list [--app-id <APP_ID>] [--limit <N>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--app-id` | String | *(optional)* | Filter by app ID |
| `--limit` | Int | *(optional)* | Max groups to return |
| `--output` | String | `json` | `json` \| `table` \| `markdown` |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Name · Internal · Public Link

---

## asc testflight testers list

List all testers in a specific beta group.

```bash
asc testflight testers list --group-id <GROUP_ID> [--limit <N>] [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--group-id` | String | *(required)* | Beta group ID |
| `--limit` | Int | *(optional)* | Max testers to return |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Table output columns:** ID · Name · Email · Invite Type

---

## asc testflight testers add

Invite a tester by email and add them directly to the group.

```bash
asc testflight testers add \
  --group-id <GROUP_ID> \
  --email <EMAIL> \
  [--first-name <NAME>] \
  [--last-name <NAME>] \
  [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--group-id` | String | *(required)* | Beta group ID |
| `--email` | String | *(required)* | Tester email |
| `--first-name` | String | *(optional)* | Tester first name |
| `--last-name` | String | *(optional)* | Tester last name |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**Output:** JSON with the created tester and affordances.

---

## asc testflight testers remove

Remove a tester from a group (does not delete their TestFlight account).

```bash
asc testflight testers remove --group-id <GROUP_ID> --tester-id <TESTER_ID>
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--group-id` | String | *(required)* | Beta group ID |
| `--tester-id` | String | *(required)* | Tester ID |

**Output:** Plain confirmation string.

**Tip:** Get `--tester-id` from the `"remove"` affordance in `testers list` output.

---

## asc testflight testers import

Bulk-add testers from a CSV file. Calls `POST /v1/betaTesters` for each row.

```bash
asc testflight testers import \
  --group-id <GROUP_ID> \
  --file <PATH_TO_CSV> \
  [--pretty] [--output <FORMAT>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--group-id` | String | *(required)* | Beta group ID |
| `--file` | String | *(required)* | Path to CSV file |
| `--output` | String | `json` | Output format |
| `--pretty` | Bool | `false` | Pretty-print JSON |

**CSV format** (header row required):
```
email,firstName,lastName
jane@example.com,Jane,Doe
john@example.com,John,
```

**Output:** JSON array of all added testers with affordances.

---

## asc testflight testers export

Export all testers in a group as CSV (compatible with `import`).

```bash
asc testflight testers export --group-id <GROUP_ID> [--limit <N>]
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--group-id` | String | *(required)* | Beta group ID |
| `--limit` | Int | *(optional)* | Max testers to export |

**Output:** CSV to stdout. Redirect to file: `asc testflight testers export --group-id g-1 > testers.csv`

**Note:** The `--output` and `--pretty` flags are NOT used — export always outputs CSV.