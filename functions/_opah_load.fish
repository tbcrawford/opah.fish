#
# Load secrets from 1Password CLI with permanent caching
#
# Loads secrets from 1Password and caches them permanently for performance.
# Can load from cache, force refresh all secrets, or refresh a specific secret.
# Validates 1Password CLI availability and authentication before fetching secrets.
# Creates environment variables for each secret defined in the configuration file.
#
# @param -h/--help Shows usage information and examples
# @param -f/--force Forces refresh of all secrets from 1Password
# @param -k/--key=KEY Refreshes only the specified secret key
# @return 0 on success, 1 if configuration not found or 1Password CLI unavailable
#
function _opah_load --description "Load secrets from 1Password CLI with permanent caching"
    # Initialize UI functions
    if not functions -q _opah_init_ui
        source (status dirname)/_opah_init_ui.fish
    end
    _opah_init_ui
    
    argparse 'h/help' 'f/force' 'k/key=' -- $argv

    if set -q _flag_help
        printf "Load secrets from 1Password CLI with permanent caching\n\n"
        printf "%s%s%s\n" (set_color --bold) "USAGE:" (set_color normal)
        printf "    _opah_load [OPTIONS]\n\n"
        printf "%s%s%s\n" (set_color --bold) "OPTIONS:" (set_color normal)
        printf "    -h, --help            Show this help message\n"
        printf "    -f, --force           Force refresh of all secrets\n"
        printf "    -k, --key=KEY         Refresh specific secret only\n\n"
        printf "%s%s%s\n" (set_color --bold) "EXAMPLES:" (set_color normal)
        printf "%s    _opah_load                    # Load from cache or fetch if missing%s\n" (set_color --dim) (set_color normal)
        printf "%s    _opah_load --force            # Force refresh all secrets%s\n" (set_color --dim) (set_color normal)
        printf "%s    _opah_load --key=API_KEY      # Refresh only API_KEY%s\n" (set_color --dim) (set_color normal)
        return 0
    end

    # Ensure path utilities are available
    if not functions -q _opah_get_cache_dir
        source (status dirname)/_opah_paths.fish
    end

    # Initialize cache directory and file paths
    set -l cache_dir (_opah_get_cache_dir)
    set -l cache_file (_opah_get_cache_file)

    # Find the opah configuration file
    set -l secrets_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "No opah configuration found" >&2
        printf "%s   Expected locations:%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET >&2
        set -l secret_paths (_opah_get_config_paths)
        for path in $secret_paths
            printf "%s   %s%s\n" $__OPAH_COLOR_DIM "$path" $__OPAH_COLOR_RESET >&2
        end
        return 1
    end

    # Check for force refresh flag
    set -l force_refresh false
    if set -q _flag_force
        set force_refresh true
    end

    # Check for specific key to refresh
    set -l specific_key ""
    if set -q _flag_key
        set specific_key "$_flag_key"
        set force_refresh true  # Force refresh when targeting specific key
    end

    # Use cached secrets if they exist and force refresh is not requested
    if test -f "$cache_file" -a "$force_refresh" = false
        source "$cache_file"
        return 0
    end

    # If refreshing specific key, load existing cache first then update only that key
    if test -n "$specific_key" -a -f "$cache_file"
        source "$cache_file"
    end

    # Check if 1Password CLI is available
    if not command -q op
        _opah_error "1Password CLI not found" >&2
        _opah_hint "Install from: https://developer.1password.com/docs/cli/get-started/" >&2
        return 1
    end

    # Check if user is signed in to 1Password
    if not op account list --format=json >/dev/null 2>&1
        _opah_error "Not signed in to 1Password" >&2
        _opah_hint "op signin" "to authenticate" >&2
        return 1
    end

    _opah_security "Loading secrets from 1Password..."

    # Create cache directory if it doesn't exist
    mkdir -p "$cache_dir"

    # Create temporary file for building cache with secure permissions
    set -l temp_cache (mktemp)
    chmod 600 "$temp_cache"

    # If updating specific key, start with existing cache content
    if test -n "$specific_key" -a -f "$cache_file"
        cp "$cache_file" "$temp_cache"
    else
        # Add header to cache file
        echo "# Cached secrets from 1Password CLI" >"$temp_cache"
        echo "# Generated on: $(date)" >>"$temp_cache"
        echo "" >>"$temp_cache"
    end

    # Use global variables for tracking to work with the handler function
    set -g __OPAH_SUCCESS_COUNT 0
    set -g __OPAH_TOTAL_COUNT 0
    set -g __OPAH_KEY_FOUND false
    set -g __OPAH_TEMP_CACHE "$temp_cache"
    set -g __OPAH_SPECIFIC_KEY "$specific_key"

    # Create handler function to process each secret
    function __load_handler --description "Handle individual secret loading"
        set -l key $argv[1]
        set -l value $argv[2]
        
        # Increment total count
        set -g __OPAH_TOTAL_COUNT (math $__OPAH_TOTAL_COUNT + 1)

        # Check if this is the specific key we're looking for
        if test -n "$__OPAH_SPECIFIC_KEY"
            if test "$key" = "$__OPAH_SPECIFIC_KEY"
                set -g __OPAH_KEY_FOUND true
            else
                return 0
            end
        end

        printf "  %s" "$key"

        # Fetch the actual secret value from 1Password
        set -l secret_value (op read "$value" 2>/dev/null)

        if test $status -eq 0; and test -n "$secret_value"
            # Escape single quotes and backslashes in the secret value
            set secret_value (string replace -a "'" "'\\''" "$secret_value")
            set secret_value (string replace -a "\\" "\\\\" "$secret_value")

            # For specific key refresh, update the cache file by replacing the line
            if test -n "$__OPAH_SPECIFIC_KEY"
                # Remove existing line for this key and add new one
                sed -i '' "/^set -gx $key /d" "$__OPAH_TEMP_CACHE" 2>/dev/null
                echo "set -gx $key '$secret_value'" >>"$__OPAH_TEMP_CACHE"
            else
                # Write to cache file normally
                echo "set -gx $key '$secret_value'" >>"$__OPAH_TEMP_CACHE"
            end
            
            set -gx $key "$secret_value"

            printf " %s✓%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
            set -g __OPAH_SUCCESS_COUNT (math $__OPAH_SUCCESS_COUNT + 1)
        else
            printf " %s✗%s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            printf "%sWarning: Failed to fetch from %s%s\n" $__OPAH_COLOR_WARNING "$value" $__OPAH_COLOR_RESET >&2
        end
    end

    # Parse YAML and extract key-value pairs under 'secrets' key
    _opah_parse_yaml "$secrets_file" __load_handler

    # Copy global values to local variables for cleanup
    set -l success_count $__OPAH_SUCCESS_COUNT
    set -l total_count $__OPAH_TOTAL_COUNT
    set -l key_found $__OPAH_KEY_FOUND

    # Clean up global variables
    set -e __OPAH_SUCCESS_COUNT
    set -e __OPAH_TOTAL_COUNT
    set -e __OPAH_KEY_FOUND
    set -e __OPAH_TEMP_CACHE
    set -e __OPAH_SPECIFIC_KEY

    # Set secure permissions on cache file before moving
    chmod 600 "$temp_cache"
    mv "$temp_cache" "$cache_file"
    
    # Ensure final cache file has secure permissions
    chmod 600 "$cache_file"

    # Check if specific key was found
    if test -n "$specific_key" -a "$key_found" = false
        _opah_error "Failed: Secret '$specific_key' not found in configuration" >&2
        return 1
    end

    # Display results with modern formatting
    if test -n "$specific_key"
        if test $success_count -eq 1
            printf "\n"
            _opah_success "Success! $specific_key refreshed"
        else
            _opah_error "Failed: Unable to refresh $specific_key" >&2
            return 1
        end
    else if test $success_count -eq $total_count; and test $success_count -gt 0
        printf "\n"
        _opah_success "Success! $success_count secrets loaded"
    else if test $success_count -gt 0
        printf "\n"
        _opah_info "Partial success: $success_count/$total_count secrets loaded"
    else
        _opah_error "Failed: No secrets loaded" >&2
        return 1
    end

    return 0
end
