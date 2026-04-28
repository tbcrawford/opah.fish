# Integration tests for _opah_load
#
# Uses a mock `op` command — no real 1Password connection is required.
#
# Run with: fishtape tests/test_load.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_ui.fish
source (status dirname)/../functions/_opah_success.fish
source (status dirname)/../functions/_opah_error.fish
source (status dirname)/../functions/_opah_warning.fish
source (status dirname)/../functions/_opah_info.fish
source (status dirname)/../functions/_opah_section.fish
source (status dirname)/../functions/_opah_hint.fish
source (status dirname)/../functions/_opah_header.fish
source (status dirname)/../functions/_opah_get_config_paths.fish
source (status dirname)/../functions/_opah_get_cache_dir.fish
source (status dirname)/../functions/_opah_get_cache_file.fish
source (status dirname)/../functions/_opah_mtime.fish
source (status dirname)/../functions/_opah_perms.fish
source (status dirname)/../functions/_opah_cache_read.fish
source (status dirname)/../functions/_opah_cache_write.fish
source (status dirname)/../functions/_opah_cache_update.fish
source (status dirname)/../functions/_opah_cache_keys.fish
source (status dirname)/../functions/_opah_cache_count.fish
source (status dirname)/../functions/_opah_parse_yaml.fish
source (status dirname)/../functions/_opah_find_config.fish
source (status dirname)/../functions/_opah_load.fish

# ── Fixtures ─────────────────────────────────────────────────────────────────

set tmp (mktemp -d)
set config_file "$tmp/secrets.yaml"
set cache_file "$tmp/cache/opah/secrets.fish"

printf "secrets:\n  OPAH_LOAD_KEY1: op://Vault/Item/field1\n  OPAH_LOAD_KEY2: op://Vault/Item/field2\n" >"$config_file"

# Mock `op` CLI — no real 1Password needed
function op
    switch "$argv[1]"
        case account
            switch "$argv[2]"
                case list
                    printf '[{"email":"test@example.com","url":"my.1password.com"}]\n'
                    return 0
            end
        case read
            # Return a predictable value derived from the reference path
            set -l ref $argv[-1]
            echo "mocked_value_for_$ref"
            return 0
    end
    return 1
end

function mock_opah_paths
    function _opah_get_cache_dir
        echo "$tmp/cache/opah"
    end

    function _opah_get_cache_file
        echo "$tmp/cache/opah/secrets.fish"
    end

    function _opah_get_config_paths
        echo "$config_file"
    end
end

mock_opah_paths

# ── Load: fetch from 1Password ────────────────────────────────────────────────

# Remove any leftover cache so _opah_load fetches fresh
rm -f "$cache_file"

@test "load: exits 0 when config is valid and op succeeds" \
    (mock_opah_paths; _opah_load --force >/dev/null 2>&1; echo $status) -eq 0

@test "load: creates the cache file after a successful fetch" \
    -f "$cache_file"

@test "load: cache file has secure permissions (600)" \
    (_opah_perms "$cache_file") = 600

@test "load: exports first secret as environment variable" \
    (begin; mock_opah_paths; set -e OPAH_LOAD_KEY1; _opah_load --force >/dev/null 2>&1; echo $OPAH_LOAD_KEY1; end) \
    = "mocked_value_for_op://Vault/Item/field1"

@test "load: exports second secret as environment variable" \
    (begin; mock_opah_paths; set -e OPAH_LOAD_KEY2; _opah_load --force >/dev/null 2>&1; echo $OPAH_LOAD_KEY2; end) \
    = "mocked_value_for_op://Vault/Item/field2"

# ── Load: read from cache ─────────────────────────────────────────────────────

# Pre-populate cache directly
printf 'OPAH_CACHED_KEY\tcached_value\n' | _opah_cache_write "$cache_file" >/dev/null

@test "load: exits 0 when cache exists and --force is not given" \
    (mock_opah_paths; _opah_load >/dev/null 2>&1; echo $status) -eq 0

@test "load: reads from cache without calling op" \
    (begin
        mock_opah_paths
        # Override op to fail — load should still succeed from cache
        function op; return 1; end
        _opah_load >/dev/null 2>&1
        echo $status
    end) -eq 0

# ── Load: --force ─────────────────────────────────────────────────────────────

@test "load --force: bypasses cache and refetches" \
    (begin
        mock_opah_paths
        # Put stale value in cache
        printf 'OPAH_LOAD_KEY1\tstale_value\n' | _opah_cache_write "$cache_file" >/dev/null
        # Restore real mock op
        function op
            switch "$argv[1]"
                case read; echo "fresh_value"; return 0
                case account; printf '[{}]\n'; return 0
            end
        end
        _opah_load --force >/dev/null 2>&1
        echo $OPAH_LOAD_KEY1
    end) = fresh_value

# ── Load: --key ───────────────────────────────────────────────────────────────

@test "load --key: exits 0 when key exists in config" \
    (begin
        mock_opah_paths
        function op
            switch "$argv[1]"
                case read; echo "single_fresh"; return 0
                case account; printf '[{}]\n'; return 0
            end
        end
        _opah_load --key=OPAH_LOAD_KEY1 >/dev/null 2>&1
        echo $status
    end) -eq 0

@test "load --key: exits 1 when key does not exist in config" \
    (mock_opah_paths; _opah_load --key=OPAH_NONEXISTENT_KEY >/dev/null 2>&1; echo $status) -eq 1

# Regression: repeated --key updates must not double-escape other keys' values
@test "load --key: other cached keys are not corrupted after repeated --key updates" \
    (begin
        mock_opah_paths
        # Establish initial cache with two keys
        function op
            switch "$argv[1]"
                case read; echo "value_for_$argv[-1]"; return 0
                case account; printf '[{}]\n'; return 0
            end
        end
        _opah_load --force >/dev/null 2>&1

        # Update KEY1 twice; KEY2 should still read back correctly
        function op
            switch "$argv[1]"
                case read; echo "updated"; return 0
                case account; printf '[{}]\n'; return 0
            end
        end
        _opah_load --key=OPAH_LOAD_KEY1 >/dev/null 2>&1
        _opah_load --key=OPAH_LOAD_KEY1 >/dev/null 2>&1

        # Re-read cache into a clean environment
        set -e OPAH_LOAD_KEY2
        _opah_cache_read "$cache_file" >/dev/null
        echo $OPAH_LOAD_KEY2
    end) = "value_for_op://Vault/Item/field2"

# ── Load: missing prerequisites ───────────────────────────────────────────────

@test "load: exits 1 when no config file found" \
    (begin
        mock_opah_paths
        function _opah_get_config_paths; echo "$tmp/no_config_here.yaml"; end
        _opah_load --force >/dev/null 2>&1
        echo $status
    end) -eq 1

@test "load: exits 1 when op command is unavailable" \
    (begin
        mock_opah_paths
        functions --erase op
        mkdir -p "$tmp/no-bin"
        printf '#!/bin/sh\nexit 127\n' > "$tmp/no-bin/op"
        chmod +x "$tmp/no-bin/op"
        set -lx PATH "$tmp/no-bin" $PATH
        rm -f "$cache_file"
        _opah_load --force >/dev/null 2>&1
        echo $status
    end) -eq 1

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
