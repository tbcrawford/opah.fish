# Tests for cache read validation
#
# Run with: fishtape tests/test_cache_validate_read.fish

source (status dirname)/../functions/_opah_perms.fish
source (status dirname)/../functions/_opah_cache_validate.fish
source (status dirname)/../functions/_opah_is_blocked_env_key.fish
source (status dirname)/../functions/_opah_cache_read.fish
source (status dirname)/../functions/_opah_cache_write.fish

set tmp (mktemp -d)
set cache_file "$tmp/secrets.fish"

@test "cache read: rejects world-readable cache file" \
    (begin
        printf 'API_KEY\tsecret\n' | _opah_cache_write "$cache_file" >/dev/null
        chmod 644 "$cache_file"
        _opah_cache_read "$cache_file" >/dev/null 2>&1
        echo $status
    end) -eq 1

@test "cache read: loads secure cache file" \
    (begin
        printf 'API_KEY\tsecret\n' | _opah_cache_write "$cache_file" >/dev/null
        _opah_cache_read "$cache_file" >/dev/null 2>&1
        echo $status
    end) -eq 0

rm -rf $tmp
