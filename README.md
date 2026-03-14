# asc-cli-skills

Claude Code agent skills for the [asc CLI](https://github.com/tddworks/asc-cli) — App Store Connect from the command line.

Each skill teaches your agent how to use a specific `asc` command group, including flags, workflows, and output formats.

## Install

```bash
asc skills install --all
```

Or install a single skill:

```bash
asc skills install --name asc-testflight
```

## Skills

| Skill | Description |
|-------|-------------|
| [asc-app-clips](asc-app-clips/) | Manage App Clips and default experiences |
| [asc-app-infos](asc-app-infos/) | Manage app info and per-locale metadata (name, subtitle, categories) |
| [asc-app-previews](asc-app-previews/) | Manage app preview video sets and uploads |
| [asc-app-shots](asc-app-shots/) | Generate App Store screenshots (AI-powered or HTML-based) |
| [asc-app-wall](asc-app-wall/) | Submit an app to the community app wall at asccli.app |
| [asc-appstore-release](asc-appstore-release/) | GitHub Actions workflow for App Store releases |
| [asc-appstore-release-local](asc-appstore-release-local/) | Local release workflow: bump, archive, upload, submit |
| [asc-auth](asc-auth/) | Authentication and multi-account management |
| [asc-beta-review](asc-beta-review/) | Beta app review submissions for TestFlight external testing |
| [asc-builds-archive](asc-builds-archive/) | Archive and export Xcode projects to IPA/PKG |
| [asc-builds-upload](asc-builds-upload/) | Upload builds and manage TestFlight distribution |
| [asc-check-readiness](asc-check-readiness/) | Pre-flight submission checks for App Store versions |
| [asc-code-signing](asc-code-signing/) | Bundle IDs, certificates, devices, and provisioning profiles |
| [asc-customer-reviews](asc-customer-reviews/) | Customer reviews and developer responses |
| [asc-game-center](asc-game-center/) | Game Center achievements and leaderboards |
| [asc-iap](asc-iap/) | In-App Purchases (consumable, non-consumable, non-renewing) |
| [asc-init](asc-init/) | Initialize project context (`.asc/project.json`) |
| [asc-performance](asc-performance/) | Performance metrics and diagnostic logs |
| [asc-plugins](asc-plugins/) | Plugin system for custom event handlers |
| [asc-reports](asc-reports/) | Sales, financial, and analytics reports |
| [asc-review-detail](asc-review-detail/) | App Store review contact info and demo accounts |
| [asc-skills](asc-skills/) | Skill management (install, update, check) |
| [asc-subscriptions](asc-subscriptions/) | Auto-renewable subscriptions, offers, and promo codes |
| [asc-testflight](asc-testflight/) | TestFlight beta groups and testers |
| [asc-users](asc-users/) | Team members and user invitations |
| [asc-xcode-cloud](asc-xcode-cloud/) | Xcode Cloud CI/CD workflows and build runs |

## Structure

Each skill is a directory with a `SKILL.md` file (and optional `references/`):

```
asc-auth/
└── SKILL.md            # Frontmatter (name, description) + usage guide

asc-code-signing/
├── SKILL.md
└── references/
    └── commands.md     # Detailed command reference
```

The `shared/` directory contains cross-skill resources like project context resolution.

## Update

```bash
asc skills check       # check for updates
asc skills update      # pull latest versions
```

## License

MIT
