# Tests for _opah_find_config and _opah_get_config_paths
#
# Run with: fishtape tests/test_find_config.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_get_config_paths.fish
source (status dirname)/../functions/_opah_get_cache_dir.fish
source (status dirname)/../functions/_opah_get_cache_file.fish
source (status dirname)/../functions/_opah_find_config.fish

# ── Fixtures ─────────────────────────────────────────────────────────────────

set tmp (mktemp -d)

# Override path discovery to point at our temp directory
function _opah_get_config_paths
    echo "$tmp/secrets.yaml"
    echo "$tmp/secrets.yml"
    echo "$tmp/.secrets.yaml"
end

# ── _opah_get_config_paths ────────────────────────────────────────────────────

@test "get_config_paths: returns at least one path" \
    (_opah_get_config_paths | count) -ge 1

@test "get_config_paths: first path ends in secrets.yaml" \
    (_opah_get_config_paths)[1] = "$tmp/secrets.yaml"

@test "get_config_paths: second path ends in secrets.yml" \
    (_opah_get_config_paths)[2] = "$tmp/secrets.yml"

# ── _opah_find_config ─────────────────────────────────────────────────────────

@test "find_config: exits 1 when no config file exists" \
    (_opah_find_config >/dev/null 2>&1; echo $status) -eq 1

@test "find_config: exits 0 when a config file exists" \
    (touch "$tmp/secrets.yaml"; _opah_find_config >/dev/null; echo $status) -eq 0

@test "find_config: outputs the path of the found file" \
    (_opah_find_config) = "$tmp/secrets.yaml"

# Remove first, verify fallback to second
@test "find_config: falls back to second path when first is absent" \
    (begin
        rm -f "$tmp/secrets.yaml"
        touch "$tmp/secrets.yml"
        _opah_find_config
    end) = "$tmp/secrets.yml"

# Priority order: first path wins when multiple exist
@test "find_config: first-priority path wins when multiple exist" \
    (begin
        touch "$tmp/secrets.yaml"
        touch "$tmp/secrets.yml"
        _opah_find_config
    end) = "$tmp/secrets.yaml"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
