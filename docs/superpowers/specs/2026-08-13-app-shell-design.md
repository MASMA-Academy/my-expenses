# MyXpenses App Shell — Design Spec

## Context

MyXpenses is a Flutter expense-tracking app. The project currently has the default
Flutter counter-app `main.dart` and five empty placeholder screen files
(`dashboard_screen.dart`, `transaction_screen.dart`, `history_screen.dart`,
`report_screen.dart`, `budget_screen.dart`).

The user supplied a mockup (5 screens: Home/Dashboard, Add Transaction, History,
Reports, Budget) and a feature list for the full app. The full app is a
multi-screen system with real data, categories, budgets, and reports — too large
for a single spec. This spec covers only the **first sub-project**: the app
shell — entry point, theming, and navigation — with all screen bodies left as
static placeholders. Screen-by-screen functionality is out of scope and will be
its own future spec/plan per screen.

## Goals

- Replace the default counter-app `main.dart` with a real app entry point.
- Establish the visual theme (colors, typography) matching the mockup.
- Establish bottom-navigation shell wiring the 4 tab screens, plus a center FAB
  that pushes the Add Transaction screen (not a 5th tab).
- Put a minimal state-management pattern (Provider) in place for later steps to
  build on, without adding real state yet.

## Non-goals

- No real transaction/budget/category data or persistence.
- No fully built-out screen UIs (dashboard cards, charts, forms, etc.) — each
  screen body is a simple placeholder for this step.
- No tests beyond `flutter analyze` and a manual run, since there's no business
  logic yet.

## File layout

```
lib/
  main.dart                    → runApp(MyXpensesApp()), wraps app in ChangeNotifierProvider<AppState>
  app.dart                     → MyXpensesApp: MaterialApp widget (title, theme, home: MainNavigation)
  theme/
    app_theme.dart             → ThemeData: colorScheme, textTheme (google_fonts Quicksand), component themes
  state/
    app_state.dart             → empty ChangeNotifier placeholder for future shared state
  navigation/
    main_navigation.dart       → Scaffold: IndexedStack of 4 tab screens + BottomNavigationBar + centered FAB
  screens/
    dashboard_screen.dart      → placeholder body (existing empty file, to be filled with minimal Scaffold-less body)
    report_screen.dart         → placeholder body (existing empty file)
    history_screen.dart        → placeholder body (existing empty file)
    budget_screen.dart         → placeholder body (existing empty file)
    transaction_screen.dart    → placeholder body (existing empty file), pushed via FAB, not a tab
```

## Theme

Palette extracted from the mockup's pastel design:

| Token | Value | Use |
|---|---|---|
| `primary` (green) | `#7FC8A9` | Buttons, active nav icon, positive amounts |
| `secondary` (pink) | `#F2A6B3` | Accents, expense amounts, heart motifs |
| `background` | `#FDF3EC` (warm cream) | Scaffold background |
| `surface` | `#FFFFFF` | Cards |
| Font | Quicksand, via the `google_fonts` package | Rounded, friendly, matches mockup |

`app_theme.dart` builds a single `ThemeData` using `ColorScheme.fromSeed` seeded
on the primary green, then overrides `secondary`/`background` to match the
table above, and sets `textTheme` to a Quicksand-based `TextTheme`.

## Navigation

`MainNavigation` (`StatefulWidget`) holds `_selectedIndex` (int, default 0).
Body is an `IndexedStack` containing the 4 tab screens in nav order (Home,
Reports, History, Budget) — `IndexedStack` so switching tabs preserves each
screen's state. `BottomNavigationBar` (or `BottomAppBar` with a notch) shows
the 4 tab icons/labels; tapping updates `_selectedIndex` via `setState`. A
centered `FloatingActionButton` (docked in the notch, matching the mockup) has
`onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
const TransactionScreen()))` — it is not one of the 4 `IndexedStack` entries.

## Data flow

None yet. `AppState` is an empty `ChangeNotifier` registered via
`ChangeNotifierProvider` in `main.dart` so later steps have a place to add
real state (transactions, budgets, categories) without restructuring
`main.dart` again. No screen reads from it in this step.

## Error handling

Not applicable — no business logic, I/O, or external calls in this step.

## Testing / verification

- `flutter analyze` must pass with no errors.
- App must launch and show the Home tab by default, with working tab
  switches and a working FAB navigation to the Add Transaction screen (back
  navigation returns to the previously selected tab).
- Verified manually via the `run` skill (or `flutter run`) rather than
  automated tests, since there is no logic to unit test yet.

## Dependencies to add

- `provider` (state management, per user decision)
- `google_fonts` (typography, per user decision)
