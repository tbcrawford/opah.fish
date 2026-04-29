# Tests for _opah_mtime and _opah_perms (cross-platform utilities)
#
# Run with: fishtape tests/test_platform.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_mtime.fish
source (status dirname)/../functions/_opah_perms.fish

# ── Fixtures ─────────────────────────────────────────────────────────────────

set tmp (mktemp -d)
set test_file "$tmp/sample"
touch "$test_file"
chmod 600 "$test_file"

# ── _opah_mtime ───────────────────────────────────────────────────────────────

@test "mtime: returns a non-empty string for an existing file" \
    -n (_opah_mtime "$test_file")

@test "mtime: exits 0 for an existing file" \
    (_opah_mtime "$test_file" >/dev/null; echo $status) -eq 0

@test "mtime: exits 1 for a missing file" \
    (_opah_mtime "$tmp/no_such_file" >/dev/null 2>&1; echo $status) -eq 1

@test "mtime: output is not the raw stat flags" \
    (count (_opah_mtime "$test_file" | string match -r '^%')) -eq 0

# ── _opah_perms ───────────────────────────────────────────────────────────────

@test "perms: returns 600 for a 600-permission file" \
    (_opah_perms "$test_file") = 600

@test "perms: returns 644 for a 644-permission file" \
    (begin; chmod 644 "$test_file"; _opah_perms "$test_file"; end) = 644

@test "perms: exits 0 for an existing file" \
    (_opah_perms "$test_file" >/dev/null; echo $status) -eq 0

@test "perms: exits 1 for a missing file" \
    (_opah_perms "$tmp/no_such_file" >/dev/null 2>&1; echo $status) -eq 1

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
