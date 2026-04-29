#
# Get cache file path
#
# Returns the full path to the secrets cache file.
#
# @return Cache file path (stdout)
#
function _opah_get_cache_file -d "Get cache file path"
    echo "$__fish_cache_dir/opah/secrets.fish"
end
