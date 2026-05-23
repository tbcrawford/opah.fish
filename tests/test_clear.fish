# Tests for _opah_clear unset behavior
#
# Run with: fishtape tests/test_clear.fish

source (status dirname)/../functions/_opah_get_config_paths.fish
source (status dirname)/../functions/_opah_get_cache_dir.fish
source (status dirname)/../functions/_opah_get_cache_file.fish
source (status dirname)/../functions/_opah_find_config.fish
source (status dirname)/../functions/_opah_parse_yaml.fish
source (status dirname)/../functions/_opah_cache_keys.fish
source (status dirname)/../functions/_opah_cache_read.fish
source (status dirname)/../functions/_opah_cache_write.fish
source (status dirname)/../functions/_opah_ui.fish
source (status dirname)/../functions/_opah_success.fish
source (status dirname)/../functions/_opah_error.fish
source (status dirname)/../functions/_opah_warning.fish
source (status dirname)/../functions/_opah_info.fish
source (status dirname)/../functions/_opah_section.fish
source (status dirname)/../functions/_opah_hint.fish
source (status dirname)/../functions/_opah_header.fish
source (status dirname)/../functions/_opah_clear.fish

set tmp (mktemp -d)
set config_file "$tmp/secrets.yaml"
set cache_dir "$tmp/cache/opah"
set cache_file "$cache_dir/secrets.fish"

function _opah_get_config_paths; echo "$config_file"; end
function _opah_get_cache_dir; echo "$cache_dir"; end
function _opah_get_cache_file; echo "$cache_file"; end

printf "secrets:\n  OPAH_CLEAR_TEST: op://Vault/Item/field\n" >"$config_file"

@test "clear: unsets env vars from tab-separated cache" \
    (begin
        printf 'OPAH_CLEAR_TEST\tcached_value\n' | _opah_cache_write "$cache_file" >/dev/null
        _opah_cache_read "$cache_file" >/dev/null
        _opah_clear --quiet >/dev/null
        if set -q OPAH_CLEAR_TEST; echo still-set; else echo cleared; end
    end) = cleared

rm -rf $tmp
