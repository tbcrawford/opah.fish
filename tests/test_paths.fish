# Tests for _opah_get_cache_dir, _opah_get_cache_file, _opah_get_config_paths
#
# Run with: fishtape tests/test_paths.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_paths.fish

# ── _opah_get_cache_dir ───────────────────────────────────────────────────────

@test "get_cache_dir: returns a non-empty string" \
    -n (_opah_get_cache_dir)

@test "get_cache_dir: path ends with /opah" \
    (_opah_get_cache_dir | string match -r '/opah$') = "/opah"

@test "get_cache_dir: is rooted under fish cache dir" \
    (_opah_get_cache_dir | string match -r "^$__fish_cache_dir") = "$__fish_cache_dir"

# ── _opah_get_cache_file ──────────────────────────────────────────────────────

@test "get_cache_file: returns a non-empty string" \
    -n (_opah_get_cache_file)

@test "get_cache_file: path ends with secrets.fish" \
    (_opah_get_cache_file | string match -r 'secrets\.fish$') = "secrets.fish"

@test "get_cache_file: is inside the cache dir" \
    (_opah_get_cache_file | string match -r "^(_opah_get_cache_dir)") = (_opah_get_cache_dir)

# ── _opah_get_config_paths ────────────────────────────────────────────────────

@test "get_config_paths: returns at least 4 paths" \
    (_opah_get_config_paths | count) -ge 4

@test "get_config_paths: includes ~/.config/fish/secrets.yaml" \
    (_opah_get_config_paths | string match -r 'secrets\.yaml$' | count) -ge 1

@test "get_config_paths: all paths are non-empty strings" \
    (_opah_get_config_paths | string length | math min) -ge 1

@test "get_config_paths: first path contains .config/fish" \
    (_opah_get_config_paths)[1] = "$HOME/.config/fish/secrets.yaml"
