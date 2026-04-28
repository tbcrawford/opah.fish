#
# Write secrets to cache atomically
#
# Writes secrets to a temporary file then atomically moves it to the cache location.
# Uses secure permissions (600) and string escape for safe serialization.
#
# @param cache_file The path to the cache file
# @param secrets_stream Tab-separated KEY<tab>VALUE stream from stdin
# @return 0 on success, 1 on error
#
function _opah_cache_write -d "Write secrets to cache atomically"
    set -l cache_file $argv[1]
    set -l cache_dir (dirname "$cache_file")

    # Create cache directory if needed
    mkdir -p "$cache_dir"

    # Create temp file with secure permissions
    set -l temp_cache (mktemp)
    chmod 600 "$temp_cache"

    # Write header
    echo "# Cached secrets from 1Password CLI" >"$temp_cache"
    echo "# Generated on: "(date) >>"$temp_cache"
    echo "# Format: KEY<tab>ESCAPED_VALUE" >>"$temp_cache"
    echo "" >>"$temp_cache"

    # Read from stdin and write escaped entries
    while read -l line
        set -l parts (string split -m 1 \t "$line")

        if test (count $parts) -ge 2
            set -l key $parts[1]
            set -l value $parts[2]

            # Escape value safely
            set -l escaped (string escape --style=script -- "$value")

            # Write to cache
            printf '%s\t%s\n' "$key" "$escaped" >>"$temp_cache"
        end
    end

    # Atomic move with secure permissions
    chmod 600 "$temp_cache"
    if not mv "$temp_cache" "$cache_file"
        rm -f "$temp_cache"
        return 1
    end

    return 0
end
