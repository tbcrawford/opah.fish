# Tests for _opah_parse_yaml
#
# Run with: fishtape tests/test_parse_yaml.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_parse_yaml.fish

# ── Fixtures ─────────────────────────────────────────────────────────────────

set tmp (mktemp -d)

function make_yaml -a name content
    set -l path "$tmp/$name.yaml"
    printf '%b' "$content" >"$path"
    echo "$path"
end

set f_basic (make_yaml basic "secrets:\n  API_KEY: op://vault/item/field\n")
set f_multi  (make_yaml multi  "secrets:\n  KEY1: op://vault/item/k1\n  KEY2: op://vault/item/k2\n  KEY3: op://vault/item/k3\n")
set f_quoted_dq (make_yaml qdq  "secrets:\n  MY_KEY: \"op://vault/item/field\"\n")
set f_quoted_sq (make_yaml qsq  "secrets:\n  MY_KEY: 'op://vault/item/field'\n")
set f_comments  (make_yaml cmt  "# top comment\nsecrets:\n  # inline comment\n  API_KEY: op://vault/item/field\n\n  # another comment\n  DB_URL: op://vault/item/db\n")
set f_nosecrets (make_yaml nope "other:\n  KEY: val\n")
set f_colon_val (make_yaml cln  "secrets:\n  CONN: postgres://user:pass@host:5432/db\n")
set f_two_sections (make_yaml two "secrets:\n  A: op://v/i/a\nother:\n  B: should_not_appear\n")
set f_tabs_in_val   (make_yaml tab  "secrets:\n  KEY: some\tvalue\n")
set f_invalid_keys  (make_yaml inv  "secrets:\n  valid_key: op://v/i/f\n  123invalid: op://v/i/f\n  has space: op://v/i/f\n")

# ── Exit status ───────────────────────────────────────────────────────────────

@test "parse_yaml: exits 0 when secrets section found" \
    (_opah_parse_yaml $f_basic >/dev/null 2>&1; echo $status) -eq 0

@test "parse_yaml: exits 1 when no secrets section" \
    (_opah_parse_yaml $f_nosecrets >/dev/null 2>&1; echo $status) -eq 1

@test "parse_yaml: exits 1 for missing file" \
    (_opah_parse_yaml /nonexistent/file.yaml >/dev/null 2>&1; echo $status) -eq 1

@test "parse_yaml: exits 1 when called with no arguments" \
    (_opah_parse_yaml >/dev/null 2>&1; echo $status) -eq 1

# ── Output format ─────────────────────────────────────────────────────────────

@test "parse_yaml: outputs KEY<tab>VALUE on one line" \
    (_opah_parse_yaml $f_basic) = (printf 'API_KEY\top://vault/item/field')

@test "parse_yaml: outputs one line per secret" \
    (_opah_parse_yaml $f_multi | count) -eq 3

@test "parse_yaml: key is correct for basic secret" \
    (_opah_parse_yaml $f_basic | string split \t)[1] = "API_KEY"

@test "parse_yaml: value is correct for basic secret" \
    (_opah_parse_yaml $f_basic | string split \t)[2] = "op://vault/item/field"

# ── Value handling ────────────────────────────────────────────────────────────

@test "parse_yaml: strips double quotes from value" \
    (_opah_parse_yaml $f_quoted_dq | string split \t)[2] = "op://vault/item/field"

@test "parse_yaml: strips single quotes from value" \
    (_opah_parse_yaml $f_quoted_sq | string split \t)[2] = "op://vault/item/field"

@test "parse_yaml: preserves colons in value" \
    (_opah_parse_yaml $f_colon_val | string split -m 1 \t)[2] = "postgres://user:pass@host:5432/db"

# ── Comments and blank lines ──────────────────────────────────────────────────

@test "parse_yaml: skips comment lines inside secrets section" \
    (_opah_parse_yaml $f_comments | count) -eq 2

@test "parse_yaml: skips blank lines inside secrets section" \
    (_opah_parse_yaml $f_comments | count) -eq 2

# ── Section boundary ──────────────────────────────────────────────────────────

@test "parse_yaml: does not output entries from sections after secrets" \
    (_opah_parse_yaml $f_two_sections | count) -eq 1

@test "parse_yaml: outputs only A from two-section file" \
    (_opah_parse_yaml $f_two_sections | string split \t)[1] = "A"

# ── Invalid keys ──────────────────────────────────────────────────────────────

@test "parse_yaml: accepts valid underscore key" \
    (_opah_parse_yaml $f_invalid_keys | count) -eq 1

@test "parse_yaml: skips key starting with digit" \
    (_opah_parse_yaml $f_invalid_keys) = (printf 'valid_key\top://v/i/f')

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
