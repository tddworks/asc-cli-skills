---
name: asc-skills
description: |
  Manage Claude Code agent skills using the `asc` CLI tool.
  Use this skill when:
  (1) Listing available skills: "asc skills list", "what skills are available", "show me asc skills"
  (2) Installing skills: "asc skills install --name asc-cli", "install all skills", "add asc skills to my agent"
  (3) Viewing installed skills: "asc skills installed", "what skills do I have", "show my installed skills"
  (4) Removing a skill: "asc skills uninstall --name asc-auth", "remove a skill"
  (5) Checking for skill updates: "asc skills check", "are my skills up to date"
  (6) Updating skills: "asc skills update", "update my asc skills"
  (7) User asks "how do I install asc skills", "set up asc CLI skills", or "get the latest asc skills"
  (8) Troubleshooting skill installation or update issues (npx, skills CLI)
---

# asc skills

Browse, install, and manage Claude Code agent skills from the `tddworks/asc-cli-skills` repository. Skills extend your agent with specialized knowledge about App Store Connect workflows — screenshots, TestFlight, code signing, subscriptions, and more.

## Commands

### list — show available skills from the repository

```bash
asc skills list
```

Lists all skills available for installation from `tddworks/asc-cli-skills`. Delegates to `npx skills add tddworks/asc-cli-skills --list`.

### install — install skills into your agent

```bash
asc skills install --name asc-cli        # install a specific skill
asc skills install --all                 # install all available skills
asc skills install                       # same as --all (default)
```

Delegates to `npx --yes skills add tddworks/asc-cli-skills`. Skills are installed to `~/.claude/skills/`.

| Flag | Purpose |
|------|---------|
| `--name <name>` | Install a specific skill by name |
| `--all` | Install all available skills |

### installed — show what's installed locally

```bash
asc skills installed [--pretty]
```

Reads `~/.claude/skills/`, parses each skill's SKILL.md frontmatter, and returns structured JSON with CAEOAS affordances.

### uninstall — remove an installed skill

```bash
asc skills uninstall --name <name>
```

Removes the skill directory from `~/.claude/skills/`.

### check — check for skill updates

```bash
asc skills check
```

Delegates to `npx skills check`. Returns one of:
- "All skills are up to date."
- "Skill updates are available. Run 'asc skills update' to refresh installed skills."
- "Skills CLI is not available. Install with: npm install -g skills"

### update — update installed skills

```bash
asc skills update
```

Delegates to `npx skills update` to pull the latest versions.

## Typical Workflow

```bash
# First time: install all asc skills
asc skills install --all

# Browse what's available
asc skills list

# Check what you have
asc skills installed --pretty

# Periodically check for updates
asc skills check

# Update when available
asc skills update

# Remove a skill you don't need
asc skills uninstall --name asc-game-center
```

## Auto-Update Checker

A non-blocking update check runs automatically on every `asc` command. It never interrupts normal CLI flow — failures are silently swallowed.

### Guard rails (skip check when any hit)

| Condition | Action |
|-----------|--------|
| `ASC_SKIP_SKILL_CHECK=true` env var | Skip |
| `CI` or `CONTINUOUS_INTEGRATION` env var set | Skip |
| Last check was less than 24 hours ago | Skip |

### How it works

1. Runs `npx skills check` (offline mode for passive checks)
2. Parses stdout: looks for "update(s) available" vs "up to date" / "no update"
3. If updates found → prints hint to stderr: `Skill updates available. Run 'asc skills update' to refresh installed skills.`
4. Saves `skillsCheckedAt` timestamp to `~/.asc/skills-config.json`

Timestamp is only persisted on success — if the skills CLI is unavailable, it retries next time.

## JSON Output

### `asc skills installed --pretty`

```json
{
  "data": [
    {
      "affordances": {
        "listSkills": "asc skills list",
        "uninstall": "asc skills uninstall --name asc-cli"
      },
      "description": "App Store Connect CLI skill",
      "id": "asc-cli",
      "isInstalled": true,
      "name": "asc-cli"
    }
  ]
}
```

Installed skills show an `uninstall` affordance. Not-yet-installed skills show an `install` affordance instead.

## Skill Storage

```
~/.claude/skills/
├── asc-cli/
│   ├── SKILL.md
│   └── references/
├── asc-auth/
│   └── SKILL.md
└── asc-testflight/
    ├── SKILL.md
    └── references/

~/.asc/skills-config.json          ← auto-update checker state
```

## Disabling Auto-Update Check

```bash
export ASC_NO_UPDATE_CHECK=1   # any value, presence-based
```

## See Also

- Full feature doc: `docs/features/skills.md`
- Skills source repository: `tddworks/asc-cli-skills`
- CAEOAS: follow `affordances.listSkills` from any `asc skills installed` response
