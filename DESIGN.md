# Design System

## Overview
Kuron is a privacy-first, dark-first mobile reading app for long-form content.
The visual style should feel focused, calm, and efficient: low visual noise,
high legibility, and clear hierarchy for browsing, reading, and offline
management workflows.

The interface should prioritize content readability and one-handed usage.
Use Material 3 patterns with restrained motion and consistent spacing.
Support three runtime themes: dark (default), light (paper-like), and amoled.

## Colors
- **Primary** (#58A6FF): Main call-to-action, active state, progress highlights.
- **Secondary** (#8B949E): Supporting actions, secondary labels, passive states.
- **Tertiary** (#A5A2FF): Accent highlights for optional metadata and supportive UI.
- **Neutral Dark Background** (#0D1117): Default app background in dark mode.
- **Neutral Dark Surface** (#161B22): App bars, sheets, and primary surfaces.
- **Neutral Dark Card** (#21262D): Card containers and grouped items.
- **Neutral Light Background** (#FAF8F5): Light mode canvas (warm paper tone).
- **Neutral Light Surface** (#F5F2ED): Light mode surface and list backgrounds.
- **Error** (#F85149): Errors, destructive actions, offline-critical alerts.
- **Success** (#3FB950): Success states, completed downloads, positive feedback.
- **Warning** (#D29922): Warning states and cautionary feedback.
- **AMOLED Background** (#000000): Pure black background for amoled mode.

Role guidance:
- Use primary color sparingly for the most important action in each viewport.
- Prefer neutral surface layering over strong color blocks.
- Keep destructive color usage explicit and limited to destructive intent.

## Typography
- **Headline Font**: System sans-serif (Material 3 default).
- **Body Font**: System sans-serif (Material 3 default).
- **Label Font**: System sans-serif (Material 3 default).

Hierarchy guidance:
- Headlines: 20-24px, medium to semi-bold for page titles and section headers.
- Body: 14-16px regular for primary reading and metadata descriptions.
- Labels: 11-12px medium for chips, badges, and compact control labels.
- Baseline line-height target: 1.4 for readable, dense mobile layouts.

## Elevation
This system is mostly flat.
Depth is communicated through surface tone differences and borders, not shadows.

Elevation guidance:
- Cards and list containers: elevation 0, with 1px outline where needed.
- Use border contrast and surface-container roles to separate groups.
- Avoid heavy blur or large drop shadows in content-heavy screens.

## Components
- **App Bar**: Flat, low-noise top bar with clear title and minimal actions.
- **Cards**: Rounded corners with subtle outline; 8px in dark/amoled,
  12px in light mode where paper surfaces are used.
- **Buttons**:
  Primary filled for key actions, secondary outlined/tonal for support actions.
  Keep labels concise and action-oriented.
- **Inputs**:
  Material 3 text fields with clear focus/error states, readable helper text,
  and strong contrast in dark mode.
- **Chips**:
  Used for tags, filters, and status. Selected chips use primary tint,
  error chips reserved for blocked/critical states.
- **Lists**:
  Dense but readable list tiles with consistent vertical rhythm,
  optional leading thumbnails, and metadata in subdued text color.
- **Reader Overlays**:
  Controls should be unobtrusive, high-contrast, and never compete with content.
  Reader chrome appears contextually and defaults back to content-first.
- **Loading/Placeholder**:
  Skeletons and placeholders use surface-container variants,
  not bright accents.
- **Offline/Network Status**:
  Inline banners and cards use semantic status colors with clear text labels,
  never color-only communication.

## Do's and Don'ts
- Do keep screens content-first with clear scanning hierarchy.
- Do maintain WCAG AA contrast for all text and controls.
- Do keep touch targets at least 44x44 logical pixels.
- Do use semantic status colors (success/warning/error) consistently.
- Do preserve privacy-focused visuals (blurred sensitive thumbnails when enabled).
- Don't overuse primary color across multiple competing actions.
- Don't mix many corner radius styles in a single screen.
- Don't rely on shadow-heavy depth effects.
- Don't use decorative motion that interrupts reading flow.
- Don't hide critical state changes behind icon-only indicators.

## Project Companion Docs
- Operational UI review checklist:
  `docs/id/DESIGN_REVIEW_CHECKLIST.md`
- Light mode detailed guide:
  `docs/id/DESIGN_LIGHT_MODE_GUIDE.md`
- Visual QA gate checklist:
  `docs/id/DESIGN_VISUAL_QA_CHECKLIST.md`