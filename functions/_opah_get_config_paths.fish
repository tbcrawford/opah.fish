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
