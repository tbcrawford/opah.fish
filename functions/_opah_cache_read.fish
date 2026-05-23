#
# Read cache and export secrets as environment variables
#
# Reads the cache file and exports each secret as a global environment variable.
# Returns the number of secrets loaded.
#
# @param cache_file The path to the cache file
# @return The number of secrets successfully loaded (stdout), 0 on success, 1 on error
#
function _opah_cache_read -d "Read cache and export secrets to environment"
    set -l cache_file $argv[1]

    if not test -f "$cache_file"
        return 1
    end

    set -l count 0

    while read -l line
        # Skip comments and empty lines
        if string match -qr '^\s*(#|$)' "$line"
            continue
        end

        # Parse tab-separated key-value pairs (split at most once to preserve tabs in values)
        set -l parts (string split -m 1 \t "$line")

        if test (count $parts) -ge 2
            set -l key $parts[1]
            set -l escaped_value $parts[2]

            # Unescape the value safely
            set -l value (string unescape --style=script "$escaped_value")

            # Export as global environment variable
            set -gx $key "$value"
            set count (math $count + 1)
        end
    end <"$cache_file"

    echo $count
    return 0
end
