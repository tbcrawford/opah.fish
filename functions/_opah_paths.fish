#
# Centralized configuration paths for opah
#
# Provides centralized functions to get configuration file paths and cache paths
# to eliminate duplication across multiple functions. This ensures consistency
# and makes maintenance easier when path logic needs to change.
#
# @return Various path-related functions
#

#
# Get list of possible configuration file paths in order of preference
#
# Returns the complete list of paths where opah configuration files might be
# located, in order of preference. This centralizes the path definitions
# used by multiple functions.
#
# @return Array of configuration file paths (stdout)
#
function _opah_get_config_paths -d "Get list of possible configuration file paths"
    echo "$HOME/.config/fish/secrets.yaml"
    echo "$HOME/.config/fish/secrets.yml"
    echo "$HOME/.config/fish/.secrets.yaml"
    echo "$HOME/.config/fish/.secrets.yml"
    echo "$HOME/.config/opah/secrets.yaml"
    echo "$HOME/.config/opah/secrets.yml"
end

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

#
# Get cache file path
#
# Returns the full path to the secrets cache file.
#
# @return Cache file path (stdout)
#
function _opah_get_cache_file -d "Get cache file path"
    echo "$(_opah_get_cache_dir)/secrets.fish"
end