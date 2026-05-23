#
# Update a single secret in the cache
#
# Updates one secret in the cache file while preserving all others.
# Uses pure Fish operations (no sed).
#
# @param cache_file The path to the cache file
# @param key The secret key to update
# @param value The new value for the secret
# @return 0 on success, 1 on error
#
function _opah_cache_update -d "Update single secret in cache"
    set -l cache_file $argv[1]
    set -l key $argv[2]
    set -l value $argv[3]

    if not test -f "$cache_file"
        return 1
    end

    # Create temp file
    set -l temp_cache (mktemp)
    chmod 600 "$temp_cache"

    set -l escaped (string escape --style=script -- "$value")
    set -l found false

    # Read existing cache and update the specific key
    while read -l line
        # Skip empty lines but preserve comments
        if string match -qr '^\s*$' "$line"
            continue
        end

        # Check if this is the key we're updating
        if string match -qr "^$key\t" "$line"
            printf '%s\t%s\n' "$key" "$escaped" >>"$temp_cache"
            set found true
        else
            echo "$line" >>"$temp_cache"
        end
    end <"$cache_file"

    # If key wasn't found, append it
    if test "$found" = false
        printf '%s\t%s\n' "$key" "$escaped" >>"$temp_cache"
    end

    # Atomic move
    chmod 600 "$temp_cache"
    if not mv "$temp_cache" "$cache_file"
        rm -f "$temp_cache"
        return 1
    end

    return 0
end
