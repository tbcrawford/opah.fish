# Tests for cache path validation (write path)
#
# Run with: fishtape tests/test_cache_validate_write.fish

source (status dirname)/../functions/_opah_perms.fish
source (status dirname)/../functions/_opah_cache_validate.fish
source (status dirname)/../functions/_opah_cache_write.fish

set tmp (mktemp -d)
set cache_dir "$tmp/opah"
set cache_file "$cache_dir/secrets.fish"

@test "cache write: creates cache directory with mode 700" \
    (begin
        rm -rf "$cache_dir"
        printf 'KEY\tval\n' | _opah_cache_write "$cache_file" >/dev/null
        _opah_perms "$cache_dir"
    end) = 700

@test "cache write: rejects world-accessible cache directory" \
    (begin
        rm -rf "$cache_dir"
        mkdir -m 755 -p "$cache_dir"
        printf 'KEY\tval\n' | _opah_cache_write "$cache_file" >/dev/null 2>&1
        echo $status
    end) -eq 1

@test "cache write: rejects non-executable cache directory" \
    (begin
        rm -rf "$cache_dir"
        mkdir -m 600 -p "$cache_dir"
        printf 'KEY\tval\n' | _opah_cache_write "$cache_file" >/dev/null 2>&1
        echo $status
    end) -eq 1

@test "cache write: rejects regular file at cache directory path" \
    (begin
        rm -rf "$cache_dir"
        touch "$cache_dir"
        printf 'KEY\tval\n' | _opah_cache_write "$cache_file" >/dev/null 2>&1
        echo $status
    end) -eq 1

rm -rf $tmp
