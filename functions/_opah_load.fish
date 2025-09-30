function _opah_load --description "Load secrets from 1Password CLI with permanent caching"
    # Ensure UI functions are available
    if not functions -q _opah_ui
        source (status dirname)/_opah_ui.fish
    end
    
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

    # Initialize cache directory
    set -l cache_dir "$__fish_cache_dir/1password-secrets"
    set -l cache_file "$cache_dir/secrets.fish"

    # Find the opah configuration file
    set -l secrets_file (_opah_find_config)
    if test $status -ne 0
        _opah_error "No opah configuration found" >&2
        printf "%s   Expected locations:%s\n" $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET >&2
        set -l secret_paths \
            "$HOME/.config/fish/secrets.yaml" \
            "$HOME/.config/fish/secrets.yml" \
            "$HOME/.config/fish/.secrets.yaml" \
            "$HOME/.config/fish/.secrets.yml" \
            "$HOME/.config/1password-secrets/secrets.yaml" \
            "$HOME/.config/1password-secrets/secrets.yml"
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
    set -g specific_key ""
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

    # Create temporary file for building cache
    set -g temp_cache (mktemp)

    # If updating specific key, start with existing cache content
    if test -n "$specific_key" -a -f "$cache_file"
        cp "$cache_file" "$temp_cache"
    else
        # Add header to cache file
        echo "# Cached secrets from 1Password CLI" >"$temp_cache"
        echo "# Generated on: $(date)" >>"$temp_cache"
        echo "" >>"$temp_cache"
    end

    # Counter for success/failure tracking (using global scope for function access)
    set -g success_count 0
    set -g total_count 0
    set -g key_found false

    # Create handler function to process each secret
    function __load_handler
        set -l key $argv[1]
        set -l value $argv[2]
        set total_count (math $total_count + 1)

        # Check if this is the specific key we're looking for
        if test -n "$specific_key"
            if test "$key" = "$specific_key"
                set key_found true
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
            if test -n "$specific_key"
                # Remove existing line for this key and add new one
                sed -i '' "/^set -gx $key /d" "$temp_cache" 2>/dev/null
                echo "set -gx $key '$secret_value'" >>"$temp_cache"
            else
                # Write to cache file normally
                echo "set -gx $key '$secret_value'" >>"$temp_cache"
            end
            
            set -gx $key "$secret_value"

            printf " %s✓%s\n" $__OPAH_COLOR_SUCCESS $__OPAH_COLOR_RESET
            set success_count (math $success_count + 1)
        else
            printf " %s✗%s\n" $__OPAH_COLOR_ERROR $__OPAH_COLOR_RESET
            printf "%sWarning: Failed to fetch from %s%s\n" $__OPAH_COLOR_WARNING "$value" $__OPAH_COLOR_RESET >&2
        end
    end

    # Parse YAML and extract key-value pairs under 'secrets' key
    _opah_parse_yaml "$secrets_file" __load_handler

    # Move temp file to final cache location
    mv "$temp_cache" "$cache_file"
    
    # Clean up global temp_cache variable
    set -e temp_cache

    # Clean up global counter variables after use
    set -l final_success_count $success_count
    set -l final_total_count $total_count
    set -l final_key_found $key_found
    set -l final_specific_key $specific_key
    set -e success_count
    set -e total_count
    set -e key_found
    set -e specific_key

    # Check if specific key was found
    if test -n "$final_specific_key" -a "$final_key_found" = false
        _opah_error "Failed: Secret '$final_specific_key' not found in configuration" >&2
        return 1
    end

    # Display results with modern formatting
    if test -n "$final_specific_key"
        if test $final_success_count -eq 1
            printf "\n"
            _opah_success "Success! $final_specific_key refreshed"
        else
            _opah_error "Failed: Unable to refresh $final_specific_key" >&2
            return 1
        end
    else if test $final_success_count -eq $final_total_count; and test $final_success_count -gt 0
        printf "\n"
        _opah_success "Success! $final_success_count secrets loaded"
    else if test $final_success_count -gt 0
        printf "\n"
        _opah_info "Partial success: $final_success_count/$final_total_count secrets loaded"
    else
        _opah_error "Failed: No secrets loaded" >&2
        return 1
    end

    return 0
end
