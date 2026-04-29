#
# Get cache directory path
#
# Returns the path to the opah cache directory, using Fish's standard
# cache directory as the base.
#
# @return Cache directory path (stdout)
#
function _opah_get_cache_dir -d "Get cache directory path"
    echo "$__fish_cache_dir/opah"
end
