---
name: asc-app-shots-prompt
description: |
  Generate optimized Gemini prompts for `asc app-shots generate` by analyzing app screenshots.
  Reads the screenshot image, identifies the app's purpose, key features, color scheme, and most
  compelling UI elements, then outputs a ready-to-run `asc app-shots generate --prompt "..."` command
  that produces professional App Store marketing screenshots.
  Use this skill when:
  (1) User asks to "generate a prompt for my screenshot", "optimize my app-shots prompt"
  (2) User wants help making their `asc app-shots generate` output look better
  (3) User says "analyze this screenshot" or "create marketing screenshot" for an app
  (4) User mentions "app-shots prompt", "enhance screenshot prompt", or "ASO screenshot"
  (5) User has a composed screenshot and wants to improve it with AI
---

# App Shots Prompt Generator

You analyze an app screenshot and generate a detailed, optimized prompt for `asc app-shots generate --prompt "..."` that produces professional App Store marketing screenshots.

The generic default prompt in `asc app-shots generate` works OK, but a **custom prompt that names exact UI panels, exact headline text, exact colors** produces dramatically better results because Gemini has specific instructions instead of having to guess.

## How it works

1. Read the user's screenshot image
2. Analyze what's on screen
3. Generate a prompt with 6 specific components
4. Output a ready-to-run command

## Step 1 — Read the screenshot

Ask the user for their screenshot path, or if they've already provided one, read it immediately with the Read tool. Study the image carefully.

## Step 2 — Analyze the image

Extract these details from the screenshot:

**App identity:**
- What kind of app is this? (weather, fitness, finance, social, etc.)
- What's the app name if visible?
- Who's the target audience?

**Visual elements:**
- What's the dominant color scheme? (dark/light mode, accent colors)
- What UI components are visible? (lists, charts, cards, maps, buttons)
- What data or content is shown? (specific text, numbers, labels)

**Breakout candidate:**
- Which single UI panel or card is the most visually compelling?
- It must be a complete section (not a single button or icon)
- It should relate to the app's core value proposition

**Marketing angle:**
- What's the #1 benefit a user gets from this app?
- What action verb best captures it? (TRACK, FIND, CREATE, MANAGE, BOOST, etc.)
- What makes this screenshot compelling at thumbnail size?

## Step 3 — Generate the prompt

Build a prompt following this exact structure. Every field must be specific to THIS screenshot — no generic placeholders.

```
This is an App Store marketing screenshot for a [APP TYPE] app. The app shows [SPECIFIC CONTENT VISIBLE ON SCREEN].

KEEP EXACTLY:
- The iPhone device frame and the app content on screen
- The overall composition (headline text at top, phone below)

IMPROVE:
- Replace the headline text with "[ACTION VERB] [BENEFIT]" in large bold white uppercase text
- Replace the subtitle with "[6-10 word supporting statement]" in smaller white italic text
- Make the device frame photorealistic — sleek iPhone 15 Pro with reflections and subtle shadows
- Make the "[EXACT PANEL NAME]" [panel/card/section] break out from the device frame — scale it up so it extends beyond both edges of the phone, with a soft drop shadow, floating in front
- Use a clean [dark/light] gradient background ([COLOR 1] to [COLOR 2]) that complements the [dark/light] app UI
- Add a small [CONTEXTUAL BADGE — e.g. a stat, rating, or label] floating near the top-right as a supporting element
- Professional App Store agency quality, crisp text, no watermarks
```

### Component guidelines

**Headline (ACTION VERB + BENEFIT):**
- 2-4 words, ALL CAPS
- Start with a strong action verb: TRACK, FIND, CREATE, MANAGE, BOOST, DISCOVER, BUILD, PLAN, MONITOR, ORGANIZE
- The benefit should be specific: "TRACK CARD PRICES" not "MANAGE STUFF"
- Should make someone stop scrolling

**Subtitle:**
- 6-10 words, sentence case, italic
- Expands on the headline with a supporting benefit
- Examples: "Professional-grade forecasts at your fingertips", "Every card's value, updated in real-time"

**Breakout element:**
- Name the EXACT UI panel visible on screen (e.g. "Forecast Model Runs toggle panel", "Portfolio Summary card", "Recent Transactions list")
- Must be a complete card/section, not a single button or icon
- If no panel clearly reinforces the headline, write "No breakout — the app screen speaks for itself"

**Background:**
- Dark apps → dark gradient (deep navy #0A1628 to black #000000, or deep purple #1A0A2E to black)
- Light apps → light gradient (soft blue #E8F4FD to white, or warm cream #FFF8F0 to white)
- The gradient should complement, not clash with, the app's color scheme

**Supporting element:**
- A small contextual badge that reinforces value
- Examples: "4.9★" rating, "69°F" temperature, "$1,234" portfolio value, "12 new" notification count
- Must be relevant to what's actually shown on screen

## Step 4 — Output the command

Present the prompt to the user, then output the ready-to-run command:

```bash
asc app-shots generate \
  --file <screenshot-path> \
  --prompt '<the generated prompt>' \
  --device-type APP_IPHONE_67 \
  --output-dir .asc/app-shots/output
```

Also suggest a style reference variation if the user has a reference screenshot:

```bash
asc app-shots generate \
  --file <screenshot-path> \
  --style-reference <reference-path> \
  --device-type APP_IPHONE_67 \
  --output-dir .asc/app-shots/output
```

Use `--device-type` to resize output to exact App Store dimensions. Common types:
- `APP_IPHONE_69` (1320×2868) — iPhone 6.9"
- `APP_IPHONE_67` (1290×2796) — iPhone 6.7"
- `APP_IPAD_PRO_129` (2048×2732) — iPad 13"

## Examples

### Weather app input
Screenshot shows: San Francisco weather with temperature charts, wind speed, precipitation data, "Forecast Model Runs" toggle.

Generated prompt:
```
This is an App Store marketing screenshot for a weather forecasting app. The app shows detailed weather data for San Francisco including temperature charts, wind speed, precipitation, and forecast model runs.

KEEP EXACTLY:
- The iPhone device frame and the app content on screen
- The overall composition (headline text at top, phone below)

IMPROVE:
- Replace the headline text with "TRACK WEATHER IN DETAIL" in large bold white uppercase text
- Replace the subtitle with "Professional-grade forecasts at your fingertips" in smaller white italic text
- Make the device frame photorealistic — sleek iPhone 15 Pro with reflections and subtle shadows
- Make the "Forecast Model Runs" toggle panel break out from the device frame — scale it up so it extends beyond both edges of the phone, with a soft drop shadow, floating in front
- Use a clean dark gradient background (deep navy to black) that complements the dark weather UI
- Add a small temperature badge "69°F" floating near the top-right as a supporting element
- Professional App Store agency quality, crisp text, no watermarks
```

### Finance app input
Screenshot shows: stock portfolio with holdings list, pie chart allocation, total value $45,230.

Generated prompt:
```
This is an App Store marketing screenshot for an investment portfolio tracker. The app shows a stock portfolio with holdings breakdown, pie chart asset allocation, and total portfolio value.

KEEP EXACTLY:
- The iPhone device frame and the app content on screen
- The overall composition (headline text at top, phone below)

IMPROVE:
- Replace the headline text with "GROW YOUR WEALTH" in large bold white uppercase text
- Replace the subtitle with "Track every investment in real-time" in smaller white italic text
- Make the device frame photorealistic — sleek iPhone 15 Pro with reflections and subtle shadows
- Make the "Asset Allocation" pie chart card break out from the device frame — scale it up so it extends beyond both edges of the phone, with a soft drop shadow, floating in front
- Use a clean dark gradient background (deep emerald #0A2818 to black) that complements the finance UI
- Add a small portfolio value badge "$45,230" floating near the top-right as a supporting element
- Professional App Store agency quality, crisp text, no watermarks
```
