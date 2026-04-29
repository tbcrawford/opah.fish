# CLI Output Redesign — Design Spec

**Date:** 2026-04-24
**Branch:** refactor/stream-cache-ci

---

## Goal

Revamp all user-facing output in `opah` to follow a consistent, coherent design system. Replace all emoji usage with Unicode geometric sigils. Establish a clear visual hierarchy using color, weight, and spacing alone — no decorative box-drawing chrome in subcommand output.

---

## Design System

### Color Palette — "Ocean"

Hex values are approximate references for the visual mockups; actual rendered colors depend on the terminal's color scheme. Implementation uses fish's named `set_color` arguments.

| Role | `set_color` argument | Hex (approx) | Usage |
|---|---|---|---|
| Brand / accent | `brcyan` | `#56d4c8` | `opah` name, section headers, info sigil |
| Success | `green` | `#57ab5a` | `●` sigil, "cached · loaded" state text |
| Error | `red` | `#e5534b` | `✕` sigil, "not loaded" state text |
| Warning | `yellow` | `#c69026` | `▲` sigil, partial-success states |
| Info | `brcyan` | `#56d4c8` | `◆` sigil (same as accent color) |
| Base text | `normal` | `#cdd9e5` | All primary message text |
| Dim | `normal --dim` | `#546472` | Details, metadata, hint text, command descriptions |
| Separator | `brcyan --dim` | `#1e3d45` | The `────` rule on the help screen only |

### Sigil System

Four semantic states, each with a distinct geometric shape. Shape carries meaning independent of color — the system must remain readable in monochrome.

| State | Sigil | Color | Unicode |
|---|---|---|---|
| Success | `●` | green | U+25CF BLACK CIRCLE |
| Error | `✕` | red | U+2715 MULTIPLICATION X |
| Warning | `▲` | yellow | U+25B2 BLACK UP-POINTING TRIANGLE |
| Info | `◆` | cyan | U+25C6 BLACK DIAMOND |

Sigils are always padded with a single space on each side: ` ● ` ` ✕ ` ` ▲ ` ` ◆ `.

**Collapsing of legacy types:** The previous codebase had eleven message types (`_opah_security`, `_opah_process`, `_opah_file`, `_opah_diagnostic`, etc.). All informational subcategories collapse into the single `◆` info sigil. Semantic meaning is carried by the message text, not by the sigil shape.

### Typography Rules

| Element | Treatment |
|---|---|
| `opah` brand name | Lowercase, bold, cyan — always |
| Section headers | Title Case, bold, cyan |
| Command names in help | Cyan (non-bold), left-aligned, fixed-width column |
| Command descriptions in help | Dim, right column |
| Primary message text | Normal weight, base color |
| Detail / metadata | Dim, indented 5 spaces (aligns under message text) |
| Hint / suggested next step | Dim, indented 5 spaces, plain prose |

---

## Layout Rules

### Help Screen (`opah help`)

The **only** screen that renders the brand header and separator rule. Structure:

```
opah  1password secrets manager
────────────────────────────

Usage
  opah <command> [options]

Commands
  status    show cached secrets
  ...

Examples
  opah status             # show all cached secrets
  ...

  run 'opah <command> --help' for details
```

- `opah` in bold cyan, subtitle in dim, on the same line
- `────` separator in very dim cyan immediately below
- Section labels (`Usage`, `Commands`, `Examples`) in bold cyan, title case
- Hint line at the bottom in dim, no sigil

### Subcommand Output (all other commands)

Subcommands **do not** repeat their name or render a separator rule. Output begins immediately with the first section header. The shell prompt already shows what was run.

```
Section Header
 ● primary message text
     detail or metadata

Next Section
 ▲ warning message
     run: suggested fix
```

**Section headers:** bold cyan, title case, followed by a blank line after the last item before the next section. No leading character, no trailing rule, no box-drawing.

**Blank line rhythm:** one blank line between sections, none before the first section, none after the last.

### Detail Lines

Indented 5 spaces (one space past the sigil's right edge) to visually connect to the parent message:

```
 ● op is installed
     version 2.26.1
```

### Hint Lines

Same indentation as detail lines. Used for actionable next steps following an error or warning. No sigil.

```
 ▲ 1 issue detected
     run: chmod 600 ~/.cache/opah/secrets
```

### Inline Key/Value Lists (status, load progress)

Used in `status` Secrets section and inline load progress in `reinit`/`refresh`. Key names are dim, state is colored:

```
  API_KEY      cached · loaded
  DATABASE_URL cached · loaded
  STRIPE_KEY   cached · not loaded
```

For inline per-key load progress (one key per line, sigil appended after):

```
  API_KEY       ● 
  DATABASE_URL  ● 
  STRIPE_KEY    ✕ 
```

### Step Headers (reinit)

Multi-step commands use title-cased step labels as section headers:

```
Step 1  Clear Cache
 ● environment variables unset

Step 2  Authenticate
 ● already signed in
```

The step number and step name are separated by two spaces, both title-cased, treated as a single section header string.

---

## Per-Screen Reference

### `opah help`
- Brand header + separator (only here)
- Sections: Usage, Commands, Examples
- Trailing hint line

### `opah status`
- Sections: Cache, Secrets, Summary
- Cache: `◆` info items (last updated, permissions)
- Secrets: inline key/state list (dim key, colored state)
- Summary: sigil + count message + hint if action needed

### `opah doctor`
- Sections: 1Password CLI, Authentication, Configuration, Cache, Fish Shell Integration, Summary
- Each section: one or more sigil lines + optional detail lines
- Summary: aggregate result with hint if issues found

### `opah refresh`
- No sections (single-purpose command)
- Inline per-key progress list during fetch
- Final `●` or `▲` summary line

### `opah clear`
- No sections
- `◆` info lines for each action taken (unset vars, remove file)
- Final `●` success or `✕` error

### `opah config`
- Sections: Locations, Validation, Summary
- Locations: per-path `●`/`✕` lines
- Validation: per-key `●`/`▲` lines (valid ref vs non-1Password value)

### `opah reinit`
- Sections: Step 1 Clear Cache, Step 2 Authenticate, Step 3 Load Secrets, Summary
- Step 3 uses inline per-key progress list

### `opah doctor --help` / per-command `--help`
- Matches help screen structure (Usage, Arguments/Options, Examples)
- No brand header — starts directly with `Usage` section

### Startup errors (`conf.d/opah.fish`)
- Single `✕` error line to stderr
- One `◆` info hint line below it
- No section headers (single-moment event, not a structured report)

---

## What Is Removed

| Removed | Replaced by |
|---|---|
| All emoji (`🐠 🔐 🔄 📁 🔍 📋 📍 💡 ✓ ✗ ⚠ ℹ`) | Geometric sigils `● ✕ ▲ ◆` or plain text |
| `_opah_security`, `_opah_process`, `_opah_file`, `_opah_diagnostic` functions | Collapsed into `_opah_info` (`◆`) |
| `_opah_section` with `━━━` rule | Bold cyan title-case label, blank line separation only |
| `_opah_step` with `📍` | Bold cyan `Step N  Title` section header |
| `"🐠 Fishy 1Password Secrets Management CLI"` title | `opah  1password secrets manager` |
| `SHOUTING CAPS` section labels | Title Case section labels |
| Subcommand title + ruler on every subcommand | Only on `opah help` |

---

## UI Primitive Functions (updated `_opah_ui.fish`)

The existing `_opah_ui.fish` defines all output primitives. It will be rewritten to expose:

| Function | Sigil | Color |
|---|---|---|
| `_opah_success msg [detail]` | ` ● ` | green |
| `_opah_error msg [detail]` | ` ✕ ` | red |
| `_opah_warning msg [detail]` | ` ▲ ` | yellow |
| `_opah_info msg [detail]` | ` ◆ ` | cyan |
| `_opah_section title` | (none) | bold cyan |
| `_opah_hint msg` | (none) | dim |
| `_opah_header` | (none) | brand header + ruler — called only from `_opah_show_help` |

The optional `detail` argument prints the detail line automatically at the correct indentation, eliminating the need for callers to manage spacing.
