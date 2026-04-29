#
# Get list of cached secret keys
#
# Returns a list of all secret keys in the cache file.
#
# @param cache_file The path to the cache file
# @return List of keys (stdout), one per line
#
function _opah_cache_keys -d "Get list of cached secret keys"
    set -l cache_file $argv[1]

    if not test -f "$cache_file"
        return 1
    end

    while read -l line
        # Skip comments and empty lines
        if string match -qr '^\s*(#|$)' "$line"
            continue
        end

        # Extract key (first field before tab, split at most once)
        set -l parts (string split -m 1 \t "$line")
        if test (count $parts) -ge 1
            echo $parts[1]
        end
    end <"$cache_file"
end
