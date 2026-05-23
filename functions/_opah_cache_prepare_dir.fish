#
# Create or fix the cache directory with mode 700
#
# @param cache_dir Cache directory path
# @return 0 on success, 1 on error
#
function _opah_cache_prepare_dir -d "Create cache directory with mode 700"
    set -l cache_dir $argv[1]

    if test -e "$cache_dir"; and not test -d "$cache_dir"
        echo "Cache path is not a directory: $cache_dir" >&2
        return 1
    end

    if not test -d "$cache_dir"
        mkdir -m 700 -p "$cache_dir"
        return $status
    end

    chmod 700 "$cache_dir" 2>/dev/null
    return 0
end
