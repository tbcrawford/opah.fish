#
# Find the first existing opah configuration file
#
# Searches through a predefined list of possible configuration file locations
# in order of preference and returns the path to the first file that exists.
# This utility function is used by other opah commands to locate the
# configuration file without duplicating the search logic.
#
# @return The absolute path to the configuration file (stdout), or empty with exit code 1 if not found
#
function _opah_find_config -d "Find the first existing opah configuration file"
    # Ensure path utilities are available
    if not functions -q _opah_get_config_paths
        source (status dirname)/_opah_paths.fish
    end
    
    # Get possible secret file locations from centralized function
    set -l secret_paths (_opah_get_config_paths)
    
    # Find the first existing secrets file
    for path in $secret_paths
        if test -f "$path"
            echo "$path"
            return 0
        end
    end
    
    # If no file found, return error
    return 1
end