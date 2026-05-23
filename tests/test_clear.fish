# Tests for _opah_clear unset behavior
#
# Run with: fishtape tests/test_clear.fish

source (status dirname)/../functions/_opah_get_config_paths.fish
source (status dirname)/../functions/_opah_get_cache_dir.fish
source (status dirname)/../functions/_opah_get_cache_file.fish
source (status dirname)/../functions/_opah_perms.fish
source (status dirname)/../functions/_opah_cache_validate.fish
source (status dirname)/../functions/_opah_is_blocked_env_key.fish
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
set cache_dir "$tmp/cache/opah"
set cache_file "$cache_dir/secrets.fish"

function _opah_get_cache_dir
    echo "$cache_dir"
end
function _opah_get_cache_file
    echo "$cache_file"
end

@test "clear: unsets env vars from tab-separated cache" \
    (begin
        printf 'OPAH_CLEAR_TEST\tcached_value\n' | _opah_cache_write "$cache_file" >/dev/null
        set -l loaded (_opah_cache_read "$cache_file")
        if test "$loaded" -ne 1; or not set -q OPAH_CLEAR_TEST
            echo setup-failed
            return
        end
        _opah_clear --quiet >/dev/null
        if set -q OPAH_CLEAR_TEST; echo still-set; else echo cleared; end
    end) = cleared

@test "clear: skips blocked keys like PATH when unsetting cache vars" \
    (begin
        printf 'PATH\t/evil\nOPAH_CLEAR_TEST\tsecret\n' | _opah_cache_write "$cache_file" >/dev/null
        set -gx OPAH_CLEAR_TEST secret
        _opah_clear --quiet >/dev/null
        if set -q OPAH_CLEAR_TEST; echo fail-secret; return; end
        if test -z "$PATH"; echo fail-path; return; end
        echo ok
    end) = ok

rm -rf $tmp
