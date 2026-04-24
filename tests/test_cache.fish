# Tests for _opah_cache_* functions
#
# Run with: fishtape tests/test_cache.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_cache.fish

# ── Fixtures ─────────────────────────────────────────────────────────────────

set tmp (mktemp -d)
set cache_file "$tmp/secrets.fish"

# Helper: write a stream of KEY<tab>VALUE lines into the cache
function write_entries
    printf '%s' "$argv" | _opah_cache_write "$cache_file"
end

# ── _opah_cache_write ─────────────────────────────────────────────────────────

@test "cache_write: creates the cache file" \
    (printf 'KEY\tval\n' | _opah_cache_write "$cache_file" >/dev/null; echo $status) -eq 0

@test "cache_write: file exists after write" \
    -f "$cache_file"

@test "cache_write: sets file permissions to 600" \
    (stat -f '%A' "$cache_file" 2>/dev/null; or stat -c '%a' "$cache_file" 2>/dev/null) = 600

@test "cache_write: exits 0 on success" \
    (printf 'A\t1\n' | _opah_cache_write "$cache_file" >/dev/null; echo $status) -eq 0

# ── _opah_cache_read ──────────────────────────────────────────────────────────

# Seed the cache with two entries
printf 'OPAH_TEST_A\thello\nOPAH_TEST_B\tworld\n' | _opah_cache_write "$cache_file" >/dev/null

@test "cache_read: exits 0 when cache exists" \
    (_opah_cache_read "$cache_file" >/dev/null; echo $status) -eq 0

@test "cache_read: exports first variable into environment" \
    (begin; _opah_cache_read "$cache_file" >/dev/null; echo $OPAH_TEST_A; end) = "hello"

@test "cache_read: exports second variable into environment" \
    (begin; _opah_cache_read "$cache_file" >/dev/null; echo $OPAH_TEST_B; end) = "world"

@test "cache_read: returns count of loaded secrets" \
    (_opah_cache_read "$cache_file") -eq 2

@test "cache_read: exits 1 for missing file" \
    (_opah_cache_read "$tmp/no_such_file" >/dev/null 2>&1; echo $status) -eq 1

# ── Round-trip: special characters ───────────────────────────────────────────

# Value with spaces
printf 'OPAH_TEST_SPACES\thello world\n' | _opah_cache_write "$tmp/spaces.fish" >/dev/null
@test "cache round-trip: preserves spaces in value" \
    (begin; _opah_cache_read "$tmp/spaces.fish" >/dev/null; echo $OPAH_TEST_SPACES; end) = "hello world"

# Value with double quotes
printf 'OPAH_TEST_DQ\t'"say \"hi\""'\n' | _opah_cache_write "$tmp/dq.fish" >/dev/null
@test "cache round-trip: preserves double quotes in value" \
    (begin; _opah_cache_read "$tmp/dq.fish" >/dev/null; echo $OPAH_TEST_DQ; end) = 'say "hi"'

# Value with a tab character (regression test for string split -m 1 fix)
printf "OPAH_TEST_TAB\tcol1\tcol2\n" | _opah_cache_write "$tmp/tab.fish" >/dev/null
@test "cache round-trip: preserves tab characters in value (regression)" \
    (begin; _opah_cache_read "$tmp/tab.fish" >/dev/null; echo $OPAH_TEST_TAB; end) = "col1\tcol2"

# Value with newline
printf 'OPAH_TEST_NL\tline1\nline2\n' | _opah_cache_write "$tmp/nl.fish" >/dev/null
@test "cache round-trip: preserves newline in value" \
    (begin; _opah_cache_read "$tmp/nl.fish" >/dev/null; printf '%s' $OPAH_TEST_NL | count; end) -eq 2

# ── _opah_cache_keys ──────────────────────────────────────────────────────────

# Reset to a known state
printf 'KEY_ONE\tv1\nKEY_TWO\tv2\nKEY_THREE\tv3\n' | _opah_cache_write "$cache_file" >/dev/null

@test "cache_keys: returns one line per key" \
    (_opah_cache_keys "$cache_file" | count) -eq 3

@test "cache_keys: first key name is correct" \
    (_opah_cache_keys "$cache_file")[1] = "KEY_ONE"

@test "cache_keys: contains all three keys" \
    (_opah_cache_keys "$cache_file" | string collect) = "KEY_ONE
KEY_TWO
KEY_THREE"

@test "cache_keys: exits 1 for missing file" \
    (_opah_cache_keys "$tmp/missing" >/dev/null 2>&1; echo $status) -eq 1

# ── _opah_cache_count ─────────────────────────────────────────────────────────

@test "cache_count: returns 3 for three-entry cache" \
    (_opah_cache_count "$cache_file") -eq 3

@test "cache_count: returns 0 for missing file" \
    (_opah_cache_count "$tmp/missing") -eq 0

# ── _opah_cache_update ────────────────────────────────────────────────────────

# Reset
printf 'A\told_a\nB\told_b\n' | _opah_cache_write "$cache_file" >/dev/null

@test "cache_update: exits 0 on success" \
    (_opah_cache_update "$cache_file" A new_a >/dev/null; echo $status) -eq 0

@test "cache_update: changed value is reflected on next read" \
    (begin
        _opah_cache_update "$cache_file" A updated_value >/dev/null
        _opah_cache_read "$cache_file" >/dev/null
        echo $A
    end) = "updated_value"

@test "cache_update: other keys are unchanged after update" \
    (begin
        _opah_cache_update "$cache_file" A x >/dev/null
        _opah_cache_read "$cache_file" >/dev/null
        echo $B
    end) = "old_b"

@test "cache_update: count is unchanged after updating existing key" \
    (begin
        _opah_cache_update "$cache_file" A x >/dev/null
        _opah_cache_count "$cache_file"
    end) -eq 2

@test "cache_update: appends new key when key not found" \
    (begin
        _opah_cache_update "$cache_file" NEW_KEY new_val >/dev/null
        _opah_cache_count "$cache_file"
    end) -eq 3

@test "cache_update: exits 1 for missing file" \
    (_opah_cache_update "$tmp/missing" K v >/dev/null 2>&1; echo $status) -eq 1

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
