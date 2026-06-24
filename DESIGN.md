# Kuron Design System

> Visual identity & component design language for Kuron mobile reading app.
> Reflects actual tokens in code — not aspirational.

---

## Brand Identity

| Attribute | Value |
|-----------|-------|
| **Vibe** | Warm, intimate, privacy-first reading |
| **Tone** | Mature, calm, unobtrusive — content is hero |
| **Inspiration** | Dark-mode reading apps, Material Design 3 |
| **Source** | `Frame.svg` brand assets → coral palette |

### Brand Colors

```
brandCoral  #F1958E  — Main accent, actionable elements
brandMuted  #E0827E  — Secondary accent
brandDusty  #9D555B  — Tertiary, deeper tone
brandDark   #1A1A1F  — Near black, dark surfaces
```

### Design Principles

1. **Content First** — UI recedes; typography & color serve readability
2. **Warmth** — Coral/pink undertones replace cold blue Material defaults
3. **Cohesive Darkness** — 3 calibrated modes (dark/amoled/light)
4. **Flat + Bordered** — Cards use `elevation: 0` + 1px colored borders, not shadows

---

## Color System

### Palette

```
Core Brand
  brandCoral  #F1958E
  brandMuted  #E0827E
  brandDusty  #9D555B
  brandDark   #1A1A1F

Light Theme
  bg       #FBF9F7  Warm off-white
  surface  #F3F0EC  Cream
  card     #FFFFFF  Pure white
  text     #2C2926  Warm black
  textSub  #7A716A  Muted brown
  border   #FFBE69  Warm accent

Dark Theme
  bg       #121215  Deep dark
  surface  #1A1A1F  Brand dark base
  card     #222228  Elevated card
  text     #FFFFFF  Warm white
  textSub  #9A9590  Muted
  border   #593734  Subtle borders

AMOLED Theme
  bg       #000000  Pure black
  surface  #0A0A0F  Slight tint
  card     #141418  Card surface
  border   #282830  Border

Semantic
  primary    brandCoral
  secondary  brandDusty
  tertiary   brandMuted

Status
  error    #FF6B6B
  success  #7DD3A8
  warning  #FFD076
  info     #7BB8FF
```

### Color Roles

| Role | Usage |
|------|-------|
| **Primary** | Accent actions, FAB, selected nav, active controls |
| **Primary Container** | Selected states, badge bg (dark) |
| **Surface** | Scaffold, drawers, bottom sheets |
| **Card** | Content cards, list tiles, elevated containers |
| **Border** | Card outlines — primary visual boundary (flat look) |
| **Text** | Body, headings |
| **Text Sub** | Captions, secondary info, metadata |
| **Status** | Semantic states + download progress |

### Theme Variants

| Variant | Background | Surface |
|---------|-----------|---------|
| **Light** | `#FBF9F7` | `#F3F0EC` |
| **Dark** | `#121215` | `#1A1A1F` (default) |
| **AMOLED** | `#000000` | `#0A0A0F` |

---

## Typography

**Font**: System sans-serif (no explicit `fontFamily`). Monospace only for debug.

### Weight Scale

| Token | Weight | Usage |
|-------|--------|-------|
| Light | 300 | Captions, subtitles, placeholders |
| Regular | 400 | Body text |
| Medium | 500 | Labels, small headings, buttons |
| SemiBold | 600 | Content titles, active nav |
| Bold | 700 | Headings, section titles |
| ExtraBold | 800 | Display text, hero |

### Type Scale (from `TextStyleConst`)

```dart
Display  57/700   Hero numbers (rare)
Headline 32/700   Screen titles
Title    22/600   Section headers
Body     16/400   Primary reading text
Label    14/500   Buttons, chips
Caption  12/300   Metadata
Overline 10/400   Section markers
```

Full scale in `lib/core/constants/text_style_const.dart`. Includes component-specific: `contentTitle` (SemiBold 16), `buttonLarge` (Medium 16), `navigationLabel` (Medium 14).

**Line height**: Uniform `1.4`. Styles inherit color from `Theme` — no hardcoded colors.

---

## Design Tokens (NEW)

**`lib/core/constants/design_tokens.dart`** — central token scale, replacing inline numeric literals.

### Spacing (geometric progression 4→48)

| Token | Value | Usage |
|-------|-------|-------|
| `spaceXs` | 4 | Tight icon gaps, badges |
| `spaceSm` | 8 | Card grid gaps, chip padding |
| `spaceMd` | 12 | Internal card padding |
| `spaceLg` | 16 | Screen edges (`defaultPadding`) |
| `spaceXl` | 24 | Section spacing |
| `space2xl` | 32 | Large section breaks |
| `space3xl` | 48 | Screen-level groups |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSm` | 4 | Badges, small tags |
| `radiusMd` | 8 | Buttons, compact cards |
| `radiusLg` | 12 | Input fields (most used) |
| `radiusXl` | 16 | Cards |
| `radius2xl` | 20 | Bottom sheets, modals |
| `radiusFull` | 999 | Circular elements |

### Elevation

| Token | Value | Usage |
|-------|-------|-------|
| `elevationNone` | 0 | All cards, lists |
| `elevationSm` | 1 | Subtle lift |
| `elevationMd` | 2 | FAB |
| `elevationLg` | 4 | Modal dialogs |
| `elevationXl` | 8 | Overlays, drawers |

### Durations

| Token | Value | Usage |
|-------|-------|-------|
| `durationInstant` | 50ms | Tap feedback |
| `durationFast` | 150ms | Hover, press states |
| `durationPageTurn` | 200ms | Reader page turns |
| `durationNormal` | 300ms | UI transitions |
| `durationSlow` | 500ms | Overlay fade |
| `durationPageEnter` | 700ms | Screen transitions |

### Curves

| Token | Curve | Usage |
|-------|-------|-------|
| `curveStandard` | `easeInOutCubic` | Most UI motion |
| `curveReaderPage` | `easeOutCubic` | Reader page turns |
| `curveEnter` | `easeOut` | Entrance animations |
| `curveExit` | `fastEaseInToSlowEaseOut` | Exit animations |

---

## Components

### Cards
```
CardThemeData(
  color: {light: white, dark: #222228, amoled: #141418},
  elevation: elevationNone,
  shape: RoundedRectangleBorder(
    borderRadius: radiusXl (16),
    side: BorderSide(color: themeBorder, width: 1),
  ),
)
```

### Navigation Bar
- Selected: brandCoral indicator (15-25% alpha) + SemiBold label
- Unselected: textSub + Medium label
- Background: surface color per theme

### Input Fields
- Filled, surface-colored bg, radiusLg (12)
- Border: border color → primary 2px (focused)

### FAB
- Primary bg, white foreground, elevationMd (2) / elevationSm (1 amoled)

---

## Source Files

| File | Role |
|------|------|
| `lib/core/constants/colors_const.dart` | Brand palette, theme, semantic colors |
| `lib/core/constants/text_style_const.dart` | Weight system, type scale, component styles |
| `lib/core/constants/design_tokens.dart` | Spacing, radius, elevation, duration, curves |
| `lib/core/utils/tag_color_palette.dart` | Tag→color mapping (12 categories) |
| `lib/core/constants/app_constants.dart` | Config-driven UI values |
| `lib/presentation/cubits/theme/theme_cubit.dart` | ThemeData (light/dark/amoled) |

---

*Updated 2026-06-24 — matches codebase. Design tokens now live in `DesignTokens` class, 45+ files migrated.*
