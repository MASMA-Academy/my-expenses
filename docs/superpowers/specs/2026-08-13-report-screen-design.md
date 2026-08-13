# Report Screen — Design Spec

## Context

MyXpenses is a Flutter expense-tracking app. `DashboardScreen`, `HistoryScreen`
(and the `MainScreen` shell in `main.dart`) are already implemented with real
data flowing from a `List<TransactionItem>` held in `MainScreen`. `report_screen.dart`
is currently an empty file, and the `ReportScreen` case in `main.dart`'s
`getCurrentScreen()` switch (index 1) is commented out.

The user supplied a mockup screenshot of the Reports tab: a Week/Month/Year
period selector, a month navigator, a "Spending by Category" donut chart with
legend, an "Income vs Expense" bar comparison with decorative emoji badges,
and a 3-chip period summary (Income/Expense/Balance).

This spec covers building out `ReportScreen` to match that mockup, wired into
the existing bottom-nav shell, using real data from the transactions list
already threaded through `MainScreen`.

## Goals

- Implement `ReportScreen` as a `StatefulWidget` consuming
  `List<TransactionItem> transactions`, following the existing screen pattern
  (`DashboardScreen`, `HistoryScreen`).
- Week / Month / Year period selector, all three fully functional, with
  prev/next navigation and a date-picker shortcut.
- Category breakdown (Food/Transport/Shopping/Bills/Others) as a real
  multi-segment donut (via `CustomPainter`, no new dependency) plus a legend
  with amounts and percentages.
- Income vs Expense comparison as proportional bars with emoji badges.
- A period summary card (Income / Expense / Balance chips).
- An empty state (matching the app's existing 🌱 pattern) when the selected
  period has no transactions.
- Wire `ReportScreen` into `main.dart`'s tab switch (index 1).

## Non-goals

- No new packages (charting stays hand-rolled via `CustomPainter`).
- No persistence changes — reads the same in-memory `transactions` list
  `MainScreen` already owns.
- No changes to `TransactionItem` or other screens beyond uncommenting the
  existing `ReportScreen` case and import in `main.dart`.

## File layout

```
lib/
  screens/
    report_screen.dart   → ReportScreen (StatefulWidget), currently empty
  main.dart               → uncomment `case 1: return ReportScreen(transactions: transactions);`
```

## Period logic

`_ReportScreenState` holds:
- `selectedPeriod` — `'Week' | 'Month' | 'Year'`, default `'Month'`.
- `referenceDate` — `DateTime`, default `DateTime.now()`.

Derived per period from `referenceDate`:
- **Week**: Monday–Sunday range containing `referenceDate`. Label:
  `"Aug 10 – 16, 2026"`. Prev/next shift `referenceDate` by ±7 days.
- **Month**: calendar month. Label: `"August 2026"`. Prev/next shift by
  ±1 month (via constructing `DateTime(year, month ± 1)`, which correctly
  rolls the year over).
- **Year**: calendar year. Label: `"2026"`. Prev/next shift by ±1 year.

The calendar icon next to the label opens `showDatePicker`; picking a date
sets `referenceDate` to it (period stays whatever's selected).

Filtering: `transactions.where((t) => !t.date.isBefore(periodStart) && !t.date.isAfter(periodEnd))`.

## Data aggregation

From the filtered list:
- `totalIncome` = sum where `income == true`.
- `totalExpense` = sum where `income == false`.
- `balance` = `totalIncome - totalExpense`.
- Category breakdown (expenses only), fixed display order and colors reused
  from `DashboardScreen`/`HistoryScreen`'s category color helpers:
  - Food — `#7EBBA9`
  - Transport — `#FFA6AA`
  - Shopping — `#D4C9BE`
  - Bills — `#A8DDC5`
  - Others (any category not in the four above) — `#E4DEDB`
- Percentage per category = `categoryAmount / totalExpense` (0% when
  `totalExpense == 0`).

## Screen sections (top → bottom)

1. **Header** — centered "Reports" title, no back chevron (this is a
   bottom-nav tab, not a pushed screen).
2. **Period pill selector** — Week/Month/Year, same `AnimatedContainer` pill
   pattern as `HistoryScreen`'s All/Income/Expense filter.
3. **Date navigator card** — white rounded card: `chevron_left` icon button,
   centered period label + small calendar icon button, `chevron_right` icon
   button.
4. **"Spending by Category" card**:
   - Donut chart: `CustomPainter` drawing one arc per category proportional
     to its share of `totalExpense`, stroke-style ring (not filled pie), with
     "Total / RM x.xx" centered via a `Stack`.
   - Legend: one row per category with non-zero amount — color dot, name,
     amount, percentage — mirroring `_buildCategoryRow` in
     `DashboardScreen` but extended with a percentage column.
5. **"Income vs Expense" card** — two columns (Income, Expense), each with:
   an emoji badge (📈 income / 🐷 expense) above a bar whose height is
   proportional to `value / max(totalIncome, totalExpense, 1)`, an amount
   label, and a category label below the bar.
6. **"This [Period] Summary" card** — three chips (Income/Expense/Balance),
   styled like `HistoryScreen._summaryCard`: colored background, icon, label,
   amount.
7. **Empty state** — if the filtered list is empty, replace sections 4–6
   with the app's existing 🌱 "No transactions yet" pattern (reused style
   from `DashboardScreen`/`HistoryScreen`).

## Error handling

Not applicable — pure in-memory aggregation over a list already validated at
entry (`AddTransactionScreen`). No I/O, no external calls, no null inputs
(`transactions` is a required non-nullable list, possibly empty).

## Testing / verification

- `flutter analyze` must pass with no errors.
- Manually verified via the `run` skill: switch to the Reports tab, confirm
  it renders with whatever transactions exist (including the empty-state
  case with zero transactions), toggle Week/Month/Year, navigate prev/next
  and via the date picker, and confirm totals/percentages match the
  underlying transaction data.
- No automated tests added — consistent with `DashboardScreen`/
  `HistoryScreen`, which also have none; verification is manual per the
  existing project convention.

## Dependencies to add

None.
