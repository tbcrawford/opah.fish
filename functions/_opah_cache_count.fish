#
# Count secrets in cache
#
# Returns the number of secrets stored in the cache file.
#
# @param cache_file The path to the cache file
# @return Number of secrets (stdout)
#
function _opah_cache_count -d "Count secrets in cache"
    set -l cache_file $argv[1]

    if not test -f "$cache_file"
        echo 0
        return 0
    end

    _opah_cache_keys "$cache_file" | count
end
