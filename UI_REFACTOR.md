# UI Refactor: Before & After

Visual-only refactor of the SpawnPK Market Dashboard Flutter Windows app. All business logic, providers, and data flow are unchanged.

---

## 1. Theme & Design System

### Before
- Theme was defined inline in `main.dart` with hardcoded hex colors.
- No shared spacing or radius constants; values like `16`, `12`, `20` were repeated.
- Card theme had `elevation: 0`; inputs and navigation were styled but not centralized.

### After
- **`lib/theme/app_theme.dart`** centralizes:
  - **AppSpacing**: 4 / 8 / 12 / 16 / 24 / 32 (xs → xxl).
  - **AppRadius**: 8 / 12 / 16 / 20 (sm → xl).
  - **AppElevation**: none / sm / md / lg.
  - **AppColors**: primary, surface, background, outline, success, warning, error.
- **Material 3** theme with consistent `ColorScheme`, `CardTheme`, `InputDecorationTheme`, `NavigationRailTheme`, `ScrollbarTheme`, `TabBarTheme`, `ChipTheme`, and `TextTheme`.
- **ScrollbarTheme**: desktop-friendly scrollbars (visible thumb, hover state).
- **main.dart** only references `appTheme`; all visual tokens live in one place.

---

## 2. Reusable UI Components

### New Widgets

| Widget | Purpose |
|--------|--------|
| **AppCard** | Surface card with consistent padding (default `AppSpacing.xl`), 16px radius, optional `elevateOnHover`. |
| **SectionHeader** | Page/section title + optional subtitle + optional trailing; uses `headlineSmall` and `bodyMedium`. |
| **AppSummaryCard** | Metric card (icon + title + value) with optional hover elevation and icon background animation. |

### Before
- Each page had its own `_SummaryCard` and ad-hoc section titles.
- Cards were raw `Card` + `Padding` with varying padding and no hover.

### After
- Item Lookup and User Lookup use **AppSummaryCard** and **SectionHeader**.
- All content sections use **AppCard** for grouping; list and chart blocks are visually consistent.
- Summary cards have subtle hover elevation and icon alpha change for desktop feedback.

---

## 3. Navigation & Shell

### Before
- Navigation rail in a 80px container with custom border/background.
- Content area in a bordered container; no transition when switching pages.

### After
- **Sidebar**: 88px rail inside a rounded container (`AppRadius.xl`) with light shadow and `AppColors.surface`; spacing uses `AppSpacing.xl`.
- **Content area**: Same rounded container with soft shadow; padding uses `AppSpacing.xxl` and `AppSpacing.xl`.
- **AnimatedSwitcher** when changing pages (200ms ease) for a smoother transition.
- **KeyedSubtree** so the switcher correctly animates between Items / Users / Tracking.

---

## 4. Page-Level Layout

### Item Lookup
- **SectionHeader** for "Item Lookup" + subtitle.
- Spacing: `AppSpacing.xl` / `AppSpacing.xxl` between header, search, and content.
- **AppSummaryCard** × 3 (Avg Price, Min/Max, Volume) with hover.
- **AppCard** for Price History and Recent Trades; **Scrollbar** around the scrollable content.
- **Trade list**: `_TradeListTile` with **MouseRegion** hover (row highlight) and **AnimatedContainer**; larger tap target via `minVerticalPadding`.
- Empty state uses theme `onSurfaceVariant` for icon and text.
- Loading/error use theme `colorScheme.error` and `onSurfaceVariant`.

### User Lookup
- **SectionHeader** + **AppSummaryCard** × 3 (Total Value, Volume, Avg Price).
- **AppCard** for Activity chart and trades list.
- **TabBar** uses theme (indicator, overlay hover).
- **Trade rows**: **InkWell** with `hoverColor`; design tokens for success/warning (purchase/sale); **FilledButton** for pagination with min height 44.
- **Trade detail modal**: rounded top corners (`AppRadius.xl`), shadow, theme colors for icon backgrounds (success/warning) and text.

### User Tracking
- **SectionHeader** for title + subtitle.
- **AppCard** for "Add Tracked User" and "Notification Poll Interval"; inputs use theme (no custom border overrides).
- **FilledButton** "Add" with consistent padding and min height.
- **Tracked users**: each user in a **Card** with **InkWell** hover; **FilterChip** with theme; delete **IconButton** with `colorScheme.error` and tooltip.
- Empty and error states use theme colors.
- **Scrollbar** on the tracked users list.

---

## 5. Shared Widgets

### LoadingErrorWidget
- Uses **AppSpacing** and theme `colorScheme.error` / `onSurfaceVariant` for icon and text.

### DebouncedSearchField
- Suggestions overlay: **Material** with theme `surface`, **AppRadius.md**, and shadow.

### PriceHistoryChart / ActivityChart
- Empty state and axis labels use `Theme.of(context).colorScheme.onSurfaceVariant` instead of `Colors.grey`.
- Grid lines use `onSurfaceVariant` with alpha for consistency with theme.

---

## 6. Desktop-Oriented Tweaks

- **Hover**: Summary cards, trade list tiles, tracked user tiles, and nav rail destinations respond to hover (elevation or background).
- **Scrollbars**: Themed and visible by default for mouse users.
- **Click targets**: IconButtons with `minimumSize` (e.g. 40×40); FilledButtons with min height 44–48.
- **Keyboard**: Existing `onSubmitted` on search and poll interval preserved; no logic change.

---

## 7. Files Touched (Visual Only)

| File | Change |
|------|--------|
| `lib/main.dart` | Use `appTheme` from `theme/app_theme.dart`. |
| `lib/theme/app_theme.dart` | **New**: design tokens + full ThemeData. |
| `lib/widgets/app_card.dart` | **New**: reusable card with optional hover. |
| `lib/widgets/app_summary_card.dart` | **New**: metric card with hover. |
| `lib/widgets/section_header.dart` | **New**: section title + subtitle. |
| `lib/pages/home_page.dart` | Shell layout, spacing, AnimatedSwitcher, nav rail container. |
| `lib/pages/item_lookup_page.dart` | SectionHeader, AppCard, AppSummaryCard, Scrollbar, _TradeListTile hover, empty state. |
| `lib/pages/user_lookup_page.dart` | SectionHeader, AppCard, AppSummaryCard, theme colors in modal and rows, FilledButton pagination, Scrollbar. |
| `lib/pages/user_tracking_page.dart` | SectionHeader, AppCard, themed inputs/buttons, TrackedUserTile card + hover, Scrollbar. |
| `lib/widgets/loading_error_widget.dart` | Theme colors, AppSpacing. |
| `lib/widgets/debounced_search_field.dart` | Theme surface + AppRadius for overlay. |
| `lib/widgets/price_history_chart.dart` | Theme onSurfaceVariant for empty state and axes. |
| `lib/widgets/activity_chart.dart` | Theme onSurfaceVariant for empty state, labels, grid. |

No changes to: `lib/providers/*`, `lib/services/*`, `lib/models/*`, `lib/utils/*`, or any business logic.
