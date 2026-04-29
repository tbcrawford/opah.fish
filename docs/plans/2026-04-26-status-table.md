# opah status secrets table Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the plain-text secret list in `opah status` with a Unicode box-drawing table that shows Cached and Loaded status columns.

**Architecture:** Extract all table-rendering logic into a new `_opah_status_table` helper function. `_opah_status.fish` builds a parallel list of loaded-flags and calls the helper. Column widths are computed at runtime from the key names and `$COLUMNS`.

**Tech Stack:** Fish shell (3.3+), fishtape (test runner), `just` (task runner)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `functions/_opah_status_table.fish` | **Create** | Box-drawing table renderer |
| `functions/_opah_status.fish` | **Modify** | Call helper instead of per-key printf |
| `tests/test_status_table.fish` | **Create** | Unit tests for the table renderer |
| `tests/test_cli_smoke.fish` | **Modify** | Update pattern match for new table output |

---

## Task 1: Create `_opah_status_table` — basic rendering

**Files:**
- Create: `tests/test_status_table.fish`
- Create: `functions/_opah_status_table.fish`

### Step 1.1 — Write the failing tests

Create `tests/test_status_table.fish`:

```fish
# Unit tests for _opah_status_table.
# Strips ANSI escape codes before asserting text content.

set repo_root (path dirname (status dirname))
set functions_dir "$repo_root/functions"

function run_table -a script_body
    fish --no-config -C "set fish_function_path $functions_dir \$fish_function_path" \
        -c "$script_body" 2>&1 \
        | string replace --all --regex '\x1b\[[0-9;]*m' ''
end

@test "table: top border starts with box corner" \
    (run_table '_opah_status_table 1 API_KEY 1' | string collect | string match -r '^┌') \
    = ┌

@test "table: bottom border ends with box corner" \
    (run_table '_opah_status_table 1 API_KEY 1' | string collect | string match -r '┘\n?$') \
    != ""

@test "table: header row contains Secret, Cached, Loaded" \
    (run_table '_opah_status_table 1 API_KEY 1' | string match -r 'Secret.*Cached.*Loaded') \
    != ""

@test "table: separator row contains cross junctions" \
    (run_table '_opah_status_table 1 API_KEY 1' | string match -r '├.*┼.*┤') \
    != ""

@test "table: loaded key shows check in both columns" \
    (run_table '_opah_status_table 1 API_KEY 1' | string match -r 'API_KEY.*✓.*✓') \
    != ""

@test "table: unloaded key shows check cached and cross loaded" \
    (run_table '_opah_status_table 1 API_KEY 0' | string match -r 'API_KEY.*✓.*✕') \
    != ""

@test "table: multiple keys each appear on their own row" \
    (begin
        set out (run_table '_opah_status_table 2 API_KEY DB_PASS 1 0' | string collect)
        if string match -q '*API_KEY*' -- $out; and string match -q '*DB_PASS*' -- $out
            echo ok
        end
    end) = ok

@test "table: short keys use Secret header as minimum column width" \
    (run_table '_opah_status_table 1 K 1' | string match -r 'Secret') \
    != ""

@test "table: key is truncated with ellipsis when terminal is narrow" \
    (run_table 'set -gx COLUMNS 40; _opah_status_table 1 ABCDEFGHIJKLMNOPQRSTUVWXYZ 1' \
        | string match -r '…') \
    = '…'

@test "table: zero secrets returns without output" \
    (run_table '_opah_status_table 0') \
    = ""
```

- [ ] **Step 1.2 — Run tests to confirm they all fail**

```bash
just test test_status_table
```

Expected: all tests FAIL (function not found or missing).

- [ ] **Step 1.3 — Create `functions/_opah_status_table.fish`**

```fish
#
# Render secrets status as a Unicode box-drawing table.
#
# Usage: _opah_status_table N key1 ... keyN flag1 ... flagN
#
#   N     – count of secrets
#   keyI  – secret name
#   flagI – 1 if loaded into env, 0 if not
#
# All listed keys are implicitly cached (they came from the cache file).
#
function _opah_status_table -d "Render secrets status as a Unicode box table"
    set -l n $argv[1]
    if test $n -eq 0
        return 0
    end

    set -l keys $argv[2..(math $n + 1)]
    set -l flags $argv[(math $n + 2)..-1]

    # ── Secret column width ───────────────────────────────────────────────────
    # Minimum = length of "Secret" (6) so the header always fits.
    set -l max_key_len 6
    for key in $keys
        set -l klen (string length -- $key)
        if test $klen -gt $max_key_len
            set max_key_len $klen
        end
    end

    # Cap total table width to min($COLUMNS, 80).
    # Total table width = secret_col + 24  (borders + two 10-wide status cols)
    set -l term_width 80
    if set -q COLUMNS; and string match -qr '^\d+$' -- "$COLUMNS"
        if test "$COLUMNS" -lt 80
            set term_width $COLUMNS
        end
    end
    set -l max_secret_col (math $term_width - 24)
    if test (math $max_key_len + 2) -gt $max_secret_col
        set max_key_len (math $max_secret_col - 2)
    end

    set -l secret_col (math $max_key_len + 2)
    set -l status_col 10

    # ── Horizontal rule strings ───────────────────────────────────────────────
    set -l h_s (string repeat -n $secret_col ─)
    set -l h_c (string repeat -n $status_col ─)

    # ── Center "Secret" in secret_col ────────────────────────────────────────
    set -l s_pad_total (math $secret_col - 6)
    set -l s_pad_l (math "floor($s_pad_total / 2)")
    set -l s_pad_r (math $s_pad_total - $s_pad_l)
    set -l hdr_secret (printf "%*s%s%*s" $s_pad_l "" Secret $s_pad_r "")

    # ── Sigil padding: 1 char centered in a 10-wide cell ─────────────────────
    # floor((10-1)/2) = 4 left, 5 right
    set -l sig_l "    "
    set -l sig_r "     "

    # ── Top border ────────────────────────────────────────────────────────────
    printf "%s┌%s┬%s┬%s┐%s\n" \
        $__OPAH_COLOR_DIM $h_s $h_c $h_c $__OPAH_COLOR_RESET

    # ── Header row ────────────────────────────────────────────────────────────
    printf "%s│%s%s%s│%s  Cached  %s│%s  Loaded  %s│%s\n" \
        $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET $hdr_secret $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET $__OPAH_COLOR_DIM \
        $__OPAH_COLOR_RESET

    # ── Header separator ──────────────────────────────────────────────────────
    printf "%s├%s┼%s┼%s┤%s\n" \
        $__OPAH_COLOR_DIM $h_s $h_c $h_c $__OPAH_COLOR_RESET

    # ── Data rows ─────────────────────────────────────────────────────────────
    for i in (seq 1 $n)
        set -l key $keys[$i]
        set -l is_loaded $flags[$i]

        # Truncate key if it exceeds max_key_len
        if test (string length -- $key) -gt $max_key_len
            set key (string sub -l (math $max_key_len - 1) -- $key)…
        end

        # Left-align key padded to max_key_len with one space on each side
        set -l padded (printf " %-*s " $max_key_len "$key")

        # Cached is always ✓ — keys listed here came from the cache file
        set -l cached_sig "$__OPAH_COLOR_SUCCESS✓$__OPAH_COLOR_RESET"
        if test "$is_loaded" = 1
            set -l loaded_sig "$__OPAH_COLOR_SUCCESS✓$__OPAH_COLOR_RESET"
        else
            set -l loaded_sig "$__OPAH_COLOR_ERROR✕$__OPAH_COLOR_RESET"
        end

        printf "%s│%s%s%s│%s%s%s%s%s│%s%s%s%s%s│%s\n" \
            $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET $padded $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET $sig_l $cached_sig $sig_r $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET $sig_l $loaded_sig $sig_r $__OPAH_COLOR_DIM \
            $__OPAH_COLOR_RESET
    end

    # ── Bottom border ─────────────────────────────────────────────────────────
    printf "%s└%s┴%s┴%s┘%s\n" \
        $__OPAH_COLOR_DIM $h_s $h_c $h_c $__OPAH_COLOR_RESET
end
```

- [ ] **Step 1.4 — Run tests to confirm they all pass**

```bash
just test test_status_table
```

Expected: all 10 tests PASS.

- [ ] **Step 1.5 — Format**

```bash
just fmt
```

Expected: no errors (fish_indent rewrites files in-place).

- [ ] **Step 1.6 — Commit**

```bash
git add functions/_opah_status_table.fish tests/test_status_table.fish
git commit -m "feat: add _opah_status_table box-drawing renderer"
```

---

## Task 2: Wire `_opah_status_table` into `_opah_status.fish`

**Files:**
- Modify: `functions/_opah_status.fish`
- Modify: `tests/test_cli_smoke.fish`

- [ ] **Step 2.1 — Update the smoke test to match table output**

In `tests/test_cli_smoke.fish`, find and replace the status test (around line 114):

Old:
```fish
@test "cli smoke: opah status reports mocked secret as cached and loaded" \
    (begin
        reset_cache
        set -l output (run_mocked_cli 'opah refresh >/dev/null; and opah status API_KEY')
        if string match -q '*cached*' -- $output; and string match -q '*loaded*' -- $output
            echo ok
        end
    end) = ok
```

New:
```fish
@test "cli smoke: opah status reports mocked secret as cached and loaded" \
    (begin
        reset_cache
        set -l output (run_mocked_cli 'opah refresh >/dev/null; and opah status API_KEY')
        if string match -q '*Cached*' -- $output; and string match -q '*Loaded*' -- $output
            echo ok
        end
    end) = ok
```

- [ ] **Step 2.2 — Run smoke tests to confirm they currently pass (baseline)**

```bash
just test test_cli_smoke
```

Expected: all tests PASS (the updated pattern will match both old and new output because "Cached"/"Loaded" don't appear yet — this step just verifies no existing breakage).

- [ ] **Step 2.3 — Replace the per-key printf loops in `_opah_status.fish`**

Replace the entire Secrets section (lines 46–80) with the following. The Cache section above and Summary section below are unchanged.

Old (lines 46–80 in `functions/_opah_status.fish`):
```fish
    # Secrets section
    _opah_section Secrets

    if test -n "$filter_key"
        # Single secret lookup
        if contains -- $filter_key $cached_keys
            if set -q $filter_key
                printf "  %s%-20s%s %scached · loaded%s\n" \
                    $__OPAH_COLOR_DIM $filter_key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
            else
                printf "  %s%-20s%s %scached%s · %snot loaded%s\n" \
                    $__OPAH_COLOR_DIM $filter_key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            end
        else
            _opah_error "$filter_key not found in cache"
            return 1
        end
    else
        # All secrets
        set -l loaded_count 0
        for key in $cached_keys
            if set -q $key
                printf "  %s%-20s%s %scached · loaded%s\n" \
                    $__OPAH_COLOR_DIM $key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
                set loaded_count (math $loaded_count + 1)
            else
                printf "  %s%-20s%s %scached%s · %snot loaded%s\n" \
                    $__OPAH_COLOR_DIM $key $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET \
                    $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            end
        end

        set -l total (count $cached_keys)
```

New (replace from `# Secrets section` through `set -l total (count $cached_keys)`):
```fish
    # Secrets section
    _opah_section Secrets

    if test -n "$filter_key"
        # Single secret lookup
        if contains -- $filter_key $cached_keys
            set -l is_loaded 0
            if set -q $filter_key
                set is_loaded 1
            end
            _opah_status_table 1 $filter_key $is_loaded
        else
            _opah_error "$filter_key not found in cache"
            return 1
        end
    else
        # All secrets — build parallel loaded-flags list
        set -l loaded_count 0
        set -l loaded_flags
        for key in $cached_keys
            if set -q $key
                set -a loaded_flags 1
                set loaded_count (math $loaded_count + 1)
            else
                set -a loaded_flags 0
            end
        end
        _opah_status_table (count $cached_keys) $cached_keys $loaded_flags

        set -l total (count $cached_keys)
```

- [ ] **Step 2.4 — Run the full test suite**

```bash
just test
```

Expected: all tests PASS. If the smoke test for `opah status` fails, check that `_opah_status_table` is in `fish_function_path` inside the mocked runner (it is, because the runner sets the full functions dir).

- [ ] **Step 2.5 — Format**

```bash
just fmt
```

- [ ] **Step 2.6 — Lint**

```bash
just lint
```

Expected: `All files OK`.

- [ ] **Step 2.7 — Commit**

```bash
git add functions/_opah_status.fish tests/test_cli_smoke.fish
git commit -m "feat: render opah status secrets as unicode box table"
```
