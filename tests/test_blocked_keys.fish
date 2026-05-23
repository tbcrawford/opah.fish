# Tests for blocked environment variable names
#
# Run with: fishtape tests/test_blocked_keys.fish

source (status dirname)/../functions/_opah_is_blocked_env_key.fish
source (status dirname)/../functions/_opah_parse_yaml.fish
source (status dirname)/../functions/_opah_cache_read.fish
source (status dirname)/../functions/_opah_cache_write.fish

set tmp (mktemp -d)
set f_blocked (printf '%s\n' \
    "secrets:" \
    "  API_KEY: op://vault/item/key" \
    "  PATH: op://vault/item/path" \
    "  LD_PRELOAD: op://vault/item/ld" \
    >"$tmp/blocked.yaml"; echo "$tmp/blocked.yaml")
set cache_file "$tmp/cache.fish"

@test "blocked key: PATH is blocked" \
    (_opah_is_blocked_env_key PATH; echo $status) -eq 0

@test "blocked key: API_KEY is allowed" \
    (_opah_is_blocked_env_key API_KEY; echo $status) -eq 1

@test "parse_yaml: skips blocked keys" \
    (_opah_parse_yaml $f_blocked | count) -eq 1

@test "cache_read: does not export blocked keys from cache" \
    (begin
        printf 'PATH\t/evil\nAPI_KEY\tsecret\n' | _opah_cache_write "$cache_file" >/dev/null
        _opah_cache_read "$cache_file"
    end) -eq 1

rm -rf $tmp
