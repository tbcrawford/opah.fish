# opah status — secrets table design

**Date:** 2026-04-26
**Status:** Approved

## Overview

Replace the plain-text list in `_opah_status`'s Secrets section with a Unicode box-drawing table. The table gives each secret a clearly labelled Cached and Loaded column, uses consistent column widths, and fits within the terminal width.

## Visual design

```
Secrets
┌──────────────────────┬──────────┬──────────┐
│       Secret         │  Cached  │  Loaded  │
├──────────────────────┼──────────┼──────────┤
│ API_KEY              │    ✓     │    ✓     │
│ DATABASE_URL         │    ✓     │    ✕     │
│ STRIPE_SECRET_KEY    │    ✓     │    ✓     │
└──────────────────────┴──────────┴──────────┘
```

## Sigils

| State      | Sigil | Unicode  | Color                     |
|------------|-------|----------|---------------------------|
| present    | `✓`   | U+2713   | green (`$__OPAH_COLOR_SUCCESS`) |
| absent     | `✕`   | U+2715   | red (`$__OPAH_COLOR_ERROR`)    |

`✓` and `✕` are paired because they share the same stroke weight (both from the Dingbats block, adjacent codepoints). `✕` is already the Ocean error sigil — this is a consistent reuse.

## Column layout

### Secret column

- Width: `max(string length(key) for key in keys) + 2`
  - The `+ 2` provides one space of padding on each side.
- Minimum width: `8` (1 + `Secret` + 1), so the header always fits.
- Content: left-aligned, right-padded with spaces to fill the column.
- Header (`Secret`): centered within the column.

### Cached and Loaded columns

- Fixed internal width: `10` (2 padding + 6 for header text + 2 padding).
- Content: sigil centered within the 10-wide cell.
  - Centering formula: `floor((10 - 1) / 2)` = 4 spaces left, 5 spaces right.
- Header (`Cached`, `Loaded`): centered — 2 spaces each side.

### Maximum table width

The total table width is:

```
1 + secret_col + 1 + 10 + 1 + 10 + 1  =  secret_col + 24
```

The Secret column must not cause the total to exceed `min($COLUMNS, 80)`. If `$COLUMNS` is unset, treat it as 80.

Maximum Secret column width = `min($COLUMNS, 80) - 24`.

If the longest key name + 2 exceeds that, truncate the column to the maximum and truncate displayed key names with `…` (U+2026) to fit.

### Box-drawing characters

All border characters use the single-line box set. They are rendered in `$__OPAH_COLOR_DIM` (dim normal), matching the existing `────────────────────────────` separator in `_opah_header`.

| Position           | Chars                   |
|--------------------|-------------------------|
| Top border         | `┌` `─` `┬` `┐`        |
| Header separator   | `├` `─` `┼` `┤`        |
| Data row sides     | `│` (left and right)    |
| Data row dividers  | `│` (between columns)   |
| Bottom border      | `└` `─` `┴` `┘`        |

## Behaviour

- The table replaces only the per-key lines in the Secrets section. The Cache section, Summary section, and all other output remain unchanged.
- Single-secret lookup (`opah status KEY`) shows a table with one data row.
- The `filter_key` path uses the same table rendering helper as the all-secrets path.

## Implementation notes

- Add a helper function `_opah_status_table` (or inline logic) that accepts the list of keys and a parallel list of loaded flags, computes column widths, and prints the table.
- Fish string padding: use `string pad` (available in fish 3.3+) for right-padding the Secret column. Fall back to `printf %-*s` if needed.
- Centering a sigil in a fixed-width cell: pre-compute the left-pad count and print with `printf`.
- Color resets: apply `$__OPAH_COLOR_RESET` after each colored span so dim box chars are not affected by the preceding color.
