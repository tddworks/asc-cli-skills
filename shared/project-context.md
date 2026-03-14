# Project Context Resolution

`asc init` saves the current project's app ID, name, and bundle ID to `.asc/project.json`
in the working directory. All skills that need `--app-id` should read this file first.

## File location & shape

```
.asc/project.json          ← relative to the current working directory
```

```json
{
  "appId": "6450406024",
  "appName": "My App",
  "bundleId": "com.example.app"
}
```

## Resolution order (ALWAYS follow this)

1. **User already provided** the app ID in their message → use it directly, skip everything else
2. **Project context exists** → read `.asc/project.json`, use `appId`
3. **No context** → run `asc apps list`, show results, ask user to pick or run `asc init`

Never jump straight to `asc apps list` without checking for project context first.

## Reading the context

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')
```

If `APP_ID` is empty after this, fall back to step 3 above.

## Setting up project context

If no `.asc/project.json` exists and the user hasn't provided an app ID, suggest:

```bash
asc init                    # auto-detect from *.xcodeproj bundle ID
asc init --name "My App"    # search by name
asc init --app-id <id>      # pin directly
```

After `asc init`, the app ID is available for all future skill invocations without prompting.

## Skills that use this pattern

Any skill whose workflow starts with `--app-id` should apply this resolution:
`asc-testflight`, `asc-app-infos`, `asc-builds-upload`, `asc-subscriptions`, `asc-iap`, `asc-app-shots`

Skills that work downstream (`--version-id`, `--localization-id`, `--set-id`) don't need it directly,
but may resolve the app ID transitively via `asc versions list --app-id`.